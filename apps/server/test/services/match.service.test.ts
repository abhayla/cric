import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { teams, teamRosters } from '../../src/db/schema/teams.ts';
import { matches, matchPlayers, matchResult } from '../../src/db/schema/matches.ts';
import { innings } from '../../src/db/schema/innings.ts';
import {
  createMatch,
  getMatches,
  getMatch,
  setPlayingXI,
  recordToss,
} from '../../src/services/match.service.ts';

const TEST_SUFFIX = Date.now();

// Test user IDs
let scorerUserId: string;
const testUserIds: string[] = [];
let homeTeamId: string;
let awayTeamId: string;
let testMatchId: string;

// We need 11+ players per team for playing XI tests
const PLAYER_COUNT = 12;
let homePlayerIds: string[] = [];
let awayPlayerIds: string[] = [];

/** Helper: create a match at "toss" status with both playing XI set */
async function createTossReadyMatch() {
  const match = await createMatch({
    homeTeamId,
    awayTeamId,
    format: 'T20',
    totalOvers: 20,
    ballTypeId: 1,
    matchDate: '2026-03-25',
    createdBy: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: homeTeamId,
    playerIds: homePlayerIds.slice(0, 11),
    captainId: homePlayerIds[0]!,
    keeperId: homePlayerIds[1]!,
    userId: scorerUserId,
  });

  await setPlayingXI(match.id, {
    teamId: awayTeamId,
    playerIds: awayPlayerIds.slice(0, 11),
    captainId: awayPlayerIds[0]!,
    keeperId: awayPlayerIds[1]!,
    userId: scorerUserId,
  });

  return match;
}

beforeAll(async () => {
  // Create scorer user
  const [scorer] = await db
    .insert(users)
    .values({
      firebaseUid: `test-match-scorer-${TEST_SUFFIX}`,
      phone: '+919876550001',
      displayName: 'Match Scorer',
    })
    .returning();
  scorerUserId = scorer!.id;
  testUserIds.push(scorerUserId);

  // Create home team players
  const homeValues = Array.from({ length: PLAYER_COUNT }, (_, i) => ({
    firebaseUid: `test-match-home-${i}-${TEST_SUFFIX}`,
    phone: `+91987655${String(i + 10).padStart(4, '0')}`,
    displayName: `Home Player ${i + 1}`,
  }));
  const homePlayers = await db.insert(users).values(homeValues).returning();
  homePlayerIds = homePlayers.map((p) => p.id);
  testUserIds.push(...homePlayerIds);

  // Create away team players
  const awayValues = Array.from({ length: PLAYER_COUNT }, (_, i) => ({
    firebaseUid: `test-match-away-${i}-${TEST_SUFFIX}`,
    phone: `+91987656${String(i + 10).padStart(4, '0')}`,
    displayName: `Away Player ${i + 1}`,
  }));
  const awayPlayers = await db.insert(users).values(awayValues).returning();
  awayPlayerIds = awayPlayers.map((p) => p.id);
  testUserIds.push(...awayPlayerIds);

  // Create teams
  const [homeTeam] = await db
    .insert(teams)
    .values({ name: `Home Team ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  homeTeamId = homeTeam!.id;

  const [awayTeam] = await db
    .insert(teams)
    .values({ name: `Away Team ${TEST_SUFFIX}`, createdBy: scorerUserId })
    .returning();
  awayTeamId = awayTeam!.id;

  // Add players to team rosters (batch)
  const homeRosterValues = homePlayerIds.map((playerId) => ({
    teamId: homeTeamId,
    playerId,
    role: 'player',
  }));
  await db.insert(teamRosters).values(homeRosterValues);

  const awayRosterValues = awayPlayerIds.map((playerId) => ({
    teamId: awayTeamId,
    playerId,
    role: 'player',
  }));
  await db.insert(teamRosters).values(awayRosterValues);
});

afterAll(async () => {
  // Get all match IDs created by scorer
  const matchIds = await db
    .select({ id: matches.id })
    .from(matches)
    .where(eq(matches.createdBy, scorerUserId))
    .then((r) => r.map((m) => m.id));

  if (matchIds.length > 0) {
    // Clean in reverse dependency order
    await db.delete(matchResult).where(inArray(matchResult.matchId, matchIds));
    await db.delete(innings).where(inArray(innings.matchId, matchIds));
    await db.delete(matchPlayers).where(inArray(matchPlayers.matchId, matchIds));
    await db.delete(matches).where(inArray(matches.id, matchIds));
  }

  await db.delete(teamRosters).where(eq(teamRosters.teamId, homeTeamId));
  await db.delete(teamRosters).where(eq(teamRosters.teamId, awayTeamId));
  await db.delete(teams).where(eq(teams.id, homeTeamId));
  await db.delete(teams).where(eq(teams.id, awayTeamId));

  if (testUserIds.length > 0) {
    await db.delete(users).where(inArray(users.id, testUserIds));
  }
});

describe('Match Service', () => {
  describe('createMatch', () => {
    it('creates match with valid input', async () => {
      const match = await createMatch({
        homeTeamId,
        awayTeamId,
        format: 'T20',
        totalOvers: 20,
        ballTypeId: 1,
        venue: 'Wankhede Stadium',
        matchDate: '2026-03-15',
        createdBy: scorerUserId,
      });

      expect(match).toBeDefined();
      expect(match.id).toBeTruthy();
      expect(match.homeTeamId).toBe(homeTeamId);
      expect(match.awayTeamId).toBe(awayTeamId);
      expect(match.format).toBe('T20');
      expect(match.totalOvers).toBe(20);
      expect(match.status).toBe('setup');
      expect(match.scorerId).toBe(scorerUserId);
      expect(match.playersPerSide).toBe(11);
      expect(match.wideRuns).toBe(1);
      expect(match.noBallRuns).toBe(1);
      testMatchId = match.id;
    });

    it('rejects homeTeamId === awayTeamId', async () => {
      await expect(
        createMatch({
          homeTeamId,
          awayTeamId: homeTeamId,
          format: 'T20',
          totalOvers: 20,
          ballTypeId: 1,
          matchDate: '2026-03-15',
          createdBy: scorerUserId,
        }),
      ).rejects.toThrow('Home team and away team must be different');
    });

    it('rejects totalOvers < 1', async () => {
      await expect(
        createMatch({
          homeTeamId,
          awayTeamId,
          format: 'T20',
          totalOvers: 0,
          ballTypeId: 1,
          matchDate: '2026-03-15',
          createdBy: scorerUserId,
        }),
      ).rejects.toThrow('Total overs must be between 1 and 50');
    });

    it('rejects totalOvers > 50', async () => {
      await expect(
        createMatch({
          homeTeamId,
          awayTeamId,
          format: 'T20',
          totalOvers: 51,
          ballTypeId: 1,
          matchDate: '2026-03-15',
          createdBy: scorerUserId,
        }),
      ).rejects.toThrow('Total overs must be between 1 and 50');
    });

    it('rejects playersPerSide < 2', async () => {
      await expect(
        createMatch({
          homeTeamId,
          awayTeamId,
          format: 'T20',
          totalOvers: 20,
          ballTypeId: 1,
          matchDate: '2026-03-15',
          playersPerSide: 1,
          createdBy: scorerUserId,
        }),
      ).rejects.toThrow('Players per side must be between 2 and 11');
    });

    it('rejects playersPerSide > 11', async () => {
      await expect(
        createMatch({
          homeTeamId,
          awayTeamId,
          format: 'T20',
          totalOvers: 20,
          ballTypeId: 1,
          matchDate: '2026-03-15',
          playersPerSide: 12,
          createdBy: scorerUserId,
        }),
      ).rejects.toThrow('Players per side must be between 2 and 11');
    });

    it('defaults wideRuns=1, noBallRuns=1, playersPerSide=11', async () => {
      const match = await createMatch({
        homeTeamId,
        awayTeamId,
        format: 'ODI',
        totalOvers: 50,
        ballTypeId: 1,
        matchDate: '2026-03-16',
        createdBy: scorerUserId,
      });

      expect(match.playersPerSide).toBe(11);
      expect(match.wideRuns).toBe(1);
      expect(match.noBallRuns).toBe(1);
      expect(match.maxOversPerBowler).toBe(10); // ceil(50/5)
    });
  });

  describe('getMatches', () => {
    it('returns matches for user (as scorer)', async () => {
      const result = await getMatches(scorerUserId);
      expect(result.matches.length).toBeGreaterThanOrEqual(1);
      const found = result.matches.find((m) => m.id === testMatchId);
      expect(found).toBeDefined();
    });

    it('filters by status', async () => {
      const result = await getMatches(scorerUserId, { status: 'setup' });
      expect(result.matches.length).toBeGreaterThanOrEqual(1);
      result.matches.forEach((m) => expect(m.status).toBe('setup'));
    });

    it('supports pagination', async () => {
      const result = await getMatches(scorerUserId, { page: 1, limit: 1 });
      expect(result.matches.length).toBeLessThanOrEqual(1);
      expect(result.page).toBe(1);
    });

    it('returns team names in response', async () => {
      const result = await getMatches(scorerUserId);
      const found = result.matches.find((m) => m.id === testMatchId);
      expect(found).toBeDefined();
      expect(found!.homeTeam).toBeDefined();
      expect(found!.homeTeam.id).toBe(homeTeamId);
      expect(found!.homeTeam.name).toContain('Home Team');
      expect(found!.awayTeam).toBeDefined();
      expect(found!.awayTeam.id).toBe(awayTeamId);
      expect(found!.awayTeam.name).toContain('Away Team');
    });

    it('returns null innings/result for setup match', async () => {
      const result = await getMatches(scorerUserId, { status: 'setup' });
      const setupMatch = result.matches.find((m) => m.id === testMatchId);
      expect(setupMatch).toBeDefined();
      expect(setupMatch!.currentInnings).toBeNull();
      expect(setupMatch!.result).toBeNull();
    });
  });

  describe('getMatch', () => {
    it('returns match with team names', async () => {
      const match = await getMatch(testMatchId);
      expect(match).not.toBeNull();
      expect(match!.id).toBe(testMatchId);
      expect(match!.homeTeamName).toBeDefined();
      expect(match!.awayTeamName).toBeDefined();
    });

    it('returns null for non-existent match', async () => {
      const match = await getMatch('00000000-0000-0000-0000-000000000000');
      expect(match).toBeNull();
    });
  });

  describe('setPlayingXI', () => {
    let playingXIMatchId: string;

    beforeAll(async () => {
      const match = await createMatch({
        homeTeamId,
        awayTeamId,
        format: 'T20',
        totalOvers: 20,
        ballTypeId: 1,
        matchDate: '2026-03-17',
        createdBy: scorerUserId,
      });
      playingXIMatchId = match.id;
    });

    it('sets playing XI for a team', async () => {
      const playerIds = homePlayerIds.slice(0, 11);
      const result = await setPlayingXI(playingXIMatchId, {
        teamId: homeTeamId,
        playerIds,
        captainId: playerIds[0]!,
        keeperId: playerIds[1]!,
        userId: scorerUserId,
      });

      expect(result.length).toBe(11);
    });

    it('validates exactly playersPerSide players', async () => {
      const playerIds = awayPlayerIds.slice(0, 5);
      await expect(
        setPlayingXI(playingXIMatchId, {
          teamId: awayTeamId,
          playerIds,
          captainId: playerIds[0]!,
          keeperId: playerIds[1]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Exactly 11 players required');
    });

    it('validates captain in playerIds', async () => {
      const playerIds = awayPlayerIds.slice(0, 11);
      await expect(
        setPlayingXI(playingXIMatchId, {
          teamId: awayTeamId,
          playerIds,
          captainId: awayPlayerIds[11]!,
          keeperId: playerIds[1]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Captain must be in the playing XI');
    });

    it('validates keeper in playerIds', async () => {
      const playerIds = awayPlayerIds.slice(0, 11);
      await expect(
        setPlayingXI(playingXIMatchId, {
          teamId: awayTeamId,
          playerIds,
          captainId: playerIds[0]!,
          keeperId: awayPlayerIds[11]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Keeper must be in the playing XI');
    });

    it('rejects playing XI already submitted (409)', async () => {
      const playerIds = homePlayerIds.slice(0, 11);
      await expect(
        setPlayingXI(playingXIMatchId, {
          teamId: homeTeamId,
          playerIds,
          captainId: playerIds[0]!,
          keeperId: playerIds[1]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('playing XI already submitted');
    });

    it('validates all players in team roster', async () => {
      // Use a player from home team in away team's XI
      const playerIds = [...awayPlayerIds.slice(0, 10), homePlayerIds[0]!];
      await expect(
        setPlayingXI(playingXIMatchId, {
          teamId: awayTeamId,
          playerIds,
          captainId: playerIds[0]!,
          keeperId: playerIds[1]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('not in team roster');
    });

    it('transitions match to "toss" when both teams submitted', async () => {
      const playerIds = awayPlayerIds.slice(0, 11);
      await setPlayingXI(playingXIMatchId, {
        teamId: awayTeamId,
        playerIds,
        captainId: playerIds[0]!,
        keeperId: playerIds[1]!,
        userId: scorerUserId,
      });

      const match = await getMatch(playingXIMatchId);
      expect(match!.status).toBe('toss');
    });
  });

  describe('recordToss', () => {
    let tossMatchId: string;
    let tossValidationMatchIds: string[] = [];

    beforeAll(async () => {
      // Create the main toss test match
      const mainMatch = await createTossReadyMatch();
      tossMatchId = mainMatch.id;

      // Pre-create matches for validation tests (4 needed)
      for (let i = 0; i < 4; i++) {
        const m = await createTossReadyMatch();
        tossValidationMatchIds.push(m.id);
      }
    });

    it('records toss and transitions to "live"', async () => {
      const result = await recordToss(tossMatchId, {
        winnerId: homeTeamId,
        decision: 'bat',
        openingStrikerId: homePlayerIds[0]!,
        openingNonStrikerId: homePlayerIds[1]!,
        openingBowlerId: awayPlayerIds[0]!,
        userId: scorerUserId,
      });

      expect(result.match.status).toBe('live');
      expect(result.match.tossWinnerId).toBe(homeTeamId);
      expect(result.match.tossDecision).toBe('bat');
    });

    it('creates first innings record', async () => {
      const match = await getMatch(tossMatchId);
      expect(match!.innings).toBeDefined();
      expect(match!.innings.length).toBeGreaterThanOrEqual(1);
      expect(match!.innings[0]!.inningsNumber).toBe(1);
      expect(match!.innings[0]!.battingTeamId).toBe(homeTeamId);
      expect(match!.innings[0]!.bowlingTeamId).toBe(awayTeamId);
    });

    it('validates winnerId is one of the match teams', async () => {
      await expect(
        recordToss(tossValidationMatchIds[0]!, {
          winnerId: '00000000-0000-0000-0000-000000000000',
          decision: 'bat',
          openingStrikerId: homePlayerIds[0]!,
          openingNonStrikerId: homePlayerIds[1]!,
          openingBowlerId: awayPlayerIds[0]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Toss winner must be one of the match teams');
    });

    it('validates opening striker in batting team playing XI', async () => {
      await expect(
        recordToss(tossValidationMatchIds[1]!, {
          winnerId: homeTeamId,
          decision: 'bat',
          openingStrikerId: awayPlayerIds[0]!, // away player as striker
          openingNonStrikerId: homePlayerIds[1]!,
          openingBowlerId: awayPlayerIds[0]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Opening striker must be in the batting team');
    });

    it('validates opening bowler in bowling team playing XI', async () => {
      await expect(
        recordToss(tossValidationMatchIds[2]!, {
          winnerId: homeTeamId,
          decision: 'bat',
          openingStrikerId: homePlayerIds[0]!,
          openingNonStrikerId: homePlayerIds[1]!,
          openingBowlerId: homePlayerIds[2]!, // home player as bowler
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Opening bowler must be in the bowling team');
    });

    it('validates striker !== non-striker', async () => {
      await expect(
        recordToss(tossValidationMatchIds[3]!, {
          winnerId: homeTeamId,
          decision: 'bat',
          openingStrikerId: homePlayerIds[0]!,
          openingNonStrikerId: homePlayerIds[0]!, // same as striker
          openingBowlerId: awayPlayerIds[0]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Striker and non-striker must be different players');
    });

    it('rejects if match not in "toss" status', async () => {
      // testMatchId is in "setup" status
      await expect(
        recordToss(testMatchId, {
          winnerId: homeTeamId,
          decision: 'bat',
          openingStrikerId: homePlayerIds[0]!,
          openingNonStrikerId: homePlayerIds[1]!,
          openingBowlerId: awayPlayerIds[0]!,
          userId: scorerUserId,
        }),
      ).rejects.toThrow('Match must be in toss status');
    });
  });

  describe('getMatches enriched response', () => {
    let liveMatchId: string;

    beforeAll(async () => {
      // Create a live match (toss recorded → innings exists)
      const match = await createTossReadyMatch();
      liveMatchId = match.id;
      await recordToss(liveMatchId, {
        winnerId: homeTeamId,
        decision: 'bat',
        openingStrikerId: homePlayerIds[0]!,
        openingNonStrikerId: homePlayerIds[1]!,
        openingBowlerId: awayPlayerIds[0]!,
        userId: scorerUserId,
      });
    });

    it('returns innings data for live match', async () => {
      const result = await getMatches(scorerUserId, { status: 'live' });
      const found = result.matches.find((m) => m.id === liveMatchId);
      expect(found).toBeDefined();
      expect(found!.currentInnings).not.toBeNull();
      expect(found!.currentInnings!.battingTeamId).toBe(homeTeamId);
      expect(found!.currentInnings!.totalRuns).toBe(0);
      expect(found!.currentInnings!.totalWickets).toBe(0);
      expect(found!.currentInnings!.overs).toBe('0.0');
    });

    it('returns result for completed match', async () => {
      // Insert a mock match_result for the live match to test result mapping
      const { matchResult: matchResultTable } = await import('../../src/db/schema/matches.ts');
      await db.insert(matchResultTable).values({
        matchId: liveMatchId,
        resultType: 'runs',
        margin: 15,
        summary: `Home Team ${TEST_SUFFIX} won by 15 runs`,
      });

      // Update match status to completed
      await db
        .update(matches)
        .set({ status: 'completed' })
        .where(eq(matches.id, liveMatchId));

      const result = await getMatches(scorerUserId, { status: 'completed' });
      const found = result.matches.find((m) => m.id === liveMatchId);
      expect(found).toBeDefined();
      expect(found!.result).toContain('won by 15 runs');

      // Restore status for cleanup
      await db
        .update(matches)
        .set({ status: 'live' })
        .where(eq(matches.id, liveMatchId));
    });
  });
});
