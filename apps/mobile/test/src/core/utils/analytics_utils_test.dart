import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/utils/analytics_utils.dart';
import 'package:cricscores/src/features/analytics/domain/entities/chart_data.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/domain/entities/scorecard_data.dart';
import 'package:cricscores/src/features/scoring/domain/entities/wicket_info.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  // ── computeManhattan ─────────────────────────────────────────────────

  group('computeManhattan', () {
    test('empty deliveries returns empty list', () {
      expect(computeManhattan([]), isEmpty);
    });

    test('single over with 6 legal balls', () {
      final deliveries = List.generate(
        6,
        (i) => Delivery(
          id: 'del-$i',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: i + 1,
          sequenceNumber: i + 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          runsFromBat: 2,
        ),
      );

      final result = computeManhattan(deliveries);
      expect(result.length, 1);
      expect(result[0].overNumber, 1); // 1-based
      expect(result[0].runs, 12); // 6 * 2
      expect(result[0].hasWicket, false);
    });

    test('wicket over is flagged', () {
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
          runsFromBat: 4,
          isBoundaryFour: true,
        ),
        Delivery(
          id: 'del-2',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 2,
          sequenceNumber: 2,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          wicketInfo: const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.bowled,
            bowlerCredited: true,
          ),
        ),
      ];

      final result = computeManhattan(deliveries);
      expect(result[0].hasWicket, true);
      expect(result[0].runs, 4); // 4 + 0
    });

    test('extras counted in over runs', () {
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
          isWide: true,
          wideRuns: 1,
        ),
        Delivery(
          id: 'del-2',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 2,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          runsFromBat: 3,
        ),
      ];

      final result = computeManhattan(deliveries);
      expect(result[0].runs, 4); // 1 (wide) + 3 (bat)
    });

    test('multiple overs sorted correctly', () {
      final deliveries = [
        _delivery(overNumber: 2, runs: 6),
        _delivery(overNumber: 0, runs: 3),
        _delivery(overNumber: 1, runs: 8),
      ];

      final result = computeManhattan(deliveries);
      expect(result.length, 3);
      expect(result[0].overNumber, 1);
      expect(result[0].runs, 3);
      expect(result[1].overNumber, 2);
      expect(result[1].runs, 8);
      expect(result[2].overNumber, 3);
      expect(result[2].runs, 6);
    });

    test('partial last over included', () {
      final deliveries = [
        _delivery(overNumber: 0, runs: 6),
        _delivery(overNumber: 0, runs: 4),
        _delivery(overNumber: 0, runs: 0),
        _delivery(overNumber: 0, runs: 1),
        _delivery(overNumber: 0, runs: 2),
        _delivery(overNumber: 0, runs: 0),
        // Over 1 only has 3 balls (partial)
        _delivery(overNumber: 1, runs: 4),
        _delivery(overNumber: 1, runs: 2),
        _delivery(overNumber: 1, runs: 1),
      ];

      final result = computeManhattan(deliveries);
      expect(result.length, 2);
      expect(result[0].runs, 13); // 6+4+0+1+2+0
      expect(result[1].runs, 7); // 4+2+1
    });
  });

  // ── computeWorm ──────────────────────────────────────────────────────

  group('computeWorm', () {
    test('empty manhattan returns only start point', () {
      final result = computeWorm([]);
      expect(result.length, 1);
      expect(result[0].overNumber, 0);
      expect(result[0].cumulativeRuns, 0);
    });

    test('cumulative runs computed correctly', () {
      const manhattan = [
        OverStats(overNumber: 1, runs: 8, hasWicket: false),
        OverStats(overNumber: 2, runs: 5, hasWicket: false),
        OverStats(overNumber: 3, runs: 12, hasWicket: true),
      ];

      final result = computeWorm(manhattan);
      expect(result.length, 4); // start + 3 overs
      expect(result[0].overNumber, 0);
      expect(result[0].cumulativeRuns, 0);
      expect(result[1].overNumber, 1);
      expect(result[1].cumulativeRuns, 8);
      expect(result[2].overNumber, 2);
      expect(result[2].cumulativeRuns, 13);
      expect(result[3].overNumber, 3);
      expect(result[3].cumulativeRuns, 25);
    });

    test('final cumulative matches total score', () {
      const manhattan = [
        OverStats(overNumber: 1, runs: 10, hasWicket: false),
        OverStats(overNumber: 2, runs: 7, hasWicket: false),
        OverStats(overNumber: 3, runs: 3, hasWicket: false),
      ];

      final result = computeWorm(manhattan);
      expect(result.last.cumulativeRuns, 20);
    });

    test('zero-run overs keep cumulative flat', () {
      const manhattan = [
        OverStats(overNumber: 1, runs: 5, hasWicket: false),
        OverStats(overNumber: 2, runs: 0, hasWicket: false),
        OverStats(overNumber: 3, runs: 3, hasWicket: false),
      ];

      final result = computeWorm(manhattan);
      expect(result[1].cumulativeRuns, 5);
      expect(result[2].cumulativeRuns, 5); // Flat
      expect(result[3].cumulativeRuns, 8);
    });
  });

  // ── computeRunRate ───────────────────────────────────────────────────

  group('computeRunRate', () {
    test('empty manhattan returns empty list', () {
      expect(computeRunRate([]), isEmpty);
    });

    test('per-over run rate values', () {
      const manhattan = [
        OverStats(overNumber: 1, runs: 8, hasWicket: false),
        OverStats(overNumber: 2, runs: 0, hasWicket: false),
        OverStats(overNumber: 3, runs: 15, hasWicket: false),
      ];

      final result = computeRunRate(manhattan);
      expect(result.length, 3);
      expect(result[0].overNumber, 1);
      expect(result[0].runRate, 8.0);
      expect(result[1].overNumber, 2);
      expect(result[1].runRate, 0.0);
      expect(result[2].overNumber, 3);
      expect(result[2].runRate, 15.0);
    });
  });

  // ── computeInningsChartData ──────────────────────────────────────────

  group('computeInningsChartData', () {
    test('computes all three chart types from innings', () {
      final innings = _createInningsData(
        teamName: 'Team A',
        deliveries: [
          _delivery(overNumber: 0, runs: 8),
          _delivery(overNumber: 0, runs: 4),
          _delivery(overNumber: 1, runs: 6),
        ],
        totalRuns: 18,
        totalWickets: 0,
        totalBalls: 12,
      );

      final result = computeInningsChartData(innings);
      expect(result.teamName, 'Team A');
      expect(result.scoreDisplay, '18/0');
      expect(result.manhattan.length, 2);
      expect(result.worm.length, 3); // start + 2 overs
      expect(result.runRate.length, 2);
    });

    test('empty innings produces empty charts', () {
      final innings = _createInningsData(
        teamName: 'Team B',
        deliveries: [],
        totalRuns: 0,
        totalWickets: 0,
        totalBalls: 0,
      );

      final result = computeInningsChartData(innings);
      expect(result.manhattan, isEmpty);
      expect(result.worm.length, 1); // Only start point
      expect(result.runRate, isEmpty);
    });
  });

  // ── computeMatchChartData ────────────────────────────────────────────

  group('computeMatchChartData', () {
    test('computes chart data for both innings', () {
      final data = _createScorecardData();
      final result = computeMatchChartData(data);

      expect(result.firstInnings.teamName, 'Team A');
      expect(result.secondInnings.teamName, 'Team B');
      expect(result.totalOvers, 20);
      expect(result.firstInnings.manhattan.isNotEmpty, true);
      expect(result.secondInnings.manhattan.isNotEmpty, true);
    });

    test('innings chart data reflects actual delivery history', () {
      final data = _createScorecardData();
      final result = computeMatchChartData(data);

      // First innings has 2 overs of deliveries
      expect(result.firstInnings.manhattan.length, 2);
      // Second innings has 1 over of deliveries
      expect(result.secondInnings.manhattan.length, 1);
    });
  });

  // ── Round-trip verification ──────────────────────────────────────────

  group('round-trip verification', () {
    test('known deliveries produce exact chart values', () {
      // Over 0: 4, 1, 0, 2, 6, 1 = 14 runs, no wicket
      // Over 1: 0, W, 1, 0, 0, 3 = 4 runs, wicket
      // Over 2: 2, 4, 1 = 7 runs (partial), no wicket
      final deliveries = [
        _delivery(overNumber: 0, runs: 4),
        _delivery(overNumber: 0, runs: 1),
        _delivery(overNumber: 0, runs: 0),
        _delivery(overNumber: 0, runs: 2),
        _delivery(overNumber: 0, runs: 6),
        _delivery(overNumber: 0, runs: 1),
        _delivery(overNumber: 1, runs: 0),
        _delivery(overNumber: 1, runs: 0, isWicket: true),
        _delivery(overNumber: 1, runs: 1),
        _delivery(overNumber: 1, runs: 0),
        _delivery(overNumber: 1, runs: 0),
        _delivery(overNumber: 1, runs: 3),
        _delivery(overNumber: 2, runs: 2),
        _delivery(overNumber: 2, runs: 4),
        _delivery(overNumber: 2, runs: 1),
      ];

      final manhattan = computeManhattan(deliveries);
      expect(manhattan.length, 3);
      expect(manhattan[0].runs, 14);
      expect(manhattan[0].hasWicket, false);
      expect(manhattan[1].runs, 4);
      expect(manhattan[1].hasWicket, true);
      expect(manhattan[2].runs, 7);
      expect(manhattan[2].hasWicket, false);

      final worm = computeWorm(manhattan);
      expect(worm.last.cumulativeRuns, 25); // 14 + 4 + 7

      final runRate = computeRunRate(manhattan);
      expect(runRate[0].runRate, 14.0);
      expect(runRate[1].runRate, 4.0);
      expect(runRate[2].runRate, 7.0);
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────

  group('edge cases', () {
    test('1-over innings', () {
      final deliveries = [
        _delivery(overNumber: 0, runs: 10),
      ];

      final manhattan = computeManhattan(deliveries);
      expect(manhattan.length, 1);
      expect(manhattan[0].overNumber, 1);
      expect(manhattan[0].runs, 10);

      final worm = computeWorm(manhattan);
      expect(worm.length, 2);
      expect(worm[0].cumulativeRuns, 0);
      expect(worm[1].cumulativeRuns, 10);
    });

    test('all-out early produces fewer overs than totalOvers', () {
      // Only 3 overs bowled in a 20-over match (all out early)
      final deliveries = [
        _delivery(overNumber: 0, runs: 5),
        _delivery(overNumber: 1, runs: 3, isWicket: true),
        _delivery(overNumber: 2, runs: 0, isWicket: true),
      ];

      final manhattan = computeManhattan(deliveries);
      expect(manhattan.length, 3);
      // No padding to 20 overs — chart shows actual overs bowled
    });

    test('no-ball and wide extras in same over accumulate', () {
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
          isWide: true,
          wideRuns: 2, // Wide + 1 run
        ),
        Delivery(
          id: 'del-2',
          inningsId: 'inn-1',
          overNumber: 0,
          ballNumber: 1,
          sequenceNumber: 2,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isNoBall: true,
          noBallRuns: 1,
          runsFromBat: 4,
        ),
      ];

      final manhattan = computeManhattan(deliveries);
      expect(manhattan[0].runs, 7); // 2 (wide) + 1 (nb) + 4 (bat)
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────

int _seq = 0;

Delivery _delivery({
  required int overNumber,
  required int runs,
  bool isWicket = false,
}) {
  _seq++;
  return Delivery(
    id: 'del-$_seq',
    inningsId: 'inn-1',
    overNumber: overNumber,
    ballNumber: 1,
    sequenceNumber: _seq,
    strikerId: 'p1',
    nonStrikerId: 'p2',
    bowlerId: 'b1',
    runsFromBat: runs,
    isWicket: isWicket,
    wicketInfo: isWicket
        ? const WicketInfo(
            dismissedPlayerId: 'p1',
            dismissalType: DismissalType.bowled,
            bowlerCredited: true,
          )
        : null,
  );
}

InningsData _createInningsData({
  required String teamName,
  required List<Delivery> deliveries,
  required int totalRuns,
  required int totalWickets,
  required int totalBalls,
}) {
  return InningsData(
    teamName: teamName,
    teamId: 'team-${teamName.toLowerCase().replaceAll(' ', '-')}',
    totalRuns: totalRuns,
    totalWickets: totalWickets,
    totalBalls: totalBalls,
    totalWides: 0,
    totalNoBalls: 0,
    totalByes: 0,
    totalLegByes: 0,
    totalExtras: 0,
    batterStats: const {},
    bowlerStats: const {},
    fallOfWickets: const [],
    deliveryHistory: deliveries,
    battingTeamPlayers: const [],
    bowlingTeamPlayers: const [],
  );
}

ScorecardData _createScorecardData() {
  final firstDeliveries = [
    Delivery(
      id: 'fd-1',
      inningsId: 'inn-1',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsFromBat: 4,
      isBoundaryFour: true,
    ),
    Delivery(
      id: 'fd-2',
      inningsId: 'inn-1',
      overNumber: 0,
      ballNumber: 2,
      sequenceNumber: 2,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsFromBat: 2,
    ),
    Delivery(
      id: 'fd-3',
      inningsId: 'inn-1',
      overNumber: 1,
      ballNumber: 1,
      sequenceNumber: 3,
      strikerId: 'p2',
      nonStrikerId: 'p1',
      bowlerId: 'b2',
      runsFromBat: 6,
      isBoundarySix: true,
    ),
  ];

  final secondDeliveries = [
    Delivery(
      id: 'sd-1',
      inningsId: 'inn-2',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p3',
      nonStrikerId: 'p4',
      bowlerId: 'b3',
      runsFromBat: 3,
    ),
  ];

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
      bowlerStats: const {},
      fallOfWickets: const [],
      deliveryHistory: firstDeliveries,
      battingTeamPlayers: const [
        PlayingXIPlayer(playerId: 'p1', displayName: 'Player 1'),
        PlayingXIPlayer(playerId: 'p2', displayName: 'Player 2'),
      ],
      bowlingTeamPlayers: const [],
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
      batterStats: const {},
      bowlerStats: const {},
      fallOfWickets: const [],
      deliveryHistory: secondDeliveries,
      battingTeamPlayers: const [],
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
