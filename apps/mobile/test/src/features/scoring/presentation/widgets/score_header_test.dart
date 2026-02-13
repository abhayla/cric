import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/score_header.dart';

void main() {
  Widget buildHeader({
    String battingTeamName = 'Mumbai Warriors',
    int inningsNumber = 1,
    int totalRuns = 150,
    int totalWickets = 4,
    String oversDisplay = '15.3',
    double runRate = 9.68,
    double? requiredRunRate,
    int? target,
    int? runsNeeded,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: ScoreHeader(
          battingTeamName: battingTeamName,
          inningsNumber: inningsNumber,
          totalRuns: totalRuns,
          totalWickets: totalWickets,
          oversDisplay: oversDisplay,
          runRate: runRate,
          requiredRunRate: requiredRunRate,
          target: target,
          runsNeeded: runsNeeded,
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  group('ScoreHeader', () {
    testWidgets('renders batting team name', (tester) async {
      await tester.pumpWidget(buildHeader());
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('renders innings label', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 1));
      expect(find.text('1st Innings'), findsOneWidget);
    });

    testWidgets('renders second innings label', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 2));
      expect(find.text('2nd Innings'), findsOneWidget);
    });

    testWidgets('renders score display', (tester) async {
      await tester.pumpWidget(buildHeader(totalRuns: 150, totalWickets: 4));
      expect(find.text('150/4'), findsOneWidget);
    });

    testWidgets('renders overs display', (tester) async {
      await tester.pumpWidget(buildHeader(oversDisplay: '15.3'));
      expect(find.text('(15.3)'), findsOneWidget);
    });

    testWidgets('renders current run rate', (tester) async {
      await tester.pumpWidget(buildHeader(runRate: 9.68));
      expect(find.text('CRR: 9.68'), findsOneWidget);
    });

    testWidgets('hides RRR/target/need for 1st innings', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 1));
      expect(find.textContaining('RRR'), findsNothing);
      expect(find.textContaining('Target'), findsNothing);
      expect(find.textContaining('Need'), findsNothing);
    });

    testWidgets('shows target for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('Target: 180'), findsOneWidget);
    });

    testWidgets('shows runs needed for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('Need: 30'), findsOneWidget);
    });

    testWidgets('shows required run rate for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('RRR: 10.50'), findsOneWidget);
    });

    testWidgets('calls onBack when back button tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildHeader(onBack: () => called = true));
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(called, isTrue);
    });
  });
}
