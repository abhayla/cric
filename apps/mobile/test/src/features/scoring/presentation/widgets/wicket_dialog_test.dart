import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/theme/app_colors.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/wicket_dialog.dart';

void main() {
  List<PlayingXIPlayer> makeBowlingTeam({int count = 11}) {
    return List.generate(
      count,
      (i) => PlayingXIPlayer(
        playerId: 'bowl-$i',
        displayName: 'Bowler ${i + 1}',
        playerRole: i < 3 ? 'bowler' : 'all_rounder',
        isCaptain: i == 0,
        isKeeper: i == 4,
      ),
    );
  }

  Widget buildDialog({
    List<PlayingXIPlayer>? bowlingTeamPlayers,
    String strikerName = 'Virat Kohli',
    String strikerId = 'striker-1',
    String nonStrikerName = 'Rohit Sharma',
    String nonStrikerId = 'non-striker-1',
    bool isFreeHitPending = false,
    ValueChanged<WicketDialogResult>? onConfirm,
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
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => WicketDialog(
                    bowlingTeamPlayers:
                        bowlingTeamPlayers ?? makeBowlingTeam(),
                    strikerName: strikerName,
                    strikerId: strikerId,
                    nonStrikerName: nonStrikerName,
                    nonStrikerId: nonStrikerId,
                    isFreeHitPending: isFreeHitPending,
                    onConfirm: (result) {
                      Navigator.of(ctx).pop();
                      (onConfirm ?? (_) {})(result);
                    },
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
  }

  /// Tap a dismissal type chip by label.
  Future<void> tapDismissalType(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
  }

  group('WicketDialog header', () {
    testWidgets('renders Wicket! title', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      expect(find.text('Wicket!'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button pops dialog', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      expect(find.text('Wicket!'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Wicket!'), findsNothing);
    });
  });

  group('WicketDialog step 1 — dismissal type grid', () {
    testWidgets('renders step subtitle', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      expect(find.text('How was the batter dismissed?'), findsOneWidget);
    });

    testWidgets('renders all 11 dismissal types', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      expect(find.text('Bowled'), findsOneWidget);
      expect(find.text('Caught'), findsOneWidget);
      expect(find.text('LBW'), findsOneWidget);
      expect(find.text('Run Out'), findsOneWidget);
      expect(find.text('Stumped'), findsOneWidget);
      expect(find.text('Hit Wicket'), findsOneWidget);
      expect(find.text('C & B'), findsOneWidget);
      expect(find.text('Ret. Hurt'), findsOneWidget);
      expect(find.text('Ret. Out'), findsOneWidget);
      expect(find.text('Timed Out'), findsOneWidget);
      expect(find.text('Obstruct.'), findsOneWidget);
    });

    testWidgets('active types are tappable', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Bowled');
      // Should now show Confirm Wicket button (step 1 terminal types)
      expect(find.text('Confirm Wicket'), findsOneWidget);
    });

    testWidgets('Timed Out is disabled', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      // Find the Timed Out chip — it should have low opacity
      final timedOutFinder = find.text('Timed Out');
      expect(timedOutFinder, findsOneWidget);
      // Tap it - should not change button text
      await tester.tap(timedOutFinder);
      await tester.pump();
      // Next/Confirm button should remain disabled (no selection)
      final confirmButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    });

    testWidgets('Obstruct. is disabled', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      final obstructFinder = find.text('Obstruct.');
      expect(obstructFinder, findsOneWidget);
      await tester.tap(obstructFinder);
      await tester.pump();
      final confirmButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    });

    testWidgets('tap selects dismissal type', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      // Should see Next button enabled (caught needs fielder)
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    });

    testWidgets('tap deselects previously selected type', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      // Select Caught
      await tapDismissalType(tester, 'Caught');
      expect(find.text('Next'), findsOneWidget);
      // Select Run Out instead
      await tapDismissalType(tester, 'Run Out');
      // Still showing Next (both need fielder)
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    });

    testWidgets('Next disabled without selection', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    });

    testWidgets('Back button is disabled on step 1', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      final backButton = find.widgetWithText(TextButton, 'Back');
      expect(tester.widget<TextButton>(backButton).onPressed, isNull);
    });
  });

  group('WicketDialog step 1 — button text per type', () {
    testWidgets('Bowled shows Confirm Wicket', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Bowled');
      expect(find.text('Confirm Wicket'), findsOneWidget);
    });

    testWidgets('Caught shows Next', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Stumped shows Next', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Stumped');
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Run Out shows Next', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Run Out');
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('C & B shows Confirm Wicket', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'C & B');
      expect(find.text('Confirm Wicket'), findsOneWidget);
    });

    testWidgets('Ret. Hurt shows Confirm Wicket', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Ret. Hurt');
      expect(find.text('Confirm Wicket'), findsOneWidget);
    });
  });

  group('WicketDialog free hit mode', () {
    testWidgets('only Run Out is enabled during free hit', (tester) async {
      await tester.pumpWidget(buildDialog(isFreeHitPending: true));
      await openDialog(tester);
      // Run Out should be tappable
      await tapDismissalType(tester, 'Run Out');
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    });

    testWidgets('Bowled is disabled during free hit', (tester) async {
      await tester.pumpWidget(buildDialog(isFreeHitPending: true));
      await openDialog(tester);
      await tapDismissalType(tester, 'Bowled');
      await tester.pump();
      // Next button should remain disabled
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    });

    testWidgets('Caught is disabled during free hit', (tester) async {
      await tester.pumpWidget(buildDialog(isFreeHitPending: true));
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.pump();
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    });
  });

  group('WicketDialog step 2 — fielder selection', () {
    testWidgets('title shows Select Fielder for Caught', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Select Fielder'), findsOneWidget);
    });

    testWidgets('title shows Select Fielder for Stumped', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Stumped');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Select Fielder'), findsOneWidget);
    });

    testWidgets('title shows Select Fielder for Run Out', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Run Out');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Select Fielder'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders bowling team players', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Bowler 1'), findsOneWidget);
      expect(find.text('Bowler 2'), findsOneWidget);
    });

    testWidgets('WK badge shows for keeper', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('(WK)'), findsOneWidget);
    });

    testWidgets('tap selects fielder', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Tap first player
      await tester.tap(find.text('Bowler 1'));
      await tester.pump();
      // Confirm button should now be enabled
      final confirmButton =
          find.widgetWithText(FilledButton, 'Confirm Wicket');
      expect(
          tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    });

    testWidgets('search filters players', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Type in search
      await tester.enterText(find.byType(TextField), 'Bowler 3');
      await tester.pump();
      // Should only show matching player (2 = text field + list row)
      expect(find.text('Bowler 3'), findsNWidgets(2));
      expect(find.text('Bowler 1'), findsNothing);
    });

    testWidgets('Confirm disabled without fielder selection', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // For caught, next step is fielder — button should say "Confirm Wicket" and be disabled
      final confirmButton =
          find.widgetWithText(FilledButton, 'Confirm Wicket');
      expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    });

    testWidgets('Back preserves dismissal selection', (tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Go back
      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pump();
      // Should be back on step 1 with Caught still showing Next
      expect(find.text('How was the batter dismissed?'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('WicketDialog step 3 — run out details', () {
    Future<void> navigateToStep3(WidgetTester tester) async {
      await tester.pumpWidget(buildDialog());
      await openDialog(tester);
      await tapDismissalType(tester, 'Run Out');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select a fielder
      await tester.tap(find.text('Bowler 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('title shows Run Out Details', (tester) async {
      await navigateToStep3(tester);
      expect(find.text('Run Out Details'), findsOneWidget);
    });

    testWidgets('shows striker and non-striker cards with names',
        (tester) async {
      await navigateToStep3(tester);
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
    });

    testWidgets('striker is selected by default', (tester) async {
      await navigateToStep3(tester);
      // "Which batter was run out?" label
      expect(find.text('Which batter was run out?'), findsOneWidget);
      // Striker card should be visually selected (has border color)
      // We verify by checking the confirm result later
    });

    testWidgets('tap toggles batter selection', (tester) async {
      await navigateToStep3(tester);
      // Tap non-striker
      await tester.tap(find.text('Rohit Sharma'));
      await tester.pump();
      // Non-striker should now be selected — we verify through callback
    });

    testWidgets('batters crossed toggle present', (tester) async {
      await navigateToStep3(tester);
      expect(find.text('Had batters crossed?'), findsOneWidget);
      // Step 3 has 2 switches: batters crossed + direct hit
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('runs 0-3 buttons with 0 default', (tester) async {
      await navigateToStep3(tester);
      expect(find.text('Runs before run out'), findsOneWidget);
      // Check 0,1,2,3 buttons exist
      for (final r in [0, 1, 2, 3]) {
        expect(
          find.descendant(
            of: find.byType(WicketDialog),
            matching: find.text('$r'),
          ),
          findsWidgets,
        );
      }
    });

    testWidgets('Back preserves fielder selection', (tester) async {
      await navigateToStep3(tester);
      // Go back to step 2
      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pump();
      // Should be on step 2 (fielder selection)
      expect(find.text('Select Fielder'), findsOneWidget);
      // Fielder should still be selected — confirm should be enabled (as Next for run out)
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    });
  });

  group('WicketDialog confirm callbacks', () {
    testWidgets('Bowled callback has correct params', (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialog(
        onConfirm: (r) => captured = r,
      ));
      await openDialog(tester);
      await tapDismissalType(tester, 'Bowled');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.dismissalType, DismissalType.bowled);
      expect(captured!.dismissedPlayerId, 'striker-1');
      expect(captured!.fielderId, isNull);
      expect(captured!.runsFromBat, 0);
      expect(captured!.battersCrossed, false);
    });

    testWidgets('Caught + fielder callback has correct params',
        (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialog(
        onConfirm: (r) => captured = r,
      ));
      await openDialog(tester);
      await tapDismissalType(tester, 'Caught');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select Bowler 1 as fielder
      await tester.tap(find.text('Bowler 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.dismissalType, DismissalType.caught);
      expect(captured!.dismissedPlayerId, 'striker-1');
      expect(captured!.fielderId, 'bowl-0');
      expect(captured!.fielderName, 'Bowler 1');
    });

    testWidgets('Run Out full params callback', (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialog(
        onConfirm: (r) => captured = r,
      ));
      await openDialog(tester);
      // Step 1: select Run Out
      await tapDismissalType(tester, 'Run Out');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 2: select fielder
      await tester.tap(find.text('Bowler 2'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 3: select non-striker, toggle crossed, set runs to 1
      await tester.tap(find.text('Rohit Sharma'));
      await tester.pump();
      // Toggle "Had batters crossed?" (first Switch)
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      // Tap runs "1" button in the run out details step
      final runsButton = find.descendant(
        of: find.byType(WicketDialog),
        matching: find.text('1'),
      );
      await tester.tap(runsButton.last);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.dismissalType, DismissalType.runOut);
      expect(captured!.dismissedPlayerId, 'non-striker-1');
      expect(captured!.fielderId, 'bowl-1');
      expect(captured!.fielderName, 'Bowler 2');
      expect(captured!.runsFromBat, 1);
      expect(captured!.battersCrossed, true);
    });

    testWidgets('Ret. Hurt callback has correct params', (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialog(
        onConfirm: (r) => captured = r,
      ));
      await openDialog(tester);
      await tapDismissalType(tester, 'Ret. Hurt');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.dismissalType, DismissalType.retiredHurt);
      expect(captured!.dismissedPlayerId, 'striker-1');
      expect(captured!.fielderId, isNull);
    });

    testWidgets('C & B callback has correct params', (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialog(
        onConfirm: (r) => captured = r,
      ));
      await openDialog(tester);
      await tapDismissalType(tester, 'C & B');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.dismissalType, DismissalType.caughtAndBowled);
      expect(captured!.dismissedPlayerId, 'striker-1');
      expect(captured!.fielderId, isNull);
    });
  });

  // ── New helper for isWide / isNoBall params ──

  Widget buildDialogWithExtras({
    List<PlayingXIPlayer>? bowlingTeamPlayers,
    String strikerName = 'Virat Kohli',
    String strikerId = 'striker-1',
    String nonStrikerName = 'Rohit Sharma',
    String nonStrikerId = 'non-striker-1',
    bool isFreeHitPending = false,
    bool isWide = false,
    bool isNoBall = false,
    ValueChanged<WicketDialogResult>? onConfirm,
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
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => WicketDialog(
                    bowlingTeamPlayers:
                        bowlingTeamPlayers ?? makeBowlingTeam(),
                    strikerName: strikerName,
                    strikerId: strikerId,
                    nonStrikerName: nonStrikerName,
                    nonStrikerId: nonStrikerId,
                    isFreeHitPending: isFreeHitPending,
                    isWide: isWide,
                    isNoBall: isNoBall,
                    onConfirm: (result) {
                      Navigator.of(ctx).pop();
                      (onConfirm ?? (_) {})(result);
                    },
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialogExtras(WidgetTester tester) async {
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
  }

  group('WicketDialog isWide mode', () {
    testWidgets('isWide=true — only Stumped and Run Out are tappable',
        (tester) async {
      await tester.pumpWidget(buildDialogWithExtras(isWide: true));
      await openDialogExtras(tester);

      // Without any selection, Next button should be disabled
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Bowled should be disabled — tapping it should not enable Next
      await tapDismissalType(tester, 'Bowled');
      await tester.pump();
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Caught should be disabled
      await tapDismissalType(tester, 'Caught');
      await tester.pump();
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Stumped should be tappable — tap it and verify Next is enabled
      await tapDismissalType(tester, 'Stumped');
      final nextAfterStumped = find.widgetWithText(FilledButton, 'Next');
      expect(
          tester.widget<FilledButton>(nextAfterStumped).onPressed, isNotNull);
    });

    testWidgets('isWide=true — Run Out is also tappable', (tester) async {
      await tester.pumpWidget(buildDialogWithExtras(isWide: true));
      await openDialogExtras(tester);

      await tapDismissalType(tester, 'Run Out');
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    });
  });

  group('WicketDialog isNoBall mode', () {
    testWidgets('isNoBall=true — only Run Out is tappable', (tester) async {
      await tester.pumpWidget(buildDialogWithExtras(isNoBall: true));
      await openDialogExtras(tester);

      // Next button should be disabled without selection
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Stumped should be disabled on no-ball
      await tapDismissalType(tester, 'Stumped');
      await tester.pump();
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Bowled should also be disabled
      await tapDismissalType(tester, 'Bowled');
      await tester.pump();
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

      // Run Out should be tappable
      await tapDismissalType(tester, 'Run Out');
      final nextAfterRunOut = find.widgetWithText(FilledButton, 'Next');
      expect(
          tester.widget<FilledButton>(nextAfterRunOut).onPressed, isNotNull);
    });
  });

  group('WicketDialog Direct Hit toggle', () {
    testWidgets('Direct hit toggle visible on step 3', (tester) async {
      await tester.pumpWidget(buildDialogWithExtras());
      await openDialogExtras(tester);
      // Step 1: select Run Out
      await tapDismissalType(tester, 'Run Out');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 2: select fielder
      await tester.tap(find.text('Bowler 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 3: verify Direct hit? text is visible
      expect(find.text('Direct hit?'), findsOneWidget);
    });

    testWidgets('Direct hit toggle sets isDirectHit=true in result',
        (tester) async {
      WicketDialogResult? captured;
      await tester.pumpWidget(buildDialogWithExtras(
        onConfirm: (r) => captured = r,
      ));
      await openDialogExtras(tester);
      // Step 1: select Run Out
      await tapDismissalType(tester, 'Run Out');
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 2: select fielder
      await tester.tap(find.text('Bowler 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 3: toggle Direct hit on — find the Switch widgets, the direct hit one
      // There are multiple switches (batters crossed + direct hit)
      final switches = find.byType(Switch);
      // Direct hit switch is the second one
      await tester.tap(switches.last);
      await tester.pump();
      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.isDirectHit, true);
    });
  });
}
