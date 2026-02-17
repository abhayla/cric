import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  /// Helper: create a notifier with batters and bowler pre-selected.
  /// Uses 6-over format with magic over on over 4.
  ScoringNotifier makeNotifier({
    int totalOvers = 6,
    int playersPerSide = 6,
    int inningsNumber = 1,
    int? target,
    int? magicOverNumber = 4,
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
      magicOverNumber: magicOverNumber,
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
  /// Returns the notifier at the start of the target over with a bowler set.
  void advanceToOver(ScoringNotifier notifier, int targetOver) {
    final bowlerNames = ['Bowler 1', 'Bowler 2', 'Bowler 3', 'Bowler 4', 'Bowler 5', 'Bowler 6'];
    for (var over = 1; over < targetOver; over++) {
      bowlDotOver(notifier);
      if (over < targetOver) {
        // Select next bowler (can't be same as last)
        final nextBowlerId = 'bowl-${(over % 6) + 1}';
        selectBowler(notifier, nextBowlerId, bowlerNames[over % 6]);
      }
    }
  }

  group('Magic Over — runs doubling', () {
    test('runs scored during magic over are doubled', () {
      final notifier = makeNotifier(magicOverNumber: 4);

      // Advance to over 4 (the magic over)
      advanceToOver(notifier, 4);

      // Verify we're on over 4
      expect(notifier.state.currentOverNumber, 4);

      // Score a single — should become 2 runs
      notifier.recordDelivery(runsFromBat: 1);

      expect(notifier.state.totalRuns, 2); // 1 * 2 = 2
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, true);
    });

    test('boundary four during magic over becomes 8 runs', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(notifier.state.totalRuns, 8); // 4 * 2 = 8
    });

    test('boundary six during magic over becomes 12 runs', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(notifier.state.totalRuns, 12); // 6 * 2 = 12
    });

    test('dot ball during magic over stays 0', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 0);

      expect(notifier.state.totalRuns, 0); // 0 * 2 = 0, no change
    });

    test('runs NOT doubled on non-magic overs', () {
      final notifier = makeNotifier(magicOverNumber: 4);

      // Over 1: score a four — should stay 4
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(notifier.state.totalRuns, 4);
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, false);
    });

    test('no doubling when magicOverNumber is null', () {
      final notifier = makeNotifier(magicOverNumber: null);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(notifier.state.totalRuns, 4); // No magic over — stays 4
      expect(notifier.state.deliveryHistory.last.isMagicOverDelivery, false);
    });
  });

  group('Magic Over — extras doubling', () {
    test('wide runs during magic over are doubled', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordWide(); // 1 wide run

      expect(notifier.state.totalRuns, 2); // 1 * 2 = 2
    });

    test('no-ball runs during magic over are doubled', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordNoBall(runsFromBat: 2); // 1 NB + 2 bat = 3

      expect(notifier.state.totalRuns, 6); // 3 * 2 = 6
    });

    test('bye runs during magic over are doubled', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordBye(byeRuns: 2);

      expect(notifier.state.totalRuns, 4); // 2 * 2 = 4
    });

    test('leg-bye runs during magic over are doubled', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordLegBye(legByeRuns: 1);

      expect(notifier.state.totalRuns, 2); // 1 * 2 = 2
    });
  });

  group('Magic Over — strike rotation uses original runs', () {
    test('single in magic over doubles to 2 but SWAPS strike (odd original)', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 1);

      // Original runs = 1 (odd) → should swap
      expect(notifier.state.strikerId, isNot(strikerBefore));
      expect(notifier.state.totalRuns, 2); // But score doubled
    });

    test('two in magic over doubles to 4 but NO swap (even original)', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 2);

      // Original runs = 2 (even) → no swap
      expect(notifier.state.strikerId, strikerBefore);
      expect(notifier.state.totalRuns, 4); // But score doubled
    });

    test('three in magic over doubles to 6 but SWAPS strike (odd original)', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      final strikerBefore = notifier.state.strikerId;
      notifier.recordDelivery(runsFromBat: 3);

      // Original runs = 3 (odd) → should swap
      expect(notifier.state.strikerId, isNot(strikerBefore));
      expect(notifier.state.totalRuns, 6);
    });
  });

  group('Magic Over — batter stats use doubled runs', () {
    test('batter runsScored uses doubled runs during magic over', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      final strikerId = notifier.state.strikerId!;
      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      // Batter should be credited with 8 runs (doubled)
      final batter = notifier.state.batterStats[strikerId]!;
      expect(batter.runsScored, 8);
    });
  });

  group('Magic Over — bowler stats use doubled runs', () {
    test('bowler runsConceded uses doubled runs during magic over', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 2);

      // Bowler concedes 4 (doubled) — batting runs are doubled
      final bowler = notifier.state.bowlerStats[notifier.state.bowlerId]!;
      expect(bowler.runsConceded, 4);
    });
  });

  group('Magic Over — undo reverses doubled amount', () {
    test('undo a magic over delivery correctly removes doubled runs', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      advanceToOver(notifier, 4);

      notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(notifier.state.totalRuns, 8);

      notifier.undoLastDelivery();
      expect(notifier.state.totalRuns, 0); // Back to 0
    });
  });

  group('Magic Over — target chase uses doubled runs', () {
    test('target chased mid-magic-over with doubled runs', () {
      final notifier = makeNotifier(
        magicOverNumber: 4,
        inningsNumber: 2,
        target: 10,
      );
      advanceToOver(notifier, 4);

      // Verify we're at over 4 and not complete yet
      expect(notifier.state.currentOverNumber, 4);
      expect(notifier.state.isInningsComplete, false);
      expect(notifier.state.target, 10);

      // Need 10 to win. Score a six in magic over → 12 runs
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(notifier.state.totalRuns, 12);
      expect(notifier.state.isInningsComplete, true);
      expect(notifier.state.completionReason, InningsCompletionReason.targetChased);
    });
  });

  group('Magic Over — magicOverNumber in state', () {
    test('state preserves magicOverNumber', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      expect(notifier.state.magicOverNumber, 4);
    });

    test('state preserves null magicOverNumber', () {
      final notifier = makeNotifier(magicOverNumber: null);
      expect(notifier.state.magicOverNumber, isNull);
    });

    test('magicOverNumber preserved through copyWith', () {
      final notifier = makeNotifier(magicOverNumber: 4);
      final copied = notifier.state.copyWith(totalRuns: 100);
      expect(copied.magicOverNumber, 4);
    });
  });

  group('Magic Over — second innings carries magicOverNumber', () {
    test('startSecondInnings preserves magicOverNumber', () {
      final notifier = makeNotifier(
        magicOverNumber: 4,
        playersPerSide: 6,
        totalOvers: 6,
      );

      // Complete 1st innings by bowling 6 overs of dots
      for (var over = 0; over < 6; over++) {
        bowlDotOver(notifier);
        if (over < 5) {
          // Select next bowler
          selectBowler(
            notifier,
            'bowl-${(over % 6) + 2 > 6 ? ((over % 6) + 2) - 6 : (over % 6) + 2}',
            'Bowler ${(over % 6) + 2 > 6 ? ((over % 6) + 2) - 6 : (over % 6) + 2}',
          );
        }
      }

      expect(notifier.state.isInningsComplete, true);

      // Start 2nd innings
      notifier.startSecondInnings(
        strikerId: 'bowl-1',
        strikerName: 'Bowler 1',
        nonStrikerId: 'bowl-2',
        nonStrikerName: 'Bowler 2',
        bowlerId: 'bat-1',
        bowlerName: 'Batter 1',
      );

      expect(notifier.state.magicOverNumber, 4);
      expect(notifier.state.inningsNumber, 2);
    });
  });
}
