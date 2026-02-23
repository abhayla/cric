import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  group('InningsData', () {
    InningsData createInningsData({
      String teamName = 'Team A',
      String teamId = 'team-a',
      int totalRuns = 150,
      int totalWickets = 5,
      int totalBalls = 120,
      int totalWides = 3,
      int totalNoBalls = 2,
      int totalByes = 1,
      int totalLegByes = 2,
      int totalExtras = 8,
      Map<String, BatterInnings>? batterStats,
      Map<String, BowlerSpell>? bowlerStats,
      List<FallOfWicket>? fallOfWickets,
      List<Delivery>? deliveryHistory,
      List<PlayingXIPlayer>? battingTeamPlayers,
      List<PlayingXIPlayer>? bowlingTeamPlayers,
    }) {
      return InningsData(
        teamName: teamName,
        teamId: teamId,
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        totalBalls: totalBalls,
        totalWides: totalWides,
        totalNoBalls: totalNoBalls,
        totalByes: totalByes,
        totalLegByes: totalLegByes,
        totalExtras: totalExtras,
        batterStats: batterStats ?? const {},
        bowlerStats: bowlerStats ?? const {},
        fallOfWickets: fallOfWickets ?? const [],
        deliveryHistory: deliveryHistory ?? const [],
        battingTeamPlayers: battingTeamPlayers ?? const [],
        bowlingTeamPlayers: bowlingTeamPlayers ?? const [],
      );
    }

    test('scoreDisplay returns runs/wickets format', () {
      final data = createInningsData(totalRuns: 187, totalWickets: 6);
      expect(data.scoreDisplay, '187/6');
    });

    test('oversDisplay returns overs.balls format', () {
      final data = createInningsData(totalBalls: 75);
      expect(data.oversDisplay, '12.3');
    });

    test('oversDisplay shows exact overs when no remainder', () {
      final data = createInningsData(totalBalls: 120);
      expect(data.oversDisplay, '20.0');
    });

    test('runRate computes correctly', () {
      final data = createInningsData(totalRuns: 60, totalBalls: 60);
      expect(data.runRate, 6.0);
    });

    test('runRate returns 0 for empty innings', () {
      final data = createInningsData(totalRuns: 0, totalBalls: 0);
      expect(data.runRate, 0);
    });

    test('extrasDisplay shows breakdown when all types present', () {
      final data = createInningsData(
        totalExtras: 11,
        totalWides: 5,
        totalNoBalls: 3,
        totalByes: 2,
        totalLegByes: 1,
      );
      expect(data.extrasDisplay, '11 (wd 5, nb 3, b 2, lb 1)');
    });

    test('extrasDisplay shows "0" when no extras', () {
      final data = createInningsData(
        totalExtras: 0,
        totalWides: 0,
        totalNoBalls: 0,
        totalByes: 0,
        totalLegByes: 0,
      );
      expect(data.extrasDisplay, '0');
    });

    test('extrasDisplay omits zero-valued types', () {
      final data = createInningsData(
        totalExtras: 5,
        totalWides: 5,
        totalNoBalls: 0,
        totalByes: 0,
        totalLegByes: 0,
      );
      expect(data.extrasDisplay, '5 (wd 5)');
    });

    test('battingOrder returns batters in first-appearance order', () {
      final deliveries = [
        _delivery(strikerId: 'p1', nonStrikerId: 'p2', bowlerId: 'b1'),
        _delivery(strikerId: 'p2', nonStrikerId: 'p1', bowlerId: 'b1'),
        _delivery(strikerId: 'p3', nonStrikerId: 'p2', bowlerId: 'b1'),
      ];
      final stats = {
        'p1': _batter('p1', 'Player 1'),
        'p2': _batter('p2', 'Player 2'),
        'p3': _batter('p3', 'Player 3'),
      };
      final data = createInningsData(
        deliveryHistory: deliveries,
        batterStats: stats,
      );

      final order = data.battingOrder;
      expect(order.map((b) => b.playerId), ['p1', 'p2', 'p3']);
    });

    test('battingOrder includes batters not in delivery history', () {
      final deliveries = [
        _delivery(strikerId: 'p1', nonStrikerId: 'p2', bowlerId: 'b1'),
      ];
      final stats = {
        'p1': _batter('p1', 'Player 1'),
        'p2': _batter('p2', 'Player 2'),
        'p3': _batter('p3', 'Player 3'),
      };
      final data = createInningsData(
        deliveryHistory: deliveries,
        batterStats: stats,
      );

      final order = data.battingOrder;
      expect(order.length, 3);
      // p1, p2 from deliveries, p3 appended
      expect(order[0].playerId, 'p1');
      expect(order[1].playerId, 'p2');
      expect(order[2].playerId, 'p3');
    });

    test('yetToBatPlayers returns roster players not in batterStats', () {
      final roster = [
        const PlayingXIPlayer(playerId: 'p1', displayName: 'Player 1'),
        const PlayingXIPlayer(playerId: 'p2', displayName: 'Player 2'),
        const PlayingXIPlayer(playerId: 'p3', displayName: 'Player 3'),
      ];
      final stats = {
        'p1': _batter('p1', 'Player 1'),
      };
      final data = createInningsData(
        battingTeamPlayers: roster,
        batterStats: stats,
      );

      final yetToBat = data.yetToBatPlayers;
      expect(yetToBat.length, 2);
      expect(yetToBat.map((p) => p.playerId), ['p2', 'p3']);
    });

    test('yetToBatPlayers returns empty when all have batted', () {
      final roster = [
        const PlayingXIPlayer(playerId: 'p1', displayName: 'Player 1'),
      ];
      final stats = {
        'p1': _batter('p1', 'Player 1'),
      };
      final data = createInningsData(
        battingTeamPlayers: roster,
        batterStats: stats,
      );

      expect(data.yetToBatPlayers, isEmpty);
    });

    test('bowlingOrder returns bowlers in first-appearance order', () {
      final deliveries = [
        _delivery(strikerId: 'p1', nonStrikerId: 'p2', bowlerId: 'b1'),
        _delivery(strikerId: 'p1', nonStrikerId: 'p2', bowlerId: 'b2'),
        _delivery(strikerId: 'p1', nonStrikerId: 'p2', bowlerId: 'b1'),
      ];
      final stats = {
        'b1': const BowlerSpell(playerId: 'b1', displayName: 'Bowler 1'),
        'b2': const BowlerSpell(playerId: 'b2', displayName: 'Bowler 2'),
      };
      final data = createInningsData(
        deliveryHistory: deliveries,
        bowlerStats: stats,
      );

      final order = data.bowlingOrder;
      expect(order.map((b) => b.playerId), ['b1', 'b2']);
    });

    group('fromScoringState', () {
      test('captures all state fields correctly', () {
        final state = ScoringState(
          matchId: 'match-1',
          inningsId: 'innings-1',
          battingTeamId: 'team-a',
          bowlingTeamId: 'team-b',
          battingTeamName: 'Team A',
          bowlingTeamName: 'Team B',
          inningsNumber: 1,
          totalOvers: 20,
          playersPerSide: 11,
          totalRuns: 150,
          totalWickets: 7,
          totalBalls: 120,
          totalExtras: 10,
          totalWides: 4,
          totalNoBalls: 3,
          totalByes: 2,
          totalLegByes: 1,
          batterStats: {
            'p1': _batter('p1', 'Batter 1', runs: 50),
          },
          bowlerStats: {
            'b1': const BowlerSpell(playerId: 'b1', displayName: 'Bowler 1'),
          },
          battingTeamPlayers: const [
            PlayingXIPlayer(playerId: 'p1', displayName: 'Batter 1'),
          ],
          bowlingTeamPlayers: const [
            PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
          ],
        );

        final data = InningsData.fromScoringState(state);

        expect(data.teamName, 'Team A');
        expect(data.teamId, 'team-a');
        expect(data.totalRuns, 150);
        expect(data.totalWickets, 7);
        expect(data.totalBalls, 120);
        expect(data.totalWides, 4);
        expect(data.totalNoBalls, 3);
        expect(data.totalByes, 2);
        expect(data.totalLegByes, 1);
        expect(data.totalExtras, 10);
        expect(data.batterStats.length, 1);
        expect(data.bowlerStats.length, 1);
        expect(data.battingTeamPlayers.length, 1);
        expect(data.bowlingTeamPlayers.length, 1);
      });
    });
  });
}

Delivery _delivery({
  required String strikerId,
  required String nonStrikerId,
  required String bowlerId,
  int overNumber = 0,
  int ballNumber = 1,
}) {
  return Delivery(
    id: 'del-$strikerId-$ballNumber',
    inningsId: 'innings-1',
    overNumber: overNumber,
    ballNumber: ballNumber,
    sequenceNumber: 1,
    strikerId: strikerId,
    nonStrikerId: nonStrikerId,
    bowlerId: bowlerId,
  );
}

BatterInnings _batter(String id, String name, {int runs = 0}) {
  return BatterInnings(
    playerId: id,
    displayName: name,
    runsScored: runs,
  );
}
