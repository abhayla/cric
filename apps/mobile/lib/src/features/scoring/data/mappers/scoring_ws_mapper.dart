import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../domain/entities/delivery.dart';
import '../../presentation/notifiers/scoring_notifier.dart';

/// Pure functions mapping [ScoringState] to WebSocket JSON payloads
/// for the fast-path scorer broadcast.

/// Build a `score_update` payload from the current scoring state.
Map<String, dynamic> buildScoreUpdatePayload(ScoringState state) {
  final lastDelivery = state.lastDelivery;
  return {
    'type': 'score_update',
    'matchId': state.matchId,
    'data': {
      'totalRuns': state.totalRuns,
      'totalWickets': state.totalWickets,
      'overs': state.oversDisplay,
      'currentRunRate': _formatRate(state.runRate),
      'requiredRunRate': state.requiredRunRate != null
          ? _formatRate(state.requiredRunRate!)
          : null,
      if (lastDelivery != null)
        'lastDelivery': _buildLastDeliveryInfo(lastDelivery),
      'striker': state.striker != null
          ? _buildBatterSnapshot(state.striker!)
          : null,
      'nonStriker': state.nonStriker != null
          ? _buildBatterSnapshot(state.nonStriker!)
          : null,
      'bowler': state.currentBowler != null
          ? _buildBowlerSnapshot(state.currentBowler!)
          : null,
      'currentOver': state.currentOverDeliveries
          .map(_deliveryToOverBall)
          .toList(),
      'battingTeamName': state.battingTeamName,
      'bowlingTeamName': state.bowlingTeamName,
      'isFreeHitPending': state.isFreeHitPending,
      'isMagicOver': state.isMagicOver,
      'magicOverMultiplier': state.magicOverRunMultiplier,
      'deliveryCount': state.deliveryHistory.length,
    },
  };
}

/// Build a `wicket` payload when a dismissal occurs.
Map<String, dynamic> buildWicketPayload(
  ScoringState state,
  Delivery delivery, {
  String? fielderName,
}) {
  final wicket = delivery.wicketInfo;
  final dismissedBatter = wicket != null
      ? state.batterStats[wicket.dismissedPlayerId]
      : null;
  final bowler = state.currentBowler ?? state.bowlerStats[delivery.bowlerId];

  return {
    'type': 'wicket',
    'matchId': state.matchId,
    'data': {
      'dismissedPlayer': dismissedBatter?.displayName ?? '',
      'dismissalType': wicket?.dismissalType.label ?? '',
      'fielder': fielderName,
      'bowler': bowler?.displayName,
      'description': _buildDismissalDescription(
        dismissalType: wicket?.dismissalType,
        bowlerName: bowler?.displayName,
        fielderName: fielderName,
      ),
      'teamScore': '${state.totalRuns}/${state.totalWickets}',
      'overs': state.oversDisplay,
    },
  };
}

/// Build an `innings_complete` payload.
Map<String, dynamic> buildInningsCompletePayload(ScoringState state) {
  return {
    'type': 'innings_complete',
    'matchId': state.matchId,
    'data': {
      'inningsNumber': state.inningsNumber,
      'battingTeam': state.battingTeamName,
      'totalRuns': state.totalRuns,
      'totalWickets': state.totalWickets,
      'overs': state.oversDisplay,
      'target': state.totalRuns + 1,
    },
  };
}

/// Build a `match_complete` payload.
Map<String, dynamic> buildMatchCompletePayload(ScoringState state) {
  final result = state.matchResult;
  return {
    'type': 'match_complete',
    'matchId': state.matchId,
    'data': {
      'winner': result?.winnerTeamName,
      'resultType': result?.resultType.name ?? '',
      'margin': result?.margin,
      'summary': result?.resultDescription ?? '',
    },
  };
}

// ── Private helpers ──

Map<String, dynamic> _buildLastDeliveryInfo(Delivery d) {
  return {
    'runs': d.totalRuns,
    'isWide': d.isWide,
    'isNoBall': d.isNoBall,
    'isBye': d.isBye,
    'isLegBye': d.isLegBye,
    'isWicket': d.isWicket,
    'isBoundaryFour': d.isBoundaryFour,
    'isBoundarySix': d.isBoundarySix,
    'description': _formatDeliveryDescription(d),
  };
}

Map<String, dynamic> _buildBatterSnapshot(BatterInnings b) {
  return {
    'id': b.playerId,
    'name': b.displayName,
    'runs': b.runsScored,
    'balls': b.ballsFaced,
    'fours': b.fours,
    'sixes': b.sixes,
    'strikeRate': _formatRate(b.strikeRate),
  };
}

Map<String, dynamic> _buildBowlerSnapshot(BowlerSpell b) {
  return {
    'id': b.playerId,
    'name': b.displayName,
    'overs': b.oversDisplay,
    'maidens': b.maidens,
    'runs': b.runsConceded,
    'wickets': b.wicketsTaken,
    'economy': _formatRate(b.economyRate),
  };
}

Map<String, dynamic> _deliveryToOverBall(Delivery d) {
  return {
    'runs': d.totalRuns,
    'display': d.notation,
    'isWicket': d.isWicket,
  };
}

String _formatDeliveryDescription(Delivery d) {
  if (d.isWicket) return 'WICKET!';
  if (d.isBoundarySix) return 'SIX!';
  if (d.isBoundaryFour) return 'FOUR!';
  if (d.isWide) {
    final extra = d.wideRuns > 1 ? ' + ${d.wideRuns - 1} runs' : '';
    return 'Wide$extra';
  }
  if (d.isNoBall) {
    final runs = d.runsFromBat > 0 ? ' + ${d.runsFromBat} runs' : '';
    return 'No Ball$runs';
  }
  if (d.isBye) return '${d.byeRuns} Bye${d.byeRuns != 1 ? 's' : ''}';
  if (d.isLegBye) return '${d.legByeRuns} Leg Bye${d.legByeRuns != 1 ? 's' : ''}';
  if (d.totalRuns == 0) return 'Dot ball';
  return '${d.runsFromBat} run${d.runsFromBat != 1 ? 's' : ''}';
}

String _buildDismissalDescription({
  DismissalType? dismissalType,
  String? bowlerName,
  String? fielderName,
}) {
  if (dismissalType == null) return 'Wicket';
  switch (dismissalType) {
    case DismissalType.bowled:
      return 'b $bowlerName';
    case DismissalType.caught:
      return 'c $fielderName b $bowlerName';
    case DismissalType.lbw:
      return 'lbw b $bowlerName';
    case DismissalType.runOut:
      return 'run out ($fielderName)';
    case DismissalType.stumped:
      return 'st $fielderName b $bowlerName';
    case DismissalType.hitWicket:
      return 'hit wkt b $bowlerName';
    case DismissalType.caughtAndBowled:
      return 'c & b $bowlerName';
    case DismissalType.retiredHurt:
      return 'retired hurt';
    case DismissalType.retiredOut:
      return 'retired out';
    case DismissalType.timedOut:
      return 'timed out';
    case DismissalType.obstructingField:
      return 'obstructing field';
  }
}

/// Format a double to 2 decimal places (matches server's toFixed(2)).
double _formatRate(double value) {
  return double.parse(value.toStringAsFixed(2));
}
