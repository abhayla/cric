import { eq, and, ilike, sql, desc } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { users } from '../db/schema/users.ts';
import { teams, teamRosters } from '../db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../db/schema/matches.ts';
import { innings } from '../db/schema/innings.ts';
import { battingStats, bowlingStats, fieldingStats, playerCareerStats } from '../db/schema/stats.ts';
import { AppError } from '../middleware/error-handler.ts';

interface CreatePlayerInput {
  displayName: string;
  phone?: string;
  playerRole?: string;
  battingStyle?: string;
  bowlingStyle?: string;
}

export async function searchPlayersByName(query: string, limit: number = 10) {
  if (!query || query.trim().length < 2) {
    return [];
  }

  const results = await db
    .select({
      id: users.id,
      displayName: users.displayName,
      phone: users.phone,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      location: users.location,
      avatarUrl: users.avatarUrl,
    })
    .from(users)
    .where(ilike(users.displayName, `%${query.trim()}%`))
    .limit(limit);

  return results;
}

export async function searchPlayerByPhone(phone: string) {
  const [player] = await db
    .select({
      id: users.id,
      displayName: users.displayName,
      phone: users.phone,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      location: users.location,
      avatarUrl: users.avatarUrl,
    })
    .from(users)
    .where(eq(users.phone, phone))
    .limit(1);

  return player ?? null;
}

export async function createPlayer(input: CreatePlayerInput) {
  const trimmedName = input.displayName.trim();
  if (trimmedName.length < 2 || trimmedName.length > 50) {
    throw new Error('Display name must be 2-50 characters');
  }

  // Create a placeholder user (no firebase_uid — will be claimed on sign-up)
  const placeholderUid = `placeholder-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  const [player] = await db
    .insert(users)
    .values({
      firebaseUid: placeholderUid,
      displayName: trimmedName,
      phone: input.phone || null,
      playerRole: input.playerRole || null,
      battingStyle: input.battingStyle || null,
      bowlingStyle: input.bowlingStyle || null,
    })
    .returning();

  return player!;
}

// ============================================================
// Player Profile
// ============================================================

export async function getPlayerProfile(playerId: string) {
  const [player] = await db
    .select({
      id: users.id,
      displayName: users.displayName,
      phone: users.phone,
      email: users.email,
      avatarUrl: users.avatarUrl,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      location: users.location,
      createdAt: users.createdAt,
    })
    .from(users)
    .where(eq(users.id, playerId))
    .limit(1);

  if (!player) {
    throw new AppError('NOT_FOUND', 'Player not found', 404);
  }

  // Get team affiliations
  const teamAffiliations = await db
    .select({
      teamId: teams.id,
      teamName: teams.name,
      teamLogoUrl: teams.logoUrl,
      role: teamRosters.role,
      joinedAt: teamRosters.joinedAt,
    })
    .from(teamRosters)
    .innerJoin(teams, eq(teamRosters.teamId, teams.id))
    .where(
      and(
        eq(teamRosters.playerId, playerId),
        eq(teamRosters.isActive, true),
        eq(teams.isActive, true),
      ),
    );

  return { ...player, teams: teamAffiliations };
}

// ============================================================
// Player Career Stats
// ============================================================

export async function getPlayerStats(playerId: string, format: string = 'all') {
  // Verify player exists
  const [player] = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.id, playerId))
    .limit(1);

  if (!player) {
    throw new AppError('NOT_FOUND', 'Player not found', 404);
  }

  const [stats] = await db
    .select()
    .from(playerCareerStats)
    .where(
      and(
        eq(playerCareerStats.playerId, playerId),
        eq(playerCareerStats.format, format),
      ),
    )
    .limit(1);

  return stats ?? null;
}

// ============================================================
// Player Match History
// ============================================================

interface MatchHistoryQuery {
  page?: number;
  limit?: number;
  format?: string;
  result?: 'won' | 'lost' | 'tied' | 'no_result';
}

export async function getPlayerMatches(playerId: string, query: MatchHistoryQuery = {}) {
  const page = query.page ?? 1;
  const limit = Math.min(query.limit ?? 20, 50);
  const offset = (page - 1) * limit;

  // Verify player exists
  const [player] = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.id, playerId))
    .limit(1);

  if (!player) {
    throw new AppError('NOT_FOUND', 'Player not found', 404);
  }

  // Build conditions
  const conditions = [
    eq(matchPlayers.playerId, playerId),
    eq(matches.status, 'completed'),
  ];

  if (query.format) {
    conditions.push(eq(matches.format, query.format));
  }

  // For result filtering, join match_result
  if (query.result) {
    if (query.result === 'won') {
      conditions.push(sql`${matchResult.winnerTeamId} = ${matchPlayers.teamId}`);
    } else if (query.result === 'lost') {
      conditions.push(sql`${matchResult.winnerTeamId} IS NOT NULL`);
      conditions.push(sql`${matchResult.winnerTeamId} != ${matchPlayers.teamId}`);
    } else if (query.result === 'tied') {
      conditions.push(eq(matchResult.resultType, 'tie'));
    } else if (query.result === 'no_result') {
      conditions.push(eq(matchResult.resultType, 'no_result'));
    }
  }

  // Base query with left join to match_result for result filtering
  const matchRows = await db
    .select({
      matchId: matches.id,
      format: matches.format,
      totalOvers: matches.totalOvers,
      venue: matches.venue,
      matchDate: matches.matchDate,
      homeTeamId: matches.homeTeamId,
      awayTeamId: matches.awayTeamId,
      playerTeamId: matchPlayers.teamId,
    })
    .from(matchPlayers)
    .innerJoin(matches, eq(matchPlayers.matchId, matches.id))
    .leftJoin(matchResult, eq(matchResult.matchId, matches.id))
    .where(and(...conditions))
    .orderBy(desc(matches.matchDate), desc(matches.createdAt))
    .limit(limit)
    .offset(offset);

  if (matchRows.length === 0) {
    return { matches: [], total: 0, page, limit };
  }

  // Get total count
  const [countRow] = await db
    .select({ count: sql<number>`COUNT(*)::int` })
    .from(matchPlayers)
    .innerJoin(matches, eq(matchPlayers.matchId, matches.id))
    .leftJoin(matchResult, eq(matchResult.matchId, matches.id))
    .where(and(...conditions));

  const total = countRow?.count ?? 0;

  // Batch-fetch details for each match
  const matchIds = matchRows.map((m) => m.matchId);
  const matchIdsSql = sql.join(matchIds.map((id) => sql`${id}`), sql`, `);

  // Get innings for all matches (non-super-over)
  const allInnings = await db
    .select({
      id: innings.id,
      matchId: innings.matchId,
      inningsNumber: innings.inningsNumber,
      battingTeamId: innings.battingTeamId,
      totalRuns: innings.totalRuns,
      totalWickets: innings.totalWickets,
      totalOvers: innings.totalOvers,
    })
    .from(innings)
    .where(
      and(
        sql`${innings.matchId} IN (${matchIdsSql})`,
        eq(innings.isSuperOver, false),
      ),
    )
    .orderBy(innings.inningsNumber);

  // Get match results
  const allResults = await db
    .select({
      matchId: matchResult.matchId,
      winnerTeamId: matchResult.winnerTeamId,
      resultType: matchResult.resultType,
      margin: matchResult.margin,
      summary: matchResult.summary,
    })
    .from(matchResult)
    .where(sql`${matchResult.matchId} IN (${matchIdsSql})`);

  // Get team names
  const teamIds = new Set<string>();
  matchRows.forEach((m) => {
    teamIds.add(m.homeTeamId);
    teamIds.add(m.awayTeamId);
  });
  const teamIdArr = [...teamIds];
  const allTeams = await db
    .select({ id: teams.id, name: teams.name, logoUrl: teams.logoUrl })
    .from(teams)
    .where(sql`${teams.id} IN (${sql.join(teamIdArr.map((id) => sql`${id}`), sql`, `)})`);
  const teamMap = new Map(allTeams.map((t) => [t.id, t]));

  // Get personal batting stats
  const personalBatting = await db
    .select({
      inningsId: battingStats.inningsId,
      runsScored: battingStats.runsScored,
      ballsFaced: battingStats.ballsFaced,
      fours: battingStats.fours,
      sixes: battingStats.sixes,
      isNotOut: battingStats.isNotOut,
      strikeRate: battingStats.strikeRate,
    })
    .from(battingStats)
    .innerJoin(innings, eq(battingStats.inningsId, innings.id))
    .where(
      and(
        eq(battingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        sql`${innings.matchId} IN (${matchIdsSql})`,
      ),
    );

  // Get personal bowling stats
  const personalBowling = await db
    .select({
      inningsId: bowlingStats.inningsId,
      oversBowled: bowlingStats.oversBowled,
      runsConceded: bowlingStats.runsConceded,
      wicketsTaken: bowlingStats.wicketsTaken,
      maidens: bowlingStats.maidens,
      economyRate: bowlingStats.economyRate,
    })
    .from(bowlingStats)
    .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
    .where(
      and(
        eq(bowlingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        sql`${innings.matchId} IN (${matchIdsSql})`,
      ),
    );

  // Get personal fielding stats
  const personalFielding = await db
    .select({
      inningsId: fieldingStats.inningsId,
      catches: fieldingStats.catches,
      runOuts: fieldingStats.runOuts,
      stumpings: fieldingStats.stumpings,
    })
    .from(fieldingStats)
    .innerJoin(innings, eq(fieldingStats.inningsId, innings.id))
    .where(
      and(
        eq(fieldingStats.playerId, playerId),
        eq(innings.isSuperOver, false),
        sql`${innings.matchId} IN (${matchIdsSql})`,
      ),
    );

  // Build lookup maps
  const battingMap = new Map(personalBatting.map((b) => [b.inningsId, b]));
  const bowlingMap = new Map(personalBowling.map((b) => [b.inningsId, b]));
  const fieldingMap = new Map(personalFielding.map((f) => [f.inningsId, f]));
  const resultMap = new Map(allResults.map((r) => [r.matchId, r]));

  // Assemble response
  const matchList = matchRows.map((m) => {
    const matchInnings = allInnings.filter((i) => i.matchId === m.matchId);
    const result = resultMap.get(m.matchId);
    const homeTeam = teamMap.get(m.homeTeamId);
    const awayTeam = teamMap.get(m.awayTeamId);

    // Determine player result
    let playerResult: 'won' | 'lost' | 'tied' | 'no_result' = 'no_result';
    if (result) {
      if (result.resultType === 'tie') {
        playerResult = 'tied';
      } else if (result.winnerTeamId === m.playerTeamId) {
        playerResult = 'won';
      } else if (result.winnerTeamId) {
        playerResult = 'lost';
      }
    }

    // Build team scores
    const teamScores = matchInnings.map((inn) => ({
      teamId: inn.battingTeamId,
      teamName: teamMap.get(inn.battingTeamId)?.name ?? '',
      runs: inn.totalRuns,
      wickets: inn.totalWickets,
      overs: inn.totalOvers,
    }));

    // Personal performance (find from innings IDs)
    const inningsIds = matchInnings.map((i) => i.id);
    const batting = inningsIds.map((id) => battingMap.get(id)).find(Boolean) ?? null;
    const bowling = inningsIds.map((id) => bowlingMap.get(id)).find(Boolean) ?? null;
    const fielding = inningsIds.map((id) => fieldingMap.get(id)).find(Boolean) ?? null;

    return {
      matchId: m.matchId,
      format: m.format,
      venue: m.venue,
      matchDate: m.matchDate,
      homeTeam: { id: m.homeTeamId, name: homeTeam?.name ?? '', logoUrl: homeTeam?.logoUrl },
      awayTeam: { id: m.awayTeamId, name: awayTeam?.name ?? '', logoUrl: awayTeam?.logoUrl },
      teamScores,
      result: result
        ? {
            winnerTeamId: result.winnerTeamId,
            resultType: result.resultType,
            margin: result.margin,
            summary: result.summary,
          }
        : null,
      playerResult,
      playerTeamId: m.playerTeamId,
      batting,
      bowling,
      fielding,
    };
  });

  return { matches: matchList, total, page, limit };
}
