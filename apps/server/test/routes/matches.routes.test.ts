import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { playerCareerStats } from '../../src/db/schema/stats.ts';
import { matchRoutes } from '../../src/routes/v1/matches.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';

const app = new Elysia().use(errorHandler).use(matchRoutes);

const BASE = 'http://localhost/api/v1/matches';
const TEST_SUFFIX = Date.now();
const JSON_HEADERS = { 'Content-Type': 'application/json' };

let testUserId: string;
let homeTeamId: string;
let awayTeamId: string;
let testMatchId: string;
const testUserIds: string[] = [];
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

const PLAYER_COUNT = 11;

beforeAll(async () => {
  // Ensure test user (auth middleware returns firebaseUid 'test-user-e2e-001')
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.firebaseUid, 'test-user-e2e-001'))
    .limit(1);

  if (existing[0]) {
    testUserId = existing[0].id;
  } else {
    const [u] = await db
      .insert(users)
      .values({
        firebaseUid: 'test-user-e2e-001',
        phone: '+919999900001',
        displayName: 'Route Test User',
      })
      .returning();
    testUserId = u!.id;
  }
  testUserIds.push(testUserId);

  // Create home team players
  const homeValues = Array.from({ length: PLAYER_COUNT }, (_, i) => ({
    firebaseUid: `test-mroute-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987670${String(i + 10).padStart(4, '0')}`,
    displayName: `MRoute Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away team players
  const awayValues = Array.from({ length: PLAYER_COUNT }, (_, i) => ({
    firebaseUid: `test-mroute-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987671${String(i + 10).padStart(4, '0')}`,
    displayName: `MRoute Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `MRoute Home ${TEST_SUFFIX}`, createdBy: testUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `MRoute Away ${TEST_SUFFIX}`, createdBy: testUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add players to rosters
  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Create a test match for GET/PUT tests
  const [match] = await db
    .insert(matches)
    .values({
      homeTeamId,
      awayTeamId,
      format: 'T20',
      totalOvers: 20,
      ballTypeId: 1,
      matchDate: '2026-06-15',
      status: 'setup',
      createdBy: testUserId,
      scorerId: testUserId,
    })
    .returning();
  testMatchId = match!.id;
});

afterAll(async () => {
  // Clean matches created by test user
  const matchIds = await db
    .select({ id: matches.id })
    .from(matches)
    .where(eq(matches.createdBy, testUserId))
    .then((r) => r.map((m) => m.id));

  if (matchIds.length > 0) {
    await db.delete(matchResult).where(inArray(matchResult.matchId, matchIds));
    await db.delete(innings).where(inArray(innings.matchId, matchIds));
    await db.delete(matchPlayers).where(inArray(matchPlayers.matchId, matchIds));
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));

  // Delete created users (not the shared test-user-e2e-001)
  const createdUserIds = testUserIds.filter((id) => id !== testUserId);
  if (createdUserIds.length > 0) {
    await db.delete(playerCareerStats).where(inArray(playerCareerStats.playerId, createdUserIds));
    await db.delete(users).where(inArray(users.id, createdUserIds));
  }
});

describe('Matches Routes', () => {
  // ---- POST / ----
  describe('POST /', () => {
    it('creates match with valid data -> 201', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            homeTeamId,
            awayTeamId,
            format: 'T20',
            totalOvers: 20,
            ballTypeId: 1,
            matchDate: '2026-07-01',
          }),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.match).toBeDefined();
      expect(body.match.id).toBeTruthy();
      expect(body.match.status).toBe('setup');
    });

    it('rejects missing homeTeamId -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            awayTeamId,
            format: 'T20',
            totalOvers: 20,
            ballTypeId: 1,
            matchDate: '2026-07-01',
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects invalid format -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            homeTeamId,
            awayTeamId,
            format: 'INVALID',
            totalOvers: 20,
            ballTypeId: 1,
            matchDate: '2026-07-01',
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects totalOvers: 0 -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            homeTeamId,
            awayTeamId,
            format: 'T20',
            totalOvers: 0,
            ballTypeId: 1,
            matchDate: '2026-07-01',
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // ---- GET / ----
  describe('GET /', () => {
    it('returns matches list -> 200', async () => {
      const res = await app.handle(new Request(BASE));

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toBeDefined();
    });
  });

  // ---- GET /:id ----
  describe('GET /:id', () => {
    it('returns match by id -> 200', async () => {
      const res = await app.handle(new Request(`${BASE}/${testMatchId}`));

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.match).toBeDefined();
      expect(body.match.id).toBe(testMatchId);
    });

    it('returns 404 for unknown UUID', async () => {
      const res = await app.handle(
        new Request(`${BASE}/00000000-0000-0000-0000-000000000000`),
      );

      expect(res.status).toBe(404);
    });
  });

  // ---- POST /:id/playing-xi ----
  describe('POST /:id/playing-xi', () => {
    it('sets playing XI -> 201', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testMatchId}/playing-xi`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            teamId: homeTeamId,
            playerIds: homePlayerIds,
            captainId: homePlayerIds[0],
            keeperId: homePlayerIds[1],
          }),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.players).toBeDefined();
    });
  });

  // ---- PUT /:id/toss ----
  describe('PUT /:id/toss', () => {
    it('records toss with valid data -> 200', async () => {
      // First set away playing XI so match is ready for toss
      await app.handle(
        new Request(`${BASE}/${testMatchId}/playing-xi`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            teamId: awayTeamId,
            playerIds: awayPlayerIds,
            captainId: awayPlayerIds[0],
            keeperId: awayPlayerIds[1],
          }),
        }),
      );

      const res = await app.handle(
        new Request(`${BASE}/${testMatchId}/toss`, {
          method: 'PUT',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            winnerId: homeTeamId,
            decision: 'bat',
            openingStrikerId: homePlayerIds[0],
            openingNonStrikerId: homePlayerIds[1],
            openingBowlerId: awayPlayerIds[0],
          }),
        }),
      );

      expect(res.status).toBe(200);
    });

    it('rejects invalid toss decision -> 400', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testMatchId}/toss`, {
          method: 'PUT',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            winnerId: homeTeamId,
            decision: 'swim',
            openingStrikerId: homePlayerIds[0],
            openingNonStrikerId: homePlayerIds[1],
            openingBowlerId: awayPlayerIds[0],
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });
});
