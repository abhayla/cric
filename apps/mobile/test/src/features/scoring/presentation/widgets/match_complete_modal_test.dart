import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/theme/app_colors.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';

void main() {
  Widget buildModal({
    FirstInningsSummary firstInnings = const FirstInningsSummary(
      teamName: 'Mumbai Warriors',
      teamId: 'team-mw',
      totalRuns: 187,
      totalWickets: 6,
      totalBalls: 120,
      oversDisplay: '20.0',
    ),
    String secondTeamName = 'Delhi Strikers',
    int secondTotalRuns = 172,
    int secondTotalWickets = 9,
    String secondOversDisplay = '20.0',
    MatchResult matchResult = const MatchResult(
      winnerTeamId: 'team-mw',
      winnerTeamName: 'Mumbai Warriors',
      resultType: MatchResultType.runs,
      margin: 15,
      resultDescription: 'Mumbai Warriors won by 15 runs',
    ),
    ValueChanged<MatchCompleteAction>? onAction,
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
        body: Center(
          child: MatchCompleteModal(
            firstInnings: firstInnings,
            secondTeamName: secondTeamName,
            secondTotalRuns: secondTotalRuns,
            secondTotalWickets: secondTotalWickets,
            secondOversDisplay: secondOversDisplay,
            matchResult: matchResult,
            onAction: onAction ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('MatchCompleteModal header', () {
    testWidgets('shows "Match Complete!" title', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Match Complete!'), findsOneWidget);
    });

    testWidgets('header has primaryContainer background color', (tester) async {
      await tester.pumpWidget(buildModal());
      final headerContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Match Complete!'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = headerContainer.decoration as BoxDecoration?;
      final theme = Theme.of(
        tester.element(find.byType(MatchCompleteModal)),
      );
      expect(decoration?.color, theme.colorScheme.primaryContainer);
    });
  });

  group('MatchCompleteModal score comparison', () {
    testWidgets('shows 1st innings team name', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('shows 1st innings score', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('187/6'), findsOneWidget);
    });

    testWidgets('shows 1st innings overs with ov label', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('(20.0 ov)'), findsWidgets);
    });

    testWidgets('shows VS separator', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('shows 2nd innings team name', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Delhi Strikers'), findsOneWidget);
    });

    testWidgets('shows 2nd innings score', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('172/9'), findsOneWidget);
    });

    testWidgets('shows 2nd innings overs', (tester) async {
      await tester.pumpWidget(buildModal(secondOversDisplay: '18.3'));
      expect(find.text('(18.3 ov)'), findsOneWidget);
    });

    testWidgets('shows team initials in avatars', (tester) async {
      await tester.pumpWidget(buildModal());
      // Mumbai Warriors → MW, Delhi Strikers → DS
      expect(find.text('MW'), findsOneWidget);
      expect(find.text('DS'), findsOneWidget);
    });
  });

  group('MatchCompleteModal result text', () {
    testWidgets('runs victory result text', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(
        find.text('Mumbai Warriors won by 15 runs'),
        findsOneWidget,
      );
    });

    testWidgets('wickets victory result text', (tester) async {
      await tester.pumpWidget(buildModal(
        matchResult: const MatchResult(
          winnerTeamId: 'team-ds',
          winnerTeamName: 'Delhi Strikers',
          resultType: MatchResultType.wickets,
          margin: 5,
          resultDescription: 'Delhi Strikers won by 5 wickets',
        ),
      ));
      expect(
        find.text('Delhi Strikers won by 5 wickets'),
        findsOneWidget,
      );
    });

    testWidgets('tie result text', (tester) async {
      await tester.pumpWidget(buildModal(
        matchResult: const MatchResult(
          winnerTeamId: null,
          winnerTeamName: null,
          resultType: MatchResultType.tie,
          margin: null,
          resultDescription: 'Match Tied',
        ),
      ));
      expect(find.text('Match Tied'), findsOneWidget);
    });
  });

  group('MatchCompleteModal footer actions', () {
    testWidgets('View Scorecard button present', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.widgetWithText(FilledButton, 'View Scorecard'), findsOneWidget);
    });

    testWidgets('Back to Home button present', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(
        find.widgetWithText(OutlinedButton, 'Back to Home'),
        findsOneWidget,
      );
    });

    testWidgets('tapping View Scorecard fires viewScorecard action',
        (tester) async {
      MatchCompleteAction? firedAction;
      await tester.pumpWidget(buildModal(
        onAction: (action) => firedAction = action,
      ));
      await tester.tap(find.widgetWithText(FilledButton, 'View Scorecard'));
      await tester.pump();
      expect(firedAction, MatchCompleteAction.viewScorecard);
    });

    testWidgets('tapping Back to Home fires backToHome action',
        (tester) async {
      MatchCompleteAction? firedAction;
      await tester.pumpWidget(buildModal(
        onAction: (action) => firedAction = action,
      ));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back to Home'));
      await tester.pump();
      expect(firedAction, MatchCompleteAction.backToHome);
    });
  });
}
