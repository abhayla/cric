import { eq, and, sql, count, inArray, desc } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { matches, matchPlayers, matchResult } from '../db/schema/matches.ts';
import { innings } from '../db/schema/innings.ts';
import { teams } from '../db/schema/teams.ts';
import { teamRosters } from '../db/schema/teams.ts';
import { AppError } from '../middleware/error-handler.ts';

interface CreateMatchInput {
  homeTeamId: string;
  awayTeamId: string;
  format: string;
  totalOvers: number;
  ballTypeId: number;
  venue?: string;
  matchDate: string;
  playersPerSide?: number;
  maxOversPerBowler?: number;
  wideRuns?: number;
  noBallRuns?: number;
  powerplayOvers?: number;
  magicOverNumbers?: number[] | null;
  magicOverRunMultiplier?: number;
  magicOverWicketPenalty?: number;
  createdBy: string;
}

interface GetMatchesOptions {
  status?: string;
  page?: number;
  limit?: number;
}

interface SetPlayingXIInput {
  teamId: string;
  playerIds: string[];
  captainId: string;
  keeperId: string;
  userId: string;
}

interface RecordTossInput {
  winnerId: string;
  decision: string;
  openingStrikerId: string;
  openingNonStrikerId: string;
  openingBowlerId: string;
  userId: string;
}

export async function createMatch(input: CreateMatchInput) {
  // Validate teams are different
  if (input.homeTeamId === input.awayTeamId) {
    throw new AppError('VALIDATION_ERROR', 'Home team and away team must be different', 400);
  }

  // Validate totalOvers
  if (input.totalOvers < 1 || input.totalOvers > 50) {
    throw new AppError('VALIDATION_ERROR', 'Total overs must be between 1 and 50', 400);
  }

  // Validate playersPerSide
  const playersPerSide = input.playersPerSide ?? 11;
  if (playersPerSide < 2 || playersPerSide > 11) {
    throw new AppError('VALIDATION_ERROR', 'Players per side must be between 2 and 11', 400);
  }

  // Verify both teams exist and are active
  const [homeTeam] = await db
    .select({ id: teams.id })
    .from(teams)
    .where(and(eq(teams.id, input.homeTeamId), eq(teams.isActive, true)))
    .limit(1);

  if (!homeTeam) {
    throw new AppError('NOT_FOUND', 'Home team not found', 404);
  }

  const [awayTeam] = await db
    .select({ id: teams.id })
    .from(teams)
    .where(and(eq(teams.id, input.awayTeamId), eq(teams.isActive, true)))
    .limit(1);

  if (!awayTeam) {
    throw new AppError('NOT_FOUND', 'Away team not found', 404);
  }

  // Default maxOversPerBowler: ceil(totalOvers / 5)
  const maxOversPerBowler = input.maxOversPerBowler ?? Math.ceil(input.totalOvers / 5);

  const [match] = await db
    .insert(matches)
    .values({
      homeTeamId: input.homeTeamId,
      awayTeamId: input.awayTeamId,
      format: input.format,
      totalOvers: input.totalOvers,
      ballTypeId: input.ballTypeId,
      venue: input.venue ?? null,
      matchDate: input.matchDate,
      playersPerSide,
      maxOversPerBowler,
      wideRuns: input.wideRuns ?? 1,
      noBallRuns: input.noBallRuns ?? 1,
      powerplayOvers: input.powerplayOvers ?? null,
      magicOverNumbers: input.magicOverNumbers ?? null,
      magicOverRunMultiplier: input.magicOverRunMultiplier ?? 2,
      magicOverWicketPenalty: input.magicOverWicketPenalty ?? -5,
      scorerId: input.createdBy,
      createdBy: input.createdBy,
      status: 'setup',
    })
    .returning();

  return match!;
}

export async function getMatches(userId: string, options: GetMatchesOptions = {}) {
  const page = options.page ?? 1;
  const limit = Math.min(options.limit ?? 20, 50);
  const offset = (page - 1) * limit;

  const conditions = [
    sql`(${matches.scorerId} = ${userId} OR ${matches.id} IN (
      SELECT ${matchPlayers.matchId} FROM ${matchPlayers}
      WHERE ${matchPlayers.playerId} = ${userId}
    ))`,
  ];

  if (options.status) {
    conditions.push(eq(matches.status, options.status));
  }

  const whereClause = conditions.length === 1 ? conditions[0]! : and(...conditions);

  const result = await db
    .select({
      id: matches.id,
      homeTeamId: matches.homeTeamId,
      awayTeamId: matches.awayTeamId,
      format: matches.format,
      totalOvers: matches.totalOvers,
      status: matches.status,
      venue: matches.venue,
      matchDate: matches.matchDate,
      scorerId: matches.scorerId,
      createdAt: matches.createdAt,
    })
    .from(matches)
    .where(whereClause)
    .orderBy(desc(matches.createdAt))
    .limit(limit)
    .offset(offset);

  // Batch-fetch team names and innings for all matched IDs
  const matchIds = result.map((m) => m.id);

  if (matchIds.length === 0) {
    const [countResult] = await db
      .select({ total: count() })
      .from(matches)
      .where(whereClause);

    return { matches: [], total: countResult!.total, page };
  }

  // Fetch team names for all home/away team IDs
  const teamIds = [...new Set(result.flatMap((m) => [m.homeTeamId, m.awayTeamId]))];
  const teamRows = await db
    .select({ id: teams.id, name: teams.name })
    .from(teams)
    .where(inArray(teams.id, teamIds));
  const teamNameMap = new Map(teamRows.map((t) => [t.id, t.name]));

  // Fetch latest innings per match (ordered by innings_number desc, take first per match)
  const inningsRows = await db
    .select({
      matchId: innings.matchId,
      battingTeamId: innings.battingTeamId,
      totalRuns: innings.totalRuns,
      totalWickets: innings.totalWickets,
      totalOvers: innings.totalOvers,
      inningsNumber: innings.inningsNumber,
    })
    .from(innings)
    .where(inArray(innings.matchId, matchIds))
    .orderBy(desc(innings.inningsNumber));

  // Build a map: matchId → { first?, second? } innings data
  const inningsMap = new Map<string, { first?: typeof inningsRows[0]; second?: typeof inningsRows[0] }>();
  for (const row of inningsRows) {
    if (!inningsMap.has(row.matchId)) {
      inningsMap.set(row.matchId, {});
    }
    const entry = inningsMap.get(row.matchId)!;
    if (row.inningsNumber === 1) entry.first = row;
    else if (row.inningsNumber === 2) entry.second = row;
  }

  // Fetch match results for completed matches
  const resultRows = await db
    .select({
      matchId: matchResult.matchId,
      summary: matchResult.summary,
    })
    .from(matchResult)
    .where(inArray(matchResult.matchId, matchIds));
  const resultMap = new Map(resultRows.map((r) => [r.matchId, r.summary]));

  // Assemble enriched response
  const enrichedMatches = result.map((m) => {
    const matchInnings = inningsMap.get(m.id);
    // currentInnings = latest innings (for live match display)
    const currentInnings = matchInnings?.second ?? matchInnings?.first;
    const formatInnings = (inn: typeof inningsRows[0] | undefined) =>
      inn
        ? {
            battingTeamId: inn.battingTeamId,
            totalRuns: inn.totalRuns,
            totalWickets: inn.totalWickets,
            overs: inn.totalOvers,
          }
        : null;
    return {
      id: m.id,
      homeTeam: { id: m.homeTeamId, name: teamNameMap.get(m.homeTeamId) ?? null },
      awayTeam: { id: m.awayTeamId, name: teamNameMap.get(m.awayTeamId) ?? null },
      format: m.format,
      totalOvers: m.totalOvers,
      status: m.status,
      venue: m.venue,
      matchDate: m.matchDate,
      scorerId: m.scorerId,
      createdAt: m.createdAt,
      currentInnings: formatInnings(currentInnings),
      firstInnings: formatInnings(matchInnings?.first),
      secondInnings: formatInnings(matchInnings?.second),
      result: resultMap.get(m.id) ?? null,
    };
  });

  const [countResult] = await db
    .select({ total: count() })
    .from(matches)
    .where(whereClause);

  return {
    matches: enrichedMatches,
    total: countResult!.total,
    page,
  };
}

export async function getMatch(matchId: string) {
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) return null;

  // Get team names
  const [homeTeam] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, match.homeTeamId))
    .limit(1);

  const [awayTeam] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, match.awayTeamId))
    .limit(1);

  // Get innings
  const matchInnings = await db
    .select()
    .from(innings)
    .where(eq(innings.matchId, matchId))
    .orderBy(innings.inningsNumber);

  return {
    ...match,
    homeTeamName: homeTeam?.name ?? null,
    awayTeamName: awayTeam?.name ?? null,
    innings: matchInnings,
  };
}

export async function setPlayingXI(matchId: string, input: SetPlayingXIInput) {
  // Get match
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  // Validate match status
  if (match.status !== 'setup' && match.status !== 'toss') {
    throw new AppError('VALIDATION_ERROR', 'Playing XI can only be set during setup or toss', 400);
  }

  // Validate teamId is one of the match teams
  if (input.teamId !== match.homeTeamId && input.teamId !== match.awayTeamId) {
    throw new AppError('VALIDATION_ERROR', 'Team is not part of this match', 400);
  }

  // Validate player count matches playersPerSide
  if (input.playerIds.length !== match.playersPerSide) {
    throw new AppError('VALIDATION_ERROR', `Exactly ${match.playersPerSide} players required`, 400);
  }

  // Validate captain in playerIds
  if (!input.playerIds.includes(input.captainId)) {
    throw new AppError('VALIDATION_ERROR', 'Captain must be in the playing XI', 400);
  }

  // Validate keeper in playerIds
  if (!input.playerIds.includes(input.keeperId)) {
    throw new AppError('VALIDATION_ERROR', 'Keeper must be in the playing XI', 400);
  }

  // Check if playing XI already submitted for this team
  const [existingXI] = await db
    .select({ id: matchPlayers.id })
    .from(matchPlayers)
    .where(
      and(
        eq(matchPlayers.matchId, matchId),
        eq(matchPlayers.teamId, input.teamId),
      ),
    )
    .limit(1);

  if (existingXI) {
    throw new AppError('CONFLICT', 'This team\'s playing XI already submitted for this match', 409);
  }

  // Validate all players are in team roster
  const rosterPlayers = await db
    .select({ playerId: teamRosters.playerId })
    .from(teamRosters)
    .where(
      and(
        eq(teamRosters.teamId, input.teamId),
        eq(teamRosters.isActive, true),
        inArray(teamRosters.playerId, input.playerIds),
      ),
    );

  const rosterPlayerIds = new Set(rosterPlayers.map((r) => r.playerId));
  const invalidPlayers = input.playerIds.filter((id) => !rosterPlayerIds.has(id));
  if (invalidPlayers.length > 0) {
    throw new AppError('VALIDATION_ERROR', 'Some players are not in team roster', 400);
  }

  // Insert match_players records (batch)
  const valuesToInsert = input.playerIds.map((playerId, i) => ({
    matchId,
    teamId: input.teamId,
    playerId,
    battingOrder: i + 1,
    isCaptain: playerId === input.captainId,
    isKeeper: playerId === input.keeperId,
  }));

  const insertedPlayers = await db
    .insert(matchPlayers)
    .values(valuesToInsert)
    .returning();

  // Check if both teams now have playing XI → transition to "toss"
  const otherTeamId = input.teamId === match.homeTeamId ? match.awayTeamId : match.homeTeamId;
  const [otherTeamXI] = await db
    .select({ id: matchPlayers.id })
    .from(matchPlayers)
    .where(
      and(
        eq(matchPlayers.matchId, matchId),
        eq(matchPlayers.teamId, otherTeamId),
      ),
    )
    .limit(1);

  if (otherTeamXI) {
    await db
      .update(matches)
      .set({ status: 'toss' })
      .where(eq(matches.id, matchId));
  }

  return insertedPlayers;
}

export async function recordToss(matchId: string, input: RecordTossInput) {
  // Get match
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  // Validate match status
  if (match.status !== 'toss') {
    throw new AppError('VALIDATION_ERROR', 'Match must be in toss status to record toss', 400);
  }

  // Validate winnerId is one of the match teams
  if (input.winnerId !== match.homeTeamId && input.winnerId !== match.awayTeamId) {
    throw new AppError('VALIDATION_ERROR', 'Toss winner must be one of the match teams', 400);
  }

  // Validate striker !== non-striker
  if (input.openingStrikerId === input.openingNonStrikerId) {
    throw new AppError('VALIDATION_ERROR', 'Striker and non-striker must be different players', 400);
  }

  // Determine batting and bowling teams based on decision
  let battingTeamId: string;
  let bowlingTeamId: string;

  if (input.decision === 'bat') {
    battingTeamId = input.winnerId;
    bowlingTeamId = input.winnerId === match.homeTeamId ? match.awayTeamId : match.homeTeamId;
  } else {
    bowlingTeamId = input.winnerId;
    battingTeamId = input.winnerId === match.homeTeamId ? match.awayTeamId : match.homeTeamId;
  }

  // Get batting team's playing XI
  const battingXI = await db
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(
      and(
        eq(matchPlayers.matchId, matchId),
        eq(matchPlayers.teamId, battingTeamId),
      ),
    );
  const battingPlayerIds = new Set(battingXI.map((p) => p.playerId));

  // Get bowling team's playing XI
  const bowlingXI = await db
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(
      and(
        eq(matchPlayers.matchId, matchId),
        eq(matchPlayers.teamId, bowlingTeamId),
      ),
    );
  const bowlingPlayerIds = new Set(bowlingXI.map((p) => p.playerId));

  // Validate opening striker in batting team playing XI
  if (!battingPlayerIds.has(input.openingStrikerId)) {
    throw new AppError('VALIDATION_ERROR', 'Opening striker must be in the batting team\'s playing XI', 400);
  }

  // Validate opening non-striker in batting team playing XI
  if (!battingPlayerIds.has(input.openingNonStrikerId)) {
    throw new AppError('VALIDATION_ERROR', 'Opening non-striker must be in the batting team\'s playing XI', 400);
  }

  // Validate opening bowler in bowling team playing XI
  if (!bowlingPlayerIds.has(input.openingBowlerId)) {
    throw new AppError('VALIDATION_ERROR', 'Opening bowler must be in the bowling team\'s playing XI', 400);
  }

  // Update match: toss info + status = "live"
  const [updatedMatch] = await db
    .update(matches)
    .set({
      tossWinnerId: input.winnerId,
      tossDecision: input.decision,
      status: 'live',
    })
    .where(eq(matches.id, matchId))
    .returning();

  // Create first innings
  const [firstInnings] = await db
    .insert(innings)
    .values({
      matchId,
      inningsNumber: 1,
      battingTeamId,
      bowlingTeamId,
    })
    .returning();

  return {
    match: updatedMatch!,
    innings: firstInnings!,
  };
}
