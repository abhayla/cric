import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  /// Helper: create a notifier with batters and bowler pre-selected.
  /// Uses 6-over format with configurable magic over settings.
  ScoringNotifier makeNotifier({
    int totalOvers = 6,
    int playersPerSide = 6,
    int inningsNumber = 1,
    int? target,
    List<int>? magicOverNumbers = const [4],
    int magicOverRunMultiplier = 2,
    int magicOverWicketPenalty = -5,
    int wideRunsPenalty = 1,
    int noBallRunsPenalty = 1,
    List<PlayingXIPlayer>? bowlingTeamPlayers,
  }) {
    final defaultBowlingPlayers = [
      const PlayingXIPlayer(playerId: 'bowl-1', displayName: 'Bowler 1'),
      const PlayingXIPlayer(playerId: 'bowl-2', displayName: 'Bowler 2'),
      const PlayingXIPlayer(playerId: 'bowl-3', displayName: 'Bowler 3'),
      const PlayingXIPlayer(playerId: 'bowl-4', displayName: 'Bowler 4'),
      const PlayingXIPlayer(playerId: 'bowl-5', displayName: 'Bowler 5'),
      const PlayingXIPlayer(playerId: 'bowl-6', displayName: 'Bowler 6'),
    ];

    final state = ScoringState(
      matchId: 'match-1',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      inningsNumber: inningsNumber,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      wideRunsPenalty: wideRunsPenalty,
      noBallRunsPenalty: noBallRunsPenalty,
      magicOverNumbers: magicOverNumbers,
      magicOverRunMultiplier: magicOverRunMultiplier,
      magicOverWicketPenalty: magicOverWicketPenalty,
      target: target,
      strikerId: 'bat-1',
      nonStrikerId: 'bat-2',
      bowlerId: 'bowl-1',
      bowlingTeamPlayers: bowlingTeamPlayers ?? defaultBowlingPlayers,
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

  /// Helper: bowl a full over of dot balls.
  void bowlDotOver(ScoringNotifier notifier) {
    for (var i = 0; i < 6; i++) {
      notifier.recordDelivery(runsFromBat: 0);
    }
  }

  /// Helper: select a new bowler for the next over.
  void selectBowler(ScoringNotifier notifier, String bowlerId, String name) {
    notifier.selectNewBowler(playerId: bowlerId, displayName: name);
  }

  /// Helper: advance to a specific over (1-based) by bowling full dot overs.
  void advanceToOver(ScoringNotifier notifier, int targetOver) {
    final bowlerNames = [
      'Bowler 1', 'Bowler 2', 'Bowler 3',
      'Bowler 4', 'Bowler 5', 'Bowler 6',
    ];
    for (var over = 1; over < targetOver; over++) {
      bowlDotOver(notifier);
      if (over < targetOver) {
        final nextBowlerId = 'bowl-${(over % 6) + 1}';
        selectBowler(notifier, nextBowlerId, bowlerNames[over % 6]);
      }
    }
  }

  group('Magic Over — runs multiplied (default 2x)', () {
    test('runs scored during magic over are doubled', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      expect(notifier.state.currentOverNumber, 4);
      notifier.recordDelivery(runsFromBat: 1);

      expect(notifier.state.totalRuns, 2); // 1 * 2 = 2
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, true);
    });

    test('boundary four during magic over becomes 8 runs', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 8);
    });

    test('boundary six during magic over becomes 12 runs', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      expect(notifier.state.totalRuns, 12);
    });

    test('dot ball during magic over stays 0', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 0);
      expect(notifier.state.totalRuns, 0);
    });

    test('runs NOT multiplied on non-magic overs', () {
      final notifier = makeNotifier();

      // Over 1: score a four — should stay 4
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(notifier.state.totalRuns, 4);
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, false);
    });

    test('no multiplying when magicOverNumbers is null', () {
      final notifier = makeNotifier(magicOverNumbers: null);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 4);
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, false);
    });

    test('no multiplying when magicOverNumbers is empty', () {
      final notifier = makeNotifier(magicOverNumbers: []);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 4);
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, false);
    });
  });

  group('Magic Over — configurable multiplier', () {
    test('1x multiplier has no effect', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 1);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 4); // 4 * 1 = 4
    });

    test('3x multiplier triples runs', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 3);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 2);
      expect(notifier.state.totalRuns, 6); // 2 * 3 = 6
    });

    test('5x multiplier quintuples runs', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 5);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 20); // 4 * 5 = 20
    });
  });

  group('Magic Over — multiple magic overs', () {
    test('multiple magic overs apply to all specified overs', () {
      final notifier = makeNotifier(magicOverNumbers: [3, 5]);
      advanceToOver(notifier, 3);

      // Over 3 is magic
      notifier.recordDelivery(runsFromBat: 2);
      expect(notifier.state.totalRuns, 4); // 2 * 2 = 4

      // Complete over 3
      for (var i = 0; i < 5; i++) {
        notifier.recordDelivery(runsFromBat: 0);
      }

      // Over 4 is NOT magic
      selectBowler(notifier, 'bowl-3', 'Bowler 3');
      notifier.recordDelivery(runsFromBat: 2);
      expect(notifier.state.totalRuns, 6); // 4 + 2 (not multiplied)

      // Complete over 4
      for (var i = 0; i < 5; i++) {
        notifier.recordDelivery(runsFromBat: 0);
      }

      // Over 5 is magic
      selectBowler(notifier, 'bowl-4', 'Bowler 4');
      notifier.recordDelivery(runsFromBat: 1);
      expect(notifier.state.totalRuns, 8); // 6 + (1 * 2) = 8
    });

    test('over not in magicOverNumbers is not magic', () {
      final notifier = makeNotifier(magicOverNumbers: [3, 5]);
      advanceToOver(notifier, 4);

      expect(notifier.state.isMagicOver, false);
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 4); // Not multiplied
    });
  });

  group('Magic Over — wicket penalty', () {
    test('wicket in magic over applies penalty', () {
      final notifier = makeNotifier(magicOverWicketPenalty: -5);
      advanceToOver(notifier, 4);

      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: notifier.state.strikerId!,
      );

      // Penalty: -5 runs applied to total
      expect(notifier.state.totalRuns, -5);
      expect(notifier.state.totalWickets, 1);
      expect(notifier.state.deliveryHistory.last.magicOverPenaltyApplied, -5);
    });

    test('wicket penalty of 0 has no effect', () {
      final notifier = makeNotifier(magicOverWicketPenalty: 0);
      advanceToOver(notifier, 4);

      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: notifier.state.strikerId!,
      );

      expect(notifier.state.totalRuns, 0);
    });

    test('wicket penalty of -20 (max) deducts 20 runs', () {
      final notifier = makeNotifier(magicOverWicketPenalty: -20);
      advanceToOver(notifier, 4);

      // Score 10 runs first
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 8); // 4 * 2 = 8

      // Select new batter after we'll need it
      final strikerId = notifier.state.strikerId!;
      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: strikerId,
      );

      // 8 + 0 + (-20) = -12
      expect(notifier.state.totalRuns, -12);
    });

    test('no wicket penalty on non-magic over', () {
      final notifier = makeNotifier();

      // Over 1: not magic
      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: notifier.state.strikerId!,
      );

      expect(notifier.state.totalRuns, 0);
      expect(notifier.state.deliveryHistory.last.magicOverPenaltyApplied, 0);
    });

    test('wicket with runs in magic over applies both multiplier and penalty', () {
      final notifier = makeNotifier(
        magicOverRunMultiplier: 3,
        magicOverWicketPenalty: -7,
      );
      advanceToOver(notifier, 4);

      // Run out with 2 runs scored before dismissal
      notifier.recordWicket(
        runsFromBat: 2,
        dismissalType: DismissalType.runOut,
        dismissedPlayerId: notifier.state.nonStrikerId!,
      );

      // Runs: 2 * 3 = 6, penalty: -7, total: 6 + (-7) = -1
      expect(notifier.state.totalRuns, -1);
    });
  });

  group('Magic Over — extras multiplied', () {
    test('wide runs during magic over are multiplied', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 3);
      advanceToOver(notifier, 4);

      notifier.recordWide(); // 1 wide run * 3 = 3
      expect(notifier.state.totalRuns, 3);
    });

    test('no-ball runs during magic over are multiplied', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 2);
      advanceToOver(notifier, 4);

      notifier.recordNoBall(runsFromBat: 2); // (1 NB + 2 bat) * 2 = 6
      expect(notifier.state.totalRuns, 6);
    });

    test('bye runs during magic over are multiplied', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 2);
      advanceToOver(notifier, 4);

      notifier.recordBye(byeRuns: 2);
      expect(notifier.state.totalRuns, 4); // 2 * 2 = 4
    });

    test('leg-bye runs during magic over are multiplied', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 2);
      advanceToOver(notifier, 4);

      notifier.recordLegBye(legByeRuns: 1);
      expect(notifier.state.totalRuns, 2); // 1 * 2 = 2
    });
  });

  group('Magic Over — strike rotation uses original runs', () {
    test('single in magic over doubles to 2 but SWAPS strike (odd original)', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 1);

      expect(notifier.state.strikerId, isNot(strikerBefore));
      expect(notifier.state.totalRuns, 2);
    });

    test('two in magic over doubles to 4 but NO swap (even original)', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 2);

      expect(notifier.state.strikerId, strikerBefore);
      expect(notifier.state.totalRuns, 4);
    });

    test('three in magic over doubles to 6 but SWAPS strike (odd original)', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 3);

      expect(notifier.state.strikerId, isNot(strikerBefore));
      expect(notifier.state.totalRuns, 6);
    });
  });

  group('Magic Over — batter/bowler stats use multiplied runs', () {
    test('batter runsScored uses multiplied runs during magic over', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 3);
      advanceToOver(notifier, 4);

      final strikerId = notifier.state.strikerId!;
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      final batter = notifier.state.batterStats[strikerId]!;
      expect(batter.runsScored, 12); // 4 * 3 = 12
    });

    test('bowler runsConceded uses multiplied runs during magic over', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 3);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 2);

      final bowler = notifier.state.bowlerStats[notifier.state.bowlerId]!;
      expect(bowler.runsConceded, 6); // 2 * 3 = 6
    });
  });

  group('Magic Over — undo reverses multiplied amount + penalty', () {
    test('undo a magic over delivery correctly removes multiplied runs', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 3);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 12);

      notifier.undoLastDelivery();
      expect(notifier.state.totalRuns, 0);
    });

    test('undo a magic over wicket reverses penalty', () {
      final notifier = makeNotifier(magicOverWicketPenalty: -5);
      advanceToOver(notifier, 4);

      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: notifier.state.strikerId!,
      );
      expect(notifier.state.totalRuns, -5);
      expect(notifier.state.totalWickets, 1);

      notifier.undoLastDelivery();
      expect(notifier.state.totalRuns, 0);
      expect(notifier.state.totalWickets, 0);
    });

    test('undo strike rotation correct for magic over delivery', () {
      final notifier = makeNotifier();
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 1); // Odd → swap
      expect(notifier.state.strikerId, isNot(strikerBefore));

      notifier.undoLastDelivery();
      expect(notifier.state.strikerId, strikerBefore);
    });
  });

  group('Magic Over — target chase uses multiplied runs', () {
    test('target chased mid-magic-over with multiplied runs', () {
      final notifier = makeNotifier(
        magicOverRunMultiplier: 2,
        inningsNumber: 2,
        target: 10,
      );
      advanceToOver(notifier, 4);

      expect(notifier.state.currentOverNumber, 4);
      expect(notifier.state.isInningsComplete, false);

      // Need 10 to win. Score a six in magic over → 12 runs
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(notifier.state.totalRuns, 12);
      expect(notifier.state.isInningsComplete, true);
      expect(notifier.state.completionReason, InningsCompletionReason.targetChased);
    });
  });

  group('Magic Over — state fields', () {
    test('state preserves magicOverNumbers', () {
      final notifier = makeNotifier(magicOverNumbers: [3, 5]);
      expect(notifier.state.magicOverNumbers, [3, 5]);
    });

    test('state preserves null magicOverNumbers', () {
      final notifier = makeNotifier(magicOverNumbers: null);
      expect(notifier.state.magicOverNumbers, isNull);
    });

    test('state preserves magicOverRunMultiplier', () {
      final notifier = makeNotifier(magicOverRunMultiplier: 4);
      expect(notifier.state.magicOverRunMultiplier, 4);
    });

    test('state preserves magicOverWicketPenalty', () {
      final notifier = makeNotifier(magicOverWicketPenalty: -10);
      expect(notifier.state.magicOverWicketPenalty, -10);
    });

    test('isMagicOver computed getter works', () {
      final notifier = makeNotifier(magicOverNumbers: [3, 5]);

      // Over 1 is not magic
      expect(notifier.state.isMagicOver, false);

      advanceToOver(notifier, 3);
      expect(notifier.state.isMagicOver, true);
    });

    test('copyWith preserves all magic over fields', () {
      final notifier = makeNotifier(
        magicOverNumbers: [2, 4],
        magicOverRunMultiplier: 3,
        magicOverWicketPenalty: -7,
      );
      final copied = notifier.state.copyWith(totalRuns: 100);
      expect(copied.magicOverNumbers, [2, 4]);
      expect(copied.magicOverRunMultiplier, 3);
      expect(copied.magicOverWicketPenalty, -7);
    });
  });

  group('Magic Over — second innings carries config', () {
    test('startSecondInnings preserves all magic over fields', () {
      final notifier = makeNotifier(
        magicOverNumbers: [3, 5],
        magicOverRunMultiplier: 4,
        magicOverWicketPenalty: -10,
        playersPerSide: 6,
        totalOvers: 6,
      );

      // Complete 1st innings by bowling 6 overs of dots
      for (var over = 0; over < 6; over++) {
        bowlDotOver(notifier);
        if (over < 5) {
          selectBowler(
            notifier,
            'bowl-${(over % 6) + 2 > 6 ? ((over % 6) + 2) - 6 : (over % 6) + 2}',
            'Bowler ${(over % 6) + 2 > 6 ? ((over % 6) + 2) - 6 : (over % 6) + 2}',
          );
        }
      }

      expect(notifier.state.isInningsComplete, true);

      notifier.startSecondInnings(
        strikerId: 'bowl-1',
        strikerName: 'Bowler 1',
        nonStrikerId: 'bowl-2',
        nonStrikerName: 'Bowler 2',
        bowlerId: 'bat-1',
        bowlerName: 'Batter 1',
      );

      expect(notifier.state.magicOverNumbers, [3, 5]);
      expect(notifier.state.magicOverRunMultiplier, 4);
      expect(notifier.state.magicOverWicketPenalty, -10);
      expect(notifier.state.inningsNumber, 2);
    });
  });
}
