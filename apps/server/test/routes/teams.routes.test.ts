import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { teamRoutes } from '../../src/routes/v1/teams.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';

const app = new Elysia().use(errorHandler).use(teamRoutes);

const BASE = 'http://localhost/api/v1/teams';
const TEST_SUFFIX = Date.now();
const JSON_HEADERS = { 'Content-Type': 'application/json' };

// The auth middleware in test mode returns firebaseUid: 'test-user-e2e-001'
// We need a user record with that UID in the DB.
let testUserId: string;
let testTeamId: string;
let playerUserId: string;

beforeAll(async () => {
  // Ensure test user exists (auth middleware returns this UID in test mode)
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

  // Create a second user to add to roster
  const [player] = await db
    .insert(users)
    .values({
      firebaseUid: `test-route-player-${TEST_SUFFIX}`,
      phone: '+919876590001',
      displayName: `Route Player ${TEST_SUFFIX}`,
    })
    .returning();
  playerUserId = player!.id;

  // Create a team for GET/PUT/DELETE tests
  const [team] = await db
    .insert(teams)
    .values({
      name: `Route Team ${TEST_SUFFIX}`,
      createdBy: testUserId,
    })
    .returning();
  testTeamId = team!.id;
});

afterAll(async () => {
  // Clean up in reverse dependency order
  // First find all teams created by test user
  const teamIds = await db
    .select({ id: teams.id })
    .from(teams)
    .where(eq(teams.createdBy, testUserId))
    .then((r) => r.map((t) => t.id));

  if (teamIds.length > 0) {
    // Remove match_players referencing these teams (from other test suites too)
    const { matchPlayers, matchResult, matches } = await import('../../src/db/schema/matches.ts');
    const { innings } = await import('../../src/db/schema/innings.ts');

    // Find matches referencing these teams
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

    // Now clean rosters and teams
    for (const tid of teamIds) {
      await db.delete(teamRosters).where(eq(teamRosters.teamId, tid));
    }
    await db.delete(teams).where(inArray(teams.id, teamIds));
  }

  if (playerUserId) {
    await db.delete(users).where(eq(users.id, playerUserId));
  }
});

describe('Teams Routes', () => {
  // ---- POST / ----
  describe('POST /', () => {
    it('creates a team with valid data -> 201', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({ name: `Valid Team ${TEST_SUFFIX}` }),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.team).toBeDefined();
      expect(body.team.id).toBeTruthy();
      expect(body.team.name).toBe(`Valid Team ${TEST_SUFFIX}`);

      // Clean up created team
      await db.delete(teams).where(eq(teams.id, body.team.id));
    });

    it('rejects missing name -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({}),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects name too short (1 char) -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({ name: 'A' }),
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
    it('returns teams list -> 200', async () => {
      const res = await app.handle(new Request(BASE));

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.teams).toBeDefined();
      expect(body.total).toBeDefined();
      expect(body.page).toBeDefined();
    });
  });

  // ---- GET /:id ----
  describe('GET /:id', () => {
    it('returns team by id -> 200', async () => {
      const res = await app.handle(new Request(`${BASE}/${testTeamId}`));

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.team).toBeDefined();
      expect(body.team.id).toBe(testTeamId);
    });

    it('returns 404 for unknown UUID', async () => {
      const res = await app.handle(
        new Request(`${BASE}/00000000-0000-0000-0000-000000000000`),
      );

      expect(res.status).toBe(404);
    });
  });

  // ---- PUT /:id ----
  describe('PUT /:id', () => {
    it('updates team name -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testTeamId}`, {
          method: 'PUT',
          headers: JSON_HEADERS,
          body: JSON.stringify({ name: `Updated Team ${TEST_SUFFIX}` }),
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.team).toBeDefined();
    });
  });

  // ---- DELETE /:id ----
  describe('DELETE /:id', () => {
    it('deletes team -> 200 with message', async () => {
      // Create a disposable team for deletion
      const [disposable] = await db
        .insert(teams)
        .values({ name: `Disposable ${TEST_SUFFIX}`, createdBy: testUserId })
        .returning();

      const res = await app.handle(
        new Request(`${BASE}/${disposable!.id}`, { method: 'DELETE' }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.message).toBeDefined();
    });
  });

  // ---- POST /:id/players ----
  describe('POST /:id/players', () => {
    it('adds player to team -> 201', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testTeamId}/players`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            playerId: playerUserId,
            jerseyNumber: 10,
            role: 'player',
          }),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.rosterEntry).toBeDefined();
    });

    it('rejects invalid jerseyNumber (-1) -> 400', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testTeamId}/players`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            playerId: '00000000-0000-0000-0000-000000000099',
            jerseyNumber: -1,
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // ---- DELETE /:id/players/:pid ----
  describe('DELETE /:id/players/:pid', () => {
    it('removes player from team -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testTeamId}/players/${playerUserId}`, {
          method: 'DELETE',
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.message).toBeDefined();
    });
  });
});
