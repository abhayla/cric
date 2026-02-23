import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_batter_sheet.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/wicket_dialog.dart';

import 'delivery_record.dart';

/// Default visual delay (ms) between UI taps for watching on device.
const defaultPauseMs = 300;

/// Visual pause for watching on device.
Future<void> visualPause(WidgetTester tester, [int ms = defaultPauseMs]) async {
  await tester.pump(Duration(milliseconds: ms));
}

/// Like pumpAndSettle but with a timeout — won't hang on infinite animations.
Future<void> settle(WidgetTester tester, {int fallbackMs = 2000}) async {
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  } catch (_) {
    for (var i = 0; i < (fallbackMs ~/ 100); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Basic Tap Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Ensure no lingering bottom sheets are blocking ScoringControls.
///
/// On small-viewport devices, a stale SelectBowlerSheet or SelectBatterSheet
/// may cover the scoring controls. This helper detects and dismisses them.
Future<void> _ensureScoringControlsAccessible(WidgetTester tester) async {
  // Check for bowler sheet (uses InkWell rows, not ListTile)
  if (find.byType(SelectBowlerSheet).evaluate().isNotEmpty) {
    print('    [auto-clear] Stale SelectBowlerSheet — tapping first eligible bowler');
    final sheet = find.byType(SelectBowlerSheet);
    final inkWells = find.descendant(of: sheet, matching: find.byType(InkWell));
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.first, warnIfMissed: false);
      await settle(tester);
    } else {
      // Tap outside the sheet to dismiss it
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
    }
  }

  // Check for batter sheet (uses InkWell rows, not ListTile)
  if (find.byType(SelectBatterSheet).evaluate().isNotEmpty) {
    print('    [auto-clear] Stale SelectBatterSheet — tapping first available batter');
    final sheet = find.byType(SelectBatterSheet);
    final inkWells = find.descendant(of: sheet, matching: find.byType(InkWell));
    if (inkWells.evaluate().isNotEmpty) {
      await tester.tap(inkWells.first, warnIfMissed: false);
      await settle(tester);
    } else {
      // Tap outside the sheet to dismiss it
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
  await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Confirm an extras panel selection.
Future<void> confirmExtra(WidgetTester tester) async {
  // Wait briefly for the extras panel to fully render
  await settle(tester);
  final confirmButton = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('Confirm'),
  );
  if (confirmButton.evaluate().isEmpty) {
    // ExtrasPanel may not have opened (tap missed) — try re-opening
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
      print('    [confirmExtra] ExtrasPanel still not found — skipping');
      return;
    }
    await tester.tap(retryConfirm);
  } else {
    await tester.tap(confirmButton);
  }
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Confirm extras panel with a specific run value (tap the run chip first).
Future<void> confirmExtraWithRuns(WidgetTester tester, int runs) async {
  await settle(tester);
  // Tap the run chip inside ExtrasPanel
  final runChip = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('$runs'),
  );
  if (runChip.evaluate().isNotEmpty) {
    await tester.tap(runChip.first);
    await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Select a bowler in the SelectBowlerSheet.
///
/// Waits up to 3 seconds for the sheet to appear, then selects the named bowler.
/// If the preferred bowler isn't found, tries all bowlers in [fallbackNames].
Future<void> selectBowler(WidgetTester tester, String name,
    {List<String>? fallbackNames}) async {
  // Wait for the bowler sheet to appear (it may still be animating in)
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(SelectBowlerSheet).evaluate().isNotEmpty) break;
  }
  await settle(tester);

  if (find.byType(SelectBowlerSheet).evaluate().isEmpty) {
    print('    [selectBowler] No SelectBowlerSheet found — skipping');
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

  // Preferred bowler not found (e.g. ineligible) — try fallbacks
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
  // Last resort: tap the first InkWell in the sheet (bowler rows use InkWell)
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
  print('    [selectBowler] WARNING: Could not select any bowler!');
}

/// Select a batter in the SelectBatterSheet.
///
/// Waits up to 3 seconds for the sheet to appear, then selects the named batter.
Future<void> selectBatter(WidgetTester tester, String name) async {
  // Wait for the batter sheet to appear
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(SelectBatterSheet).evaluate().isNotEmpty) break;
  }
  await settle(tester);

  if (find.byType(SelectBatterSheet).evaluate().isEmpty) {
    print('    [selectBatter] No SelectBatterSheet found — skipping');
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
    // Try tapping first available batter as fallback (batter rows use InkWell)
    final anyRow = find.descendant(
      of: find.byType(SelectBatterSheet),
      matching: find.byType(InkWell),
    );
    if (anyRow.evaluate().isNotEmpty) {
      await tester.tap(anyRow.first, warnIfMissed: false);
      await settle(tester);
      print('    [selectBatter] "$name" not found — selected first available');
    } else {
      print('    [selectBatter] WARNING: "$name" not found in sheet!');
    }
  }
}

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

  // Step 3: Select bowler (may need scrolling if bowler is off-screen)
  final bowlerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(bowler),
  );
  expect(bowlerRow, findsOneWidget, reason: 'Bowler "$bowler" must exist');
  // Scroll the bowler into view before tapping
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

// ═══════════════════════════════════════════════════════════════════════════
// Random Innings Play
// ═══════════════════════════════════════════════════════════════════════════

/// Weighted random delivery type.
enum RandomDeliveryType {
  dot(30),     // 30% probability
  single(25),  // 25%
  two(15),     // 15%
  three(5),    // 5%
  four(10),    // 10%
  six(5),      // 5%
  wicket(5),   // 5%
  wide(3),     // 3%
  noBall(2);   // 2%

  const RandomDeliveryType(this.weight);
  final int weight;

  static RandomDeliveryType pick(Random random) {
    final totalWeight = RandomDeliveryType.values.fold(0, (s, v) => s + v.weight);
    var roll = random.nextInt(totalWeight);
    for (final type in RandomDeliveryType.values) {
      roll -= type.weight;
      if (roll < 0) return type;
    }
    return RandomDeliveryType.dot;
  }
}

/// Play a random innings of up to [totalOvers] overs with [playersPerSide] players.
///
/// Records deliveries using UI taps and tracks each delivery in [matchRecord].
/// Handles bowler rotation, wickets, and innings completion.
///
/// Returns when the innings is complete (all out, overs exhausted, or target chased).
Future<void> playRandomInnings({
  required WidgetTester tester,
  required MatchRecord matchRecord,
  required int inningsNumber,
  required int totalOvers,
  required int playersPerSide,
  required List<String> bowlerNames,
  required List<String> batterNames,
  int? magicOverNumber,
  Random? random,
}) async {
  final rng = random ?? Random(42);
  var wickets = 0;
  var legalBalls = 0;
  var currentOverBalls = 0;
  var bowlerIndex = 0;
  var lastBowlerIndex = -1;
  var nextBatterIndex = 2; // First 2 are openers

  final maxWickets = playersPerSide - 1;
  final maxBalls = totalOvers * 6;

  // Dismiss any sheet that may be open at the START of the innings
  // (e.g., bowler sheet if page initialized with bowlerId==null).
  // Only do this once — the per-over selectBowler / per-wicket selectBatter
  // calls handle subsequent sheets.
  await _dismissAnyOpenSheet(
    tester,
    bowlerNames: bowlerNames,
    batterNames: batterNames,
    bowlerIndex: bowlerIndex,
    nextBatterIndex: nextBatterIndex,
  );

  while (wickets < maxWickets && legalBalls < maxBalls) {
    // Check if match/innings is complete (modal appeared)
    await settle(tester);
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty ||
        find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
      print('  [innings $inningsNumber] Breaking: completion modal detected '
          '(legal=$legalBalls, wkts=$wickets)');
      break;
    }

    final overNumber = (legalBalls ~/ 6) + 1;
    final ballNumber = currentOverBalls + 1;

    // Pick random delivery
    var deliveryType = RandomDeliveryType.pick(rng);

    // Don't take wickets if we'd be all out on the last ball needed
    if (deliveryType == RandomDeliveryType.wicket && wickets >= maxWickets - 1) {
      // 50% chance to still allow it
      if (rng.nextBool()) {
        deliveryType = RandomDeliveryType.dot;
      }
    }

    final isMagicOver = magicOverNumber != null && overNumber == magicOverNumber;

    switch (deliveryType) {
      case RandomDeliveryType.dot:
        await tapRun(tester, 0);
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: 0,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.single:
        await tapRun(tester, 1);
        final runs = isMagicOver ? 2 : 1;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.two:
        await tapRun(tester, 2);
        final runs = isMagicOver ? 4 : 2;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.three:
        await tapRun(tester, 3);
        final runs = isMagicOver ? 6 : 3;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.four:
        await tapRun(tester, 4);
        final runs = isMagicOver ? 8 : 4;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs,
          isBoundaryFour: true,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.six:
        await tapRun(tester, 6);
        final runs = isMagicOver ? 12 : 6;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs,
          isBoundarySix: true,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.wicket:
        if (wickets < maxWickets) {
          await tapWicket(tester);
          await selectDismissalType(tester, 'Bowled');
          await tapWicketConfirm(tester);
          matchRecord.addDelivery(inningsNumber, DeliveryRecord(
            isWicket: true,
            overNumber: overNumber,
            ballNumber: ballNumber,
            isMagicOver: isMagicOver,
          ));
          wickets++;
          legalBalls++;
          currentOverBalls++;

          // Select new batter if not all out
          if (wickets < maxWickets && nextBatterIndex < batterNames.length) {
            await selectBatter(tester, batterNames[nextBatterIndex]);
            nextBatterIndex++;
          }
        }

      case RandomDeliveryType.wide:
        await tapExtra(tester, 'WD');
        await confirmExtra(tester);
        final runs = isMagicOver ? 2 : 1;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          isWide: true,
          wideRuns: runs,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        // Wide is not legal — no ball count increment

      case RandomDeliveryType.noBall:
        await tapExtra(tester, 'NB');
        await confirmExtra(tester);
        final runs = isMagicOver ? 2 : 1;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          isNoBall: true,
          noBallRuns: runs,
          overNumber: overNumber,
          ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        // No-ball is not legal — no ball count increment
    }

    // Check for over completion
    if (currentOverBalls >= 6) {
      final overNum = legalBalls ~/ 6;
      print('  [innings $inningsNumber] Over $overNum complete '
          '(legal=$legalBalls, wkts=$wickets)');
      currentOverBalls = 0;

      // Need to select bowler for next over (if innings not complete)
      if (legalBalls < maxBalls && wickets < maxWickets) {
        // Rotate bowlers, skip last bowler (consecutive-over rule)
        var nextBowlerIdx = (bowlerIndex + 1) % bowlerNames.length;
        if (nextBowlerIdx == lastBowlerIndex) {
          nextBowlerIdx = (nextBowlerIdx + 1) % bowlerNames.length;
        }
        lastBowlerIndex = bowlerIndex;
        bowlerIndex = nextBowlerIdx;

        await selectBowler(tester, bowlerNames[bowlerIndex],
            fallbackNames: bowlerNames);
      }
    }

    // Check again for completion modals
    await settle(tester);
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty ||
        find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
      break;
    }
  }
}

/// Dismiss any auto-opened bowler or batter selection bottom sheets.
///
/// The ScoringPage auto-opens these sheets when state changes trigger
/// `needsNewBowler` or `needsNewBatter`. If one is open, select the
/// appropriate player to dismiss it before continuing.
Future<void> _dismissAnyOpenSheet(
  WidgetTester tester, {
  required List<String> bowlerNames,
  required List<String> batterNames,
  required int bowlerIndex,
  required int nextBatterIndex,
}) async {
  // Use pumpAndSettle to ensure all animations (including sheet show/pop)
  // have completed before checking the widget tree.
  await settle(tester);

  // Check for bowler selection sheet
  if (find.byType(SelectBowlerSheet).evaluate().isNotEmpty) {
    print('    [auto-dismiss] SelectBowlerSheet detected — selecting bowler');
    final bowlerName = bowlerNames[bowlerIndex % bowlerNames.length];
    final bowler = find.descendant(
      of: find.byType(SelectBowlerSheet),
      matching: find.textContaining(bowlerName),
    );
    if (bowler.evaluate().isNotEmpty) {
      await tester.ensureVisible(bowler.first);
      await tester.tap(bowler.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      await visualPause(tester, 500);
      print('    [auto-dismiss] Selected bowler: $bowlerName');
    } else {
      // Try any eligible bowler in the sheet
      for (final name in bowlerNames) {
        final alt = find.descendant(
          of: find.byType(SelectBowlerSheet),
          matching: find.textContaining(name),
        );
        if (alt.evaluate().isNotEmpty) {
          await tester.ensureVisible(alt.first);
          await tester.tap(alt.first, warnIfMissed: false);
          await tester.pumpAndSettle();
          await visualPause(tester, 500);
          print('    [auto-dismiss] Selected fallback bowler: $name');
          break;
        }
      }
    }
  }

  // Check for batter selection sheet
  if (find.byType(SelectBatterSheet).evaluate().isNotEmpty) {
    print('    [auto-dismiss] SelectBatterSheet detected — selecting batter');
    if (nextBatterIndex < batterNames.length) {
      final batterName = batterNames[nextBatterIndex];
      final batter = find.descendant(
        of: find.byType(SelectBatterSheet),
        matching: find.textContaining(batterName),
      );
      if (batter.evaluate().isNotEmpty) {
        await tester.ensureVisible(batter.first);
        await tester.tap(batter.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        await visualPause(tester, 500);
        print('    [auto-dismiss] Selected batter: $batterName');
      }
    }
  }
}
