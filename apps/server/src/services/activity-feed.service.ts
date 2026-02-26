import { eq, and, desc, count, inArray } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { activityFeed } from '../db/schema/activity-feed.ts';
import { matches, matchPlayers, matchResult } from '../db/schema/matches.ts';
import { teams } from '../db/schema/teams.ts';
import { teamRosters } from '../db/schema/teams.ts';
import { tournamentTeams, tournaments } from '../db/schema/tournaments.ts';


interface CreateActivityEventInput {
  userId: string;
  eventType: string;
  title: string;
  description?: string;
  referenceType?: string;
  referenceId?: string;
  deliveryId?: string;
}

export async function createActivityEvent(input: CreateActivityEventInput) {
  const [event] = await db
    .insert(activityFeed)
    .values({
      userId: input.userId,
      eventType: input.eventType,
      title: input.title,
      description: input.description ?? null,
      referenceType: input.referenceType ?? null,
      referenceId: input.referenceId ?? null,
      deliveryId: input.deliveryId ?? null,
    })
    .returning();

  return event!;
}

export async function createBulkActivityEvents(events: CreateActivityEventInput[]) {
  if (events.length === 0) return [];

  const result = await db
    .insert(activityFeed)
    .values(
      events.map((e) => ({
        userId: e.userId,
        eventType: e.eventType,
        title: e.title,
        description: e.description ?? null,
        referenceType: e.referenceType ?? null,
        referenceId: e.referenceId ?? null,
        deliveryId: e.deliveryId ?? null,
      })),
    )
    .returning();

  return result;
}

export async function getActivityFeed(userId: string, page: number = 1, limit: number = 20) {
  const offset = (page - 1) * limit;

  const events = await db
    .select()
    .from(activityFeed)
    .where(eq(activityFeed.userId, userId))
    .orderBy(desc(activityFeed.createdAt))
    .limit(limit)
    .offset(offset);

  const [countResult] = await db
    .select({ total: count() })
    .from(activityFeed)
    .where(eq(activityFeed.userId, userId));

  return {
    events,
    total: countResult!.total,
    page,
  };
}

export async function markEventsAsRead(userId: string, eventIds: string[]) {
  if (eventIds.length === 0) return;

  await db
    .update(activityFeed)
    .set({ isRead: true })
    .where(
      and(
        eq(activityFeed.userId, userId),
        inArray(activityFeed.id, eventIds),
      ),
    );
}

export async function getUnreadCount(userId: string): Promise<number> {
  const [result] = await db
    .select({ count: count() })
    .from(activityFeed)
    .where(
      and(
        eq(activityFeed.userId, userId),
        eq(activityFeed.isRead, false),
      ),
    );

  return result!.count;
}

// ============================================================
// Delete by Delivery (milestone undo support)
// ============================================================

export async function deleteActivityEventsByDeliveryId(deliveryId: string) {
  await db
    .delete(activityFeed)
    .where(eq(activityFeed.deliveryId, deliveryId));
}

// ============================================================
// Helper: get all match player IDs
// ============================================================

async function getMatchPlayerIds(matchId: string): Promise<string[]> {
  const players = await db
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(eq(matchPlayers.matchId, matchId));

  return players.map((p) => p.playerId);
}

// Helper: get all tournament participant IDs (all teams' rosters, deduplicated)
async function getTournamentParticipantIds(tournamentId: string): Promise<string[]> {
  const registeredTeamRows = await db
    .select({ teamId: tournamentTeams.teamId })
    .from(tournamentTeams)
    .where(eq(tournamentTeams.tournamentId, tournamentId));

  if (registeredTeamRows.length === 0) return [];

  const teamIds = registeredTeamRows.map((r) => r.teamId);

  const rosterMembers = await db
    .select({ playerId: teamRosters.playerId })
    .from(teamRosters)
    .where(
      and(
        inArray(teamRosters.teamId, teamIds),
        eq(teamRosters.isActive, true),
      ),
    );

  return [...new Set(rosterMembers.map((r) => r.playerId))];
}

// Helper: get team roster player IDs
async function getTeamRosterPlayerIds(teamId: string): Promise<string[]> {
  const rosterMembers = await db
    .select({ playerId: teamRosters.playerId })
    .from(teamRosters)
    .where(
      and(
        eq(teamRosters.teamId, teamId),
        eq(teamRosters.isActive, true),
      ),
    );

  return rosterMembers.map((r) => r.playerId);
}

// ============================================================
// Event Emitters (fire-and-forget from service hooks)
// ============================================================

// -- Enriched match_completed --

export async function emitMatchCompletedEvents(matchId: string) {
  const [match] = await db
    .select({ id: matches.id, homeTeamId: matches.homeTeamId, awayTeamId: matches.awayTeamId })
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) return;

  // Get team names
  const teamRows = await db
    .select({ id: teams.id, name: teams.name })
    .from(teams)
    .where(inArray(teams.id, [match.homeTeamId, match.awayTeamId]));

  const teamMap = Object.fromEntries(teamRows.map((t) => [t.id, t.name]));

  // Get result summary
  const [result] = await db
    .select({ summary: matchResult.summary, resultType: matchResult.resultType })
    .from(matchResult)
    .where(eq(matchResult.matchId, matchId))
    .limit(1);

  // Build enriched title from result summary
  const fallbackTitle = `${teamMap[match.homeTeamId] ?? 'Team'} vs ${teamMap[match.awayTeamId] ?? 'Team'}`;
  const title = result?.summary
    ? `Match Result: ${result.summary}`
    : `Match Completed: ${fallbackTitle}`;

  const playerIds = await getMatchPlayerIds(matchId);
  if (playerIds.length === 0) return;

  const events = playerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'match_completed',
    title,
    description: result?.summary ?? 'Match has ended',
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

// -- Personal Milestones --

export interface MilestoneInfo {
  type: 'century' | 'half_century' | 'five_wicket_haul' | 'three_wicket_haul' | 'hat_trick';
  playerName: string;
  playerId: string;
}

export async function emitMilestoneEvents(matchId: string, deliveryId: string, milestones: MilestoneInfo[]) {
  if (milestones.length === 0) return;

  const playerIds = await getMatchPlayerIds(matchId);
  if (playerIds.length === 0) return;

  const titleMap: Record<string, (name: string) => string> = {
    century: (name) => `Century! ${name} scored 100 runs`,
    half_century: (name) => `Half-Century! ${name} scored 50 runs`,
    five_wicket_haul: (name) => `5 Wickets! ${name} took 5 wickets`,
    three_wicket_haul: (name) => `3 Wickets! ${name} took 3 wickets`,
    hat_trick: (name) => `Hat-Trick! ${name} took 3 in 3 balls`,
  };

  const events: CreateActivityEventInput[] = [];

  for (const milestone of milestones) {
    const titleFn = titleMap[milestone.type];
    if (!titleFn) continue;

    for (const playerId of playerIds) {
      events.push({
        userId: playerId,
        eventType: milestone.type,
        title: titleFn(milestone.playerName),
        referenceType: 'match',
        referenceId: matchId,
        deliveryId,
      });
    }
  }

  await createBulkActivityEvents(events);
}

// -- Match Lifecycle --

export async function emitMatchStartedEvents(matchId: string) {
  const [match] = await db
    .select({ homeTeamId: matches.homeTeamId, awayTeamId: matches.awayTeamId })
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) return;

  const teamRows = await db
    .select({ id: teams.id, name: teams.name })
    .from(teams)
    .where(inArray(teams.id, [match.homeTeamId, match.awayTeamId]));

  const teamMap = Object.fromEntries(teamRows.map((t) => [t.id, t.name]));
  const title = `Match Started: ${teamMap[match.homeTeamId] ?? 'Team'} vs ${teamMap[match.awayTeamId] ?? 'Team'}`;

  const playerIds = await getMatchPlayerIds(matchId);
  if (playerIds.length === 0) return;

  const events = playerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'match_started',
    title,
    description: 'Toss completed. Match is now live!',
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

export async function emitMatchAbandonedEvents(matchId: string) {
  const [match] = await db
    .select({ homeTeamId: matches.homeTeamId, awayTeamId: matches.awayTeamId })
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) return;

  const teamRows = await db
    .select({ id: teams.id, name: teams.name })
    .from(teams)
    .where(inArray(teams.id, [match.homeTeamId, match.awayTeamId]));

  const teamMap = Object.fromEntries(teamRows.map((t) => [t.id, t.name]));
  const title = `Match Abandoned: ${teamMap[match.homeTeamId] ?? 'Team'} vs ${teamMap[match.awayTeamId] ?? 'Team'}`;

  const playerIds = await getMatchPlayerIds(matchId);
  if (playerIds.length === 0) return;

  const events = playerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'match_abandoned',
    title,
    description: 'Match abandoned — No Result',
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

export async function emitInningsCompletedEvents(matchId: string, inningsNumber: number, reason: string) {
  const playerIds = await getMatchPlayerIds(matchId);
  if (playerIds.length === 0) return;

  const reasonLabels: Record<string, string> = {
    all_out: 'All Out',
    overs_complete: 'Overs Completed',
    target_chased: 'Target Chased',
    declared: 'Declared',
  };

  const reasonLabel = reasonLabels[reason] ?? reason;

  const events = playerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'innings_completed',
    title: `Innings ${inningsNumber} Complete: ${reasonLabel}`,
    description: `Innings ${inningsNumber} ended — ${reasonLabel}`,
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

// -- Tournament Events --

export async function emitTournamentMatchResultEvents(matchId: string) {
  const [match] = await db
    .select({ tournamentId: matches.tournamentId })
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match?.tournamentId) return;

  // Get result summary
  const [result] = await db
    .select({ summary: matchResult.summary })
    .from(matchResult)
    .where(eq(matchResult.matchId, matchId))
    .limit(1);

  const participantIds = await getTournamentParticipantIds(match.tournamentId);
  if (participantIds.length === 0) return;

  const events = participantIds.map((playerId) => ({
    userId: playerId,
    eventType: 'tournament_match_result',
    title: result?.summary ? `Tournament Match: ${result.summary}` : 'Tournament Match Completed',
    description: result?.summary ?? 'A tournament match has ended',
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

export async function emitTeamAddedToTournamentEvents(tournamentId: string, teamId: string) {
  const [tournament] = await db
    .select({ name: tournaments.name })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) return;

  const rosterPlayerIds = await getTeamRosterPlayerIds(teamId);
  if (rosterPlayerIds.length === 0) return;

  const events = rosterPlayerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'team_added_tournament',
    title: `Team added to ${tournament.name}`,
    description: `Your team has been added to the tournament ${tournament.name}`,
    referenceType: 'tournament',
    referenceId: tournamentId,
  }));

  await createBulkActivityEvents(events);
}

export async function emitRegistrationResolvedEvents(tournamentId: string, teamId: string, action: 'approved' | 'rejected', rejectionReason?: string | null) {
  const [tournament] = await db
    .select({ name: tournaments.name })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) return;

  const rosterPlayerIds = await getTeamRosterPlayerIds(teamId);
  if (rosterPlayerIds.length === 0) return;

  const statusLabel = action === 'approved' ? 'Approved' : 'Rejected';
  const description = action === 'approved'
    ? `Your team's registration for ${tournament.name} has been approved`
    : `Your team's registration for ${tournament.name} was rejected${rejectionReason ? `: ${rejectionReason}` : ''}`;

  const events = rosterPlayerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'registration_resolved',
    title: `Registration ${statusLabel}: ${tournament.name}`,
    description,
    referenceType: 'tournament',
    referenceId: tournamentId,
  }));

  await createBulkActivityEvents(events);
}

export async function emitFixturesGeneratedEvents(tournamentId: string) {
  const [tournament] = await db
    .select({ name: tournaments.name })
    .from(tournaments)
    .where(eq(tournaments.id, tournamentId))
    .limit(1);

  if (!tournament) return;

  const participantIds = await getTournamentParticipantIds(tournamentId);
  if (participantIds.length === 0) return;

  const events = participantIds.map((playerId) => ({
    userId: playerId,
    eventType: 'fixtures_generated',
    title: `Fixtures Generated: ${tournament.name}`,
    description: `Match fixtures have been generated for ${tournament.name}`,
    referenceType: 'tournament',
    referenceId: tournamentId,
  }));

  await createBulkActivityEvents(events);
}

// -- Existing tournament update events --

export async function emitTournamentUpdateEvents(tournamentId: string, tournamentName: string, newStatus: string) {
  const participantIds = await getTournamentParticipantIds(tournamentId);
  if (participantIds.length === 0) return;

  const statusLabel = newStatus.charAt(0).toUpperCase() + newStatus.slice(1);

  const events = participantIds.map((playerId) => ({
    userId: playerId,
    eventType: 'tournament_update',
    title: `${tournamentName} is now ${statusLabel}`,
    description: `Tournament status changed to ${statusLabel}`,
    referenceType: 'tournament',
    referenceId: tournamentId,
  }));

  await createBulkActivityEvents(events);
}

// -- Team Events --

export async function emitPlayerAddedEvents(teamId: string, addedPlayerId: string) {
  const [team] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, teamId))
    .limit(1);

  if (!team) return;

  // Notify the added player
  await createActivityEvent({
    userId: addedPlayerId,
    eventType: 'player_added',
    title: `Added to ${team.name}`,
    description: `You have been added to the team ${team.name}`,
    referenceType: 'team',
    referenceId: teamId,
  });
}

export async function emitPlayerRemovedEvents(teamId: string, playerId: string) {
  const [team] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, teamId))
    .limit(1);

  if (!team) return;

  await createActivityEvent({
    userId: playerId,
    eventType: 'player_removed',
    title: `Removed from ${team.name}`,
    description: `You have been removed from the team ${team.name}`,
    referenceType: 'team',
    referenceId: teamId,
  });
}

export async function emitTeamJoinedEvents(teamId: string, playerId: string) {
  const [team] = await db
    .select({ name: teams.name })
    .from(teams)
    .where(eq(teams.id, teamId))
    .limit(1);

  if (!team) return;

  await createActivityEvent({
    userId: playerId,
    eventType: 'team_joined',
    title: `Joined ${team.name}`,
    description: `You have joined the team ${team.name}`,
    referenceType: 'team',
    referenceId: teamId,
  });
}
