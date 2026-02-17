import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, and } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams } from '../../src/db/schema/teams.ts';
import { teamRosters } from '../../src/db/schema/teams.ts';
import {
  createTeam,
  getTeams,
  getTeam,
  updateTeam,
  deleteTeam,
  addPlayer,
  removePlayer,
  searchPlayers,
} from '../../src/services/team.service.ts';

const TEST_SUFFIX = Date.now();

let ownerUserId: string;
let playerUserId: string;
let otherUserId: string;
let testTeamId: string;

beforeAll(async () => {
  // Create test users
  const [owner] = await db
    .insert(users)
    .values({
      firebaseUid: `test-owner-${TEST_SUFFIX}`,
      phone: '+919876540001',
      displayName: 'Test Owner',
      playerRole: 'all_rounder',
      battingStyle: 'right_hand',
      bowlingStyle: 'right_arm_fast',
      location: 'Mumbai',
    })
    .returning();
  ownerUserId = owner!.id;

  const [player] = await db
    .insert(users)
    .values({
      firebaseUid: `test-player-${TEST_SUFFIX}`,
      phone: '+919876540002',
      displayName: 'Test Player',
      playerRole: 'batter',
      battingStyle: 'left_hand',
      bowlingStyle: 'none',
      location: 'Delhi',
    })
    .returning();
  playerUserId = player!.id;

  const [other] = await db
    .insert(users)
    .values({
      firebaseUid: `test-other-${TEST_SUFFIX}`,
      phone: '+919876540003',
      displayName: 'Other User',
      playerRole: 'bowler',
      battingStyle: 'right_hand',
      bowlingStyle: 'left_arm_orthodox',
    })
    .returning();
  otherUserId = other!.id;
});

afterAll(async () => {
  // Clean up in reverse dependency order
  await db.delete(teamRosters).where(
    eq(teamRosters.teamId, testTeamId),
  );
  await db.delete(teams).where(
    eq(teams.createdBy, ownerUserId),
  );
  await db.delete(users).where(eq(users.firebaseUid, `test-owner-${TEST_SUFFIX}`));
  await db.delete(users).where(eq(users.firebaseUid, `test-player-${TEST_SUFFIX}`));
  await db.delete(users).where(eq(users.firebaseUid, `test-other-${TEST_SUFFIX}`));
});

describe('Team Service', () => {
  describe('createTeam', () => {
    it('creates a team with valid input', async () => {
      const team = await createTeam({
        name: 'Mumbai Warriors',
        location: 'Mumbai',
        createdBy: ownerUserId,
      });

      expect(team).toBeDefined();
      expect(team.id).toBeTruthy();
      expect(team.name).toBe('Mumbai Warriors');
      expect(team.location).toBe('Mumbai');
      expect(team.createdBy).toBe(ownerUserId);
      expect(team.isActive).toBe(true);
      testTeamId = team.id;
    });

    it('trims team name whitespace', async () => {
      const team = await createTeam({
        name: '  Trim Team  ',
        createdBy: ownerUserId,
      });
      expect(team.name).toBe('Trim Team');
      // Clean up
      await db.delete(teams).where(eq(teams.id, team.id));
    });

    it('rejects team name shorter than 2 chars', async () => {
      await expect(
        createTeam({ name: 'A', createdBy: ownerUserId }),
      ).rejects.toThrow('Team name must be 2-50 characters');
    });

    it('rejects team name longer than 50 chars', async () => {
      await expect(
        createTeam({
          name: 'A'.repeat(51),
          createdBy: ownerUserId,
        }),
      ).rejects.toThrow('Team name must be 2-50 characters');
    });
  });

  describe('getTeams', () => {
    it('returns teams for the owner', async () => {
      const result = await getTeams(ownerUserId);
      expect(result.teams.length).toBeGreaterThanOrEqual(1);
      const found = result.teams.find((t) => t.id === testTeamId);
      expect(found).toBeDefined();
      expect(found!.role).toBe('owner');
      expect(found!.playerCount).toBe(0);
    });

    it('returns empty for user with no teams', async () => {
      const result = await getTeams(otherUserId);
      expect(result.teams.length).toBe(0);
      expect(result.total).toBe(0);
    });

    it('supports pagination', async () => {
      const result = await getTeams(ownerUserId, 1, 1);
      expect(result.teams.length).toBeLessThanOrEqual(1);
      expect(result.page).toBe(1);
    });
  });

  describe('getTeam', () => {
    it('returns team with roster', async () => {
      const team = await getTeam(testTeamId);
      expect(team).not.toBeNull();
      expect(team!.name).toBe('Mumbai Warriors');
      expect(team!.roster).toBeDefined();
      expect(Array.isArray(team!.roster)).toBe(true);
    });

    it('returns null for non-existent team', async () => {
      const team = await getTeam('00000000-0000-0000-0000-000000000000');
      expect(team).toBeNull();
    });
  });

  describe('updateTeam', () => {
    it('updates team name by owner', async () => {
      const updated = await updateTeam(testTeamId, ownerUserId, {
        name: 'Mumbai Warriors XI',
      });
      expect(updated).not.toBeNull();
      expect(updated!.name).toBe('Mumbai Warriors XI');
    });

    it('updates team location', async () => {
      const updated = await updateTeam(testTeamId, ownerUserId, {
        location: 'Navi Mumbai',
      });
      expect(updated!.location).toBe('Navi Mumbai');
    });

    it('rejects update from unauthorized user', async () => {
      await expect(
        updateTeam(testTeamId, otherUserId, { name: 'Hacked' }),
      ).rejects.toThrow('Only team owner or captain can perform this action');
    });

    it('rejects empty update', async () => {
      await expect(
        updateTeam(testTeamId, ownerUserId, {}),
      ).rejects.toThrow('No fields to update');
    });

    it('rejects invalid team name', async () => {
      await expect(
        updateTeam(testTeamId, ownerUserId, { name: 'X' }),
      ).rejects.toThrow('Team name must be 2-50 characters');
    });
  });

  describe('addPlayer', () => {
    it('adds a player to the team', async () => {
      const entry = await addPlayer(testTeamId, ownerUserId, {
        playerId: playerUserId,
        role: 'player',
        jerseyNumber: 7,
      });

      expect(entry).toBeDefined();
      expect(entry.playerId).toBe(playerUserId);
      expect(entry.role).toBe('player');
      expect(entry.jerseyNumber).toBe(7);
      expect(entry.isActive).toBe(true);
    });

    it('rejects duplicate player', async () => {
      await expect(
        addPlayer(testTeamId, ownerUserId, { playerId: playerUserId }),
      ).rejects.toThrow('Player is already on this team');
    });

    it('rejects non-existent player', async () => {
      await expect(
        addPlayer(testTeamId, ownerUserId, {
          playerId: '00000000-0000-0000-0000-000000000000',
        }),
      ).rejects.toThrow('Player not found');
    });

    it('rejects unauthorized user', async () => {
      await expect(
        addPlayer(testTeamId, otherUserId, { playerId: otherUserId }),
      ).rejects.toThrow('Only team owner or captain can perform this action');
    });

    it('defaults role to player', async () => {
      const entry = await addPlayer(testTeamId, ownerUserId, {
        playerId: otherUserId,
      });
      expect(entry.role).toBe('player');
      // Clean up
      await db
        .update(teamRosters)
        .set({ isActive: false })
        .where(
          and(
            eq(teamRosters.teamId, testTeamId),
            eq(teamRosters.playerId, otherUserId),
          ),
        );
    });
  });

  describe('removePlayer', () => {
    it('removes a player from the team (soft delete)', async () => {
      const removed = await removePlayer(testTeamId, ownerUserId, playerUserId);
      expect(removed).toBeDefined();
      expect(removed.isActive).toBe(false);
    });

    it('rejects removing non-existent roster entry', async () => {
      await expect(
        removePlayer(testTeamId, ownerUserId, '00000000-0000-0000-0000-000000000000'),
      ).rejects.toThrow('Player not found in team roster');
    });

    it('reactivates previously removed player on re-add', async () => {
      const reactivated = await addPlayer(testTeamId, ownerUserId, {
        playerId: playerUserId,
        role: 'captain',
      });
      expect(reactivated.isActive).toBe(true);
      expect(reactivated.role).toBe('captain');
    });
  });

  describe('getTeam (with roster)', () => {
    it('returns roster with player details', async () => {
      const team = await getTeam(testTeamId);
      expect(team!.roster.length).toBeGreaterThanOrEqual(1);

      const player = team!.roster.find((r) => r.playerId === playerUserId);
      expect(player).toBeDefined();
      expect(player!.displayName).toBe('Test Player');
      expect(player!.battingStyle).toBe('left_hand');
      expect(player!.role).toBe('captain');
    });
  });

  describe('getTeams (with roster member)', () => {
    it('returns teams for roster member', async () => {
      const result = await getTeams(playerUserId);
      const found = result.teams.find((t) => t.id === testTeamId);
      expect(found).toBeDefined();
      expect(found!.role).toBe('captain');
      expect(found!.playerCount).toBeGreaterThanOrEqual(1);
    });
  });

  describe('searchPlayers', () => {
    it('finds players by partial name match', async () => {
      const results = await searchPlayers('Test');
      expect(results.length).toBeGreaterThanOrEqual(2);
    });

    it('is case insensitive', async () => {
      const results = await searchPlayers('test owner');
      expect(results.length).toBeGreaterThanOrEqual(1);
      expect(results[0]!.displayName).toBe('Test Owner');
    });

    it('returns empty for no match', async () => {
      const results = await searchPlayers('ZZZZNONEXISTENT');
      expect(results.length).toBe(0);
    });

    it('returns empty for short query', async () => {
      const results = await searchPlayers('A');
      expect(results.length).toBe(0);
    });

    it('respects limit parameter', async () => {
      const results = await searchPlayers('Test', 1);
      expect(results.length).toBeLessThanOrEqual(1);
    });
  });

  describe('deleteTeam', () => {
    it('rejects delete from unauthorized user', async () => {
      await expect(
        deleteTeam(testTeamId, otherUserId),
      ).rejects.toThrow('Only team owner or captain can perform this action');
    });

    it('soft deletes a team', async () => {
      const deleted = await deleteTeam(testTeamId, ownerUserId);
      expect(deleted).not.toBeNull();
      expect(deleted!.isActive).toBe(false);
    });

    it('getTeam returns null for deleted team', async () => {
      const team = await getTeam(testTeamId);
      expect(team).toBeNull();
    });
  });
});
