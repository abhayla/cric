/// Random innings scoring flow — weighted random deliveries.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_batter_sheet.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';

import '../core/test_utils.dart';
import '../helpers/scoring.dart';
import '../models/delivery_record.dart';

/// Weighted random delivery type.
enum RandomDeliveryType {
  dot(30),
  single(25),
  two(15),
  three(5),
  four(10),
  six(5),
  wicket(5),
  wide(3),
  noBall(2);

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

/// Play a random innings of up to [totalOvers] overs.
///
/// Records deliveries via UI taps, tracks each delivery in [matchRecord].
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

  // Dismiss any sheet open at start of innings
  await _dismissAnyOpenSheet(
    tester,
    bowlerNames: bowlerNames,
    batterNames: batterNames,
    bowlerIndex: bowlerIndex,
    nextBatterIndex: nextBatterIndex,
  );

  while (wickets < maxWickets && legalBalls < maxBalls) {
    // Check if match/innings is complete
    await settle(tester);
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty ||
        find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
      print('  [innings $inningsNumber] Breaking: completion modal detected '
          '(legal=$legalBalls, wkts=$wickets)');
      break;
    }

    final overNumber = (legalBalls ~/ 6) + 1;
    final ballNumber = currentOverBalls + 1;

    var deliveryType = RandomDeliveryType.pick(rng);

    // Don't take wickets if nearly all out
    if (deliveryType == RandomDeliveryType.wicket && wickets >= maxWickets - 1) {
      if (rng.nextBool()) deliveryType = RandomDeliveryType.dot;
    }

    final isMagicOver = magicOverNumber != null && overNumber == magicOverNumber;

    switch (deliveryType) {
      case RandomDeliveryType.dot:
        await tapRun(tester, 0);
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: 0, overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.single:
        await tapRun(tester, 1);
        final runs = isMagicOver ? 2 : 1;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs, overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.two:
        await tapRun(tester, 2);
        final runs = isMagicOver ? 4 : 2;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs, overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.three:
        await tapRun(tester, 3);
        final runs = isMagicOver ? 6 : 3;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs, overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.four:
        await tapRun(tester, 4);
        final runs = isMagicOver ? 8 : 4;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs, isBoundaryFour: true,
          overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
        legalBalls++;
        currentOverBalls++;

      case RandomDeliveryType.six:
        await tapRun(tester, 6);
        final runs = isMagicOver ? 12 : 6;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          runsFromBat: runs, isBoundarySix: true,
          overNumber: overNumber, ballNumber: ballNumber,
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
            isWicket: true, overNumber: overNumber, ballNumber: ballNumber,
            isMagicOver: isMagicOver,
          ));
          wickets++;
          legalBalls++;
          currentOverBalls++;

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
          isWide: true, wideRuns: runs,
          overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));

      case RandomDeliveryType.noBall:
        await tapExtra(tester, 'NB');
        await confirmExtra(tester);
        final runs = isMagicOver ? 2 : 1;
        matchRecord.addDelivery(inningsNumber, DeliveryRecord(
          isNoBall: true, noBallRuns: runs,
          overNumber: overNumber, ballNumber: ballNumber,
          isMagicOver: isMagicOver,
        ));
    }

    // Check for over completion
    if (currentOverBalls >= 6) {
      final overNum = legalBalls ~/ 6;
      print('  [innings $inningsNumber] Over $overNum complete '
          '(legal=$legalBalls, wkts=$wickets)');
      currentOverBalls = 0;

      if (legalBalls < maxBalls && wickets < maxWickets) {
        // Rotate bowlers, skip last bowler
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

  // Final settle to let any pending state changes (over/innings/match completion) process.
  // Use extra-long settle because async delivery processing (WS publish, server sync,
  // completion callbacks) can lag behind the test's tap cadence by several seconds.
  await settle(tester, pumpCount: 20);
  await tester.pump(const Duration(seconds: 3));
  await settle(tester, pumpCount: 20);
}

/// Dismiss any auto-opened bowler or batter selection sheets.
Future<void> _dismissAnyOpenSheet(
  WidgetTester tester, {
  required List<String> bowlerNames,
  required List<String> batterNames,
  required int bowlerIndex,
  required int nextBatterIndex,
}) async {
  await settle(tester);

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
      await settle(tester);
      await visualPause(tester, 500);
      print('    [auto-dismiss] Selected bowler: $bowlerName');
    } else {
      for (final name in bowlerNames) {
        final alt = find.descendant(
          of: find.byType(SelectBowlerSheet),
          matching: find.textContaining(name),
        );
        if (alt.evaluate().isNotEmpty) {
          await tester.ensureVisible(alt.first);
          await tester.tap(alt.first, warnIfMissed: false);
          await settle(tester);
          await visualPause(tester, 500);
          print('    [auto-dismiss] Selected fallback bowler: $name');
          break;
        }
      }
    }
  }

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
        await settle(tester);
        await visualPause(tester, 500);
        print('    [auto-dismiss] Selected batter: $batterName');
      }
    }
  }
}
