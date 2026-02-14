import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/analytics/domain/entities/chart_data.dart';

void main() {
  group('OverStats', () {
    test('stores over number, runs, and wicket flag', () {
      const over = OverStats(overNumber: 1, runs: 12, hasWicket: true);
      expect(over.overNumber, 1);
      expect(over.runs, 12);
      expect(over.hasWicket, true);
    });

    test('wicket-free over', () {
      const over = OverStats(overNumber: 5, runs: 6, hasWicket: false);
      expect(over.hasWicket, false);
    });
  });

  group('WormDataPoint', () {
    test('stores over number and cumulative runs', () {
      const point = WormDataPoint(overNumber: 0, cumulativeRuns: 0);
      expect(point.overNumber, 0);
      expect(point.cumulativeRuns, 0);
    });

    test('non-zero cumulative runs', () {
      const point = WormDataPoint(overNumber: 10, cumulativeRuns: 85);
      expect(point.overNumber, 10);
      expect(point.cumulativeRuns, 85);
    });
  });

  group('RunRateDataPoint', () {
    test('stores over number and run rate', () {
      const point = RunRateDataPoint(overNumber: 1, runRate: 8.0);
      expect(point.overNumber, 1);
      expect(point.runRate, 8.0);
    });

    test('zero run rate for maiden over', () {
      const point = RunRateDataPoint(overNumber: 3, runRate: 0.0);
      expect(point.runRate, 0.0);
    });
  });

  group('InningsChartData', () {
    test('stores all chart data for one innings', () {
      final data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '187/6',
        manhattan: const [
          OverStats(overNumber: 1, runs: 8, hasWicket: false),
          OverStats(overNumber: 2, runs: 12, hasWicket: true),
        ],
        worm: const [
          WormDataPoint(overNumber: 0, cumulativeRuns: 0),
          WormDataPoint(overNumber: 1, cumulativeRuns: 8),
          WormDataPoint(overNumber: 2, cumulativeRuns: 20),
        ],
        runRate: const [
          RunRateDataPoint(overNumber: 1, runRate: 8.0),
          RunRateDataPoint(overNumber: 2, runRate: 12.0),
        ],
      );

      expect(data.teamName, 'Team A');
      expect(data.scoreDisplay, '187/6');
      expect(data.manhattan.length, 2);
      expect(data.worm.length, 3);
      expect(data.runRate.length, 2);
    });
  });

  group('MatchChartData', () {
    test('stores both innings and total overs', () {
      const first = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '150/5',
        manhattan: [],
        worm: [],
        runRate: [],
      );
      const second = InningsChartData(
        teamName: 'Team B',
        scoreDisplay: '120/8',
        manhattan: [],
        worm: [],
        runRate: [],
      );

      const match = MatchChartData(
        firstInnings: first,
        secondInnings: second,
        totalOvers: 20,
      );

      expect(match.firstInnings.teamName, 'Team A');
      expect(match.secondInnings.teamName, 'Team B');
      expect(match.totalOvers, 20);
    });
  });
}
