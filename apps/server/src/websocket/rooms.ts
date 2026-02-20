import { eq, and, desc } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { matches, matchResult } from '../db/schema/matches.ts';
import { innings } from '../db/schema/innings.ts';
import { deliveries } from '../db/schema/deliveries.ts';
import { battingStats, bowlingStats } from '../db/schema/stats.ts';
import { users } from '../db/schema/users.ts';
import { teams } from '../db/schema/teams.ts';
import type {
  MatchStateMessage,
  ScoreUpdateMessage,
  WicketMessage,
  InningsCompleteMessage,
  MatchCompleteMessage,
  DeliveryUndoneMessage,
  PlayerBattingSnapshot,
  PlayerBowlingSnapshot,
  OverBallDisplay,
  LastDeliveryInfo,
} from '../types/websocket.ts';

// ============================================================
// Room topic helper
// ============================================================

export function matchTopic(matchId: string): string {
  return `match:${matchId}`;
}

// ============================================================
// Get Match State — Full snapshot for room join
// ============================================================

export async function getMatchState(matchId: string): Promise<MatchStateMessage> {
  // Fetch match
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new Error('Match not found');
  }

  // Get current (latest) innings
  const allInnings = await db
    .select()
    .from(innings)
    .where(eq(innings.matchId, matchId))
    .orderBy(desc(innings.inningsNumber));

  const currentInnings = allInnings[0];

  // Fetch team names
  const [homeTeam] = await db.select({ name: teams.name }).from(teams).where(eq(teams.id, match.homeTeamId)).limit(1);
  const [awayTeam] = await db.select({ name: teams.name }).from(teams).where(eq(teams.id, match.awayTeamId)).limit(1);

  if (!currentInnings) {
    // Match exists but no innings yet (still in setup/toss)
    return {
      type: 'match_state',
      matchId,
      data: {
        status: match.status,
        inningsNumber: 0,
        totalRuns: 0,
        totalWickets: 0,
        overs: '0.0',
        currentRunRate: null,
        requiredRunRate: null,
        target: null,
        striker: null,
        nonStriker: null,
        bowler: null,
        currentOver: [],
        recentDeliveries: [],
        battingTeamName: undefined,
        bowlingTeamName: undefined,
        isFreeHitPending: false,
        isMagicOver: false,
        magicOverMultiplier: match.magicOverRunMultiplier,
      },
    };
  }

  // Get batting stats for current innings
  const batterStats = await db
    .select({
      playerId: battingStats.playerId,
      runsScored: battingStats.runsScored,
      ballsFaced: battingStats.ballsFaced,
      fours: battingStats.fours,
      sixes: battingStats.sixes,
      isNotOut: battingStats.isNotOut,
      playerName: users.displayName,
    })
    .from(battingStats)
    .innerJoin(users, eq(users.id, battingStats.playerId))
    .where(eq(battingStats.inningsId, currentInnings.id));

  // Get bowling stats for current innings
  const bowlerStats = await db
    .select({
      playerId: bowlingStats.playerId,
      oversBowled: bowlingStats.oversBowled,
      maidens: bowlingStats.maidens,
      runsConceded: bowlingStats.runsConceded,
      wicketsTaken: bowlingStats.wicketsTaken,
      playerName: users.displayName,
    })
    .from(bowlingStats)
    .innerJoin(users, eq(users.id, bowlingStats.playerId))
    .where(eq(bowlingStats.inningsId, currentInnings.id));

  // Get last delivery to determine current striker/non-striker/bowler
  const [lastDelivery] = await db
    .select()
    .from(deliveries)
    .where(eq(deliveries.inningsId, currentInnings.id))
    .orderBy(desc(deliveries.sequenceNumber))
    .limit(1);

  // Build current over balls
  const currentOverNumber = lastDelivery?.overNumber ?? 0;
  const currentOverDeliveries = await db
    .select()
    .from(deliveries)
    .where(
      and(
        eq(deliveries.inningsId, currentInnings.id),
        eq(deliveries.overNumber, currentOverNumber),
      ),
    )
    .orderBy(deliveries.sequenceNumber);

  const currentOver = currentOverDeliveries.map(deliveryToOverBall);

  // Get recent deliveries (last 12 for display)
  const recentDeliveriesRaw = await db
    .select()
    .from(deliveries)
    .where(eq(deliveries.inningsId, currentInnings.id))
    .orderBy(desc(deliveries.sequenceNumber))
    .limit(12);

  const recentDeliveries = recentDeliveriesRaw.reverse().map(deliveryToOverBall);

  // Build striker/non-striker/bowler snapshots
  let striker: PlayerBattingSnapshot | null = null;
  let nonStriker: PlayerBattingSnapshot | null = null;
  let bowler: PlayerBowlingSnapshot | null = null;

  if (lastDelivery) {
    const strikerStat = batterStats.find((b) => b.playerId === lastDelivery.strikerId);
    if (strikerStat) {
      striker = {
        id: strikerStat.playerId,
        name: strikerStat.playerName,
        runs: strikerStat.runsScored,
        balls: strikerStat.ballsFaced,
        fours: strikerStat.fours,
        sixes: strikerStat.sixes,
        strikeRate: strikerStat.ballsFaced > 0
          ? parseFloat(((strikerStat.runsScored / strikerStat.ballsFaced) * 100).toFixed(2))
          : 0,
      };
    }

    const nonStrikerStat = batterStats.find((b) => b.playerId === lastDelivery.nonStrikerId);
    if (nonStrikerStat) {
      nonStriker = {
        id: nonStrikerStat.playerId,
        name: nonStrikerStat.playerName,
        runs: nonStrikerStat.runsScored,
        balls: nonStrikerStat.ballsFaced,
        fours: nonStrikerStat.fours,
        sixes: nonStrikerStat.sixes,
        strikeRate: nonStrikerStat.ballsFaced > 0
          ? parseFloat(((nonStrikerStat.runsScored / nonStrikerStat.ballsFaced) * 100).toFixed(2))
          : 0,
      };
    }

    const bowlerStat = bowlerStats.find((b) => b.playerId === lastDelivery.bowlerId);
    if (bowlerStat) {
      const bowlerOvers = String(bowlerStat.oversBowled);
      const parsedOvers = parseFloat(bowlerOvers) || 0;
      bowler = {
        id: bowlerStat.playerId,
        name: bowlerStat.playerName,
        overs: bowlerOvers,
        maidens: bowlerStat.maidens,
        runs: bowlerStat.runsConceded,
        wickets: bowlerStat.wicketsTaken,
        economy: parsedOvers > 0
          ? parseFloat((bowlerStat.runsConceded / parsedOvers).toFixed(2))
          : 0,
      };
    }
  }

  // Calculate run rates
  const oversStr = String(currentInnings.totalOvers);
  const parsedOvers = parseFloat(oversStr);
  const oversDecimal = Math.floor(parsedOvers) + (parsedOvers % 1) * 10 / 6;
  const currentRunRate = oversDecimal > 0
    ? parseFloat((currentInnings.totalRuns / oversDecimal).toFixed(2))
    : null;

  let requiredRunRate: number | null = null;
  if (currentInnings.target !== null && currentInnings.inningsNumber >= 2) {
    const runsNeeded = currentInnings.target - currentInnings.totalRuns;
    const totalMatchOvers = match.totalOvers;
    const oversRemaining = totalMatchOvers - oversDecimal;
    if (oversRemaining > 0 && runsNeeded > 0) {
      requiredRunRate = parseFloat((runsNeeded / oversRemaining).toFixed(2));
    }
  }

  // Derive team names based on batting team
  const battingTeamName = currentInnings.battingTeamId === match.homeTeamId
    ? homeTeam?.name
    : awayTeam?.name;
  const bowlingTeamName = currentInnings.battingTeamId === match.homeTeamId
    ? awayTeam?.name
    : homeTeam?.name;

  // Derive free hit: last delivery was a no-ball
  const isFreeHitPending = lastDelivery?.isNoBall === true;

  // Derive magic over
  const magicOverNumbers = (match.magicOverNumbers as number[] | null) ?? [];
  const isMagicOver = magicOverNumbers.includes(currentOverNumber);

  return {
    type: 'match_state',
    matchId,
    data: {
      status: match.status,
      inningsNumber: currentInnings.inningsNumber,
      totalRuns: currentInnings.totalRuns,
      totalWickets: currentInnings.totalWickets,
      overs: oversStr,
      currentRunRate,
      requiredRunRate,
      target: currentInnings.target,
      striker,
      nonStriker,
      bowler,
      currentOver,
      recentDeliveries,
      battingTeamName: battingTeamName ?? undefined,
      bowlingTeamName: bowlingTeamName ?? undefined,
      isFreeHitPending,
      isMagicOver,
      magicOverMultiplier: match.magicOverRunMultiplier,
    },
  };
}

// ============================================================
// Build Score Update Message
// ============================================================

export function buildScoreUpdate(
  matchId: string,
  delivery: typeof deliveries.$inferSelect,
  updatedInnings: typeof innings.$inferSelect,
  batterStat: { playerId: string; name: string; runs: number; balls: number; fours: number; sixes: number } | null,
  bowlerStat: { playerId: string; name: string; overs: string; maidens: number; runs: number; wickets: number } | null,
  currentOver: OverBallDisplay[],
  nonStrikerStat?: { playerId: string; name: string; runs: number; balls: number; fours: number; sixes: number } | null,
  extras?: { battingTeamName?: string; bowlingTeamName?: string; isFreeHitPending?: boolean; isMagicOver?: boolean; magicOverMultiplier?: number },
): ScoreUpdateMessage {
  const oversStr = String(updatedInnings.totalOvers);
  const parsedOvers = parseFloat(oversStr);
  const oversDecimal = Math.floor(parsedOvers) + (parsedOvers % 1) * 10 / 6;
  const currentRunRate = oversDecimal > 0
    ? parseFloat((updatedInnings.totalRuns / oversDecimal).toFixed(2))
    : null;

  const lastDelivery: LastDeliveryInfo = {
    runs: delivery.totalRuns,
    isWide: delivery.isWide,
    isNoBall: delivery.isNoBall,
    isBye: delivery.isBye,
    isLegBye: delivery.isLegBye,
    isWicket: delivery.isWicket,
    isBoundaryFour: delivery.isBoundaryFour,
    isBoundarySix: delivery.isBoundarySix,
    description: formatDeliveryDescription(delivery),
  };

  return {
    type: 'score_update',
    matchId,
    data: {
      totalRuns: updatedInnings.totalRuns,
      totalWickets: updatedInnings.totalWickets,
      overs: oversStr,
      currentRunRate,
      requiredRunRate: null, // Caller can set if needed
      lastDelivery,
      striker: batterStat ? {
        id: batterStat.playerId,
        name: batterStat.name,
        runs: batterStat.runs,
        balls: batterStat.balls,
        fours: batterStat.fours,
        sixes: batterStat.sixes,
        strikeRate: batterStat.balls > 0
          ? parseFloat(((batterStat.runs / batterStat.balls) * 100).toFixed(2))
          : 0,
      } : null,
      nonStriker: nonStrikerStat ? {
        id: nonStrikerStat.playerId,
        name: nonStrikerStat.name,
        runs: nonStrikerStat.runs,
        balls: nonStrikerStat.balls,
        fours: nonStrikerStat.fours,
        sixes: nonStrikerStat.sixes,
        strikeRate: nonStrikerStat.balls > 0
          ? parseFloat(((nonStrikerStat.runs / nonStrikerStat.balls) * 100).toFixed(2))
          : 0,
      } : null,
      bowler: bowlerStat ? {
        id: bowlerStat.playerId,
        name: bowlerStat.name,
        overs: bowlerStat.overs,
        maidens: bowlerStat.maidens,
        runs: bowlerStat.runs,
        wickets: bowlerStat.wickets,
        economy: parseFloat(bowlerStat.overs) > 0
          ? parseFloat((bowlerStat.runs / parseFloat(bowlerStat.overs)).toFixed(2))
          : 0,
      } : null,
      currentOver,
      ...(extras ?? {}),
    },
  };
}

// ============================================================
// Build Wicket Message
// ============================================================

export function buildWicketMessage(
  matchId: string,
  dismissedPlayerName: string,
  dismissalTypeName: string,
  fielderName: string | null,
  bowlerName: string | null,
  teamScore: string,
  overs: string,
): WicketMessage {
  let description = '';
  switch (dismissalTypeName) {
    case 'bowled':
      description = `b ${bowlerName}`;
      break;
    case 'caught':
      description = `c ${fielderName} b ${bowlerName}`;
      break;
    case 'caught_and_bowled':
      description = `c & b ${bowlerName}`;
      break;
    case 'lbw':
      description = `lbw b ${bowlerName}`;
      break;
    case 'stumped':
      description = `st ${fielderName} b ${bowlerName}`;
      break;
    case 'run_out':
      description = `run out (${fielderName || 'direct hit'})`;
      break;
    case 'hit_wicket':
      description = `hit wicket b ${bowlerName}`;
      break;
    default:
      description = dismissalTypeName;
  }

  return {
    type: 'wicket',
    matchId,
    data: {
      dismissedPlayer: dismissedPlayerName,
      dismissalType: dismissalTypeName,
      fielder: fielderName,
      bowler: bowlerName,
      description,
      teamScore,
      overs,
    },
  };
}

// ============================================================
// Build Innings Complete Message
// ============================================================

export function buildInningsCompleteMessage(
  matchId: string,
  inn: typeof innings.$inferSelect,
  battingTeamName: string,
): InningsCompleteMessage {
  return {
    type: 'innings_complete',
    matchId,
    data: {
      inningsNumber: inn.inningsNumber,
      battingTeam: battingTeamName,
      totalRuns: inn.totalRuns,
      totalWickets: inn.totalWickets,
      overs: String(inn.totalOvers),
      target: inn.totalRuns + 1,
    },
  };
}

// ============================================================
// Build Match Complete Message
// ============================================================

export function buildMatchCompleteMessage(
  matchId: string,
  result: typeof matchResult.$inferSelect,
  winnerTeamName: string | null,
): MatchCompleteMessage {
  return {
    type: 'match_complete',
    matchId,
    data: {
      winner: winnerTeamName,
      resultType: result.resultType,
      margin: result.margin,
      summary: result.summary ?? '',
    },
  };
}

// ============================================================
// Build Delivery Undone Message
// ============================================================

export function buildDeliveryUndoneMessage(
  matchId: string,
  removedDeliveryId: string,
  updatedInnings: typeof innings.$inferSelect,
  batterStat: { playerId: string; runs: number; balls: number; fours: number; sixes: number } | null,
  bowlerStat: { playerId: string; overs: string; runs: number; wickets: number; maidens: number } | null,
  currentOver: OverBallDisplay[],
): DeliveryUndoneMessage {
  return {
    type: 'delivery_undone',
    matchId,
    data: {
      inningsId: updatedInnings.id,
      removedDeliveryId,
      updatedScore: {
        runs: updatedInnings.totalRuns,
        wickets: updatedInnings.totalWickets,
        overs: String(updatedInnings.totalOvers),
      },
      updatedBatterStats: batterStat ? {
        strikerId: batterStat.playerId,
        strikerRuns: batterStat.runs,
        strikerBalls: batterStat.balls,
        strikerFours: batterStat.fours,
        strikerSixes: batterStat.sixes,
      } : null,
      updatedBowlerStats: bowlerStat ? {
        bowlerId: bowlerStat.playerId,
        bowlerOvers: bowlerStat.overs,
        bowlerRuns: bowlerStat.runs,
        bowlerWickets: bowlerStat.wickets,
        bowlerMaidens: bowlerStat.maidens,
      } : null,
      currentOver,
    },
  };
}

// ============================================================
// Helpers
// ============================================================

function deliveryToOverBall(d: typeof deliveries.$inferSelect): OverBallDisplay {
  let display: string;
  if (d.isWicket) {
    display = 'W';
  } else if (d.isWide) {
    display = d.totalRuns > 1 ? `${d.totalRuns}Wd` : 'Wd';
  } else if (d.isNoBall) {
    display = d.totalRuns > 1 ? `${d.totalRuns}Nb` : 'Nb';
  } else if (d.isBoundarySix) {
    display = '6';
  } else if (d.isBoundaryFour) {
    display = '4';
  } else if (d.isBye) {
    display = d.byeRuns > 0 ? `${d.byeRuns}B` : 'B';
  } else if (d.isLegBye) {
    display = d.legByeRuns > 0 ? `${d.legByeRuns}Lb` : 'Lb';
  } else if (d.totalRuns === 0) {
    display = '.';
  } else {
    display = String(d.runsFromBat);
  }

  return {
    runs: d.totalRuns,
    display,
    ...(d.isWicket ? { isWicket: true } : {}),
  };
}

function formatDeliveryDescription(d: typeof deliveries.$inferSelect): string {
  const parts: string[] = [];
  if (d.isWicket) parts.push('WICKET!');
  if (d.isBoundarySix) parts.push('SIX!');
  else if (d.isBoundaryFour) parts.push('FOUR!');
  if (d.isWide) parts.push('Wide');
  if (d.isNoBall) parts.push('No ball');
  if (d.isBye) parts.push(`${d.byeRuns} bye${d.byeRuns !== 1 ? 's' : ''}`);
  if (d.isLegBye) parts.push(`${d.legByeRuns} leg bye${d.legByeRuns !== 1 ? 's' : ''}`);
  if (parts.length === 0) {
    if (d.runsFromBat === 0) return 'Dot ball';
    return `${d.runsFromBat} run${d.runsFromBat !== 1 ? 's' : ''}`;
  }
  return parts.join(', ');
}
