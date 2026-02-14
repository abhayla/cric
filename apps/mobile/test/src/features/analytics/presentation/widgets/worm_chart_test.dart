import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/analytics/domain/entities/chart_data.dart';
import 'package:cricapp/src/features/analytics/presentation/widgets/worm_chart.dart';

void main() {
  Widget buildWidget(MatchChartData data) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: WormChart(data: data),
        ),
      ),
    );
  }

  group('WormChart', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));
      expect(find.text('Cumulative Runs Comparison'), findsOneWidget);
    });

    testWidgets('renders LineChart widget', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows legend with both team names and scores', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));

      expect(find.text('Team A — 150/5'), findsOneWidget);
      expect(find.text('Team B — 120/8'), findsOneWidget);
    });

    testWidgets('handles empty data for both innings', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [WormDataPoint(overNumber: 0, cumulativeRuns: 0)],
          runRate: [],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [WormDataPoint(overNumber: 0, cumulativeRuns: 0)],
          runRate: [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('handles different innings lengths', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '180/4',
          manhattan: [],
          worm: [
            WormDataPoint(overNumber: 0, cumulativeRuns: 0),
            WormDataPoint(overNumber: 1, cumulativeRuns: 10),
            WormDataPoint(overNumber: 2, cumulativeRuns: 25),
            WormDataPoint(overNumber: 3, cumulativeRuns: 40),
            WormDataPoint(overNumber: 4, cumulativeRuns: 55),
            WormDataPoint(overNumber: 5, cumulativeRuns: 80),
          ],
          runRate: [],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '60/10',
          manhattan: [],
          worm: [
            WormDataPoint(overNumber: 0, cumulativeRuns: 0),
            WormDataPoint(overNumber: 1, cumulativeRuns: 8),
            WormDataPoint(overNumber: 2, cumulativeRuns: 30),
            // Shorter — all out after 2 overs
          ],
          runRate: [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with 20 overs of data', (tester) async {
      final worm = <WormDataPoint>[
        const WormDataPoint(overNumber: 0, cumulativeRuns: 0),
        for (int i = 1; i <= 20; i++)
          WormDataPoint(overNumber: i, cumulativeRuns: i * 8),
      ];

      final data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '160/5',
          manhattan: const [],
          worm: worm,
          runRate: const [],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '140/7',
          manhattan: const [],
          worm: worm.map((w) => WormDataPoint(
            overNumber: w.overNumber,
            cumulativeRuns: (w.cumulativeRuns * 0.8).toInt(),
          )).toList(),
          runRate: const [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('uses custom colors when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: WormChart(
              data: _createMatchData(),
              firstInningsColor: Colors.green,
              secondInningsColor: Colors.orange,
            ),
          ),
        ),
      ));

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('second innings only scenario works', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [WormDataPoint(overNumber: 0, cumulativeRuns: 0)],
          runRate: [],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '50/2',
          manhattan: [],
          worm: [
            WormDataPoint(overNumber: 0, cumulativeRuns: 0),
            WormDataPoint(overNumber: 1, cumulativeRuns: 15),
            WormDataPoint(overNumber: 2, cumulativeRuns: 50),
          ],
          runRate: [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}

MatchChartData _createMatchData() {
  return const MatchChartData(
    firstInnings: InningsChartData(
      teamName: 'Team A',
      scoreDisplay: '150/5',
      manhattan: [],
      worm: [
        WormDataPoint(overNumber: 0, cumulativeRuns: 0),
        WormDataPoint(overNumber: 1, cumulativeRuns: 8),
        WormDataPoint(overNumber: 2, cumulativeRuns: 20),
        WormDataPoint(overNumber: 3, cumulativeRuns: 35),
      ],
      runRate: [],
    ),
    secondInnings: InningsChartData(
      teamName: 'Team B',
      scoreDisplay: '120/8',
      manhattan: [],
      worm: [
        WormDataPoint(overNumber: 0, cumulativeRuns: 0),
        WormDataPoint(overNumber: 1, cumulativeRuns: 10),
        WormDataPoint(overNumber: 2, cumulativeRuns: 18),
      ],
      runRate: [],
    ),
    totalOvers: 20,
  );
}
