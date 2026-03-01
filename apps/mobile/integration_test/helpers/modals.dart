/// Modal interaction helpers — innings transition, match complete, super over.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/super_over_setup_wizard.dart';

import '../core/test_utils.dart';

/// Complete the innings transition modal.
Future<void> completeInningsTransition(
  WidgetTester tester, {
  required String striker,
  required String nonStriker,
  required String bowler,
}) async {
  await settle(tester);
  await visualPause(tester, 600);

  // Step 1: Summary -> Next
  expect(find.byType(InningsTransitionModal), findsOneWidget);
  final nextButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton);
  await settle(tester);
  await visualPause(tester);

  // Step 2: Select 2 openers
  final strikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(striker),
  );
  await tester.tap(strikerRow);
  await settle(tester);
  await visualPause(tester);

  final nonStrikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(nonStriker),
  );
  await tester.tap(nonStrikerRow);
  await settle(tester);
  await visualPause(tester);

  // Next -> Step 3
  final nextButton2 = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton2);
  await settle(tester);
  await visualPause(tester);

  // Step 3: Select bowler
  final bowlerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(bowler),
  );
  expect(bowlerRow, findsOneWidget, reason: 'Bowler "$bowler" must exist');
  await tester.ensureVisible(bowlerRow);
  await settle(tester);
  await tester.tap(bowlerRow);
  await settle(tester);
  await visualPause(tester);

  // Start Innings
  final startButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Start Innings'),
  );
  await tester.tap(startButton);
  await settle(tester);
  await visualPause(tester, 1000);

  // Extra settle to ensure dialog pop animation fully completes
  await settle(tester);
}

/// Capture the match result text from the MatchCompleteModal.
///
/// Returns the result string (e.g. "Team1 won by 5 runs") or null if not found.
Future<String?> captureMatchCompleteResult(WidgetTester tester) async {
  // Clear any snackbars (sync errors, etc.) that might block the modal
  clearSnackBars(tester);
  await settle(tester);

  // Allow extra time for match completion — server sync errors or slow
  // completion callbacks can delay the modal appearance.
  // Clear snackbars repeatedly during the wait since sync errors can pile up.
  var found = await waitForFinder(tester, find.byType(MatchCompleteModal),
      timeoutMs: 20000, intervalMs: 500);

  if (!found) {
    // Second attempt: aggressive snackbar clearing + extra pumps to let async
    // delivery processing (WS publish, server sync) catch up.
    print('    [captureResult] MatchCompleteModal not found on first try, clearing snackbars and retrying...');
    clearSnackBars(tester);
    await settle(tester, pumpCount: 30);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester, pumpCount: 30);
    found = await waitForFinder(tester, find.byType(MatchCompleteModal),
        timeoutMs: 20000, intervalMs: 500);
  }

  if (!found) {
    // Dump visible texts for debugging
    dumpVisibleTexts(tester, 'captureMatchCompleteResult-noModal', 30);
  }

  expect(find.byType(MatchCompleteModal), findsOneWidget,
      reason: 'MatchCompleteModal should appear after match ends');

  final modalTexts = find.descendant(
    of: find.byType(MatchCompleteModal),
    matching: find.byType(Text),
  );

  String? result;
  for (final element in modalTexts.evaluate()) {
    final textWidget = element.widget as Text;
    final text = textWidget.data ?? textWidget.textSpan?.toPlainText();
    if (text != null &&
        (text.contains('won by') ||
            text.contains('Tied') ||
            text.contains('No Result') ||
            text.contains('Draw') ||
            text.contains('Abandoned'))) {
      result = text;
      break;
    }
  }

  expect(result, isNotNull,
      reason: 'MatchCompleteModal should contain a result text (won by/Tied/No Result/Draw)');
  print('    [captureResult] Match result: $result');
  return result;
}

/// Dismiss the match complete modal.
///
/// Tries "Back to Home" → "Done" → any FilledButton.
Future<void> dismissMatchCompleteModal(WidgetTester tester) async {
  await waitForFinder(tester, find.byType(MatchCompleteModal),
      timeoutMs: 10000, intervalMs: 500);

  if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
    print('    [matchComplete] No MatchCompleteModal found');
    return;
  }

  final backHome = find.text('Back to Home');
  if (backHome.evaluate().isNotEmpty) {
    await tester.tap(backHome.first);
    await settle(tester);
    return;
  }

  final done = find.text('Done');
  if (done.evaluate().isNotEmpty) {
    await tester.tap(done.first);
    await settle(tester);
    return;
  }

  final buttons = find.byType(FilledButton);
  if (buttons.evaluate().isNotEmpty) {
    await tester.tap(buttons.first);
    await settle(tester);
  }
}

/// Complete the Super Over Setup Wizard (3 steps).
///
/// Step 1: Select 2 batters from the batting team (tap by name).
/// Step 2: Select 1 bowler from the bowling team (tap by name).
/// Step 3: Confirm selections → tap "Start Super Over".
Future<void> completeSuperOverWizard(
  WidgetTester tester, {
  required String batter1,
  required String batter2,
  required String bowler,
}) async {
  // Wait for wizard to appear
  final found = await waitForFinder(
    tester,
    find.byType(SuperOverSetupWizard),
    timeoutMs: 15000,
    intervalMs: 500,
  );
  expect(found, isTrue,
      reason: 'SuperOverSetupWizard should appear after tied knockout match');
  print('    [superOver] Wizard appeared');

  // Step 1: Select 2 batters
  final batter1Text = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.textContaining(batter1),
  );
  expect(batter1Text, findsAtLeast(1),
      reason: 'Batter "$batter1" must exist in wizard');
  await tester.ensureVisible(batter1Text.first);
  await settle(tester);
  await tester.tap(batter1Text.first, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
  print('    [superOver] Step 1: Selected batter1 $batter1');

  final batter2Text = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.textContaining(batter2),
  );
  expect(batter2Text, findsAtLeast(1),
      reason: 'Batter "$batter2" must exist in wizard');
  await tester.ensureVisible(batter2Text.first);
  await settle(tester);
  await tester.tap(batter2Text.first, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
  print('    [superOver] Step 1: Selected batter2 $batter2');

  // Tap "Next" to go to Step 2
  final nextButton1 = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton1);
  await settle(tester);
  await visualPause(tester);
  print('    [superOver] Step 1 → Step 2');

  // Step 2: Select bowler
  final bowlerText = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.textContaining(bowler),
  );
  expect(bowlerText, findsAtLeast(1),
      reason: 'Bowler "$bowler" must exist in wizard');
  await tester.ensureVisible(bowlerText.first);
  await settle(tester);
  await tester.tap(bowlerText.first, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
  print('    [superOver] Step 2: Selected bowler $bowler');

  // Tap "Next" to go to Step 3
  final nextButton2 = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton2);
  await settle(tester);
  await visualPause(tester);
  print('    [superOver] Step 2 → Step 3');

  // Step 3: Confirm — tap "Start Super Over"
  final startButton = find.descendant(
    of: find.byType(SuperOverSetupWizard),
    matching: find.text('Start Super Over'),
  );
  expect(startButton, findsOneWidget,
      reason: 'Step 3 should show "Start Super Over" button');
  await tester.tap(startButton);
  await settle(tester);
  await visualPause(tester, 1000);
  // Extra settle to let wizard close and scoring page reload
  await settle(tester);
  print('    [superOver] Wizard completed — super over started');
}
