import { eq, and, sql, count, desc, asc, inArray, sum } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { tournaments, tournamentTeams, tournamentGroups, tournamentFixtures, tournamentStandings, tournamentRequests } from '../db/schema/tournaments.ts';
import { teams, teamRosters } from '../db/schema/teams.ts';
import { users } from '../db/schema/users.ts';
import { matches } from '../db/schema/matches.ts';
import { innings } from '../db/schema/innings.ts';
import { battingStats, bowlingStats } from '../db/schema/stats.ts';
import { AppError } from '../middleware/error-handler.ts';
import { emitTournamentUpdateEvents } from './activity-feed.service.ts';

// -- Types --

interface CreateTournamentInput {
  name: string;
  format: string;
  oversPerMatch: number;
  ballTypeId: number;
  pointsWin?: number;
  pointsTie?: number;
  pointsNoResult?: number;
  pointsLoss?: number;
  numGroups?: number;
  qualifyPerGroup?: number;
  hasThirdPlaceMatch?: boolean;
  playersPerSide?: number;
  maxOversPerBowler?: number | null;
  wideRuns?: number;
  noBallRuns?: number;
  powerplayOvers?: number | null;
  magicOverNumbers?: number[] | null;
  magicOverRunMultiplier?: number;
  magicOverWicketPenalty?: number;
  startDate?: string | null;
  endDate?: string | null;
  createdBy: string;
}

interface UpdateTournamentInput {
  name?: string;
  oversPerMatch?: number;
  ballTypeId?: number;
  pointsWin?: number;
  pointsTie?: number;
  pointsNoResult?: number;
  pointsLoss?: number;
  numGroups?: number;
  qualifyPerGroup?: number;
  hasThirdPlaceMatch?: boolean;
  playersPerSide?: number;
  maxOversPerBowler?: number | null;
  wideRuns?: number;
  noBallRuns?: number;
  powerplayOvers?: number | null;
  magicOverNumbers?: number[] | null;
  magicOverRunMultiplier?: number;
  magicOverWicketPenalty?: number;
  startDate?: string | null;
  endDate?: string | null;
}

const VALID_FORMATS = ['round_robin', 'knockout', 'group_knockout'] as const;
const VALID_TRANSITIONS: Record<string, string[]> = {
  draft: ['registration'],
  registration: ['live'],
  live: ['completed'],
  completed: [],
};

// -- CRUD --

export async function createTournament(input: CreateTournamentInput) {
  const trimmedName = input.name.trim();
  if (trimmedName.length < 2 || trimmedName.length > 100) {
    throw new AppError('VALIDATION_ERROR', 'Tournament name must be 2-100 characters', 400);
  }

  if (!VALID_FORMATS.includes(input.format as typeof VALID_FORMATS[number])) {
    throw new AppError('VALIDATION_ERROR', `Invalid format. Must be one of: ${VALID_FORMATS.join(', ')}`, 400);
  }

  if (input.oversPerMatch < 1 || input.oversPerMatch > 50) {
    throw new AppError('VALIDATION_ERROR', 'Overs per match must be between 1 and 50', 400);
  }

  const playersPerSide = input.playersPerSide ?? 11;
  if (playersPerSide < 2 || playersPerSide > 11) {
    throw new AppError('VALIDATION_ERROR', 'Players per side must be between 2 and 11', 400);
  }

  const [tournament] = await db
    .insert(tournaments)
    .values({
      name: trimmedName,
      format: input.format,
      oversPerMatch: input.oversPerMatch,
      ballTypeId: input.ballTypeId,
      status: 'draft',
      pointsWin: input.pointsWin ?? 2,
      pointsTie: input.pointsTie ?? 1,
      pointsNoResult: input.pointsNoResult ?? 1,
      pointsLoss: input.pointsLoss ?? 0,
      numGroups: input.numGroups ?? 1,
      qualifyPerGroup: input.qualifyPerGroup ?? 2,
      hasThirdPlaceMatch: input.hasThirdPlaceMatch ?? false,
      playersPerSide,
      maxOversPerBowler: input.maxOversPerBowler ?? null,
      wideRuns: input.wideRuns ?? 1,
      noBallRuns: input.noBallRuns ?? 1,
      powerplayOvers: input.powerplayOvers ?? null,
      magicOverNumbers: input.magicOverNumbers ?? null,
      magicOverRunMultiplier: input.magicOverRunMultiplier ?? 2,
      magicOverWicketPenalty: input.magicOverWicketPenalty ?? -5,
      createdBy: input.createdBy,
      startDate: input.startDate ?? null,
      endDate: input.endDate ?? null,
    })
    .returning();

  return tournament!;
}

export async function getTournaments(userId: string, page: number = 1, limit: number = 20, statusFilter?: string) {
  const offset = (page - 1) * limit;

  const conditions = [
    sql`(${tournaments.createdBy} = ${userId} OR ${tournaments.id} IN (
      SELECT ${tournamentTeams.tournamentId} FROM ${tournamentTeams}
      WHERE ${tournamentTeams.teamId} IN (
        SELECT ${teamRosters.teamId} FROM ${teamRosters}
        WHERE ${teamRosters.playerId} = ${userId} AND ${teamRosters.isActive} = true
      )
    ))`,
  ];

  if (statusFilter) {
    conditions.push(eq(tournaments.status, statusFilter));
  }

  const whereClause = conditions.length === 1 ? conditions[0]! : and(...conditions);

  const result = await db
    .select({
      id: tournaments.id,
      name: tournaments.name,
      format: tournaments.format,
      oversPerMatch: tournaments.oversPerMatch,
      status: tournaments.status,
      startDate: tournaments.startDate,
      endDate: tournaments.endDate,
      createdBy: tournaments.createdBy,
      createdAt: tournaments.createdAt,
    })
    .from(tournaments)
    .where(whereClause)
    .orderBy(desc(tournaments.createdAt))
    .limit(limit)
    .offset(offset);

  const [countResult] = await db
    .select({ total: count() })
    .from(tournaments)
    .where(whereClause);

  // Get team counts for each tournament
  const tournamentsWithMeta = await Promise.all(
    result.map(async (t) => {
      const [teamCountResult] = await db
        .select({ count: count() })
        .from(tournamentTeams)
        .where(eq(tournamentTeams.tournamentId, t.id));

      return {
        ...t,
        teamCount: teamCountResult!.count,
      };
    }),
  );

  return {
    tournaments: tournamentsWithMeta,
    total: countResult!.total,
    page,
  };
}

export async function getTournament(tournamentId: string) {
  const [tournament] = await db
    .select()
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) return null;

  // Get teams with names
  const teamsResult = await db
    .select({
      id: tournamentTeams.id,
      tournamentId: tournamentTeams.tournamentId,
      teamId: tournamentTeams.teamId,
      groupName: tournamentTeams.groupName,
      seedNumber: tournamentTeams.seedNumber,
      joinedAt: tournamentTeams.joinedAt,
      teamName: teams.name,
    })
    .from(tournamentTeams)
    .innerJoin(teams, eq(tournamentTeams.teamId, teams.id))
    .where(eq(tournamentTeams.tournamentId, tournamentId))
    .orderBy(tournamentTeams.joinedAt);

  // Get groups
  const groupsResult = await db
    .select()
    .from(tournamentGroups)
    .where(eq(tournamentGroups.tournamentId, tournamentId))
    .orderBy(tournamentGroups.name);

  // Build groups with team counts
  const groupsWithCounts = groupsResult.map((g) => ({
    name: g.name,
    teamCount: teamsResult.filter((t) => t.groupName === g.name).length,
  }));

  return {
    ...tournament,
    teams: teamsResult,
    groups: groupsWithCounts,
  };
}

export async function updateTournament(tournamentId: string, userId: string, input: UpdateTournamentInput) {
  await assertOrganizerAccess(tournamentId, userId);

  const [tournament] = await db
    .select({ status: tournaments.status })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (tournament!.status !== 'draft' && tournament!.status !== 'registration') {
    throw new AppError('CONFLICT', 'Tournament can only be updated in draft or registration status', 409);
  }

  const updates: Record<string, unknown> = {};

  if (input.name !== undefined) {
    const trimmed = input.name.trim();
    if (trimmed.length < 2 || trimmed.length > 100) {
      throw new AppError('VALIDATION_ERROR', 'Tournament name must be 2-100 characters', 400);
    }
    updates.name = trimmed;
  }
  if (input.oversPerMatch !== undefined) {
    if (input.oversPerMatch < 1 || input.oversPerMatch > 50) {
      throw new AppError('VALIDATION_ERROR', 'Overs must be between 1 and 50', 400);
    }
    updates.oversPerMatch = input.oversPerMatch;
  }
  if (input.ballTypeId !== undefined) updates.ballTypeId = input.ballTypeId;
  if (input.pointsWin !== undefined) updates.pointsWin = input.pointsWin;
  if (input.pointsTie !== undefined) updates.pointsTie = input.pointsTie;
  if (input.pointsNoResult !== undefined) updates.pointsNoResult = input.pointsNoResult;
  if (input.pointsLoss !== undefined) updates.pointsLoss = input.pointsLoss;
  if (input.numGroups !== undefined) updates.numGroups = input.numGroups;
  if (input.qualifyPerGroup !== undefined) updates.qualifyPerGroup = input.qualifyPerGroup;
  if (input.hasThirdPlaceMatch !== undefined) updates.hasThirdPlaceMatch = input.hasThirdPlaceMatch;
  if (input.playersPerSide !== undefined) updates.playersPerSide = input.playersPerSide;
  if (input.maxOversPerBowler !== undefined) updates.maxOversPerBowler = input.maxOversPerBowler;
  if (input.wideRuns !== undefined) updates.wideRuns = input.wideRuns;
  if (input.noBallRuns !== undefined) updates.noBallRuns = input.noBallRuns;
  if (input.powerplayOvers !== undefined) updates.powerplayOvers = input.powerplayOvers;
  if (input.startDate !== undefined) updates.startDate = input.startDate;
  if (input.endDate !== undefined) updates.endDate = input.endDate;

  if (Object.keys(updates).length === 0) {
    throw new AppError('VALIDATION_ERROR', 'No fields to update', 400);
  }

  const [updated] = await db
    .update(tournaments)
    .set(updates)
    .where(eq(tournaments.id, tournamentId))
    .returning();

  return updated!;
}

export async function transitionStatus(tournamentId: string, userId: string, newStatus: string) {
  await assertOrganizerAccess(tournamentId, userId);

  const [tournament] = await db
    .select({ status: tournaments.status })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  const currentStatus = tournament!.status;
  const validNext = VALID_TRANSITIONS[currentStatus] ?? [];

  if (!validNext.includes(newStatus)) {
    throw new AppError('VALIDATION_ERROR', `Cannot transition from '${currentStatus}' to '${newStatus}'`, 400);
  }

  // Additional checks for registration → live
  if (newStatus === 'live') {
    const [teamCount] = await db
      .select({ count: count() })
      .from(tournamentTeams)
      .where(eq(tournamentTeams.tournamentId, tournamentId));

    if (teamCount!.count < 2) {
      throw new AppError('VALIDATION_ERROR', 'Tournament must have at least 2 teams to go live', 400);
    }

    const [fixtureCount] = await db
      .select({ count: count() })
      .from(tournamentFixtures)
      .where(eq(tournamentFixtures.tournamentId, tournamentId));

    if (fixtureCount!.count === 0) {
      throw new AppError('VALIDATION_ERROR', 'Fixtures must be generated before going live', 400);
    }
  }

  const [updated] = await db
    .update(tournaments)
    .set({ status: newStatus })
    .where(eq(tournaments.id, tournamentId))
    .returning();

  // Fire-and-forget activity feed events
  emitTournamentUpdateEvents(tournamentId, updated!.name, newStatus).catch((err) =>
    console.error(`[ActivityFeed] Failed for tournament=${tournamentId}:`, err),
  );

  return updated!;
}

// -- Team Management --

export async function addTeam(
  tournamentId: string,
  userId: string,
  teamId: string,
  groupName?: string | null,
  seedNumber?: number | null,
) {
  await assertOrganizerAccess(tournamentId, userId);

  const [tournament] = await db
    .select({ status: tournaments.status, playersPerSide: tournaments.playersPerSide })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (tournament!.status !== 'draft' && tournament!.status !== 'registration') {
    throw new AppError('CONFLICT', 'Cannot add teams after tournament is live', 409);
  }

  // Check team exists and is active
  const [team] = await db
    .select({ id: teams.id, name: teams.name })
    .from(teams)
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .limit(1);

  if (!team) {
    throw new AppError('NOT_FOUND', 'Team not found', 404);
  }

  // Check not already in tournament
  const [existing] = await db
    .select({ id: tournamentTeams.id })
    .from(tournamentTeams)
    .where(and(
      eq(tournamentTeams.tournamentId, tournamentId),
      eq(tournamentTeams.teamId, teamId),
    ))
    .limit(1);

  if (existing) {
    throw new AppError('CONFLICT', 'Team is already in this tournament', 409);
  }

  // Validate roster size
  await assertRosterSize(teamId, tournament!.playersPerSide);

  const [entry] = await db
    .insert(tournamentTeams)
    .values({
      tournamentId,
      teamId,
      groupName: groupName ?? null,
      seedNumber: seedNumber ?? null,
    })
    .returning();

  // Initialize standings for this team
  await db
    .insert(tournamentStandings)
    .values({
      tournamentId,
      teamId,
      groupName: groupName ?? null,
    });

  return {
    ...entry!,
    teamName: team.name,
  };
}

export async function registerTeam(tournamentId: string, userId: string, teamId: string) {
  const [tournament] = await db
    .select({ status: tournaments.status, playersPerSide: tournaments.playersPerSide })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) {
    throw new AppError('NOT_FOUND', 'Tournament not found', 404);
  }

  if (tournament.status !== 'registration') {
    throw new AppError('VALIDATION_ERROR', 'Tournament is not accepting registrations', 400);
  }

  // Check user is captain or owner of the team
  await assertTeamCaptainAccess(teamId, userId);

  // Validate roster size
  await assertRosterSize(teamId, tournament.playersPerSide);

  // Check for existing request or registration
  const [existingRequest] = await db
    .select({ id: tournamentRequests.id, status: tournamentRequests.status })
    .from(tournamentRequests)
    .where(and(
      eq(tournamentRequests.tournamentId, tournamentId),
      eq(tournamentRequests.teamId, teamId),
    ))
    .limit(1);

  if (existingRequest) {
    throw new AppError('CONFLICT', `Team already has a ${existingRequest.status} request`, 409);
  }

  const [existingTeam] = await db
    .select({ id: tournamentTeams.id })
    .from(tournamentTeams)
    .where(and(
      eq(tournamentTeams.tournamentId, tournamentId),
      eq(tournamentTeams.teamId, teamId),
    ))
    .limit(1);

  if (existingTeam) {
    throw new AppError('CONFLICT', 'Team is already registered', 409);
  }

  // Get team name for response
  const [team] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, teamId))
    .limit(1);

  const [request] = await db
    .insert(tournamentRequests)
    .values({
      tournamentId,
      teamId,
      requestedBy: userId,
      status: 'pending',
    })
    .returning();

  return {
    ...request!,
    teamName: team?.name ?? null,
  };
}

export async function getRequests(tournamentId: string, userId: string, statusFilter?: string) {
  await assertOrganizerAccess(tournamentId, userId);

  const conditions = [eq(tournamentRequests.tournamentId, tournamentId)];
  if (statusFilter) {
    conditions.push(eq(tournamentRequests.status, statusFilter));
  }

  const result = await db
    .select({
      id: tournamentRequests.id,
      tournamentId: tournamentRequests.tournamentId,
      teamId: tournamentRequests.teamId,
      requestedBy: tournamentRequests.requestedBy,
      status: tournamentRequests.status,
      rejectionReason: tournamentRequests.rejectionReason,
      requestedAt: tournamentRequests.requestedAt,
      resolvedAt: tournamentRequests.resolvedAt,
      teamName: teams.name,
      teamLocation: teams.location,
      requestedByName: users.displayName,
    })
    .from(tournamentRequests)
    .innerJoin(teams, eq(tournamentRequests.teamId, teams.id))
    .innerJoin(users, eq(tournamentRequests.requestedBy, users.id))
    .where(and(...conditions))
    .orderBy(desc(tournamentRequests.requestedAt));

  // Get roster counts
  const requestsWithCounts = await Promise.all(
    result.map(async (r) => {
      const [rosterCount] = await db
        .select({ count: count() })
        .from(teamRosters)
        .where(and(eq(teamRosters.teamId, r.teamId), eq(teamRosters.isActive, true)));

      return {
        ...r,
        rosterCount: rosterCount!.count,
      };
    }),
  );

  return requestsWithCounts;
}

export async function resolveRequest(
  tournamentId: string,
  userId: string,
  requestId: string,
  action: 'approved' | 'rejected',
  groupName?: string | null,
  seedNumber?: number | null,
  rejectionReason?: string | null,
) {
  await assertOrganizerAccess(tournamentId, userId);

  const [request] = await db
    .select()
    .from(tournamentRequests)
    .where(and(
      eq(tournamentRequests.id, requestId),
      eq(tournamentRequests.tournamentId, tournamentId),
    ))
    .limit(1);

  if (!request) {
    throw new AppError('NOT_FOUND', 'Request not found', 404);
  }

  if (request.status !== 'pending') {
    throw new AppError('VALIDATION_ERROR', 'Request is not in pending status', 400);
  }

  const now = new Date();

  if (action === 'approved') {
    // Add team to tournament
    await db
      .insert(tournamentTeams)
      .values({
        tournamentId,
        teamId: request.teamId,
        groupName: groupName ?? null,
        seedNumber: seedNumber ?? null,
      });

    // Initialize standings
    await db
      .insert(tournamentStandings)
      .values({
        tournamentId,
        teamId: request.teamId,
        groupName: groupName ?? null,
      });
  }

  const [updated] = await db
    .update(tournamentRequests)
    .set({
      status: action,
      rejectionReason: action === 'rejected' ? (rejectionReason ?? null) : null,
      resolvedAt: now,
    })
    .where(eq(tournamentRequests.id, requestId))
    .returning();

  // Get team name
  const [team] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, request.teamId))
    .limit(1);

  return {
    ...updated!,
    teamName: team?.name ?? null,
  };
}

export async function removeTeam(tournamentId: string, userId: string, teamId: string) {
  await assertOrganizerAccess(tournamentId, userId);

  const [tournament] = await db
    .select({ status: tournaments.status })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (tournament!.status !== 'draft' && tournament!.status !== 'registration') {
    throw new AppError('CONFLICT', 'Cannot remove teams after tournament is live', 409);
  }

  const [deleted] = await db
    .delete(tournamentTeams)
    .where(and(
      eq(tournamentTeams.tournamentId, tournamentId),
      eq(tournamentTeams.teamId, teamId),
    ))
    .returning();

  if (!deleted) {
    throw new AppError('NOT_FOUND', 'Team not found in tournament', 404);
  }

  // Also remove standings entry
  await db
    .delete(tournamentStandings)
    .where(and(
      eq(tournamentStandings.tournamentId, tournamentId),
      eq(tournamentStandings.teamId, teamId),
    ));
}

// -- Fixtures --

export async function generateFixtures(tournamentId: string, userId: string) {
  await assertOrganizerAccess(tournamentId, userId);

  const [tournament] = await db
    .select()
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  // Check no existing fixtures
  const [existingFixtures] = await db
    .select({ count: count() })
    .from(tournamentFixtures)
    .where(eq(tournamentFixtures.tournamentId, tournamentId));

  if (existingFixtures!.count > 0) {
    throw new AppError('CONFLICT', 'Fixtures already generated. Delete existing fixtures first.', 409);
  }

  // Get teams
  const tournamentTeamsList = await db
    .select({
      teamId: tournamentTeams.teamId,
      groupName: tournamentTeams.groupName,
      seedNumber: tournamentTeams.seedNumber,
      teamName: teams.name,
    })
    .from(tournamentTeams)
    .innerJoin(teams, eq(tournamentTeams.teamId, teams.id))
    .where(eq(tournamentTeams.tournamentId, tournamentId))
    .orderBy(tournamentTeams.seedNumber);

  if (tournamentTeamsList.length < 2) {
    throw new AppError('VALIDATION_ERROR', 'At least 2 teams required to generate fixtures', 400);
  }

  let fixtures: typeof fixtureValues = [];
  const fixtureValues: Array<{
    tournamentId: string;
    roundNumber: number;
    roundType: string;
    fixtureOrder: number;
    groupName?: string | null;
    homeTeamId: string;
    awayTeamId: string;
  }> = [];

  const format = tournament!.format;

  if (format === 'round_robin') {
    fixtures = generateRoundRobinFixtures(tournamentId, tournamentTeamsList);
  } else if (format === 'knockout') {
    fixtures = generateKnockoutFixtures(tournamentId, tournamentTeamsList, tournament!.hasThirdPlaceMatch);
  } else if (format === 'group_knockout') {
    fixtures = generateGroupKnockoutFixtures(
      tournamentId,
      tournamentTeamsList,
      tournament!.numGroups,
      tournament!.qualifyPerGroup,
      tournament!.hasThirdPlaceMatch,
    );
  }

  if (fixtures.length === 0) {
    throw new AppError('VALIDATION_ERROR', 'Could not generate fixtures for the given configuration', 400);
  }

  const inserted = await db
    .insert(tournamentFixtures)
    .values(fixtures)
    .returning();

  // Attach team names to response
  const teamNameMap = new Map(tournamentTeamsList.map((t) => [t.teamId, t.teamName]));
  const fixturesWithNames = inserted.map((f) => ({
    ...f,
    homeTeamName: teamNameMap.get(f.homeTeamId) ?? null,
    awayTeamName: teamNameMap.get(f.awayTeamId) ?? null,
  }));

  return {
    fixtures: fixturesWithNames,
    totalFixtures: inserted.length,
  };
}

export async function getFixtures(tournamentId: string, roundType?: string, groupName?: string) {
  const conditions = [eq(tournamentFixtures.tournamentId, tournamentId)];

  if (roundType) {
    conditions.push(eq(tournamentFixtures.roundType, roundType));
  }
  if (groupName) {
    conditions.push(eq(tournamentFixtures.groupName, groupName));
  }

  const result = await db
    .select({
      id: tournamentFixtures.id,
      tournamentId: tournamentFixtures.tournamentId,
      matchId: tournamentFixtures.matchId,
      roundNumber: tournamentFixtures.roundNumber,
      roundType: tournamentFixtures.roundType,
      fixtureOrder: tournamentFixtures.fixtureOrder,
      groupName: tournamentFixtures.groupName,
      homeTeamId: tournamentFixtures.homeTeamId,
      awayTeamId: tournamentFixtures.awayTeamId,
      scheduledDate: tournamentFixtures.scheduledDate,
      scheduledTime: tournamentFixtures.scheduledTime,
      estimatedDurationMinutes: tournamentFixtures.estimatedDurationMinutes,
      venue: tournamentFixtures.venue,
      createdAt: tournamentFixtures.createdAt,
    })
    .from(tournamentFixtures)
    .where(and(...conditions))
    .orderBy(asc(tournamentFixtures.roundNumber), asc(tournamentFixtures.fixtureOrder));

  // Get team names for all fixtures
  const teamIds = new Set<string>();
  result.forEach((f) => {
    teamIds.add(f.homeTeamId);
    teamIds.add(f.awayTeamId);
  });

  const teamNames = teamIds.size > 0
    ? await db
        .select({ id: teams.id, name: teams.name })
        .from(teams)
        .where(inArray(teams.id, [...teamIds]))
    : [];

  const nameMap = new Map(teamNames.map((t) => [t.id, t.name]));

  return result.map((f) => ({
    ...f,
    homeTeamName: nameMap.get(f.homeTeamId) ?? null,
    awayTeamName: nameMap.get(f.awayTeamId) ?? null,
  }));
}

export async function editFixture(
  tournamentId: string,
  userId: string,
  fixtureId: string,
  input: {
    scheduledDate?: string | null;
    scheduledTime?: string | null;
    estimatedDurationMinutes?: number | null;
    venue?: string | null;
    homeTeamId?: string;
    awayTeamId?: string;
  },
) {
  await assertOrganizerAccess(tournamentId, userId);

  const updates: Record<string, unknown> = {};
  if (input.scheduledDate !== undefined) updates.scheduledDate = input.scheduledDate;
  if (input.scheduledTime !== undefined) updates.scheduledTime = input.scheduledTime;
  if (input.estimatedDurationMinutes !== undefined) updates.estimatedDurationMinutes = input.estimatedDurationMinutes;
  if (input.venue !== undefined) updates.venue = input.venue;
  if (input.homeTeamId !== undefined) updates.homeTeamId = input.homeTeamId;
  if (input.awayTeamId !== undefined) updates.awayTeamId = input.awayTeamId;

  if (Object.keys(updates).length === 0) {
    throw new AppError('VALIDATION_ERROR', 'No fields to update', 400);
  }

  const [updated] = await db
    .update(tournamentFixtures)
    .set(updates)
    .where(and(
      eq(tournamentFixtures.id, fixtureId),
      eq(tournamentFixtures.tournamentId, tournamentId),
    ))
    .returning();

  if (!updated) {
    throw new AppError('NOT_FOUND', 'Fixture not found', 404);
  }

  // Check for schedule conflicts
  let scheduleWarning: string | null = null;
  if (updated.venue && updated.scheduledDate && updated.scheduledTime) {
    scheduleWarning = await detectScheduleConflict(
      tournamentId,
      fixtureId,
      updated.venue,
      updated.scheduledDate,
      updated.scheduledTime,
      updated.estimatedDurationMinutes ?? 180,
    );
  }

  return { fixture: updated, scheduleWarning };
}

// -- Standings --

export async function getStandings(tournamentId: string, groupName?: string) {
  const conditions = [eq(tournamentStandings.tournamentId, tournamentId)];
  if (groupName) {
    conditions.push(eq(tournamentStandings.groupName, groupName));
  }

  const result = await db
    .select({
      tournamentId: tournamentStandings.tournamentId,
      teamId: tournamentStandings.teamId,
      groupName: tournamentStandings.groupName,
      played: tournamentStandings.played,
      won: tournamentStandings.won,
      lost: tournamentStandings.lost,
      tied: tournamentStandings.tied,
      noResult: tournamentStandings.noResult,
      points: tournamentStandings.points,
      nrr: tournamentStandings.nrr,
      totalRunsScored: tournamentStandings.totalRunsScored,
      totalOversFaced: tournamentStandings.totalOversFaced,
      totalRunsConceded: tournamentStandings.totalRunsConceded,
      totalOversBowled: tournamentStandings.totalOversBowled,
      position: tournamentStandings.position,
      teamName: teams.name,
    })
    .from(tournamentStandings)
    .innerJoin(teams, eq(tournamentStandings.teamId, teams.id))
    .where(and(...conditions))
    .orderBy(desc(tournamentStandings.points), desc(tournamentStandings.nrr));

  // Get distinct groups
  const groupsResult = await db
    .select({ groupName: tournamentStandings.groupName })
    .from(tournamentStandings)
    .where(eq(tournamentStandings.tournamentId, tournamentId))
    .groupBy(tournamentStandings.groupName)
    .orderBy(tournamentStandings.groupName);

  const groups = groupsResult
    .map((g) => g.groupName)
    .filter((g): g is string => g !== null);

  return { standings: result, groups };
}

// -- Leaderboard --

export async function getLeaderboard(tournamentId: string, category: string, limit: number = 10) {
  // All leaderboard queries join through: stats → innings → matches WHERE tournament_id
  if (category === 'runs') {
    const result = await db
      .select({
        playerId: battingStats.playerId,
        playerName: users.displayName,
        totalRuns: sum(battingStats.runsScored).mapWith(Number),
        matchCount: count(sql`DISTINCT ${innings.matchId}`),
      })
      .from(battingStats)
      .innerJoin(innings, eq(battingStats.inningsId, innings.id))
      .innerJoin(matches, eq(innings.matchId, matches.id))
      .innerJoin(users, eq(battingStats.playerId, users.id))
      .where(eq(matches.tournamentId, tournamentId))
      .groupBy(battingStats.playerId, users.displayName)
      .orderBy(desc(sum(battingStats.runsScored)))
      .limit(limit);

    return {
      category,
      leaderboard: result.map((r, i) => ({
        rank: i + 1,
        playerId: r.playerId,
        playerName: r.playerName ?? 'Unknown',
        teamName: '',
        value: r.totalRuns ?? 0,
        matches: r.matchCount ?? 0,
      })),
    };
  }

  if (category === 'wickets') {
    const result = await db
      .select({
        playerId: bowlingStats.playerId,
        playerName: users.displayName,
        totalWickets: sum(bowlingStats.wicketsTaken).mapWith(Number),
        matchCount: count(sql`DISTINCT ${innings.matchId}`),
      })
      .from(bowlingStats)
      .innerJoin(innings, eq(bowlingStats.inningsId, innings.id))
      .innerJoin(matches, eq(innings.matchId, matches.id))
      .innerJoin(users, eq(bowlingStats.playerId, users.id))
      .where(eq(matches.tournamentId, tournamentId))
      .groupBy(bowlingStats.playerId, users.displayName)
      .orderBy(desc(sum(bowlingStats.wicketsTaken)))
      .limit(limit);

    return {
      category,
      leaderboard: result.map((r, i) => ({
        rank: i + 1,
        playerId: r.playerId,
        playerName: r.playerName ?? 'Unknown',
        teamName: '',
        value: r.totalWickets ?? 0,
        matches: r.matchCount ?? 0,
      })),
    };
  }

  // Default: return empty
  return { category, leaderboard: [] };
}

// -- Fixture Generation Algorithms --

interface TeamEntry {
  teamId: string;
  groupName: string | null;
  seedNumber: number | null;
  teamName: string;
}

type FixtureValue = {
  tournamentId: string;
  roundNumber: number;
  roundType: string;
  fixtureOrder: number;
  groupName?: string | null;
  homeTeamId: string;
  awayTeamId: string;
};

function generateRoundRobinFixtures(tournamentId: string, teamEntries: TeamEntry[]): FixtureValue[] {
  const fixtures: FixtureValue[] = [];
  const n = teamEntries.length;
  let order = 0;

  // Standard round-robin: each pair plays once
  for (let i = 0; i < n; i++) {
    for (let j = i + 1; j < n; j++) {
      order++;
      fixtures.push({
        tournamentId,
        roundNumber: 1,
        roundType: 'group',
        fixtureOrder: order,
        groupName: null,
        homeTeamId: teamEntries[i]!.teamId,
        awayTeamId: teamEntries[j]!.teamId,
      });
    }
  }

  return fixtures;
}

function generateKnockoutFixtures(
  tournamentId: string,
  teamEntries: TeamEntry[],
  hasThirdPlace: boolean,
): FixtureValue[] {
  const fixtures: FixtureValue[] = [];
  const n = teamEntries.length;

  // Sort by seed number
  const sorted = [...teamEntries].sort((a, b) => (a.seedNumber ?? 999) - (b.seedNumber ?? 999));

  if (n === 2) {
    // Final only
    fixtures.push({
      tournamentId,
      roundNumber: 1,
      roundType: 'final',
      fixtureOrder: 1,
      homeTeamId: sorted[0]!.teamId,
      awayTeamId: sorted[1]!.teamId,
    });
  } else if (n <= 4) {
    // Semi-finals + final
    let matchOrder = 0;
    // SF1: seed 1 vs seed 4 (or last)
    matchOrder++;
    fixtures.push({
      tournamentId,
      roundNumber: 1,
      roundType: 'semi_final',
      fixtureOrder: matchOrder,
      homeTeamId: sorted[0]!.teamId,
      awayTeamId: sorted[Math.min(3, n - 1)]!.teamId,
    });
    // SF2: seed 2 vs seed 3
    if (n >= 3) {
      matchOrder++;
      fixtures.push({
        tournamentId,
        roundNumber: 1,
        roundType: 'semi_final',
        fixtureOrder: matchOrder,
        homeTeamId: sorted[1]!.teamId,
        awayTeamId: sorted[2]!.teamId,
      });
    }
    // Final placeholder (teams TBD until semis complete)
    // For now, use first seeds as placeholders
    fixtures.push({
      tournamentId,
      roundNumber: 2,
      roundType: 'final',
      fixtureOrder: 1,
      homeTeamId: sorted[0]!.teamId,
      awayTeamId: sorted[1]!.teamId,
    });

    if (hasThirdPlace && n >= 4) {
      fixtures.push({
        tournamentId,
        roundNumber: 2,
        roundType: 'third_place',
        fixtureOrder: 2,
        homeTeamId: sorted[2]!.teamId,
        awayTeamId: sorted[3]!.teamId,
      });
    }
  } else if (n <= 8) {
    // Quarter-finals + semi-finals + final
    let order = 0;
    // QF pairings: 1v8, 4v5, 2v7, 3v6 (standard seeded bracket)
    const qfPairs = [
      [0, Math.min(7, n - 1)],
      [3, Math.min(4, n - 1)],
      [1, Math.min(6, n - 1)],
      [2, Math.min(5, n - 1)],
    ];

    for (const [homeIdx, awayIdx] of qfPairs) {
      if (homeIdx! < n && awayIdx! < n && homeIdx !== awayIdx) {
        order++;
        fixtures.push({
          tournamentId,
          roundNumber: 1,
          roundType: 'quarter_final',
          fixtureOrder: order,
          homeTeamId: sorted[homeIdx!]!.teamId,
          awayTeamId: sorted[awayIdx!]!.teamId,
        });
      }
    }

    // Semi-final placeholders
    fixtures.push({
      tournamentId,
      roundNumber: 2,
      roundType: 'semi_final',
      fixtureOrder: 1,
      homeTeamId: sorted[0]!.teamId,
      awayTeamId: sorted[1]!.teamId,
    });
    fixtures.push({
      tournamentId,
      roundNumber: 2,
      roundType: 'semi_final',
      fixtureOrder: 2,
      homeTeamId: sorted[2]!.teamId,
      awayTeamId: sorted[Math.min(3, n - 1)]!.teamId,
    });

    // Final placeholder
    fixtures.push({
      tournamentId,
      roundNumber: 3,
      roundType: 'final',
      fixtureOrder: 1,
      homeTeamId: sorted[0]!.teamId,
      awayTeamId: sorted[1]!.teamId,
    });

    if (hasThirdPlace) {
      fixtures.push({
        tournamentId,
        roundNumber: 3,
        roundType: 'third_place',
        fixtureOrder: 2,
        homeTeamId: sorted[2]!.teamId,
        awayTeamId: sorted[Math.min(3, n - 1)]!.teamId,
      });
    }
  }

  return fixtures;
}

function generateGroupKnockoutFixtures(
  tournamentId: string,
  teamEntries: TeamEntry[],
  numGroups: number,
  qualifyPerGroup: number,
  hasThirdPlace: boolean,
): FixtureValue[] {
  const fixtures: FixtureValue[] = [];

  // Split teams into groups
  const groups: Map<string, TeamEntry[]> = new Map();
  for (let i = 0; i < numGroups; i++) {
    groups.set(String.fromCharCode(65 + i), []);
  }

  // Assign teams to groups based on groupName, or round-robin if not assigned
  teamEntries.forEach((team, idx) => {
    const groupKey = team.groupName ?? String.fromCharCode(65 + (idx % numGroups));
    const group = groups.get(groupKey);
    if (group) {
      group.push(team);
    } else {
      // Fallback: assign to group A
      groups.get('A')?.push(team);
    }
  });

  // Generate round-robin within each group
  let roundNumber = 1;
  let totalOrder = 0;
  groups.forEach((groupTeams, groupName) => {
    for (let i = 0; i < groupTeams.length; i++) {
      for (let j = i + 1; j < groupTeams.length; j++) {
        totalOrder++;
        fixtures.push({
          tournamentId,
          roundNumber,
          roundType: 'group',
          fixtureOrder: totalOrder,
          groupName,
          homeTeamId: groupTeams[i]!.teamId,
          awayTeamId: groupTeams[j]!.teamId,
        });
      }
    }
  });

  // Generate knockout fixtures from qualifiers
  const totalQualifiers = numGroups * qualifyPerGroup;
  if (totalQualifiers >= 2) {
    // Build placeholder knockout bracket
    // Seeding: A1 vs B2, B1 vs A2, etc.
    const qualifiers: TeamEntry[] = [];
    const groupNames = [...groups.keys()].sort();

    for (let pos = 0; pos < qualifyPerGroup; pos++) {
      for (const gn of groupNames) {
        const groupTeams = groups.get(gn) ?? [];
        if (pos < groupTeams.length) {
          qualifiers.push({ ...groupTeams[pos]!, groupName: gn });
        }
      }
    }

    // Generate knockout from qualifiers
    const koFixtures = generateKnockoutFixtures(tournamentId, qualifiers, hasThirdPlace);
    // Adjust round numbers for knockout stage
    const maxGroupRound = roundNumber;
    for (const kf of koFixtures) {
      kf.roundNumber += maxGroupRound;
      fixtures.push(kf);
    }
  }

  return fixtures;
}

// -- Schedule Conflict Detection --

async function detectScheduleConflict(
  tournamentId: string,
  excludeFixtureId: string,
  venue: string,
  date: string,
  time: string,
  durationMinutes: number,
): Promise<string | null> {
  // Find other fixtures at same venue on same date (excluding current fixture)
  const otherFixtures = await db
    .select({
      id: tournamentFixtures.id,
      scheduledTime: tournamentFixtures.scheduledTime,
      estimatedDurationMinutes: tournamentFixtures.estimatedDurationMinutes,
      fixtureOrder: tournamentFixtures.fixtureOrder,
    })
    .from(tournamentFixtures)
    .where(and(
      eq(tournamentFixtures.tournamentId, tournamentId),
      eq(tournamentFixtures.venue, venue),
      eq(tournamentFixtures.scheduledDate, date),
      sql`${tournamentFixtures.id} != ${excludeFixtureId}`,
      sql`${tournamentFixtures.scheduledTime} IS NOT NULL`,
    ));

  for (const other of otherFixtures) {
    if (!other.scheduledTime) continue;
    const otherDuration = other.estimatedDurationMinutes ?? 180;

    // Simple time overlap check
    const currentStart = parseTimeToMinutes(time);
    const currentEnd = currentStart + durationMinutes;
    const otherStart = parseTimeToMinutes(other.scheduledTime);
    const otherEnd = otherStart + otherDuration;

    if (currentStart < otherEnd && otherStart < currentEnd) {
      return `Another fixture at ${venue} on ${date} overlaps (Match #${other.fixtureOrder} at ${other.scheduledTime}, ~${otherDuration} min)`;
    }
  }

  return null;
}

function parseTimeToMinutes(timeStr: string): number {
  const [hours, minutes] = timeStr.split(':').map(Number);
  return (hours ?? 0) * 60 + (minutes ?? 0);
}

// -- Helpers --

async function assertOrganizerAccess(tournamentId: string, userId: string) {
  const [tournament] = await db
    .select({ createdBy: tournaments.createdBy })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) {
    throw new AppError('NOT_FOUND', 'Tournament not found', 404);
  }

  if (tournament.createdBy !== userId) {
    throw new AppError('FORBIDDEN', 'Only the tournament organizer can perform this action', 403);
  }
}

async function assertTeamCaptainAccess(teamId: string, userId: string) {
  const [team] = await db
    .select({ createdBy: teams.createdBy })
    .from(teams)
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .limit(1);

  if (!team) {
    throw new AppError('NOT_FOUND', 'Team not found', 404);
  }

  if (team.createdBy === userId) return; // Owner has access

  const [rosterEntry] = await db
    .select({ role: teamRosters.role })
    .from(teamRosters)
    .where(and(
      eq(teamRosters.teamId, teamId),
      eq(teamRosters.playerId, userId),
      eq(teamRosters.isActive, true),
    ))
    .limit(1);

  if (!rosterEntry || rosterEntry.role !== 'captain') {
    throw new AppError('FORBIDDEN', 'Only team owner or captain can perform this action', 403);
  }
}

async function assertRosterSize(teamId: string, minPlayers: number) {
  const [rosterCount] = await db
    .select({ count: count() })
    .from(teamRosters)
    .where(and(eq(teamRosters.teamId, teamId), eq(teamRosters.isActive, true)));

  if (rosterCount!.count < minPlayers) {
    throw new AppError('VALIDATION_ERROR', `Team must have at least ${minPlayers} players in roster`, 400);
  }
}
