import { describe, expect, it, beforeAll, afterAll, mock } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchResult } from '../../src/db/schema/matches.ts';
import { deliveries } from '../../src/db/schema/deliveries.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { battingStats, bowlingStats } from '../../src/db/schema/stats.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import {
  recordDelivery,
  undoDelivery,
  abandonMatch,
  declareInnings,
  reopenInnings,
} from '../../src/services/scoring.service.ts';
import { websocketHandler } from '../../src/websocket/handler.ts';
import { initBroadcaster, broadcastScoreUpdate, broadcastWicket, broadcastInningsComplete, broadcastMatchComplete, broadcastDeliveryUndone, broadcastMatchState } from '../../src/websocket/broadcaster.ts';
import {
  buildScoreUpdate,
  buildWicketMessage,
  buildInningsCompleteMessage,
  buildMatchCompleteMessage,
  buildDeliveryUndoneMessage,
  getMatchState,
} from '../../src/websocket/rooms.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';
import type { OverBallDisplay } from '../../src/types/websocket.ts';

const TEST_SUFFIX = `ws-broadcast-${Date.now()}`;
const PLAYERS_PER_SIDE = 3;
const WS_PORT = 9877;

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

let app: ReturnType<typeof createTestApp>;

function createTestApp() {
  return new Elysia()
    .use(errorHandler)
    .use(websocketHandler)
    .listen(WS_PORT);
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

function collectMessages(ws: WebSocket, count: number, timeoutMs = 5000): Promise<unknown[]> {
  return new Promise((resolve) => {
    const messages: unknown[] = [];
    const timer = setTimeout(() => resolve(messages), timeoutMs);
    ws.onmessage = (event) => {
      messages.push(JSON.parse(event.data as string));
      if (messages.length >= count) {
        clearTimeout(timer);
        resolve(messages);
      }
    };
  });
}

function deliveryToOverBall(d: typeof deliveries.$inferSelect): OverBallDisplay {
  let display: string;
  if (d.isWicket) display = 'W';
  else if (d.isWide) display = d.totalRuns > 1 ? `${d.totalRuns}Wd` : 'Wd';
  else if (d.isNoBall) display = d.totalRuns > 1 ? `${d.totalRuns}Nb` : 'Nb';
  else if (d.isBoundarySix) display = '6';
  else if (d.isBoundaryFour) display = '4';
  else if (d.totalRuns === 0) display = '.';
  else display = String(d.runsFromBat);

  return { runs: d.totalRuns, display, ...(d.isWicket ? { isWicket: true } : {}) };
}

async function createLiveMatch() {
  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers: 2,
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

  const tossResult = await recordToss(match.id, {
    winnerId: homeTeamId,
    decision: 'bat',
    openingStrikerId: homePlayerIds[0]!,
    openingNonStrikerId: homePlayerIds[1]!,
    openingBowlerId: awayPlayerIds[0]!,
    userId: scorerUserId,
  });

  return { matchId: match.id, inningsId: tossResult.innings.id };
}

beforeAll(async () => {
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-${TEST_SUFFIX}-scorer`,
      phone: '+919876900001',
      displayName: 'WS Broadcast Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  const homeValues = Array.from({ length: 4 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-home-${i}`,
    phone: `+91987690${String(i + 10).padStart(4, '0')}`,
    displayName: `WS BC Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  const awayValues = Array.from({ length: 4 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-away-${i}`,
    phone: `+91987691${String(i + 10).padStart(4, '0')}`,
    displayName: `WS BC Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `WS BC Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `WS BC Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  app = createTestApp();
  initBroadcaster(app.server!);
});

afterAll(async () => {
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
// Integration: Service call → broadcast → WS subscriber receives
// ============================================================

describe('Service → Broadcast → WS subscriber', () => {
  it('subscriber receives score_update after delivery', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    // Connect and join match room
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise; // consume match_state

    // Set up listener
    const broadcastPromise = waitForMessage(ws);

    // Record delivery via service
    const result = await recordDelivery(matchId, scorerUserId, {
      inningsId,
      overNumber: 0,
      ballNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 4,
      isWide: false,
      isNoBall: false,
      isBye: false,
      isLegBye: false,
      wideRuns: 0,
      noBallRuns: 0,
      byeRuns: 0,
      legByeRuns: 0,
      isWicket: false,
      isBoundaryFour: true,
      isBoundarySix: false,
    });

    // Build and broadcast score_update (same as route handler does)
    const overDeliveries = await db
      .select()
      .from(deliveries)
      .where(eq(deliveries.inningsId, inningsId))
      .orderBy(deliveries.sequenceNumber);
    const currentOver = overDeliveries.map(deliveryToOverBall);

    const [strikerStat] = await db
      .select({ playerId: battingStats.playerId, runs: battingStats.runsScored, balls: battingStats.ballsFaced, fours: battingStats.fours, sixes: battingStats.sixes, name: users.displayName })
      .from(battingStats)
      .innerJoin(users, eq(users.id, battingStats.playerId))
      .where(eq(battingStats.inningsId, inningsId))
      .limit(1);

    const [bowlerStat] = await db
      .select({ playerId: bowlingStats.playerId, overs: bowlingStats.oversBowled, maidens: bowlingStats.maidens, runs: bowlingStats.runsConceded, wickets: bowlingStats.wicketsTaken, name: users.displayName })
      .from(bowlingStats)
      .innerJoin(users, eq(users.id, bowlingStats.playerId))
      .where(eq(bowlingStats.inningsId, inningsId))
      .limit(1);

    const msg = buildScoreUpdate(
      matchId,
      result.delivery,
      result.updatedInnings!,
      strikerStat ? { playerId: strikerStat.playerId, name: strikerStat.name, runs: strikerStat.runs, balls: strikerStat.balls, fours: strikerStat.fours, sixes: strikerStat.sixes } : null,
      bowlerStat ? { playerId: bowlerStat.playerId, name: bowlerStat.name, overs: String(bowlerStat.overs), maidens: bowlerStat.maidens, runs: bowlerStat.runs, wickets: bowlerStat.wickets } : null,
      currentOver,
    );
    broadcastScoreUpdate(matchId, msg);

    const broadcast = await broadcastPromise as { type: string; matchId: string; data: { totalRuns: number } };
    expect(broadcast.type).toBe('score_update');
    expect(broadcast.matchId).toBe(matchId);
    expect(broadcast.data.totalRuns).toBe(4);

    ws.close();
  });

  it('subscriber receives wicket broadcast', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    const dismissalRows = await db.select().from((await import('../../src/db/schema/master-data.ts')).dismissalTypes);
    const bowledId = dismissalRows.find((r) => r.name === 'bowled')!.id;

    // Connect and join
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise;

    // Set up listeners for score_update + wicket
    const messagesPromise = collectMessages(ws, 2);

    // Record wicket delivery
    const result = await recordDelivery(matchId, scorerUserId, {
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
      isWicket: true,
      isBoundaryFour: false,
      isBoundarySix: false,
      wicket: {
        dismissedPlayerId: homePlayerIds[0]!,
        dismissalTypeId: bowledId,
        bowlerCredited: true,
      },
    });

    // Broadcast score_update
    const scoreMsg = buildScoreUpdate(matchId, result.delivery, result.updatedInnings!, null, null, []);
    broadcastScoreUpdate(matchId, scoreMsg);

    // Broadcast wicket
    const wicketMsg = buildWicketMessage(
      matchId,
      'WS BC Home 1',
      'bowled',
      null,
      'WS BC Away 1',
      `${result.updatedInnings!.totalRuns}/${result.updatedInnings!.totalWickets}`,
      String(result.updatedInnings!.totalOvers),
    );
    broadcastWicket(matchId, wicketMsg);

    const messages = await messagesPromise as { type: string }[];
    const types = messages.map((m) => m.type);
    expect(types).toContain('score_update');
    expect(types).toContain('wicket');

    ws.close();
  });

  it('subscriber receives delivery_undone after undo', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    // Record a delivery
    const result = await recordDelivery(matchId, scorerUserId, {
      inningsId,
      overNumber: 0,
      ballNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 1,
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
    });

    // Connect and join
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise;

    const broadcastPromise = waitForMessage(ws);

    // Undo
    await undoDelivery(matchId, result.delivery.id, scorerUserId);

    // Query updated state
    const [updatedInn] = await db.select().from(innings).where(eq(innings.id, inningsId)).limit(1);

    const undoMsg = buildDeliveryUndoneMessage(matchId, result.delivery.id, updatedInn!, null, null, []);
    broadcastDeliveryUndone(matchId, undoMsg);

    const broadcast = await broadcastPromise as { type: string; data: { removedDeliveryId: string } };
    expect(broadcast.type).toBe('delivery_undone');
    expect(broadcast.data.removedDeliveryId).toBe(result.delivery.id);

    ws.close();
  });

  it('subscriber receives match_complete after abandon', async () => {
    const { matchId } = await createLiveMatch();

    // Connect and join
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise;

    const broadcastPromise = waitForMessage(ws);

    // Abandon
    await abandonMatch(matchId, scorerUserId);

    // Query match result
    const [mr] = await db.select().from(matchResult).where(eq(matchResult.matchId, matchId)).limit(1);

    const matchMsg = buildMatchCompleteMessage(matchId, mr!, null);
    broadcastMatchComplete(matchId, matchMsg);

    const broadcast = await broadcastPromise as { type: string; data: { resultType: string } };
    expect(broadcast.type).toBe('match_complete');
    expect(broadcast.data.resultType).toBe('no_result');

    ws.close();
  });

  it('subscriber receives innings_complete after declare', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    // Record a delivery first
    await recordDelivery(matchId, scorerUserId, {
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
    });

    // Connect and join
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise;

    const broadcastPromise = waitForMessage(ws);

    // Declare
    await declareInnings(matchId, scorerUserId);

    // Query completed innings
    const [completedInn] = await db.select().from(innings).where(eq(innings.id, inningsId)).limit(1);
    const [battingTeam] = await db.select({ name: teams.name }).from(teams).where(eq(teams.id, completedInn!.battingTeamId)).limit(1);

    const inningsMsg = buildInningsCompleteMessage(matchId, completedInn!, battingTeam!.name);
    broadcastInningsComplete(matchId, inningsMsg);

    const broadcast = await broadcastPromise as { type: string; data: { inningsNumber: number } };
    expect(broadcast.type).toBe('innings_complete');
    expect(broadcast.data.inningsNumber).toBe(1);

    ws.close();
  });

  it('subscriber receives match_state after reopen', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    // Record + declare
    await recordDelivery(matchId, scorerUserId, {
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
    });
    await declareInnings(matchId, scorerUserId);

    // Connect and join
    const ws = await connectWs();
    const joinPromise = waitForMessage(ws);
    ws.send(JSON.stringify({ type: 'join_match', matchId }));
    await joinPromise;

    const broadcastPromise = waitForMessage(ws);

    // Reopen
    await reopenInnings(matchId, scorerUserId);

    // Broadcast full state
    const state = await getMatchState(matchId);
    broadcastMatchState(matchId, state);

    const broadcast = await broadcastPromise as { type: string; data: { status: string } };
    expect(broadcast.type).toBe('match_state');
    expect(broadcast.data.status).toBe('live');

    ws.close();
  });
});
