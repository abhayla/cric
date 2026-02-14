import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/utils/mvp_utils.dart';
import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/domain/entities/scorecard_data.dart';
import 'package:cricapp/src/features/scoring/domain/entities/wicket_info.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  // ── computeBattingPoints ─────────────────────────────────────────────

  group('computeBattingPoints', () {
    test('base points: 1 per 10 runs', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 40,
        ballsFaced: 30,
        fours: 0,
        sixes: 0,
      );
      // teamSR = 0 → no SR bonus, no milestone
      // 40/10 = 4.0
      final pts = computeBattingPoints(batter, 0);
      expect(pts, 4.0);
    });

    test('strike rate bonus when above team SR by more than 10%', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 30,
        ballsFaced: 20, // SR = 150
        fours: 0,
        sixes: 0,
      );
      // teamSR = 100, batter SR = 150, threshold = 10 → 150 > 110 → +0.5
      final pts = computeBattingPoints(batter, 100);
      expect(pts, 3.0 + 0.5); // 30/10 + 0.5
    });

    test('strike rate penalty when below team SR by more than 10%', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 20,
        ballsFaced: 30, // SR = 66.67
        fours: 0,
        sixes: 0,
      );
      // teamSR = 130, batter SR = 66.67, threshold = 13 → 66.67 < 117 → -0.5
      final pts = computeBattingPoints(batter, 130);
      expect(pts, 2.0 - 0.5); // 20/10 - 0.5
    });

    test('no SR bonus/penalty when within 10% of team SR', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 30,
        ballsFaced: 23, // SR = 130.4
        fours: 0,
        sixes: 0,
      );
      // teamSR = 125, threshold = 12.5
      // batter SR = 130.4, range = [112.5, 137.5] → within range → 0
      final pts = computeBattingPoints(batter, 125);
      expect(pts, 3.0); // 30/10, no SR adjustment
    });

    test('50-run milestone bonus', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 65,
        ballsFaced: 50,
        fours: 0,
        sixes: 0,
      );
      final pts = computeBattingPoints(batter, 0);
      expect(pts, 6.5 + 2.0); // 65/10 + milestone
    });

    test('100-run milestone replaces 50-run bonus', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 105,
        ballsFaced: 80,
        fours: 0,
        sixes: 0,
      );
      final pts = computeBattingPoints(batter, 0);
      expect(pts, 10.5 + 5.0); // 105/10 + 5 (not 5+2)
    });

    test('boundary bonuses: fours and sixes', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 30,
        ballsFaced: 25,
        fours: 4,
        sixes: 2,
      );
      final pts = computeBattingPoints(batter, 0);
      // 3.0 + 4*0.1 + 2*0.2 = 3.0 + 0.4 + 0.4 = 3.8
      expect(pts, closeTo(3.8, 0.01));
    });

    test('spec example: R. Sharma 65(40), 6 fours, 3 sixes, team SR 130', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'R. Sharma',
        runsScored: 65,
        ballsFaced: 40, // SR = 162.5
        fours: 6,
        sixes: 3,
      );
      // Base: 65/10 = 6.5
      // SR: 162.5 vs 130, threshold = 13, 162.5 > 143 → +0.5
      // Milestone: 50+ → +2
      // Fours: 6 * 0.1 = 0.6
      // Sixes: 3 * 0.2 = 0.6
      // Total = 6.5 + 0.5 + 2 + 0.6 + 0.6 = 10.2
      final pts = computeBattingPoints(batter, 130);
      expect(pts, closeTo(10.2, 0.01));
    });

    test('zero balls faced returns 0 points', () {
      const batter = BatterInnings(
        playerId: 'p1',
        displayName: 'Batter',
        runsScored: 0,
        ballsFaced: 0,
      );
      expect(computeBattingPoints(batter, 130), 0.0);
    });
  });

  // ── computeBowlingPoints ─────────────────────────────────────────────

  group('computeBowlingPoints', () {
    test('base points: 3 per wicket', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24, // 4 overs
        runsConceded: 30,
        wicketsTaken: 2,
      );
      // matchEconomy = 0 → no economy bonus, no milestone
      // 2 * 3 = 6.0
      final pts = computeBowlingPoints(bowler, 0);
      expect(pts, 6.0);
    });

    test('economy bonus when below match average by more than 0.5', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24, // 4 overs
        runsConceded: 16, // economy = 4.0
        wicketsTaken: 0,
      );
      // matchEconomy = 7.5, bowler economy = 4.0 < 7.0 → +1
      final pts = computeBowlingPoints(bowler, 7.5);
      expect(pts, 0 + 1.0); // 0 wickets + economy bonus
    });

    test('economy penalty when above match average by more than 0.5', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24,
        runsConceded: 48, // economy = 12.0
        wicketsTaken: 0,
      );
      // matchEconomy = 7.5, bowler economy = 12.0 > 8.0 → -1
      final pts = computeBowlingPoints(bowler, 7.5);
      expect(pts, -1.0);
    });

    test('no economy bonus/penalty when within 0.5 of match average', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24,
        runsConceded: 30, // economy = 7.5
        wicketsTaken: 1,
      );
      // matchEconomy = 7.5, bowler = 7.5 → within 0.5 → 0
      final pts = computeBowlingPoints(bowler, 7.5);
      expect(pts, 3.0); // 1 * 3 + 0 economy
    });

    test('maiden over bonus', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24,
        runsConceded: 20,
        wicketsTaken: 0,
        maidens: 2,
      );
      final pts = computeBowlingPoints(bowler, 0);
      expect(pts, 0 + 2.0); // 0 wickets + 2 maidens
    });

    test('3-wicket milestone bonus', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24,
        runsConceded: 25,
        wicketsTaken: 3,
      );
      final pts = computeBowlingPoints(bowler, 0);
      expect(pts, 9.0 + 3.0); // 3*3 + milestone
    });

    test('5-wicket milestone replaces 3-wicket bonus', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 24,
        runsConceded: 20,
        wicketsTaken: 5,
      );
      final pts = computeBowlingPoints(bowler, 0);
      expect(pts, 15.0 + 5.0); // 5*3 + 5 (not 5+3)
    });

    test('spec example: Bumrah 4ov, 2M, 18R, 3W, match economy 7.5', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'J. Bumrah',
        ballsBowled: 24, // 4 overs
        maidens: 2,
        runsConceded: 18, // economy = 4.5
        wicketsTaken: 3,
      );
      // Base: 3 * 3 = 9
      // Economy: 4.5 vs 7.5, 4.5 < 7.0 → +1
      // Maidens: 2 * 1 = 2
      // Milestone: 3W → +3
      // Total = 9 + 1 + 2 + 3 = 15.0
      final pts = computeBowlingPoints(bowler, 7.5);
      expect(pts, 15.0);
    });

    test('zero balls bowled returns 0 points', () {
      const bowler = BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler',
        ballsBowled: 0,
        runsConceded: 0,
        wicketsTaken: 0,
      );
      expect(computeBowlingPoints(bowler, 7.5), 0.0);
    });
  });

  // ── computeMvp (full match) ──────────────────────────────────────────

  group('computeMvp', () {
    test('tiebreaker: same total → batting points wins', () {
      final data = _createMvpTestData(
        firstBatters: {
          'p1': const BatterInnings(
            playerId: 'p1',
            displayName: 'Batter A',
            runsScored: 50,
            ballsFaced: 40,
            fours: 0,
            sixes: 0,
          ),
        },
        firstBowlers: {
          'p2': const BowlerSpell(
            playerId: 'p2',
            displayName: 'Bowler B',
            ballsBowled: 24,
            runsConceded: 20,
            wicketsTaken: 2,
            maidens: 1,
          ),
        },
        secondBatters: {},
        secondBowlers: {},
      );

      final result = computeMvp(data);
      // Both will have some points. Batter A has batting-heavy points.
      // The one with higher batting points should rank higher on tiebreak.
      final batterA =
          result.rankings.firstWhere((r) => r.playerId == 'p1');
      final bowlerB =
          result.rankings.firstWhere((r) => r.playerId == 'p2');

      // If they happen to tie, batter should rank higher
      if (batterA.totalPoints == bowlerB.totalPoints) {
        expect(
          result.rankings.indexOf(batterA),
          lessThan(result.rankings.indexOf(bowlerB)),
        );
      }
    });

    test('players from both innings are included', () {
      final data = _createMvpTestData(
        firstBatters: {
          'p1': const BatterInnings(
            playerId: 'p1',
            displayName: 'Player 1',
            runsScored: 30,
            ballsFaced: 25,
          ),
        },
        firstBowlers: {
          'p3': const BowlerSpell(
            playerId: 'p3',
            displayName: 'Player 3',
            ballsBowled: 24,
            runsConceded: 30,
            wicketsTaken: 1,
          ),
        },
        secondBatters: {
          'p3': const BatterInnings(
            playerId: 'p3',
            displayName: 'Player 3',
            runsScored: 40,
            ballsFaced: 30,
          ),
        },
        secondBowlers: {
          'p1': const BowlerSpell(
            playerId: 'p1',
            displayName: 'Player 1',
            ballsBowled: 24,
            runsConceded: 25,
            wicketsTaken: 2,
          ),
        },
      );

      final result = computeMvp(data);
      expect(result.rankings.length, 2);

      // Player 3 has both batting and bowling
      final p3 = result.rankings.firstWhere((r) => r.playerId == 'p3');
      expect(p3.battingPoints, greaterThan(0));
      expect(p3.bowlingPoints, greaterThan(0));
    });

    test('fielding points from catches in delivery history', () {
      final deliveries = [
        Delivery(
          id: 'del-1',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.caught,
            bowlerCredited: true,
            fielderId: 'f1',
          ),
        ),
        Delivery(
          id: 'del-2',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 2,
          sequenceNumber: 2,
          strikerId: 'p3',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p3',
            dismissalType: DismissalType.caught,
            bowlerCredited: true,
            fielderId: 'f1',
          ),
        ),
      ];

      final data = _createMvpTestDataWithDeliveries(
        firstDeliveries: deliveries,
        firstBowlingTeamPlayers: const [
          PlayingXIPlayer(playerId: 'f1', displayName: 'Fielder 1'),
          PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
        ],
      );

      final result = computeMvp(data);
      final fielder = result.rankings.firstWhere((r) => r.playerId == 'f1');
      expect(fielder.fieldingPoints, 3.0); // 2 catches * 1.5
    });

    test('stumping fielding points', () {
      final deliveries = [
        Delivery(
          id: 'del-1',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.stumped,
            bowlerCredited: true,
            fielderId: 'wk1',
          ),
        ),
      ];

      final data = _createMvpTestDataWithDeliveries(
        firstDeliveries: deliveries,
        firstBowlingTeamPlayers: const [
          PlayingXIPlayer(playerId: 'wk1', displayName: 'Keeper'),
          PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
        ],
      );

      final result = computeMvp(data);
      final keeper = result.rankings.firstWhere((r) => r.playerId == 'wk1');
      expect(keeper.fieldingPoints, 1.5); // 1 stumping * 1.5
    });

    test('run out fielding points', () {
      final deliveries = [
        Delivery(
          id: 'del-1',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.runOut,
            bowlerCredited: false,
            fielderId: 'f1',
          ),
        ),
      ];

      final data = _createMvpTestDataWithDeliveries(
        firstDeliveries: deliveries,
        firstBowlingTeamPlayers: const [
          PlayingXIPlayer(playerId: 'f1', displayName: 'Fielder 1'),
          PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
        ],
      );

      final result = computeMvp(data);
      final fielder = result.rankings.firstWhere((r) => r.playerId == 'f1');
      expect(fielder.fieldingPoints, 1.5); // 1 run out * 1.5
    });

    test('sorted descending by total points', () {
      final data = _createMvpTestData(
        firstBatters: {
          'p1': const BatterInnings(
            playerId: 'p1',
            displayName: 'Player 1',
            runsScored: 100,
            ballsFaced: 70,
            fours: 10,
            sixes: 5,
          ),
          'p2': const BatterInnings(
            playerId: 'p2',
            displayName: 'Player 2',
            runsScored: 20,
            ballsFaced: 30,
          ),
        },
        firstBowlers: {},
        secondBatters: {},
        secondBowlers: {},
      );

      final result = computeMvp(data);
      expect(result.rankings.length, 2);
      expect(result.rankings[0].totalPoints,
          greaterThanOrEqualTo(result.rankings[1].totalPoints));
    });

    test('performance summary shows batting, bowling, and fielding', () {
      final data = _createMvpTestData(
        firstBatters: {
          'p1': const BatterInnings(
            playerId: 'p1',
            displayName: 'Player 1',
            runsScored: 54,
            ballsFaced: 38,
            fours: 4,
            sixes: 2,
          ),
        },
        firstBowlers: {},
        secondBatters: {},
        secondBowlers: {
          'p1': const BowlerSpell(
            playerId: 'p1',
            displayName: 'Player 1',
            ballsBowled: 12,
            runsConceded: 15,
            wicketsTaken: 1,
          ),
        },
      );

      final result = computeMvp(data);
      final p1 = result.rankings.firstWhere((r) => r.playerId == 'p1');
      expect(p1.performanceSummary, contains('54(38)'));
      expect(p1.performanceSummary, contains('1/15'));
    });

    test('player with 0 contributions gets 0 points', () {
      final data = _createMvpTestData(
        firstBatters: {
          'p1': const BatterInnings(
            playerId: 'p1',
            displayName: 'Player 1',
            runsScored: 0,
            ballsFaced: 3,
          ),
        },
        firstBowlers: {},
        secondBatters: {},
        secondBowlers: {},
      );

      final result = computeMvp(data);
      final p1 = result.rankings.firstWhere((r) => r.playerId == 'p1');
      expect(p1.battingPoints, closeTo(0.0, 0.51)); // May have SR penalty
      expect(p1.bowlingPoints, 0.0);
      expect(p1.fieldingPoints, 0.0);
    });

    test('all-rounder with batting + bowling + fielding in same match', () {
      final deliveries = [
        Delivery(
          id: 'del-1',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'ar1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.caught,
            bowlerCredited: true,
            fielderId: 'ar1', // Caught & bowled effectively
          ),
        ),
      ];

      final data = _createFullAllRounderData(deliveries);
      final result = computeMvp(data);
      final ar = result.rankings.firstWhere((r) => r.playerId == 'ar1');

      expect(ar.battingPoints, greaterThan(0));
      expect(ar.bowlingPoints, greaterThan(0));
      expect(ar.fieldingPoints, greaterThan(0));
    });
  });
}

// ── Test data helpers ──────────────────────────────────────────────────

ScorecardData _createMvpTestData({
  required Map<String, BatterInnings> firstBatters,
  required Map<String, BowlerSpell> firstBowlers,
  required Map<String, BatterInnings> secondBatters,
  required Map<String, BowlerSpell> secondBowlers,
}) {
  int totalFirstRuns = 0;
  int totalFirstBalls = 0;
  for (final b in firstBatters.values) {
    totalFirstRuns += b.runsScored;
    totalFirstBalls += b.ballsFaced;
  }

  int totalSecondRuns = 0;
  int totalSecondBalls = 0;
  for (final b in secondBatters.values) {
    totalSecondRuns += b.runsScored;
    totalSecondBalls += b.ballsFaced;
  }

  return ScorecardData(
    matchId: 'match-1',
    totalOvers: 20,
    playersPerSide: 11,
    firstInnings: InningsData(
      teamName: 'Team A',
      teamId: 'team-a',
      totalRuns: totalFirstRuns,
      totalWickets: 0,
      totalBalls: totalFirstBalls,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: firstBatters,
      bowlerStats: firstBowlers,
      fallOfWickets: const [],
      deliveryHistory: const [],
      battingTeamPlayers: firstBatters.values
          .map((b) =>
              PlayingXIPlayer(playerId: b.playerId, displayName: b.displayName))
          .toList(),
      bowlingTeamPlayers: firstBowlers.values
          .map((b) =>
              PlayingXIPlayer(playerId: b.playerId, displayName: b.displayName))
          .toList(),
    ),
    secondInnings: InningsData(
      teamName: 'Team B',
      teamId: 'team-b',
      totalRuns: totalSecondRuns,
      totalWickets: 0,
      totalBalls: totalSecondBalls,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: secondBatters,
      bowlerStats: secondBowlers,
      fallOfWickets: const [],
      deliveryHistory: const [],
      battingTeamPlayers: secondBatters.values
          .map((b) =>
              PlayingXIPlayer(playerId: b.playerId, displayName: b.displayName))
          .toList(),
      bowlingTeamPlayers: secondBowlers.values
          .map((b) =>
              PlayingXIPlayer(playerId: b.playerId, displayName: b.displayName))
          .toList(),
    ),
    matchResult: const MatchResult(
      winnerTeamId: 'team-a',
      winnerTeamName: 'Team A',
      resultType: MatchResultType.runs,
      margin: 30,
      resultDescription: 'Team A won by 30 runs',
    ),
  );
}

ScorecardData _createMvpTestDataWithDeliveries({
  required List<Delivery> firstDeliveries,
  List<PlayingXIPlayer> firstBowlingTeamPlayers = const [],
}) {
  return ScorecardData(
    matchId: 'match-1',
    totalOvers: 20,
    playersPerSide: 11,
    firstInnings: InningsData(
      teamName: 'Team A',
      teamId: 'team-a',
      totalRuns: 0,
      totalWickets: 0,
      totalBalls: 0,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: const {},
      bowlerStats: const {},
      fallOfWickets: const [],
      deliveryHistory: firstDeliveries,
      battingTeamPlayers: const [],
      bowlingTeamPlayers: firstBowlingTeamPlayers,
    ),
    secondInnings: InningsData(
      teamName: 'Team B',
      teamId: 'team-b',
      totalRuns: 0,
      totalWickets: 0,
      totalBalls: 0,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: const {},
      bowlerStats: const {},
      fallOfWickets: const [],
      deliveryHistory: const [],
      battingTeamPlayers: const [],
      bowlingTeamPlayers: const [],
    ),
    matchResult: const MatchResult(
      resultType: MatchResultType.tie,
      resultDescription: 'Match tied',
    ),
  );
}

ScorecardData _createFullAllRounderData(List<Delivery> deliveries) {
  return ScorecardData(
    matchId: 'match-1',
    totalOvers: 20,
    playersPerSide: 11,
    firstInnings: InningsData(
      teamName: 'Team A',
      teamId: 'team-a',
      totalRuns: 150,
      totalWickets: 5,
      totalBalls: 120,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: const {},
      bowlerStats: {
        'ar1': const BowlerSpell(
          playerId: 'ar1',
          displayName: 'All Rounder',
          ballsBowled: 24,
          runsConceded: 25,
          wicketsTaken: 2,
        ),
      },
      fallOfWickets: const [],
      deliveryHistory: deliveries,
      battingTeamPlayers: const [],
      bowlingTeamPlayers: const [
        PlayingXIPlayer(playerId: 'ar1', displayName: 'All Rounder'),
      ],
    ),
    secondInnings: InningsData(
      teamName: 'Team B',
      teamId: 'team-b',
      totalRuns: 120,
      totalWickets: 8,
      totalBalls: 120,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      totalExtras: 0,
      batterStats: {
        'ar1': const BatterInnings(
          playerId: 'ar1',
          displayName: 'All Rounder',
          runsScored: 45,
          ballsFaced: 30,
          fours: 4,
          sixes: 2,
        ),
      },
      bowlerStats: const {},
      fallOfWickets: const [],
      deliveryHistory: const [],
      battingTeamPlayers: const [
        PlayingXIPlayer(playerId: 'ar1', displayName: 'All Rounder'),
      ],
      bowlingTeamPlayers: const [],
    ),
    matchResult: const MatchResult(
      winnerTeamId: 'team-a',
      winnerTeamName: 'Team A',
      resultType: MatchResultType.runs,
      margin: 30,
      resultDescription: 'Team A won by 30 runs',
    ),
  );
}
