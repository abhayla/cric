import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import {
  battingStats,
  bowlingStats,
  fieldingStats,
  playerCareerStats,
} from '../../src/db/schema/stats.ts';
import { refreshMatchPlayerCareerStats } from '../../src/services/career-stats.service.ts';
import {
  getPlayerProfile,
  getPlayerStats,
  getPlayerMatches,
} from '../../src/services/player.service.ts';

const TEST_SUFFIX = Date.now();

let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
const matchIds: string[] = [];

/** Helper: expect a promise to reject */
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

/** Create a completed match with stats, refresh career stats */
async function createCompletedMatchAndRefresh(opts: {
  format?: string;
  battingRuns?: number;
  ballsFaced?: number;
  fours?: number;
  sixes?: number;
  isNotOut?: boolean;
  bowlerWickets?: number;
  bowlerRuns?: number;
  catches?: number;
  venue?: string;
  matchDate?: string;
}) {
  const format = opts.format ?? 'T20';
  const batterId = homePlayerIds[0]!;
  const bowlerId = awayPlayerIds[0]!;

  // Create match
  const [match] = await db
    .insert(matches)
    .values({
      homeTeamId,
      awayTeamId,
      format,
      totalOvers: 20,
      ballTypeId: 1,
      matchDate: opts.matchDate ?? '2026-06-15',
      playersPerSide: 11,
      status: 'completed',
      createdBy: scorerUserId,
      venue: opts.venue,
    })
    .returning();
  matchIds.push(match!.id);

  // Add match players
  await db.insert(matchPlayers).values([
    { matchId: match!.id, teamId: homeTeamId, playerId: batterId },
    { matchId: match!.id, teamId: awayTeamId, playerId: bowlerId },
  ]);

  // Create innings
  const [inn1] = await db
    .insert(innings)
    .values({
      matchId: match!.id,
      inningsNumber: 1,
      battingTeamId: homeTeamId,
      bowlingTeamId: awayTeamId,
      totalRuns: opts.battingRuns ?? 150,
      totalWickets: 5,
      totalOvers: '20.0',
      isCompleted: true,
      isSuperOver: false,
    })
    .returning();

  const [inn2] = await db
    .insert(innings)
    .values({
      matchId: match!.id,
      inningsNumber: 2,
      battingTeamId: awayTeamId,
      bowlingTeamId: homeTeamId,
      totalRuns: 140,
      totalWickets: 8,
      totalOvers: '20.0',
      isCompleted: true,
      isSuperOver: false,
    })
    .returning();

  // Insert batting stats (home player batted in 1st innings)
  await db.insert(battingStats).values({
    inningsId: inn1!.id,
    playerId: batterId,
    battingPosition: 1,
    runsScored: opts.battingRuns ?? 150,
    ballsFaced: opts.ballsFaced ?? 100,
    fours: opts.fours ?? 15,
    sixes: opts.sixes ?? 5,
    isNotOut: opts.isNotOut ?? false,
  });

  // Insert bowling stats (away player bowled in 1st innings)
  await db.insert(bowlingStats).values({
    inningsId: inn1!.id,
    playerId: bowlerId,
    oversBowled: '4.0',
    maidens: 0,
    runsConceded: opts.bowlerRuns ?? 35,
    wicketsTaken: opts.bowlerWickets ?? 2,
  });

  // Insert fielding stats
  if ((opts.catches ?? 0) > 0) {
    await db.insert(fieldingStats).values({
      inningsId: inn2!.id,
      playerId: batterId,
      catches: opts.catches ?? 0,
      runOuts: 0,
      stumpings: 0,
    });
  }

  // Insert match result
  await db.insert(matchResult).values({
    matchId: match!.id,
    winnerTeamId: homeTeamId,
    resultType: 'runs',
    margin: 10,
    summary: 'Won by 10 runs',
  });

  // Refresh career stats (same as what happens after completeMatch)
  await db.transaction(async (tx) => {
    await refreshMatchPlayerCareerStats(tx, match!.id);
  });

  return match!.id;
}

beforeAll(async () => {
  // Create scorer
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-e2e-scorer-${TEST_SUFFIX}`,
      phone: '+919876900001',
      displayName: 'E2E Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Create home players
  const homeValues = Array.from({ length: 3 }, (_, i) => ({
    firebaseUid: `test-e2e-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987690${String(i + 10).padStart(4, '0')}`,
    displayName: `E2E Home Player ${i + 1}`,
    playerRole: i === 0 ? 'batter' : 'bowler',
    battingStyle: 'right_hand',
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away players
  const awayValues = Array.from({ length: 3 }, (_, i) => ({
    firebaseUid: `test-e2e-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987691${String(i + 10).padStart(4, '0')}`,
    displayName: `E2E Away Player ${i + 1}`,
    playerRole: i === 0 ? 'bowler' : 'batter',
    battingStyle: 'right_hand',
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `E2E Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `E2E Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add to rosters
  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' as const })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' as const })),
  );
});

afterAll(async () => {
  // Clean up career stats
  if (testUserIds.length > 0) {
    await db
      .delete(playerCareerStats)
      .where(inArray(playerCareerStats.playerId, testUserIds));
  }

  // Delete matches and cascaded data
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
// Full Pipeline: Match Completion → Stats → API
// ============================================================

describe('Player Stats E2E Pipeline', () => {
  describe('Match completion → career stats refresh', () => {
    it('refreshes career stats for all players after match completion', async () => {
      await createCompletedMatchAndRefresh({
        battingRuns: 75,
        ballsFaced: 50,
        fours: 8,
        sixes: 3,
        catches: 2,
      });

      // Verify batter career stats were created
      const [batterStats] = await db
        .select()
        .from(playerCareerStats)
        .where(eq(playerCareerStats.playerId, homePlayerIds[0]!));

      expect(batterStats).toBeDefined();
      expect(Number(batterStats!.totalRuns)).toBe(75);
      expect(Number(batterStats!.fours)).toBe(8);
      expect(Number(batterStats!.sixes)).toBe(3);
    });

    it('accumulates stats across multiple matches', async () => {
      // First match already created above with 75 runs
      await createCompletedMatchAndRefresh({
        battingRuns: 50,
        ballsFaced: 40,
        fours: 5,
        sixes: 1,
        matchDate: '2026-06-16',
      });

      const stats = await db
        .select()
        .from(playerCareerStats)
        .where(eq(playerCareerStats.playerId, homePlayerIds[0]!));

      // Should have "all" format stats accumulated
      const allStats = stats.find((s) => s.format === 'all');
      expect(allStats).toBeDefined();
      expect(Number(allStats!.totalRuns)).toBe(125); // 75 + 50
      expect(Number(allStats!.matchesPlayed)).toBe(2);
    });

    it('separates stats by format', async () => {
      await createCompletedMatchAndRefresh({
        format: 'ODI',
        battingRuns: 100,
        ballsFaced: 80,
        fours: 10,
        sixes: 4,
        matchDate: '2026-06-17',
      });

      const stats = await db
        .select()
        .from(playerCareerStats)
        .where(eq(playerCareerStats.playerId, homePlayerIds[0]!));

      const t20Stats = stats.find((s) => s.format === 'T20');
      const odiStats = stats.find((s) => s.format === 'ODI');
      const allStats = stats.find((s) => s.format === 'all');

      expect(t20Stats).toBeDefined();
      expect(odiStats).toBeDefined();
      expect(allStats).toBeDefined();

      expect(Number(t20Stats!.totalRuns)).toBe(125); // 75 + 50
      expect(Number(odiStats!.totalRuns)).toBe(100);
      expect(Number(allStats!.totalRuns)).toBe(225); // 75 + 50 + 100
    });
  });

  describe('getPlayerProfile API', () => {
    it('returns player profile with team affiliations', async () => {
      const result = await getPlayerProfile(homePlayerIds[0]!);

      expect(result.id).toBe(homePlayerIds[0]!);
      expect(result.displayName).toContain('E2E Home Player');
      expect(result.teams.length).toBeGreaterThanOrEqual(1);
      expect(result.teams[0]!.teamName).toContain('E2E Home');
    });

    it('throws 404 for non-existent player', async () => {
      await expectToReject(
        () => getPlayerProfile('00000000-0000-0000-0000-000000000000'),
        'not found',
      );
    });
  });

  describe('getPlayerStats API', () => {
    it('returns career stats for all formats by default', async () => {
      const result = await getPlayerStats(homePlayerIds[0]!);

      expect(result).not.toBeNull();
      expect(result!.format).toBe('all');
      expect(Number(result!.totalRuns)).toBe(225);
      expect(Number(result!.matchesPlayed)).toBe(3);
    });

    it('returns format-specific stats', async () => {
      const result = await getPlayerStats(homePlayerIds[0]!, 'T20');

      expect(result).not.toBeNull();
      expect(result!.format).toBe('T20');
      expect(Number(result!.totalRuns)).toBe(125);
      expect(Number(result!.matchesPlayed)).toBe(2);
    });

    it('returns null for player with no stats', async () => {
      // homePlayerIds[2] was never a batter/bowler in any match
      const result = await getPlayerStats(homePlayerIds[2]!);
      expect(result).toBeNull();
    });
  });

  describe('getPlayerMatches API', () => {
    it('returns paginated match history', async () => {
      const result = await getPlayerMatches(homePlayerIds[0]!);

      expect(result.matches.length).toBeGreaterThanOrEqual(3);
      expect(result.total).toBeGreaterThanOrEqual(3);
      expect(result.page).toBe(1);
    });

    it('includes team scores and results', async () => {
      const result = await getPlayerMatches(homePlayerIds[0]!);

      const match = result.matches[0]!;
      expect(match.homeTeam).toBeDefined();
      expect(match.awayTeam).toBeDefined();
      expect(match.teamScores.length).toBeGreaterThanOrEqual(1);
    });

    it('includes personal performance stats', async () => {
      const result = await getPlayerMatches(homePlayerIds[0]!);

      // Find a match where our player has batting stats
      const matchWithStats = result.matches.find(
        (m: any) => m.batting && m.batting.runsScored > 0,
      );
      expect(matchWithStats).toBeDefined();
      expect(matchWithStats!.batting.runsScored).toBeGreaterThan(0);
    });

    it('filters by result (won)', async () => {
      const result = await getPlayerMatches(homePlayerIds[0]!, {
        result: 'won',
      });

      // All matches created have homeTeam winning
      expect(result.matches.length).toBeGreaterThanOrEqual(1);
    });

    it('paginates correctly', async () => {
      const page1 = await getPlayerMatches(homePlayerIds[0]!, {
        page: 1,
        limit: 2,
      });

      expect(page1.matches.length).toBeLessThanOrEqual(2);
      expect(page1.page).toBe(1);

      if (page1.total > 2) {
        const page2 = await getPlayerMatches(homePlayerIds[0]!, {
          page: 2,
          limit: 2,
        });
        expect(page2.page).toBe(2);
        expect(page2.matches.length).toBeGreaterThanOrEqual(1);
      }
    });

    it('returns empty for player with no matches', async () => {
      const result = await getPlayerMatches(homePlayerIds[2]!);
      expect(result.matches.length).toBe(0);
      expect(result.total).toBe(0);
    });

    it('orders matches by date descending', async () => {
      const result = await getPlayerMatches(homePlayerIds[0]!);

      if (result.matches.length >= 2) {
        const dates = result.matches.map((m: any) => m.matchDate);
        for (let i = 0; i < dates.length - 1; i++) {
          expect(dates[i]! >= dates[i + 1]!).toBe(true);
        }
      }
    });
  });

  describe('Super over exclusion', () => {
    it('does not count super over stats in career totals', async () => {
      // Get current stats before super over match
      const beforeStats = await getPlayerStats(homePlayerIds[0]!, 'T20');
      const beforeRuns = beforeStats ? Number(beforeStats.totalRuns) : 0;

      // Create match with super over innings
      const [soMatch] = await db
        .insert(matches)
        .values({
          homeTeamId,
          awayTeamId,
          format: 'T20',
          totalOvers: 20,
          ballTypeId: 1,
          matchDate: '2026-06-20',
          playersPerSide: 11,
          status: 'completed',
          createdBy: scorerUserId,
        })
        .returning();
      matchIds.push(soMatch!.id);

      await db.insert(matchPlayers).values([
        { matchId: soMatch!.id, teamId: homeTeamId, playerId: homePlayerIds[0]! },
        { matchId: soMatch!.id, teamId: awayTeamId, playerId: awayPlayerIds[0]! },
      ]);

      // Regular innings
      const [regInn] = await db
        .insert(innings)
        .values({
          matchId: soMatch!.id,
          inningsNumber: 1,
          battingTeamId: homeTeamId,
          bowlingTeamId: awayTeamId,
          totalRuns: 30,
          totalWickets: 2,
          totalOvers: '20.0',
          isCompleted: true,
          isSuperOver: false,
        })
        .returning();

      await db.insert(innings).values({
        matchId: soMatch!.id,
        inningsNumber: 2,
        battingTeamId: awayTeamId,
        bowlingTeamId: homeTeamId,
        totalRuns: 30,
        totalWickets: 3,
        totalOvers: '20.0',
        isCompleted: true,
        isSuperOver: false,
      });

      // Super over (should be excluded)
      const [soInn] = await db
        .insert(innings)
        .values({
          matchId: soMatch!.id,
          inningsNumber: 3,
          battingTeamId: homeTeamId,
          bowlingTeamId: awayTeamId,
          totalRuns: 15,
          totalWickets: 0,
          totalOvers: '1.0',
          isCompleted: true,
          isSuperOver: true,
        })
        .returning();

      // Batting stats for regular innings
      await db.insert(battingStats).values({
        inningsId: regInn!.id,
        playerId: homePlayerIds[0]!,
        battingPosition: 1,
        runsScored: 30,
        ballsFaced: 25,
      });

      // Batting stats for super over (should be excluded)
      await db.insert(battingStats).values({
        inningsId: soInn!.id,
        playerId: homePlayerIds[0]!,
        battingPosition: 1,
        runsScored: 15,
        ballsFaced: 6,
      });

      await db.insert(matchResult).values({
        matchId: soMatch!.id,
        winnerTeamId: homeTeamId,
        resultType: 'super_over',
        margin: 0,
        summary: 'Won in Super Over',
      });

      await db.transaction(async (tx) => {
        await refreshMatchPlayerCareerStats(tx, soMatch!.id);
      });

      // Verify super over runs NOT included
      const afterStats = await getPlayerStats(homePlayerIds[0]!, 'T20');
      const afterRuns = afterStats ? Number(afterStats.totalRuns) : 0;

      // Should only add 30 (regular), not 15 (super over)
      expect(afterRuns).toBe(beforeRuns + 30);
    });
  });
});
