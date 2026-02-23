import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/utils/scoring_utils.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';

void main() {
  // ── isLegalDelivery ──────────────────────────────────────────────────

  group('ScoringUtils.isLegalDelivery', () {
    test('normal delivery is legal', () {
      expect(
        ScoringUtils.isLegalDelivery(isWide: false, isNoBall: false),
        true,
      );
    });

    test('wide is not legal', () {
      expect(
        ScoringUtils.isLegalDelivery(isWide: true, isNoBall: false),
        false,
      );
    });

    test('no-ball is not legal', () {
      expect(
        ScoringUtils.isLegalDelivery(isWide: false, isNoBall: true),
        false,
      );
    });

    test('penalty is not legal', () {
      expect(
        ScoringUtils.isLegalDelivery(
          isWide: false,
          isNoBall: false,
          isPenalty: true,
        ),
        false,
      );
    });

    test('wide + no-ball is not legal', () {
      expect(
        ScoringUtils.isLegalDelivery(isWide: true, isNoBall: true),
        false,
      );
    });
  });

  // ── calculateTotalRuns ───────────────────────────────────────────────

  group('ScoringUtils.calculateTotalRuns', () {
    test('all zeros returns 0', () {
      expect(ScoringUtils.calculateTotalRuns(), 0);
    });

    test('bat runs only', () {
      expect(ScoringUtils.calculateTotalRuns(runsFromBat: 4), 4);
    });

    test('wide runs only', () {
      expect(ScoringUtils.calculateTotalRuns(wideRuns: 1), 1);
    });

    test('no-ball runs only', () {
      expect(ScoringUtils.calculateTotalRuns(noBallRuns: 1), 1);
    });

    test('bye runs only', () {
      expect(ScoringUtils.calculateTotalRuns(byeRuns: 2), 2);
    });

    test('leg-bye runs only', () {
      expect(ScoringUtils.calculateTotalRuns(legByeRuns: 3), 3);
    });

    test('no-ball + bat runs', () {
      expect(
        ScoringUtils.calculateTotalRuns(runsFromBat: 4, noBallRuns: 1),
        5,
      );
    });

    test('wide + additional runs', () {
      expect(ScoringUtils.calculateTotalRuns(wideRuns: 3), 3);
    });

    test('all run types combined', () {
      expect(
        ScoringUtils.calculateTotalRuns(
          runsFromBat: 1,
          wideRuns: 0,
          noBallRuns: 1,
          byeRuns: 0,
          legByeRuns: 0,
        ),
        2,
      );
    });
  });

  // ── shouldSwapStrike ─────────────────────────────────────────────────

  group('ScoringUtils.shouldSwapStrike', () {
    test('dot ball does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        false,
      );
    });

    test('1 run swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 1,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        true,
      );
    });

    test('2 runs does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 2,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        false,
      );
    });

    test('3 runs swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 3,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        true,
      );
    });

    test('4 runs does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 4,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        false,
      );
    });

    test('6 runs does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 6,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        false,
      );
    });

    test('5 runs (overthrow) swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 5,
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        true,
      );
    });

    test('wide with 1 run (base penalty) swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: true,
          wideRuns: 1,
          isBye: false,
          isLegBye: false,
        ),
        true,
      );
    });

    test('wide with 2 runs does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: true,
          wideRuns: 2,
          isBye: false,
          isLegBye: false,
        ),
        false,
      );
    });

    test('wide with 3 runs swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: true,
          wideRuns: 3,
          isBye: false,
          isLegBye: false,
        ),
        true,
      );
    });

    test('1 bye swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: false,
          isBye: true,
          byeRuns: 1,
          isLegBye: false,
        ),
        true,
      );
    });

    test('2 byes does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: false,
          isBye: true,
          byeRuns: 2,
          isLegBye: false,
        ),
        false,
      );
    });

    test('1 leg-bye swaps', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: false,
          isBye: false,
          isLegBye: true,
          legByeRuns: 1,
        ),
        true,
      );
    });

    test('2 leg-byes does not swap', () {
      expect(
        ScoringUtils.shouldSwapStrike(
          runsFromBat: 0,
          isWide: false,
          isBye: false,
          isLegBye: true,
          legByeRuns: 2,
        ),
        false,
      );
    });
  });

  // ── isOverComplete ───────────────────────────────────────────────────

  group('ScoringUtils.isOverComplete', () {
    test('0 balls is not complete', () {
      expect(ScoringUtils.isOverComplete(0), false);
    });

    test('5 balls is not complete', () {
      expect(ScoringUtils.isOverComplete(5), false);
    });

    test('6 balls is complete', () {
      expect(ScoringUtils.isOverComplete(6), true);
    });

    test('7 balls is complete (edge case)', () {
      expect(ScoringUtils.isOverComplete(7), true);
    });
  });

  // ── checkInningsCompletion ───────────────────────────────────────────

  group('ScoringUtils.checkInningsCompletion', () {
    test('returns null when innings continues', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 5,
          playersPerSide: 11,
          totalBalls: 60,
          totalOvers: 20,
          totalRuns: 100,
          target: null,
          inningsNumber: 1,
        ),
        isNull,
      );
    });

    test('returns allOut when wickets reach threshold', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 10,
          playersPerSide: 11,
          totalBalls: 90,
          totalOvers: 20,
          totalRuns: 150,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.allOut,
      );
    });

    test('returns allOut for flexible team sizes (6-a-side)', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 5,
          playersPerSide: 6,
          totalBalls: 30,
          totalOvers: 10,
          totalRuns: 80,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.allOut,
      );
    });

    test('returns allOut for 8-a-side', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 7,
          playersPerSide: 8,
          totalBalls: 50,
          totalOvers: 15,
          totalRuns: 100,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.allOut,
      );
    });

    test('returns oversExhausted when max overs bowled', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 5,
          playersPerSide: 11,
          totalBalls: 120,
          totalOvers: 20,
          totalRuns: 180,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.oversExhausted,
      );
    });

    test('returns targetChased in 2nd innings when target met', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 3,
          playersPerSide: 11,
          totalBalls: 90,
          totalOvers: 20,
          totalRuns: 180,
          target: 180,
          inningsNumber: 2,
        ),
        InningsCompletionReason.targetChased,
      );
    });

    test('returns targetChased when target exceeded', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 2,
          playersPerSide: 11,
          totalBalls: 80,
          totalOvers: 20,
          totalRuns: 185,
          target: 180,
          inningsNumber: 2,
        ),
        InningsCompletionReason.targetChased,
      );
    });

    test('does not return targetChased in 1st innings', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 0,
          playersPerSide: 11,
          totalBalls: 60,
          totalOvers: 20,
          totalRuns: 200,
          target: 180,
          inningsNumber: 1,
        ),
        isNull,
      );
    });

    test('allOut takes priority over oversExhausted', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 10,
          playersPerSide: 11,
          totalBalls: 120,
          totalOvers: 20,
          totalRuns: 150,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.allOut,
      );
    });

    test('returns null when 1 short of allOut', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 9,
          playersPerSide: 11,
          totalBalls: 100,
          totalOvers: 20,
          totalRuns: 150,
          target: null,
          inningsNumber: 1,
        ),
        isNull,
      );
    });

    test('returns null when 1 ball short of overs', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 5,
          playersPerSide: 11,
          totalBalls: 119,
          totalOvers: 20,
          totalRuns: 170,
          target: null,
          inningsNumber: 1,
        ),
        isNull,
      );
    });

    test('returns null in 2nd innings when 1 short of target', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 3,
          playersPerSide: 11,
          totalBalls: 80,
          totalOvers: 20,
          totalRuns: 179,
          target: 180,
          inningsNumber: 2,
        ),
        isNull,
      );
    });

    test('2-a-side allOut at 1 wicket', () {
      expect(
        ScoringUtils.checkInningsCompletion(
          totalWickets: 1,
          playersPerSide: 2,
          totalBalls: 10,
          totalOvers: 5,
          totalRuns: 20,
          target: null,
          inningsNumber: 1,
        ),
        InningsCompletionReason.allOut,
      );
    });
  });

  // ── isMaidenOver ─────────────────────────────────────────────────────

  group('ScoringUtils.isMaidenOver', () {
    Delivery makeDel({
      int runsFromBat = 0,
      bool isWide = false,
      bool isNoBall = false,
      bool isBye = false,
      int byeRuns = 0,
      bool isLegBye = false,
      int legByeRuns = 0,
    }) {
      return Delivery(
        id: 'del',
        inningsId: 'inn-1',
        overNumber: 1,
        ballNumber: 1,
        sequenceNumber: 1,
        strikerId: 'bat-1',
        nonStrikerId: 'bat-2',
        bowlerId: 'bowl-1',
        runsFromBat: runsFromBat,
        isWide: isWide,
        wideRuns: isWide ? 1 : 0,
        isNoBall: isNoBall,
        noBallRuns: isNoBall ? 1 : 0,
        isBye: isBye,
        byeRuns: byeRuns,
        isLegBye: isLegBye,
        legByeRuns: legByeRuns,
      );
    }

    test('6 dot balls is a maiden', () {
      expect(
        ScoringUtils.isMaidenOver(List.generate(6, (_) => makeDel())),
        true,
      );
    });

    test('any bat runs breaks maiden', () {
      final dels = List.generate(5, (_) => makeDel())
        ..add(makeDel(runsFromBat: 1));
      expect(ScoringUtils.isMaidenOver(dels), false);
    });

    test('wide breaks maiden', () {
      final dels = List.generate(5, (_) => makeDel())
        ..add(makeDel(isWide: true));
      expect(ScoringUtils.isMaidenOver(dels), false);
    });

    test('no-ball breaks maiden', () {
      final dels = List.generate(5, (_) => makeDel())
        ..add(makeDel(isNoBall: true));
      expect(ScoringUtils.isMaidenOver(dels), false);
    });

    test('byes do NOT break maiden', () {
      final dels = List.generate(5, (_) => makeDel())
        ..add(makeDel(isBye: true, byeRuns: 2));
      expect(ScoringUtils.isMaidenOver(dels), true);
    });

    test('leg-byes do NOT break maiden', () {
      final dels = List.generate(5, (_) => makeDel())
        ..add(makeDel(isLegBye: true, legByeRuns: 1));
      expect(ScoringUtils.isMaidenOver(dels), true);
    });

    test('empty deliveries list is not maiden', () {
      expect(ScoringUtils.isMaidenOver([]), false);
    });
  });

  // ── isNextFreeHit ────────────────────────────────────────────────────

  group('ScoringUtils.isNextFreeHit', () {
    test('free hit after no-ball', () {
      expect(
        ScoringUtils.isNextFreeHit(
          previousWasNoBall: true,
          previousWasFreeHit: false,
          previousWasLegal: false,
        ),
        true,
      );
    });

    test('no free hit after legal delivery', () {
      expect(
        ScoringUtils.isNextFreeHit(
          previousWasNoBall: false,
          previousWasFreeHit: false,
          previousWasLegal: true,
        ),
        false,
      );
    });

    test('free hit persists through wide', () {
      expect(
        ScoringUtils.isNextFreeHit(
          previousWasNoBall: false,
          previousWasFreeHit: true,
          previousWasLegal: false,
        ),
        true,
      );
    });

    test('free hit consumed by legal delivery', () {
      expect(
        ScoringUtils.isNextFreeHit(
          previousWasNoBall: false,
          previousWasFreeHit: true,
          previousWasLegal: true,
        ),
        false,
      );
    });

    test('no-ball on free hit generates another free hit', () {
      expect(
        ScoringUtils.isNextFreeHit(
          previousWasNoBall: true,
          previousWasFreeHit: true,
          previousWasLegal: false,
        ),
        true,
      );
    });
  });

  // ── validateExtras ───────────────────────────────────────────────────

  group('ScoringUtils.validateExtras', () {
    test('no extras is valid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: false,
          isBye: false,
          isLegBye: false,
        ),
        isNull,
      );
    });

    test('wide only is valid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: true,
          isBye: false,
          isLegBye: false,
        ),
        isNull,
      );
    });

    test('bye only is valid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: false,
          isBye: true,
          isLegBye: false,
        ),
        isNull,
      );
    });

    test('leg-bye only is valid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: false,
          isBye: false,
          isLegBye: true,
        ),
        isNull,
      );
    });

    test('wide + bye is invalid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: true,
          isBye: true,
          isLegBye: false,
        ),
        isNotNull,
      );
    });

    test('wide + leg-bye is invalid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: true,
          isBye: false,
          isLegBye: true,
        ),
        isNotNull,
      );
    });

    test('bye + leg-bye is invalid', () {
      expect(
        ScoringUtils.validateExtras(
          isWide: false,
          isBye: true,
          isLegBye: true,
        ),
        isNotNull,
      );
    });
  });

  // ── validateBatterPair ───────────────────────────────────────────────

  group('ScoringUtils.validateBatterPair', () {
    test('different players is valid', () {
      expect(
        ScoringUtils.validateBatterPair(
          strikerId: 'bat-1',
          nonStrikerId: 'bat-2',
        ),
        isNull,
      );
    });

    test('same player is invalid', () {
      expect(
        ScoringUtils.validateBatterPair(
          strikerId: 'bat-1',
          nonStrikerId: 'bat-1',
        ),
        isNotNull,
      );
    });
  });
}
