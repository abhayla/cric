/// Modal interaction helpers — innings transition, match complete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';

import '../core/test_utils.dart';

/// Complete the innings transition modal.
Future<void> completeInningsTransition(
  WidgetTester tester, {
  required String striker,
  required String nonStriker,
  required String bowler,
}) async {
  await tester.pumpAndSettle();
  await visualPause(tester, 600);

  // Step 1: Summary -> Next
  expect(find.byType(InningsTransitionModal), findsOneWidget);
  final nextButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
  await visualPause(tester);

  // Step 2: Select 2 openers
  final strikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(striker),
  );
  await tester.tap(strikerRow);
  await tester.pumpAndSettle();
  await visualPause(tester);

  final nonStrikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(nonStriker),
  );
  await tester.tap(nonStrikerRow);
  await tester.pumpAndSettle();
  await visualPause(tester);

  // Next -> Step 3
  final nextButton2 = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton2);
  await tester.pumpAndSettle();
  await visualPause(tester);

  // Step 3: Select bowler
  final bowlerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(bowler),
  );
  expect(bowlerRow, findsOneWidget, reason: 'Bowler "$bowler" must exist');
  await tester.ensureVisible(bowlerRow);
  await tester.pumpAndSettle();
  await tester.tap(bowlerRow);
  await tester.pumpAndSettle();
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
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
  }

  if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
    print('    [captureResult] No MatchCompleteModal found');
    return null;
  }

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
            text.contains('Draw'))) {
      result = text;
      break;
    }
  }

  if (result != null) {
    print('    [captureResult] Match result: $result');
  } else {
    print('    [captureResult] Could not find result text in modal');
  }
  return result;
}

/// Dismiss the match complete modal.
///
/// Tries "Back to Home" → "Done" → any FilledButton.
Future<void> dismissMatchCompleteModal(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
  }

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
