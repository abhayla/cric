import 'dart:convert';

import '../../../features/scoring/domain/entities/batter_innings.dart';
import '../../../features/scoring/domain/entities/bowler_spell.dart';

// ============================================================
// WebSocket Message Types — mirrors server types/websocket.ts
// ============================================================

// --- Shared sub-types ---

class WsPlayerBattingSnapshot {
  const WsPlayerBattingSnapshot({
    required this.id,
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  final String id;
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;

  factory WsPlayerBattingSnapshot.fromJson(Map<String, dynamic> json) {
    return WsPlayerBattingSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      runs: json['runs'] as int,
      balls: json['balls'] as int,
      fours: json['fours'] as int,
      sixes: json['sixes'] as int,
      strikeRate: (json['strikeRate'] as num).toDouble(),
    );
  }

  BatterInnings toBatterInnings() {
    return BatterInnings(
      playerId: id,
      displayName: name,
      runsScored: runs,
      ballsFaced: balls,
      fours: fours,
      sixes: sixes,
    );
  }
}

class WsPlayerBowlingSnapshot {
  const WsPlayerBowlingSnapshot({
    required this.id,
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String id;
  final String name;
  final String overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;

  factory WsPlayerBowlingSnapshot.fromJson(Map<String, dynamic> json) {
    return WsPlayerBowlingSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      overs: json['overs'] as String,
      maidens: json['maidens'] as int,
      runs: json['runs'] as int,
      wickets: json['wickets'] as int,
      economy: (json['economy'] as num).toDouble(),
    );
  }

  BowlerSpell toBowlerSpell() {
    return BowlerSpell(
      playerId: id,
      displayName: name,
      ballsBowled: parseOversString(overs),
      maidens: maidens,
      runsConceded: runs,
      wicketsTaken: wickets,
    );
  }
}

class WsOverBallDisplay {
  const WsOverBallDisplay({
    required this.runs,
    required this.display,
    this.isWicket = false,
  });

  final int runs;
  final String display;
  final bool isWicket;

  factory WsOverBallDisplay.fromJson(Map<String, dynamic> json) {
    return WsOverBallDisplay(
      runs: json['runs'] as int,
      display: json['display'] as String,
      isWicket: json['isWicket'] as bool? ?? false,
    );
  }
}

class WsLastDeliveryInfo {
  const WsLastDeliveryInfo({
    required this.runs,
    required this.isWide,
    required this.isNoBall,
    required this.isBye,
    required this.isLegBye,
    required this.isWicket,
    required this.isBoundaryFour,
    required this.isBoundarySix,
    required this.description,
  });

  final int runs;
  final bool isWide;
  final bool isNoBall;
  final bool isBye;
  final bool isLegBye;
  final bool isWicket;
  final bool isBoundaryFour;
  final bool isBoundarySix;
  final String description;

  factory WsLastDeliveryInfo.fromJson(Map<String, dynamic> json) {
    return WsLastDeliveryInfo(
      runs: json['runs'] as int,
      isWide: json['isWide'] as bool,
      isNoBall: json['isNoBall'] as bool,
      isBye: json['isBye'] as bool,
      isLegBye: json['isLegBye'] as bool,
      isWicket: json['isWicket'] as bool,
      isBoundaryFour: json['isBoundaryFour'] as bool,
      isBoundarySix: json['isBoundarySix'] as bool,
      description: json['description'] as String,
    );
  }
}

// --- Server → Client Messages (sealed hierarchy) ---

sealed class WsServerMessage {}

class WsMatchStateMessage extends WsServerMessage {
  WsMatchStateMessage({required this.matchId, required this.data});

  final String matchId;
  final WsMatchStateData data;

  factory WsMatchStateMessage.fromJson(Map<String, dynamic> json) {
    return WsMatchStateMessage(
      matchId: json['matchId'] as String,
      data: WsMatchStateData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsMatchStateData {
  const WsMatchStateData({
    required this.status,
    required this.inningsNumber,
    required this.totalRuns,
    required this.totalWickets,
    required this.overs,
    this.currentRunRate,
    this.requiredRunRate,
    this.target,
    this.striker,
    this.nonStriker,
    this.bowler,
    required this.currentOver,
    required this.recentDeliveries,
    this.battingTeamName,
    this.bowlingTeamName,
    this.isFreeHitPending,
    this.isMagicOver,
    this.magicOverMultiplier,
  });

  final String status;
  final int inningsNumber;
  final int totalRuns;
  final int totalWickets;
  final String overs;
  final double? currentRunRate;
  final double? requiredRunRate;
  final int? target;
  final WsPlayerBattingSnapshot? striker;
  final WsPlayerBattingSnapshot? nonStriker;
  final WsPlayerBowlingSnapshot? bowler;
  final List<WsOverBallDisplay> currentOver;
  final List<WsOverBallDisplay> recentDeliveries;
  final String? battingTeamName;
  final String? bowlingTeamName;
  final bool? isFreeHitPending;
  final bool? isMagicOver;
  final int? magicOverMultiplier;

  factory WsMatchStateData.fromJson(Map<String, dynamic> json) {
    return WsMatchStateData(
      status: json['status'] as String,
      inningsNumber: json['inningsNumber'] as int,
      totalRuns: json['totalRuns'] as int,
      totalWickets: json['totalWickets'] as int,
      overs: json['overs'] as String,
      currentRunRate: (json['currentRunRate'] as num?)?.toDouble(),
      requiredRunRate: (json['requiredRunRate'] as num?)?.toDouble(),
      target: json['target'] as int?,
      striker: json['striker'] != null
          ? WsPlayerBattingSnapshot.fromJson(
              json['striker'] as Map<String, dynamic>)
          : null,
      nonStriker: json['nonStriker'] != null
          ? WsPlayerBattingSnapshot.fromJson(
              json['nonStriker'] as Map<String, dynamic>)
          : null,
      bowler: json['bowler'] != null
          ? WsPlayerBowlingSnapshot.fromJson(
              json['bowler'] as Map<String, dynamic>)
          : null,
      currentOver: (json['currentOver'] as List)
          .map((e) => WsOverBallDisplay.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentDeliveries: (json['recentDeliveries'] as List)
          .map((e) => WsOverBallDisplay.fromJson(e as Map<String, dynamic>))
          .toList(),
      battingTeamName: json['battingTeamName'] as String?,
      bowlingTeamName: json['bowlingTeamName'] as String?,
      isFreeHitPending: json['isFreeHitPending'] as bool?,
      isMagicOver: json['isMagicOver'] as bool?,
      magicOverMultiplier: json['magicOverMultiplier'] as int?,
    );
  }
}

class WsScoreUpdateMessage extends WsServerMessage {
  WsScoreUpdateMessage({required this.matchId, required this.data});

  final String matchId;
  final WsScoreUpdateData data;

  factory WsScoreUpdateMessage.fromJson(Map<String, dynamic> json) {
    return WsScoreUpdateMessage(
      matchId: json['matchId'] as String,
      data: WsScoreUpdateData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsScoreUpdateData {
  const WsScoreUpdateData({
    required this.totalRuns,
    required this.totalWickets,
    required this.overs,
    this.currentRunRate,
    this.requiredRunRate,
    required this.lastDelivery,
    this.striker,
    this.nonStriker,
    this.bowler,
    required this.currentOver,
    this.battingTeamName,
    this.bowlingTeamName,
    this.isFreeHitPending,
    this.isMagicOver,
    this.magicOverMultiplier,
  });

  final int totalRuns;
  final int totalWickets;
  final String overs;
  final double? currentRunRate;
  final double? requiredRunRate;
  final WsLastDeliveryInfo lastDelivery;
  final WsPlayerBattingSnapshot? striker;
  final WsPlayerBattingSnapshot? nonStriker;
  final WsPlayerBowlingSnapshot? bowler;
  final List<WsOverBallDisplay> currentOver;
  final String? battingTeamName;
  final String? bowlingTeamName;
  final bool? isFreeHitPending;
  final bool? isMagicOver;
  final int? magicOverMultiplier;

  factory WsScoreUpdateData.fromJson(Map<String, dynamic> json) {
    return WsScoreUpdateData(
      totalRuns: json['totalRuns'] as int,
      totalWickets: json['totalWickets'] as int,
      overs: json['overs'] as String,
      currentRunRate: (json['currentRunRate'] as num?)?.toDouble(),
      requiredRunRate: (json['requiredRunRate'] as num?)?.toDouble(),
      lastDelivery: WsLastDeliveryInfo.fromJson(
          json['lastDelivery'] as Map<String, dynamic>),
      striker: json['striker'] != null
          ? WsPlayerBattingSnapshot.fromJson(
              json['striker'] as Map<String, dynamic>)
          : null,
      nonStriker: json['nonStriker'] != null
          ? WsPlayerBattingSnapshot.fromJson(
              json['nonStriker'] as Map<String, dynamic>)
          : null,
      bowler: json['bowler'] != null
          ? WsPlayerBowlingSnapshot.fromJson(
              json['bowler'] as Map<String, dynamic>)
          : null,
      currentOver: (json['currentOver'] as List)
          .map((e) => WsOverBallDisplay.fromJson(e as Map<String, dynamic>))
          .toList(),
      battingTeamName: json['battingTeamName'] as String?,
      bowlingTeamName: json['bowlingTeamName'] as String?,
      isFreeHitPending: json['isFreeHitPending'] as bool?,
      isMagicOver: json['isMagicOver'] as bool?,
      magicOverMultiplier: json['magicOverMultiplier'] as int?,
    );
  }
}

class WsWicketMessage extends WsServerMessage {
  WsWicketMessage({required this.matchId, required this.data});

  final String matchId;
  final WsWicketData data;

  factory WsWicketMessage.fromJson(Map<String, dynamic> json) {
    return WsWicketMessage(
      matchId: json['matchId'] as String,
      data: WsWicketData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsWicketData {
  const WsWicketData({
    required this.dismissedPlayer,
    required this.dismissalType,
    this.fielder,
    this.bowler,
    required this.description,
    required this.teamScore,
    required this.overs,
  });

  final String dismissedPlayer;
  final String dismissalType;
  final String? fielder;
  final String? bowler;
  final String description;
  final String teamScore;
  final String overs;

  factory WsWicketData.fromJson(Map<String, dynamic> json) {
    return WsWicketData(
      dismissedPlayer: json['dismissedPlayer'] as String,
      dismissalType: json['dismissalType'] as String,
      fielder: json['fielder'] as String?,
      bowler: json['bowler'] as String?,
      description: json['description'] as String,
      teamScore: json['teamScore'] as String,
      overs: json['overs'] as String,
    );
  }
}

class WsInningsCompleteMessage extends WsServerMessage {
  WsInningsCompleteMessage({required this.matchId, required this.data});

  final String matchId;
  final WsInningsCompleteData data;

  factory WsInningsCompleteMessage.fromJson(Map<String, dynamic> json) {
    return WsInningsCompleteMessage(
      matchId: json['matchId'] as String,
      data:
          WsInningsCompleteData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsInningsCompleteData {
  const WsInningsCompleteData({
    required this.inningsNumber,
    required this.battingTeam,
    required this.totalRuns,
    required this.totalWickets,
    required this.overs,
    required this.target,
  });

  final int inningsNumber;
  final String battingTeam;
  final int totalRuns;
  final int totalWickets;
  final String overs;
  final int target;

  factory WsInningsCompleteData.fromJson(Map<String, dynamic> json) {
    return WsInningsCompleteData(
      inningsNumber: json['inningsNumber'] as int,
      battingTeam: json['battingTeam'] as String,
      totalRuns: json['totalRuns'] as int,
      totalWickets: json['totalWickets'] as int,
      overs: json['overs'] as String,
      target: json['target'] as int,
    );
  }
}

class WsMatchCompleteMessage extends WsServerMessage {
  WsMatchCompleteMessage({required this.matchId, required this.data});

  final String matchId;
  final WsMatchCompleteData data;

  factory WsMatchCompleteMessage.fromJson(Map<String, dynamic> json) {
    return WsMatchCompleteMessage(
      matchId: json['matchId'] as String,
      data: WsMatchCompleteData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsMatchCompleteData {
  const WsMatchCompleteData({
    this.winner,
    required this.resultType,
    this.margin,
    required this.summary,
  });

  final String? winner;
  final String resultType;
  final int? margin;
  final String summary;

  factory WsMatchCompleteData.fromJson(Map<String, dynamic> json) {
    return WsMatchCompleteData(
      winner: json['winner'] as String?,
      resultType: json['resultType'] as String,
      margin: json['margin'] as int?,
      summary: json['summary'] as String,
    );
  }
}

class WsDeliveryUndoneMessage extends WsServerMessage {
  WsDeliveryUndoneMessage({required this.matchId, required this.data});

  final String matchId;
  final WsDeliveryUndoneData data;

  factory WsDeliveryUndoneMessage.fromJson(Map<String, dynamic> json) {
    return WsDeliveryUndoneMessage(
      matchId: json['matchId'] as String,
      data:
          WsDeliveryUndoneData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WsDeliveryUndoneData {
  const WsDeliveryUndoneData({
    required this.inningsId,
    required this.removedDeliveryId,
    required this.updatedScore,
    this.updatedBatterStats,
    this.updatedBowlerStats,
    required this.currentOver,
  });

  final String inningsId;
  final String removedDeliveryId;
  final WsUpdatedScore updatedScore;
  final WsUpdatedBatterStats? updatedBatterStats;
  final WsUpdatedBowlerStats? updatedBowlerStats;
  final List<WsOverBallDisplay> currentOver;

  factory WsDeliveryUndoneData.fromJson(Map<String, dynamic> json) {
    return WsDeliveryUndoneData(
      inningsId: json['inningsId'] as String,
      removedDeliveryId: json['removedDeliveryId'] as String,
      updatedScore: WsUpdatedScore.fromJson(
          json['updatedScore'] as Map<String, dynamic>),
      updatedBatterStats: json['updatedBatterStats'] != null
          ? WsUpdatedBatterStats.fromJson(
              json['updatedBatterStats'] as Map<String, dynamic>)
          : null,
      updatedBowlerStats: json['updatedBowlerStats'] != null
          ? WsUpdatedBowlerStats.fromJson(
              json['updatedBowlerStats'] as Map<String, dynamic>)
          : null,
      currentOver: (json['currentOver'] as List)
          .map((e) => WsOverBallDisplay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WsUpdatedScore {
  const WsUpdatedScore({
    required this.runs,
    required this.wickets,
    required this.overs,
  });

  final int runs;
  final int wickets;
  final String overs;

  factory WsUpdatedScore.fromJson(Map<String, dynamic> json) {
    return WsUpdatedScore(
      runs: json['runs'] as int,
      wickets: json['wickets'] as int,
      overs: json['overs'] as String,
    );
  }
}

class WsUpdatedBatterStats {
  const WsUpdatedBatterStats({
    required this.strikerId,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.strikerFours,
    required this.strikerSixes,
  });

  final String strikerId;
  final int strikerRuns;
  final int strikerBalls;
  final int strikerFours;
  final int strikerSixes;

  factory WsUpdatedBatterStats.fromJson(Map<String, dynamic> json) {
    return WsUpdatedBatterStats(
      strikerId: json['strikerId'] as String,
      strikerRuns: json['strikerRuns'] as int,
      strikerBalls: json['strikerBalls'] as int,
      strikerFours: json['strikerFours'] as int,
      strikerSixes: json['strikerSixes'] as int,
    );
  }
}

class WsUpdatedBowlerStats {
  const WsUpdatedBowlerStats({
    required this.bowlerId,
    required this.bowlerOvers,
    required this.bowlerRuns,
    required this.bowlerWickets,
    required this.bowlerMaidens,
  });

  final String bowlerId;
  final String bowlerOvers;
  final int bowlerRuns;
  final int bowlerWickets;
  final int bowlerMaidens;

  factory WsUpdatedBowlerStats.fromJson(Map<String, dynamic> json) {
    return WsUpdatedBowlerStats(
      bowlerId: json['bowlerId'] as String,
      bowlerOvers: json['bowlerOvers'] as String,
      bowlerRuns: json['bowlerRuns'] as int,
      bowlerWickets: json['bowlerWickets'] as int,
      bowlerMaidens: json['bowlerMaidens'] as int,
    );
  }
}

class WsErrorMessage extends WsServerMessage {
  WsErrorMessage({required this.message});

  final String message;

  factory WsErrorMessage.fromJson(Map<String, dynamic> json) {
    return WsErrorMessage(message: json['message'] as String);
  }
}

// --- Parse + dispatch ---

/// Parses a raw WebSocket message string into the appropriate message type.
WsServerMessage parseServerMessage(String raw) {
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return switch (json['type']) {
      'match_state' => WsMatchStateMessage.fromJson(json),
      'score_update' => WsScoreUpdateMessage.fromJson(json),
      'wicket' => WsWicketMessage.fromJson(json),
      'innings_complete' => WsInningsCompleteMessage.fromJson(json),
      'match_complete' => WsMatchCompleteMessage.fromJson(json),
      'delivery_undone' => WsDeliveryUndoneMessage.fromJson(json),
      'error' => WsErrorMessage.fromJson(json),
      _ => WsErrorMessage(
          message: 'Unknown message type: ${json['type']}'),
    };
  } catch (e) {
    if (e is WsErrorMessage) rethrow;
    return WsErrorMessage(message: 'Failed to parse message: $e');
  }
}

// --- Helper ---

/// Parses overs string "4.2" → total balls (26).
/// Inverse of CricketUtils.formatOvers.
int parseOversString(String overs) {
  final parts = overs.split('.');
  final completedOvers = int.parse(parts[0]);
  final balls = parts.length > 1 ? int.parse(parts[1]) : 0;
  return (completedOvers * 6) + balls;
}
