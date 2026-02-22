// ============================================================
// WebSocket Message Types — Client ↔ Server
// ============================================================

// --- Shared sub-types ---

export interface PlayerBattingSnapshot {
  id: string;
  name: string;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  strikeRate: number;
}

export interface PlayerBowlingSnapshot {
  id: string;
  name: string;
  overs: string;
  maidens: number;
  runs: number;
  wickets: number;
  economy: number;
}

export interface OverBallDisplay {
  runs: number;
  display: string;
  isWicket?: boolean;
}

export interface LastDeliveryInfo {
  runs: number;
  isWide: boolean;
  isNoBall: boolean;
  isBye: boolean;
  isLegBye: boolean;
  isWicket: boolean;
  isBoundaryFour: boolean;
  isBoundarySix: boolean;
  description: string;
}

// --- Client → Server Messages ---

export interface JoinMatchMessage {
  type: 'join_match';
  matchId: string;
}

export interface LeaveMatchMessage {
  type: 'leave_match';
  matchId: string;
}

export interface PublishScoreMessage {
  type: 'publish_score';
  matchId: string;
  payload: object;
}

export interface PingMessage {
  type: 'ping';
}

export type ClientMessage = JoinMatchMessage | LeaveMatchMessage | PublishScoreMessage | PingMessage;

// --- Server → Client Messages ---

export interface MatchStateMessage {
  type: 'match_state';
  matchId: string;
  data: {
    status: string;
    inningsNumber: number;
    totalRuns: number;
    totalWickets: number;
    overs: string;
    currentRunRate: number | null;
    requiredRunRate: number | null;
    target: number | null;
    striker: PlayerBattingSnapshot | null;
    nonStriker: PlayerBattingSnapshot | null;
    bowler: PlayerBowlingSnapshot | null;
    currentOver: OverBallDisplay[];
    recentDeliveries: OverBallDisplay[];
    battingTeamName?: string;
    bowlingTeamName?: string;
    isFreeHitPending?: boolean;
    isMagicOver?: boolean;
    magicOverMultiplier?: number;
    deliveryCount?: number;
  };
}

export interface ScoreUpdateMessage {
  type: 'score_update';
  matchId: string;
  data: {
    totalRuns: number;
    totalWickets: number;
    overs: string;
    currentRunRate: number | null;
    requiredRunRate: number | null;
    lastDelivery: LastDeliveryInfo;
    striker: PlayerBattingSnapshot | null;
    nonStriker: PlayerBattingSnapshot | null;
    bowler: PlayerBowlingSnapshot | null;
    currentOver: OverBallDisplay[];
    battingTeamName?: string;
    bowlingTeamName?: string;
    isFreeHitPending?: boolean;
    isMagicOver?: boolean;
    magicOverMultiplier?: number;
    deliveryCount?: number;
  };
}

export interface WicketMessage {
  type: 'wicket';
  matchId: string;
  data: {
    dismissedPlayer: string;
    dismissalType: string;
    fielder: string | null;
    bowler: string | null;
    description: string;
    teamScore: string;
    overs: string;
  };
}

export interface InningsCompleteMessage {
  type: 'innings_complete';
  matchId: string;
  data: {
    inningsNumber: number;
    battingTeam: string;
    totalRuns: number;
    totalWickets: number;
    overs: string;
    target: number;
  };
}

export interface MatchCompleteMessage {
  type: 'match_complete';
  matchId: string;
  data: {
    winner: string | null;
    resultType: string;
    margin: number | null;
    summary: string;
  };
}

export interface DeliveryUndoneMessage {
  type: 'delivery_undone';
  matchId: string;
  data: {
    inningsId: string;
    removedDeliveryId: string;
    updatedScore: {
      runs: number;
      wickets: number;
      overs: string;
    };
    updatedBatterStats: {
      strikerId: string;
      strikerRuns: number;
      strikerBalls: number;
      strikerFours: number;
      strikerSixes: number;
    } | null;
    updatedBowlerStats: {
      bowlerId: string;
      bowlerOvers: string;
      bowlerRuns: number;
      bowlerWickets: number;
      bowlerMaidens: number;
    } | null;
    currentOver: OverBallDisplay[];
  };
}

export interface ErrorMessage {
  type: 'error';
  message: string;
}

export type ServerMessage =
  | MatchStateMessage
  | ScoreUpdateMessage
  | WicketMessage
  | InningsCompleteMessage
  | MatchCompleteMessage
  | DeliveryUndoneMessage
  | ErrorMessage;
