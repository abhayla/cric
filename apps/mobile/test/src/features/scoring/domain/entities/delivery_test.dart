import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/wicket_info.dart';

void main() {
  // ── DismissalType enum ────────────────────────────────────────────────

  group('DismissalType', () {
    test('has exactly 11 values', () {
      expect(DismissalType.values.length, 11);
    });

    test('IDs match server seed data (1-11)', () {
      expect(DismissalType.bowled.id, 1);
      expect(DismissalType.caught.id, 2);
      expect(DismissalType.lbw.id, 3);
      expect(DismissalType.runOut.id, 4);
      expect(DismissalType.stumped.id, 5);
      expect(DismissalType.hitWicket.id, 6);
      expect(DismissalType.caughtAndBowled.id, 7);
      expect(DismissalType.retiredHurt.id, 8);
      expect(DismissalType.retiredOut.id, 9);
      expect(DismissalType.timedOut.id, 10);
      expect(DismissalType.obstructingField.id, 11);
    });

    test('labels are correct', () {
      expect(DismissalType.bowled.label, 'Bowled');
      expect(DismissalType.caught.label, 'Caught');
      expect(DismissalType.lbw.label, 'LBW');
      expect(DismissalType.runOut.label, 'Run Out');
      expect(DismissalType.stumped.label, 'Stumped');
      expect(DismissalType.hitWicket.label, 'Hit Wicket');
      expect(DismissalType.caughtAndBowled.label, 'Caught & Bowled');
      expect(DismissalType.retiredHurt.label, 'Retired Hurt');
      expect(DismissalType.retiredOut.label, 'Retired Out');
      expect(DismissalType.timedOut.label, 'Timed Out');
      expect(DismissalType.obstructingField.label, 'Obstructing Field');
    });

    test('codes are correct', () {
      expect(DismissalType.bowled.code, 'b');
      expect(DismissalType.caught.code, 'c');
      expect(DismissalType.lbw.code, 'lbw');
      expect(DismissalType.runOut.code, 'ro');
      expect(DismissalType.stumped.code, 'st');
      expect(DismissalType.hitWicket.code, 'hw');
      expect(DismissalType.caughtAndBowled.code, 'c&b');
      expect(DismissalType.retiredHurt.code, 'rh');
      expect(DismissalType.retiredOut.code, 'ret');
      expect(DismissalType.timedOut.code, 'to');
      expect(DismissalType.obstructingField.code, 'of');
    });

    test('requiresFielder is correct', () {
      expect(DismissalType.bowled.requiresFielder, false);
      expect(DismissalType.caught.requiresFielder, true);
      expect(DismissalType.lbw.requiresFielder, false);
      expect(DismissalType.runOut.requiresFielder, true);
      expect(DismissalType.stumped.requiresFielder, true);
      expect(DismissalType.hitWicket.requiresFielder, false);
      expect(DismissalType.caughtAndBowled.requiresFielder, false);
      expect(DismissalType.retiredHurt.requiresFielder, false);
      expect(DismissalType.retiredOut.requiresFielder, false);
      expect(DismissalType.timedOut.requiresFielder, false);
      expect(DismissalType.obstructingField.requiresFielder, false);
    });

    test('bowlerCredited is correct', () {
      expect(DismissalType.bowled.bowlerCredited, true);
      expect(DismissalType.caught.bowlerCredited, true);
      expect(DismissalType.lbw.bowlerCredited, true);
      expect(DismissalType.runOut.bowlerCredited, false);
      expect(DismissalType.stumped.bowlerCredited, true);
      expect(DismissalType.hitWicket.bowlerCredited, true);
      expect(DismissalType.caughtAndBowled.bowlerCredited, true);
      expect(DismissalType.retiredHurt.bowlerCredited, false);
      expect(DismissalType.retiredOut.bowlerCredited, false);
      expect(DismissalType.timedOut.bowlerCredited, false);
      expect(DismissalType.obstructingField.bowlerCredited, false);
    });

    test('isMvpActive is true for id <= 9', () {
      for (final dt in DismissalType.values) {
        expect(dt.isMvpActive, dt.id <= 9, reason: '${dt.name} id=${dt.id}');
      }
    });

    test('isRealWicket excludes retired types and post-MVP', () {
      expect(DismissalType.bowled.isRealWicket, true);
      expect(DismissalType.caught.isRealWicket, true);
      expect(DismissalType.lbw.isRealWicket, true);
      expect(DismissalType.runOut.isRealWicket, true);
      expect(DismissalType.stumped.isRealWicket, true);
      expect(DismissalType.hitWicket.isRealWicket, true);
      expect(DismissalType.caughtAndBowled.isRealWicket, true);
      expect(DismissalType.retiredHurt.isRealWicket, false);
      expect(DismissalType.retiredOut.isRealWicket, false);
      expect(DismissalType.timedOut.isRealWicket, false);
      expect(DismissalType.obstructingField.isRealWicket, false);
    });

    test('isValidOnFreeHit is true only for runOut', () {
      for (final dt in DismissalType.values) {
        expect(
          dt.isValidOnFreeHit,
          dt == DismissalType.runOut,
          reason: dt.name,
        );
      }
    });

    test('isValidOnWide is true only for stumped and runOut', () {
      for (final dt in DismissalType.values) {
        expect(
          dt.isValidOnWide,
          dt == DismissalType.stumped || dt == DismissalType.runOut,
          reason: dt.name,
        );
      }
    });

    test('fromId returns correct values', () {
      for (final dt in DismissalType.values) {
        expect(DismissalType.fromId(dt.id), dt);
      }
    });

    test('fromId throws for unknown id', () {
      expect(() => DismissalType.fromId(0), throwsArgumentError);
      expect(() => DismissalType.fromId(99), throwsArgumentError);
    });

    test('fromCode returns correct values', () {
      for (final dt in DismissalType.values) {
        expect(DismissalType.fromCode(dt.code), dt);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => DismissalType.fromCode('xxx'), throwsArgumentError);
    });
  });

  // ── InningsCompletionReason enum ─────────────────────────────────────

  group('InningsCompletionReason', () {
    test('has exactly 5 values', () {
      expect(InningsCompletionReason.values.length, 5);
    });

    test('apiValues are correct', () {
      expect(InningsCompletionReason.allOut.apiValue, 'all_out');
      expect(InningsCompletionReason.oversExhausted.apiValue, 'overs_exhausted');
      expect(InningsCompletionReason.targetChased.apiValue, 'target_chased');
      expect(InningsCompletionReason.declared.apiValue, 'declared');
      expect(InningsCompletionReason.abandoned.apiValue, 'abandoned');
    });

    test('labels are correct', () {
      expect(InningsCompletionReason.allOut.label, 'All Out');
      expect(InningsCompletionReason.oversExhausted.label, 'Overs Exhausted');
      expect(InningsCompletionReason.targetChased.label, 'Target Chased');
      expect(InningsCompletionReason.declared.label, 'Declared');
    });

    test('fromApiValue parses correctly', () {
      expect(
        InningsCompletionReason.fromApiValue('all_out'),
        InningsCompletionReason.allOut,
      );
      expect(
        InningsCompletionReason.fromApiValue('overs_exhausted'),
        InningsCompletionReason.oversExhausted,
      );
      expect(
        InningsCompletionReason.fromApiValue('target_chased'),
        InningsCompletionReason.targetChased,
      );
      expect(
        InningsCompletionReason.fromApiValue('declared'),
        InningsCompletionReason.declared,
      );
    });

    test('fromApiValue throws for unknown value', () {
      expect(
        () => InningsCompletionReason.fromApiValue('unknown'),
        throwsArgumentError,
      );
    });
  });

  // ── Delivery entity ──────────────────────────────────────────────────

  group('Delivery', () {
    Delivery createDelivery({
      String id = 'del-1',
      String inningsId = 'inn-1',
      int overNumber = 1,
      int ballNumber = 1,
      int sequenceNumber = 1,
      String strikerId = 'bat-1',
      String nonStrikerId = 'bat-2',
      String bowlerId = 'bowl-1',
      int runsFromBat = 0,
      bool isWide = false,
      int wideRuns = 0,
      bool isNoBall = false,
      int noBallRuns = 0,
      bool isBye = false,
      int byeRuns = 0,
      bool isLegBye = false,
      int legByeRuns = 0,
      bool isWicket = false,
      bool isBoundaryFour = false,
      bool isBoundarySix = false,
      bool isFreeHit = false,
      bool isPenalty = false,
      WicketInfo? wicketInfo,
    }) {
      return Delivery(
        id: id,
        inningsId: inningsId,
        overNumber: overNumber,
        ballNumber: ballNumber,
        sequenceNumber: sequenceNumber,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        runsFromBat: runsFromBat,
        isWide: isWide,
        wideRuns: wideRuns,
        isNoBall: isNoBall,
        noBallRuns: noBallRuns,
        isBye: isBye,
        byeRuns: byeRuns,
        isLegBye: isLegBye,
        legByeRuns: legByeRuns,
        isWicket: isWicket,
        isBoundaryFour: isBoundaryFour,
        isBoundarySix: isBoundarySix,
        isFreeHit: isFreeHit,
        isPenalty: isPenalty,
        wicketInfo: wicketInfo,
      );
    }

    test('constructs with required fields and defaults', () {
      final d = createDelivery();
      expect(d.id, 'del-1');
      expect(d.inningsId, 'inn-1');
      expect(d.overNumber, 1);
      expect(d.ballNumber, 1);
      expect(d.sequenceNumber, 1);
      expect(d.strikerId, 'bat-1');
      expect(d.nonStrikerId, 'bat-2');
      expect(d.bowlerId, 'bowl-1');
      expect(d.runsFromBat, 0);
      expect(d.isWide, false);
      expect(d.wideRuns, 0);
      expect(d.isNoBall, false);
      expect(d.noBallRuns, 0);
      expect(d.isBye, false);
      expect(d.byeRuns, 0);
      expect(d.isLegBye, false);
      expect(d.legByeRuns, 0);
      expect(d.isWicket, false);
      expect(d.isBoundaryFour, false);
      expect(d.isBoundarySix, false);
      expect(d.isFreeHit, false);
      expect(d.isPenalty, false);
      expect(d.wicketInfo, isNull);
    });

    // ── isLegal ──

    test('isLegal is true for normal delivery', () {
      expect(createDelivery().isLegal, true);
    });

    test('isLegal is false for wide', () {
      expect(createDelivery(isWide: true, wideRuns: 1).isLegal, false);
    });

    test('isLegal is false for no-ball', () {
      expect(createDelivery(isNoBall: true, noBallRuns: 1).isLegal, false);
    });

    test('isLegal is false for penalty', () {
      expect(createDelivery(isPenalty: true).isLegal, false);
    });

    test('isLegal is true for bye (legal delivery)', () {
      expect(createDelivery(isBye: true, byeRuns: 1).isLegal, true);
    });

    test('isLegal is true for leg-bye (legal delivery)', () {
      expect(createDelivery(isLegBye: true, legByeRuns: 1).isLegal, true);
    });

    // ── totalRuns ──

    test('totalRuns is 0 for dot ball', () {
      expect(createDelivery().totalRuns, 0);
    });

    test('totalRuns counts runs from bat', () {
      expect(createDelivery(runsFromBat: 4).totalRuns, 4);
    });

    test('totalRuns counts wide runs', () {
      expect(
        createDelivery(isWide: true, wideRuns: 1).totalRuns,
        1,
      );
    });

    test('totalRuns counts no-ball runs + bat runs', () {
      expect(
        createDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 2).totalRuns,
        3,
      );
    });

    test('totalRuns counts bye runs', () {
      expect(createDelivery(isBye: true, byeRuns: 2).totalRuns, 2);
    });

    test('totalRuns counts leg-bye runs', () {
      expect(createDelivery(isLegBye: true, legByeRuns: 3).totalRuns, 3);
    });

    test('totalRuns sums all run types', () {
      final d = createDelivery(
        runsFromBat: 1,
        isNoBall: true,
        noBallRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
      );
      expect(d.totalRuns, 2);
    });

    // ── isExtra ──

    test('isExtra is false for normal delivery', () {
      expect(createDelivery().isExtra, false);
    });

    test('isExtra is true for wide', () {
      expect(createDelivery(isWide: true, wideRuns: 1).isExtra, true);
    });

    test('isExtra is true for no-ball', () {
      expect(createDelivery(isNoBall: true, noBallRuns: 1).isExtra, true);
    });

    test('isExtra is true for bye', () {
      expect(createDelivery(isBye: true, byeRuns: 1).isExtra, true);
    });

    test('isExtra is true for leg-bye', () {
      expect(createDelivery(isLegBye: true, legByeRuns: 1).isExtra, true);
    });

    // ── isDotBall ──

    test('isDotBall is true for 0 runs legal delivery', () {
      expect(createDelivery().isDotBall, true);
    });

    test('isDotBall is false when runs scored', () {
      expect(createDelivery(runsFromBat: 1).isDotBall, false);
    });

    test('isDotBall is false for wide even with 0 additional runs', () {
      // Wide always adds at least 1 wide run
      expect(createDelivery(isWide: true, wideRuns: 1).isDotBall, false);
    });

    test('isDotBall is false for no-ball', () {
      expect(createDelivery(isNoBall: true, noBallRuns: 1).isDotBall, false);
    });

    // ── bowlerRunsConceded ──

    test('bowlerRunsConceded is 0 for dot ball', () {
      expect(createDelivery().bowlerRunsConceded, 0);
    });

    test('bowlerRunsConceded includes bat runs', () {
      expect(createDelivery(runsFromBat: 4).bowlerRunsConceded, 4);
    });

    test('bowlerRunsConceded includes wide runs', () {
      expect(
        createDelivery(isWide: true, wideRuns: 2).bowlerRunsConceded,
        2,
      );
    });

    test('bowlerRunsConceded includes no-ball runs + bat runs', () {
      expect(
        createDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 3)
            .bowlerRunsConceded,
        4,
      );
    });

    test('bowlerRunsConceded excludes bye runs', () {
      expect(createDelivery(isBye: true, byeRuns: 2).bowlerRunsConceded, 0);
    });

    test('bowlerRunsConceded excludes leg-bye runs', () {
      expect(
        createDelivery(isLegBye: true, legByeRuns: 3).bowlerRunsConceded,
        0,
      );
    });

    // ── notation ──

    test('notation for dot ball is "."', () {
      expect(createDelivery().notation, '.');
    });

    test('notation for 1 run is "1"', () {
      expect(createDelivery(runsFromBat: 1).notation, '1');
    });

    test('notation for 2 runs is "2"', () {
      expect(createDelivery(runsFromBat: 2).notation, '2');
    });

    test('notation for 3 runs is "3"', () {
      expect(createDelivery(runsFromBat: 3).notation, '3');
    });

    test('notation for boundary four is "4"', () {
      expect(
        createDelivery(runsFromBat: 4, isBoundaryFour: true).notation,
        '4',
      );
    });

    test('notation for boundary six is "6"', () {
      expect(
        createDelivery(runsFromBat: 6, isBoundarySix: true).notation,
        '6',
      );
    });

    test('notation for wicket is "W"', () {
      expect(createDelivery(isWicket: true).notation, 'W');
    });

    test('notation for wide with no additional runs is "Wd"', () {
      expect(createDelivery(isWide: true, wideRuns: 1).notation, 'Wd');
    });

    test('notation for wide + 1 additional run is "1Wd"', () {
      expect(createDelivery(isWide: true, wideRuns: 2).notation, '1Wd');
    });

    test('notation for wide + 3 additional runs is "3Wd"', () {
      expect(createDelivery(isWide: true, wideRuns: 4).notation, '3Wd');
    });

    test('notation for no-ball with 0 bat runs is "Nb"', () {
      expect(createDelivery(isNoBall: true, noBallRuns: 1).notation, 'Nb');
    });

    test('notation for no-ball + 1 bat run is "1Nb"', () {
      expect(
        createDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 1).notation,
        '1Nb',
      );
    });

    test('notation for no-ball + 4 bat runs is "4Nb"', () {
      expect(
        createDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 4).notation,
        '4Nb',
      );
    });

    test('notation for bye is "XB"', () {
      expect(createDelivery(isBye: true, byeRuns: 1).notation, '1B');
      expect(createDelivery(isBye: true, byeRuns: 4).notation, '4B');
    });

    test('notation for leg-bye is "XLb"', () {
      expect(createDelivery(isLegBye: true, legByeRuns: 1).notation, '1Lb');
      expect(createDelivery(isLegBye: true, legByeRuns: 2).notation, '2Lb');
    });

    test('notation for penalty is "P"', () {
      expect(createDelivery(isPenalty: true).notation, 'P');
    });

    test('wicket notation takes priority over extras', () {
      // Wicket on wide (e.g. stumping off wide)
      expect(
        createDelivery(isWicket: true, isWide: true, wideRuns: 1).notation,
        'W',
      );
    });

    test('notation for 5 runs (overthrow) is "5"', () {
      expect(createDelivery(runsFromBat: 5).notation, '5');
    });
  });
}
