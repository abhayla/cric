/// Match setup and toss wizard helpers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';

import '../core/test_utils.dart';

/// Select a team in the match setup page team picker.
///
/// Taps the team selector placeholder (e.g. 'Select Team A'), waits for the
/// bottom sheet with team list to load from the server, then taps the team name.
Future<void> selectTeamInMatchSetup(
  WidgetTester tester,
  String teamName, {
  required bool isHome,
}) async {
  final placeholder = isHome ? 'Select Team A' : 'Select Team B';

  final selectorText = find.text(placeholder);
  if (selectorText.evaluate().isNotEmpty) {
    final inkWell = find.ancestor(
      of: selectorText,
      matching: find.byType(InkWell),
    );
    if (inkWell.evaluate().isNotEmpty) {
      await tester.tap(inkWell.first, warnIfMissed: false);
    } else {
      await tester.tap(selectorText.first, warnIfMissed: false);
    }
  } else {
    final selectedName = find.text(teamName);
    if (selectedName.evaluate().isNotEmpty) {
      print('    [teamPicker] ${isHome ? "Team A" : "Team B"} already set to: $teamName');
      return;
    }
    print('    [teamPicker] Neither placeholder "$placeholder" nor team name found');
    return;
  }
  await settle(tester);
  await visualPause(tester, 500);

  // Wait for bottom sheet and teams to load
  await waitForFinder(tester, find.byType(ListTile),
      timeoutMs: 6000, intervalMs: 100);
  await settle(tester);

  // Find and tap the team
  final teamInSheet = find.text(teamName);
  if (teamInSheet.evaluate().isNotEmpty) {
    final listTile = find.ancestor(
      of: teamInSheet,
      matching: find.byType(ListTile),
    );
    if (listTile.evaluate().isNotEmpty) {
      await tester.ensureVisible(listTile.first);
      await tester.pumpAndSettle();
      await tester.tap(listTile.first, warnIfMissed: false);
    } else {
      await tester.tap(teamInSheet.last, warnIfMissed: false);
    }
    await settle(tester);
    await visualPause(tester, 500);
    print('    [teamPicker] Selected ${isHome ? "Team A" : "Team B"}: $teamName');
  } else {
    // Scroll through the list
    print('    [teamPicker] "$teamName" not immediately visible, scrolling...');
    final scrollable = find.byType(Scrollable);
    var found = false;
    for (var scroll = 0; scroll < 10 && !found; scroll++) {
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.last, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      final retry = find.text(teamName);
      if (retry.evaluate().isNotEmpty) {
        final listTile = find.ancestor(
          of: retry,
          matching: find.byType(ListTile),
        );
        if (listTile.evaluate().isNotEmpty) {
          await tester.ensureVisible(listTile.first);
          await tester.pumpAndSettle();
          await tester.tap(listTile.first, warnIfMissed: false);
        } else {
          await tester.tap(retry.last, warnIfMissed: false);
        }
        await settle(tester);
        await visualPause(tester, 500);
        print('    [teamPicker] Selected ${isHome ? "Team A" : "Team B"}: $teamName (after scroll)');
        found = true;
      }
    }
    if (!found) {
      print('    [teamPicker] WARNING: "$teamName" not found — dismissing picker');
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
    }
  }
}

/// Complete the Match Setup page by tapping "Proceed to Toss".
Future<void> completeMatchSetup(WidgetTester tester) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await settle(tester);
  await visualPause(tester, 300);

  final proceedButton = find.text('Proceed to Toss');
  print('    [matchSetup] "Proceed to Toss" found: ${proceedButton.evaluate().isNotEmpty}');

  if (proceedButton.evaluate().isEmpty) {
    dumpVisibleTexts(tester, 'matchSetup', 30);
    print('    [matchSetup] WARNING: Not on match setup page!');
    return;
  }

  // Invoke directly to avoid SliverAppBar hit test issues
  final filledButtonFinder = find.widgetWithText(FilledButton, 'Proceed to Toss');
  if (filledButtonFinder.evaluate().isNotEmpty) {
    final button = tester.widget<FilledButton>(filledButtonFinder.first);
    if (button.onPressed != null) {
      print('    [matchSetup] Invoking Proceed to Toss via onPressed');
      button.onPressed!();
    }
  } else {
    await tester.ensureVisible(proceedButton);
    await tester.pumpAndSettle();
    await tester.tap(proceedButton, warnIfMissed: false);
  }
  await settle(tester);
  await visualPause(tester, 2000);

  final tossText = find.text('Who won the toss?');
  print('    [matchSetup] After proceed, toss page found: ${tossText.evaluate().isNotEmpty}');
  if (tossText.evaluate().isEmpty) {
    dumpVisibleTexts(tester, 'matchSetup-afterProceed', 30);
  }
}

/// Complete the full Toss Wizard (5 steps) through the UI.
Future<void> completeTossWizard(
  WidgetTester tester, {
  required String tossWinnerName,
  required String battingOpener1,
  required String battingOpener2,
  required String openingBowler,
  int? playersPerSide,
  bool chooseBat = true,
}) async {
  // Step 1: "Who won the toss?" → tap team card
  await settle(tester);
  print('    [toss] Step 1: Selecting toss winner: $tossWinnerName');
  expect(find.text('Who won the toss?'), findsOneWidget,
      reason: 'Should be on Toss Step 1');
  final teamCard = find.text(tossWinnerName);
  if (teamCard.evaluate().isNotEmpty) {
    await tester.tap(teamCard.first);
    await tester.pump();
  }
  await _tapNextButton(tester);

  // Step 2: Toss decision
  final choice = chooseBat ? 'Bat' : 'Field';
  print('    [toss] Step 2: Choosing to $choice');
  final choiceOption = find.text(choice);
  if (choiceOption.evaluate().isNotEmpty) {
    await tester.tap(choiceOption.first);
    await tester.pump();
  }
  await _tapNextButton(tester);

  // Step 3: Playing XI for first team
  print('    [toss] Step 3: Playing XI Team A');
  await _selectPlayingXIIfNeeded(tester, playersPerSide);
  await _tapNextButton(tester);

  // Step 4: Playing XI for second team
  print('    [toss] Step 4: Playing XI Team B');
  await _selectPlayingXIIfNeeded(tester, playersPerSide);
  await _tapNextButton(tester);

  // Step 5: Select openers and bowler
  print('    [toss] Step 5: Selecting openers ($battingOpener1, $battingOpener2) and bowler ($openingBowler)');

  dumpVisibleTexts(tester, 'toss-step5-before', 40);

  // Select first opener
  final opener1 = find.textContaining(battingOpener1);
  print('    [toss] Opener1 "$battingOpener1" found: ${opener1.evaluate().length}');
  if (opener1.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener1.first);
    await tester.pumpAndSettle();
    await tester.tap(opener1.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Tapped opener1');
  }

  // Select second opener
  final opener2 = find.textContaining(battingOpener2);
  print('    [toss] Opener2 "$battingOpener2" found: ${opener2.evaluate().length}');
  if (opener2.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener2.first);
    await tester.pumpAndSettle();
    await tester.tap(opener2.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Tapped opener2');
  }

  // Select striker
  await settle(tester);
  final strikerPrompt = find.text('Who will face the first ball?');
  print('    [toss] Striker prompt found: ${strikerPrompt.evaluate().isNotEmpty}');

  if (strikerPrompt.evaluate().isNotEmpty) {
    final strikerOption = find.text(battingOpener1);
    print('    [toss] Striker option "$battingOpener1" found: ${strikerOption.evaluate().length}');
    if (strikerOption.evaluate().length >= 2) {
      await tester.ensureVisible(strikerOption.last);
      await tester.pumpAndSettle();
      await tester.tap(strikerOption.last);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (tapped last of ${strikerOption.evaluate().length})');
    } else if (strikerOption.evaluate().isNotEmpty) {
      await tester.ensureVisible(strikerOption.first);
      await tester.pumpAndSettle();
      await tester.tap(strikerOption.first);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (single match)');
    }
  } else {
    print('    [toss] WARNING: Striker prompt not found!');
  }

  // Verify openers are still selected
  await tester.pump();
  final strikerPromptStillVisible = find.text('Who will face the first ball?');
  print('    [toss] Striker prompt still visible: ${strikerPromptStillVisible.evaluate().isNotEmpty}');
  if (strikerPromptStillVisible.evaluate().isEmpty) {
    print('    [toss] Re-selecting openers...');
    final reOpener1 = find.textContaining(battingOpener1);
    if (reOpener1.evaluate().isNotEmpty) {
      await tester.tap(reOpener1.first);
      await tester.pump();
    }
    final reOpener2 = find.textContaining(battingOpener2);
    if (reOpener2.evaluate().isNotEmpty) {
      await tester.tap(reOpener2.first);
      await tester.pump();
    }
    await settle(tester);
    final reStrikerOption = find.text(battingOpener1);
    if (reStrikerOption.evaluate().length >= 2) {
      await tester.tap(reStrikerOption.last);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Re-selected striker');
    }
  }

  // Select bowler
  final bowlerOption = find.textContaining(openingBowler);
  print('    [toss] Bowler "$openingBowler" found: ${bowlerOption.evaluate().length}');
  if (bowlerOption.evaluate().isNotEmpty) {
    await tester.ensureVisible(bowlerOption.first);
    await tester.pumpAndSettle();
    await tester.tap(bowlerOption.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Selected bowler');
  } else {
    print('    [toss] WARNING: Bowler "$openingBowler" not found!');
    dumpVisibleTexts(tester, 'toss-noBowler', 50);
  }

  // Tap "Start Match"
  final filledButtons = find.byType(FilledButton);
  print('    [toss] FilledButtons found: ${filledButtons.evaluate().length}');
  if (filledButtons.evaluate().isNotEmpty) {
    final button = filledButtons.last.evaluate().first.widget as FilledButton;
    final isEnabled = button.onPressed != null;
    print('    [toss] Start Match button enabled: $isEnabled');
    if (isEnabled) {
      await tester.ensureVisible(filledButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(filledButtons.last);
      await visualPause(tester, 5000);
      await settle(tester);
      await visualPause(tester, 1000);
      await settle(tester);
      print('    [toss] Start Match tapped, waiting for scoring page...');
    } else {
      print('    [toss] ERROR: Start Match button is DISABLED!');
      dumpVisibleTexts(tester, 'toss-disabled', 50);
    }
  } else {
    print('    [toss] WARNING: No FilledButton found on toss page!');
    dumpVisibleTexts(tester, 'toss-noButton', 30);
  }

  // Verify scoring page loaded
  var scoringControls = find.byType(ScoringControls);
  for (var retry = 0; retry < 5 && scoringControls.evaluate().isEmpty; retry++) {
    print('    [toss] ScoringControls not found yet, retrying (${retry + 1}/5)...');
    await visualPause(tester, 1000);
    await settle(tester);
    scoringControls = find.byType(ScoringControls);
  }
  if (scoringControls.evaluate().isEmpty) {
    print('    [toss] ERROR: ScoringControls not found after toss!');
    dumpVisibleTexts(tester, 'toss-afterStart', 50);
  } else {
    print('    [toss] Scoring page loaded successfully');
  }
}

/// Select playing XI players if Next button is disabled (roster > playersPerSide).
Future<void> _selectPlayingXIIfNeeded(WidgetTester tester, int? playersPerSide) async {
  if (playersPerSide == null) return;
  await settle(tester);

  final filledButtons = find.byType(FilledButton);
  if (filledButtons.evaluate().isNotEmpty) {
    final button = filledButtons.last.evaluate().first.widget as FilledButton;
    if (button.onPressed != null) {
      print('    [toss] XI already pre-selected, Next is enabled');
      return;
    }
  }

  print('    [toss] Next disabled — selecting $playersPerSide players');
  final inkWells = find.byType(InkWell);
  final count = playersPerSide.clamp(0, inkWells.evaluate().length);
  for (var i = 0; i < count; i++) {
    await tester.ensureVisible(inkWells.at(i));
    await tester.tap(inkWells.at(i), warnIfMissed: false);
    await tester.pump();
  }
  await settle(tester);
}

/// Tap the Next/Start Match button in the toss wizard.
Future<void> _tapNextButton(WidgetTester tester) async {
  final filledButton = find.byType(FilledButton);
  if (filledButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(filledButton.last);
    await tester.pumpAndSettle();
    await tester.tap(filledButton.last);
    await settle(tester);
    await visualPause(tester);
  } else {
    final next = find.text('Next');
    if (next.evaluate().isNotEmpty) {
      await tester.tap(next);
      await settle(tester);
      await visualPause(tester);
    }
  }
}
