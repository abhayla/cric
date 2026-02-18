import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchResult, matchAnalytics, matchPlayers } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { playerCareerStats } from '../../src/db/schema/stats.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import {
  recordDelivery,
  declareInnings,
} from '../../src/services/scoring.service.ts';

const TEST_SUFFIX = Date.now();
const PLAYERS_PER_SIDE = 6; // Small teams for faster tests

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
let dismissalBowledId: number;

/** Helper: create a live match ready for deliveries */
async function createLiveMatch(opts?: { totalOvers?: number }) {
  const totalOvers = opts?.totalOvers ?? 5;

  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers,
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

  return {
    matchId: match.id,
    inningsId: tossResult.innings.id,
    battingTeamId: tossResult.innings.battingTeamId,
    bowlingTeamId: tossResult.innings.bowlingTeamId,
  };
}

/** Helper: record a delivery with common defaults */
function deliveryInput(inningsId: string, overrides: Record<string, unknown>) {
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
    ...overrides,
  };
}

beforeAll(async () => {
  // Create scorer
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-mvp-scorer-${TEST_SUFFIX}`,
      phone: '+919876770001',
      displayName: 'MVP Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Create players for each team
  for (const side of ['home', 'away']) {
    const values = Array.from({ length: PLAYERS_PER_SIDE }, (_, i) => ({
      firebaseUid: `test-mvp-${side}-${i}-${TEST_SUFFIX}`,
      phone: `+91987677${side === 'home' ? '1' : '2'}${String(i + 10).padStart(3, '0')}`,
      displayName: `${side === 'home' ? 'Home' : 'Away'} Player ${i + 1}`,
    }));
    const players = await db.insert(users).values(values).returning();
    const ids = players.map((p) => p.id);
    testUserIds.push(...ids);
    if (side === 'home') homePlayerIds = ids;
    else awayPlayerIds = ids;
  }

  // Create teams
  const [home] = await db.insert(teams).values({ name: `MVP Home ${TEST_SUFFIX}`, createdBy: scorerUserId }).returning();
  const [away] = await db.insert(teams).values({ name: `MVP Away ${TEST_SUFFIX}`, createdBy: scorerUserId }).returning();
  homeTeamId = home!.id;
  awayTeamId = away!.id;

  // Add rosters
  await db.insert(teamRosters).values(homePlayerIds.map((pid) => ({ teamId: homeTeamId, playerId: pid, role: 'player' })));
  await db.insert(teamRosters).values(awayPlayerIds.map((pid) => ({ teamId: awayTeamId, playerId: pid, role: 'player' })));

  // Load dismissal type IDs from seed data
  const dismissalRows = await db
    .select()
    .from((await import('../../src/db/schema/master-data.ts')).dismissalTypes);
  for (const row of dismissalRows) {
    if (row.name === 'bowled') dismissalBowledId = row.id;
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

describe('MVP Algorithm — computeMatchAwards', () => {
  it('selects MOTM based on batting score when only 1st innings batter dominates', async () => {
    const live = await createLiveMatch({ totalOvers: 2 });

    // 1st innings: Home Player 1 scores 50 (boundary sixes: 8 × 6 = 48, + four = 4, total 52)
    // Using small number of big hits to trigger half-century bonus
    let seqBall = 0;
    // Over 0: 6 sixes by player 0 (striker)
    for (let ball = 1; ball <= 6; ball++) {
      seqBall++;
      await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
        overNumber: 0,
        ballNumber: ball,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 6,
        isBoundarySix: true,
      }));
    }

    // Over 1: 6 more sixes by same player (need to stay on strike — 6 doesn't swap)
    for (let ball = 1; ball <= 6; ball++) {
      seqBall++;
      await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
        overNumber: 1,
        ballNumber: ball,
        strikerId: homePlayerIds[0]!, // stays on strike after even runs
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[2]!, // different bowler for over 1
        runsFromBat: 6,
        isBoundarySix: true,
      }));
    }

    // Innings complete (overs exhausted). Total = 72 runs.
    // Declare is not needed — innings should auto-complete.

    // Create 2nd innings — target = 73
    const [secondInnings] = await db
      .insert(innings)
      .values({
        matchId: live.matchId,
        inningsNumber: 2,
        battingTeamId: live.bowlingTeamId,
        bowlingTeamId: live.battingTeamId,
        target: 73,
      })
      .returning();

    await db.update(matches).set({ status: 'live' }).where(eq(matches.id, live.matchId));

    // 2nd innings: all out immediately for 0 (all 5 wickets — 6 players per side, 5 wickets = all out)
    for (let w = 0; w < PLAYERS_PER_SIDE - 1; w++) {
      const strikerId = awayPlayerIds[w]!;
      const nonStrikerId = awayPlayerIds[Math.min(w + 1, PLAYERS_PER_SIDE - 1)]!;
      const result = await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
        overNumber: 0,
        ballNumber: w + 1,
        strikerId,
        nonStrikerId,
        bowlerId: homePlayerIds[0]!,
        runsFromBat: 0,
        isWicket: true,
        wicket: {
          dismissedPlayerId: strikerId,
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      }));

      if (result.matchComplete) break;
    }

    // Verify match is completed
    const [matchRow] = await db.select({ status: matches.status }).from(matches).where(eq(matches.id, live.matchId));
    expect(matchRow!.status).toBe('completed');

    // Read match analytics
    const [analytics] = await db.select().from(matchAnalytics).where(eq(matchAnalytics.matchId, live.matchId));
    expect(analytics).toBeDefined();
    expect(analytics!.mvpScores).toBeDefined();

    const awards = analytics!.mvpScores as {
      motmPlayerId: string | null;
      bestBatsmanId: string | null;
      bestBatsmanRuns: number;
      bestBowlerId: string | null;
      bestBowlerWickets: number;
      playerScores: Array<{ playerId: string; battingScore: number; bowlingScore: number; totalScore: number }>;
    };

    // MOTM should be homePlayerIds[0] (scored 72 runs with sixes)
    expect(awards.motmPlayerId).toBe(homePlayerIds[0]!);

    // Best batsman = homePlayerIds[0], 72 runs
    expect(awards.bestBatsmanId).toBe(homePlayerIds[0]!);
    expect(awards.bestBatsmanRuns).toBe(72);

    // Batting score for player 0: 72/10 + 2 (50 bonus) + 3 (100 bonus is NOT triggered, <100) + 0×0.1 fours + 12×0.2 sixes
    // = 7.2 + 2 + 0 + 2.4 = 11.6
    const player0Score = awards.playerScores.find((p) => p.playerId === homePlayerIds[0]!);
    expect(player0Score).toBeDefined();
    expect(player0Score!.battingScore).toBeCloseTo(11.6, 1);

    // manOfMatchId in matchResult
    const [mr] = await db.select().from(matchResult).where(eq(matchResult.matchId, live.matchId));
    expect(mr!.manOfMatchId).toBe(homePlayerIds[0]!);
  });

  it('selects MOTM based on bowling when bowler takes 5 wickets', async () => {
    const live = await createLiveMatch({ totalOvers: 2 });

    // 1st innings: quick declare with minimal runs
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 1,
    }));

    await declareInnings(live.matchId, scorerUserId);

    // Create 2nd innings — target = 2
    const [secondInnings] = await db
      .insert(innings)
      .values({
        matchId: live.matchId,
        inningsNumber: 2,
        battingTeamId: live.bowlingTeamId,
        bowlingTeamId: live.battingTeamId,
        target: 2,
      })
      .returning();

    await db.update(matches).set({ status: 'live' }).where(eq(matches.id, live.matchId));

    // 2nd innings: homePlayerIds[2] takes all 5 wickets (all out for 0)
    for (let w = 0; w < PLAYERS_PER_SIDE - 1; w++) {
      const strikerId = awayPlayerIds[w]!;
      const nonStrikerId = awayPlayerIds[Math.min(w + 1, PLAYERS_PER_SIDE - 1)]!;
      const result = await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
        overNumber: 0,
        ballNumber: w + 1,
        strikerId,
        nonStrikerId,
        bowlerId: homePlayerIds[2]!, // Single bowler taking all wickets
        runsFromBat: 0,
        isWicket: true,
        wicket: {
          dismissedPlayerId: strikerId,
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      }));
      if (result.matchComplete) break;
    }

    // Read analytics
    const [analytics] = await db.select().from(matchAnalytics).where(eq(matchAnalytics.matchId, live.matchId));
    expect(analytics).toBeDefined();

    const awards = analytics!.mvpScores as {
      motmPlayerId: string | null;
      bestBowlerId: string | null;
      bestBowlerWickets: number;
      playerScores: Array<{ playerId: string; battingScore: number; bowlingScore: number; totalScore: number }>;
    };

    // Best bowler = homePlayerIds[2] with 5 wickets
    expect(awards.bestBowlerId).toBe(homePlayerIds[2]!);
    expect(awards.bestBowlerWickets).toBe(5);

    // Bowling score for 5 wickets: 5×3 + 1 maiden + 3 (3-wkt bonus) + 2 (5-wkt bonus) = 15 + 1 + 3 + 2 = 21
    // Actually maiden detection: all 5 balls were wickets with 0 runs — but only 5 balls, not a full over
    // So no maiden (over not complete — only 5 balls bowled in a 6-ball over)
    // Score: 5×3 + 3 (3-wkt) + 2 (5-wkt) = 20
    const bowlerScore = awards.playerScores.find((p) => p.playerId === homePlayerIds[2]!);
    expect(bowlerScore).toBeDefined();
    expect(bowlerScore!.bowlingScore).toBe(20);

    // MOTM should be the bowler (batting score is minimal for everyone)
    expect(awards.motmPlayerId).toBe(homePlayerIds[2]!);
  });

  it('best batsman tiebreak uses fewer balls faced', async () => {
    const live = await createLiveMatch({ totalOvers: 2 });

    // 1st innings: Player 0 scores 6 off 1 ball, then player 1 scores 6 off 2 balls
    // Player 0: 6 runs, 1 ball → better SR
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 6,
      isBoundarySix: true,
    }));

    // Player 1 now on strike after over would swap — but 6 doesn't swap
    // So player 0 is still on strike. Score a single to swap.
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 2,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 1,
    }));

    // Player 1 now on strike — score 6 off 1 ball
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 3,
      strikerId: homePlayerIds[1]!,
      nonStrikerId: homePlayerIds[0]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 6,
      isBoundarySix: true,
    }));

    // Player 1 scores a dot to have same runs as Player 0 (7 vs 6... actually P0=7, P1=6)
    // Let's adjust: P0 = 6+1 = 7 runs off 2 balls, P1 = 6 off 1 ball
    // For equal runs, P1 needs 1 more
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 4,
      strikerId: homePlayerIds[1]!,
      nonStrikerId: homePlayerIds[0]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 1,
    }));

    // Now P0 = 7 runs (2 balls), P1 = 7 runs (2 balls) — tied on both!
    // Let's declare and finish the match to test the tiebreak
    await declareInnings(live.matchId, scorerUserId);

    // 2nd innings: chase target quickly
    const [secondInnings] = await db
      .insert(innings)
      .values({
        matchId: live.matchId,
        inningsNumber: 2,
        battingTeamId: live.bowlingTeamId,
        bowlingTeamId: live.battingTeamId,
        target: 15,
      })
      .returning();

    await db.update(matches).set({ status: 'live' }).where(eq(matches.id, live.matchId));

    // Chase with a big hit
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
      overNumber: 0,
      ballNumber: 1,
      strikerId: awayPlayerIds[0]!,
      nonStrikerId: awayPlayerIds[1]!,
      bowlerId: homePlayerIds[0]!,
      runsFromBat: 6,
      isBoundarySix: true,
    }));

    await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
      overNumber: 0,
      ballNumber: 2,
      strikerId: awayPlayerIds[0]!,
      nonStrikerId: awayPlayerIds[1]!,
      bowlerId: homePlayerIds[0]!,
      runsFromBat: 6,
      isBoundarySix: true,
    }));

    await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
      overNumber: 0,
      ballNumber: 3,
      strikerId: awayPlayerIds[0]!,
      nonStrikerId: awayPlayerIds[1]!,
      bowlerId: homePlayerIds[0]!,
      runsFromBat: 4,
      isBoundaryFour: true,
    }));

    // Away player 0 scored 16 (chased 15), match done
    const [analytics] = await db.select().from(matchAnalytics).where(eq(matchAnalytics.matchId, live.matchId));
    expect(analytics).toBeDefined();

    const awards = analytics!.mvpScores as {
      bestBatsmanId: string | null;
      bestBatsmanRuns: number;
    };

    // Away player 0 scored 16 — should be best batsman regardless of tiebreak
    expect(awards.bestBatsmanId).toBe(awayPlayerIds[0]!);
    expect(awards.bestBatsmanRuns).toBe(16);
  });

  it('century bonus stacks with half-century bonus', async () => {
    const live = await createLiveMatch({ totalOvers: 5 });

    // Score 102 runs in 1st innings: 17 sixes = 102
    for (let over = 0; over < 3; over++) {
      for (let ball = 1; ball <= 6; ball++) {
        await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
          overNumber: over,
          ballNumber: ball,
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId: awayPlayerIds[over % 3]!, // rotate bowlers
          runsFromBat: 6,
          isBoundarySix: true,
        }));
      }
    }

    // Declare at 108 runs (18 sixes × 6 = 108)
    await declareInnings(live.matchId, scorerUserId);

    // 2nd innings: all out for 0
    const [secondInnings] = await db
      .insert(innings)
      .values({
        matchId: live.matchId,
        inningsNumber: 2,
        battingTeamId: live.bowlingTeamId,
        bowlingTeamId: live.battingTeamId,
        target: 109,
      })
      .returning();

    await db.update(matches).set({ status: 'live' }).where(eq(matches.id, live.matchId));

    for (let w = 0; w < PLAYERS_PER_SIDE - 1; w++) {
      const result = await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
        overNumber: 0,
        ballNumber: w + 1,
        strikerId: awayPlayerIds[w]!,
        nonStrikerId: awayPlayerIds[Math.min(w + 1, PLAYERS_PER_SIDE - 1)]!,
        bowlerId: homePlayerIds[2]!,
        runsFromBat: 0,
        isWicket: true,
        wicket: {
          dismissedPlayerId: awayPlayerIds[w]!,
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      }));
      if (result.matchComplete) break;
    }

    const [analytics] = await db.select().from(matchAnalytics).where(eq(matchAnalytics.matchId, live.matchId));
    const awards = analytics!.mvpScores as {
      playerScores: Array<{ playerId: string; battingScore: number; bowlingScore: number; totalScore: number }>;
    };

    const batter = awards.playerScores.find((p) => p.playerId === homePlayerIds[0]!);
    expect(batter).toBeDefined();

    // 108 runs, 18 sixes:
    // base = 108/10 = 10.8
    // 50 bonus = 2
    // 100 bonus = 3
    // fours: 0 × 0.1 = 0
    // sixes: 18 × 0.2 = 3.6
    // Total: 10.8 + 2 + 3 + 3.6 = 19.4
    expect(batter!.battingScore).toBeCloseTo(19.4, 1);
  });

  it('playerScores contains both batting and bowling for all-rounders', async () => {
    const live = await createLiveMatch({ totalOvers: 2 });

    // 1st innings: Player 0 scores 6 runs
    await recordDelivery(live.matchId, scorerUserId, deliveryInput(live.inningsId, {
      overNumber: 0,
      ballNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 4,
      isBoundaryFour: true,
    }));

    await declareInnings(live.matchId, scorerUserId);

    // 2nd innings: Player 0 now bowls and takes a wicket
    const [secondInnings] = await db
      .insert(innings)
      .values({
        matchId: live.matchId,
        inningsNumber: 2,
        battingTeamId: live.bowlingTeamId,
        bowlingTeamId: live.battingTeamId,
        target: 5,
      })
      .returning();

    await db.update(matches).set({ status: 'live' }).where(eq(matches.id, live.matchId));

    // Player 0 bowls and takes wickets → all out
    for (let w = 0; w < PLAYERS_PER_SIDE - 1; w++) {
      const result = await recordDelivery(live.matchId, scorerUserId, deliveryInput(secondInnings!.id, {
        overNumber: 0,
        ballNumber: w + 1,
        strikerId: awayPlayerIds[w]!,
        nonStrikerId: awayPlayerIds[Math.min(w + 1, PLAYERS_PER_SIDE - 1)]!,
        bowlerId: homePlayerIds[0]!, // All-rounder bowls
        runsFromBat: 0,
        isWicket: true,
        wicket: {
          dismissedPlayerId: awayPlayerIds[w]!,
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      }));
      if (result.matchComplete) break;
    }

    const [analytics] = await db.select().from(matchAnalytics).where(eq(matchAnalytics.matchId, live.matchId));
    const awards = analytics!.mvpScores as {
      motmPlayerId: string | null;
      playerScores: Array<{ playerId: string; battingScore: number; bowlingScore: number; totalScore: number }>;
    };

    // Player 0 should have both batting and bowling scores
    const allRounder = awards.playerScores.find((p) => p.playerId === homePlayerIds[0]!);
    expect(allRounder).toBeDefined();
    expect(allRounder!.battingScore).toBeGreaterThan(0); // 4 runs → 0.4 base + 0.1 four = 0.5
    expect(allRounder!.bowlingScore).toBeGreaterThan(0); // 5 wkts → 15 + 3 + 2 = 20
    expect(allRounder!.totalScore).toBe(allRounder!.battingScore + allRounder!.bowlingScore);

    // Should be MOTM (combined score highest)
    expect(awards.motmPlayerId).toBe(homePlayerIds[0]!);
  });
});
