import { eq, and, sql, desc } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { matches, matchPlayers } from '../db/schema/matches.ts';
import { innings } from '../db/schema/innings.ts';
import { battingStats, bowlingStats, fieldingStats, playerCareerStats } from '../db/schema/stats.ts';

type Tx = Parameters<Parameters<typeof db.transaction>[0]>[0];

/**
 * Convert cricket overs decimal (e.g. "3.4") to total balls.
 * 3.4 overs = 3*6 + 4 = 22 balls
 */
function oversToBalls(overs: string | null): number {
  if (!overs) return 0;
  const parts = overs.split('.');
  const completedOvers = parseInt(parts[0]!, 10) || 0;
  const extraBalls = parseInt(parts[1] || '0', 10);
  return completedOvers * 6 + extraBalls;
}

/**
 * Convert total balls back to cricket overs string.
 * 22 balls = "3.4"
 */
function ballsToOvers(totalBalls: number): string {
  const overs = Math.floor(totalBalls / 6);
  const balls = totalBalls % 6;
  return `${overs}.${balls}`;
}

/**
 * Aggregate and upsert career stats for one player in one format.
 * Pass format = 'all' to aggregate across all formats.
 */
export async function refreshPlayerCareerStats(
  tx: Tx,
  playerId: string,
  format: string,
): Promise<void> {
  // Base condition: completed matches, non-super-over innings
  const formatCondition =
    format === 'all'
      ? sql`TRUE`
      : sql`${matches.format} = ${format}`;

  // ── Matches played ──
  const [matchCount] = await tx
    .select({ count: sql<number>`COUNT(DISTINCT ${matches.id})::int` })
    .from(matchPlayers)
    .innerJoin(matches, eq(matchPlayers.matchId, matches.id))
    .where(
      and(
        eq(matchPlayers.playerId, playerId),
        eq(matches.status, 'completed'),
        sql`${formatCondition}`,
      ),
    );

  const matchesPlayed = matchCount?.count ?? 0;

  if (matchesPlayed === 0) {
    // Delete existing record if any (player has no completed matches in this format)
    await tx
      .delete(playerCareerStats)
      .where(
        and(
          eq(playerCareerStats.playerId, playerId),
          eq(playerCareerStats.format, format),
        ),
      );
    return;
  }

  // ── Batting aggregation ──
  const [batting] = await tx
    .select({
      inningsBatted: sql<number>`COUNT(*)::int`,
      totalRuns: sql<number>`COALESCE(SUM(${battingStats.runsScored}), 0)::int`,
      highestScore: sql<number>`COALESCE(MAX(${battingStats.runsScored}), 0)::int`,
      totalBallsFaced: sql<number>`COALESCE(SUM(${battingStats.ballsFaced}), 0)::int`,
      totalFours: sql<number>`COALESCE(SUM(${battingStats.fours}), 0)::int`,
      totalSixes: sql<number>`COALESCE(SUM(${battingStats.sixes}), 0)::int`,
      notOuts: sql<number>`COALESCE(SUM(CASE WHEN ${battingStats.isNotOut} = true THEN 1 ELSE 0 END), 0)::int`,
      fifties: sql<number>`COALESCE(SUM(CASE WHEN ${battingStats.runsScored} >= 50 AND ${battingStats.runsScored} < 100 THEN 1 ELSE 0 END), 0)::int`,
      hundreds: sql<number>`COALESCE(SUM(CASE WHEN ${battingStats.runsScored} >= 100 THEN 1 ELSE 0 END), 0)::int`,
    })
    .from(battingStats)
    .innerJoin(innings, eq(battingStats.inningsId, innings.id))
    .innerJoin(matches, eq(innings.matchId, matches.id))
    .where(
      and(
        eq(battingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        eq(matches.status, 'completed'),
        sql`${formatCondition}`,
      ),
    );

  const inningsBatted = batting?.inningsBatted ?? 0;
  const totalRuns = batting?.totalRuns ?? 0;
  const notOuts = batting?.notOuts ?? 0;
  const totalBallsFaced = batting?.totalBallsFaced ?? 0;

  // Batting average: runs / (innings - not_outs), null if divisor is 0
  const dismissals = inningsBatted - notOuts;
  const battingAverage = dismissals > 0 ? (totalRuns / dismissals).toFixed(2) : null;

  // Batting strike rate: (runs / balls) * 100, null if no balls faced
  const battingStrikeRate =
    totalBallsFaced > 0 ? ((totalRuns / totalBallsFaced) * 100).toFixed(2) : null;

  // ── Bowling aggregation ──
  const [bowling] = await tx
    .select({
      inningsBowled: sql<number>`COUNT(*)::int`,
      totalRunsConceded: sql<number>`COALESCE(SUM(${bowlingStats.runsConceded}), 0)::int`,
      totalWickets: sql<number>`COALESCE(SUM(${bowlingStats.wicketsTaken}), 0)::int`,
      threeWicketHauls: sql<number>`COALESCE(SUM(CASE WHEN ${bowlingStats.wicketsTaken} >= 3 AND ${bowlingStats.wicketsTaken} < 5 THEN 1 ELSE 0 END), 0)::int`,
      fiveWicketHauls: sql<number>`COALESCE(SUM(CASE WHEN ${bowlingStats.wicketsTaken} >= 5 THEN 1 ELSE 0 END), 0)::int`,
    })
    .from(bowlingStats)
    .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
    .innerJoin(matches, eq(innings.matchId, matches.id))
    .where(
      and(
        eq(bowlingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        eq(matches.status, 'completed'),
        sql`${formatCondition}`,
      ),
    );

  // Overs: sum as balls to avoid decimal math issues
  const oversRows = await tx
    .select({ oversBowled: bowlingStats.oversBowled })
    .from(bowlingStats)
    .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
    .innerJoin(matches, eq(innings.matchId, matches.id))
    .where(
      and(
        eq(bowlingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        eq(matches.status, 'completed'),
        sql`${formatCondition}`,
      ),
    );

  const totalBallsBowled = oversRows.reduce((sum, row) => sum + oversToBalls(row.oversBowled), 0);
  const oversBowled = ballsToOvers(totalBallsBowled);

  const inningsBowled = bowling?.inningsBowled ?? 0;
  const totalRunsConceded = bowling?.totalRunsConceded ?? 0;
  const totalWickets = bowling?.totalWickets ?? 0;

  // Bowling average: runs / wickets
  const bowlingAverage = totalWickets > 0 ? (totalRunsConceded / totalWickets).toFixed(2) : null;

  // Bowling economy: runs / overs (as a number)
  const oversAsNumber = totalBallsBowled / 6;
  const bowlingEconomy = oversAsNumber > 0 ? (totalRunsConceded / oversAsNumber).toFixed(2) : null;

  // Bowling strike rate: balls / wickets
  const bowlingStrikeRate =
    totalWickets > 0 ? (totalBallsBowled / totalWickets).toFixed(2) : null;

  // ── Best bowling ──
  let bestBowlingWickets = 0;
  let bestBowlingRuns = 0;

  if (inningsBowled > 0) {
    const [best] = await tx
      .select({
        wickets: bowlingStats.wicketsTaken,
        runs: bowlingStats.runsConceded,
      })
      .from(bowlingStats)
      .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
      .innerJoin(matches, eq(innings.matchId, matches.id))
      .where(
        and(
          eq(bowlingStats.playerId, playerId),
          eq(innings.isSuperOver, false),
          eq(matches.status, 'completed'),
          sql`${formatCondition}`,
        ),
      )
      .orderBy(desc(bowlingStats.wicketsTaken), sql`${bowlingStats.runsConceded} ASC`)
      .limit(1);

    if (best) {
      bestBowlingWickets = best.wickets;
      bestBowlingRuns = best.runs;
    }
  }

  // ── Fielding aggregation ──
  const [fielding] = await tx
    .select({
      totalCatches: sql<number>`COALESCE(SUM(${fieldingStats.catches}), 0)::int`,
      totalRunOuts: sql<number>`COALESCE(SUM(${fieldingStats.runOuts}), 0)::int`,
      totalStumpings: sql<number>`COALESCE(SUM(${fieldingStats.stumpings}), 0)::int`,
    })
    .from(fieldingStats)
    .innerJoin(innings, eq(fieldingStats.inningsId, innings.id))
    .innerJoin(matches, eq(innings.matchId, matches.id))
    .where(
      and(
        eq(fieldingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        eq(matches.status, 'completed'),
        sql`${formatCondition}`,
      ),
    );

  // ── Upsert: delete + insert (no unique constraint on player_id + format) ──
  await tx
    .delete(playerCareerStats)
    .where(
      and(
        eq(playerCareerStats.playerId, playerId),
        eq(playerCareerStats.format, format),
      ),
    );

  await tx.insert(playerCareerStats).values({
    playerId,
    format,
    matchesPlayed,
    inningsBatted,
    totalRuns,
    highestScore: batting?.highestScore ?? 0,
    battingAverage,
    battingStrikeRate,
    fifties: batting?.fifties ?? 0,
    hundreds: batting?.hundreds ?? 0,
    fours: batting?.totalFours ?? 0,
    sixes: batting?.totalSixes ?? 0,
    notOuts,
    inningsBowled,
    oversBowled,
    runsConceded: totalRunsConceded,
    wicketsTaken: totalWickets,
    bowlingAverage,
    bowlingEconomy,
    bowlingStrikeRate,
    bestBowlingWickets,
    bestBowlingRuns,
    threeWicketHauls: bowling?.threeWicketHauls ?? 0,
    fiveWicketHauls: bowling?.fiveWicketHauls ?? 0,
    catches: fielding?.totalCatches ?? 0,
    runOuts: fielding?.totalRunOuts ?? 0,
    stumpings: fielding?.totalStumpings ?? 0,
  });
}

/**
 * Refresh career stats for all formats the player has played, plus "all".
 */
export async function refreshPlayerAllFormats(
  tx: Tx,
  playerId: string,
): Promise<void> {
  // Find distinct formats the player has participated in (completed matches only)
  const formatRows = await tx
    .select({ format: matches.format })
    .from(matchPlayers)
    .innerJoin(matches, eq(matchPlayers.matchId, matches.id))
    .where(
      and(
        eq(matchPlayers.playerId, playerId),
        eq(matches.status, 'completed'),
      ),
    )
    .groupBy(matches.format);

  const formats = formatRows.map((r) => r.format);

  // Refresh each format
  for (const format of formats) {
    await refreshPlayerCareerStats(tx, playerId, format);
  }

  // Refresh "all" aggregate
  if (formats.length > 0) {
    await refreshPlayerCareerStats(tx, playerId, 'all');
  }
}

/**
 * Refresh career stats for ALL players who participated in a given match.
 * Called after match completion.
 */
export async function refreshMatchPlayerCareerStats(
  tx: Tx,
  matchId: string,
): Promise<void> {
  // Get all player IDs from match_players
  const players = await tx
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(eq(matchPlayers.matchId, matchId));

  const playerIds = [...new Set(players.map((p) => p.playerId))];

  for (const playerId of playerIds) {
    await refreshPlayerAllFormats(tx, playerId);
  }
}
