import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';

void main() {
  group('BowlerSpell', () {
    BowlerSpell createBowler({
      String playerId = 'bowl-1',
      String displayName = 'J Bumrah',
      int ballsBowled = 0,
      int maidens = 0,
      int runsConceded = 0,
      int wicketsTaken = 0,
      int wides = 0,
      int noBalls = 0,
      int dotBalls = 0,
    }) {
      return BowlerSpell(
        playerId: playerId,
        displayName: displayName,
        ballsBowled: ballsBowled,
        maidens: maidens,
        runsConceded: runsConceded,
        wicketsTaken: wicketsTaken,
        wides: wides,
        noBalls: noBalls,
        dotBalls: dotBalls,
      );
    }

    test('constructs with defaults', () {
      final b = createBowler();
      expect(b.playerId, 'bowl-1');
      expect(b.displayName, 'J Bumrah');
      expect(b.ballsBowled, 0);
      expect(b.maidens, 0);
      expect(b.runsConceded, 0);
      expect(b.wicketsTaken, 0);
      expect(b.wides, 0);
      expect(b.noBalls, 0);
      expect(b.dotBalls, 0);
    });

    // ── oversDisplay ──

    test('oversDisplay at start is "0.0"', () {
      expect(createBowler().oversDisplay, '0.0');
    });

    test('oversDisplay for partial over', () {
      expect(createBowler(ballsBowled: 3).oversDisplay, '0.3');
    });

    test('oversDisplay for complete overs', () {
      expect(createBowler(ballsBowled: 6).oversDisplay, '1.0');
      expect(createBowler(ballsBowled: 24).oversDisplay, '4.0');
    });

    test('oversDisplay for mixed', () {
      expect(createBowler(ballsBowled: 8).oversDisplay, '1.2');
      expect(createBowler(ballsBowled: 22).oversDisplay, '3.4');
    });

    // ── economyRate ──

    test('economyRate is 0 when no balls bowled', () {
      expect(createBowler().economyRate, 0);
    });

    test('economyRate calculated correctly', () {
      // 18 runs from 24 balls (4 overs) = 4.5 RPO
      final b = createBowler(runsConceded: 18, ballsBowled: 24);
      expect(b.economyRate, 4.5);
    });

    test('economyRate for expensive bowling', () {
      // 50 runs from 12 balls (2 overs) = 25.0 RPO
      final b = createBowler(runsConceded: 50, ballsBowled: 12);
      expect(b.economyRate, 25.0);
    });

    test('economyRate for tight bowling', () {
      // 6 runs from 24 balls (4 overs) = 1.5 RPO
      final b = createBowler(runsConceded: 6, ballsBowled: 24);
      expect(b.economyRate, 1.5);
    });

    test('economyRate for partial over', () {
      // 10 runs from 3 balls = 20.0 RPO
      final b = createBowler(runsConceded: 10, ballsBowled: 3);
      expect(b.economyRate, 20.0);
    });

    test('economyRate for 0 runs', () {
      // 0 runs from 6 balls = 0.0 RPO
      final b = createBowler(runsConceded: 0, ballsBowled: 6);
      expect(b.economyRate, 0);
    });

    // ── figures ──

    test('figures format is wickets-runs', () {
      expect(createBowler().figures, '0-0');
    });

    test('figures for standard spell', () {
      final b = createBowler(wicketsTaken: 3, runsConceded: 25);
      expect(b.figures, '3-25');
    });

    test('figures for no-wicket spell', () {
      final b = createBowler(wicketsTaken: 0, runsConceded: 40);
      expect(b.figures, '0-40');
    });

    test('figures for 5-wicket haul', () {
      final b = createBowler(wicketsTaken: 5, runsConceded: 18);
      expect(b.figures, '5-18');
    });

    // ── copyWith ──

    test('copyWith preserves identity fields', () {
      final b = createBowler(playerId: 'p-1', displayName: 'Test');
      final copy = b.copyWith(runsConceded: 10);
      expect(copy.playerId, 'p-1');
      expect(copy.displayName, 'Test');
      expect(copy.runsConceded, 10);
    });

    test('copyWith preserves originals when no args', () {
      final b = createBowler(
        ballsBowled: 12,
        maidens: 1,
        runsConceded: 20,
        wicketsTaken: 2,
        wides: 3,
        noBalls: 1,
        dotBalls: 8,
      );
      final copy = b.copyWith();
      expect(copy.ballsBowled, 12);
      expect(copy.maidens, 1);
      expect(copy.runsConceded, 20);
      expect(copy.wicketsTaken, 2);
      expect(copy.wides, 3);
      expect(copy.noBalls, 1);
      expect(copy.dotBalls, 8);
    });

    test('copyWith updates multiple fields', () {
      final b = createBowler(
        ballsBowled: 6,
        runsConceded: 10,
      );
      final updated = b.copyWith(
        ballsBowled: 7,
        runsConceded: 14,
        wicketsTaken: 1,
      );
      expect(updated.ballsBowled, 7);
      expect(updated.runsConceded, 14);
      expect(updated.wicketsTaken, 1);
    });

    test('copyWith updates maidens', () {
      final b = createBowler(maidens: 0);
      final updated = b.copyWith(maidens: 2);
      expect(updated.maidens, 2);
    });

    test('copyWith updates dot balls', () {
      final b = createBowler(dotBalls: 5);
      final updated = b.copyWith(dotBalls: 10);
      expect(updated.dotBalls, 10);
    });
  });
}
