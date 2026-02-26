import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray, and, desc } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import { deliveries } from '../../src/db/schema/deliveries.ts';
import { battingStats, bowlingStats } from '../../src/db/schema/stats.ts';
import { activityFeed } from '../../src/db/schema/activity-feed.ts';
import {
  createMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';
import {
  recordDelivery,
  undoDelivery,
} from '../../src/services/scoring.service.ts';

const TEST_SUFFIX = `ms-${Date.now()}`;
const PLAYERS_PER_SIDE = 11;

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

// Dismissal type IDs (loaded from seed data)
let dismissalBowledId: number;

/** Create a live match with both playing XI set and toss completed */
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

/** Helper to build a standard delivery input */
function makeDeliveryInput(
  inningsId: string,
  overNumber: number,
  ballNumber: number,
  opts: {
    strikerId?: string;
    nonStrikerId?: string;
    bowlerId?: string;
    runsFromBat?: number;
    isWide?: boolean;
    isNoBall?: boolean;
    isBoundaryFour?: boolean;
    isBoundarySix?: boolean;
    isWicket?: boolean;
    wicket?: {
      dismissedPlayerId: string;
      dismissalTypeId: number;
      fielderId?: string;
      bowlerCredited: boolean;
    };
  } = {},
) {
  return {
    inningsId,
    overNumber,
    ballNumber,
    strikerId: opts.strikerId ?? homePlayerIds[0]!,
    nonStrikerId: opts.nonStrikerId ?? homePlayerIds[1]!,
    bowlerId: opts.bowlerId ?? awayPlayerIds[0]!,
    runsFromBat: opts.runsFromBat ?? 0,
    isWide: opts.isWide ?? false,
    isNoBall: opts.isNoBall ?? false,
    isBye: false,
    isLegBye: false,
    wideRuns: 0,
    noBallRuns: 0,
    byeRuns: 0,
    legByeRuns: 0,
    isWicket: opts.isWicket ?? false,
    isBoundaryFour: opts.isBoundaryFour ?? false,
    isBoundarySix: opts.isBoundarySix ?? false,
    wicket: opts.wicket,
  };
}

beforeAll(async () => {
  // Create scorer user
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-ms-scorer-${TEST_SUFFIX}`,
      phone: '+919870100001',
      displayName: 'MS Test Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Create home team players (12)
  const homeValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-ms-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987010${String(i + 10).padStart(4, '0')}`,
    displayName: `MS Home ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away team players (12)
  const awayValues = Array.from({ length: 12 }, (_, i) => ({
    firebaseUid: `test-ms-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987011${String(i + 10).padStart(4, '0')}`,
    displayName: `MS Away ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `MS Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `MS Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
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
    .from((await import('../../src/db/schema/master-data.ts')).dismissalTypes);
  for (const row of dismissalRows) {
    if (row.name === 'bowled') dismissalBowledId = row.id;
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
    await db.delete(matchResult).where(inArray(matchResult.matchId, matchIds));
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  // Clean up activity feed events for test users
  if (testUserIds.length > 0) {
    await db.delete(activityFeed).where(inArray(activityFeed.userId, testUserIds));
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
// BATTING MILESTONES
// ============================================================
describe('Scoring Milestones', () => {
  describe('Half-century detection', () => {
    it('detects half-century at exactly 50 runs', async () => {
      const { matchId, inningsId } = await createLiveMatch();
      let seq = 1;

      // Score 48 runs: 8 sixes (8 * 6 = 48)
      // Over 0: balls 1-6 with alternating bowlers at over boundaries
      // We score sixes to reach 48 quickly, then a 2 to reach exactly 50
      for (let i = 0; i < 8; i++) {
        const overNumber = Math.floor(seq / 7); // approximate — let the service track
        // After 6 legal balls the service increments the over.
        // To keep it simple: record balls sequentially. The service handles overs.
        const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          Math.floor(i / 6),
          (i % 6) + 1,
          {
            runsFromBat: 6,
            isBoundarySix: true,
            // After over 0 (6 balls) the bowler must change
            bowlerId: i < 6 ? awayPlayerIds[0]! : awayPlayerIds[1]!,
          },
        ));
        expect(result.milestones.length).toBe(0);
      }

      // Now score 2 to reach exactly 50 (48 + 2 = 50)
      const fiftyResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        1,
        3,
        {
          runsFromBat: 2,
          bowlerId: awayPlayerIds[1]!,
        },
      ));

      expect(fiftyResult.milestones.length).toBe(1);
      expect(fiftyResult.milestones[0]!.type).toBe('half_century');
      expect(fiftyResult.milestones[0]!.playerId).toBe(homePlayerIds[0]!);
      expect(fiftyResult.milestones[0]!.playerName).toBe('MS Home 1');
    });
  });

  describe('Century detection', () => {
    it('detects century at exactly 100 runs without duplicate half-century', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      // Score 96 runs: 16 sixes (16 * 6 = 96)
      // Overs 0-2, with bowler changes at over boundaries
      let ballCount = 0;
      const bowlers = [awayPlayerIds[0]!, awayPlayerIds[1]!, awayPlayerIds[2]!];

      for (let i = 0; i < 16; i++) {
        const overNumber = Math.floor(ballCount / 6);
        const ballNumber = (ballCount % 6) + 1;
        const bowlerId = bowlers[overNumber % bowlers.length]!;

        const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          overNumber,
          ballNumber,
          {
            runsFromBat: 6,
            isBoundarySix: true,
            bowlerId,
          },
        ));
        ballCount++;

        // Check half-century milestone at ball 8+1=9 (48 + 6 = 54 crosses 50)
        // Actually at ball 9 (8th six = 48, 9th six would give 54 which crosses 50 but not 100)
        if (i === 8) {
          // 9th six = 54 runs total, crosses 50
          expect(result.milestones.some((m) => m.type === 'half_century')).toBe(true);
        }
      }

      // Score 4 to reach exactly 100 (96 + 4 = 100)
      const overNumber = Math.floor(ballCount / 6);
      const ballNumber = (ballCount % 6) + 1;
      const bowlerId = bowlers[overNumber % bowlers.length]!;

      const centuryResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        overNumber,
        ballNumber,
        {
          runsFromBat: 4,
          isBoundaryFour: true,
          bowlerId,
        },
      ));

      // Should have century but NOT half_century
      expect(centuryResult.milestones.length).toBe(1);
      expect(centuryResult.milestones[0]!.type).toBe('century');
      expect(centuryResult.milestones[0]!.playerId).toBe(homePlayerIds[0]!);
    });
  });

  describe('No milestone below threshold', () => {
    it('no milestone at 49 runs', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      // Score 48 runs: 8 sixes
      for (let i = 0; i < 8; i++) {
        await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          Math.floor(i / 6),
          (i % 6) + 1,
          {
            runsFromBat: 6,
            isBoundarySix: true,
            bowlerId: i < 6 ? awayPlayerIds[0]! : awayPlayerIds[1]!,
          },
        ));
      }

      // Score 1 to reach 49
      const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        1,
        3,
        {
          runsFromBat: 1,
          bowlerId: awayPlayerIds[1]!,
        },
      ));

      expect(result.milestones.length).toBe(0);
    });
  });

  // ============================================================
  // BOWLING MILESTONES
  // ============================================================
  describe('3-wicket haul detection', () => {
    it('detects 3-wicket haul at exactly 3 wickets', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      const bowlerId = awayPlayerIds[0]!;

      // Take 2 wickets first (balls 1 and 2 of over 0)
      for (let i = 0; i < 2; i++) {
        const dismissedId = homePlayerIds[i === 0 ? 0 : 1]!;
        // After a wicket, next batter comes in
        const strikerId = i === 0 ? homePlayerIds[0]! : homePlayerIds[2]!;
        const nonStrikerId = i === 0 ? homePlayerIds[1]! : homePlayerIds[1]!;

        const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          0,
          i + 1,
          {
            strikerId,
            nonStrikerId: i === 0 ? homePlayerIds[1]! : homePlayerIds[1]!,
            bowlerId,
            isWicket: true,
            wicket: {
              dismissedPlayerId: dismissedId,
              dismissalTypeId: dismissalBowledId,
              bowlerCredited: true,
            },
          },
        ));
        expect(result.milestones.filter((m) => m.type === 'three_wicket_haul').length).toBe(0);
      }

      // 3rd wicket: should trigger 3-wicket haul
      const thirdWicketResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        0,
        3,
        {
          strikerId: homePlayerIds[3]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId,
          isWicket: true,
          wicket: {
            dismissedPlayerId: homePlayerIds[3]!,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        },
      ));

      const threeWicketMilestones = thirdWicketResult.milestones.filter(
        (m) => m.type === 'three_wicket_haul',
      );
      expect(threeWicketMilestones.length).toBe(1);
      expect(threeWicketMilestones[0]!.playerId).toBe(bowlerId);
    });
  });

  describe('5-wicket haul detection', () => {
    it('detects 5-wicket haul at exactly 5 wickets', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      const bowlerId = awayPlayerIds[0]!;
      let lastResult: any;

      // Take 5 wickets (across multiple overs if needed)
      for (let i = 0; i < 5; i++) {
        // Striker is the batter being dismissed, next batter replaces
        const strikerId = homePlayerIds[i]!;
        const nonStrikerId = homePlayerIds[i === 0 ? 1 : (i + 1 > 10 ? 10 : i + 1)]!;

        // Ensure different non-striker than striker
        const effectiveNonStriker = strikerId === nonStrikerId
          ? homePlayerIds[(i + 2) % homePlayerIds.length]!
          : nonStrikerId;

        lastResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          Math.floor(i / 6),
          (i % 6) + 1,
          {
            strikerId,
            nonStrikerId: effectiveNonStriker,
            bowlerId,
            isWicket: true,
            wicket: {
              dismissedPlayerId: strikerId,
              dismissalTypeId: dismissalBowledId,
              bowlerCredited: true,
            },
          },
        ));
      }

      // 5th wicket should trigger five_wicket_haul
      const fiveWicketMilestones = lastResult.milestones.filter(
        (m: any) => m.type === 'five_wicket_haul',
      );
      expect(fiveWicketMilestones.length).toBe(1);
      expect(fiveWicketMilestones[0]!.playerId).toBe(bowlerId);

      // Should NOT have three_wicket_haul on the 5th wicket (that was on the 3rd)
      const threeWicketOn5th = lastResult.milestones.filter(
        (m: any) => m.type === 'three_wicket_haul',
      );
      expect(threeWicketOn5th.length).toBe(0);
    });
  });

  // ============================================================
  // HAT-TRICK
  // ============================================================
  describe('Hat-trick detection', () => {
    it('detects hat-trick: 3 consecutive wickets by same bowler', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      const bowlerId = awayPlayerIds[0]!;

      // Take 3 consecutive wickets
      let lastResult: any;
      for (let i = 0; i < 3; i++) {
        const strikerId = homePlayerIds[i]!;
        const nonStrikerId = homePlayerIds[i + 1 < 3 ? i + 1 : 3]!;
        const effectiveNonStriker = strikerId === nonStrikerId
          ? homePlayerIds[(i + 2) % homePlayerIds.length]!
          : nonStrikerId;

        lastResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          0,
          i + 1,
          {
            strikerId,
            nonStrikerId: effectiveNonStriker,
            bowlerId,
            isWicket: true,
            wicket: {
              dismissedPlayerId: strikerId,
              dismissalTypeId: dismissalBowledId,
              bowlerCredited: true,
            },
          },
        ));
      }

      const hatTrickMilestones = lastResult.milestones.filter(
        (m: any) => m.type === 'hat_trick',
      );
      expect(hatTrickMilestones.length).toBe(1);
      expect(hatTrickMilestones[0]!.playerId).toBe(bowlerId);
    });

    it('no hat-trick when broken by non-wicket delivery', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      const bowlerId = awayPlayerIds[0]!;

      // Wicket 1
      await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        0,
        1,
        {
          strikerId: homePlayerIds[0]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId,
          isWicket: true,
          wicket: {
            dismissedPlayerId: homePlayerIds[0]!,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        },
      ));

      // Dot ball (breaks consecutive wickets)
      await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        0,
        2,
        {
          strikerId: homePlayerIds[2]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId,
          runsFromBat: 0,
        },
      ));

      // Wicket 2
      await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        0,
        3,
        {
          strikerId: homePlayerIds[2]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId,
          isWicket: true,
          wicket: {
            dismissedPlayerId: homePlayerIds[2]!,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        },
      ));

      // Wicket 3
      const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        0,
        4,
        {
          strikerId: homePlayerIds[3]!,
          nonStrikerId: homePlayerIds[1]!,
          bowlerId,
          isWicket: true,
          wicket: {
            dismissedPlayerId: homePlayerIds[3]!,
            dismissalTypeId: dismissalBowledId,
            bowlerCredited: true,
          },
        },
      ));

      // 3-wicket haul should trigger (3 total wickets), but NOT hat-trick
      const hatTrickMilestones = result.milestones.filter(
        (m) => m.type === 'hat_trick',
      );
      expect(hatTrickMilestones.length).toBe(0);

      // 3-wicket haul SHOULD be present
      const threeWicket = result.milestones.filter(
        (m) => m.type === 'three_wicket_haul',
      );
      expect(threeWicket.length).toBe(1);
    });
  });

  // ============================================================
  // UNDO REMOVES MILESTONE EVENTS
  // ============================================================
  describe('Undo removes milestone activity events', () => {
    it('undoDelivery deletes activity_feed events linked to that delivery', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      const bowlerId = awayPlayerIds[0]!;

      // Take 3 consecutive wickets to trigger hat-trick + 3-wicket haul
      let lastDeliveryId: string = '';
      for (let i = 0; i < 3; i++) {
        const strikerId = homePlayerIds[i]!;
        const nonStrikerId = homePlayerIds[i + 1 < 3 ? i + 1 : 3]!;
        const effectiveNonStriker = strikerId === nonStrikerId
          ? homePlayerIds[(i + 2) % homePlayerIds.length]!
          : nonStrikerId;

        const result = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          0,
          i + 1,
          {
            strikerId,
            nonStrikerId: effectiveNonStriker,
            bowlerId,
            isWicket: true,
            wicket: {
              dismissedPlayerId: strikerId,
              dismissalTypeId: dismissalBowledId,
              bowlerCredited: true,
            },
          },
        ));
        lastDeliveryId = result.delivery.id;
      }

      // Wait briefly for fire-and-forget milestone emit to complete
      await new Promise((resolve) => setTimeout(resolve, 200));

      // Verify activity_feed events exist for this delivery
      const beforeEvents = await db
        .select()
        .from(activityFeed)
        .where(eq(activityFeed.deliveryId, lastDeliveryId));
      expect(beforeEvents.length).toBeGreaterThan(0);

      // Undo the last delivery
      await undoDelivery(matchId, lastDeliveryId, scorerUserId);

      // Wait briefly for fire-and-forget delete to complete
      await new Promise((resolve) => setTimeout(resolve, 200));

      // Verify activity_feed events are deleted for that deliveryId
      const afterEvents = await db
        .select()
        .from(activityFeed)
        .where(eq(activityFeed.deliveryId, lastDeliveryId));
      expect(afterEvents.length).toBe(0);
    });
  });

  // ============================================================
  // WIDE DOES NOT TRIGGER BATTING MILESTONE
  // ============================================================
  describe('Wide delivery does not trigger batting milestone', () => {
    it('wide does not trigger half-century even if batter had 49 runs', async () => {
      const { matchId, inningsId } = await createLiveMatch();

      // Score 48 runs: 8 sixes
      for (let i = 0; i < 8; i++) {
        await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
          inningsId,
          Math.floor(i / 6),
          (i % 6) + 1,
          {
            runsFromBat: 6,
            isBoundarySix: true,
            bowlerId: i < 6 ? awayPlayerIds[0]! : awayPlayerIds[1]!,
          },
        ));
      }

      // Score 1 to reach 49
      await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        1,
        3,
        {
          runsFromBat: 1,
          bowlerId: awayPlayerIds[1]!,
        },
      ));

      // Wide delivery — wide runs go to extras, not batter's score
      // So batter stays at 49
      const wideResult = await recordDelivery(matchId, scorerUserId, makeDeliveryInput(
        inningsId,
        1,
        4,
        {
          runsFromBat: 0,
          isWide: true,
          bowlerId: awayPlayerIds[1]!,
        },
      ));

      // No batting milestone should fire (batter still at 49)
      const battingMilestones = wideResult.milestones.filter(
        (m) => m.type === 'half_century' || m.type === 'century',
      );
      expect(battingMilestones.length).toBe(0);
    });
  });
});
