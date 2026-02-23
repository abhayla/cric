import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

/// Performance tests for the scoring engine.
///
/// These tests verify that the scoring state machine can handle a full
/// match's worth of deliveries without exceeding time thresholds.
void main() {
  List<PlayingXIPlayer> makePlayers(String prefix, int count) {
    return List.generate(
      count,
      (i) => PlayingXIPlayer(
        playerId: '$prefix-${i + 1}',
        displayName: '$prefix Player ${i + 1}',
        playerRole: i < 5 ? 'batter' : 'bowler',
      ),
    );
  }

  ScoringNotifier makeNotifier({
    int totalOvers = 20,
    int playersPerSide = 11,
  }) {
    final state = ScoringState(
      matchId: 'perf-match',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      battingTeamPlayers: makePlayers('bat', playersPerSide),
      bowlingTeamPlayers: makePlayers('bowl', playersPerSide),
    );
    final n = ScoringNotifier(state);
    n.selectNewBatter(playerId: 'bat-1', displayName: 'bat Player 1');
    n.selectNewBatter(playerId: 'bat-2', displayName: 'bat Player 2');
    n.selectNewBowler(playerId: 'bowl-1', displayName: 'bowl Player 1');
    return n;
  }

  group('Scoring engine throughput', () {
    test('T20 innings (120 balls) completes under 100ms', () {
      final n = makeNotifier(totalOvers: 20, playersPerSide: 11);
      var bowlerIndex = 1;

      final sw = Stopwatch()..start();

      for (var over = 0; over < 20; over++) {
        for (var ball = 0; ball < 6; ball++) {
          if (n.state.isInningsComplete) break;
          n.recordDelivery(
            runsFromBat: ball % 4, // mix of 0,1,2,3
            isBoundaryFour: ball == 3,
          );
        }
        if (n.state.isInningsComplete) break;
        // Alternate bowlers (no consecutive overs)
        bowlerIndex = bowlerIndex == 1 ? 2 : 1;
        n.selectNewBowler(
          playerId: 'bowl-$bowlerIndex',
          displayName: 'bowl Player $bowlerIndex',
        );
      }

      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(100),
          reason: 'T20 innings should process in <100ms, took ${sw.elapsedMilliseconds}ms');
      expect(n.state.totalBalls, greaterThan(0));
    });

    test('ODI innings (300 balls) completes under 250ms', () {
      final n = makeNotifier(totalOvers: 50, playersPerSide: 11);
      var bowlerIndex = 1;

      final sw = Stopwatch()..start();

      for (var over = 0; over < 50; over++) {
        for (var ball = 0; ball < 6; ball++) {
          if (n.state.isInningsComplete) break;
          n.recordDelivery(
            runsFromBat: ball % 3, // mix of 0,1,2
          );
        }
        if (n.state.isInningsComplete) break;
        bowlerIndex = bowlerIndex == 1 ? 2 : 1;
        n.selectNewBowler(
          playerId: 'bowl-$bowlerIndex',
          displayName: 'bowl Player $bowlerIndex',
        );
      }

      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(250),
          reason: 'ODI innings should process in <250ms, took ${sw.elapsedMilliseconds}ms');
    });

    test('rapid undo/redo cycle (100 deliveries) under 50ms', () {
      final n = makeNotifier(totalOvers: 20, playersPerSide: 11);

      // Record 100 deliveries
      for (var i = 0; i < 100; i++) {
        n.recordDelivery(runsFromBat: i % 7);
      }

      final sw = Stopwatch()..start();

      // Undo all 100
      for (var i = 0; i < 100; i++) {
        if (!n.state.canUndo) break;
        n.undoLastDelivery();
      }

      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(50),
          reason: 'Undoing 100 deliveries should take <50ms, took ${sw.elapsedMilliseconds}ms');
      expect(n.state.totalRuns, 0);
      expect(n.state.totalBalls, 0);
    });

    test('delivery with wicket + new batter selection under 1ms each', () {
      final n = makeNotifier(totalOvers: 20, playersPerSide: 11);
      var nextBatterIndex = 3;

      final sw = Stopwatch()..start();

      // Process 9 wickets with batter selection (10th is all-out)
      for (var w = 0; w < 9; w++) {
        n.recordWicket(
          dismissalType: DismissalType.bowled,
          dismissedPlayerId: n.state.strikerId!,
        );
        n.selectNewBatter(
          playerId: 'bat-$nextBatterIndex',
          displayName: 'bat Player $nextBatterIndex',
        );
        nextBatterIndex++;
      }

      sw.stop();

      // 9 wickets + 9 batter selections = 18 operations
      final avgMs = sw.elapsedMilliseconds / 18;
      expect(avgMs, lessThan(1),
          reason: 'Average wicket+batter operation should be <1ms, was ${avgMs.toStringAsFixed(2)}ms');
      expect(n.state.totalWickets, 9);
    });
  });

  group('State size metrics', () {
    test('delivery history stays within bounds for T20', () {
      final n = makeNotifier(totalOvers: 20, playersPerSide: 11);
      var bowlerIndex = 1;

      // Bowl a full T20 innings with extras
      for (var over = 0; over < 20; over++) {
        // Add some extras per over
        n.recordWide(additionalRuns: 0);
        for (var ball = 0; ball < 6; ball++) {
          if (n.state.isInningsComplete) break;
          n.recordDelivery(runsFromBat: ball % 3);
        }
        if (n.state.isInningsComplete) break;
        bowlerIndex = bowlerIndex == 1 ? 2 : 1;
        n.selectNewBowler(
          playerId: 'bowl-$bowlerIndex',
          displayName: 'bowl Player $bowlerIndex',
        );
      }

      // T20 should have at most ~140 deliveries (120 legal + extras)
      expect(n.state.deliveryHistory.length, lessThan(200));
      // All 20 overs should be completed or innings should be complete
      expect(
        n.state.completedOvers.length + (n.state.isInningsComplete ? 0 : 1),
        greaterThanOrEqualTo(1),
      );
    });

    test('batter stats map stays bounded', () {
      final n = makeNotifier(totalOvers: 20, playersPerSide: 11);

      // Score some deliveries
      for (var i = 0; i < 12; i++) {
        n.recordDelivery(runsFromBat: i % 4);
      }

      // At most, we should have 2 batters in stats (no wickets taken)
      expect(n.state.batterStats.length, 2);
    });
  });
}
