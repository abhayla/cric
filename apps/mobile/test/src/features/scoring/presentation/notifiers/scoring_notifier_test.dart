import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  /// Helper: create a default ScoringState for testing.
  ScoringState makeState({
    String matchId = 'match-1',
    String inningsId = 'inn-1',
    String battingTeamId = 'team-a',
    String bowlingTeamId = 'team-b',
    int inningsNumber = 1,
    int totalOvers = 20,
    int playersPerSide = 11,
    int wideRunsPenalty = 1,
    int noBallRunsPenalty = 1,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
    int totalRuns = 0,
    int totalWickets = 0,
    int totalBalls = 0,
    int? target,
    Map<String, BatterInnings>? batterStats,
    Map<String, BowlerSpell>? bowlerStats,
  }) {
    return ScoringState(
      matchId: matchId,
      inningsId: inningsId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      inningsNumber: inningsNumber,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      wideRunsPenalty: wideRunsPenalty,
      noBallRunsPenalty: noBallRunsPenalty,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      totalBalls: totalBalls,
      target: target,
      batterStats: batterStats,
      bowlerStats: bowlerStats,
    );
  }

  /// Helper: create a notifier with batters and bowler pre-selected.
  ScoringNotifier makeNotifier({
    int totalOvers = 20,
    int playersPerSide = 11,
    int inningsNumber = 1,
    int? target,
    int wideRunsPenalty = 1,
    int noBallRunsPenalty = 1,
  }) {
    final state = makeState(
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      inningsNumber: inningsNumber,
      target: target,
      wideRunsPenalty: wideRunsPenalty,
      noBallRunsPenalty: noBallRunsPenalty,
      strikerId: 'bat-1',
      nonStrikerId: 'bat-2',
      bowlerId: 'bowl-1',
      batterStats: {
        'bat-1': const BatterInnings(
          playerId: 'bat-1',
          displayName: 'Batter 1',
          isOnStrike: true,
        ),
        'bat-2': const BatterInnings(
          playerId: 'bat-2',
          displayName: 'Batter 2',
        ),
      },
      bowlerStats: {
        'bowl-1': const BowlerSpell(
          playerId: 'bowl-1',
          displayName: 'Bowler 1',
        ),
      },
    );
    return ScoringNotifier(state);
  }

  // ── ScoringState construction ────────────────────────────────────────

  group('ScoringState', () {
    test('constructs with defaults', () {
      final s = makeState();
      expect(s.matchId, 'match-1');
      expect(s.inningsId, 'inn-1');
      expect(s.totalRuns, 0);
      expect(s.totalWickets, 0);
      expect(s.totalBalls, 0);
      expect(s.strikerId, isNull);
      expect(s.nonStrikerId, isNull);
      expect(s.bowlerId, isNull);
      expect(s.isFreeHitPending, false);
      expect(s.isInningsComplete, false);
      expect(s.isMatchComplete, false);
      expect(s.deliveryHistory, isEmpty);
      expect(s.batterStats, isEmpty);
      expect(s.bowlerStats, isEmpty);
    });

    test('oversDisplay at start', () {
      expect(makeState().oversDisplay, '0.0');
    });

    test('oversDisplay after balls', () {
      expect(makeState(totalBalls: 7).oversDisplay, '1.1');
      expect(makeState(totalBalls: 120).oversDisplay, '20.0');
    });

    test('runRate at start', () {
      expect(makeState().runRate, 0);
    });

    test('runRate calculation', () {
      expect(makeState(totalRuns: 60, totalBalls: 30).runRate, 12.0);
    });

    test('runsNeeded with no target', () {
      expect(makeState().runsNeeded, isNull);
    });

    test('runsNeeded with target', () {
      expect(makeState(totalRuns: 50, target: 180).runsNeeded, 130);
    });

    test('runsNeeded when target reached', () {
      expect(makeState(totalRuns: 180, target: 180).runsNeeded, 0);
    });

    test('ballsRemaining calculation', () {
      expect(makeState(totalOvers: 20).ballsRemaining, 120);
      expect(makeState(totalOvers: 20, totalBalls: 60).ballsRemaining, 60);
    });

    test('requiredRunRate with no target', () {
      expect(makeState().requiredRunRate, isNull);
    });

    test('requiredRunRate calculation', () {
      final s = makeState(
        totalRuns: 50,
        totalBalls: 60,
        totalOvers: 20,
        target: 180,
      );
      // Need 130 from 60 balls remaining = 13.0 RPO
      expect(s.requiredRunRate, 13.0);
    });

    test('scoreDisplay format', () {
      expect(makeState(totalRuns: 185, totalWickets: 6).scoreDisplay, '185/6');
      expect(makeState().scoreDisplay, '0/0');
    });

    test('currentOverNumber starts at 1', () {
      expect(makeState().currentOverNumber, 1);
    });

    test('currentOverNumber increments', () {
      expect(makeState(totalBalls: 6).currentOverNumber, 2);
      expect(makeState(totalBalls: 12).currentOverNumber, 3);
    });

    test('canUndo is false with empty history', () {
      expect(makeState().canUndo, false);
    });

    test('needsNewBatter when striker is null', () {
      expect(makeState(strikerId: null).needsNewBatter, true);
    });

    test('needsNewBatter when non-striker is null', () {
      expect(
        makeState(strikerId: 'bat-1', nonStrikerId: null).needsNewBatter,
        true,
      );
    });

    test('needsNewBatter false when both set', () {
      expect(
        makeState(strikerId: 'bat-1', nonStrikerId: 'bat-2').needsNewBatter,
        false,
      );
    });

    test('needsNewBowler when bowler is null', () {
      expect(makeState(bowlerId: null).needsNewBowler, true);
    });

    test('striker returns correct batter', () {
      final s = makeState(
        strikerId: 'bat-1',
        batterStats: {
          'bat-1': const BatterInnings(
            playerId: 'bat-1',
            displayName: 'Test',
          ),
        },
      );
      expect(s.striker?.playerId, 'bat-1');
    });

    test('currentBowler returns correct bowler', () {
      final s = makeState(
        bowlerId: 'bowl-1',
        bowlerStats: {
          'bowl-1': const BowlerSpell(
            playerId: 'bowl-1',
            displayName: 'Test',
          ),
        },
      );
      expect(s.currentBowler?.playerId, 'bowl-1');
    });

    // ── copyWith ──

    test('copyWith preserves values when no args', () {
      final s = makeState(
        strikerId: 'bat-1',
        totalRuns: 100,
        target: 180,
      );
      final copy = s.copyWith();
      expect(copy.strikerId, 'bat-1');
      expect(copy.totalRuns, 100);
      expect(copy.target, 180);
    });

    test('copyWith can set nullable field to null', () {
      final s = makeState(strikerId: 'bat-1', target: 180);
      final copy = s.copyWith(strikerId: null, target: null);
      expect(copy.strikerId, isNull);
      expect(copy.target, isNull);
    });

    test('copyWith updates non-nullable field', () {
      final s = makeState(totalRuns: 100);
      final copy = s.copyWith(totalRuns: 150);
      expect(copy.totalRuns, 150);
    });

    test('copyWith sentinel preserves nullable when not provided', () {
      final s = makeState(strikerId: 'bat-1');
      final copy = s.copyWith(totalRuns: 50);
      expect(copy.strikerId, 'bat-1');
    });
  });

  // ── ScoringNotifier: recordDelivery ──────────────────────────────────

  group('ScoringNotifier.recordDelivery', () {
    test('dot ball records correctly', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.totalRuns, 0);
      expect(n.state.totalBalls, 1);
      expect(n.state.deliveryHistory.length, 1);
      expect(n.state.deliveryHistory.last.isDotBall, true);
    });

    test('single run swaps strike', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 1);

      expect(n.state.totalRuns, 1);
      expect(n.state.strikerId, 'bat-2');
      expect(n.state.nonStrikerId, 'bat-1');
    });

    test('2 runs keeps strike', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 2);

      expect(n.state.totalRuns, 2);
      expect(n.state.strikerId, 'bat-1');
    });

    test('3 runs swaps strike', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 3);

      expect(n.state.totalRuns, 3);
      expect(n.state.strikerId, 'bat-2');
    });

    test('boundary four records runs and fours', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(n.state.totalRuns, 4);
      expect(n.state.batterStats['bat-1']?.runsScored, 4);
      expect(n.state.batterStats['bat-1']?.fours, 1);
    });

    test('boundary six records runs and sixes', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(n.state.totalRuns, 6);
      expect(n.state.batterStats['bat-1']?.runsScored, 6);
      expect(n.state.batterStats['bat-1']?.sixes, 1);
    });

    test('updates batter balls faced on legal delivery', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.batterStats['bat-1']?.ballsFaced, 1);
    });

    test('updates bowler stats', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4);

      final bowler = n.state.bowlerStats['bowl-1']!;
      expect(bowler.ballsBowled, 1);
      expect(bowler.runsConceded, 4);
    });

    test('dot ball increments bowler dot balls', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.bowlerStats['bowl-1']?.dotBalls, 1);
    });

    test('sequence of deliveries accumulates correctly', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0);
      n.recordDelivery(runsFromBat: 1);
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(n.state.totalRuns, 5);
      expect(n.state.totalBalls, 3);
      expect(n.state.deliveryHistory.length, 3);
    });
  });

  // ── ScoringNotifier: recordWide ──────────────────────────────────────

  group('ScoringNotifier.recordWide', () {
    test('wide adds penalty runs', () {
      final n = makeNotifier();
      n.recordWide();

      expect(n.state.totalRuns, 1);
      expect(n.state.totalWides, 1);
      expect(n.state.totalExtras, 1);
      expect(n.state.totalBalls, 0); // Not a legal delivery
    });

    test('wide does not increment batter balls faced', () {
      final n = makeNotifier();
      n.recordWide();

      expect(n.state.batterStats['bat-1']?.ballsFaced, 0);
    });

    test('wide with additional runs', () {
      final n = makeNotifier();
      n.recordWide(additionalRuns: 2);

      expect(n.state.totalRuns, 3); // 1 penalty + 2 additional
      expect(n.state.totalWides, 3);
    });

    test('wide swaps strike on odd runs', () {
      final n = makeNotifier();
      n.recordWide(); // 1 wide run = odd → swap

      expect(n.state.strikerId, 'bat-2');
    });

    test('wide does not swap on even runs', () {
      final n = makeNotifier();
      n.recordWide(additionalRuns: 1); // 2 wide runs = even → no swap

      expect(n.state.strikerId, 'bat-1');
    });

    test('configurable wide penalty', () {
      final n = makeNotifier(wideRunsPenalty: 2);
      n.recordWide();

      expect(n.state.totalRuns, 2);
      expect(n.state.totalWides, 2);
    });

    test('wide increments bowler wide count', () {
      final n = makeNotifier();
      n.recordWide();

      expect(n.state.bowlerStats['bowl-1']?.wides, 1);
    });

    test('bowler concedes wide runs', () {
      final n = makeNotifier();
      n.recordWide(additionalRuns: 2);

      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 3);
    });
  });

  // ── ScoringNotifier: recordNoBall ────────────────────────────────────

  group('ScoringNotifier.recordNoBall', () {
    test('no-ball adds penalty runs', () {
      final n = makeNotifier();
      n.recordNoBall();

      expect(n.state.totalRuns, 1);
      expect(n.state.totalNoBalls, 1);
      expect(n.state.totalExtras, 1);
      expect(n.state.totalBalls, 0);
    });

    test('no-ball with bat runs credits batter', () {
      final n = makeNotifier();
      n.recordNoBall(runsFromBat: 4);

      expect(n.state.totalRuns, 5); // 1 NB + 4 bat
      expect(n.state.batterStats['bat-1']?.runsScored, 4);
    });

    test('no-ball triggers free hit', () {
      final n = makeNotifier();
      n.recordNoBall();

      expect(n.state.isFreeHitPending, true);
    });

    test('free hit consumed by legal delivery', () {
      final n = makeNotifier();
      n.recordNoBall();
      expect(n.state.isFreeHitPending, true);

      n.recordDelivery(runsFromBat: 0);
      expect(n.state.isFreeHitPending, false);
    });

    test('no-ball does not increment batter balls faced', () {
      final n = makeNotifier();
      n.recordNoBall();

      expect(n.state.batterStats['bat-1']?.ballsFaced, 0);
    });

    test('bowler concedes NB penalty + bat runs', () {
      final n = makeNotifier();
      n.recordNoBall(runsFromBat: 2);

      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 3);
      expect(n.state.bowlerStats['bowl-1']?.noBalls, 1);
    });

    test('configurable no-ball penalty', () {
      final n = makeNotifier(noBallRunsPenalty: 2);
      n.recordNoBall();

      expect(n.state.totalRuns, 2);
      expect(n.state.totalNoBalls, 2);
    });
  });

  // ── ScoringNotifier: recordBye / recordLegBye ────────────────────────

  group('ScoringNotifier.recordBye', () {
    test('bye adds to extras', () {
      final n = makeNotifier();
      n.recordBye(byeRuns: 2);

      expect(n.state.totalRuns, 2);
      expect(n.state.totalByes, 2);
      expect(n.state.totalExtras, 2);
      expect(n.state.totalBalls, 1); // Legal delivery
    });

    test('bye does not credit batter runs', () {
      final n = makeNotifier();
      n.recordBye(byeRuns: 4);

      expect(n.state.batterStats['bat-1']?.runsScored, 0);
      expect(n.state.batterStats['bat-1']?.ballsFaced, 1);
    });

    test('bye does not count against bowler', () {
      final n = makeNotifier();
      n.recordBye(byeRuns: 4);

      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 0);
    });

    test('odd byes swap strike', () {
      final n = makeNotifier();
      n.recordBye(byeRuns: 1);

      expect(n.state.strikerId, 'bat-2');
    });

    test('even byes keep strike', () {
      final n = makeNotifier();
      n.recordBye(byeRuns: 2);

      expect(n.state.strikerId, 'bat-1');
    });
  });

  group('ScoringNotifier.recordLegBye', () {
    test('leg-bye adds to extras', () {
      final n = makeNotifier();
      n.recordLegBye(legByeRuns: 1);

      expect(n.state.totalRuns, 1);
      expect(n.state.totalLegByes, 1);
      expect(n.state.totalExtras, 1);
      expect(n.state.totalBalls, 1);
    });

    test('leg-bye does not credit batter', () {
      final n = makeNotifier();
      n.recordLegBye(legByeRuns: 3);

      expect(n.state.batterStats['bat-1']?.runsScored, 0);
    });

    test('leg-bye does not count against bowler', () {
      final n = makeNotifier();
      n.recordLegBye(legByeRuns: 2);

      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 0);
    });
  });

  // ── ScoringNotifier: recordWicket ────────────────────────────────────

  group('ScoringNotifier.recordWicket', () {
    test('bowled dismissal records correctly', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );

      expect(n.state.totalWickets, 1);
      expect(n.state.totalBalls, 1);
      expect(n.state.strikerId, isNull); // Needs new batter
      expect(n.state.batterStats['bat-1']?.isNotOut, false);
    });

    test('caught dismissal credits bowler', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: 'bat-1',
        fielderId: 'fielder-1',
      );

      expect(n.state.bowlerStats['bowl-1']?.wicketsTaken, 1);
    });

    test('run out does not credit bowler', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.runOut,
        dismissedPlayerId: 'bat-1',
        fielderId: 'fielder-1',
      );

      expect(n.state.bowlerStats['bowl-1']?.wicketsTaken, 0);
    });

    test('wicket with runs scored', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: 'bat-1',
        runsFromBat: 0,
      );

      expect(n.state.totalRuns, 0);
      expect(n.state.totalWickets, 1);
    });

    test('lbw credits bowler', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.lbw,
        dismissedPlayerId: 'bat-1',
      );

      expect(n.state.bowlerStats['bowl-1']?.wicketsTaken, 1);
    });

    test('stumped credits bowler', () {
      final n = makeNotifier();
      n.recordWicket(
        dismissalType: DismissalType.stumped,
        dismissedPlayerId: 'bat-1',
        fielderId: 'keeper-1',
      );

      expect(n.state.bowlerStats['bowl-1']?.wicketsTaken, 1);
    });

    test('multiple wickets accumulate', () {
      final n = makeNotifier();

      // First wicket
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      expect(n.state.totalWickets, 1);

      // Select new batter
      n.selectNewBatter(playerId: 'bat-3', displayName: 'Batter 3');

      // Second wicket
      n.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: 'bat-3',
        fielderId: 'fielder-1',
      );
      expect(n.state.totalWickets, 2);
    });
  });

  // ── ScoringNotifier: undoLastDelivery ────────────────────────────────

  group('ScoringNotifier.undoLastDelivery', () {
    test('undo dot ball reverses stats', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0);
      expect(n.state.totalBalls, 1);

      n.undoLastDelivery();
      expect(n.state.totalRuns, 0);
      expect(n.state.totalBalls, 0);
      expect(n.state.deliveryHistory, isEmpty);
    });

    test('undo single run reverses strike swap', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 1);
      expect(n.state.strikerId, 'bat-2');

      n.undoLastDelivery();
      expect(n.state.strikerId, 'bat-1');
    });

    test('undo boundary reverses batter fours', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      n.undoLastDelivery();
      expect(n.state.batterStats['bat-1']?.fours, 0);
      expect(n.state.batterStats['bat-1']?.runsScored, 0);
    });

    test('undo wide reverses extras', () {
      final n = makeNotifier();
      n.recordWide();

      n.undoLastDelivery();
      expect(n.state.totalWides, 0);
      expect(n.state.totalExtras, 0);
      expect(n.state.totalRuns, 0);
    });

    test('undo no-ball clears free hit', () {
      final n = makeNotifier();
      n.recordNoBall();
      expect(n.state.isFreeHitPending, true);

      n.undoLastDelivery();
      expect(n.state.isFreeHitPending, false);
    });

    test('undo does nothing when history is empty', () {
      final n = makeNotifier();
      n.undoLastDelivery();
      expect(n.state.totalBalls, 0);
    });

    test('undo does nothing when innings complete', () {
      final n = makeNotifier(playersPerSide: 2);
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      expect(n.state.isInningsComplete, true);

      n.undoLastDelivery();
      expect(n.state.totalWickets, 1); // Not reversed
    });

    test('undo reverses bowler stats', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4);

      n.undoLastDelivery();
      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 0);
      expect(n.state.bowlerStats['bowl-1']?.ballsBowled, 0);
    });

    test('multiple undos work sequentially', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 1);
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.totalRuns, 5);
      expect(n.state.totalBalls, 3);

      n.undoLastDelivery();
      expect(n.state.totalRuns, 5);
      expect(n.state.totalBalls, 2);

      n.undoLastDelivery();
      expect(n.state.totalRuns, 1);
      expect(n.state.totalBalls, 1);

      n.undoLastDelivery();
      expect(n.state.totalRuns, 0);
      expect(n.state.totalBalls, 0);
    });
  });

  // ── ScoringNotifier: swapStrike ──────────────────────────────────────

  group('ScoringNotifier.swapStrike', () {
    test('swaps striker and non-striker', () {
      final n = makeNotifier();
      expect(n.state.strikerId, 'bat-1');
      expect(n.state.nonStrikerId, 'bat-2');

      n.swapStrike();
      expect(n.state.strikerId, 'bat-2');
      expect(n.state.nonStrikerId, 'bat-1');
    });

    test('updates batter isOnStrike', () {
      final n = makeNotifier();
      n.swapStrike();

      expect(n.state.batterStats['bat-1']?.isOnStrike, false);
      expect(n.state.batterStats['bat-2']?.isOnStrike, true);
    });

    test('double swap returns to original', () {
      final n = makeNotifier();
      n.swapStrike();
      n.swapStrike();

      expect(n.state.strikerId, 'bat-1');
      expect(n.state.nonStrikerId, 'bat-2');
    });

    test('does nothing when striker is null', () {
      final n = ScoringNotifier(makeState(nonStrikerId: 'bat-2'));
      n.swapStrike();
      expect(n.state.strikerId, isNull);
    });
  });

  // ── ScoringNotifier: selectNewBatter ─────────────────────────────────

  group('ScoringNotifier.selectNewBatter', () {
    test('selects new batter at striker position', () {
      final n = makeNotifier();
      // Simulate wicket first
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      expect(n.state.strikerId, isNull);

      n.selectNewBatter(playerId: 'bat-3', displayName: 'Batter 3');
      expect(n.state.strikerId, 'bat-3');
      expect(n.state.batterStats['bat-3']?.displayName, 'Batter 3');
      expect(n.state.batterStats['bat-3']?.isOnStrike, true);
    });

    test('selects new batter at non-striker when striker exists', () {
      final state = makeState(
        strikerId: 'bat-1',
        batterStats: {
          'bat-1': const BatterInnings(
            playerId: 'bat-1',
            displayName: 'Batter 1',
            isOnStrike: true,
          ),
        },
      );
      final n = ScoringNotifier(state);

      n.selectNewBatter(playerId: 'bat-2', displayName: 'Batter 2');
      expect(n.state.nonStrikerId, 'bat-2');
      expect(n.state.batterStats['bat-2']?.isOnStrike, false);
    });
  });

  // ── ScoringNotifier: selectNewBowler ─────────────────────────────────

  group('ScoringNotifier.selectNewBowler', () {
    test('selects a new bowler', () {
      final state = makeState();
      final n = ScoringNotifier(state);

      n.selectNewBowler(playerId: 'bowl-1', displayName: 'Bowler 1');
      expect(n.state.bowlerId, 'bowl-1');
      expect(n.state.bowlerStats['bowl-1']?.displayName, 'Bowler 1');
    });

    test('preserves existing bowler stats', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4);
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 4);

      // Reselecting same bowler preserves stats
      n.selectNewBowler(playerId: 'bowl-1', displayName: 'Bowler 1');
      expect(n.state.bowlerStats['bowl-1']?.runsConceded, 4);
    });

    test('creates new bowler entry for new bowler', () {
      final n = makeNotifier();
      n.selectNewBowler(playerId: 'bowl-2', displayName: 'Bowler 2');

      expect(n.state.bowlerId, 'bowl-2');
      expect(n.state.bowlerStats['bowl-2']?.displayName, 'Bowler 2');
      expect(n.state.bowlerStats['bowl-2']?.ballsBowled, 0);
    });
  });

  // ── ScoringNotifier: over completion ─────────────────────────────────

  group('ScoringNotifier: over completion', () {
    test('over completes after 6 legal balls', () {
      final n = makeNotifier();
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.completedOvers.length, 1);
      expect(n.state.currentOverBalls, 0);
      expect(n.state.bowlerId, isNull); // Needs new bowler
    });

    test('wides do not count toward over completion', () {
      final n = makeNotifier();
      n.recordWide();
      n.recordWide();
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.completedOvers, isEmpty);
      expect(n.state.currentOverBalls, 5);
    });

    test('maiden over detected correctly', () {
      final n = makeNotifier();
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.completedOvers.first.isMaiden, true);
      expect(n.state.bowlerStats['bowl-1']?.maidens, 1);
    });

    test('over with runs is not maiden', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.completedOvers.first.isMaiden, false);
    });

    test('byes in over do not break maiden', () {
      final n = makeNotifier();
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      n.recordBye(byeRuns: 2);

      expect(n.state.completedOvers.first.isMaiden, true);
    });

    test('over end swaps strike', () {
      final n = makeNotifier();
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      // Dot ball over → over swap only → bat-2 now on strike
      expect(n.state.strikerId, 'bat-2');
    });

    test('over end after odd last ball cancels swap', () {
      final n = makeNotifier();
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      n.recordDelivery(runsFromBat: 1); // 6th ball: 1 run (swap) + over swap = cancel

      // 1 run swaps → bat-2 on strike
      // Over swap → bat-1 on strike again
      expect(n.state.strikerId, 'bat-1');
    });

    test('lastBowlerId set after over completion', () {
      final n = makeNotifier();
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.lastBowlerId, 'bowl-1');
    });
  });

  // ── ScoringNotifier: innings completion ──────────────────────────────

  group('ScoringNotifier: innings completion', () {
    test('innings complete on all out', () {
      final n = makeNotifier(playersPerSide: 2);
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );

      expect(n.state.isInningsComplete, true);
      expect(n.state.completionReason, InningsCompletionReason.allOut);
    });

    test('innings complete on overs exhausted', () {
      final n = makeNotifier(totalOvers: 1);
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.isInningsComplete, true);
      expect(
        n.state.completionReason,
        InningsCompletionReason.oversExhausted,
      );
    });

    test('innings complete on target chased (2nd innings)', () {
      final n = makeNotifier(inningsNumber: 2, target: 5);
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(n.state.isInningsComplete, true);
      expect(n.state.isMatchComplete, true);
      expect(
        n.state.completionReason,
        InningsCompletionReason.targetChased,
      );
    });

    test('match complete when 2nd innings ends', () {
      final n = makeNotifier(inningsNumber: 2, target: 180, totalOvers: 1);
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.isInningsComplete, true);
      expect(n.state.isMatchComplete, true);
    });

    test('match not complete when 1st innings ends', () {
      final n = makeNotifier(totalOvers: 1);
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.isInningsComplete, true);
      expect(n.state.isMatchComplete, false);
    });

    test('no delivery after innings complete', () {
      final n = makeNotifier(playersPerSide: 2);
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      expect(n.state.isInningsComplete, true);

      n.recordDelivery(runsFromBat: 4);
      expect(n.state.totalRuns, 0); // Not changed
      expect(n.state.deliveryHistory.length, 1); // Only the wicket
    });
  });

  // ── ScoringNotifier: free hit ────────────────────────────────────────

  group('ScoringNotifier: free hit', () {
    test('free hit set after no-ball', () {
      final n = makeNotifier();
      n.recordNoBall();

      expect(n.state.isFreeHitPending, true);
    });

    test('free hit delivery has isFreeHit flag', () {
      final n = makeNotifier();
      n.recordNoBall();
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.deliveryHistory[1].isFreeHit, true);
    });

    test('free hit consumed after legal delivery', () {
      final n = makeNotifier();
      n.recordNoBall();
      n.recordDelivery(runsFromBat: 0);

      expect(n.state.isFreeHitPending, false);
    });

    test('free hit persists through wide', () {
      final n = makeNotifier();
      n.recordNoBall();
      n.recordWide(); // Wide on free hit → still free hit

      expect(n.state.isFreeHitPending, true);
    });

    test('no-ball on free hit continues free hit', () {
      final n = makeNotifier();
      n.recordNoBall();
      n.recordNoBall(); // NB on free hit → another free hit

      expect(n.state.isFreeHitPending, true);
    });
  });

  // ── ScoringNotifier: integrated scenarios ────────────────────────────

  group('ScoringNotifier: integrated scenarios', () {
    test('full over with mixed deliveries', () {
      final n = makeNotifier();
      n.recordDelivery(runsFromBat: 0); // Dot
      n.recordDelivery(runsFromBat: 1); // Single → swap
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true); // Four
      n.recordWide(); // Wide (+1)
      n.recordDelivery(runsFromBat: 0); // Dot
      n.recordDelivery(runsFromBat: 2); // Double
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true); // Six

      // 6 legal + 1 wide = 7 deliveries total
      expect(n.state.deliveryHistory.length, 7);
      expect(n.state.totalRuns, 14); // 0+1+4+1+0+2+6
      expect(n.state.totalBalls, 6);
      expect(n.state.completedOvers.length, 1);
    });

    test('all-out scenario with small team', () {
      final n = makeNotifier(playersPerSide: 3);

      // Wicket 1
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      n.selectNewBatter(playerId: 'bat-3', displayName: 'Batter 3');
      expect(n.state.isInningsComplete, false);

      // Wicket 2 → all out (3 - 1 = 2 wickets)
      n.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: 'bat-3',
        fielderId: 'fielder-1',
      );
      expect(n.state.isInningsComplete, true);
      expect(n.state.completionReason, InningsCompletionReason.allOut);
    });
  });
}
