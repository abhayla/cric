import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { deliveries } from '../../src/db/schema/deliveries.ts';
import { battingStats, bowlingStats, fieldingStats, playerCareerStats } from '../../src/db/schema/stats.ts';
import { matchAnalytics } from '../../src/db/schema/matches.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import {
  recordDeliveryBatch,
  recordDelivery,
} from '../../src/services/scoring.service.ts';

const TEST_SUFFIX = `batch-${Date.now()}`;
const PLAYERS_PER_SIDE = 11;

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
let dismissalBowledId: number;
let dismissalCaughtId: number;

async function createLiveMatch(opts?: {
  totalOvers?: number;
  playersPerSide?: number;
}) {
  const totalOvers = opts?.totalOvers ?? 20;
  const playersPerSide = opts?.playersPerSide ?? PLAYERS_PER_SIDE;

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
    decision: 'bat',
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

function makeDotBall(inningsNumber: number, overNumber: number, ballNumber: number, id?: string) {
  return {
    ...(id ? { id } : {}),
    inningsNumber,
    overNumber,
    ballNumber,
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

function makeWicketBall(
  inningsNumber: number,
  overNumber: number,
  ballNumber: number,
  dismissedPlayerId: string,
) {
  return {
    inningsNumber,
    overNumber,
    ballNumber,
    strikerId: dismissedPlayerId,
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
      dismissedPlayerId,
      dismissalTypeId: dismissalBowledId,
      bowlerCredited: true,
    },
  };
}

beforeAll(async () => {
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-batch-scorer-${TEST_SUFFIX}`,
      phone: '+919876700001',
      displayName: 'Batch Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  const homeValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-batch-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987670${String(i + 10).padStart(4, '0')}`,
    displayName: `Home Batch ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  const awayValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-batch-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987671${String(i + 10).padStart(4, '0')}`,
    displayName: `Away Batch ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `Home Batch ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `Away Batch ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Load dismissal type IDs
  const dismissalRows = await db
    .select()
    .from((await import('../../src/db/schema/master-data.ts')).dismissalTypes);
  for (const row of dismissalRows) {
    if (row.name === 'bowled') dismissalBowledId = row.id;
    if (row.name === 'caught') dismissalCaughtId = row.id;
  }
});

afterAll(async () => {
  const matchIds = await db
    .select({ id: matches.id })
    .from(matches)
    .where(eq(matches.createdBy, scorerUserId))
    .then((r) => r.map((m) => m.id));

  if (matchIds.length > 0) {
    await db.delete(matchAnalytics).where(inArray(matchAnalytics.matchId, matchIds));
    await db.delete(matchResult).where(inArray(matchResult.matchId, matchIds));
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  if (testUserIds.length > 0) {
    await db.delete(playerCareerStats).where(inArray(playerCareerStats.playerId, testUserIds));
  }

  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));

  if (testUserIds.length > 0) {
    await db.delete(users).where(inArray(users.id, testUserIds));
  }
});

describe('recordDeliveryBatch', () => {
  it('batch of 6 dots → over completed, maiden detected', async () => {
    const { matchId } = await createLiveMatch();

    const dots = Array.from({ length: 6 }, (_, i) =>
      makeDotBall(1, 0, i + 1),
    );

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: dots,
    });

    expect(result.processed).toBe(6);
    expect(result.skipped).toBe(0);

    // Verify innings shows 1.0 overs
    const [inn] = await db
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));
    expect(String(inn!.totalOvers)).toBe('1.0');
    expect(inn!.totalRuns).toBe(0);

    // Verify bowler stats — should have maiden
    const [bowlerStat] = await db
      .select()
      .from(bowlingStats)
      .where(eq(bowlingStats.inningsId, inn!.id));
    expect(bowlerStat!.maidens).toBe(1);
  });

  it('batch with wickets → stats correct', async () => {
    const { matchId } = await createLiveMatch();

    // 3 dots + 1 wicket + 2 more dots
    const batch = [
      makeDotBall(1, 0, 1),
      makeDotBall(1, 0, 2),
      makeDotBall(1, 0, 3),
      makeWicketBall(1, 0, 4, homePlayerIds[0]!),
      // After wicket, next batter comes in
      {
        ...makeDotBall(1, 0, 5),
        strikerId: homePlayerIds[2]!, // New batter
      },
      {
        ...makeDotBall(1, 0, 6),
        strikerId: homePlayerIds[2]!,
      },
    ];

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: batch,
    });

    expect(result.processed).toBe(6);

    // Check innings wickets
    const [inn] = await db
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));
    expect(inn!.totalWickets).toBe(1);

    // Check bowler wickets
    const [bowlerStat] = await db
      .select()
      .from(bowlingStats)
      .where(eq(bowlingStats.inningsId, inn!.id));
    expect(bowlerStat!.wicketsTaken).toBe(1);
  });

  it('idempotent retry → no duplicates, skipped count correct', async () => {
    const { matchId } = await createLiveMatch();

    const deliveryId = crypto.randomUUID();
    const batch = [
      { ...makeDotBall(1, 0, 1), id: deliveryId },
      makeDotBall(1, 0, 2),
    ];

    // First run
    const first = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: batch,
    });
    expect(first.processed).toBe(2);
    expect(first.skipped).toBe(0);

    // Second run — same batch with same UUID
    const second = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: batch,
    });
    // First delivery skipped (duplicate UUID), second has no UUID so gets new sequence
    expect(second.skipped).toBe(1);

    // Count total deliveries — should be 3 (2 from first + 1 new from second)
    const allDels = await db
      .select()
      .from(deliveries)
      .where(eq(deliveries.inningsId, (await db.select().from(innings).where(eq(innings.matchId, matchId)))[0]!.id));
    expect(allDels.length).toBe(3);
  });

  it('empty batch → processed: 0', async () => {
    const { matchId } = await createLiveMatch();

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: [],
    });

    expect(result.processed).toBe(0);
    expect(result.skipped).toBe(0);
    expect(result.inningsComplete).toBe(false);
    expect(result.matchComplete).toBe(false);
  });

  it('batch spanning innings — 1st innings exhausted → 2nd innings auto-created', async () => {
    // Use a very short match (1 over each)
    const { matchId } = await createLiveMatch({ totalOvers: 1 });

    // 6 dots for innings 1 (completes it) + 6 dots for innings 2
    const batch = [
      ...Array.from({ length: 6 }, (_, i) => makeDotBall(1, 0, i + 1)),
      ...Array.from({ length: 6 }, (_, i) => ({
        ...makeDotBall(2, 0, i + 1),
        // In innings 2, batting/bowling teams swap
        strikerId: awayPlayerIds[0]!,
        nonStrikerId: awayPlayerIds[1]!,
        bowlerId: homePlayerIds[0]!,
      })),
    ];

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: batch,
    });

    expect(result.processed).toBe(12);
    expect(result.inningsComplete).toBe(true);
    expect(result.matchComplete).toBe(true);

    // Verify both innings exist
    const allInnings = await db
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));
    expect(allInnings.length).toBe(2);
    expect(allInnings.every(i => i.isCompleted)).toBe(true);
  });

  it('target chased mid-batch → match completes, remaining deliveries skipped', async () => {
    const { matchId } = await createLiveMatch({ totalOvers: 2 });

    // Play 1 over of innings 1 scoring 6 runs (a six on ball 1, rest dots)
    const inn1Batch = [
      {
        ...makeDotBall(1, 0, 1),
        runsFromBat: 6,
        isBoundarySix: true,
      },
      ...Array.from({ length: 5 }, (_, i) => makeDotBall(1, 0, i + 2)),
      ...Array.from({ length: 6 }, (_, i) => makeDotBall(1, 1, i + 1)),
    ];

    await recordDeliveryBatch(matchId, scorerUserId, { deliveries: inn1Batch });

    // Now innings 2: target is 7. Send 12 balls with a six on ball 1 + boundary four on ball 2
    // Ball 1: six (6 runs) → need 1 more. Ball 2: four (4 runs) → target chased (10 >= 7)
    // Remaining 10 balls should be skipped
    const inn2Batch = [
      {
        ...makeDotBall(2, 0, 1),
        strikerId: awayPlayerIds[0]!,
        nonStrikerId: awayPlayerIds[1]!,
        bowlerId: homePlayerIds[0]!,
        runsFromBat: 6,
        isBoundarySix: true,
      },
      {
        ...makeDotBall(2, 0, 2),
        strikerId: awayPlayerIds[0]!,
        nonStrikerId: awayPlayerIds[1]!,
        bowlerId: homePlayerIds[0]!,
        runsFromBat: 4,
        isBoundaryFour: true,
      },
      ...Array.from({ length: 10 }, (_, i) => ({
        ...makeDotBall(2, 0, i + 3),
        strikerId: awayPlayerIds[0]!,
        nonStrikerId: awayPlayerIds[1]!,
        bowlerId: homePlayerIds[0]!,
      })),
    ];

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: inn2Batch,
    });

    expect(result.matchComplete).toBe(true);
    // Only 2 deliveries should be processed (target chased after ball 2)
    expect(result.processed).toBe(2);
  });

  it('pre-create innings 2 when only innings 2 deliveries in batch', async () => {
    const { matchId } = await createLiveMatch({ totalOvers: 1 });

    // First, complete innings 1 via individual calls
    for (let i = 0; i < 6; i++) {
      await recordDelivery(matchId, scorerUserId, {
        ...makeDotBall(1, 0, i + 1),
        inningsNumber: 1,
      });
    }

    // Verify innings 1 is complete
    const allInnings = await db
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));

    // recordDelivery already auto-creates innings 2, so it should exist
    expect(allInnings.length).toBe(2);

    // Now send a batch with only innings 2 deliveries
    const inn2Batch = Array.from({ length: 6 }, (_, i) => ({
      ...makeDotBall(2, 0, i + 1),
      strikerId: awayPlayerIds[0]!,
      nonStrikerId: awayPlayerIds[1]!,
      bowlerId: homePlayerIds[0]!,
    }));

    const result = await recordDeliveryBatch(matchId, scorerUserId, {
      deliveries: inn2Batch,
    });

    expect(result.processed).toBe(6);
    expect(result.matchComplete).toBe(true);
  });

  it('transaction rollback on invalid delivery mid-batch → no partial data', async () => {
    const { matchId } = await createLiveMatch();

    // 2 good dots, then a delivery with no inningsId or inningsNumber (invalid)
    const invalidDelivery = makeDotBall(1, 0, 3);
    // Remove inningsNumber to make it invalid
    delete (invalidDelivery as Record<string, unknown>).inningsNumber;

    const batch = [
      makeDotBall(1, 0, 1),
      makeDotBall(1, 0, 2),
      invalidDelivery,
    ];

    let threw = false;
    try {
      await recordDeliveryBatch(matchId, scorerUserId, { deliveries: batch });
    } catch {
      threw = true;
    }
    expect(threw).toBe(true);

    // No deliveries should have been persisted (transaction rolled back)
    const [inn] = await db
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));
    const dels = await db
      .select()
      .from(deliveries)
      .where(eq(deliveries.inningsId, inn!.id));
    expect(dels.length).toBe(0);
  });
});
