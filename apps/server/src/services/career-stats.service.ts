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
 *
 * Optimized: uses batch SQL with GROUPING SETS to compute all players × all formats
 * in ~8 queries total (O(1) regardless of player count), instead of the previous
 * per-player loop that ran ~17 queries × 22 players = ~374 queries.
 */
export async function refreshMatchPlayerCareerStats(
  tx: Tx,
  matchId: string,
): Promise<void> {
  // ── Query 1: Get all player IDs from match_players ──
  const players = await tx
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(eq(matchPlayers.matchId, matchId));

  const playerIds = [...new Set(players.map((p) => p.playerId))];
  if (playerIds.length === 0) return;

  // Build a reusable SQL fragment for IN (...) since Drizzle raw sql doesn't auto-serialize JS arrays
  const playerIdList = sql.join(playerIds.map((id) => sql`${id}::uuid`), sql`, `);

  // ── Query 2: Match count per player per format + 'all' ──
  const matchCountRows = await tx.execute<{
    player_id: string;
    format: string;
    matches_played: number;
  }>(sql`
    SELECT
      mp.player_id,
      CASE WHEN GROUPING(m.format) = 1 THEN 'all' ELSE m.format END AS format,
      COUNT(DISTINCT m.id)::int AS matches_played
    FROM match_players mp
    JOIN matches m ON mp.match_id = m.id
    WHERE mp.player_id IN (${playerIdList})
      AND m.status = 'completed'
    GROUP BY GROUPING SETS (
      (mp.player_id, m.format),
      (mp.player_id)
    )
  `);

  // ── Query 3: Batting aggregation ──
  const battingRows = await tx.execute<{
    player_id: string;
    format: string;
    innings_batted: number;
    total_runs: number;
    highest_score: number;
    total_balls_faced: number;
    total_fours: number;
    total_sixes: number;
    not_outs: number;
    fifties: number;
    hundreds: number;
  }>(sql`
    SELECT
      bs.player_id,
      CASE WHEN GROUPING(m.format) = 1 THEN 'all' ELSE m.format END AS format,
      COUNT(*)::int AS innings_batted,
      COALESCE(SUM(bs.runs_scored), 0)::int AS total_runs,
      COALESCE(MAX(bs.runs_scored), 0)::int AS highest_score,
      COALESCE(SUM(bs.balls_faced), 0)::int AS total_balls_faced,
      COALESCE(SUM(bs.fours), 0)::int AS total_fours,
      COALESCE(SUM(bs.sixes), 0)::int AS total_sixes,
      COALESCE(SUM(CASE WHEN bs.is_not_out = true THEN 1 ELSE 0 END), 0)::int AS not_outs,
      COALESCE(SUM(CASE WHEN bs.runs_scored >= 50 AND bs.runs_scored < 100 THEN 1 ELSE 0 END), 0)::int AS fifties,
      COALESCE(SUM(CASE WHEN bs.runs_scored >= 100 THEN 1 ELSE 0 END), 0)::int AS hundreds
    FROM batting_stats bs
    JOIN innings i ON bs.innings_id = i.id
    JOIN matches m ON i.match_id = m.id
    WHERE bs.player_id IN (${playerIdList})
      AND i.is_super_over = false
      AND m.status = 'completed'
    GROUP BY GROUPING SETS (
      (bs.player_id, m.format),
      (bs.player_id)
    )
  `);

  // ── Query 4: Bowling aggregation (with inline overs→balls math) ──
  const bowlingRows = await tx.execute<{
    player_id: string;
    format: string;
    innings_bowled: number;
    total_runs_conceded: number;
    total_wickets: number;
    total_balls_bowled: number;
    three_wicket_hauls: number;
    five_wicket_hauls: number;
  }>(sql`
    SELECT
      bw.player_id,
      CASE WHEN GROUPING(m.format) = 1 THEN 'all' ELSE m.format END AS format,
      COUNT(*)::int AS innings_bowled,
      COALESCE(SUM(bw.runs_conceded), 0)::int AS total_runs_conceded,
      COALESCE(SUM(bw.wickets_taken), 0)::int AS total_wickets,
      COALESCE(SUM(
        SPLIT_PART(bw.overs_bowled::text, '.', 1)::int * 6 +
        COALESCE(NULLIF(SPLIT_PART(bw.overs_bowled::text, '.', 2), ''), '0')::int
      ), 0)::int AS total_balls_bowled,
      COALESCE(SUM(CASE WHEN bw.wickets_taken >= 3 AND bw.wickets_taken < 5 THEN 1 ELSE 0 END), 0)::int AS three_wicket_hauls,
      COALESCE(SUM(CASE WHEN bw.wickets_taken >= 5 THEN 1 ELSE 0 END), 0)::int AS five_wicket_hauls
    FROM bowling_stats bw
    JOIN innings i ON bw.innings_id = i.id
    JOIN matches m ON i.match_id = m.id
    WHERE bw.player_id IN (${playerIdList})
      AND i.is_super_over = false
      AND m.status = 'completed'
    GROUP BY GROUPING SETS (
      (bw.player_id, m.format),
      (bw.player_id)
    )
  `);

  // ── Query 5: Best bowling via ROW_NUMBER() window ──
  const bestBowlingRows = await tx.execute<{
    player_id: string;
    format: string;
    best_wickets: number;
    best_runs: number;
  }>(sql`
    WITH per_format AS (
      SELECT
        bw.player_id,
        m.format,
        bw.wickets_taken,
        bw.runs_conceded,
        ROW_NUMBER() OVER (
          PARTITION BY bw.player_id, m.format
          ORDER BY bw.wickets_taken DESC, bw.runs_conceded ASC
        ) AS rn
      FROM bowling_stats bw
      JOIN innings i ON bw.innings_id = i.id
      JOIN matches m ON i.match_id = m.id
      WHERE bw.player_id IN (${playerIdList})
        AND i.is_super_over = false
        AND m.status = 'completed'
    ),
    per_all AS (
      SELECT
        bw.player_id,
        'all' AS format,
        bw.wickets_taken,
        bw.runs_conceded,
        ROW_NUMBER() OVER (
          PARTITION BY bw.player_id
          ORDER BY bw.wickets_taken DESC, bw.runs_conceded ASC
        ) AS rn
      FROM bowling_stats bw
      JOIN innings i ON bw.innings_id = i.id
      JOIN matches m ON i.match_id = m.id
      WHERE bw.player_id IN (${playerIdList})
        AND i.is_super_over = false
        AND m.status = 'completed'
    )
    SELECT player_id, format, wickets_taken AS best_wickets, runs_conceded AS best_runs
    FROM per_format WHERE rn = 1
    UNION ALL
    SELECT player_id, format, wickets_taken AS best_wickets, runs_conceded AS best_runs
    FROM per_all WHERE rn = 1
  `);

  // ── Query 6: Fielding aggregation ──
  const fieldingRows = await tx.execute<{
    player_id: string;
    format: string;
    total_catches: number;
    total_run_outs: number;
    total_stumpings: number;
  }>(sql`
    SELECT
      fs.player_id,
      CASE WHEN GROUPING(m.format) = 1 THEN 'all' ELSE m.format END AS format,
      COALESCE(SUM(fs.catches), 0)::int AS total_catches,
      COALESCE(SUM(fs.run_outs), 0)::int AS total_run_outs,
      COALESCE(SUM(fs.stumpings), 0)::int AS total_stumpings
    FROM fielding_stats fs
    JOIN innings i ON fs.innings_id = i.id
    JOIN matches m ON i.match_id = m.id
    WHERE fs.player_id IN (${playerIdList})
      AND i.is_super_over = false
      AND m.status = 'completed'
    GROUP BY GROUPING SETS (
      (fs.player_id, m.format),
      (fs.player_id)
    )
  `);

  // ── JS-side merge into Map<"playerId:format", stats> ──
  type StatsRow = {
    playerId: string;
    format: string;
    matchesPlayed: number;
    inningsBatted: number;
    totalRuns: number;
    highestScore: number;
    totalBallsFaced: number;
    totalFours: number;
    totalSixes: number;
    notOuts: number;
    fifties: number;
    hundreds: number;
    inningsBowled: number;
    totalRunsConceded: number;
    totalWickets: number;
    totalBallsBowled: number;
    threeWicketHauls: number;
    fiveWicketHauls: number;
    bestBowlingWickets: number;
    bestBowlingRuns: number;
    totalCatches: number;
    totalRunOuts: number;
    totalStumpings: number;
  };

  const statsMap = new Map<string, StatsRow>();

  function getOrCreate(playerId: string, format: string): StatsRow {
    const key = `${playerId}:${format}`;
    let row = statsMap.get(key);
    if (!row) {
      row = {
        playerId, format,
        matchesPlayed: 0,
        inningsBatted: 0, totalRuns: 0, highestScore: 0, totalBallsFaced: 0,
        totalFours: 0, totalSixes: 0, notOuts: 0, fifties: 0, hundreds: 0,
        inningsBowled: 0, totalRunsConceded: 0, totalWickets: 0, totalBallsBowled: 0,
        threeWicketHauls: 0, fiveWicketHauls: 0,
        bestBowlingWickets: 0, bestBowlingRuns: 0,
        totalCatches: 0, totalRunOuts: 0, totalStumpings: 0,
      };
      statsMap.set(key, row);
    }
    return row;
  }

  for (const r of matchCountRows) {
    const row = getOrCreate(r.player_id, r.format);
    row.matchesPlayed = Number(r.matches_played);
  }

  for (const r of battingRows) {
    const row = getOrCreate(r.player_id, r.format);
    row.inningsBatted = Number(r.innings_batted);
    row.totalRuns = Number(r.total_runs);
    row.highestScore = Number(r.highest_score);
    row.totalBallsFaced = Number(r.total_balls_faced);
    row.totalFours = Number(r.total_fours);
    row.totalSixes = Number(r.total_sixes);
    row.notOuts = Number(r.not_outs);
    row.fifties = Number(r.fifties);
    row.hundreds = Number(r.hundreds);
  }

  for (const r of bowlingRows) {
    const row = getOrCreate(r.player_id, r.format);
    row.inningsBowled = Number(r.innings_bowled);
    row.totalRunsConceded = Number(r.total_runs_conceded);
    row.totalWickets = Number(r.total_wickets);
    row.totalBallsBowled = Number(r.total_balls_bowled);
    row.threeWicketHauls = Number(r.three_wicket_hauls);
    row.fiveWicketHauls = Number(r.five_wicket_hauls);
  }

  for (const r of bestBowlingRows) {
    const row = getOrCreate(r.player_id, r.format);
    row.bestBowlingWickets = Number(r.best_wickets);
    row.bestBowlingRuns = Number(r.best_runs);
  }

  for (const r of fieldingRows) {
    const row = getOrCreate(r.player_id, r.format);
    row.totalCatches = Number(r.total_catches);
    row.totalRunOuts = Number(r.total_run_outs);
    row.totalStumpings = Number(r.total_stumpings);
  }

  // ── Query 7: Bulk delete old career stats ──
  await tx
    .delete(playerCareerStats)
    .where(sql`${playerCareerStats.playerId} IN (${playerIdList})`);

  // ── Query 8: Bulk insert all rows ──
  const values = Array.from(statsMap.values())
    .filter((row) => row.matchesPlayed > 0)
    .map((row) => {
      const dismissals = row.inningsBatted - row.notOuts;
      const battingAverage = dismissals > 0
        ? (row.totalRuns / dismissals).toFixed(2) : null;
      const battingStrikeRate = row.totalBallsFaced > 0
        ? ((row.totalRuns / row.totalBallsFaced) * 100).toFixed(2) : null;
      const bowlingAverage = row.totalWickets > 0
        ? (row.totalRunsConceded / row.totalWickets).toFixed(2) : null;
      const oversAsNumber = row.totalBallsBowled / 6;
      const bowlingEconomy = oversAsNumber > 0
        ? (row.totalRunsConceded / oversAsNumber).toFixed(2) : null;
      const bowlingStrikeRate = row.totalWickets > 0
        ? (row.totalBallsBowled / row.totalWickets).toFixed(2) : null;

      return {
        playerId: row.playerId,
        format: row.format,
        matchesPlayed: row.matchesPlayed,
        inningsBatted: row.inningsBatted,
        totalRuns: row.totalRuns,
        highestScore: row.highestScore,
        battingAverage,
        battingStrikeRate,
        fifties: row.fifties,
        hundreds: row.hundreds,
        fours: row.totalFours,
        sixes: row.totalSixes,
        notOuts: row.notOuts,
        inningsBowled: row.inningsBowled,
        oversBowled: ballsToOvers(row.totalBallsBowled),
        runsConceded: row.totalRunsConceded,
        wicketsTaken: row.totalWickets,
        bowlingAverage,
        bowlingEconomy,
        bowlingStrikeRate,
        bestBowlingWickets: row.bestBowlingWickets,
        bestBowlingRuns: row.bestBowlingRuns,
        threeWicketHauls: row.threeWicketHauls,
        fiveWicketHauls: row.fiveWicketHauls,
        catches: row.totalCatches,
        runOuts: row.totalRunOuts,
        stumpings: row.totalStumpings,
      };
    });

  if (values.length > 0) {
    await tx.insert(playerCareerStats).values(values);
  }
}
