import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/presentation/notifiers/toss_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/pages/toss_page.dart';

void main() {
  // -- Test data --
  const homeId = 'home-team-id';
  const awayId = 'away-team-id';
  const homeName = 'Mumbai Warriors';
  const awayName = 'Delhi Strikers';

  List<RosterPlayer> makeRoster(int count, {String prefix = 'p'}) {
    return List.generate(count, (i) {
      return RosterPlayer(
        playerId: '$prefix-$i',
        displayName: '${prefix.toUpperCase()} Player ${i + 1}',
        playerRole: i < 3 ? 'batter' : (i < 6 ? 'bowler' : 'all_rounder'),
        isCaptain: i == 0,
        isKeeper: i == 4,
      );
    });
  }

  Widget buildPage({
    String matchId = 'match-1',
    String homeTeamId = homeId,
    String homeTeamName = homeName,
    String awayTeamId = awayId,
    String awayTeamName = awayName,
    int playersPerSide = 11,
    List<RosterPlayer>? homeRoster,
    List<RosterPlayer>? awayRoster,
    void Function()? onStartMatch,
  }) {
    return MaterialApp(
      home: TossPage(
        matchId: matchId,
        homeTeamId: homeTeamId,
        homeTeamName: homeTeamName,
        awayTeamId: awayTeamId,
        awayTeamName: awayTeamName,
        playersPerSide: playersPerSide,
        homeRoster: homeRoster ?? makeRoster(11, prefix: 'h'),
        awayRoster: awayRoster ?? makeRoster(11, prefix: 'a'),
        onStartMatch: onStartMatch ?? () {},
      ),
    );
  }

  group('TossPage', () {
    testWidgets('shows AppBar with "Toss" title', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.widgetWithText(AppBar, 'Toss'), findsOneWidget);
    });

    testWidgets('shows stepper with 5 step labels', (tester) async {
      await tester.pumpWidget(buildPage());
      // Step labels from the wireframe
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Step 1: shows "Who won the toss?" heading', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Who won the toss?'), findsOneWidget);
    });

    testWidgets('Step 1: shows both team cards', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text(homeName), findsOneWidget);
      expect(find.text(awayName), findsOneWidget);
    });

    testWidgets('Step 1: Next button is visible', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Step 1: Next button is disabled without selection',
        (tester) async {
      await tester.pumpWidget(buildPage());
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Step 1: Back button is hidden', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Step 1: tapping team card enables Next', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(find.text(homeName));
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Step 2: shows after tapping team + Next', (tester) async {
      await tester.pumpWidget(buildPage());
      // Select home team
      await tester.tap(find.text(homeName));
      await tester.pump();
      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // Step 2 content
      expect(find.textContaining('chose to'), findsOneWidget);
    });

    testWidgets('Step 2: shows Bat and Field options', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Bat'), findsOneWidget);
      expect(find.text('Field'), findsOneWidget);
    });

    testWidgets('Step 2: shows Back button', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('Step 2: Back returns to Step 1', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Who won the toss?'), findsOneWidget);
    });

    testWidgets('Step 3: shows Playing XI heading with team name',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Navigate to Step 3
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bat'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Playing XI'), findsOneWidget);
    });

    testWidgets('Step 3: shows player list from home roster', (tester) async {
      await tester.pumpWidget(buildPage());
      // Navigate to Step 3
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bat'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // First player should be visible (with captain badge)
      expect(find.text('H Player 1 (C)'), findsOneWidget);
    });

    testWidgets('Step 3: shows selected count label', (tester) async {
      await tester.pumpWidget(buildPage());
      // Navigate to Step 3
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bat'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // All 11 pre-selected
      expect(find.text('11 / 11 selected'), findsOneWidget);
    });

    testWidgets('Step 5: shows opener and bowler sections', (tester) async {
      // Use a smaller playersPerSide (6) to make navigation faster
      final homeRoster = makeRoster(6, prefix: 'h');
      final awayRoster = makeRoster(6, prefix: 'a');
      await tester.pumpWidget(buildPage(
        playersPerSide: 6,
        homeRoster: homeRoster,
        awayRoster: awayRoster,
      ));

      // Step 1: Select home team
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Select Bat
      await tester.tap(find.text('Bat'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: XI already pre-selected (6 == 6), Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: XI already pre-selected, Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 5
      expect(find.text('Select Opening Batsmen'), findsOneWidget);
      expect(find.text('Select Opening Bowler'), findsOneWidget);
    });

    testWidgets('Step 5: button shows "Start Match"', (tester) async {
      final homeRoster = makeRoster(6, prefix: 'h');
      final awayRoster = makeRoster(6, prefix: 'a');
      await tester.pumpWidget(buildPage(
        playersPerSide: 6,
        homeRoster: homeRoster,
        awayRoster: awayRoster,
      ));

      // Navigate through all steps
      await tester.tap(find.text(homeName));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bat'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Start Match'), findsOneWidget);
    });
  });
}
