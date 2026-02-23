import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/utils/cricket_utils.dart';

void main() {
  // ── ballsToOvers ────────────────────────────────────────────────────

  group('CricketUtils.ballsToOvers', () {
    test('0 balls → 0.0', () {
      expect(CricketUtils.ballsToOvers(0), 0.0);
    });

    test('1 ball → 0.1', () {
      expect(CricketUtils.ballsToOvers(1), 0.1);
    });

    test('5 balls → 0.5', () {
      expect(CricketUtils.ballsToOvers(5), 0.5);
    });

    test('6 balls → 1.0 (complete over)', () {
      expect(CricketUtils.ballsToOvers(6), 1.0);
    });

    test('7 balls → 1.1', () {
      expect(CricketUtils.ballsToOvers(7), 1.1);
    });

    test('13 balls → 2.1', () {
      expect(CricketUtils.ballsToOvers(13), closeTo(2.1, 0.001));
    });

    test('120 balls → 20.0 (full T20)', () {
      expect(CricketUtils.ballsToOvers(120), 20.0);
    });

    test('119 balls → 19.5', () {
      expect(CricketUtils.ballsToOvers(119), closeTo(19.5, 0.001));
    });

    test('300 balls → 50.0 (full ODI)', () {
      expect(CricketUtils.ballsToOvers(300), 50.0);
    });
  });

  // ── formatOvers ─────────────────────────────────────────────────────

  group('CricketUtils.formatOvers', () {
    test('0 balls → "0.0"', () {
      expect(CricketUtils.formatOvers(0), '0.0');
    });

    test('1 ball → "0.1"', () {
      expect(CricketUtils.formatOvers(1), '0.1');
    });

    test('5 balls → "0.5"', () {
      expect(CricketUtils.formatOvers(5), '0.5');
    });

    test('6 balls → "1.0"', () {
      expect(CricketUtils.formatOvers(6), '1.0');
    });

    test('13 balls → "2.1"', () {
      expect(CricketUtils.formatOvers(13), '2.1');
    });

    test('120 balls → "20.0"', () {
      expect(CricketUtils.formatOvers(120), '20.0');
    });
  });

  // ── currentRunRate ──────────────────────────────────────────────────

  group('CricketUtils.currentRunRate', () {
    test('0 balls → 0', () {
      expect(CricketUtils.currentRunRate(100, 0), 0.0);
    });

    test('6 runs in 6 balls → 6.0 rpo', () {
      expect(CricketUtils.currentRunRate(6, 6), 6.0);
    });

    test('12 runs in 6 balls → 12.0 rpo', () {
      expect(CricketUtils.currentRunRate(12, 6), 12.0);
    });

    test('0 runs in 6 balls → 0.0 rpo', () {
      expect(CricketUtils.currentRunRate(0, 6), 0.0);
    });

    test('180 runs in 120 balls → 9.0 rpo', () {
      expect(CricketUtils.currentRunRate(180, 120), 9.0);
    });

    test('50 runs in 30 balls → 10.0 rpo', () {
      expect(CricketUtils.currentRunRate(50, 30), 10.0);
    });
  });

  // ── requiredRunRate ─────────────────────────────────────────────────

  group('CricketUtils.requiredRunRate', () {
    test('0 balls remaining → infinity', () {
      expect(CricketUtils.requiredRunRate(50, 0), double.infinity);
    });

    test('negative balls remaining → infinity', () {
      expect(CricketUtils.requiredRunRate(50, -1), double.infinity);
    });

    test('60 needed in 60 balls → 6.0 rpo', () {
      expect(CricketUtils.requiredRunRate(60, 60), 6.0);
    });

    test('120 needed in 60 balls → 12.0 rpo', () {
      expect(CricketUtils.requiredRunRate(120, 60), 12.0);
    });

    test('1 needed in 6 balls → 1.0 rpo', () {
      expect(CricketUtils.requiredRunRate(1, 6), 1.0);
    });

    test('36 needed in 12 balls → 18.0 rpo', () {
      expect(CricketUtils.requiredRunRate(36, 12), 18.0);
    });
  });

  // ── maxOversPerBowler ───────────────────────────────────────────────

  group('CricketUtils.maxOversPerBowler', () {
    test('20 overs → 4 (T20)', () {
      expect(CricketUtils.maxOversPerBowler(20), 4);
    });

    test('50 overs → 10 (ODI)', () {
      expect(CricketUtils.maxOversPerBowler(50), 10);
    });

    test('10 overs → 2', () {
      expect(CricketUtils.maxOversPerBowler(10), 2);
    });

    test('5 overs → 1', () {
      expect(CricketUtils.maxOversPerBowler(5), 1);
    });

    test('6 overs → 2 (ceil(6/5))', () {
      expect(CricketUtils.maxOversPerBowler(6), 2);
    });

    test('1 over → 1 (ceil(1/5))', () {
      expect(CricketUtils.maxOversPerBowler(1), 1);
    });

    test('15 overs → 3', () {
      expect(CricketUtils.maxOversPerBowler(15), 3);
    });

    test('7 overs → 2 (ceil(7/5))', () {
      expect(CricketUtils.maxOversPerBowler(7), 2);
    });
  });
}
