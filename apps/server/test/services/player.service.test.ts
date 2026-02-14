import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { battingStats, bowlingStats, fieldingStats, playerCareerStats } from '../../src/db/schema/stats.ts';
import {
  searchPlayersByName,
  searchPlayerByPhone,
  createPlayer,
  getPlayerProfile,
  getPlayerStats,
  getPlayerMatches,
} from '../../src/services/player.service.ts';
import { refreshPlayerAllFormats } from '../../src/services/career-stats.service.ts';

const TEST_SUFFIX = Date.now();
const createdPlayerIds: string[] = [];

/** Helper: expect a promise to reject (workaround for bun .rejects.toThrow() hang) */
async function expectToReject(fn: () => Promise<unknown>, msgSubstring?: string) {
  let threw = false;
  let error: unknown;
  try {
    await fn();
  } catch (e) {
    threw = true;
    error = e;
  }
  expect(threw).toBe(true);
  if (msgSubstring && error instanceof Error) {
    expect(error.message).toContain(msgSubstring);
  }
}

afterAll(async () => {
  for (const id of createdPlayerIds) {
    await db.delete(users).where(eq(users.id, id));
  }
});

describe('Player Service', () => {
  describe('createPlayer', () => {
    it('creates a placeholder player', async () => {
      const player = await createPlayer({
        displayName: `SearchTest Player ${TEST_SUFFIX}`,
        phone: '+919999990001',
        playerRole: 'batter',
        battingStyle: 'right_hand',
        bowlingStyle: 'none',
      });

      expect(player).toBeDefined();
      expect(player.id).toBeTruthy();
      expect(player.displayName).toBe(`SearchTest Player ${TEST_SUFFIX}`);
      expect(player.phone).toBe('+919999990001');
      expect(player.firebaseUid).toContain('placeholder-');
      createdPlayerIds.push(player.id);
    });

    it('trims display name', async () => {
      const player = await createPlayer({
        displayName: `  Trimmed ${TEST_SUFFIX}  `,
      });
      expect(player.displayName).toBe(`Trimmed ${TEST_SUFFIX}`);
      createdPlayerIds.push(player.id);
    });

    it('rejects short name', async () => {
      await expect(
        createPlayer({ displayName: 'A' }),
      ).rejects.toThrow('Display name must be 2-50 characters');
    });
  });

  describe('searchPlayersByName', () => {
    it('finds players by partial name', async () => {
      const results = await searchPlayersByName(`SearchTest`);
      expect(results.length).toBeGreaterThanOrEqual(1);
      const found = results.find((p) => p.displayName === `SearchTest Player ${TEST_SUFFIX}`);
      expect(found).toBeDefined();
    });

    it('is case insensitive', async () => {
      const results = await searchPlayersByName(`searchtest`);
      expect(results.length).toBeGreaterThanOrEqual(1);
    });

    it('returns empty for short query', async () => {
      const results = await searchPlayersByName('Z');
      expect(results.length).toBe(0);
    });

    it('returns empty for no match', async () => {
      const results = await searchPlayersByName('ZZZNONEXISTENT999');
      expect(results.length).toBe(0);
    });

    it('respects limit', async () => {
      const results = await searchPlayersByName('SearchTest', 1);
      expect(results.length).toBeLessThanOrEqual(1);
    });
  });

  describe('searchPlayerByPhone', () => {
    it('finds player by exact phone', async () => {
      const player = await searchPlayerByPhone('+919999990001');
      expect(player).not.toBeNull();
      expect(player!.displayName).toBe(`SearchTest Player ${TEST_SUFFIX}`);
    });

    it('returns null for non-existent phone', async () => {
      const player = await searchPlayerByPhone('+910000000000');
      expect(player).toBeNull();
    });
  });
});

// ============================================================
// Profile, Stats & Match History Tests
// ============================================================

describe('Player Profile & Stats', () => {
  let profilePlayerId: string;
  let profileTeamId: string;
  let profileTeam2Id: string;
  let opponentTeamId: string;
  let opponentPlayerIds: string[] = [];
  const profileTestUserIds: string[] = [];
  const profileTestMatchIds: string[] = [];

  beforeAll(async () => {
    // Create profile test player
    const [player] = await db
      .insert(users)
      .values({
        firebaseUid: `test-profile-player-${TEST_SUFFIX}`,
        phone: '+919888800001',
        displayName: `Profile Test Player ${TEST_SUFFIX}`,
        playerRole: 'all_rounder',
        battingStyle: 'right_hand',
        bowlingStyle: 'right_arm_fast',
        location: 'Mumbai',
      })
      .returning();
    profilePlayerId = player!.id;
    profileTestUserIds.push(profilePlayerId);

    // Create opponent players
    const oppValues = Array.from({ length: 2 }, (_, i) => ({
      firebaseUid: `test-profile-opp-${i}-${TEST_SUFFIX}`,
      phone: `+91988881${String(i + 10).padStart(4, '0')}`,
      displayName: `Profile Opp ${i + 1} ${TEST_SUFFIX}`,
    }));
    const oppPlayers = await db.insert(users).values(oppValues).returning();
    opponentPlayerIds = oppPlayers.map((p) => p.id);
    profileTestUserIds.push(...opponentPlayerIds);

    // Create teams
    const [team1] = await db
      .insert(teams)
      .values({ name: `Profile Team 1 ${TEST_SUFFIX}`, createdBy: profilePlayerId })
      .returning();
    profileTeamId = team1!.id;

    const [team2] = await db
      .insert(teams)
      .values({ name: `Profile Team 2 ${TEST_SUFFIX}`, createdBy: profilePlayerId })
      .returning();
    profileTeam2Id = team2!.id;

    const [oppTeam] = await db
      .insert(teams)
      .values({ name: `Profile Opponent ${TEST_SUFFIX}`, createdBy: opponentPlayerIds[0]! })
      .returning();
    opponentTeamId = oppTeam!.id;

    // Add player to both teams
    await db.insert(teamRosters).values([
      { teamId: profileTeamId, playerId: profilePlayerId, role: 'player' },
      { teamId: profileTeam2Id, playerId: profilePlayerId, role: 'captain' },
    ]);
    await db.insert(teamRosters).values(
      opponentPlayerIds.map((pid) => ({ teamId: opponentTeamId, playerId: pid, role: 'player' })),
    );

    // Create 3 completed matches with stats
    for (let i = 0; i < 3; i++) {
      const format = i === 2 ? 'ODI' : 'T20';
      const [match] = await db
        .insert(matches)
        .values({
          homeTeamId: profileTeamId,
          awayTeamId: opponentTeamId,
          format,
          totalOvers: format === 'ODI' ? 50 : 20,
          ballTypeId: 1,
          matchDate: `2026-0${6 + i}-15`,
          playersPerSide: 11,
          status: 'completed',
          createdBy: profilePlayerId,
        })
        .returning();
      profileTestMatchIds.push(match!.id);

      await db.insert(matchPlayers).values([
        { matchId: match!.id, teamId: profileTeamId, playerId: profilePlayerId },
        { matchId: match!.id, teamId: opponentTeamId, playerId: opponentPlayerIds[0]! },
      ]);

      // 1st innings
      const [inn1] = await db
        .insert(innings)
        .values({
          matchId: match!.id,
          inningsNumber: 1,
          battingTeamId: profileTeamId,
          bowlingTeamId: opponentTeamId,
          totalRuns: 50 + i * 30,
          totalWickets: 3,
          totalOvers: '10.0',
          isCompleted: true,
        })
        .returning();

      // 2nd innings
      const [inn2] = await db
        .insert(innings)
        .values({
          matchId: match!.id,
          inningsNumber: 2,
          battingTeamId: opponentTeamId,
          bowlingTeamId: profileTeamId,
          totalRuns: 40 + i * 10,
          totalWickets: 5,
          totalOvers: '10.0',
          isCompleted: true,
        })
        .returning();

      // Batting stats
      await db.insert(battingStats).values({
        inningsId: inn1!.id,
        playerId: profilePlayerId,
        battingPosition: 1,
        runsScored: 30 + i * 25,
        ballsFaced: 20 + i * 10,
        fours: 3 + i,
        sixes: 1,
        isNotOut: i === 1,
      });

      // Bowling stats
      await db.insert(bowlingStats).values({
        inningsId: inn2!.id,
        playerId: profilePlayerId,
        oversBowled: '4.0',
        runsConceded: 25 + i * 5,
        wicketsTaken: 1 + i,
      });

      // Match result
      const isWon = i < 2;
      await db.insert(matchResult).values({
        matchId: match!.id,
        winnerTeamId: isWon ? profileTeamId : opponentTeamId,
        resultType: isWon ? 'runs' : 'wickets',
        margin: 10,
        summary: isWon ? 'Won by 10 runs' : 'Lost by 10 wickets',
      });
    }

    // Populate career stats
    await db.transaction(async (tx) => {
      await refreshPlayerAllFormats(tx, profilePlayerId);
    });
  });

  afterAll(async () => {
    // Clean up
    if (profileTestUserIds.length > 0) {
      await db.delete(playerCareerStats).where(inArray(playerCareerStats.playerId, profileTestUserIds));
    }
    if (profileTestMatchIds.length > 0) {
      await db.delete(matchResult).where(inArray(matchResult.matchId, profileTestMatchIds));
      await db.delete(matches).where(inArray(matches.id, profileTestMatchIds));
    }
    await db.delete(teamRosters).where(eq(teamRosters.teamId, profileTeamId));
    await db.delete(teamRosters).where(eq(teamRosters.teamId, profileTeam2Id));
    await db.delete(teamRosters).where(eq(teamRosters.teamId, opponentTeamId));
    await db.delete(teams).where(eq(teams.id, profileTeamId));
    await db.delete(teams).where(eq(teams.id, profileTeam2Id));
    await db.delete(teams).where(eq(teams.id, opponentTeamId));
    if (profileTestUserIds.length > 0) {
      await db.delete(users).where(inArray(users.id, profileTestUserIds));
    }
  });

  describe('getPlayerProfile', () => {
    it('returns player profile with all fields', async () => {
      const profile = await getPlayerProfile(profilePlayerId);
      expect(profile.id).toBe(profilePlayerId);
      expect(profile.displayName).toContain('Profile Test Player');
      expect(profile.playerRole).toBe('all_rounder');
      expect(profile.battingStyle).toBe('right_hand');
      expect(profile.bowlingStyle).toBe('right_arm_fast');
      expect(profile.location).toBe('Mumbai');
    });

    it('returns team affiliations', async () => {
      const profile = await getPlayerProfile(profilePlayerId);
      expect(profile.teams.length).toBe(2);
      const teamNames = profile.teams.map((t) => t.teamName);
      expect(teamNames).toContain(`Profile Team 1 ${TEST_SUFFIX}`);
      expect(teamNames).toContain(`Profile Team 2 ${TEST_SUFFIX}`);
    });

    it('throws 404 for non-existent player', async () => {
      await expectToReject(
        () => getPlayerProfile('00000000-0000-0000-0000-000000000000'),
        'Player not found',
      );
    });

    it('returns empty teams for player with no team', async () => {
      // Create a player without any team membership
      const [loner] = await db
        .insert(users)
        .values({
          firebaseUid: `test-profile-loner-${TEST_SUFFIX}`,
          displayName: `Loner ${TEST_SUFFIX}`,
        })
        .returning();
      profileTestUserIds.push(loner!.id);

      const profile = await getPlayerProfile(loner!.id);
      expect(profile.teams.length).toBe(0);
    });

    it('includes role from team roster', async () => {
      const profile = await getPlayerProfile(profilePlayerId);
      const team2 = profile.teams.find((t) => t.teamName === `Profile Team 2 ${TEST_SUFFIX}`);
      expect(team2?.role).toBe('captain');
    });
  });

  describe('getPlayerStats', () => {
    it('returns stats for "all" format', async () => {
      const stats = await getPlayerStats(profilePlayerId, 'all');
      expect(stats).not.toBeNull();
      expect(stats!.matchesPlayed).toBe(3);
      expect(stats!.totalRuns).toBeGreaterThan(0);
    });

    it('returns stats filtered by T20 format', async () => {
      const stats = await getPlayerStats(profilePlayerId, 'T20');
      expect(stats).not.toBeNull();
      expect(stats!.matchesPlayed).toBe(2); // Only 2 T20 matches
    });

    it('returns null for format with no matches', async () => {
      const stats = await getPlayerStats(profilePlayerId, 'Test');
      expect(stats).toBeNull();
    });

    it('throws 404 for non-existent player', async () => {
      await expectToReject(
        () => getPlayerStats('00000000-0000-0000-0000-000000000000'),
        'Player not found',
      );
    });

    it('includes computed batting and bowling fields', async () => {
      const stats = await getPlayerStats(profilePlayerId, 'all');
      expect(stats).not.toBeNull();
      expect(stats!.wicketsTaken).toBeGreaterThan(0);
      expect(stats!.highestScore).toBeGreaterThan(0);
      if (stats!.battingAverage) {
        expect(Number(stats!.battingAverage)).toBeGreaterThan(0);
      }
    });
  });

  describe('getPlayerMatches', () => {
    it('returns match history with pagination', async () => {
      const result = await getPlayerMatches(profilePlayerId, { page: 1, limit: 2 });
      expect(result.matches.length).toBe(2);
      expect(result.total).toBe(3);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(2);
    });

    it('returns page 2', async () => {
      const result = await getPlayerMatches(profilePlayerId, { page: 2, limit: 2 });
      expect(result.matches.length).toBe(1);
    });

    it('filters by format', async () => {
      const result = await getPlayerMatches(profilePlayerId, { format: 'ODI' });
      expect(result.matches.length).toBe(1);
      expect(result.matches[0]!.format).toBe('ODI');
    });

    it('filters by result - won', async () => {
      const result = await getPlayerMatches(profilePlayerId, { result: 'won' });
      expect(result.matches.length).toBe(2);
      result.matches.forEach((m) => {
        expect(m.playerResult).toBe('won');
      });
    });

    it('filters by result - lost', async () => {
      const result = await getPlayerMatches(profilePlayerId, { result: 'lost' });
      expect(result.matches.length).toBe(1);
      expect(result.matches[0]!.playerResult).toBe('lost');
    });

    it('orders by match date descending', async () => {
      const result = await getPlayerMatches(profilePlayerId);
      expect(result.matches.length).toBe(3);
      const dates = result.matches.map((m) => m.matchDate);
      // Should be descending
      for (let i = 1; i < dates.length; i++) {
        expect(dates[i - 1]! >= dates[i]!).toBe(true);
      }
    });

    it('includes team scores', async () => {
      const result = await getPlayerMatches(profilePlayerId, { limit: 1 });
      const match = result.matches[0]!;
      expect(match.teamScores.length).toBeGreaterThanOrEqual(1);
      expect(match.teamScores[0]!.runs).toBeGreaterThan(0);
    });

    it('includes home and away team info', async () => {
      const result = await getPlayerMatches(profilePlayerId, { limit: 1 });
      const match = result.matches[0]!;
      expect(match.homeTeam.name).toContain('Profile Team');
      expect(match.awayTeam.name).toContain('Profile Opponent');
    });

    it('includes match result info', async () => {
      const result = await getPlayerMatches(profilePlayerId, { limit: 1 });
      const match = result.matches[0]!;
      expect(match.result).not.toBeNull();
      expect(match.result!.resultType).toBeTruthy();
      expect(match.result!.summary).toBeTruthy();
    });

    it('returns empty for player with no matches', async () => {
      // Use the loner player from profile tests
      const loner = profileTestUserIds.find((id) => id !== profilePlayerId && !opponentPlayerIds.includes(id));
      if (loner) {
        const result = await getPlayerMatches(loner);
        expect(result.matches.length).toBe(0);
        expect(result.total).toBe(0);
      }
    });

    it('throws 404 for non-existent player', async () => {
      await expectToReject(
        () => getPlayerMatches('00000000-0000-0000-0000-000000000000'),
        'Player not found',
      );
    });
  });
});
