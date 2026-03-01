import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/pages/match_setup_page.dart';

void main() {
  Widget buildPage({
    void Function(
      String matchId, {
      required String homeTeamId,
      required String homeTeamName,
      required String awayTeamId,
      required String awayTeamName,
      required int playersPerSide,
      required int totalOvers,
      required int wideRuns,
      required int noBallRuns,
      required List<int>? magicOverNumbers,
      required int magicOverRunMultiplier,
      required int magicOverWicketPenalty,
      required bool isKnockoutMatch,
    })? onMatchCreated,
    void Function()? onNavigateToCreateTeam,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MatchSetupPage(
          onMatchCreated: onMatchCreated ??
              (_, {
                required homeTeamId,
                required homeTeamName,
                required awayTeamId,
                required awayTeamName,
                required playersPerSide,
                required totalOvers,
                required wideRuns,
                required noBallRuns,
                required magicOverNumbers,
                required magicOverRunMultiplier,
                required magicOverWicketPenalty,
                required isKnockoutMatch,
              }) {},
          onNavigateToCreateTeam: onNavigateToCreateTeam,
        ),
      ),
    );
  }

  group('MatchSetupPage', () {
    testWidgets('shows AppBar with "New Match" title', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('New Match'), findsOneWidget);
    });

    testWidgets('shows team selection section', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Teams'), findsOneWidget);
    });

    testWidgets('shows team A selector with placeholder', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Select Team A'), findsOneWidget);
    });

    testWidgets('shows team B selector with placeholder', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Select Team B'), findsOneWidget);
    });

    testWidgets('shows VS badge between team selectors', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('shows Match Format section with overs input', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Match Format'), findsOneWidget);
    });

    testWidgets('shows overs preset chips', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('shows Players Per Side section', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Players Per Side'), findsOneWidget);
    });

    testWidgets('shows player preset chips (6, 8, 11)', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('6'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('shows Ball Type section with 4 chips', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Ball Type'), findsOneWidget);
      expect(find.text('Leather'), findsOneWidget);
      expect(find.text('Tennis'), findsOneWidget);
      expect(find.text('Tape'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('shows Match Date field', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Match Date'), findsOneWidget);
    });

    testWidgets('shows Venue field', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Venue (optional)'), findsOneWidget);
    });

    testWidgets('shows Advanced Settings toggle (collapsed)', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Advanced Settings'), findsOneWidget);
      // Advanced fields hidden by default
      expect(find.text('Wide Runs'), findsNothing);
    });

    testWidgets('expands advanced settings on tap', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.ensureVisible(find.text('Advanced Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Wide Runs'), findsOneWidget);
      expect(find.text('No-Ball Runs'), findsOneWidget);
      expect(find.text('Max Overs Per Bowler'), findsOneWidget);
      expect(find.text('Powerplay Overs'), findsOneWidget);
    });

    testWidgets('shows Proceed to Toss button', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Proceed to Toss'), findsOneWidget);
    });

    testWidgets('Proceed to Toss is disabled initially (no teams)',
        (tester) async {
      await tester.pumpWidget(buildPage());
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping overs preset chip updates selection', (tester) async {
      await tester.pumpWidget(buildPage());

      // Tap the "10" chip
      await tester.tap(find.widgetWithText(ChoiceChip, '10'));
      await tester.pump();

      // "10" should now be selected
      final chip10 =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10'));
      expect(chip10.selected, true);
    });

    testWidgets('tapping ball type chip updates selection', (tester) async {
      await tester.pumpWidget(buildPage());

      // Scroll to the "Tennis" chip first (it may be off-screen)
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tennis'));
      await tester.pumpAndSettle();

      // Tap the "Tennis" chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tennis'));
      await tester.pump();

      final tennisChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Tennis'));
      expect(tennisChip.selected, true);
    });
  });
}
