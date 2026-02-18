import { Elysia } from 'elysia';
import { eq, sql } from 'drizzle-orm';
import { db } from '../../db/index.ts';
import { deliveries } from '../../db/schema/deliveries.ts';
import { innings } from '../../db/schema/innings.ts';
import { matches, matchResult, matchAnalytics } from '../../db/schema/matches.ts';
import { tournamentStandings } from '../../db/schema/tournaments.ts';
import { battingStats, bowlingStats } from '../../db/schema/stats.ts';
import { users } from '../../db/schema/users.ts';

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
      .select()
      .from(deliveries)
      .where(sql`${deliveries.inningsId} IN ${inningsIds}`)
      .orderBy(deliveries.sequenceNumber);

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
  });
