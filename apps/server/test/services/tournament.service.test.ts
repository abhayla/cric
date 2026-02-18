import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, and, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import {
  tournaments,
  tournamentTeams,
  tournamentGroups,
  tournamentFixtures,
  tournamentStandings,
  tournamentRequests,
} from '../../src/db/schema/tournaments.ts';
import {
  createTournament,
  getTournaments,
  getTournament,
  updateTournament,
  transitionStatus,
  addTeam,
  registerTeam,
  getRequests,
  resolveRequest,
  removeTeam,
  generateFixtures,
  getFixtures,
  editFixture,
  getStandings,
  getLeaderboard,
} from '../../src/services/tournament.service.ts';

const TEST_SUFFIX = Date.now();

// Test user IDs
let organizerUserId: string;
let captainUserId: string;
let randomUserId: string;
const testUserIds: string[] = [];

// Teams: need enough players for playersPerSide validation
const PLAYER_COUNT = 11;
let teamAId: string;
let teamBId: string;
let teamCId: string;
let teamDId: string;
let teamEId: string; // 5th team for knockout bracket tests
const teamIds: string[] = [];

// Tournament IDs for cleanup
let tournamentIds: string[] = [];

/** Helper to try/catch and assert thrown errors — avoids Bun's .toThrow hanging issue */
async function expectToReject(fn: () => Promise<unknown>, msgSubstring?: string) {
  let threw = false;
  let errorMessage = '';
  try {
    await fn();
  } catch (e: unknown) {
    threw = true;
    errorMessage = (e as Error).message ?? '';
  }
  expect(threw).toBe(true);
  if (msgSubstring) {
    expect(errorMessage).toContain(msgSubstring);
  }
}

beforeAll(async () => {
  // Create organizer user
  const [organizer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-tourn-organizer-${TEST_SUFFIX}`,
      phone: '+919876660001',
      displayName: 'Tournament Organizer',
    })
    .returning();
  organizerUserId = organizer!.id;
  testUserIds.push(organizerUserId);

  // Create captain user (for registerTeam tests)
  const [captain] = await db
    .insert(users)
    .values({
      firebaseUid: `test-tourn-captain-${TEST_SUFFIX}`,
      phone: '+919876660002',
      displayName: 'Team Captain',
    })
    .returning();
  captainUserId = captain!.id;
  testUserIds.push(captainUserId);

  // Create random user (for auth denial tests)
  const [random] = await db
    .insert(users)
    .values({
      firebaseUid: `test-tourn-random-${TEST_SUFFIX}`,
      phone: '+919876660003',
      displayName: 'Random User',
    })
    .returning();
  randomUserId = random!.id;
  testUserIds.push(randomUserId);

  // Create 5 teams with 11 players each
  const teamNames = ['Team Alpha', 'Team Beta', 'Team Charlie', 'Team Delta', 'Team Echo'];
  const createdTeams: string[] = [];

  for (let t = 0; t < 5; t++) {
    // Create players for this team
    const playerValues = Array.from({ length: PLAYER_COUNT }, (_, i) => ({
      firebaseUid: `test-tourn-team${t}-player${i}-${TEST_SUFFIX}`,
      phone: `+91987666${String(t * 100 + i + 10).padStart(4, '0')}`,
      displayName: `${teamNames[t]} Player ${i + 1}`,
    }));
    const players = await db.insert(users).values(playerValues).returning();
    const playerIds = players.map((p) => p.id);
    testUserIds.push(...playerIds);

    // Create team — first team owned by captain, rest by organizer
    const ownerId = t === 0 ? captainUserId : organizerUserId;
    const [team] = await db
      .insert(teams)
      .values({ name: `${teamNames[t]} ${TEST_SUFFIX}`, createdBy: ownerId })
      .returning();
    createdTeams.push(team!.id);

    // Add players to roster
    const rosterValues = playerIds.map((playerId, i) => ({
      teamId: team!.id,
      playerId,
      role: i === 0 ? 'captain' : 'player',
    }));
    await db.insert(teamRosters).values(rosterValues);

    // Also add captain user to team A's roster as captain
    if (t === 0) {
      await db.insert(teamRosters).values({
        teamId: team!.id,
        playerId: captainUserId,
        role: 'captain',
      });
    }
  }

  teamAId = createdTeams[0]!;
  teamBId = createdTeams[1]!;
  teamCId = createdTeams[2]!;
  teamDId = createdTeams[3]!;
  teamEId = createdTeams[4]!;
  teamIds.push(...createdTeams);
});

afterAll(async () => {
  // Clean in reverse dependency order
  if (tournamentIds.length > 0) {
    // Fixtures, standings, requests, teams, groups — all cascade from tournament delete
    await db.delete(tournamentFixtures).where(inArray(tournamentFixtures.tournamentId, tournamentIds));
    await db.delete(tournamentStandings).where(inArray(tournamentStandings.tournamentId, tournamentIds));
    await db.delete(tournamentRequests).where(inArray(tournamentRequests.tournamentId, tournamentIds));
    await db.delete(tournamentTeams).where(inArray(tournamentTeams.tournamentId, tournamentIds));
    await db.delete(tournamentGroups).where(inArray(tournamentGroups.tournamentId, tournamentIds));
    await db.delete(tournaments).where(inArray(tournaments.id, tournamentIds));
  }

  // Clean teams
  for (const tid of teamIds) {
    await db.delete(teamRosters).where(eq(teamRosters.teamId, tid));
    await db.delete(teams).where(eq(teams.id, tid));
  }

  // Clean users
  if (testUserIds.length > 0) {
    await db.delete(users).where(inArray(users.id, testUserIds));
  }
});

describe('Tournament Service', () => {
  // ===========================================
  // CRUD
  // ===========================================
  describe('createTournament', () => {
    it('creates tournament with valid input', async () => {
      const t = await createTournament({
        name: 'Test League',
        format: 'round_robin',
        oversPerMatch: 20,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });

      tournamentIds.push(t.id);
      expect(t.name).toBe('Test League');
      expect(t.format).toBe('round_robin');
      expect(t.oversPerMatch).toBe(20);
      expect(t.status).toBe('draft');
      expect(t.pointsWin).toBe(2);
      expect(t.pointsTie).toBe(1);
      expect(t.pointsLoss).toBe(0);
      expect(t.playersPerSide).toBe(11);
    });

    it('trims whitespace from name', async () => {
      const t = await createTournament({
        name: '  Padded Name  ',
        format: 'knockout',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);
      expect(t.name).toBe('Padded Name');
    });

    it('rejects name shorter than 2 chars', async () => {
      await expectToReject(
        () => createTournament({ name: 'X', format: 'round_robin', oversPerMatch: 20, ballTypeId: 1, createdBy: organizerUserId }),
        '2-100 characters',
      );
    });

    it('rejects invalid format', async () => {
      await expectToReject(
        () => createTournament({ name: 'Bad Format', format: 'invalid', oversPerMatch: 20, ballTypeId: 1, createdBy: organizerUserId }),
        'Invalid format',
      );
    });

    it('rejects overs out of range', async () => {
      await expectToReject(
        () => createTournament({ name: 'No Overs', format: 'round_robin', oversPerMatch: 0, ballTypeId: 1, createdBy: organizerUserId }),
        '1 and 50',
      );
      await expectToReject(
        () => createTournament({ name: 'Too Many', format: 'round_robin', oversPerMatch: 51, ballTypeId: 1, createdBy: organizerUserId }),
        '1 and 50',
      );
    });

    it('rejects playersPerSide out of range', async () => {
      await expectToReject(
        () => createTournament({ name: 'Bad PPS', format: 'round_robin', oversPerMatch: 20, ballTypeId: 1, playersPerSide: 1, createdBy: organizerUserId }),
        '2 and 11',
      );
      await expectToReject(
        () => createTournament({ name: 'Bad PPS', format: 'round_robin', oversPerMatch: 20, ballTypeId: 1, playersPerSide: 12, createdBy: organizerUserId }),
        '2 and 11',
      );
    });

    it('accepts all three valid formats', async () => {
      for (const format of ['round_robin', 'knockout', 'group_knockout']) {
        const t = await createTournament({
          name: `Format ${format} ${TEST_SUFFIX}`,
          format,
          oversPerMatch: 20,
          ballTypeId: 1,
          createdBy: organizerUserId,
        });
        tournamentIds.push(t.id);
        expect(t.format).toBe(format);
      }
    });
  });

  // ===========================================
  // getTournaments / getTournament
  // ===========================================
  describe('getTournaments', () => {
    it('returns tournaments for organizer', async () => {
      const result = await getTournaments(organizerUserId);
      expect(result.tournaments.length).toBeGreaterThan(0);
      expect(result.total).toBeGreaterThan(0);
      expect(result.page).toBe(1);
    });

    it('returns empty for user with no tournaments', async () => {
      const result = await getTournaments(randomUserId);
      expect(result.tournaments.length).toBe(0);
    });

    it('filters by status', async () => {
      const result = await getTournaments(organizerUserId, 1, 20, 'draft');
      for (const t of result.tournaments) {
        expect(t.status).toBe('draft');
      }
    });
  });

  describe('getTournament', () => {
    it('returns tournament with teams and groups', async () => {
      const result = await getTournament(tournamentIds[0]!);
      expect(result).not.toBeNull();
      expect(result!.name).toBe('Test League');
      expect(Array.isArray(result!.teams)).toBe(true);
      expect(Array.isArray(result!.groups)).toBe(true);
    });

    it('returns null for non-existent', async () => {
      const result = await getTournament('00000000-0000-0000-0000-000000000000');
      expect(result).toBeNull();
    });
  });

  // ===========================================
  // updateTournament
  // ===========================================
  describe('updateTournament', () => {
    it('updates name', async () => {
      const updated = await updateTournament(tournamentIds[0]!, organizerUserId, { name: 'Renamed League' });
      expect(updated.name).toBe('Renamed League');
    });

    it('rejects empty update', async () => {
      await expectToReject(
        () => updateTournament(tournamentIds[0]!, organizerUserId, {}),
        'No fields to update',
      );
    });

    it('rejects non-organizer', async () => {
      await expectToReject(
        () => updateTournament(tournamentIds[0]!, randomUserId, { name: 'Hacked' }),
        'organizer',
      );
    });

    it('validates name length on update', async () => {
      await expectToReject(
        () => updateTournament(tournamentIds[0]!, organizerUserId, { name: 'X' }),
        '2-100 characters',
      );
    });

    it('validates overs on update', async () => {
      await expectToReject(
        () => updateTournament(tournamentIds[0]!, organizerUserId, { oversPerMatch: 0 }),
        '1 and 50',
      );
    });
  });

  // ===========================================
  // Team Management: addTeam, removeTeam
  // ===========================================
  describe('addTeam', () => {
    it('adds team to tournament', async () => {
      const entry = await addTeam(tournamentIds[0]!, organizerUserId, teamAId);
      expect(entry.teamId).toBe(teamAId);
      expect(entry.teamName).toBeDefined();
    });

    it('adds second team', async () => {
      const entry = await addTeam(tournamentIds[0]!, organizerUserId, teamBId);
      expect(entry.teamId).toBe(teamBId);
    });

    it('rejects duplicate team', async () => {
      await expectToReject(
        () => addTeam(tournamentIds[0]!, organizerUserId, teamAId),
        'already in this tournament',
      );
    });

    it('rejects non-organizer', async () => {
      await expectToReject(
        () => addTeam(tournamentIds[0]!, randomUserId, teamCId),
        'organizer',
      );
    });

    it('initializes standings for added team', async () => {
      const standings = await getStandings(tournamentIds[0]!);
      const teamAStanding = standings.standings.find((s) => s.teamId === teamAId);
      expect(teamAStanding).toBeDefined();
      expect(teamAStanding!.played).toBe(0);
      expect(teamAStanding!.won).toBe(0);
      expect(teamAStanding!.points).toBe(0);
    });
  });

  describe('removeTeam', () => {
    it('removes team from tournament', async () => {
      // Add team C first, then remove
      await addTeam(tournamentIds[0]!, organizerUserId, teamCId);
      await removeTeam(tournamentIds[0]!, organizerUserId, teamCId);

      // Verify standings also removed
      const standings = await getStandings(tournamentIds[0]!);
      const teamCStanding = standings.standings.find((s) => s.teamId === teamCId);
      expect(teamCStanding).toBeUndefined();
    });

    it('rejects non-existent team removal', async () => {
      await expectToReject(
        () => removeTeam(tournamentIds[0]!, organizerUserId, '00000000-0000-0000-0000-000000000000'),
        'not found',
      );
    });

    it('rejects non-organizer removal', async () => {
      await expectToReject(
        () => removeTeam(tournamentIds[0]!, randomUserId, teamAId),
        'organizer',
      );
    });
  });

  // ===========================================
  // Registration flow: registerTeam, getRequests, resolveRequest
  // ===========================================
  describe('registerTeam', () => {
    let registrationTournamentId: string;

    beforeAll(async () => {
      // Create a tournament in registration status
      const t = await createTournament({
        name: 'Registration Test',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      registrationTournamentId = t.id;
      tournamentIds.push(t.id);

      // Transition to registration
      await db.update(tournaments).set({ status: 'registration' }).where(eq(tournaments.id, t.id));
    });

    it('captain can register team', async () => {
      // captainUserId is owner of teamA and has captain role
      const request = await registerTeam(registrationTournamentId, captainUserId, teamAId);
      expect(request.status).toBe('pending');
      expect(request.teamId).toBe(teamAId);
      expect(request.teamName).toBeDefined();
    });

    it('rejects duplicate registration', async () => {
      await expectToReject(
        () => registerTeam(registrationTournamentId, captainUserId, teamAId),
        'already has a',
      );
    });

    it('rejects non-captain/owner', async () => {
      await expectToReject(
        () => registerTeam(registrationTournamentId, randomUserId, teamBId),
        'captain',
      );
    });

    it('rejects when tournament is not in registration status', async () => {
      await expectToReject(
        () => registerTeam(tournamentIds[0]!, captainUserId, teamCId), // tournamentIds[0] is 'draft'
        'not accepting registrations',
      );
    });
  });

  describe('getRequests', () => {
    it('organizer can view requests', async () => {
      // Use the registration tournament from above
      const regTournId = tournamentIds[tournamentIds.length - 1]!;
      const requests = await getRequests(regTournId, organizerUserId);
      expect(requests.length).toBeGreaterThan(0);
      expect(requests[0]!.teamName).toBeDefined();
      expect(requests[0]!.rosterCount).toBeGreaterThanOrEqual(11);
    });

    it('filters by status', async () => {
      const regTournId = tournamentIds[tournamentIds.length - 1]!;
      const pending = await getRequests(regTournId, organizerUserId, 'pending');
      for (const r of pending) {
        expect(r.status).toBe('pending');
      }
    });

    it('rejects non-organizer', async () => {
      const regTournId = tournamentIds[tournamentIds.length - 1]!;
      await expectToReject(
        () => getRequests(regTournId, randomUserId),
        'organizer',
      );
    });
  });

  describe('resolveRequest', () => {
    it('approves request and adds team + standings', async () => {
      const regTournId = tournamentIds[tournamentIds.length - 1]!;
      const requests = await getRequests(regTournId, organizerUserId, 'pending');
      const request = requests[0]!;

      const resolved = await resolveRequest(regTournId, organizerUserId, request.id, 'approved');
      expect(resolved.status).toBe('approved');
      expect(resolved.resolvedAt).toBeDefined();

      // Verify team is now in tournament
      const detail = await getTournament(regTournId);
      const teamEntry = detail!.teams.find((t: { teamId: string }) => t.teamId === teamAId);
      expect(teamEntry).toBeDefined();

      // Verify standings initialized
      const standings = await getStandings(regTournId);
      const teamStanding = standings.standings.find((s) => s.teamId === teamAId);
      expect(teamStanding).toBeDefined();
    });

    it('rejects already-resolved request', async () => {
      const regTournId = tournamentIds[tournamentIds.length - 1]!;
      const requests = await getRequests(regTournId, organizerUserId, 'approved');
      if (requests.length > 0) {
        await expectToReject(
          () => resolveRequest(regTournId, organizerUserId, requests[0]!.id, 'approved'),
          'not in pending',
        );
      }
    });
  });

  // ===========================================
  // Status Transitions
  // ===========================================
  describe('transitionStatus', () => {
    it('transitions draft → registration', async () => {
      // Use a fresh tournament
      const t = await createTournament({
        name: 'Status Test',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      const updated = await transitionStatus(t.id, organizerUserId, 'registration');
      expect(updated.status).toBe('registration');
    });

    it('rejects invalid transition (draft → live)', async () => {
      const t = await createTournament({
        name: 'Bad Transition',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      await expectToReject(
        () => transitionStatus(t.id, organizerUserId, 'live'),
        'Cannot transition',
      );
    });

    it('rejects registration → live without teams', async () => {
      const t = await createTournament({
        name: 'No Teams',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);
      await db.update(tournaments).set({ status: 'registration' }).where(eq(tournaments.id, t.id));

      await expectToReject(
        () => transitionStatus(t.id, organizerUserId, 'live'),
        'at least 2 teams',
      );
    });

    it('rejects registration → live without fixtures', async () => {
      const t = await createTournament({
        name: 'No Fixtures',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      // Add 2 teams
      await addTeam(t.id, organizerUserId, teamCId);
      await addTeam(t.id, organizerUserId, teamDId);

      await db.update(tournaments).set({ status: 'registration' }).where(eq(tournaments.id, t.id));

      await expectToReject(
        () => transitionStatus(t.id, organizerUserId, 'live'),
        'Fixtures must be generated',
      );
    });

    it('allows registration → live with teams + fixtures', async () => {
      const t = await createTournament({
        name: 'Go Live',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId);
      await addTeam(t.id, organizerUserId, teamBId);
      await generateFixtures(t.id, organizerUserId);

      await db.update(tournaments).set({ status: 'registration' }).where(eq(tournaments.id, t.id));

      const updated = await transitionStatus(t.id, organizerUserId, 'live');
      expect(updated.status).toBe('live');
    });

    it('transitions live → completed', async () => {
      // Use the tournament just set to 'live'
      const liveTournId = tournamentIds[tournamentIds.length - 1]!;
      const updated = await transitionStatus(liveTournId, organizerUserId, 'completed');
      expect(updated.status).toBe('completed');
    });

    it('rejects non-organizer', async () => {
      const t = await createTournament({
        name: 'Auth Test',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      await expectToReject(
        () => transitionStatus(t.id, randomUserId, 'registration'),
        'organizer',
      );
    });
  });

  // ===========================================
  // Fixture Generation
  // ===========================================
  describe('generateFixtures — round_robin', () => {
    let rrTournamentId: string;

    beforeAll(async () => {
      const t = await createTournament({
        name: 'RR Fixture Test',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      rrTournamentId = t.id;
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId);
      await addTeam(t.id, organizerUserId, teamBId);
      await addTeam(t.id, organizerUserId, teamCId);
    });

    it('generates correct number of fixtures (n choose 2)', async () => {
      const result = await generateFixtures(rrTournamentId, organizerUserId);
      // 3 teams → 3 fixtures (3 choose 2)
      expect(result.totalFixtures).toBe(3);
      expect(result.fixtures.length).toBe(3);
    });

    it('all fixtures are roundType=group, roundNumber=1', async () => {
      const fixtures = await getFixtures(rrTournamentId);
      for (const f of fixtures) {
        expect(f.roundType).toBe('group');
        expect(f.roundNumber).toBe(1);
      }
    });

    it('each pair plays exactly once', async () => {
      const fixtures = await getFixtures(rrTournamentId);
      const pairs = new Set<string>();
      for (const f of fixtures) {
        const key = [f.homeTeamId, f.awayTeamId].sort().join('-');
        expect(pairs.has(key)).toBe(false);
        pairs.add(key);
      }
      expect(pairs.size).toBe(3);
    });

    it('fixtures have team names', async () => {
      const fixtures = await getFixtures(rrTournamentId);
      for (const f of fixtures) {
        expect(f.homeTeamName).toBeTruthy();
        expect(f.awayTeamName).toBeTruthy();
      }
    });

    it('rejects duplicate generation', async () => {
      await expectToReject(
        () => generateFixtures(rrTournamentId, organizerUserId),
        'already generated',
      );
    });
  });

  describe('generateFixtures — knockout (2 teams)', () => {
    let koTournamentId: string;

    beforeAll(async () => {
      const t = await createTournament({
        name: 'KO 2 Teams',
        format: 'knockout',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      koTournamentId = t.id;
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId, null, 1);
      await addTeam(t.id, organizerUserId, teamBId, null, 2);
    });

    it('generates 1 final', async () => {
      const result = await generateFixtures(koTournamentId, organizerUserId);
      expect(result.totalFixtures).toBe(1);
      expect(result.fixtures[0]!.roundType).toBe('final');
    });
  });

  describe('generateFixtures — knockout (4 teams)', () => {
    let koTournamentId: string;

    beforeAll(async () => {
      const t = await createTournament({
        name: 'KO 4 Teams',
        format: 'knockout',
        oversPerMatch: 10,
        ballTypeId: 1,
        hasThirdPlaceMatch: true,
        createdBy: organizerUserId,
      });
      koTournamentId = t.id;
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId, null, 1);
      await addTeam(t.id, organizerUserId, teamBId, null, 2);
      await addTeam(t.id, organizerUserId, teamCId, null, 3);
      await addTeam(t.id, organizerUserId, teamDId, null, 4);
    });

    it('generates SF + Final + 3rd place = 4 fixtures', async () => {
      const result = await generateFixtures(koTournamentId, organizerUserId);
      expect(result.totalFixtures).toBe(4);
    });

    it('has 2 semi-finals in round 1', async () => {
      const fixtures = await getFixtures(koTournamentId, 'semi_final');
      expect(fixtures.length).toBe(2);
      for (const f of fixtures) {
        expect(f.roundNumber).toBe(1);
      }
    });

    it('has 1 final in round 2', async () => {
      const fixtures = await getFixtures(koTournamentId, 'final');
      expect(fixtures.length).toBe(1);
      expect(fixtures[0]!.roundNumber).toBe(2);
    });

    it('has 1 third-place match in round 2', async () => {
      const fixtures = await getFixtures(koTournamentId, 'third_place');
      expect(fixtures.length).toBe(1);
      expect(fixtures[0]!.roundNumber).toBe(2);
    });

    it('seed 1 vs seed 4 in SF1 (seeded bracket)', async () => {
      const semis = await getFixtures(koTournamentId, 'semi_final');
      const sf1 = semis.find((f) => f.fixtureOrder === 1)!;
      // Seed 1 = teamA (home), seed 4 = teamD (away)
      expect(sf1.homeTeamId).toBe(teamAId);
      expect(sf1.awayTeamId).toBe(teamDId);
    });
  });

  describe('generateFixtures — knockout (5 teams)', () => {
    let koTournamentId: string;

    beforeAll(async () => {
      const t = await createTournament({
        name: 'KO 5 Teams',
        format: 'knockout',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      koTournamentId = t.id;
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId, null, 1);
      await addTeam(t.id, organizerUserId, teamBId, null, 2);
      await addTeam(t.id, organizerUserId, teamCId, null, 3);
      await addTeam(t.id, organizerUserId, teamDId, null, 4);
      await addTeam(t.id, organizerUserId, teamEId, null, 5);
    });

    it('generates QF + SF + Final for 5 teams', async () => {
      const result = await generateFixtures(koTournamentId, organizerUserId);
      // 5 teams: QFs (4 teams paired, 1 gets bye via duplicate idx) + SFs + Final
      expect(result.totalFixtures).toBeGreaterThanOrEqual(4);

      const fixtures = await getFixtures(koTournamentId);
      const qfs = fixtures.filter((f) => f.roundType === 'quarter_final');
      const sfs = fixtures.filter((f) => f.roundType === 'semi_final');
      const finals = fixtures.filter((f) => f.roundType === 'final');

      expect(qfs.length).toBeGreaterThanOrEqual(2);
      expect(sfs.length).toBe(2);
      expect(finals.length).toBe(1);
    });
  });

  describe('generateFixtures — group_knockout', () => {
    let gkTournamentId: string;

    beforeAll(async () => {
      const t = await createTournament({
        name: 'GK Fixture Test',
        format: 'group_knockout',
        oversPerMatch: 10,
        ballTypeId: 1,
        numGroups: 2,
        qualifyPerGroup: 1,
        createdBy: organizerUserId,
      });
      gkTournamentId = t.id;
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId, 'A', 1);
      await addTeam(t.id, organizerUserId, teamBId, 'A', 2);
      await addTeam(t.id, organizerUserId, teamCId, 'B', 1);
      await addTeam(t.id, organizerUserId, teamDId, 'B', 2);
    });

    it('generates group stage + knockout stage', async () => {
      const result = await generateFixtures(gkTournamentId, organizerUserId);
      expect(result.totalFixtures).toBeGreaterThanOrEqual(3);

      const fixtures = await getFixtures(gkTournamentId);
      const groupFixtures = fixtures.filter((f) => f.roundType === 'group');
      const knockoutFixtures = fixtures.filter((f) => f.roundType !== 'group');

      // 2 teams per group × 2 groups = 2 group fixtures (1 per group)
      expect(groupFixtures.length).toBe(2);
      // 1 qualifier per group = 2 teams → 1 final
      expect(knockoutFixtures.length).toBeGreaterThanOrEqual(1);
    });

    it('group fixtures have groupName', async () => {
      const fixtures = await getFixtures(gkTournamentId, 'group');
      for (const f of fixtures) {
        expect(f.groupName).toBeTruthy();
      }
    });

    it('can filter fixtures by groupName', async () => {
      const groupA = await getFixtures(gkTournamentId, 'group', 'A');
      expect(groupA.length).toBe(1);
      expect(groupA[0]!.groupName).toBe('A');
    });
  });

  // ===========================================
  // editFixture
  // ===========================================
  describe('editFixture', () => {
    it('updates venue and schedule', async () => {
      const fixtures = await getFixtures(tournamentIds[0]!);
      if (fixtures.length > 0) {
        const result = await editFixture(tournamentIds[0]!, organizerUserId, fixtures[0]!.id, {
          venue: 'Eden Gardens',
          scheduledDate: '2026-04-01',
          scheduledTime: '14:00',
          estimatedDurationMinutes: 180,
        });
        expect(result.fixture.venue).toBe('Eden Gardens');
        expect(result.scheduleWarning).toBeNull();
      }
    });

    it('detects schedule conflict', async () => {
      // First, get the round-robin tournament with fixtures
      // Set up two fixtures at the same venue/date/time
      const rrTournId = tournamentIds.find((id) => id !== tournamentIds[0]);
      if (!rrTournId) return;

      const fixtures = await getFixtures(rrTournId);
      if (fixtures.length >= 2) {
        // Set first fixture to a venue/time
        await editFixture(rrTournId, organizerUserId, fixtures[0]!.id, {
          venue: 'Wankhede',
          scheduledDate: '2026-05-01',
          scheduledTime: '10:00',
          estimatedDurationMinutes: 180,
        });

        // Set second fixture to same venue/date with overlapping time
        const result = await editFixture(rrTournId, organizerUserId, fixtures[1]!.id, {
          venue: 'Wankhede',
          scheduledDate: '2026-05-01',
          scheduledTime: '11:00',
          estimatedDurationMinutes: 180,
        });
        expect(result.scheduleWarning).toBeTruthy();
        expect(result.scheduleWarning).toContain('Wankhede');
      }
    });

    it('rejects empty update', async () => {
      const fixtures = await getFixtures(tournamentIds[0]!);
      if (fixtures.length > 0) {
        await expectToReject(
          () => editFixture(tournamentIds[0]!, organizerUserId, fixtures[0]!.id, {}),
          'No fields',
        );
      }
    });
  });

  // ===========================================
  // Standings
  // ===========================================
  describe('getStandings', () => {
    it('returns standings with team names', async () => {
      const result = await getStandings(tournamentIds[0]!);
      expect(Array.isArray(result.standings)).toBe(true);
      for (const s of result.standings) {
        expect(s.teamName).toBeTruthy();
        expect(s.played).toBeDefined();
        expect(s.points).toBeDefined();
        expect(s.nrr).toBeDefined();
      }
    });

    it('returns distinct group names', async () => {
      const result = await getStandings(tournamentIds[0]!);
      expect(Array.isArray(result.groups)).toBe(true);
    });
  });

  // ===========================================
  // Leaderboard
  // ===========================================
  describe('getLeaderboard', () => {
    it('returns empty leaderboard for tournament with no matches', async () => {
      const result = await getLeaderboard(tournamentIds[0]!, 'runs');
      expect(result.category).toBe('runs');
      expect(result.leaderboard.length).toBe(0);
    });

    it('returns empty for wickets category', async () => {
      const result = await getLeaderboard(tournamentIds[0]!, 'wickets');
      expect(result.category).toBe('wickets');
      expect(result.leaderboard.length).toBe(0);
    });

    it('returns empty for unknown category', async () => {
      const result = await getLeaderboard(tournamentIds[0]!, 'fielding');
      expect(result.category).toBe('fielding');
      expect(result.leaderboard.length).toBe(0);
    });
  });

  // ===========================================
  // Edge cases
  // ===========================================
  describe('edge cases', () => {
    it('rejects adding team to live tournament', async () => {
      // Create and transition to live
      const t = await createTournament({
        name: 'Live Block',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);

      await addTeam(t.id, organizerUserId, teamAId);
      await addTeam(t.id, organizerUserId, teamBId);
      await generateFixtures(t.id, organizerUserId);
      await db.update(tournaments).set({ status: 'live' }).where(eq(tournaments.id, t.id));

      await expectToReject(
        () => addTeam(t.id, organizerUserId, teamCId),
        'after tournament is live',
      );
    });

    it('rejects removing team from live tournament', async () => {
      const liveTournId = tournamentIds[tournamentIds.length - 1]!;
      await expectToReject(
        () => removeTeam(liveTournId, organizerUserId, teamAId),
        'after tournament is live',
      );
    });

    it('rejects updating live tournament', async () => {
      const liveTournId = tournamentIds[tournamentIds.length - 1]!;
      await expectToReject(
        () => updateTournament(liveTournId, organizerUserId, { name: 'Changed' }),
        'draft or registration',
      );
    });

    it('generateFixtures rejects with less than 2 teams', async () => {
      const t = await createTournament({
        name: 'One Team',
        format: 'round_robin',
        oversPerMatch: 10,
        ballTypeId: 1,
        createdBy: organizerUserId,
      });
      tournamentIds.push(t.id);
      await addTeam(t.id, organizerUserId, teamAId);

      await expectToReject(
        () => generateFixtures(t.id, organizerUserId),
        'At least 2 teams',
      );
    });

    it('generateFixtures rejects non-organizer', async () => {
      await expectToReject(
        () => generateFixtures(tournamentIds[0]!, randomUserId),
        'organizer',
      );
    });
  });
});
