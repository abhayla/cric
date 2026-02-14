import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/analytics/domain/entities/mvp_data.dart';

void main() {
  group('MvpPlayerScore', () {
    test('stores all fields correctly', () {
      const score = MvpPlayerScore(
        playerId: 'p1',
        displayName: 'V. Kohli',
        teamName: 'Team A',
        teamId: 'team-a',
        battingPoints: 10.2,
        bowlingPoints: 0.0,
        fieldingPoints: 3.0,
        totalPoints: 13.2,
        performanceSummary: '65(40), 2 ct',
      );

      expect(score.playerId, 'p1');
      expect(score.displayName, 'V. Kohli');
      expect(score.teamName, 'Team A');
      expect(score.teamId, 'team-a');
      expect(score.battingPoints, 10.2);
      expect(score.bowlingPoints, 0.0);
      expect(score.fieldingPoints, 3.0);
      expect(score.totalPoints, 13.2);
      expect(score.performanceSummary, '65(40), 2 ct');
    });

    test('zero points player', () {
      const score = MvpPlayerScore(
        playerId: 'p2',
        displayName: 'Some Player',
        teamName: 'Team B',
        teamId: 'team-b',
        battingPoints: 0.0,
        bowlingPoints: 0.0,
        fieldingPoints: 0.0,
        totalPoints: 0.0,
        performanceSummary: '0(3)',
      );

      expect(score.totalPoints, 0.0);
    });
  });

  group('MatchMvpData', () {
    test('stores sorted rankings', () {
      const mvp = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Player 1',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 10.0,
            bowlingPoints: 5.0,
            fieldingPoints: 1.5,
            totalPoints: 16.5,
            performanceSummary: '80(50), 1/20',
          ),
          MvpPlayerScore(
            playerId: 'p2',
            displayName: 'Player 2',
            teamName: 'Team B',
            teamId: 'team-b',
            battingPoints: 5.0,
            bowlingPoints: 8.0,
            fieldingPoints: 0.0,
            totalPoints: 13.0,
            performanceSummary: '30(25), 3/22',
          ),
        ],
      );

      expect(mvp.rankings.length, 2);
      expect(mvp.rankings.first.totalPoints, greaterThan(mvp.rankings.last.totalPoints));
    });

    test('empty rankings for no players', () {
      const mvp = MatchMvpData(rankings: []);
      expect(mvp.rankings, isEmpty);
    });

    test('single player match', () {
      const mvp = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Solo Player',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 5.0,
            bowlingPoints: 0.0,
            fieldingPoints: 0.0,
            totalPoints: 5.0,
            performanceSummary: '50(40)',
          ),
        ],
      );
      expect(mvp.rankings.length, 1);
    });
  });
}
