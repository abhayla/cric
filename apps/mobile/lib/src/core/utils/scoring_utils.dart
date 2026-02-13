import '../../features/scoring/domain/entities/delivery.dart';

/// Pure scoring utility functions.
///
/// Independently testable functions for strike rotation, maiden detection,
/// innings completion, free hit logic, and validation.
abstract final class ScoringUtils {
  /// Whether a delivery is legal (counts toward over completion).
  ///
  /// A delivery is legal if it's not a wide, not a no-ball, and not a penalty.
  static bool isLegalDelivery({
    required bool isWide,
    required bool isNoBall,
    bool isPenalty = false,
  }) {
    return !isWide && !isNoBall && !isPenalty;
  }

  /// Calculates total runs scored from a delivery.
  static int calculateTotalRuns({
    int runsFromBat = 0,
    int wideRuns = 0,
    int noBallRuns = 0,
    int byeRuns = 0,
    int legByeRuns = 0,
  }) {
    return runsFromBat + wideRuns + noBallRuns + byeRuns + legByeRuns;
  }

  /// Determines if strike should swap after a delivery.
  ///
  /// Strike swaps on odd runs movement. The "runs movement" is:
  /// - For normal/no-ball deliveries: runsFromBat
  /// - For wides: wideRuns (includes base penalty)
  /// - For byes: byeRuns
  /// - For leg-byes: legByeRuns
  static bool shouldSwapStrike({
    required int runsFromBat,
    required bool isWide,
    int wideRuns = 0,
    required bool isBye,
    int byeRuns = 0,
    required bool isLegBye,
    int legByeRuns = 0,
  }) {
    int runsForStrike;
    if (isWide) {
      // Wide: runs movement = total wide runs (base + additional)
      runsForStrike = wideRuns;
    } else if (isBye) {
      runsForStrike = byeRuns;
    } else if (isLegBye) {
      runsForStrike = legByeRuns;
    } else {
      runsForStrike = runsFromBat;
    }
    return runsForStrike.isOdd;
  }

  /// Whether an over is complete (6 legal balls bowled).
  static bool isOverComplete(int legalBallsInOver) {
    return legalBallsInOver >= 6;
  }

  /// Checks if the innings is complete and returns the reason (or null).
  ///
  /// Returns the [InningsCompletionReason] if innings should end,
  /// or null if innings continues.
  static InningsCompletionReason? checkInningsCompletion({
    required int totalWickets,
    required int playersPerSide,
    required int totalBalls,
    required int totalOvers,
    required int totalRuns,
    required int? target,
    required int inningsNumber,
  }) {
    // All out: players_per_side - 1 wickets
    if (totalWickets >= playersPerSide - 1) {
      return InningsCompletionReason.allOut;
    }

    // Overs exhausted
    if (totalBalls >= totalOvers * 6) {
      return InningsCompletionReason.oversExhausted;
    }

    // Target chased (2nd innings only)
    if (target != null && inningsNumber >= 2 && totalRuns >= target) {
      return InningsCompletionReason.targetChased;
    }

    return null;
  }

  /// Whether an over is a maiden.
  ///
  /// A maiden over has zero runs from bat AND zero wides AND zero no-balls
  /// across all deliveries. Byes and leg-byes do NOT break a maiden.
  static bool isMaidenOver(List<Delivery> overDeliveries) {
    if (overDeliveries.isEmpty) return false;

    for (final d in overDeliveries) {
      if (d.runsFromBat > 0) return false;
      if (d.isWide) return false;
      if (d.isNoBall) return false;
    }
    return true;
  }

  /// Determines if the next delivery should be a free hit.
  ///
  /// Free hit rules:
  /// - Triggered by a no-ball
  /// - Persists through wides (wide on free hit → next is still free hit)
  /// - Consumed by a legal delivery
  static bool isNextFreeHit({
    required bool previousWasNoBall,
    required bool previousWasFreeHit,
    required bool previousWasLegal,
  }) {
    // If previous was a no-ball, next is always free hit
    if (previousWasNoBall) return true;

    // If previous was a free hit and was not legal (e.g. wide),
    // free hit persists
    if (previousWasFreeHit && !previousWasLegal) return true;

    return false;
  }

  /// Validates that extras are mutually exclusive where required.
  ///
  /// Wide and bye/leg-bye are mutually exclusive (wide IS an extra type).
  /// Returns null if valid, error message if invalid.
  static String? validateExtras({
    required bool isWide,
    required bool isBye,
    required bool isLegBye,
  }) {
    if (isWide && isBye) return 'Wide and bye are mutually exclusive';
    if (isWide && isLegBye) return 'Wide and leg-bye are mutually exclusive';
    if (isBye && isLegBye) return 'Bye and leg-bye are mutually exclusive';
    return null;
  }

  /// Validates that striker and non-striker are different players.
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateBatterPair({
    required String strikerId,
    required String nonStrikerId,
  }) {
    if (strikerId == nonStrikerId) {
      return 'Striker and non-striker must be different players';
    }
    return null;
  }
}
