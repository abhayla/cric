/// Cricket utility functions.
///
/// Strike rotation, over calculation, and display helpers.
abstract final class CricketUtils {
  /// Converts total legal balls to overs decimal notation.
  ///
  /// Example: 13 balls → 2.1 (2 overs, 1 ball).
  static double ballsToOvers(int totalBalls) {
    final completedOvers = totalBalls ~/ 6;
    final remainingBalls = totalBalls % 6;
    return completedOvers + (remainingBalls / 10);
  }

  /// Formats overs as string: "2.1", "20.0".
  static String formatOvers(int totalBalls) {
    final completedOvers = totalBalls ~/ 6;
    final remainingBalls = totalBalls % 6;
    return '$completedOvers.$remainingBalls';
  }

  /// Calculates current run rate.
  static double currentRunRate(int runs, int totalBalls) {
    if (totalBalls == 0) return 0;
    return (runs / totalBalls) * 6;
  }

  /// Calculates required run rate.
  static double requiredRunRate(int runsNeeded, int ballsRemaining) {
    if (ballsRemaining <= 0) return double.infinity;
    return (runsNeeded / ballsRemaining) * 6;
  }

  /// Calculates maximum overs per bowler.
  ///
  /// Formula: ceil(totalOvers / 5).
  static int maxOversPerBowler(int totalOvers) {
    return (totalOvers / 5).ceil();
  }
}
