import '../../features/scoring/domain/entities/delivery.dart';

/// Generates ball-by-ball commentary text from delivery data.
///
/// Pure utility — no dependencies beyond the Delivery entity.
String generateCommentary(Delivery delivery, {String? strikerName, String? bowlerName}) {
  final batter = strikerName ?? 'Batter';
  final bowler = bowlerName ?? 'Bowler';
  final over = '${delivery.overNumber}.${delivery.ballNumber}';

  if (delivery.isWicket) {
    return _wicketCommentary(delivery, batter, bowler, over);
  }

  if (delivery.isWide) {
    final extra = delivery.wideRuns - 1;
    if (extra > 0) {
      return '$over $bowler to $batter, wide, $extra extra ${_runsWord(extra)}';
    }
    return '$over $bowler to $batter, wide';
  }

  if (delivery.isNoBall) {
    final batRuns = delivery.runsFromBat;
    if (batRuns > 0) {
      return '$over $bowler to $batter, no ball, $batRuns ${_runsWord(batRuns)} scored';
    }
    return '$over $bowler to $batter, no ball';
  }

  if (delivery.isBye) {
    return '$over $bowler to $batter, ${delivery.byeRuns} ${_byeWord(delivery.byeRuns)}';
  }

  if (delivery.isLegBye) {
    return '$over $bowler to $batter, ${delivery.legByeRuns} leg ${_byeWord(delivery.legByeRuns)}';
  }

  if (delivery.isBoundarySix) {
    return '$over $bowler to $batter, SIX!';
  }

  if (delivery.isBoundaryFour) {
    return '$over $bowler to $batter, FOUR!';
  }

  if (delivery.runsFromBat == 0) {
    return '$over $bowler to $batter, no run';
  }

  return '$over $bowler to $batter, ${delivery.runsFromBat} ${_runsWord(delivery.runsFromBat)}';
}

String _wicketCommentary(Delivery delivery, String batter, String bowler, String over) {
  final wicket = delivery.wicketInfo;
  if (wicket == null) {
    return '$over $bowler to $batter, OUT!';
  }

  switch (wicket.dismissalType) {
    case DismissalType.bowled:
      return '$over $bowler to $batter, OUT! Bowled!';
    case DismissalType.caught:
      return '$over $bowler to $batter, OUT! Caught!';
    case DismissalType.caughtAndBowled:
      return '$over $bowler to $batter, OUT! Caught & Bowled!';
    case DismissalType.lbw:
      return '$over $bowler to $batter, OUT! LBW!';
    case DismissalType.runOut:
      return '$over $bowler to $batter, OUT! Run Out!';
    case DismissalType.stumped:
      return '$over $bowler to $batter, OUT! Stumped!';
    case DismissalType.hitWicket:
      return '$over $bowler to $batter, OUT! Hit Wicket!';
    case DismissalType.retiredHurt:
      return '$over $batter retired hurt';
    case DismissalType.retiredOut:
      return '$over $batter retired out';
    case DismissalType.timedOut:
      return '$over $batter timed out';
    case DismissalType.obstructingField:
      return '$over $bowler to $batter, OUT! Obstructing the field!';
  }
}

String _runsWord(int runs) => runs == 1 ? 'run' : 'runs';

String _byeWord(int runs) => runs == 1 ? 'bye' : 'byes';
