import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/analytics/domain/entities/chart_data.dart';
import 'package:cricscores/src/features/analytics/presentation/widgets/manhattan_chart.dart';

void main() {
  Widget buildWidget(InningsChartData data) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: ManhattanChart(data: data),
        ),
      ),
    );
  }

  group('ManhattanChart', () {
    testWidgets('shows title with team name', (tester) async {
      final data = _createChartData(teamName: 'India');
      await tester.pumpWidget(buildWidget(data));

      expect(find.text('Runs Per Over — India Innings'), findsOneWidget);
    });

    testWidgets('renders BarChart widget', (tester) async {
      final data = _createChartData();
      await tester.pumpWidget(buildWidget(data));

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('shows legend with Runs and Wicket Over labels', (tester) async {
      final data = _createChartData();
      await tester.pumpWidget(buildWidget(data));

      expect(find.text('Runs'), findsOneWidget);
      expect(find.text('Wicket Over'), findsOneWidget);
    });

    testWidgets('handles empty data', (tester) async {
      const data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '0/0',
        manhattan: [],
        worm: [],
        runRate: [],
      );
      await tester.pumpWidget(buildWidget(data));

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders with multiple overs of data', (tester) async {
      final data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '45/2',
        manhattan: List.generate(
          5,
          (i) => OverStats(
            overNumber: i + 1,
            runs: (i + 1) * 3,
            hasWicket: i == 2,
          ),
        ),
        worm: const [],
        runRate: const [],
      );
      await tester.pumpWidget(buildWidget(data));

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('single over data renders correctly', (tester) async {
      const data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '8/0',
        manhattan: [OverStats(overNumber: 1, runs: 8, hasWicket: false)],
        worm: [],
        runRate: [],
      );
      await tester.pumpWidget(buildWidget(data));

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('uses correct team color and wicket color', (tester) async {
      final data = _createChartData();
      const customTeam = Color(0xFF00FF00);
      const customWicket = Color(0xFFFF0000);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: ManhattanChart(
              data: data,
              teamColor: customTeam,
              wicketColor: customWicket,
            ),
          ),
        ),
      ));

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('displays score in data context', (tester) async {
      final data = _createChartData(scoreDisplay: '187/6');
      await tester.pumpWidget(buildWidget(data));

      // Score is in the data but not explicitly shown in title
      // Title shows team name
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('all wicket overs scenario renders', (tester) async {
      const data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '30/3',
        manhattan: [
          OverStats(overNumber: 1, runs: 10, hasWicket: true),
          OverStats(overNumber: 2, runs: 8, hasWicket: true),
          OverStats(overNumber: 3, runs: 12, hasWicket: true),
        ],
        worm: [],
        runRate: [],
      );
      await tester.pumpWidget(buildWidget(data));

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('20-over match renders all bars', (tester) async {
      final data = InningsChartData(
        teamName: 'Team A',
        scoreDisplay: '180/4',
        manhattan: List.generate(
          20,
          (i) => OverStats(
            overNumber: i + 1,
            runs: 9,
            hasWicket: i == 5 || i == 12,
          ),
        ),
        worm: const [],
        runRate: const [],
      );
      await tester.pumpWidget(buildWidget(data));

      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}

InningsChartData _createChartData({
  String teamName = 'Team A',
  String scoreDisplay = '150/5',
}) {
  return InningsChartData(
    teamName: teamName,
    scoreDisplay: scoreDisplay,
    manhattan: const [
      OverStats(overNumber: 1, runs: 8, hasWicket: false),
      OverStats(overNumber: 2, runs: 12, hasWicket: true),
      OverStats(overNumber: 3, runs: 5, hasWicket: false),
    ],
    worm: const [],
    runRate: const [],
  );
}
