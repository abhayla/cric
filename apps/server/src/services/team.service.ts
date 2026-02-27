import { eq, and, ilike, count, sql } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { teams } from '../db/schema/teams.ts';
import { teamRosters } from '../db/schema/teams.ts';
import { matches } from '../db/schema/matches.ts';
import { users } from '../db/schema/users.ts';
import { AppError } from '../middleware/error-handler.ts';
import { emitPlayerAddedEvents, emitPlayerRemovedEvents, emitTeamJoinedEvents } from './activity-feed.service.ts';

const MAX_ROSTER_SIZE = 25;

interface CreateTeamInput {
  name: string;
  location?: string;
  logoUrl?: string;
  createdBy: string;
}

interface UpdateTeamInput {
  name?: string;
  location?: string;
  logoUrl?: string;
}

interface AddPlayerInput {
  playerId: string;
  jerseyNumber?: number;
  role?: string;
}

export async function createTeam(input: CreateTeamInput) {
  const trimmedName = input.name.trim();
  if (trimmedName.length < 2 || trimmedName.length > 50) {
    throw new AppError('VALIDATION_ERROR', 'Team name must be 2-50 characters', 400);
  }

  const [team] = await db
    .insert(teams)
    .values({
      name: trimmedName,
      location: input.location?.trim() || null,
      logoUrl: input.logoUrl || null,
      createdBy: input.createdBy,
    })
    .returning();

  return team!;
}

export async function getTeams(userId: string, page: number = 1, limit: number = 20) {
  const offset = (page - 1) * limit;

  // Get teams where user is creator or roster member
  const result = await db
    .select({
      id: teams.id,
      name: teams.name,
      logoUrl: teams.logoUrl,
      location: teams.location,
      createdBy: teams.createdBy,
      isActive: teams.isActive,
      createdAt: teams.createdAt,
      updatedAt: teams.updatedAt,
    })
    .from(teams)
    .where(
      and(
        eq(teams.isActive, true),
        sql`(${teams.createdBy} = ${userId} OR ${teams.id} IN (
          SELECT ${teamRosters.teamId} FROM ${teamRosters}
          WHERE ${teamRosters.playerId} = ${userId} AND ${teamRosters.isActive} = true
        ))`,
      ),
    )
    .orderBy(teams.createdAt)
    .limit(limit)
    .offset(offset);

  // Get total count
  const [countResult] = await db
    .select({ total: count() })
    .from(teams)
    .where(
      and(
        eq(teams.isActive, true),
        sql`(${teams.createdBy} = ${userId} OR ${teams.id} IN (
          SELECT ${teamRosters.teamId} FROM ${teamRosters}
          WHERE ${teamRosters.playerId} = ${userId} AND ${teamRosters.isActive} = true
        ))`,
      ),
    );

  // Get player counts and user roles for each team
  const teamsWithMeta = await Promise.all(
    result.map(async (team) => {
      const [playerCountResult] = await db
        .select({ count: count() })
        .from(teamRosters)
        .where(and(eq(teamRosters.teamId, team.id), eq(teamRosters.isActive, true)));

      let role = 'member';
      if (team.createdBy === userId) {
        role = 'owner';
      } else {
        const [rosterEntry] = await db
          .select({ role: teamRosters.role })
          .from(teamRosters)
          .where(
            and(
              eq(teamRosters.teamId, team.id),
              eq(teamRosters.playerId, userId),
              eq(teamRosters.isActive, true),
            ),
          )
          .limit(1);
        if (rosterEntry) {
          role = rosterEntry.role;
        }
      }

      return {
        ...team,
        playerCount: playerCountResult!.count,
        role,
      };
    }),
  );

  // Batch query: count live matches per team
  const teamIds = result.map((t) => t.id);
  const liveMatchCounts = new Map<string, number>();
  if (teamIds.length > 0) {
    const liveCounts = await db
      .select({
        teamId: sql<string>`team_id`,
        count: count(),
      })
      .from(
        sql`(
          SELECT ${matches.homeTeamId} AS team_id, ${matches.id} FROM ${matches}
          WHERE ${matches.status} IN ('live', 'innings_break')
            AND ${matches.homeTeamId} IN ${sql`(${sql.join(teamIds.map(id => sql`${id}`), sql`, `)})`}
          UNION ALL
          SELECT ${matches.awayTeamId} AS team_id, ${matches.id} FROM ${matches}
          WHERE ${matches.status} IN ('live', 'innings_break')
            AND ${matches.awayTeamId} IN ${sql`(${sql.join(teamIds.map(id => sql`${id}`), sql`, `)})`}
        ) AS live_matches`,
      )
      .groupBy(sql`team_id`);
    for (const row of liveCounts) {
      liveMatchCounts.set(row.teamId, row.count);
    }
  }

  return {
    teams: teamsWithMeta.map((t) => ({
      ...t,
      liveMatchCount: liveMatchCounts.get(t.id) ?? 0,
    })),
    total: countResult!.total,
    page,
  };
}

export async function getTeam(teamId: string) {
  const [team] = await db
    .select()
    .from(teams)
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .limit(1);

  if (!team) return null;

  const roster = await db
    .select({
      id: teamRosters.id,
      playerId: teamRosters.playerId,
      jerseyNumber: teamRosters.jerseyNumber,
      role: teamRosters.role,
      isActive: teamRosters.isActive,
      joinedAt: teamRosters.joinedAt,
      displayName: users.displayName,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      phone: users.phone,
      avatarUrl: users.avatarUrl,
      isVerified: users.isVerified,
    })
    .from(teamRosters)
    .innerJoin(users, eq(teamRosters.playerId, users.id))
    .where(and(eq(teamRosters.teamId, teamId), eq(teamRosters.isActive, true)))
    .orderBy(teamRosters.joinedAt);

  return { ...team, roster };
}

export async function updateTeam(teamId: string, userId: string, input: UpdateTeamInput) {
  // Check authorization
  await assertTeamAuth(teamId, userId);

  const updates: Record<string, unknown> = {};
  if (input.name !== undefined) {
    const trimmed = input.name.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      throw new AppError('VALIDATION_ERROR', 'Team name must be 2-50 characters', 400);
    }
    updates.name = trimmed;
  }
  if (input.location !== undefined) updates.location = input.location.trim() || null;
  if (input.logoUrl !== undefined) updates.logoUrl = input.logoUrl || null;

  if (Object.keys(updates).length === 0) {
    throw new AppError('VALIDATION_ERROR', 'No fields to update', 400);
  }

  const [updated] = await db
    .update(teams)
    .set(updates)
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .returning();

  return updated ?? null;
}

export async function deleteTeam(teamId: string, userId: string) {
  await assertTeamAuth(teamId, userId);

  const [updated] = await db
    .update(teams)
    .set({ isActive: false })
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .returning();

  return updated ?? null;
}

export async function addPlayer(teamId: string, userId: string, input: AddPlayerInput) {
  await assertTeamAuth(teamId, userId);

  // Check roster size
  const [rosterCount] = await db
    .select({ count: count() })
    .from(teamRosters)
    .where(and(eq(teamRosters.teamId, teamId), eq(teamRosters.isActive, true)));

  if (rosterCount!.count >= MAX_ROSTER_SIZE) {
    throw new AppError('VALIDATION_ERROR', `Team roster cannot exceed ${MAX_ROSTER_SIZE} players`, 400);
  }

  // Verify player exists
  const [player] = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.id, input.playerId))
    .limit(1);

  if (!player) {
    throw new AppError('NOT_FOUND', 'Player not found', 404);
  }

  // Check if player already on roster
  const [existing] = await db
    .select({ id: teamRosters.id, isActive: teamRosters.isActive })
    .from(teamRosters)
    .where(and(eq(teamRosters.teamId, teamId), eq(teamRosters.playerId, input.playerId)))
    .limit(1);

  if (existing) {
    if (existing.isActive) {
      throw new AppError('CONFLICT', 'Player is already on this team', 409);
    }
    // Reactivate previously removed player
    await db
      .update(teamRosters)
      .set({
        isActive: true,
        role: input.role || 'player',
        jerseyNumber: input.jerseyNumber ?? null,
      })
      .where(eq(teamRosters.id, existing.id));

    // Return enriched entry with user data (matches getTeam roster shape)
    const [enriched] = await db
      .select({
        id: teamRosters.id,
        playerId: teamRosters.playerId,
        jerseyNumber: teamRosters.jerseyNumber,
        role: teamRosters.role,
        isActive: teamRosters.isActive,
        joinedAt: teamRosters.joinedAt,
        displayName: users.displayName,
        battingStyle: users.battingStyle,
        bowlingStyle: users.bowlingStyle,
        playerRole: users.playerRole,
        phone: users.phone,
        avatarUrl: users.avatarUrl,
        isVerified: users.isVerified,
      })
      .from(teamRosters)
      .innerJoin(users, eq(teamRosters.playerId, users.id))
      .where(eq(teamRosters.id, existing.id))
      .limit(1);
    return enriched!;
  }

  const [entry] = await db
    .insert(teamRosters)
    .values({
      teamId,
      playerId: input.playerId,
      jerseyNumber: input.jerseyNumber ?? null,
      role: input.role || 'player',
    })
    .returning();

  // Return enriched entry with user data (matches getTeam roster shape)
  const [enriched] = await db
    .select({
      id: teamRosters.id,
      playerId: teamRosters.playerId,
      jerseyNumber: teamRosters.jerseyNumber,
      role: teamRosters.role,
      isActive: teamRosters.isActive,
      joinedAt: teamRosters.joinedAt,
      displayName: users.displayName,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      phone: users.phone,
      avatarUrl: users.avatarUrl,
      isVerified: users.isVerified,
    })
    .from(teamRosters)
    .innerJoin(users, eq(teamRosters.playerId, users.id))
    .where(eq(teamRosters.id, entry!.id))
    .limit(1);

  // Fire-and-forget activity feed events
  emitPlayerAddedEvents(teamId, input.playerId).catch((err) =>
    console.error(`[ActivityFeed] Failed for team=${teamId}:`, err),
  );
  emitTeamJoinedEvents(teamId, input.playerId).catch((err) =>
    console.error(`[ActivityFeed] Team joined emit failed for team=${teamId}:`, err),
  );

  return enriched!;
}

export async function removePlayer(teamId: string, userId: string, playerId: string) {
  await assertTeamAuth(teamId, userId);

  const [updated] = await db
    .update(teamRosters)
    .set({ isActive: false })
    .where(
      and(
        eq(teamRosters.teamId, teamId),
        eq(teamRosters.playerId, playerId),
        eq(teamRosters.isActive, true),
      ),
    )
    .returning();

  if (!updated) {
    throw new AppError('NOT_FOUND', 'Player not found in team roster', 404);
  }

  // Fire-and-forget activity feed event
  emitPlayerRemovedEvents(teamId, playerId).catch((err) =>
    console.error(`[ActivityFeed] Player removed emit failed for team=${teamId}:`, err),
  );

  return updated;
}

export async function searchPlayers(query: string, limit: number = 10) {
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

// Helper: assert user is owner or captain of team
async function assertTeamAuth(teamId: string, userId: string) {
  const [team] = await db
    .select({ createdBy: teams.createdBy })
    .from(teams)
    .where(and(eq(teams.id, teamId), eq(teams.isActive, true)))
    .limit(1);

  if (!team) {
    throw new AppError('NOT_FOUND', 'Team not found', 404);
  }

  if (team.createdBy === userId) return;

  const [rosterEntry] = await db
    .select({ role: teamRosters.role })
    .from(teamRosters)
    .where(
      and(
        eq(teamRosters.teamId, teamId),
        eq(teamRosters.playerId, userId),
        eq(teamRosters.isActive, true),
      ),
    )
    .limit(1);

  if (!rosterEntry || rosterEntry.role !== 'captain') {
    throw new AppError('FORBIDDEN', 'Only team owner or captain can perform this action', 403);
  }
}
