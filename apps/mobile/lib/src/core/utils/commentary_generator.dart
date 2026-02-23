import '../../features/scoring/domain/entities/delivery.dart';

/// Generates ball-by-ball commentary text from delivery data.
///
/// Pure utility — no dependencies beyond the Delivery entity.
/// When [magicOverMultiplier] is provided and > 1, augments commentary
/// with magic over effects (multiplied runs, wicket penalty).
String generateCommentary(
  Delivery delivery, {
  String? strikerName,
  String? bowlerName,
  int? magicOverMultiplier,
}) {
  final batter = strikerName ?? 'Batter';
  final bowler = bowlerName ?? 'Bowler';
  final over = '${delivery.overNumber}.${delivery.ballNumber}';
  final isMagic = delivery.isMagicOverDelivery &&
      magicOverMultiplier != null &&
      magicOverMultiplier > 1;

  if (delivery.isWicket) {
    final base = _wicketCommentary(delivery, batter, bowler, over);
    if (isMagic && delivery.magicOverPenaltyApplied != 0) {
      return 'MAGIC OVER! $base ${delivery.magicOverPenaltyApplied} penalty runs applied';
    }
    return isMagic ? 'MAGIC OVER! $base' : base;
  }

  if (delivery.isWide) {
    final extra = delivery.wideRuns - 1;
    String base;
    if (extra > 0) {
      base = '$over $bowler to $batter, wide, $extra extra ${_runsWord(extra)}';
    } else {
      base = '$over $bowler to $batter, wide';
    }
    if (isMagic && delivery.totalRuns > 0) {
      final original = delivery.totalRuns ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.totalRuns} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.isNoBall) {
    final batRuns = delivery.runsFromBat;
    String base;
    if (batRuns > 0) {
      base = '$over $bowler to $batter, no ball, $batRuns ${_runsWord(batRuns)} scored';
    } else {
      base = '$over $bowler to $batter, no ball';
    }
    if (isMagic && delivery.totalRuns > 0) {
      final original = delivery.totalRuns ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.totalRuns} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.isBye) {
    final base = '$over $bowler to $batter, ${delivery.byeRuns} ${_byeWord(delivery.byeRuns)}';
    if (isMagic && delivery.totalRuns > 0) {
      final original = delivery.totalRuns ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.totalRuns} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.isLegBye) {
    final base = '$over $bowler to $batter, ${delivery.legByeRuns} leg ${_byeWord(delivery.legByeRuns)}';
    if (isMagic && delivery.totalRuns > 0) {
      final original = delivery.totalRuns ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.totalRuns} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.isBoundarySix) {
    final base = '$over $bowler to $batter, SIX!';
    if (isMagic) {
      final original = delivery.runsFromBat ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.runsFromBat} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.isBoundaryFour) {
    final base = '$over $bowler to $batter, FOUR!';
    if (isMagic) {
      final original = delivery.runsFromBat ~/ magicOverMultiplier;
      return 'MAGIC OVER! $base ($original -> ${delivery.runsFromBat} awarded, ${magicOverMultiplier}x)';
    }
    return base;
  }

  if (delivery.runsFromBat == 0) {
    return isMagic
        ? 'MAGIC OVER! $over $bowler to $batter, no run'
        : '$over $bowler to $batter, no run';
  }

  final base = '$over $bowler to $batter, ${delivery.runsFromBat} ${_runsWord(delivery.runsFromBat)}';
  if (isMagic) {
    final original = delivery.runsFromBat ~/ magicOverMultiplier;
    return 'MAGIC OVER! $base ($original -> ${delivery.runsFromBat} awarded, ${magicOverMultiplier}x)';
  }
  return base;
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
