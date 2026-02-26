import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray, and } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { activityFeed } from '../../src/db/schema/activity-feed.ts';
import { tournaments, tournamentTeams } from '../../src/db/schema/tournaments.ts';
import { deliveries } from '../../src/db/schema/deliveries.ts';
import { innings } from '../../src/db/schema/innings.ts';
import {
  emitMilestoneEvents,
  deleteActivityEventsByDeliveryId,
  emitMatchStartedEvents,
  emitMatchAbandonedEvents,
  emitInningsCompletedEvents,
  emitTournamentMatchResultEvents,
  emitTeamAddedToTournamentEvents,
  emitRegistrationResolvedEvents,
  emitPlayerRemovedEvents,
  emitTeamJoinedEvents,
  type MilestoneInfo,
} from '../../src/services/activity-feed.service.ts';

const TEST_SUFFIX = `af-${Date.now()}`;

// Test entity IDs
let scorerUserId: string;
const allUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];
let matchId: string;
let inningsId: string;
let deliveryId: string;

// Tournament test data
let tournamentId: string;
let tournTeamId: string; // third team for tournament-only tests

beforeAll(async () => {
  // Create scorer user
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-af-scorer-${TEST_SUFFIX}`,
      phone: '+919870000001',
      displayName: 'AF Test Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  allUserIds.push(scorerUserId);

  // Create home players (3 is enough for emitter tests)
  const homePlayers = await db
    .insert(users)
    .values(
      Array.from({ length: 3 }, (_, i) => ({
        firebaseUid: `test-af-home-${i}-${TEST_SUFFIX}`,
        phone: `+91987000${String(i + 10).padStart(4, '0')}`,
        displayName: `AF Home ${i + 1}`,
      })),
    )
    .returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  allUserIds.push(...homePlayerIds);

  // Create away players (3)
  const awayPlayers = await db
    .insert(users)
    .values(
      Array.from({ length: 3 }, (_, i) => ({
        firebaseUid: `test-af-away-${i}-${TEST_SUFFIX}`,
        phone: `+91987001${String(i + 10).padStart(4, '0')}`,
        displayName: `AF Away ${i + 1}`,
      })),
    )
    .returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  allUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `AF Home ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `AF Away ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add players to rosters
  await db.insert(teamRosters).values(
    homePlayerIds.map((playerId) => ({ teamId: homeTeamId, playerId, role: 'player' })),
  );
  await db.insert(teamRosters).values(
    awayPlayerIds.map((playerId) => ({ teamId: awayTeamId, playerId, role: 'player' })),
  );

  // Create a match directly (SETUP status is fine — emitters query matchPlayers, not status)
  const [match] = await db
    .insert(matches)
    .values({
      homeTeamId,
      awayTeamId,
      format: 'T20',
      totalOvers: 20,
      ballTypeId: 1,
      matchDate: '2026-06-15',
      playersPerSide: 3,
      createdBy: scorerUserId,
      status: 'LIVE',
    })
    .returning();
  matchId = match!.id;

  // Insert match_players so getMatchPlayerIds works
  const allMatchPlayerIds = [...homePlayerIds, ...awayPlayerIds];
  await db.insert(matchPlayers).values(
    allMatchPlayerIds.map((playerId, idx) => ({
      matchId,
      teamId: idx < homePlayerIds.length ? homeTeamId : awayTeamId,
      playerId,
    })),
  );

  // Create innings + a delivery so we have a deliveryId for milestone tests
  const [inn] = await db
    .insert(innings)
    .values({
      matchId,
      inningsNumber: 1,
      battingTeamId: homeTeamId,
      bowlingTeamId: awayTeamId,
    })
    .returning();
  inningsId = inn!.id;

  const [del] = await db
    .insert(deliveries)
    .values({
      inningsId,
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: homePlayerIds[0]!,
      nonStrikerId: homePlayerIds[1]!,
      bowlerId: awayPlayerIds[0]!,
      runsFromBat: 4,
      totalRuns: 4,
      isLegal: true,
      isWide: false,
      isNoBall: false,
      isBye: false,
      isLegBye: false,
      wideRuns: 0,
      noBallRuns: 0,
      byeRuns: 0,
      legByeRuns: 0,
      isWicket: false,
      isBoundaryFour: true,
      isBoundarySix: false,
    })
    .returning();
  deliveryId = del!.id;

  // --- Tournament test data ---
  // Create a third team for tournament-specific tests
  const tournPlayers = await db
    .insert(users)
    .values(
      Array.from({ length: 2 }, (_, i) => ({
        firebaseUid: `test-af-tourn-${i}-${TEST_SUFFIX}`,
        phone: `+91987002${String(i + 10).padStart(4, '0')}`,
        displayName: `AF Tourn ${i + 1}`,
      })),
    )
    .returning();
  const tournPlayerIds = tournPlayers.map((p) => p.id);
  allUserIds.push(...tournPlayerIds);

  const [tournTeam] = await db
    .insert(teams)
    .values({ name: `AF Tourn ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  tournTeamId = tournTeam!.id;

  await db.insert(teamRosters).values(
    tournPlayerIds.map((playerId) => ({ teamId: tournTeamId, playerId, role: 'player' })),
  );

  // Create tournament
  const [tourn] = await db
    .insert(tournaments)
    .values({
      name: `AF Tournament ${TEST_SUFFIX}`,
      format: 'T20',
      oversPerMatch: 20,
      ballTypeId: 1,
      status: 'active',
      createdBy: scorerUserId,
    })
    .returning();
  tournamentId = tourn!.id;

  // Add home team and tourn team to tournament
  await db.insert(tournamentTeams).values([
    { tournamentId, teamId: homeTeamId },
    { tournamentId, teamId: tournTeamId },
  ]);
});

afterAll(async () => {
  // Clean up activity feed events created during tests
  if (allUserIds.length > 0) {
    await db.delete(activityFeed).where(inArray(activityFeed.userId, allUserIds));
  }

  // Delete deliveries, innings, match players, match result, match
  await db.delete(deliveries).where(eq(deliveries.inningsId, inningsId));
  await db.delete(innings).where(eq(innings.matchId, matchId));
  await db.delete(matchPlayers).where(eq(matchPlayers.matchId, matchId));
  await db.delete(matchResult).where(eq(matchResult.matchId, matchId));
  await db.delete(matches).where(eq(matches.id, matchId));

  // Tournament cleanup
  await db.delete(tournamentTeams).where(eq(tournamentTeams.tournamentId, tournamentId));
  await db.delete(tournaments).where(eq(tournaments.id, tournamentId));

  // Rosters, teams, users
  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, tournTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));
  await db.delete(teams).where(eq(teams.id, tournTeamId));

  if (allUserIds.length > 0) {
    await db.delete(users).where(inArray(users.id, allUserIds));
  }
});

/** Helper to clear activity_feed for our test users before each describe block */
async function clearActivityFeed() {
  if (allUserIds.length > 0) {
    await db.delete(activityFeed).where(inArray(activityFeed.userId, allUserIds));
  }
}

/** Helper to count activity_feed rows for a given eventType and referenceId */
async function countEvents(eventType: string, referenceId: string) {
  const rows = await db
    .select()
    .from(activityFeed)
    .where(
      and(
        eq(activityFeed.eventType, eventType),
        eq(activityFeed.referenceId, referenceId),
      ),
    );
  return rows;
}

// ============================================================
// emitMilestoneEvents
// ============================================================
describe('emitMilestoneEvents', () => {
  it('creates events for all match players with correct deliveryId', async () => {
    await clearActivityFeed();

    const milestones: MilestoneInfo[] = [
      { type: 'half_century', playerName: 'AF Home 1', playerId: homePlayerIds[0]! },
    ];

    await emitMilestoneEvents(matchId, deliveryId, milestones);

    const events = await countEvents('half_century', matchId);
    // Should create one event per match player (6 total: 3 home + 3 away)
    expect(events.length).toBe(6);

    // All events should reference the delivery
    for (const event of events) {
      expect(event.deliveryId).toBe(deliveryId);
      expect(event.title).toContain('AF Home 1');
      expect(event.title).toContain('50 runs');
      expect(event.referenceType).toBe('match');
      expect(event.referenceId).toBe(matchId);
    }
  });

  it('creates events for multiple milestones in one call', async () => {
    await clearActivityFeed();

    const milestones: MilestoneInfo[] = [
      { type: 'century', playerName: 'AF Home 1', playerId: homePlayerIds[0]! },
      { type: 'hat_trick', playerName: 'AF Away 1', playerId: awayPlayerIds[0]! },
    ];

    await emitMilestoneEvents(matchId, deliveryId, milestones);

    const centuryEvents = await countEvents('century', matchId);
    const hatTrickEvents = await countEvents('hat_trick', matchId);

    expect(centuryEvents.length).toBe(6);
    expect(hatTrickEvents.length).toBe(6);
  });

  it('does nothing when milestones array is empty', async () => {
    await clearActivityFeed();

    await emitMilestoneEvents(matchId, deliveryId, []);

    const events = await db
      .select()
      .from(activityFeed)
      .where(eq(activityFeed.referenceId, matchId));

    expect(events.length).toBe(0);
  });
});

// ============================================================
// deleteActivityEventsByDeliveryId
// ============================================================
describe('deleteActivityEventsByDeliveryId', () => {
  it('removes milestone events with matching deliveryId, leaves others intact', async () => {
    await clearActivityFeed();

    // Create milestone events (with deliveryId)
    const milestones: MilestoneInfo[] = [
      { type: 'half_century', playerName: 'AF Home 1', playerId: homePlayerIds[0]! },
    ];
    await emitMilestoneEvents(matchId, deliveryId, milestones);

    // Create a non-milestone event (without deliveryId) for one of the same users
    await db.insert(activityFeed).values({
      userId: homePlayerIds[0]!,
      eventType: 'match_started',
      title: 'Test match started event',
      referenceType: 'match',
      referenceId: matchId,
    });

    // Verify both types exist
    const beforeEvents = await db
      .select()
      .from(activityFeed)
      .where(eq(activityFeed.referenceId, matchId));
    const milestoneCountBefore = beforeEvents.filter((e) => e.deliveryId === deliveryId).length;
    const otherCountBefore = beforeEvents.filter((e) => e.deliveryId !== deliveryId).length;
    expect(milestoneCountBefore).toBe(6);
    expect(otherCountBefore).toBe(1);

    // Delete by deliveryId
    await deleteActivityEventsByDeliveryId(deliveryId);

    // Only milestone events should be gone
    const afterEvents = await db
      .select()
      .from(activityFeed)
      .where(eq(activityFeed.referenceId, matchId));
    expect(afterEvents.length).toBe(1);
    expect(afterEvents[0]!.eventType).toBe('match_started');
  });
});

// ============================================================
// emitMatchStartedEvents
// ============================================================
describe('emitMatchStartedEvents', () => {
  it('creates events for all match players with team names in title', async () => {
    await clearActivityFeed();

    await emitMatchStartedEvents(matchId);

    const events = await countEvents('match_started', matchId);
    expect(events.length).toBe(6);

    // Title should contain team names
    const title = events[0]!.title;
    expect(title).toContain('Match Started');
    expect(title).toContain(`AF Home ${TEST_SUFFIX}`);
    expect(title).toContain(`AF Away ${TEST_SUFFIX}`);
  });
});

// ============================================================
// emitMatchAbandonedEvents
// ============================================================
describe('emitMatchAbandonedEvents', () => {
  it('creates events for all match players', async () => {
    await clearActivityFeed();

    await emitMatchAbandonedEvents(matchId);

    const events = await countEvents('match_abandoned', matchId);
    expect(events.length).toBe(6);

    const title = events[0]!.title;
    expect(title).toContain('Match Abandoned');
    expect(events[0]!.description).toContain('No Result');
  });
});

// ============================================================
// emitInningsCompletedEvents
// ============================================================
describe('emitInningsCompletedEvents', () => {
  it('creates events with correct reason text for all_out', async () => {
    await clearActivityFeed();

    await emitInningsCompletedEvents(matchId, 1, 'all_out');

    const events = await countEvents('innings_completed', matchId);
    expect(events.length).toBe(6);

    expect(events[0]!.title).toBe('Innings 1 Complete: All Out');
    expect(events[0]!.description).toContain('All Out');
  });

  it('creates events with correct reason text for overs_complete', async () => {
    await clearActivityFeed();

    await emitInningsCompletedEvents(matchId, 1, 'overs_complete');

    const events = await countEvents('innings_completed', matchId);
    expect(events.length).toBe(6);
    expect(events[0]!.title).toBe('Innings 1 Complete: Overs Completed');
  });

  it('creates events with correct reason text for target_chased', async () => {
    await clearActivityFeed();

    await emitInningsCompletedEvents(matchId, 2, 'target_chased');

    const events = await countEvents('innings_completed', matchId);
    expect(events.length).toBe(6);
    expect(events[0]!.title).toBe('Innings 2 Complete: Target Chased');
  });

  it('creates events with correct reason text for declared', async () => {
    await clearActivityFeed();

    await emitInningsCompletedEvents(matchId, 1, 'declared');

    const events = await countEvents('innings_completed', matchId);
    expect(events.length).toBe(6);
    expect(events[0]!.title).toBe('Innings 1 Complete: Declared');
  });
});

// ============================================================
// emitTournamentMatchResultEvents
// ============================================================
describe('emitTournamentMatchResultEvents', () => {
  let tournMatchId: string;

  beforeAll(async () => {
    // Create a match linked to the tournament
    const [tournMatch] = await db
      .insert(matches)
      .values({
        homeTeamId,
        awayTeamId,
        format: 'T20',
        totalOvers: 20,
        ballTypeId: 1,
        matchDate: '2026-06-15',
        playersPerSide: 3,
        createdBy: scorerUserId,
        status: 'COMPLETED',
        tournamentId,
      })
      .returning();
    tournMatchId = tournMatch!.id;

    // Add match result
    await db.insert(matchResult).values({
      matchId: tournMatchId,
      resultType: 'runs',
      summary: 'AF Home won by 50 runs',
      margin: 50,
    });
  });

  afterAll(async () => {
    await db.delete(matchResult).where(eq(matchResult.matchId, tournMatchId));
    await db.delete(matches).where(eq(matches.id, tournMatchId));
  });

  it('creates events for all tournament participants', async () => {
    await clearActivityFeed();

    await emitTournamentMatchResultEvents(tournMatchId);

    const events = await countEvents('tournament_match_result', tournMatchId);

    // Tournament has homeTeam (3 players) + tournTeam (2 players) = 5 participants
    expect(events.length).toBe(5);
    expect(events[0]!.title).toContain('AF Home won by 50 runs');
  });

  it('does nothing for a match without tournamentId', async () => {
    await clearActivityFeed();

    // matchId is the non-tournament match
    await emitTournamentMatchResultEvents(matchId);

    const events = await countEvents('tournament_match_result', matchId);
    expect(events.length).toBe(0);
  });
});

// ============================================================
// emitTeamAddedToTournamentEvents
// ============================================================
describe('emitTeamAddedToTournamentEvents', () => {
  it('creates events for team roster members only', async () => {
    await clearActivityFeed();

    await emitTeamAddedToTournamentEvents(tournamentId, awayTeamId);

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'team_added_tournament'),
          eq(activityFeed.referenceId, tournamentId),
        ),
      );

    // awayTeam has 3 roster members
    expect(events.length).toBe(3);
    expect(events[0]!.title).toContain(`AF Tournament ${TEST_SUFFIX}`);
    expect(events[0]!.referenceType).toBe('tournament');

    // Verify events are only for away player IDs
    const eventUserIds = events.map((e) => e.userId).sort();
    expect(eventUserIds).toEqual([...awayPlayerIds].sort());
  });
});

// ============================================================
// emitRegistrationResolvedEvents
// ============================================================
describe('emitRegistrationResolvedEvents', () => {
  it('creates approved events for team roster', async () => {
    await clearActivityFeed();

    await emitRegistrationResolvedEvents(tournamentId, homeTeamId, 'approved');

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'registration_resolved'),
          eq(activityFeed.referenceId, tournamentId),
        ),
      );

    expect(events.length).toBe(3); // homeTeam has 3 roster members
    expect(events[0]!.title).toContain('Approved');
    expect(events[0]!.title).toContain(`AF Tournament ${TEST_SUFFIX}`);
    expect(events[0]!.description).toContain('approved');
  });

  it('creates rejected events with reason', async () => {
    await clearActivityFeed();

    await emitRegistrationResolvedEvents(tournamentId, homeTeamId, 'rejected', 'Roster too small');

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'registration_resolved'),
          eq(activityFeed.referenceId, tournamentId),
        ),
      );

    expect(events.length).toBe(3);
    expect(events[0]!.title).toContain('Rejected');
    expect(events[0]!.description).toContain('rejected');
    expect(events[0]!.description).toContain('Roster too small');
  });

  it('creates rejected events without reason', async () => {
    await clearActivityFeed();

    await emitRegistrationResolvedEvents(tournamentId, homeTeamId, 'rejected');

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'registration_resolved'),
          eq(activityFeed.referenceId, tournamentId),
        ),
      );

    expect(events.length).toBe(3);
    expect(events[0]!.title).toContain('Rejected');
    // Description should NOT contain "undefined" or extra colon
    expect(events[0]!.description).not.toContain('undefined');
  });
});

// ============================================================
// emitPlayerRemovedEvents
// ============================================================
describe('emitPlayerRemovedEvents', () => {
  it('creates a single event for the removed player', async () => {
    await clearActivityFeed();

    await emitPlayerRemovedEvents(homeTeamId, homePlayerIds[2]!);

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'player_removed'),
          eq(activityFeed.userId, homePlayerIds[2]!),
        ),
      );

    expect(events.length).toBe(1);
    expect(events[0]!.title).toContain('Removed from');
    expect(events[0]!.title).toContain(`AF Home ${TEST_SUFFIX}`);
    expect(events[0]!.referenceType).toBe('team');
    expect(events[0]!.referenceId).toBe(homeTeamId);
  });
});

// ============================================================
// emitTeamJoinedEvents
// ============================================================
describe('emitTeamJoinedEvents', () => {
  it('creates a single event for the joined player', async () => {
    await clearActivityFeed();

    await emitTeamJoinedEvents(awayTeamId, awayPlayerIds[1]!);

    const events = await db
      .select()
      .from(activityFeed)
      .where(
        and(
          eq(activityFeed.eventType, 'team_joined'),
          eq(activityFeed.userId, awayPlayerIds[1]!),
        ),
      );

    expect(events.length).toBe(1);
    expect(events[0]!.title).toContain('Joined');
    expect(events[0]!.title).toContain(`AF Away ${TEST_SUFFIX}`);
    expect(events[0]!.referenceType).toBe('team');
    expect(events[0]!.referenceId).toBe(awayTeamId);
  });
});
