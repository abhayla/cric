// Chart data classes for Manhattan, Worm, and Run Rate charts.
// Pure Dart value types computed client-side from InningsData.

/// Runs scored in a single over — used by Manhattan chart.
class OverStats {
  const OverStats({
    required this.overNumber,
    required this.runs,
    required this.hasWicket,
  });

  /// 1-based over number.
  final int overNumber;

  /// Total runs scored in this over.
  final int runs;

  /// Whether any wicket fell in this over.
  final bool hasWicket;
}

/// A point on the Worm (cumulative runs) chart.
class WormDataPoint {
  const WormDataPoint({
    required this.overNumber,
    required this.cumulativeRuns,
  });

  /// 0 = start (before first over), 1-N = after each over.
  final int overNumber;

  /// Cumulative runs at the end of this over.
  final int cumulativeRuns;
}

/// A point on the Run Rate per over chart.
class RunRateDataPoint {
  const RunRateDataPoint({
    required this.overNumber,
    required this.runRate,
  });

  /// 1-based over number.
  final int overNumber;

  /// Runs scored in this over (as double for chart axis).
  final double runRate;
}

/// Chart data for a single innings.
class InningsChartData {
  const InningsChartData({
    required this.teamName,
    required this.scoreDisplay,
    required this.manhattan,
    required this.worm,
    required this.runRate,
  });

  final String teamName;

  /// Score display, e.g. "187/6".
  final String scoreDisplay;

  final List<OverStats> manhattan;
  final List<WormDataPoint> worm;
  final List<RunRateDataPoint> runRate;
}

/// Chart data for both innings in a match.
class MatchChartData {
  const MatchChartData({
    required this.firstInnings,
    required this.secondInnings,
    required this.totalOvers,
  });

  final InningsChartData firstInnings;
  final InningsChartData secondInnings;

  /// Total overs configured for the match.
  final int totalOvers;
}
