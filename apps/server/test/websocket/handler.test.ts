import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchResult } from '../../src/db/schema/matches.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import { websocketHandler } from '../../src/websocket/handler.ts';

const TEST_SUFFIX = `ws-handler-${Date.now()}`;
const PLAYERS_PER_SIDE = 11;
const WS_PORT = 9876; // Use a non-standard port for tests

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
let testMatchId: string;

let app: ReturnType<typeof createApp>;

function createApp() {
  return new Elysia().use(websocketHandler).listen(WS_PORT);
}

function connectWs(path = '/ws'): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://localhost:${WS_PORT}${path}`);
    ws.onopen = () => resolve(ws);
    ws.onerror = (err) => reject(err);
  });
}

function waitForMessage(ws: WebSocket, timeoutMs = 5000): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('WS message timeout')), timeoutMs);
    ws.onmessage = (event) => {
      clearTimeout(timer);
      resolve(JSON.parse(event.data as string));
    };
  });
}

beforeAll(async () => {
  // Create test data.
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-${TEST_SUFFIX}-scorer`,
      phone: '+919876800001',
      displayName: 'WS Handler Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Update scorer's firebaseUid to match what the test auth mode returns.
  // ENABLE_TEST_AUTH maps all WS tokens to 'test-user-e2e-001'.
  // This is needed for publish_score to pass verifyScorerForMatch.
  // First clear any existing user with this UID to avoid unique constraint.
  await db
    .update(users)
    .set({ firebaseUid: `stale-${TEST_SUFFIX}` })
    .where(eq(users.firebaseUid, 'test-user-e2e-001'));
  await db
    .update(users)
    .set({ firebaseUid: 'test-user-e2e-001' })
    .where(eq(users.id, scorerUserId));

  const homeValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-home-${i}`,
    phone: `+91987680${String(i + 10).padStart(4, '0')}`,
    displayName: `WS Handler Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  const awayValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-away-${i}`,
    phone: `+91987681${String(i + 10).padStart(4, '0')}`,
    displayName: `WS Handler Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `WS Handler Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `WS Handler Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Create a live match for testing
  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers: 20,
    ballTypeId: 1,
    matchDate: '2026-06-15',
    playersPerSide: PLAYERS_PER_SIDE,
    createdBy: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: homeTeamId,
    playerIds: homePlayerIds.slice(0, PLAYERS_PER_SIDE),
    captainId: homePlayerIds[0]!,
    keeperId: homePlayerIds[1]!,
    userId: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: awayTeamId,
    playerIds: awayPlayerIds.slice(0, PLAYERS_PER_SIDE),
    captainId: awayPlayerIds[0]!,
    keeperId: awayPlayerIds[1]!,
    userId: scorerUserId,
  });

  await recordToss(match.id, {
    winnerId: homeTeamId,
    decision: 'bat',
    openingStrikerId: homePlayerIds[0]!,
    openingNonStrikerId: homePlayerIds[1]!,
    openingBowlerId: awayPlayerIds[0]!,
    userId: scorerUserId,
  });

  testMatchId = match.id;

  // Start WS server
  app = createApp();
});

afterAll(async () => {
  // Stop server
  app?.stop();

  const matchIds = await db
    .select({ id: matches.id })
    .from(matches)
    .where(eq(matches.createdBy, scorerUserId))
    .then((r) => r.map((m) => m.id));

  if (matchIds.length > 0) {
    await db.delete(matchResult).where(inArray(matchResult.matchId, matchIds));
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));

  if (testUserIds.length > 0) {
    await db.delete(users).where(inArray(users.id, testUserIds));
  }
});

// ============================================================
// Connection Tests
// ============================================================

describe('WebSocket Connection', () => {
  it('connects successfully', async () => {
    const ws = await connectWs();
    expect(ws.readyState).toBe(WebSocket.OPEN);
    ws.close();
  });

  it('connects without token (anonymous viewer)', async () => {
    const ws = await connectWs('/ws');
    expect(ws.readyState).toBe(WebSocket.OPEN);
    ws.close();
  });

  it('connects with token query param', async () => {
    const ws = await connectWs('/ws?token=some-jwt-token');
    expect(ws.readyState).toBe(WebSocket.OPEN);
    ws.close();
  });
});

// ============================================================
// Join Match Tests
// ============================================================

describe('join_match', () => {
  it('receives match_state after joining', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({ type: 'join_match', matchId: testMatchId }));

    const response = await responsePromise as { type: string; matchId: string; data: { status: string } };

    expect(response.type).toBe('match_state');
    expect(response.matchId).toBe(testMatchId);
    expect(response.data.status).toBe('live');

    ws.close();
  });

  it('returns error for non-existent match', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({
      type: 'join_match',
      matchId: '00000000-0000-0000-0000-000000000000',
    }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toBe('Match not found');

    ws.close();
  });

  it('returns error when matchId missing', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({ type: 'join_match' }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toContain('matchId');

    ws.close();
  });
});

// ============================================================
// Leave Match Tests
// ============================================================

describe('leave_match', () => {
  it('does not error on leave', async () => {
    const ws = await connectWs();

    // Join first
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId: testMatchId }));
    await joinPromise;

    // Leave — no response expected (it just unsubscribes)
    ws.send(JSON.stringify({ type: 'leave_match', matchId: testMatchId }));

    // Small delay to ensure no error
    await new Promise((r) => setTimeout(r, 100));

    expect(ws.readyState).toBe(WebSocket.OPEN);
    ws.close();
  });
});

// ============================================================
// Invalid Message Tests
// ============================================================

// ============================================================
// Publish Score Tests (fast-path relay)
// ============================================================

describe('publish_score', () => {
  it('relays payload to room subscribers', async () => {
    // Scorer joins and publishes (with token so publish_score is authorized)
    const scorer = await connectWs('/ws?token=test-scorer');
    const joinPromise = waitForMessage(scorer);
    scorer.send(JSON.stringify({ type: 'join_match', matchId: testMatchId }));
    await joinPromise; // consume match_state

    // Viewer joins same room
    const viewer = await connectWs();
    const viewerJoinPromise = waitForMessage(viewer);
    viewer.send(JSON.stringify({ type: 'join_match', matchId: testMatchId }));
    await viewerJoinPromise; // consume match_state

    // Scorer publishes score update
    const viewerMsgPromise = waitForMessage(viewer);
    const testPayload = {
      type: 'score_update',
      matchId: testMatchId,
      data: { totalRuns: 42, totalWickets: 2, overs: '5.3' },
    };
    scorer.send(JSON.stringify({
      type: 'publish_score',
      matchId: testMatchId,
      payload: testPayload,
    }));

    const relayed = await viewerMsgPromise as { type: string; data: { totalRuns: number } };

    expect(relayed.type).toBe('score_update');
    expect(relayed.data.totalRuns).toBe(42);

    scorer.close();
    viewer.close();
  });

  it('returns error when matchId is missing', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({
      type: 'publish_score',
      payload: { type: 'score_update' },
    }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toContain('matchId');

    ws.close();
  });

  it('returns error when payload is missing', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({
      type: 'publish_score',
      matchId: testMatchId,
    }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toContain('payload');

    ws.close();
  });
});

// ============================================================
// Invalid Message Tests
// ============================================================

describe('invalid messages', () => {
  it('returns error for unknown message type', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({ type: 'unknown_action' }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toContain('Unknown message type');

    ws.close();
  });

  it('returns error for message without type', async () => {
    const ws = await connectWs();
    const responsePromise = waitForMessage(ws);

    ws.send(JSON.stringify({ foo: 'bar' }));

    const response = await responsePromise as { type: string; message: string };

    expect(response.type).toBe('error');
    expect(response.message).toContain('Invalid message format');

    ws.close();
  });
});
