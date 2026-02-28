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

  // Wait for bottom sheet with search field to load
  await waitForFinder(tester, find.text('Search teams'),
      timeoutMs: 10000, intervalMs: 200);
  await settle(tester);

  // Type team name into the search field to filter the list.
  // Find search field via hint text to avoid hitting the venue TextField.
  final searchField = find.ancestor(
    of: find.text('Search teams'),
    matching: find.byType(TextField),
  );
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField.first, teamName);
    await settle(tester);
    await dismissKeyboard(tester);
    await settle(tester);
  }

  // Find the exact team name inside a ListTile (not in the search field).
  final teamTexts = find.text(teamName);
  Finder? targetTile;
  for (final element in teamTexts.evaluate()) {
    final listTile = find.ancestor(
      of: find.byWidget(element.widget),
      matching: find.byType(ListTile),
    );
    if (listTile.evaluate().isNotEmpty) {
      targetTile = listTile;
      break;
    }
  }

  if (targetTile != null && targetTile.evaluate().isNotEmpty) {
    await tester.ensureVisible(targetTile.first);
    await settle(tester);
    await tester.tap(targetTile.first, warnIfMissed: false);
    await settle(tester);
    await visualPause(tester, 500);
    print('    [teamPicker] Selected ${isHome ? "Team A" : "Team B"}: $teamName');
  } else {
    dumpVisibleTexts(tester, 'teamPicker-notFound', 40);
    fail('Team "$teamName" must be found in the team picker list');
  }
}

/// Complete the Match Setup page by tapping "Proceed to Toss".
Future<void> completeMatchSetup(WidgetTester tester) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await settle(tester);
  await visualPause(tester, 300);

  final proceedButton = find.text('Proceed to Toss');
  expect(proceedButton, findsAtLeast(1),
      reason: 'Match setup page should show "Proceed to Toss" button');

  // SliverAppBar absorbs taps in integration tests when it overlaps content.
  // Invoking onPressed directly is the standard workaround.
  final filledButtonFinder = find.widgetWithText(FilledButton, 'Proceed to Toss');
  if (filledButtonFinder.evaluate().isNotEmpty) {
    final button = tester.widget<FilledButton>(filledButtonFinder.first);
    if (button.onPressed != null) {
      print('    [matchSetup] Invoking Proceed to Toss via onPressed');
      button.onPressed!();
    }
  } else {
    await tester.ensureVisible(proceedButton);
    await settle(tester);
    await tester.tap(proceedButton, warnIfMissed: false);
  }
  await settle(tester);
  await visualPause(tester, 2000);

  // Wait for toss wizard to load — navigation from match setup may be async
  await waitForFinder(tester, find.text('Who won the toss?'),
      timeoutMs: 15000, intervalMs: 500);

  final tossText = find.text('Who won the toss?');
  expect(tossText, findsOneWidget,
      reason: 'Toss wizard Step 1 ("Who won the toss?") should appear after proceeding');
  print('    [matchSetup] Toss wizard loaded');
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
    await settle(tester);
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
    await settle(tester);
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
      await settle(tester);
      await tester.tap(strikerOption.last);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (tapped last of ${strikerOption.evaluate().length})');
    } else if (strikerOption.evaluate().isNotEmpty) {
      await tester.ensureVisible(strikerOption.first);
      await settle(tester);
      await tester.tap(strikerOption.first);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (single match)');
    }
  } else {
    print('    [toss] WARNING: Striker prompt not found!');
  }

  // TECH DEBT: Defensive re-selection to handle a race condition in the toss
  // wizard UI where selecting a striker can deselect the openers. Root cause
  // suspected in TossWizardNotifier state transitions — investigate separately.
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
    await settle(tester);
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
      await settle(tester);
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
  expect(scoringControls, findsOneWidget,
      reason: 'Scoring page (ScoringControls) must load after completing toss');
  print('    [toss] Scoring page loaded successfully');
}

/// Select playing XI players if Next button is disabled (roster > playersPerSide).
///
/// Waits up to 15s for roster player rows to appear and auto-select (when
/// roster.length == playersPerSide). If auto-select doesn't kick in, falls
/// back to tapping player row InkWells with circular checkbox indicators.
Future<void> _selectPlayingXIIfNeeded(WidgetTester tester, int? playersPerSide) async {
  if (playersPerSide == null) return;
  await settle(tester);

  // Wait up to 15s for roster to load and auto-select all players.
  // Check both: (a) Next button enabled (auto-select worked), and
  // (b) player rows appeared (roster loaded, manual select possible).
  var playerRowsFound = false;
  for (var attempt = 0; attempt < 30; attempt++) {
    // Check if Next is already enabled (auto-select when roster == playersPerSide)
    final filledButtons = find.byType(FilledButton);
    if (filledButtons.evaluate().isNotEmpty) {
      final button = filledButtons.last.evaluate().first.widget as FilledButton;
      if (button.onPressed != null) {
        print('    [toss] XI auto-selected (Next enabled after ${attempt * 500}ms)');
        return;
      }
    }

    // Check if player rows have appeared (CircleAvatar inside the XI step)
    final avatars = find.byType(CircleAvatar);
    if (avatars.evaluate().length >= 2) {
      playerRowsFound = true;
      break;
    }

    await tester.pump(const Duration(milliseconds: 500));
  }

  if (!playerRowsFound) {
    // Check again if Next became enabled during final pump
    final filledButtons = find.byType(FilledButton);
    if (filledButtons.evaluate().isNotEmpty) {
      final button = filledButtons.last.evaluate().first.widget as FilledButton;
      if (button.onPressed != null) {
        print('    [toss] XI auto-selected (Next enabled at end of wait)');
        return;
      }
    }
    print('    [toss] ERROR: No player rows appeared after 15s — roster is empty!');
    print('    [toss] This usually means the team roster API call failed silently.');
    dumpVisibleTexts(tester, 'toss-emptyRoster', 50);
    fail('Playing XI roster is empty — team roster fetch likely failed. '
        'Check [Router] debug logs for "Failed to fetch team rosters" error.');
  }

  // Roster loaded but auto-select didn't work — manually tap player rows.
  print('    [toss] Next still disabled — selecting players manually');

  // Player row InkWells have borderRadius(12) and contain a circular checkbox.
  // Count all matching InkWells and tap up to playersPerSide.
  final allInkWells = find.byType(InkWell);
  var selected = 0;
  for (var i = 0; i < allInkWells.evaluate().length && selected < playersPerSide; i++) {
    final inkWellElement = allInkWells.at(i).evaluate().first;
    final inkWellWidget = inkWellElement.widget as InkWell;

    // Player row InkWells have borderRadius(12) — stepper/nav InkWells don't
    if (inkWellWidget.borderRadius == BorderRadius.circular(12)) {
      await tester.ensureVisible(allInkWells.at(i));
      await tester.tap(allInkWells.at(i), warnIfMissed: false);
      await tester.pump();
      selected++;
    }
  }
  print('    [toss] Manually selected $selected players');
  if (selected == 0) {
    print('    [toss] WARNING: 0 players selected via InkWell(borderRadius:12) fallback');
    dumpVisibleTexts(tester, 'toss-noSelection', 60);
  }
  await settle(tester);
}

/// Tap the Next/Start Match button in the toss wizard.
Future<void> _tapNextButton(WidgetTester tester) async {
  final filledButton = find.byType(FilledButton);
  if (filledButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(filledButton.last);
    await settle(tester);
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
