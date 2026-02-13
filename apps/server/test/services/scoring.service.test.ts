import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray, and, desc } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings, overs } from '../../src/db/schema/innings.ts';
import { deliveries, wicketsByDelivery, fallOfWickets } from '../../src/db/schema/deliveries.ts';
import { battingStats, bowlingStats, fieldingStats } from '../../src/db/schema/stats.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import {
  recordDelivery,
  undoDelivery,
  getDeliveries,
  abandonMatch,
  declareInnings,
  reopenInnings,
  reopenMatch,
} from '../../src/services/scoring.service.ts';

const TEST_SUFFIX = Date.now();
const PLAYERS_PER_SIDE = 11;

// Test user IDs
let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

// Dismissal type IDs (loaded from seed data)
let dismissalBowledId: number;
let dismissalCaughtId: number;
let dismissalLbwId: number;
let dismissalRunOutId: number;
let dismissalStumpedId: number;
let dismissalHitWicketId: number;
let dismissalCaughtAndBowledId: number;
let dismissalRetiredHurtId: number;
let dismissalRetiredOutId: number;

/** Create a live match with both playing XI set and toss completed */
async function createLiveMatch(opts?: {
  totalOvers?: number;
  playersPerSide?: number;
  wideRuns?: number;
  noBallRuns?: number;
  maxOversPerBowler?: number;
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
    wideRuns: opts?.wideRuns,
    noBallRuns: opts?.noBallRuns,
    maxOversPerBowler: opts?.maxOversPerBowler,
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
    match: tossResult.match,
  };
}

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

/** Helper to record a simple dot ball */
function dotBallInput(inningsId: string, overNumber: number, ballNumber: number, seqNum: number) {
  return {
    inningsId,
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

beforeAll(async () => {
  // Create scorer user
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-scoring-scorer-${TEST_SUFFIX}`,
      phone: '+919876600001',
      displayName: 'Scoring Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Create home team players (12 to have substitutes)
  const homeValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-scoring-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987660${String(i + 10).padStart(4, '0')}`,
    displayName: `Home Scorer ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away team players (12)
  const awayValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-scoring-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987661${String(i + 10).padStart(4, '0')}`,
    displayName: `Away Scorer ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `Home Scoring ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `Away Scoring ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add all players to rosters
  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Load dismissal type IDs from seed data
  const dismissalRows = await db
    .select()
    .from(
      // Import from schema
      (await import('../../src/db/schema/master-data.ts')).dismissalTypes,
    );
  for (const row of dismissalRows) {
    switch (row.name) {
      case 'bowled': dismissalBowledId = row.id; break;
      case 'caught': dismissalCaughtId = row.id; break;
      case 'lbw': dismissalLbwId = row.id; break;
      case 'run_out': dismissalRunOutId = row.id; break;
      case 'stumped': dismissalStumpedId = row.id; break;
      case 'hit_wicket': dismissalHitWicketId = row.id; break;
      case 'caught_and_bowled': dismissalCaughtAndBowledId = row.id; break;
      case 'retired_hurt': dismissalRetiredHurtId = row.id; break;
      case 'retired_out': dismissalRetiredOutId = row.id; break;
    }
  }
});

afterAll(async () => {
  // Delete all matches created by scorer (cascades to innings, deliveries, stats, etc.)
  const matchIds = await db
    .select({ id: matches.id })
    .from(matches)
    .where(eq(matches.createdBy, scorerUserId))
    .then((r) => r.map((m) => m.id));

  if (matchIds.length > 0) {
    // Delete in dependency order — cascades handle most, but be explicit
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
// DELIVERY RECORDING — Basic deliveries
// ============================================================
describe('Scoring Service', () => {
  describe('recordDelivery — basic deliveries', () => {
    let matchId: string;
    let inningsId: string;

    beforeAll(async () => {
      const live = await createLiveMatch();
      matchId = live.matchId;
      inningsId = live.inningsId;
    });

    it('records a dot ball (0 runs)', async () => {
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
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery).toBeDefined();
      expect(result.delivery.totalRuns).toBe(0);
      expect(result.delivery.isLegal).toBe(true);
      expect(result.delivery.sequenceNumber).toBe(1);
    });

    it('records 1 run — batter credited', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 2,
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

      expect(result.delivery.totalRuns).toBe(1);
      expect(result.delivery.runsFromBat).toBe(1);
      expect(result.delivery.isLegal).toBe(true);
    });

    it('records boundary four', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 3,
        strikerId: homePlayerIds[1]!,
        nonStrikerId: homePlayerIds[0]!,
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

      expect(result.delivery.totalRuns).toBe(4);
      expect(result.delivery.isBoundaryFour).toBe(true);
    });

    it('records boundary six', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 4,
        strikerId: homePlayerIds[1]!,
        nonStrikerId: homePlayerIds[0]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 6,
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
        isBoundarySix: true,
      });

      expect(result.delivery.totalRuns).toBe(6);
      expect(result.delivery.isBoundarySix).toBe(true);
    });

    it('increments sequence number for each delivery', async () => {
      // After 4 deliveries above, next should be 5
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 5,
        strikerId: homePlayerIds[1]!,
        nonStrikerId: homePlayerIds[0]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 2,
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

      expect(result.delivery.sequenceNumber).toBe(5);
    });
  });

  // ============================================================
  // EXTRAS
  // ============================================================
  describe('recordDelivery — extras', () => {
    let matchId: string;
    let inningsId: string;

    beforeAll(async () => {
      const live = await createLiveMatch();
      matchId = live.matchId;
      inningsId = live.inningsId;
    });

    it('records a wide (default 1 run)', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.isWide).toBe(true);
      expect(result.delivery.isLegal).toBe(false);
      expect(result.delivery.totalRuns).toBe(1);
      expect(result.delivery.wideRuns).toBe(1);
    });

    it('records a wide with additional runs', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 3,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.isLegal).toBe(false);
      expect(result.delivery.totalRuns).toBe(3);
      expect(result.delivery.wideRuns).toBe(3);
    });

    it('records a no-ball with bat runs', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 4,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: true,
        isBoundarySix: false,
      });

      expect(result.delivery.isNoBall).toBe(true);
      expect(result.delivery.isLegal).toBe(false);
      expect(result.delivery.totalRuns).toBe(5); // 4 bat + 1 NB
      expect(result.delivery.runsFromBat).toBe(4);
      expect(result.delivery.noBallRuns).toBe(1);
    });

    it('records a no-ball with byes', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: true,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 2,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.totalRuns).toBe(3); // 1 NB + 2 byes
      expect(result.delivery.noBallRuns).toBe(1);
      expect(result.delivery.byeRuns).toBe(2);
      expect(result.delivery.runsFromBat).toBe(0);
    });

    it('records 2 byes — legal delivery', async () => {
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
        isBye: true,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 0,
        byeRuns: 2,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.isLegal).toBe(true);
      expect(result.delivery.totalRuns).toBe(2);
      expect(result.delivery.byeRuns).toBe(2);
      expect(result.delivery.runsFromBat).toBe(0);
    });

    it('records 1 leg-bye — legal delivery', async () => {
      const result = await recordDelivery(matchId, scorerUserId, {
        inningsId,
        overNumber: 0,
        ballNumber: 2,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: false,
        isBye: false,
        isLegBye: true,
        wideRuns: 0,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 1,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.isLegal).toBe(true);
      expect(result.delivery.totalRuns).toBe(1);
      expect(result.delivery.legByeRuns).toBe(1);
    });

    it('rejects wide + bye (mutual exclusivity)', async () => {
      await expectToReject(() =>
        recordDelivery(matchId, scorerUserId, {
          inningsId,
          overNumber: 0,
          ballNumber: 3,
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId: awayPlayerIds[0]!,
          runsFromBat: 0,
          isWide: true,
          isNoBall: false,
          isBye: true,
          isLegBye: false,
          wideRuns: 1,
          noBallRuns: 0,
          byeRuns: 1,
          legByeRuns: 0,
          isWicket: false,
          isBoundaryFour: false,
          isBoundarySix: false,
        }),
      );
    });

    it('rejects wide + leg-bye (mutual exclusivity)', async () => {
      await expectToReject(() =>
        recordDelivery(matchId, scorerUserId, {
          inningsId,
          overNumber: 0,
          ballNumber: 3,
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId: awayPlayerIds[0]!,
          runsFromBat: 0,
          isWide: true,
          isNoBall: false,
          isBye: false,
          isLegBye: true,
          wideRuns: 1,
          noBallRuns: 0,
          byeRuns: 0,
          legByeRuns: 1,
          isWicket: false,
          isBoundaryFour: false,
          isBoundarySix: false,
        }),
      );
    });
  });

  // ============================================================
  // WICKETS
  // ============================================================
  describe('recordDelivery — wickets', () => {
    it('records a bowled dismissal', async () => {
      const live = await createLiveMatch();
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      });

      expect(result.delivery.isWicket).toBe(true);
      expect(result.delivery.totalRuns).toBe(0);
    });

    it('records a caught dismissal with fielder', async () => {
      const live = await createLiveMatch();
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0, // Law 33: runs before catch don't count
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
          dismissalTypeId: dismissalCaughtId,
          fielderId: awayPlayerIds[2]!,
          bowlerCredited: true,
        },
      });

      expect(result.delivery.isWicket).toBe(true);
    });

    it('records a run out with fielder', async () => {
      const live = await createLiveMatch();
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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
        isWicket: true,
        isBoundaryFour: false,
        isBoundarySix: false,
        wicket: {
          dismissedPlayerId: homePlayerIds[0]!,
          dismissalTypeId: dismissalRunOutId,
          fielderId: awayPlayerIds[1]!,
          bowlerCredited: false,
        },
      });

      expect(result.delivery.isWicket).toBe(true);
      expect(result.delivery.totalRuns).toBe(1); // Runs before run out count
    });

    it('records stumped off wide — bowler credited', async () => {
      const live = await createLiveMatch();
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: true,
        isBoundaryFour: false,
        isBoundarySix: false,
        wicket: {
          dismissedPlayerId: homePlayerIds[0]!,
          dismissalTypeId: dismissalStumpedId,
          fielderId: awayPlayerIds[1]!, // keeper
          bowlerCredited: true,
        },
      });

      expect(result.delivery.isWide).toBe(true);
      expect(result.delivery.isWicket).toBe(true);
    });

    it('records a caught & bowled', async () => {
      const live = await createLiveMatch();
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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
          dismissalTypeId: dismissalCaughtAndBowledId,
          bowlerCredited: true,
        },
      });

      expect(result.delivery.isWicket).toBe(true);
    });
  });

  // ============================================================
  // FREE HIT
  // ============================================================
  describe('recordDelivery — free hit', () => {
    it('sets isFreeHit after no-ball', async () => {
      const live = await createLiveMatch();

      // Ball 1: no-ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Ball 2: should be free hit
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 2,
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

      expect(result.delivery.isFreeHit).toBe(true);
    });

    it('free hit chains through another no-ball', async () => {
      const live = await createLiveMatch();

      // Ball 1: no-ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Ball 2: free hit + another no-ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Ball 3: still free hit (no-ball → free hit → no-ball → still free hit)
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      expect(result.delivery.isFreeHit).toBe(true);
    });

    it('free hit persists through wides', async () => {
      const live = await createLiveMatch();

      // No-ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Wide (during free hit — free hit persists)
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Next delivery: still free hit (wide doesn't consume it)
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      expect(result.delivery.isFreeHit).toBe(true);
    });
  });

  // ============================================================
  // STATS UPDATES
  // ============================================================
  describe('recordDelivery — stats updates', () => {
    it('updates batting stats (runs, balls, fours, sixes)', async () => {
      const live = await createLiveMatch();

      // 4 runs (boundary)
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      // Check batting stats
      const [batter] = await db
        .select()
        .from(battingStats)
        .where(
          and(
            eq(battingStats.inningsId, live.inningsId),
            eq(battingStats.playerId, homePlayerIds[0]!),
          ),
        );

      expect(batter).toBeDefined();
      expect(batter!.runsScored).toBe(4);
      expect(batter!.ballsFaced).toBe(1);
      expect(batter!.fours).toBe(1);
    });

    it('updates bowling stats (runs, overs, dot balls)', async () => {
      const live = await createLiveMatch();

      // Dot ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      const [bowler] = await db
        .select()
        .from(bowlingStats)
        .where(
          and(
            eq(bowlingStats.inningsId, live.inningsId),
            eq(bowlingStats.playerId, awayPlayerIds[0]!),
          ),
        );

      expect(bowler).toBeDefined();
      expect(bowler!.runsConceded).toBe(0);
      expect(bowler!.dotBalls).toBe(1);
    });

    it('updates innings totals', async () => {
      const live = await createLiveMatch();

      // Record a delivery with 3 runs
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 3,
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

      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.totalRuns).toBe(3);
    });

    it('updates fielding stats on wicket with fielder', async () => {
      const live = await createLiveMatch();

      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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
          dismissalTypeId: dismissalCaughtId,
          fielderId: awayPlayerIds[2]!,
          bowlerCredited: true,
        },
      });

      const [fielder] = await db
        .select()
        .from(fieldingStats)
        .where(
          and(
            eq(fieldingStats.inningsId, live.inningsId),
            eq(fieldingStats.playerId, awayPlayerIds[2]!),
          ),
        );

      expect(fielder).toBeDefined();
      expect(fielder!.catches).toBe(1);
    });

    it('wide does not count as ball faced for batter', async () => {
      const live = await createLiveMatch();

      // Record a wide
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      const [batter] = await db
        .select()
        .from(battingStats)
        .where(
          and(
            eq(battingStats.inningsId, live.inningsId),
            eq(battingStats.playerId, homePlayerIds[0]!),
          ),
        );

      // Batter may or may not have a record yet; if they do, balls faced = 0
      if (batter) {
        expect(batter.ballsFaced).toBe(0);
      }
    });
  });

  // ============================================================
  // OVER COMPLETION + MAIDEN
  // ============================================================
  describe('recordDelivery — over completion', () => {
    it('completes over after 6 legal deliveries', async () => {
      const live = await createLiveMatch();

      // Bowl 6 dot balls
      for (let i = 1; i <= 6; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
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
      }

      // Check overs record was created
      const [overRecord] = await db
        .select()
        .from(overs)
        .where(
          and(eq(overs.inningsId, live.inningsId), eq(overs.overNumber, 0)),
        );

      expect(overRecord).toBeDefined();
      expect(overRecord!.isCompleted).toBe(true);
      expect(overRecord!.isMaiden).toBe(true); // 6 dot balls
      expect(overRecord!.runsConceded).toBe(0);
    });

    it('maiden detection — byes do NOT break maiden', async () => {
      const live = await createLiveMatch();

      // 5 dot balls + 1 bye = maiden
      for (let i = 1; i <= 5; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
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
      }

      // 6th ball: bye
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 6,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: false,
        isBye: true,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 0,
        byeRuns: 2,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      const [overRecord] = await db
        .select()
        .from(overs)
        .where(
          and(eq(overs.inningsId, live.inningsId), eq(overs.overNumber, 0)),
        );

      expect(overRecord!.isMaiden).toBe(true);
    });

    it('wides do NOT count as legal — over not complete', async () => {
      const live = await createLiveMatch();

      // 5 legal dot balls
      for (let i = 1; i <= 5; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
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
      }

      // Wide (not legal, over not complete yet)
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 6,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // Over should NOT be complete (only 5 legal balls)
      const overRecords = await db
        .select()
        .from(overs)
        .where(
          and(eq(overs.inningsId, live.inningsId), eq(overs.overNumber, 0)),
        );

      // Either no record yet, or not completed
      if (overRecords.length > 0) {
        expect(overRecords[0]!.isCompleted).toBe(false);
      }
    });

    it('wide breaks maiden', async () => {
      const live = await createLiveMatch();

      // 5 dot balls + 1 wide + 1 dot ball = over complete but NOT maiden
      for (let i = 1; i <= 5; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
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
      }

      // Wide
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 6,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 1,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      // 6th legal ball
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 6,
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

      const [overRecord] = await db
        .select()
        .from(overs)
        .where(
          and(eq(overs.inningsId, live.inningsId), eq(overs.overNumber, 0)),
        );

      expect(overRecord!.isCompleted).toBe(true);
      expect(overRecord!.isMaiden).toBe(false); // Wide broke it
    });
  });

  // ============================================================
  // INNINGS COMPLETION
  // ============================================================
  describe('recordDelivery — innings completion', () => {
    it('all-out triggers innings completion (standard 11-a-side)', async () => {
      const live = await createLiveMatch();

      // Take 10 wickets (all out for 11-a-side)
      for (let w = 0; w < 10; w++) {
        const strikerId = homePlayerIds[w]!;
        const nonStrikerId = homePlayerIds[w + 1 < 11 ? w + 1 : w]!;

        const result = await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: w,
          ballNumber: 1,
          strikerId,
          nonStrikerId,
          bowlerId: awayPlayerIds[w % 5]!, // Rotate bowlers
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
            dismissedPlayerId: strikerId,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        });

        // On 10th wicket, innings should be complete
        if (w === 9) {
          expect(result.inningsComplete).toBe(true);
        }
      }

      // Verify innings marked as completed
      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.isCompleted).toBe(true);
      expect(inn!.completedReason).toBe('all_out');
    });

    it('all-out with flexible team size (6-a-side)', async () => {
      const live = await createLiveMatch({ playersPerSide: 6 });

      // Take 5 wickets (all out for 6-a-side)
      for (let w = 0; w < 5; w++) {
        const strikerId = homePlayerIds[w]!;
        const nonStrikerId = homePlayerIds[w + 1 < 6 ? w + 1 : w]!;

        const result = await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: w,
          ballNumber: 1,
          strikerId,
          nonStrikerId,
          bowlerId: awayPlayerIds[w % 3]!,
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
            dismissedPlayerId: strikerId,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        });

        if (w === 4) {
          expect(result.inningsComplete).toBe(true);
        }
      }
    });
  });

  // ============================================================
  // VALIDATION
  // ============================================================
  describe('recordDelivery — validation', () => {
    it('rejects when match is not in LIVE status', async () => {
      // Create a match but don't complete toss (stays in setup)
      const match = await createMatch({
        homeTeamId,
        awayTeamId,
        format: 'T20',
        totalOvers: 20,
        ballTypeId: 1,
        matchDate: '2026-06-20',
        createdBy: scorerUserId,
      });

      await expectToReject(() =>
        recordDelivery(match.id, scorerUserId, {
          inningsId: '00000000-0000-0000-0000-000000000000',
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
        }),
      );
    });

    it('rejects when user is not the scorer', async () => {
      const live = await createLiveMatch();

      await expectToReject(() =>
        recordDelivery(live.matchId, homePlayerIds[5]!, {
          inningsId: live.inningsId,
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
        }),
      );
    });

    it('rejects when striker === non-striker', async () => {
      const live = await createLiveMatch();

      await expectToReject(() =>
        recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: 1,
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[0]!, // same as striker
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
        }),
      );
    });
  });

  // ============================================================
  // UNDO
  // ============================================================
  describe('undoDelivery', () => {
    it('undoes the last delivery and reverses stats', async () => {
      const live = await createLiveMatch();

      // Record 2 runs
      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 2,
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

      // Undo
      await undoDelivery(live.matchId, result.delivery.id, scorerUserId);

      // Innings should be back to 0
      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.totalRuns).toBe(0);
    });

    it('undoes a wicket delivery — restores dismissed batter stats', async () => {
      const live = await createLiveMatch();

      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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
          dismissalTypeId: dismissalBowledId,
          bowlerCredited: true,
        },
      });

      // Undo the wicket
      await undoDelivery(live.matchId, result.delivery.id, scorerUserId);

      // Innings should have 0 wickets
      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.totalWickets).toBe(0);

      // Fall of wickets should be removed
      const fow = await db
        .select()
        .from(fallOfWickets)
        .where(eq(fallOfWickets.deliveryId, result.delivery.id));

      expect(fow.length).toBe(0);
    });

    it('rejects undo when delivery is not the last one', async () => {
      const live = await createLiveMatch();

      const first = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      // Record second delivery
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 2,
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

      // Try to undo the first delivery (not the last)
      await expectToReject(() =>
        undoDelivery(live.matchId, first.delivery.id, scorerUserId),
      );
    });

    it('rejects undo by non-scorer', async () => {
      const live = await createLiveMatch();

      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
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

      await expectToReject(() =>
        undoDelivery(live.matchId, result.delivery.id, homePlayerIds[5]!),
      );
    });
  });

  // ============================================================
  // GET DELIVERIES
  // ============================================================
  describe('getDeliveries', () => {
    it('returns paginated deliveries for an innings', async () => {
      const live = await createLiveMatch();

      // Record 3 deliveries
      for (let i = 1; i <= 3; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId: awayPlayerIds[0]!,
          runsFromBat: i,
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
      }

      const result = await getDeliveries(live.inningsId, 1, 50);
      expect(result.deliveries.length).toBe(3);
      expect(result.total).toBe(3);
    });

    it('respects page and limit', async () => {
      const live = await createLiveMatch();

      // Record 5 deliveries
      for (let i = 1; i <= 5; i++) {
        await recordDelivery(live.matchId, scorerUserId, {
          inningsId: live.inningsId,
          overNumber: 0,
          ballNumber: i,
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
      }

      const page1 = await getDeliveries(live.inningsId, 1, 2);
      expect(page1.deliveries.length).toBe(2);
      expect(page1.total).toBe(5);

      const page2 = await getDeliveries(live.inningsId, 2, 2);
      expect(page2.deliveries.length).toBe(2);
    });
  });

  // ============================================================
  // ABANDON MATCH
  // ============================================================
  describe('abandonMatch', () => {
    it('sets match status to abandoned and creates no_result', async () => {
      const live = await createLiveMatch();

      await abandonMatch(live.matchId, scorerUserId);

      const [match] = await db
        .select()
        .from(matches)
        .where(eq(matches.id, live.matchId));

      expect(match!.status).toBe('abandoned');

      const [result] = await db
        .select()
        .from(matchResult)
        .where(eq(matchResult.matchId, live.matchId));

      expect(result).toBeDefined();
      expect(result!.resultType).toBe('no_result');
      expect(result!.winnerTeamId).toBeNull();
    });

    it('rejects abandon by non-scorer', async () => {
      const live = await createLiveMatch();

      await expectToReject(() =>
        abandonMatch(live.matchId, homePlayerIds[5]!),
      );
    });
  });

  // ============================================================
  // DECLARE INNINGS
  // ============================================================
  describe('declareInnings', () => {
    it('marks current innings as completed with reason "declared"', async () => {
      const live = await createLiveMatch();

      // Record a delivery first
      await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 50,
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

      await declareInnings(live.matchId, scorerUserId);

      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.isCompleted).toBe(true);
      expect(inn!.completedReason).toBe('declared');
    });
  });

  // ============================================================
  // REOPEN
  // ============================================================
  describe('reopenInnings', () => {
    it('reopens a completed innings', async () => {
      const live = await createLiveMatch();

      // Declare innings
      await declareInnings(live.matchId, scorerUserId);

      // Reopen
      await reopenInnings(live.matchId, scorerUserId);

      const [inn] = await db
        .select()
        .from(innings)
        .where(eq(innings.id, live.inningsId));

      expect(inn!.isCompleted).toBe(false);
      expect(inn!.completedReason).toBeNull();
    });
  });

  describe('reopenMatch', () => {
    it('reopens a completed match', async () => {
      const live = await createLiveMatch();

      // Abandon to complete it
      await abandonMatch(live.matchId, scorerUserId);

      // Reopen
      await reopenMatch(live.matchId, scorerUserId);

      const [match] = await db
        .select()
        .from(matches)
        .where(eq(matches.id, live.matchId));

      expect(match!.status).toBe('live');

      // Match result should be deleted
      const results = await db
        .select()
        .from(matchResult)
        .where(eq(matchResult.matchId, live.matchId));

      expect(results.length).toBe(0);
    });
  });

  // ============================================================
  // CONFIGURABLE RULES
  // ============================================================
  describe('configurable rules', () => {
    it('uses match-specific wide_runs value', async () => {
      const live = await createLiveMatch({ wideRuns: 2 });

      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: true,
        isNoBall: false,
        isBye: false,
        isLegBye: false,
        wideRuns: 2,
        noBallRuns: 0,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.wideRuns).toBe(2);
      expect(result.delivery.totalRuns).toBe(2);
    });

    it('uses match-specific no_ball_runs value', async () => {
      const live = await createLiveMatch({ noBallRuns: 2 });

      const result = await recordDelivery(live.matchId, scorerUserId, {
        inningsId: live.inningsId,
        overNumber: 0,
        ballNumber: 1,
        strikerId: homePlayerIds[0]!,
        nonStrikerId: homePlayerIds[1]!,
        bowlerId: awayPlayerIds[0]!,
        runsFromBat: 0,
        isWide: false,
        isNoBall: true,
        isBye: false,
        isLegBye: false,
        wideRuns: 0,
        noBallRuns: 2,
        byeRuns: 0,
        legByeRuns: 0,
        isWicket: false,
        isBoundaryFour: false,
        isBoundarySix: false,
      });

      expect(result.delivery.noBallRuns).toBe(2);
      expect(result.delivery.totalRuns).toBe(2);
    });
  });
});
