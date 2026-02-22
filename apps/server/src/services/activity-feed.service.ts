import { eq, and, desc, count, inArray } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { activityFeed } from '../db/schema/activity-feed.ts';
import { matches, matchPlayers, matchResult } from '../db/schema/matches.ts';
import { teams } from '../db/schema/teams.ts';
import { teamRosters } from '../db/schema/teams.ts';
import { tournamentTeams } from '../db/schema/tournaments.ts';

interface CreateActivityEventInput {
  userId: string;
  eventType: string;
  title: string;
  description?: string;
  referenceType?: string;
  referenceId?: string;
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
// Event Emitters (fire-and-forget from service hooks)
// ============================================================

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
  const title = `${teamMap[match.homeTeamId] ?? 'Team'} vs ${teamMap[match.awayTeamId] ?? 'Team'}`;

  // Get result summary
  const [result] = await db
    .select({ summary: matchResult.summary })
    .from(matchResult)
    .where(eq(matchResult.matchId, matchId))
    .limit(1);

  // Get all players in the match
  const players = await db
    .select({ playerId: matchPlayers.playerId })
    .from(matchPlayers)
    .where(eq(matchPlayers.matchId, matchId));

  if (players.length === 0) return;

  const events = players.map((p) => ({
    userId: p.playerId,
    eventType: 'match_completed',
    title: `Match Completed: ${title}`,
    description: result?.summary ?? 'Match has ended',
    referenceType: 'match',
    referenceId: matchId,
  }));

  await createBulkActivityEvents(events);
}

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

export async function emitTournamentUpdateEvents(tournamentId: string, tournamentName: string, newStatus: string) {
  // Get all players from teams registered in this tournament
  const registeredTeamRows = await db
    .select({ teamId: tournamentTeams.teamId })
    .from(tournamentTeams)
    .where(eq(tournamentTeams.tournamentId, tournamentId));

  if (registeredTeamRows.length === 0) return;

  const teamIds = registeredTeamRows.map((r) => r.teamId);

  // Get all active roster members of these teams
  const rosterMembers = await db
    .select({ playerId: teamRosters.playerId })
    .from(teamRosters)
    .where(
      and(
        inArray(teamRosters.teamId, teamIds),
        eq(teamRosters.isActive, true),
      ),
    );

  // Deduplicate player IDs (a player might be on multiple teams)
  const uniquePlayerIds = [...new Set(rosterMembers.map((r) => r.playerId))];
  if (uniquePlayerIds.length === 0) return;

  const statusLabel = newStatus.charAt(0).toUpperCase() + newStatus.slice(1);

  const events = uniquePlayerIds.map((playerId) => ({
    userId: playerId,
    eventType: 'tournament_update',
    title: `${tournamentName} is now ${statusLabel}`,
    description: `Tournament status changed to ${statusLabel}`,
    referenceType: 'tournament',
    referenceId: tournamentId,
  }));

  await createBulkActivityEvents(events);
}
