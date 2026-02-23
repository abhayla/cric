import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/analytics/domain/entities/chart_data.dart';
import 'package:cricscores/src/features/analytics/presentation/widgets/run_rate_chart.dart';

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
          child: RunRateChart(data: data),
        ),
      ),
    );
  }

  group('RunRateChart', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));
      expect(find.text('Run Rate Per Over'), findsOneWidget);
    });

    testWidgets('renders LineChart widget', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows legend with team run rate labels', (tester) async {
      await tester.pumpWidget(buildWidget(_createMatchData()));

      expect(find.text('Team A Run Rate'), findsOneWidget);
      expect(find.text('Team B Run Rate'), findsOneWidget);
    });

    testWidgets('handles empty data', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [],
          runRate: [],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [],
          runRate: [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('renders with different innings lengths', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '150/5',
          manhattan: [],
          worm: [],
          runRate: [
            RunRateDataPoint(overNumber: 1, runRate: 8.0),
            RunRateDataPoint(overNumber: 2, runRate: 12.0),
            RunRateDataPoint(overNumber: 3, runRate: 5.0),
            RunRateDataPoint(overNumber: 4, runRate: 10.0),
          ],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '40/10',
          manhattan: [],
          worm: [],
          runRate: [
            RunRateDataPoint(overNumber: 1, runRate: 15.0),
            RunRateDataPoint(overNumber: 2, runRate: 3.0),
          ],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles zero run rate overs', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '10/0',
          manhattan: [],
          worm: [],
          runRate: [
            RunRateDataPoint(overNumber: 1, runRate: 10.0),
            RunRateDataPoint(overNumber: 2, runRate: 0.0),
            RunRateDataPoint(overNumber: 3, runRate: 0.0),
          ],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [],
          runRate: [],
        ),
        totalOvers: 20,
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles high run rate values', (tester) async {
      const data = MatchChartData(
        firstInnings: InningsChartData(
          teamName: 'Team A',
          scoreDisplay: '200/3',
          manhattan: [],
          worm: [],
          runRate: [
            RunRateDataPoint(overNumber: 1, runRate: 24.0),
            RunRateDataPoint(overNumber: 2, runRate: 18.0),
            RunRateDataPoint(overNumber: 3, runRate: 30.0),
          ],
        ),
        secondInnings: InningsChartData(
          teamName: 'Team B',
          scoreDisplay: '0/0',
          manhattan: [],
          worm: [],
          runRate: [],
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
            child: RunRateChart(
              data: _createMatchData(),
              firstInningsColor: Colors.purple,
              secondInningsColor: Colors.teal,
            ),
          ),
        ),
      ));

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
      worm: [],
      runRate: [
        RunRateDataPoint(overNumber: 1, runRate: 8.0),
        RunRateDataPoint(overNumber: 2, runRate: 12.0),
        RunRateDataPoint(overNumber: 3, runRate: 5.0),
      ],
    ),
    secondInnings: InningsChartData(
      teamName: 'Team B',
      scoreDisplay: '120/8',
      manhattan: [],
      worm: [],
      runRate: [
        RunRateDataPoint(overNumber: 1, runRate: 10.0),
        RunRateDataPoint(overNumber: 2, runRate: 6.0),
      ],
    ),
    totalOvers: 20,
  );
}
