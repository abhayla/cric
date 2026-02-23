import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/over.dart';

void main() {
  group('Over', () {
    Delivery makeDelivery({
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
    }) {
      return Delivery(
        id: 'del-${DateTime.now().microsecondsSinceEpoch}',
        inningsId: 'inn-1',
        overNumber: 1,
        ballNumber: 1,
        sequenceNumber: 1,
        strikerId: 'bat-1',
        nonStrikerId: 'bat-2',
        bowlerId: 'bowl-1',
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
      );
    }

    test('constructs with defaults', () {
      const o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'J Bumrah',
      );
      expect(o.overNumber, 1);
      expect(o.bowlerId, 'bowl-1');
      expect(o.bowlerName, 'J Bumrah');
      expect(o.runsConceded, 0);
      expect(o.wicketsTaken, 0);
      expect(o.isMaiden, false);
      expect(o.deliveries, isEmpty);
    });

    test('constructs with all fields', () {
      final deliveries = [makeDelivery(), makeDelivery(runsFromBat: 4)];
      final o = Over(
        overNumber: 5,
        bowlerId: 'bowl-2',
        bowlerName: 'R Ashwin',
        runsConceded: 12,
        wicketsTaken: 1,
        isMaiden: false,
        deliveries: deliveries,
      );
      expect(o.overNumber, 5);
      expect(o.bowlerName, 'R Ashwin');
      expect(o.runsConceded, 12);
      expect(o.wicketsTaken, 1);
      expect(o.deliveries.length, 2);
    });

    // ── legalBalls ──

    test('legalBalls counts only legal deliveries', () {
      final deliveries = [
        makeDelivery(),
        makeDelivery(runsFromBat: 1),
        makeDelivery(isWide: true, wideRuns: 1),
        makeDelivery(isNoBall: true, noBallRuns: 1),
        makeDelivery(runsFromBat: 4, isBoundaryFour: true),
        makeDelivery(),
        makeDelivery(runsFromBat: 2),
        makeDelivery(),
      ];
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        deliveries: deliveries,
      );
      // 6 legal (excluding wide and NB)
      expect(o.legalBalls, 6);
    });

    test('legalBalls with no deliveries', () {
      const o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
      );
      expect(o.legalBalls, 0);
    });

    test('legalBalls counts byes and leg-byes as legal', () {
      final deliveries = [
        makeDelivery(isBye: true, byeRuns: 1),
        makeDelivery(isLegBye: true, legByeRuns: 2),
      ];
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        deliveries: deliveries,
      );
      expect(o.legalBalls, 2);
    });

    // ── totalDeliveries ──

    test('totalDeliveries counts all deliveries', () {
      final deliveries = [
        makeDelivery(),
        makeDelivery(isWide: true, wideRuns: 1),
        makeDelivery(),
        makeDelivery(isNoBall: true, noBallRuns: 1),
        makeDelivery(),
      ];
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        deliveries: deliveries,
      );
      expect(o.totalDeliveries, 5);
    });

    // ── notation ──

    test('notation for empty over', () {
      const o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
      );
      expect(o.notation, '');
    });

    test('notation for maiden over', () {
      final deliveries = List.generate(6, (_) => makeDelivery());
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        isMaiden: true,
        deliveries: deliveries,
      );
      expect(o.notation, '. . . . . .');
    });

    test('notation for mixed over', () {
      final deliveries = [
        makeDelivery(),
        makeDelivery(runsFromBat: 1),
        makeDelivery(runsFromBat: 4, isBoundaryFour: true),
        makeDelivery(isWicket: true),
        makeDelivery(),
        makeDelivery(isWide: true, wideRuns: 1),
        makeDelivery(runsFromBat: 2),
        makeDelivery(runsFromBat: 6, isBoundarySix: true),
      ];
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        deliveries: deliveries,
      );
      expect(o.notation, '. 1 4 W . Wd 2 6');
    });

    test('notation for over with no-ball', () {
      final deliveries = [
        makeDelivery(),
        makeDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 2),
        makeDelivery(runsFromBat: 1),
      ];
      final o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        deliveries: deliveries,
      );
      expect(o.notation, '. 2Nb 1');
    });

    // ── maiden flag ──

    test('maiden over flag is stored', () {
      const o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        isMaiden: true,
      );
      expect(o.isMaiden, true);
    });

    test('non-maiden over flag is false', () {
      const o = Over(
        overNumber: 1,
        bowlerId: 'bowl-1',
        bowlerName: 'Test',
        runsConceded: 8,
      );
      expect(o.isMaiden, false);
    });
  });
}
