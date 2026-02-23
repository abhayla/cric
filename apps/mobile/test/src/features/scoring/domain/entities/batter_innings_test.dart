import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';

void main() {
  group('BatterInnings', () {
    BatterInnings createBatter({
      String playerId = 'bat-1',
      String displayName = 'V Kohli',
      int runsScored = 0,
      int ballsFaced = 0,
      int fours = 0,
      int sixes = 0,
      bool isNotOut = true,
      bool isOnStrike = false,
      bool isRetiredHurt = false,
      DismissalType? dismissalType,
      String? dismissedByName,
      String? fielderName,
    }) {
      return BatterInnings(
        playerId: playerId,
        displayName: displayName,
        runsScored: runsScored,
        ballsFaced: ballsFaced,
        fours: fours,
        sixes: sixes,
        isNotOut: isNotOut,
        isOnStrike: isOnStrike,
        isRetiredHurt: isRetiredHurt,
        dismissalType: dismissalType,
        dismissedByName: dismissedByName,
        fielderName: fielderName,
      );
    }

    test('constructs with defaults', () {
      final b = createBatter();
      expect(b.playerId, 'bat-1');
      expect(b.displayName, 'V Kohli');
      expect(b.runsScored, 0);
      expect(b.ballsFaced, 0);
      expect(b.fours, 0);
      expect(b.sixes, 0);
      expect(b.isNotOut, true);
      expect(b.isOnStrike, false);
      expect(b.isRetiredHurt, false);
      expect(b.dismissalType, isNull);
      expect(b.dismissedByName, isNull);
      expect(b.fielderName, isNull);
    });

    // ── strikeRate ──

    test('strikeRate is 0 when no balls faced', () {
      expect(createBatter().strikeRate, 0);
    });

    test('strikeRate is 100 when runs equal balls', () {
      final b = createBatter(runsScored: 30, ballsFaced: 30);
      expect(b.strikeRate, 100);
    });

    test('strikeRate for aggressive batting', () {
      // 65 off 40 = 162.5
      final b = createBatter(runsScored: 65, ballsFaced: 40);
      expect(b.strikeRate, 162.5);
    });

    test('strikeRate for defensive batting', () {
      // 10 off 30 = 33.33...
      final b = createBatter(runsScored: 10, ballsFaced: 30);
      expect(b.strikeRate, closeTo(33.33, 0.01));
    });

    test('strikeRate is 0 when 0 runs off balls', () {
      final b = createBatter(runsScored: 0, ballsFaced: 5);
      expect(b.strikeRate, 0);
    });

    // ── isActive ──

    test('isActive when not out and not retired', () {
      expect(createBatter(isNotOut: true, isRetiredHurt: false).isActive, true);
    });

    test('isActive is false when dismissed', () {
      expect(createBatter(isNotOut: false).isActive, false);
    });

    test('isActive is false when retired hurt', () {
      expect(createBatter(isRetiredHurt: true).isActive, false);
    });

    test('isActive is false when both dismissed and retired', () {
      expect(
        createBatter(isNotOut: false, isRetiredHurt: true).isActive,
        false,
      );
    });

    // ── canReturn ──

    test('canReturn is true when retired hurt and not out', () {
      expect(createBatter(isRetiredHurt: true, isNotOut: true).canReturn, true);
    });

    test('canReturn is false when not retired hurt', () {
      expect(createBatter(isRetiredHurt: false).canReturn, false);
    });

    test('canReturn is false when retired but not out (retired out is not out=false)', () {
      expect(
        createBatter(isRetiredHurt: true, isNotOut: false).canReturn,
        false,
      );
    });

    test('canReturn is false for active batter', () {
      expect(
        createBatter(isNotOut: true, isRetiredHurt: false).canReturn,
        false,
      );
    });

    // ── dismissalDescription ──

    test('dismissalDescription for not out batter', () {
      expect(createBatter().dismissalDescription, 'not out');
    });

    test('dismissalDescription for bowled', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.bowled,
        dismissedByName: 'Bumrah',
      );
      expect(b.dismissalDescription, 'b Bumrah');
    });

    test('dismissalDescription for caught', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.caught,
        dismissedByName: 'Bumrah',
        fielderName: 'Kohli',
      );
      expect(b.dismissalDescription, 'c Kohli b Bumrah');
    });

    test('dismissalDescription for lbw', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.lbw,
        dismissedByName: 'Ashwin',
      );
      expect(b.dismissalDescription, 'lbw b Ashwin');
    });

    test('dismissalDescription for run out', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.runOut,
        fielderName: 'Jadeja',
      );
      expect(b.dismissalDescription, 'run out (Jadeja)');
    });

    test('dismissalDescription for stumped', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.stumped,
        dismissedByName: 'Ashwin',
        fielderName: 'Pant',
      );
      expect(b.dismissalDescription, 'st Pant b Ashwin');
    });

    test('dismissalDescription for hit wicket', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.hitWicket,
        dismissedByName: 'Bumrah',
      );
      expect(b.dismissalDescription, 'hit wkt b Bumrah');
    });

    test('dismissalDescription for caught & bowled', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.caughtAndBowled,
        dismissedByName: 'Bumrah',
      );
      expect(b.dismissalDescription, 'c & b Bumrah');
    });

    test('dismissalDescription for retired hurt', () {
      final b = createBatter(
        isNotOut: true,
        isRetiredHurt: true,
        dismissalType: DismissalType.retiredHurt,
      );
      expect(b.dismissalDescription, 'retired hurt');
    });

    test('dismissalDescription for retired out', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.retiredOut,
      );
      expect(b.dismissalDescription, 'retired out');
    });

    // ── copyWith ──

    test('copyWith preserves original values when no args', () {
      final b = createBatter(
        runsScored: 50,
        ballsFaced: 40,
        fours: 6,
        sixes: 2,
        isOnStrike: true,
      );
      final copy = b.copyWith();
      expect(copy.playerId, b.playerId);
      expect(copy.displayName, b.displayName);
      expect(copy.runsScored, 50);
      expect(copy.ballsFaced, 40);
      expect(copy.fours, 6);
      expect(copy.sixes, 2);
      expect(copy.isOnStrike, true);
    });

    test('copyWith updates specified fields', () {
      final b = createBatter(runsScored: 30, ballsFaced: 25);
      final updated = b.copyWith(runsScored: 34, ballsFaced: 26, fours: 1);
      expect(updated.runsScored, 34);
      expect(updated.ballsFaced, 26);
      expect(updated.fours, 1);
      expect(updated.playerId, b.playerId);
    });

    test('copyWith updates dismissal', () {
      final b = createBatter();
      final dismissed = b.copyWith(
        isNotOut: false,
        dismissalType: DismissalType.bowled,
        dismissedByName: 'Bumrah',
      );
      expect(dismissed.isNotOut, false);
      expect(dismissed.dismissalType, DismissalType.bowled);
      expect(dismissed.dismissedByName, 'Bumrah');
    });

    test('copyWith updates strike', () {
      final b = createBatter(isOnStrike: false);
      final onStrike = b.copyWith(isOnStrike: true);
      expect(onStrike.isOnStrike, true);
    });

    test('copyWith updates retired hurt', () {
      final b = createBatter();
      final retired = b.copyWith(isRetiredHurt: true);
      expect(retired.isRetiredHurt, true);
      expect(retired.isNotOut, true);
    });

    test('copyWith preserves immutable identity fields', () {
      final b = createBatter(playerId: 'p-1', displayName: 'Test Player');
      final copy = b.copyWith(runsScored: 100);
      expect(copy.playerId, 'p-1');
      expect(copy.displayName, 'Test Player');
    });

    // ── edge cases ──

    test('dismissalDescription with missing names shows empty', () {
      final b = createBatter(
        isNotOut: false,
        dismissalType: DismissalType.caught,
      );
      expect(b.dismissalDescription, 'c  b ');
    });

    test('high strike rate calculation', () {
      // 100 off 50 balls = 200.0
      final b = createBatter(runsScored: 100, ballsFaced: 50);
      expect(b.strikeRate, 200.0);
    });

    test('1 run off 1 ball', () {
      final b = createBatter(runsScored: 1, ballsFaced: 1);
      expect(b.strikeRate, 100.0);
    });
  });
}
