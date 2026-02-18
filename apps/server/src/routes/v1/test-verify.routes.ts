import { Elysia } from 'elysia';
import { eq, sql } from 'drizzle-orm';
import { db } from '../../db/index.ts';
import { deliveries } from '../../db/schema/deliveries.ts';
import { innings } from '../../db/schema/innings.ts';
import { matches, matchResult, matchAnalytics } from '../../db/schema/matches.ts';
import { tournamentStandings } from '../../db/schema/tournaments.ts';
import { battingStats, bowlingStats } from '../../db/schema/stats.ts';
import { users } from '../../db/schema/users.ts';
import { teams } from '../../db/schema/teams.ts';

/**
 * Test verification API routes — ONLY enabled when NODE_ENV=test.
 *
 * Provides direct database query endpoints for E2E test assertions.
 */
export const testVerifyRoutes = new Elysia({ prefix: '/api/v1/test' })
  // Guard: only available in test environment
  .onBeforeHandle(({ set, path }) => {
    // Allow health check in any environment
    if (path.endsWith('/health')) return;
    if (process.env.NODE_ENV !== 'test') {
      set.status = 403;
      return { error: 'Test endpoints only available in test environment' };
    }
  })

  // GET /api/v1/test/health — health check (no guard)
  .get('/health', () => ({ status: 'ok', env: process.env.NODE_ENV }))

  // GET /api/v1/test/deliveries/:matchId — all deliveries for a match
  .get('/deliveries/:matchId', async ({ params }) => {
    const matchInnings = await db
      .select({ id: innings.id })
      .from(innings)
      .where(eq(innings.matchId, params.matchId));

    if (matchInnings.length === 0) {
      return { deliveries: [] };
    }

    const inningsIds = matchInnings.map((i) => i.id);
    const allDeliveries = await db
      .select({
        id: deliveries.id,
        inningsId: deliveries.inningsId,
        inningsNumber: innings.inningsNumber,
        overNumber: deliveries.overNumber,
        ballNumber: deliveries.ballNumber,
        sequenceNumber: deliveries.sequenceNumber,
        strikerId: deliveries.strikerId,
        nonStrikerId: deliveries.nonStrikerId,
        bowlerId: deliveries.bowlerId,
        runsFromBat: deliveries.runsFromBat,
        isWide: deliveries.isWide,
        wideRuns: deliveries.wideRuns,
        isNoBall: deliveries.isNoBall,
        noBallRuns: deliveries.noBallRuns,
        isBye: deliveries.isBye,
        byeRuns: deliveries.byeRuns,
        isLegBye: deliveries.isLegBye,
        legByeRuns: deliveries.legByeRuns,
        totalRuns: deliveries.totalRuns,
        isWicket: deliveries.isWicket,
        isLegal: deliveries.isLegal,
        isBoundaryFour: deliveries.isBoundaryFour,
        isBoundarySix: deliveries.isBoundarySix,
        isFreeHit: deliveries.isFreeHit,
        isPenalty: deliveries.isPenalty,
      })
      .from(deliveries)
      .innerJoin(innings, eq(deliveries.inningsId, innings.id))
      .where(sql`${deliveries.inningsId} IN ${inningsIds}`)
      .orderBy(innings.inningsNumber, deliveries.sequenceNumber);

    return { deliveries: allDeliveries };
  })

  // GET /api/v1/test/standings/:tournamentId — raw standings
  .get('/standings/:tournamentId', async ({ params }) => {
    const standings = await db
      .select()
      .from(tournamentStandings)
      .where(eq(tournamentStandings.tournamentId, params.tournamentId));

    return { standings };
  })

  // GET /api/v1/test/match-result/:matchId — match result
  .get('/match-result/:matchId', async ({ params }) => {
    const [result] = await db
      .select()
      .from(matchResult)
      .where(eq(matchResult.matchId, params.matchId))
      .limit(1);

    return { result: result ?? null };
  })

  // GET /api/v1/test/leaderboard/:tournamentId?category=runs|wickets
  .get('/leaderboard/:tournamentId', async ({ params, query }) => {
    const category = (query as any)?.category ?? 'runs';
    const tournamentId = params.tournamentId;

    if (category === 'runs') {
      const result = await db
        .select({
          playerId: battingStats.playerId,
          playerName: users.displayName,
          totalRuns: sql<number>`SUM(${battingStats.runsScored})`,
        })
        .from(battingStats)
        .innerJoin(innings, eq(battingStats.inningsId, innings.id))
        .innerJoin(matches, eq(innings.matchId, matches.id))
        .innerJoin(users, eq(battingStats.playerId, users.id))
        .where(eq(matches.tournamentId, tournamentId))
        .groupBy(battingStats.playerId, users.displayName)
        .orderBy(sql`SUM(${battingStats.runsScored}) DESC`)
        .limit(10);

      return { category, leaderboard: result };
    }

    if (category === 'wickets') {
      const result = await db
        .select({
          playerId: bowlingStats.playerId,
          playerName: users.displayName,
          totalWickets: sql<number>`SUM(${bowlingStats.wicketsTaken})`,
        })
        .from(bowlingStats)
        .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
        .innerJoin(matches, eq(innings.matchId, matches.id))
        .innerJoin(users, eq(bowlingStats.playerId, users.id))
        .where(eq(matches.tournamentId, tournamentId))
        .groupBy(bowlingStats.playerId, users.displayName)
        .orderBy(sql`SUM(${bowlingStats.wicketsTaken}) DESC`)
        .limit(10);

      return { category, leaderboard: result };
    }

    return { category, leaderboard: [] };
  })

  // GET /api/v1/test/match-awards/:matchId — match awards (MOTM, best batsman, best bowler)
  .get('/match-awards/:matchId', async ({ params }) => {
    const [result] = await db
      .select()
      .from(matchResult)
      .where(eq(matchResult.matchId, params.matchId))
      .limit(1);

    const [analytics] = await db
      .select()
      .from(matchAnalytics)
      .where(eq(matchAnalytics.matchId, params.matchId))
      .limit(1);

    return {
      manOfMatchId: result?.manOfMatchId ?? null,
      awards: analytics?.mvpScores ?? null,
    };
  })

  // GET /api/v1/test/match-stats/:matchId — batting + bowling stats per innings
  .get('/match-stats/:matchId', async ({ params }) => {
    const matchInnings = await db
      .select({ id: innings.id, inningsNumber: innings.inningsNumber })
      .from(innings)
      .where(eq(innings.matchId, params.matchId))
      .orderBy(innings.inningsNumber);

    if (matchInnings.length === 0) {
      return { batting: [], bowling: [] };
    }

    const inningsIds = matchInnings.map((i) => i.id);

    const batting = await db
      .select({
        inningsId: battingStats.inningsId,
        playerId: battingStats.playerId,
        playerName: users.displayName,
        runsScored: battingStats.runsScored,
        ballsFaced: battingStats.ballsFaced,
        fours: battingStats.fours,
        sixes: battingStats.sixes,
        isNotOut: battingStats.isNotOut,
        battingPosition: battingStats.battingPosition,
      })
      .from(battingStats)
      .innerJoin(users, eq(battingStats.playerId, users.id))
      .where(sql`${battingStats.inningsId} IN ${inningsIds}`)
      .orderBy(battingStats.battingPosition);

    const bowling = await db
      .select({
        inningsId: bowlingStats.inningsId,
        playerId: bowlingStats.playerId,
        playerName: users.displayName,
        oversBowled: bowlingStats.oversBowled,
        maidens: bowlingStats.maidens,
        runsConceded: bowlingStats.runsConceded,
        wicketsTaken: bowlingStats.wicketsTaken,
        wides: bowlingStats.wides,
        noBalls: bowlingStats.noBalls,
        dotBalls: bowlingStats.dotBalls,
      })
      .from(bowlingStats)
      .innerJoin(users, eq(bowlingStats.playerId, users.id))
      .where(sql`${bowlingStats.inningsId} IN ${inningsIds}`);

    // Map innings IDs to numbers for easier client consumption
    const inningsMap = Object.fromEntries(matchInnings.map((i) => [i.id, i.inningsNumber]));

    return {
      batting: batting.map((b) => ({ ...b, inningsNumber: inningsMap[b.inningsId] })),
      bowling: bowling.map((b) => ({ ...b, inningsNumber: inningsMap[b.inningsId] })),
    };
  })

  // GET /api/v1/test/latest-match — latest match created (for test verification)
  .get('/latest-match', async () => {
    const [match] = await db
      .select({
        id: matches.id,
        createdAt: matches.createdAt,
      })
      .from(matches)
      .orderBy(sql`${matches.createdAt} DESC`)
      .limit(1);

    return { matchId: match?.id ?? null };
  })

  // POST /api/v1/test/run-migration — apply pending schema changes
  .post('/run-migration', async () => {
    try {
      await db.execute(sql`ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "magic_over_number" integer`);
      return { success: true, message: 'Migration applied' };
    } catch (e: any) {
      return { success: false, message: e.message };
    }
  })

  // POST /api/v1/test/reset-db — truncate all data tables, re-seed master data
  .post('/reset-db', async () => {
    try {
      // Use DELETE in FK-safe order (TRUNCATE can hang with connection pool locks)
      const tables = [
        'match_analytics',
        'match_result',
        'fall_of_wickets',
        'wickets_by_delivery',
        'deliveries',
        'batting_stats',
        'bowling_stats',
        'fielding_stats',
        'player_career_stats',
        'overs',
        'innings',
        'match_players',
        'matches',
        'tournament_standings',
        'tournament_fixtures',
        'tournament_requests',
        'tournament_teams',
        'tournament_groups',
        'tournaments',
        'team_rosters',
        'teams',
        'users',
      ];
      for (const table of tables) {
        await db.execute(sql.raw(`DELETE FROM "${table}"`));
      }

      // Apply any pending schema migrations
      await db.execute(sql`ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "magic_over_number" integer`);

      // Seed test user (matches auth middleware TEST_USER)
      await db.insert(users).values({
        firebaseUid: 'test-user-e2e-001',
        phone: '+919999900001',
        displayName: 'E2E Test Scorer',
        isVerified: true,
        playerRole: 'all_rounder',
        battingStyle: 'right_hand_bat',
        bowlingStyle: 'right_arm_medium',
      }).onConflictDoNothing();

      return { success: true, message: 'Database reset complete' };
    } catch (e: any) {
      return { success: false, message: e.message, stack: e.stack?.slice(0, 500) };
    }
  })

  // POST /api/v1/test/reset-match-data — clear only match data, preserve teams/players/users
  .post('/reset-match-data', async () => {
    try {
      const matchTables = [
        'match_analytics',
        'match_result',
        'fall_of_wickets',
        'wickets_by_delivery',
        'deliveries',
        'batting_stats',
        'bowling_stats',
        'fielding_stats',
        'player_career_stats',
        'overs',
        'innings',
        'match_players',
        'matches',
        'tournament_standings',
        'tournament_fixtures',
        'tournament_requests',
        'tournament_teams',
        'tournament_groups',
        'tournaments',
      ];
      for (const table of matchTables) {
        await db.execute(sql.raw(`DELETE FROM "${table}"`));
      }

      // Ensure test user exists (idempotent)
      await db.insert(users).values({
        firebaseUid: 'test-user-e2e-001',
        phone: '+919999900001',
        displayName: 'E2E Test Scorer',
        isVerified: true,
        playerRole: 'all_rounder',
        battingStyle: 'right_hand_bat',
        bowlingStyle: 'right_arm_medium',
      }).onConflictDoNothing();

      return { success: true, message: 'Match data reset (teams/players preserved)' };
    } catch (e: any) {
      return { success: false, message: e.message, stack: e.stack?.slice(0, 500) };
    }
  })

  // GET /api/v1/test/teams — list teams with player counts (for skip-creation check)
  .get('/teams', async () => {
    const rows = await db.execute(
      sql`SELECT t.id, t.name, (SELECT COUNT(*)::int FROM team_rosters WHERE team_id = t.id) AS player_count FROM teams t ORDER BY t.name`,
    );

    return {
      teams: (rows as any[]).map((r: any) => ({
        id: r.id,
        name: r.name,
        playerCount: r.player_count,
      })),
    };
  });
