import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_batter_sheet.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/wicket_dialog.dart';

import 'delivery_record.dart';

/// Default visual delay (ms) between UI taps for watching on device.
const defaultPauseMs = 300;

/// Visual pause for watching on device.
Future<void> visualPause(WidgetTester tester, [int ms = defaultPauseMs]) async {
  await tester.pump(Duration(milliseconds: ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Basic Tap Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Tap a run button (0, 1, 2, 3, 4, 6).
Future<void> tapRun(WidgetTester tester, int runs) async {
  final runButton = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('$runs'),
  );
  expect(runButton, findsOneWidget, reason: 'Run button $runs should exist');
  await tester.tap(runButton);
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Tap an extras button (WD, NB, B, LB).
Future<void> tapExtra(WidgetTester tester, String label) async {
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text(label),
  );
  expect(button, findsOneWidget, reason: 'Extras button $label should exist');
  await tester.tap(button);
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Confirm an extras panel selection.
Future<void> confirmExtra(WidgetTester tester) async {
  final confirmButton = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('Confirm'),
  );
  expect(confirmButton, findsOneWidget);
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
  await visualPause(tester);
}

/// Tap the wicket (W) button.
Future<void> tapWicket(WidgetTester tester) async {
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('W'),
  );
  expect(button, findsOneWidget);
  await tester.tap(button);
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
Future<void> selectBowler(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final bowlerName = find.descendant(
    of: find.byType(SelectBowlerSheet),
    matching: find.textContaining(name),
  );
  if (bowlerName.evaluate().isNotEmpty) {
    await tester.tap(bowlerName.first);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  await visualPause(tester, 500);
}

/// Select a batter in the SelectBatterSheet.
Future<void> selectBatter(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final batterName = find.descendant(
    of: find.byType(SelectBatterSheet),
    matching: find.textContaining(name),
  );
  if (batterName.evaluate().isNotEmpty) {
    await tester.tap(batterName.first);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  await visualPause(tester);
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

  // Step 3: Select bowler
  final bowlerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(bowler),
  );
  await tester.tap(bowlerRow);
  await tester.pumpAndSettle();
  await visualPause(tester);

  // Start Innings
  final startButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Start Innings'),
  );
  await tester.tap(startButton);
  await tester.pumpAndSettle();
  await visualPause(tester, 600);
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

  while (wickets < maxWickets && legalBalls < maxBalls) {
    // Check if match/innings is complete (modal appeared)
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty ||
        find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
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

        await selectBowler(tester, bowlerNames[bowlerIndex]);
      }
    }

    // Check again for completion modals
    await tester.pumpAndSettle();
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty ||
        find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
      break;
    }
  }
}
