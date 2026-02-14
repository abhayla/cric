import '../../features/analytics/domain/entities/chart_data.dart';
import '../../features/scoring/domain/entities/delivery.dart';
import '../../features/scoring/domain/entities/innings_data.dart';
import '../../features/scoring/domain/entities/scorecard_data.dart';

/// Compute Manhattan chart data: runs per over grouped from deliveries.
///
/// Returns one [OverStats] per over (1-based). Partial last overs are included.
List<OverStats> computeManhattan(List<Delivery> deliveries) {
  if (deliveries.isEmpty) return [];

  // Group deliveries by overNumber (0-based in Delivery)
  final overMap = <int, _OverAccumulator>{};

  for (final d in deliveries) {
    final acc = overMap.putIfAbsent(d.overNumber, _OverAccumulator.new);
    acc.runs += d.totalRuns;
    if (d.isWicket) acc.hasWicket = true;
  }

  // Sort by over number and convert to 1-based
  final sortedOvers = overMap.keys.toList()..sort();
  return sortedOvers.map((overNum) {
    final acc = overMap[overNum]!;
    return OverStats(
      overNumber: overNum + 1, // Convert to 1-based
      runs: acc.runs,
      hasWicket: acc.hasWicket,
    );
  }).toList();
}

/// Compute Worm chart data: cumulative runs after each over.
///
/// Always starts with (0, 0) representing the start of innings.
List<WormDataPoint> computeWorm(List<OverStats> manhattan) {
  final points = <WormDataPoint>[
    const WormDataPoint(overNumber: 0, cumulativeRuns: 0),
  ];

  int cumulative = 0;
  for (final over in manhattan) {
    cumulative += over.runs;
    points.add(WormDataPoint(
      overNumber: over.overNumber,
      cumulativeRuns: cumulative,
    ));
  }

  return points;
}

/// Compute Run Rate chart data: runs scored per over.
List<RunRateDataPoint> computeRunRate(List<OverStats> manhattan) {
  return manhattan
      .map((over) => RunRateDataPoint(
            overNumber: over.overNumber,
            runRate: over.runs.toDouble(),
          ))
      .toList();
}

/// Compute all chart data for a single innings.
InningsChartData computeInningsChartData(InningsData innings) {
  final manhattan = computeManhattan(innings.deliveryHistory);
  final worm = computeWorm(manhattan);
  final runRate = computeRunRate(manhattan);

  return InningsChartData(
    teamName: innings.teamName,
    scoreDisplay: innings.scoreDisplay,
    manhattan: manhattan,
    worm: worm,
    runRate: runRate,
  );
}

/// Compute chart data for both innings in a match.
MatchChartData computeMatchChartData(ScorecardData data) {
  return MatchChartData(
    firstInnings: computeInningsChartData(data.firstInnings),
    secondInnings: computeInningsChartData(data.secondInnings),
    totalOvers: data.totalOvers,
  );
}

/// Internal accumulator for grouping deliveries by over.
class _OverAccumulator {
  int runs = 0;
  bool hasWicket = false;
}
