/// Low-level scoring UI interaction primitives.
///
/// tapRun, tapExtra, tapWicket, selectBowler, selectBatter, tapUndo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_batter_sheet.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/wicket_dialog.dart';

import '../core/test_utils.dart';

/// Ensure no lingering bottom sheets are blocking ScoringControls.
Future<void> _ensureScoringControlsAccessible(WidgetTester tester) async {
  if (find.byType(SelectBowlerSheet).evaluate().isNotEmpty) {
    print('    [auto-clear] Stale SelectBowlerSheet — tapping first eligible bowler');
    final sheet = find.byType(SelectBowlerSheet);
    final inkWells = find.descendant(of: sheet, matching: find.byType(InkWell));
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.first, warnIfMissed: false);
      await settle(tester);
    } else {
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
    }
  }

  if (find.byType(SelectBatterSheet).evaluate().isNotEmpty) {
    print('    [auto-clear] Stale SelectBatterSheet — tapping first available batter');
    final sheet = find.byType(SelectBatterSheet);
    final inkWells = find.descendant(of: sheet, matching: find.byType(InkWell));
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.first, warnIfMissed: false);
      await settle(tester);
    } else {
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
    }
  }
}

/// Tap a run button (0, 1, 2, 3, 4, 6).
Future<void> tapRun(WidgetTester tester, int runs) async {
  await _ensureScoringControlsAccessible(tester);
  final runButton = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('$runs'),
  );
  expect(runButton, findsOneWidget, reason: 'Run button $runs should exist');
  await tester.ensureVisible(runButton);
  await tester.tap(runButton, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
}

/// Tap an extras button (WD, NB, B, LB).
Future<void> tapExtra(WidgetTester tester, String label) async {
  await _ensureScoringControlsAccessible(tester);
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text(label),
  );
  expect(button, findsOneWidget, reason: 'Extras button $label should exist');
  await tester.ensureVisible(button);
  await tester.tap(button, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
}

/// Confirm an extras panel selection.
Future<void> confirmExtra(WidgetTester tester) async {
  await settle(tester);
  final confirmButton = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('Confirm'),
  );
  if (confirmButton.evaluate().isEmpty) {
    print('    [confirmExtra] ExtrasPanel not found — pumping extra frames');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(ExtrasPanel).evaluate().isNotEmpty) break;
    }
    final retryConfirm = find.descendant(
      of: find.byType(ExtrasPanel),
      matching: find.text('Confirm'),
    );
    if (retryConfirm.evaluate().isEmpty) {
      fail('[confirmExtra] ExtrasPanel not found after 2s of retries — '
          'extras was tapped but never confirmed, match state is corrupt');
    }
    await tester.tap(retryConfirm);
  } else {
    await tester.tap(confirmButton);
  }
  await settle(tester);
  await visualPause(tester);
}

/// Confirm extras panel with a specific run value (tap the run chip first).
Future<void> confirmExtraWithRuns(WidgetTester tester, int runs) async {
  await settle(tester);
  final runChip = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('$runs'),
  );
  if (runChip.evaluate().isNotEmpty) {
    await tester.tap(runChip.first);
    await settle(tester);
  }
  await confirmExtra(tester);
}

/// Tap the wicket (W) button.
Future<void> tapWicket(WidgetTester tester) async {
  await _ensureScoringControlsAccessible(tester);
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('W'),
  );
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.tap(button, warnIfMissed: false);
  await settle(tester);
  await visualPause(tester);
}

/// Select a dismissal type in the WicketDialog.
Future<void> selectDismissalType(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.text(label),
  );
  expect(chip, findsOneWidget, reason: 'Dismissal type $label should exist');
  await tester.tap(chip);
  await settle(tester);
  await visualPause(tester);
}

/// Tap the primary (confirm) button in the WicketDialog.
Future<void> tapWicketConfirm(WidgetTester tester) async {
  final buttons = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.byType(FilledButton),
  );
  expect(buttons, findsOneWidget);
  await tester.tap(buttons);
  await settle(tester);
  await visualPause(tester);
}

/// Select a bowler in the SelectBowlerSheet.
///
/// Waits up to 3 seconds for the sheet to appear, then selects the named bowler.
/// If preferred bowler isn't found, tries [fallbackNames], then first available.
Future<void> selectBowler(WidgetTester tester, String name,
    {List<String>? fallbackNames}) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(SelectBowlerSheet).evaluate().isNotEmpty) break;
  }
  await settle(tester);

  if (find.byType(SelectBowlerSheet).evaluate().isEmpty) {
    // Sheet may not appear if auto-selected (1 eligible bowler).
    print('    [selectBowler] No SelectBowlerSheet — likely auto-selected');
    return;
  }

  final bowlerName = find.descendant(
    of: find.byType(SelectBowlerSheet),
    matching: find.textContaining(name),
  );
  if (bowlerName.evaluate().isNotEmpty) {
    await tester.ensureVisible(bowlerName.first);
    await tester.tap(bowlerName.first, warnIfMissed: false);
    await settle(tester);
    await visualPause(tester, 300);
    return;
  }

  print('    [selectBowler] "$name" not in sheet, trying fallbacks');
  for (final fallback in (fallbackNames ?? <String>[])) {
    final alt = find.descendant(
      of: find.byType(SelectBowlerSheet),
      matching: find.textContaining(fallback),
    );
    if (alt.evaluate().isNotEmpty) {
      await tester.ensureVisible(alt.first);
      await tester.tap(alt.first, warnIfMissed: false);
      await settle(tester);
      await visualPause(tester, 300);
      print('    [selectBowler] Selected fallback: $fallback');
      return;
    }
  }

  // Last resort: tap first InkWell in the sheet
  final anyRow = find.descendant(
    of: find.byType(SelectBowlerSheet),
    matching: find.byType(InkWell),
  );
  if (anyRow.evaluate().isNotEmpty) {
    await tester.tap(anyRow.first, warnIfMissed: false);
    await settle(tester);
    print('    [selectBowler] Selected first available bowler (last resort)');
    return;
  }
  fail('[selectBowler] Could not select any bowler — '
      'no InkWell found in SelectBowlerSheet');
}

/// Select a batter in the SelectBatterSheet.
Future<void> selectBatter(WidgetTester tester, String name) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(SelectBatterSheet).evaluate().isNotEmpty) break;
  }
  await settle(tester);

  if (find.byType(SelectBatterSheet).evaluate().isEmpty) {
    // Sheet may not appear if auto-selected (1 available batter).
    print('    [selectBatter] No SelectBatterSheet — likely auto-selected');
    return;
  }

  final batterName = find.descendant(
    of: find.byType(SelectBatterSheet),
    matching: find.textContaining(name),
  );
  if (batterName.evaluate().isNotEmpty) {
    await tester.ensureVisible(batterName.first);
    await tester.tap(batterName.first, warnIfMissed: false);
    await settle(tester);
    await visualPause(tester);
  } else {
    final anyRow = find.descendant(
      of: find.byType(SelectBatterSheet),
      matching: find.byType(InkWell),
    );
    if (anyRow.evaluate().isNotEmpty) {
      await tester.tap(anyRow.first, warnIfMissed: false);
      await settle(tester);
      print('    [selectBatter] "$name" not found — selected first available');
    } else {
      fail('[selectBatter] "$name" not found and no InkWell available in '
          'SelectBatterSheet');
    }
  }
}

/// Tap the undo button on the scoring page.
///
/// Returns true if undo was successfully tapped, false if button was
/// not found or was disabled.
Future<bool> tapUndo(WidgetTester tester) async {
  final undoButton = find.byIcon(Icons.undo);
  if (undoButton.evaluate().isEmpty) {
    print('    [undo] Undo button not found');
    return false;
  }

  final iconButtonFinder = find.ancestor(
    of: undoButton,
    matching: find.byType(IconButton),
  );
  if (iconButtonFinder.evaluate().isNotEmpty) {
    final iconButton = tester.widget<IconButton>(iconButtonFinder.first);
    if (iconButton.onPressed == null) {
      print('    [undo] Undo button is disabled');
      return false;
    }
  }

  await tester.tap(undoButton.first);
  await settle(tester);
  await visualPause(tester);
  print('    [undo] Undo tapped successfully');
  return true;
}
