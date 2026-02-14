import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { deliveries } from '../../src/db/schema/deliveries.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import { recordDelivery } from '../../src/services/scoring.service.ts';
import {
  getMatchState,
  buildScoreUpdate,
  buildWicketMessage,
  buildInningsCompleteMessage,
  buildMatchCompleteMessage,
  buildDeliveryUndoneMessage,
  matchTopic,
} from '../../src/websocket/rooms.ts';

const TEST_SUFFIX = `ws-rooms-${Date.now()}`;
const PLAYERS_PER_SIDE = 11;

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

async function createLiveMatch(opts?: {
  totalOvers?: number;
  playersPerSide?: number;
  decision?: string;
}) {
  const totalOvers = opts?.totalOvers ?? 20;
  const playersPerSide = opts?.playersPerSide ?? PLAYERS_PER_SIDE;
  const decision = opts?.decision ?? 'bat';

  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers,
    ballTypeId: 1,
    matchDate: '2026-06-15',
    playersPerSide,
    createdBy: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: homeTeamId,
    playerIds: homePlayerIds.slice(0, playersPerSide),
    captainId: homePlayerIds[0]!,
    keeperId: homePlayerIds[1]!,
    userId: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: awayTeamId,
    playerIds: awayPlayerIds.slice(0, playersPerSide),
    captainId: awayPlayerIds[0]!,
    keeperId: awayPlayerIds[1]!,
    userId: scorerUserId,
  });

  const tossResult = await recordToss(match.id, {
    winnerId: homeTeamId,
    decision,
    openingStrikerId: homePlayerIds[0]!,
    openingNonStrikerId: homePlayerIds[1]!,
    openingBowlerId: awayPlayerIds[0]!,
    userId: scorerUserId,
  });

  return {
    matchId: match.id,
    inningsId: tossResult.innings.id,
    battingTeamId: tossResult.innings.battingTeamId,
    bowlingTeamId: tossResult.innings.bowlingTeamId,
  };
}

beforeAll(async () => {
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-${TEST_SUFFIX}-scorer`,
      phone: '+919876700001',
      displayName: 'WS Rooms Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  const homeValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-home-${i}`,
    phone: `+91987670${String(i + 10).padStart(4, '0')}`,
    displayName: `WS Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  const awayValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-${TEST_SUFFIX}-away-${i}`,
    phone: `+91987671${String(i + 10).padStart(4, '0')}`,
    displayName: `WS Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `WS Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `WS Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );
});

afterAll(async () => {
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
// matchTopic
// ============================================================

describe('matchTopic', () => {
  it('returns match:<matchId> format', () => {
    expect(matchTopic('abc-123')).toBe('match:abc-123');
  });
});

// ============================================================
// getMatchState
// ============================================================

describe('getMatchState', () => {
  it('returns correct snapshot for a live match with deliveries', async () => {
    const { matchId, inningsId } = await createLiveMatch();

    // Record a dot ball
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

    // Record a four
    await recordDelivery(matchId, scorerUserId, {
      inningsId,
      overNumber: 0,
      ballNumber: 2,
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

    const state = await getMatchState(matchId);

    expect(state.type).toBe('match_state');
    expect(state.matchId).toBe(matchId);
    expect(state.data.status).toBe('live');
    expect(state.data.inningsNumber).toBe(1);
    expect(state.data.totalRuns).toBe(4);
    expect(state.data.totalWickets).toBe(0);
    expect(state.data.overs).toBe('0.2');
    expect(state.data.currentRunRate).toBeGreaterThan(0);
    expect(state.data.target).toBeNull();
    expect(state.data.striker).not.toBeNull();
    expect(state.data.striker!.runs).toBe(4);
    expect(state.data.striker!.fours).toBe(1);
    expect(state.data.bowler).not.toBeNull();
    expect(state.data.currentOver).toHaveLength(2);
    expect(state.data.currentOver[0]!.display).toBe('.');
    expect(state.data.currentOver[1]!.display).toBe('4');
  });

  it('returns empty state for match without innings', async () => {
    // Create a match in setup status (no toss yet)
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

    const state = await getMatchState(match.id);

    expect(state.type).toBe('match_state');
    expect(state.data.status).toBe('setup');
    expect(state.data.inningsNumber).toBe(0);
    expect(state.data.totalRuns).toBe(0);
    expect(state.data.striker).toBeNull();
    expect(state.data.bowler).toBeNull();
    expect(state.data.currentOver).toHaveLength(0);
  });

  it('throws for non-existent match', async () => {
    let threw = false;
    try {
      await getMatchState('00000000-0000-0000-0000-000000000000');
    } catch {
      threw = true;
    }
    expect(threw).toBe(true);
  });
});

// ============================================================
// buildScoreUpdate
// ============================================================

describe('buildScoreUpdate', () => {
  it('formats score_update message correctly', () => {
    const fakeDelivery = {
      id: 'del-1',
      inningsId: 'inn-1',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsFromBat: 4,
      isWide: false,
      wideRuns: 0,
      isNoBall: false,
      noBallRuns: 0,
      isBye: false,
      byeRuns: 0,
      isLegBye: false,
      legByeRuns: 0,
      totalRuns: 4,
      isWicket: false,
      isLegal: true,
      isBoundaryFour: true,
      isBoundarySix: false,
      isFreeHit: false,
      isPenalty: false,
      wagonWheelZoneId: null,
      timestamp: new Date(),
      synced: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as typeof deliveries.$inferSelect;

    const fakeInnings = {
      id: 'inn-1',
      matchId: 'm-1',
      inningsNumber: 1,
      battingTeamId: 't1',
      bowlingTeamId: 't2',
      totalRuns: 4,
      totalWickets: 0,
      totalOvers: '0.1' as unknown as string,
      totalExtras: 0,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      isSuperOver: false,
      superOverNumber: null,
      isCompleted: false,
      completedReason: null,
      target: null,
      penaltyRuns: 0,
      runRate: null,
      dotBallPercentage: null,
      boundaryPercentage: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as typeof innings.$inferSelect;

    const msg = buildScoreUpdate(
      'm-1',
      fakeDelivery,
      fakeInnings,
      { playerId: 'p1', name: 'Batter One', runs: 4, balls: 1, fours: 1, sixes: 0 },
      { playerId: 'b1', name: 'Bowler One', overs: '0.1', maidens: 0, runs: 4, wickets: 0 },
      [{ runs: 4, display: '4' }],
    );

    expect(msg.type).toBe('score_update');
    expect(msg.matchId).toBe('m-1');
    expect(msg.data.totalRuns).toBe(4);
    expect(msg.data.totalWickets).toBe(0);
    expect(msg.data.lastDelivery.runs).toBe(4);
    expect(msg.data.lastDelivery.isBoundaryFour).toBe(true);
    expect(msg.data.lastDelivery.description).toContain('FOUR');
    expect(msg.data.striker).not.toBeNull();
    expect(msg.data.striker!.name).toBe('Batter One');
    expect(msg.data.striker!.strikeRate).toBe(400);
    expect(msg.data.bowler).not.toBeNull();
    expect(msg.data.bowler!.name).toBe('Bowler One');
    expect(msg.data.currentOver).toHaveLength(1);
  });

  it('handles null batter/bowler stats', () => {
    const fakeDelivery = {
      id: 'del-2',
      totalRuns: 0,
      runsFromBat: 0,
      isWide: false,
      isNoBall: false,
      isBye: false,
      isLegBye: false,
      isWicket: false,
      isBoundaryFour: false,
      isBoundarySix: false,
      wideRuns: 0,
      noBallRuns: 0,
      byeRuns: 0,
      legByeRuns: 0,
      isLegal: true,
      isFreeHit: false,
      isPenalty: false,
    } as typeof deliveries.$inferSelect;

    const fakeInnings = {
      totalRuns: 0,
      totalWickets: 0,
      totalOvers: '0.1',
    } as typeof innings.$inferSelect;

    const msg = buildScoreUpdate('m-2', fakeDelivery, fakeInnings, null, null, []);

    expect(msg.data.striker).toBeNull();
    expect(msg.data.bowler).toBeNull();
    expect(msg.data.lastDelivery.description).toBe('Dot ball');
  });
});

// ============================================================
// buildWicketMessage
// ============================================================

describe('buildWicketMessage', () => {
  it('formats caught wicket correctly', () => {
    const msg = buildWicketMessage(
      'm-1',
      'S. Dhawan',
      'caught',
      'V. Kohli',
      'J. Bumrah',
      '87/3',
      '12.3',
    );

    expect(msg.type).toBe('wicket');
    expect(msg.data.dismissedPlayer).toBe('S. Dhawan');
    expect(msg.data.description).toBe('c V. Kohli b J. Bumrah');
    expect(msg.data.teamScore).toBe('87/3');
  });

  it('formats bowled wicket correctly', () => {
    const msg = buildWicketMessage('m-1', 'Batter', 'bowled', null, 'Bowler', '50/1', '5.0');
    expect(msg.data.description).toBe('b Bowler');
  });

  it('formats run out correctly', () => {
    const msg = buildWicketMessage('m-1', 'Batter', 'run_out', 'Fielder', null, '50/1', '5.0');
    expect(msg.data.description).toBe('run out (Fielder)');
  });

  it('formats stumped correctly', () => {
    const msg = buildWicketMessage('m-1', 'Batter', 'stumped', 'Keeper', 'Bowler', '50/1', '5.0');
    expect(msg.data.description).toBe('st Keeper b Bowler');
  });

  it('formats lbw correctly', () => {
    const msg = buildWicketMessage('m-1', 'Batter', 'lbw', null, 'Bowler', '50/1', '5.0');
    expect(msg.data.description).toBe('lbw b Bowler');
  });

  it('formats caught and bowled correctly', () => {
    const msg = buildWicketMessage('m-1', 'Batter', 'caught_and_bowled', null, 'Bowler', '50/1', '5.0');
    expect(msg.data.description).toBe('c & b Bowler');
  });
});

// ============================================================
// buildInningsCompleteMessage
// ============================================================

describe('buildInningsCompleteMessage', () => {
  it('formats innings complete with target', () => {
    const fakeInnings = {
      id: 'inn-1',
      inningsNumber: 1,
      totalRuns: 156,
      totalWickets: 7,
      totalOvers: '20.0',
    } as typeof innings.$inferSelect;

    const msg = buildInningsCompleteMessage('m-1', fakeInnings, 'Mumbai Warriors');

    expect(msg.type).toBe('innings_complete');
    expect(msg.data.inningsNumber).toBe(1);
    expect(msg.data.battingTeam).toBe('Mumbai Warriors');
    expect(msg.data.totalRuns).toBe(156);
    expect(msg.data.target).toBe(157);
    expect(msg.data.overs).toBe('20.0');
  });
});

// ============================================================
// buildMatchCompleteMessage
// ============================================================

describe('buildMatchCompleteMessage', () => {
  it('formats match complete with winner', () => {
    const fakeResult = {
      id: 'res-1',
      matchId: 'm-1',
      winnerTeamId: 't-1',
      resultType: 'wickets',
      margin: 5,
      manOfMatchId: null,
      summary: 'Mumbai Warriors won by 5 wickets',
      createdAt: new Date(),
      updatedAt: new Date(),
    } as typeof matchResult.$inferSelect;

    const msg = buildMatchCompleteMessage('m-1', fakeResult, 'Mumbai Warriors');

    expect(msg.type).toBe('match_complete');
    expect(msg.data.winner).toBe('Mumbai Warriors');
    expect(msg.data.resultType).toBe('wickets');
    expect(msg.data.margin).toBe(5);
    expect(msg.data.summary).toBe('Mumbai Warriors won by 5 wickets');
  });

  it('formats tie with no winner', () => {
    const fakeResult = {
      resultType: 'tie',
      margin: null,
      summary: 'Match Tied',
    } as typeof matchResult.$inferSelect;

    const msg = buildMatchCompleteMessage('m-2', fakeResult, null);

    expect(msg.data.winner).toBeNull();
    expect(msg.data.resultType).toBe('tie');
    expect(msg.data.margin).toBeNull();
  });
});

// ============================================================
// buildDeliveryUndoneMessage
// ============================================================

describe('buildDeliveryUndoneMessage', () => {
  it('formats delivery undone message correctly', () => {
    const fakeInnings = {
      id: 'inn-1',
      totalRuns: 85,
      totalWickets: 3,
      totalOvers: '12.3',
    } as typeof innings.$inferSelect;

    const msg = buildDeliveryUndoneMessage(
      'm-1',
      'del-99',
      fakeInnings,
      { playerId: 'p1', runs: 45, balls: 30, fours: 5, sixes: 2 },
      { playerId: 'b1', overs: '4.3', runs: 28, wickets: 1, maidens: 0 },
      [{ runs: 0, display: '.' }, { runs: 1, display: '1' }],
    );

    expect(msg.type).toBe('delivery_undone');
    expect(msg.data.removedDeliveryId).toBe('del-99');
    expect(msg.data.updatedScore.runs).toBe(85);
    expect(msg.data.updatedScore.wickets).toBe(3);
    expect(msg.data.updatedScore.overs).toBe('12.3');
    expect(msg.data.updatedBatterStats!.strikerId).toBe('p1');
    expect(msg.data.updatedBatterStats!.strikerRuns).toBe(45);
    expect(msg.data.updatedBowlerStats!.bowlerId).toBe('b1');
    expect(msg.data.updatedBowlerStats!.bowlerOvers).toBe('4.3');
    expect(msg.data.currentOver).toHaveLength(2);
  });

  it('handles null batter/bowler stats', () => {
    const fakeInnings = {
      id: 'inn-1',
      totalRuns: 0,
      totalWickets: 0,
      totalOvers: '0.0',
    } as typeof innings.$inferSelect;

    const msg = buildDeliveryUndoneMessage('m-1', 'del-1', fakeInnings, null, null, []);

    expect(msg.data.updatedBatterStats).toBeNull();
    expect(msg.data.updatedBowlerStats).toBeNull();
  });
});
