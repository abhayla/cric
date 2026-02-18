import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

/// Full match integration tests: simulate complete matches through the
/// ScoringNotifier state machine, verifying end-to-end correctness.
void main() {
  List<PlayingXIPlayer> makePlayers(String prefix, int count) {
    return List.generate(
      count,
      (i) => PlayingXIPlayer(
        playerId: '$prefix-${i + 1}',
        displayName: '$prefix Player ${i + 1}',
        playerRole: i < 3 ? 'batter' : (i < 6 ? 'bowler' : 'all_rounder'),
      ),
    );
  }

  /// Create a notifier set up for a complete match with player rosters.
  ScoringNotifier makeMatchNotifier({
    int totalOvers = 2,
    int playersPerSide = 3,
    int wideRunsPenalty = 1,
    int noBallRunsPenalty = 1,
  }) {
    final battingPlayers = makePlayers('bat', playersPerSide);
    final bowlingPlayers = makePlayers('bowl', playersPerSide);

    final state = ScoringState(
      matchId: 'match-int',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      wideRunsPenalty: wideRunsPenalty,
      noBallRunsPenalty: noBallRunsPenalty,
      battingTeamPlayers: battingPlayers,
      bowlingTeamPlayers: bowlingPlayers,
    );

    final notifier = ScoringNotifier(state);
    notifier.selectNewBatter(
      playerId: 'bat-1',
      displayName: 'bat Player 1',
    );
    notifier.selectNewBatter(
      playerId: 'bat-2',
      displayName: 'bat Player 2',
    );
    notifier.selectNewBowler(
      playerId: 'bowl-1',
      displayName: 'bowl Player 1',
    );
    return notifier;
  }

  /// Bowl a complete over of dot balls through the notifier.
  void bowlDotOver(ScoringNotifier n, {required String nextBowlerId}) {
    for (var i = 0; i < 6; i++) {
      n.recordDelivery(runsFromBat: 0);
    }
    // After over, select the next bowler
    n.selectNewBowler(
      playerId: nextBowlerId,
      displayName: '$nextBowlerId name',
    );
  }

  /// Transition from 1st to 2nd innings using bowling team's players.
  void transitionInnings(ScoringNotifier n) {
    n.startSecondInnings(
      strikerId: 'bowl-1',
      strikerName: 'bowl Player 1',
      nonStrikerId: 'bowl-2',
      nonStrikerName: 'bowl Player 2',
      bowlerId: 'bat-1',
      bowlerName: 'bat Player 1',
    );
  }

  // ── Full match: overs exhausted both innings, win by runs ────────────

  group('Full match — win by runs', () {
    test('1st innings scores runs, 2nd innings overs exhausted below target',
        () {
      // 2-over match, 3 players per side
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // 1st innings: score 6 singles in over 1
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 1);
      }
      // Over complete — select new bowler
      n.selectNewBowler(playerId: 'bowl-2', displayName: 'bowl Player 2');

      // Over 2: score a boundary 4 on each ball
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      }

      // 1st innings complete (overs exhausted)
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.totalRuns, 30); // 6 + 24
      expect(n.state.totalBalls, 12);
      expect(n.state.completionReason, InningsCompletionReason.oversExhausted);

      // Transition to 2nd innings
      transitionInnings(n);
      expect(n.state.inningsNumber, 2);
      expect(n.state.target, 31); // 30 + 1

      // 2nd innings: all dot balls
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      n.selectNewBowler(playerId: 'bat-2', displayName: 'bat Player 2');
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      // Match complete — win by runs
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.isMatchComplete, isTrue);
      expect(n.state.totalRuns, 0);
      expect(n.state.matchResult, isNotNull);
      expect(n.state.matchResult!.resultType, MatchResultType.runs);
      expect(n.state.matchResult!.margin, 30);
      expect(n.state.matchResult!.winnerTeamName, 'Team Alpha');
    });
  });

  // ── Full match: target chased, win by wickets ────────────────────────

  group('Full match — win by wickets (target chased)', () {
    test('2nd innings chases target successfully', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // 1st innings: score 7 runs (over 1: 1,1,1,1,1,1 = 6)
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 1);
      }
      n.selectNewBowler(playerId: 'bowl-2', displayName: 'bowl Player 2');
      // Over 2: dot, dot, dot, dot, dot, 1 = 1 run
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      n.recordDelivery(runsFromBat: 1);

      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.totalRuns, 7);

      // Transition
      transitionInnings(n);
      expect(n.state.target, 8);

      // 2nd innings: score a six on first ball → then two singles
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true); // 6
      n.recordDelivery(runsFromBat: 1); // 7
      n.recordDelivery(runsFromBat: 1); // 8 → target chased!

      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.isMatchComplete, isTrue);
      expect(n.state.totalRuns, 8);
      expect(n.state.matchResult!.resultType, MatchResultType.wickets);
      // 3 players - 1 - 0 wickets = 2 wickets remaining
      expect(n.state.matchResult!.margin, 2);
      expect(n.state.matchResult!.winnerTeamName, 'Team Beta');
    });
  });

  // ── Full match: all-out in 1st innings ───────────────────────────────

  group('Full match — all-out triggers innings end', () {
    test('3-player team: 2 wickets = all-out', () {
      final n = makeMatchNotifier(totalOvers: 5, playersPerSide: 3);

      // Wicket 1
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      expect(n.state.totalWickets, 1);
      expect(n.state.needsNewBatter, isTrue);

      // Select new batter
      n.selectNewBatter(
        playerId: 'bat-3',
        displayName: 'bat Player 3',
      );

      // Wicket 2 (all-out: 3 - 1 = 2 wickets)
      n.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: n.state.strikerId!,
        fielderId: 'bowl-2',
        fielderName: 'bowl Player 2',
      );

      expect(n.state.totalWickets, 2);
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.completionReason, InningsCompletionReason.allOut);
    });
  });

  // ── Full match: tie result ───────────────────────────────────────────

  group('Full match — tie', () {
    test('both innings score equal runs', () {
      final n = makeMatchNotifier(totalOvers: 1, playersPerSide: 3);

      // 1st innings: 6 dot balls = 0 runs
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.totalRuns, 0);

      // Transition
      transitionInnings(n);
      expect(n.state.target, 1); // 0 + 1

      // 2nd innings: all-out with 0 runs (2 wickets in 1-over match)
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bowl-1',
      );
      n.selectNewBatter(
        playerId: 'bowl-3',
        displayName: 'bowl Player 3',
      );
      n.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: n.state.strikerId!,
      );

      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.isMatchComplete, isTrue);
      expect(n.state.totalRuns, 0);
      expect(n.state.matchResult!.resultType, MatchResultType.tie);
      expect(n.state.matchResult!.resultDescription, 'Match Tied');
    });
  });

  // ── Extras flow across full match ────────────────────────────────────

  group('Full match — extras handling', () {
    test('wides and no-balls don\'t count toward over completion', () {
      final n = makeMatchNotifier(totalOvers: 1, playersPerSide: 3);

      // Bowl 3 wides, 3 no-balls, then 6 legal dot balls
      for (var i = 0; i < 3; i++) {
        n.recordWide(additionalRuns: 0); // 1 penalty each
      }
      for (var i = 0; i < 3; i++) {
        n.recordNoBall(runsFromBat: 0); // 1 penalty each
      }

      // Over is NOT complete — extras don't count
      expect(n.state.currentOverBalls, 0);
      expect(n.state.totalRuns, 6); // 3 wides + 3 no-balls = 6

      // Now 6 legal deliveries
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.totalBalls, 6); // Only legal balls
      expect(n.state.totalRuns, 6); // Only extras
      expect(n.state.totalWides, 3);
      expect(n.state.totalNoBalls, 3);
    });

    test('bye and leg-bye runs count toward innings total', () {
      final n = makeMatchNotifier(totalOvers: 1, playersPerSide: 3);

      n.recordBye(byeRuns: 2);
      n.recordLegBye(legByeRuns: 3);

      expect(n.state.totalRuns, 5);
      expect(n.state.totalByes, 2);
      expect(n.state.totalLegByes, 3);
      expect(n.state.totalBalls, 2); // Both are legal
    });
  });

  // ── Free hit chain across overs ──────────────────────────────────────

  group('Full match — free hit mechanics', () {
    test('no-ball triggers free hit, consumed by legal delivery', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // No-ball → free hit pending
      n.recordNoBall(runsFromBat: 0);
      expect(n.state.isFreeHitPending, isTrue);

      // Legal delivery on free hit → consumed
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(n.state.isFreeHitPending, isFalse);
    });

    test('wide on free hit keeps free hit pending', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // No-ball → free hit
      n.recordNoBall(runsFromBat: 0);
      expect(n.state.isFreeHitPending, isTrue);

      // Wide on free hit → free hit persists
      n.recordWide(additionalRuns: 0);
      expect(n.state.isFreeHitPending, isTrue);

      // Legal delivery → consumed
      n.recordDelivery(runsFromBat: 0);
      expect(n.state.isFreeHitPending, isFalse);
    });

    test('no-ball on free hit chains another free hit', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      n.recordNoBall(runsFromBat: 0); // Free hit pending
      n.recordNoBall(runsFromBat: 0); // Another no-ball → still free hit
      expect(n.state.isFreeHitPending, isTrue);

      n.recordDelivery(runsFromBat: 0); // Consume free hit
      expect(n.state.isFreeHitPending, isFalse);
    });
  });

  // ── Strike rotation across overs ─────────────────────────────────────

  group('Full match — strike rotation', () {
    test('odd runs swap strike, end of over swaps again', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      final originalStriker = n.state.strikerId;

      // Ball 1: 1 run → strike swaps
      n.recordDelivery(runsFromBat: 1);
      expect(n.state.strikerId, isNot(originalStriker));

      // Ball 2-6: dots → no swap
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      // End of over → strike swaps back
      // After the over, before selecting new bowler:
      // 1 run swapped once, end of over swaps again = back to original
      expect(n.state.strikerId, originalStriker);
    });

    test('even runs do not swap strike', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      final originalStriker = n.state.strikerId;

      n.recordDelivery(runsFromBat: 2);
      expect(n.state.strikerId, originalStriker);

      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(n.state.strikerId, originalStriker);

      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      expect(n.state.strikerId, originalStriker);
    });
  });

  // ── Maiden over detection ────────────────────────────────────────────

  group('Full match — maiden over', () {
    test('6 dot balls produces a maiden', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }

      // Check bowler's maiden count
      expect(n.state.bowlerStats['bowl-1']!.maidens, 1);
      expect(n.state.completedOvers.last.isMaiden, isTrue);
    });

    test('byes in over do not break maiden', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // 5 dots + 1 bye
      for (var i = 0; i < 5; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      n.recordBye(byeRuns: 1);

      // Over complete — should still be maiden (byes don't break maiden)
      expect(n.state.bowlerStats['bowl-1']!.maidens, 1);
    });
  });

  // ── Undo in integration context ──────────────────────────────────────

  group('Full match — undo mechanics', () {
    test('undo reverses delivery and restores previous state', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Score a four
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(n.state.totalRuns, 4);
      expect(n.state.totalBalls, 1);

      // Undo
      n.undoLastDelivery();
      expect(n.state.totalRuns, 0);
      expect(n.state.totalBalls, 0);
      expect(n.state.deliveryHistory, isEmpty);
    });

    test('undo wide restores extras count', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      n.recordWide(additionalRuns: 2);
      expect(n.state.totalRuns, 3); // 1 penalty + 2 additional
      expect(n.state.totalWides, 3);

      n.undoLastDelivery();
      expect(n.state.totalRuns, 0);
      expect(n.state.totalWides, 0);
    });

    test('undo after over reopens the over', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Bowl 6 dots (over complete)
      for (var i = 0; i < 6; i++) {
        n.recordDelivery(runsFromBat: 0);
      }
      expect(n.state.completedOvers, hasLength(1));
      expect(n.state.currentOverBalls, 0);
      expect(n.state.bowlerId, isNull); // Cleared after over

      // Undo without selecting new bowler first
      n.undoLastDelivery();

      // Over should be reopened: 5 balls in current over
      expect(n.state.currentOverBalls, 5);
      expect(n.state.completedOvers, isEmpty);
      expect(n.state.bowlerId, 'bowl-1'); // Restored
    });
  });

  // ── Batter/bowler stats accumulation ─────────────────────────────────

  group('Full match — stats accumulation', () {
    test('batter stats accumulate across deliveries', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Strike: bat-1
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true); // 4(1) 1x4
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true); // 10(2) 1x4 1x6
      n.recordDelivery(runsFromBat: 1); // 11(3) — swaps strike
      // Now bat-2 on strike
      n.recordDelivery(runsFromBat: 0); // bat-2: 0(1)
      n.recordDelivery(runsFromBat: 2); // bat-2: 2(2)
      n.recordDelivery(runsFromBat: 0); // bat-2: 2(3)

      final bat1 = n.state.batterStats['bat-1']!;
      expect(bat1.runsScored, 11);
      expect(bat1.ballsFaced, 3);
      expect(bat1.fours, 1);
      expect(bat1.sixes, 1);

      final bat2 = n.state.batterStats['bat-2']!;
      expect(bat2.runsScored, 2);
      expect(bat2.ballsFaced, 3);
    });

    test('bowler stats accumulate correctly', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Over 1: bowl-1 bowls 6 balls, concedes 4 runs
      n.recordDelivery(runsFromBat: 0); // dot
      n.recordDelivery(runsFromBat: 0); // dot
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      n.recordDelivery(runsFromBat: 0); // dot
      n.recordDelivery(runsFromBat: 0); // dot
      n.recordDelivery(runsFromBat: 0); // dot

      final bowl1 = n.state.bowlerStats['bowl-1']!;
      expect(bowl1.ballsBowled, 6);
      expect(bowl1.runsConceded, 4);
      expect(bowl1.wicketsTaken, 0);
      expect(bowl1.maidens, 0); // Not maiden (4 runs conceded)
      expect(bowl1.dotBalls, 5);
    });
  });

  // ── Stumping off a wide ────────────────────────────────────────────
  group('Full match — stumping off wide', () {
    test('wide + stumped: wide runs scored, wicket counted, bowler credited',
        () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Record a stumping off a wide
      n.recordWicket(
        dismissalType: DismissalType.stumped,
        dismissedPlayerId: 'bat-1',
        fielderId: 'bowl-2', // keeper
        isWide: true,
      );

      // Wide runs should be added to total (1 penalty)
      expect(n.state.totalRuns, 1); // 1 wide run
      expect(n.state.totalWides, 1);
      expect(n.state.totalWickets, 1);

      // The delivery is NOT legal (wide)
      expect(n.state.totalBalls, 0);

      // Batter dismissed
      expect(n.state.needsNewBatter, isTrue);

      // Bowler gets credit for stumped
      final bowler = n.state.bowlerStats['bowl-1']!;
      expect(bowler.wicketsTaken, 1);
      expect(bowler.wides, 1);
    });
  });

  // ── Declaration triggers innings complete ───────────────────────────
  group('Full match — declaration flow', () {
    test('declare 1st innings, then 2nd innings plays normally', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Score some runs in 1st innings
      n.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      // Total: 10 runs from 2 balls

      // Declare
      n.declareInnings();
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.completionReason, InningsCompletionReason.declared);
      expect(n.state.totalRuns, 10);

      // Transition to 2nd innings
      transitionInnings(n);
      expect(n.state.inningsNumber, 2);
      expect(n.state.target, 11); // 10 + 1

      // Chase the target
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      n.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      // Match complete — target chased (12 >= 11)
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.isMatchComplete, isTrue);
      expect(n.state.completionReason, InningsCompletionReason.targetChased);
      expect(n.state.matchResult, isNotNull);
      expect(n.state.matchResult!.resultType, MatchResultType.wickets);
    });

    test('declaration is no-op on 2nd innings', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Complete 1st innings by exhausting overs
      for (var i = 0; i < 12; i++) {
        n.recordDelivery(runsFromBat: 0);
        if (i == 5) {
          n.selectNewBowler(
              playerId: 'bowl-2', displayName: 'bowl Player 2');
        }
      }

      // Start 2nd innings
      transitionInnings(n);
      expect(n.state.inningsNumber, 2);

      // Try to declare in 2nd innings — should be no-op
      n.declareInnings();
      expect(n.state.isInningsComplete, isFalse);
    });

    test('declaration is no-op when innings already complete', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      n.declareInnings();
      expect(n.state.isInningsComplete, isTrue);
      expect(n.state.completionReason, InningsCompletionReason.declared);

      // Declare again — should not throw or change state
      n.declareInnings();
      expect(n.state.completionReason, InningsCompletionReason.declared);
    });
  });

  // ── Free hit with stumping (only run-out valid) ─────────────────────
  group('Full match — free hit restrictions', () {
    test('run-out on free hit is valid wicket', () {
      final n = makeMatchNotifier(totalOvers: 2, playersPerSide: 3);

      // Trigger free hit via no-ball
      n.recordNoBall(runsFromBat: 0);
      expect(n.state.isFreeHitPending, isTrue);

      // Run-out on free hit — should be valid
      n.recordWicket(
        dismissalType: DismissalType.runOut,
        dismissedPlayerId: 'bat-1',
        fielderId: 'bowl-2',
        runsFromBat: 1,
      );

      expect(n.state.totalWickets, 1);
      expect(n.state.needsNewBatter, isTrue);
      // Free hit consumed
      expect(n.state.isFreeHitPending, isFalse);
    });
  });
}
