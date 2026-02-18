import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { playerCareerStats } from '../../src/db/schema/stats.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import { scoringRoutes } from '../../src/routes/v1/scoring.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';

const app = new Elysia().use(errorHandler).use(scoringRoutes);

const BASE = 'http://localhost/api/v1/matches';
const TEST_SUFFIX = Date.now();
const JSON_HEADERS = { 'Content-Type': 'application/json' };
const PLAYERS_PER_SIDE = 11;

let testUserId: string;
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
const testUserIds: string[] = [];

// Live match state
let liveMatchId: string;
let liveInningsId: string;
let deliveryId: string;

// Second match for declare/reopen after abandon
let secondMatchId: string;
let secondInningsId: string;

/** Create a live match using the service layer */
async function createLiveMatch() {
  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers: 20,
    ballTypeId: 1,
    matchDate: '2026-06-20',
    createdBy: testUserId,
  });

  await setPlayingXI(match.id, {
    teamId: homeTeamId,
    playerIds: homePlayerIds.slice(0, PLAYERS_PER_SIDE),
    captainId: homePlayerIds[0]!,
    keeperId: homePlayerIds[1]!,
    userId: testUserId,
  });

  await setPlayingXI(match.id, {
    teamId: awayTeamId,
    playerIds: awayPlayerIds.slice(0, PLAYERS_PER_SIDE),
    captainId: awayPlayerIds[0]!,
    keeperId: awayPlayerIds[1]!,
    userId: testUserId,
  });

  const tossResult = await recordToss(match.id, {
    winnerId: homeTeamId,
    decision: 'bat',
    openingStrikerId: homePlayerIds[0]!,
    openingNonStrikerId: homePlayerIds[1]!,
    openingBowlerId: awayPlayerIds[0]!,
    userId: testUserId,
  });

  return {
    matchId: match.id,
    inningsId: tossResult.innings.id,
  };
}

/** Build a valid dot ball delivery body */
function dotBallBody(inningsId: string) {
  return {
    inningsId,
    overNumber: 0,
    ballNumber: 1,
    strikerId: homePlayerIds[0]!,
    nonStrikerId: homePlayerIds[1]!,
    bowlerId: awayPlayerIds[0]!,
    runsFromBat: 0,
    isWide: false,
    isNoBall: false,
    isBye: false,
    isLegBye: false,
    wideRuns: 0,
    noBallRuns: 0,
    byeRuns: 0,
    legByeRuns: 0,
    isWicket: false,
    isBoundaryFour: false,
    isBoundarySix: false,
  };
}

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
  const homeValues = Array.from({ length: PLAYERS_PER_SIDE }, (_, i) => ({
    firebaseUid: `test-sroute-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987680${String(i + 10).padStart(4, '0')}`,
    displayName: `SRoute Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away team players
  const awayValues = Array.from({ length: PLAYERS_PER_SIDE }, (_, i) => ({
    firebaseUid: `test-sroute-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987681${String(i + 10).padStart(4, '0')}`,
    displayName: `SRoute Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `SRoute Home ${TEST_SUFFIX}`, createdBy: testUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `SRoute Away ${TEST_SUFFIX}`, createdBy: testUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add players to rosters
  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Create the primary live match
  const live1 = await createLiveMatch();
  liveMatchId = live1.matchId;
  liveInningsId = live1.inningsId;

  // Create a second live match for declare/reopen tests
  const live2 = await createLiveMatch();
  secondMatchId = live2.matchId;
  secondInningsId = live2.inningsId;
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
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));

  const createdUserIds = testUserIds.filter((id) => id !== testUserId);
  if (createdUserIds.length > 0) {
    await db.delete(playerCareerStats).where(inArray(playerCareerStats.playerId, createdUserIds));
    await db.delete(users).where(inArray(users.id, createdUserIds));
  }
});

describe('Scoring Routes', () => {
  // ---- POST /:id/deliveries ----
  describe('POST /:id/deliveries', () => {
    it('records a valid dot ball -> 201', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(dotBallBody(liveInningsId)),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.delivery).toBeDefined();
      expect(body.delivery.id).toBeTruthy();
      deliveryId = body.delivery.id;
    });

    it('rejects missing strikerId -> 400', async () => {
      const deliveryBody = dotBallBody(liveInningsId);
      delete (deliveryBody as any).strikerId;

      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(deliveryBody),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects runsFromBat: -1 -> 400', async () => {
      const deliveryBody = { ...dotBallBody(liveInningsId), runsFromBat: -1 };

      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(deliveryBody),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('records a delivery with wicket -> 201', async () => {
      // Load a dismissal type ID
      const { dismissalTypes } = await import('../../src/db/schema/master-data.ts');
      const [bowled] = await db
        .select()
        .from(dismissalTypes)
        .where(eq(dismissalTypes.name, 'bowled'))
        .limit(1);

      const wicketBody = {
        ...dotBallBody(liveInningsId),
        overNumber: 0,
        ballNumber: 2,
        isWicket: true,
        wicket: {
          dismissedPlayerId: homePlayerIds[0]!,
          dismissalTypeId: bowled!.id,
          bowlerCredited: true,
        },
      };

      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(wicketBody),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.delivery).toBeDefined();
      expect(body.delivery.isWicket).toBe(true);
    });
  });

  // ---- GET /:id/deliveries ----
  describe('GET /:id/deliveries', () => {
    it('rejects without inningsId -> 400', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
    });

    it('returns deliveries with valid inningsId -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries?inningsId=${liveInningsId}`),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toBeDefined();
    });
  });

  // ---- DELETE /:id/deliveries/:did (undo) ----
  describe('DELETE /:id/deliveries/:did', () => {
    it('undoes a delivery -> 200', async () => {
      // First record a delivery to undo
      const deliveryBody = {
        ...dotBallBody(liveInningsId),
        overNumber: 0,
        ballNumber: 3,
      };
      // Use next batter since original striker was dismissed
      deliveryBody.strikerId = homePlayerIds[2]!;

      const createRes = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(deliveryBody),
        }),
      );
      const created = await createRes.json();
      const undoId = created.delivery.id;

      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/deliveries/${undoId}`, {
          method: 'DELETE',
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });
  });

  // ---- POST /:id/abandon ----
  describe('POST /:id/abandon', () => {
    it('abandons a live match -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${liveMatchId}/abandon`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({}),
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });
  });

  // ---- POST /:id/declare ----
  describe('POST /:id/declare', () => {
    it('declares innings -> 200', async () => {
      // Score at least one delivery before declaring
      const deliveryBody = dotBallBody(secondInningsId);
      await app.handle(
        new Request(`${BASE}/${secondMatchId}/deliveries`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify(deliveryBody),
        }),
      );

      const res = await app.handle(
        new Request(`${BASE}/${secondMatchId}/declare`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({}),
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });
  });

  // ---- POST /:id/reopen ----
  describe('POST /:id/reopen', () => {
    it('reopens innings with target: "innings" -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${secondMatchId}/reopen`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({ target: 'innings' }),
        }),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });

    it('rejects invalid target -> 400', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${secondMatchId}/reopen`, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({ target: 'foo' }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
    });
  });
});
