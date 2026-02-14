import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/utils/commentary_generator.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/wicket_info.dart';

void main() {
  group('generateCommentary', () {
    test('dot ball', () {
      final delivery = _delivery();
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, no run');
    });

    test('single run', () {
      final delivery = _delivery(runsFromBat: 1);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 1 run');
    });

    test('multiple runs', () {
      final delivery = _delivery(runsFromBat: 2);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 2 runs');
    });

    test('boundary four', () {
      final delivery = _delivery(runsFromBat: 4, isBoundaryFour: true);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, FOUR!');
    });

    test('boundary six', () {
      final delivery = _delivery(runsFromBat: 6, isBoundarySix: true);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, SIX!');
    });

    test('wide with no extra runs', () {
      final delivery = _delivery(isWide: true, wideRuns: 1);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, wide');
    });

    test('wide with extra runs', () {
      final delivery = _delivery(isWide: true, wideRuns: 3);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, wide, 2 extra runs');
    });

    test('no ball with no bat runs', () {
      final delivery = _delivery(isNoBall: true, noBallRuns: 1);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, no ball');
    });

    test('no ball with bat runs', () {
      final delivery = _delivery(isNoBall: true, noBallRuns: 1, runsFromBat: 4);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, no ball, 4 runs scored');
    });

    test('bye', () {
      final delivery = _delivery(isBye: true, byeRuns: 2);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 2 byes');
    });

    test('single bye', () {
      final delivery = _delivery(isBye: true, byeRuns: 1);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 1 bye');
    });

    test('leg bye', () {
      final delivery = _delivery(isLegBye: true, legByeRuns: 3);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 3 leg byes');
    });

    test('single leg bye', () {
      final delivery = _delivery(isLegBye: true, legByeRuns: 1);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, 1 leg bye');
    });

    test('wicket bowled', () {
      final delivery = _delivery(
        isWicket: true,
        wicketInfo: const WicketInfo(
          dismissedPlayerId: 'p1',
          dismissalType: DismissalType.bowled,
          bowlerCredited: true,
        ),
      );
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, OUT! Bowled!');
    });

    test('wicket caught', () {
      final delivery = _delivery(
        isWicket: true,
        wicketInfo: const WicketInfo(
          dismissedPlayerId: 'p1',
          dismissalType: DismissalType.caught,
          bowlerCredited: true,
          fielderId: 'f1',
        ),
      );
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, OUT! Caught!');
    });

    test('wicket run out', () {
      final delivery = _delivery(
        isWicket: true,
        wicketInfo: const WicketInfo(
          dismissedPlayerId: 'p1',
          dismissalType: DismissalType.runOut,
          bowlerCredited: false,
          fielderId: 'f1',
        ),
      );
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, OUT! Run Out!');
    });

    test('uses default names when not provided', () {
      final delivery = _delivery(runsFromBat: 3);
      final text = generateCommentary(delivery);
      expect(text, '0.1 Bowler to Batter, 3 runs');
    });

    test('wicket without wicketInfo', () {
      final delivery = _delivery(isWicket: true);
      final text = generateCommentary(
        delivery,
        strikerName: 'Kohli',
        bowlerName: 'Bumrah',
      );
      expect(text, '0.1 Bumrah to Kohli, OUT!');
    });
  });
}

Delivery _delivery({
  int runsFromBat = 0,
  bool isWide = false,
  int wideRuns = 0,
  bool isNoBall = false,
  int noBallRuns = 0,
  bool isBye = false,
  int byeRuns = 0,
  bool isLegBye = false,
  int legByeRuns = 0,
  bool isBoundaryFour = false,
  bool isBoundarySix = false,
  bool isWicket = false,
  WicketInfo? wicketInfo,
}) {
  return Delivery(
    id: 'del-1',
    inningsId: 'innings-1',
    overNumber: 0,
    ballNumber: 1,
    sequenceNumber: 1,
    strikerId: 'p1',
    nonStrikerId: 'p2',
    bowlerId: 'b1',
    runsFromBat: runsFromBat,
    isWide: isWide,
    wideRuns: wideRuns,
    isNoBall: isNoBall,
    noBallRuns: noBallRuns,
    isBye: isBye,
    byeRuns: byeRuns,
    isLegBye: isLegBye,
    legByeRuns: legByeRuns,
    isBoundaryFour: isBoundaryFour,
    isBoundarySix: isBoundarySix,
    isWicket: isWicket,
    wicketInfo: wicketInfo,
  );
}
