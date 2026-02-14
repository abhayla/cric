import 'package:cricapp/src/features/player_profile/domain/entities/match_performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamScore', () {
    test('scoreDisplay formats correctly', () {
      const score = TeamScore(
        teamId: '1',
        teamName: 'Mumbai',
        runs: 150,
        wickets: 5,
        overs: '20.0',
      );
      expect(score.scoreDisplay, '150/5 (20.0)');
    });
  });

  group('PersonalBatting', () {
    test('scoreDisplay shows not-out marker', () {
      const batting = PersonalBatting(
        runsScored: 75,
        ballsFaced: 45,
        fours: 8,
        sixes: 2,
        isNotOut: true,
      );
      expect(batting.scoreDisplay, '75* (45)');
    });

    test('scoreDisplay shows no marker when out', () {
      const batting = PersonalBatting(
        runsScored: 30,
        ballsFaced: 20,
        fours: 3,
        sixes: 1,
        isNotOut: false,
      );
      expect(batting.scoreDisplay, '30 (20)');
    });
  });

  group('PersonalBowling', () {
    test('figuresDisplay formats correctly', () {
      const bowling = PersonalBowling(
        oversBowled: '4.0',
        runsConceded: 25,
        wicketsTaken: 2,
        maidens: 1,
      );
      expect(bowling.figuresDisplay, '2/25 (4.0)');
    });
  });

  group('PersonalFielding', () {
    test('hasContributions returns true when catches > 0', () {
      const fielding = PersonalFielding(
        catches: 1,
        runOuts: 0,
        stumpings: 0,
      );
      expect(fielding.hasContributions, isTrue);
    });

    test('hasContributions returns false when all zero', () {
      const fielding = PersonalFielding(
        catches: 0,
        runOuts: 0,
        stumpings: 0,
      );
      expect(fielding.hasContributions, isFalse);
    });
  });

  group('MatchTeamInfo', () {
    test('initial returns first letter', () {
      const team = MatchTeamInfo(id: '1', name: 'Chennai Super Kings');
      expect(team.initial, 'C');
    });

    test('initial returns ? for empty name', () {
      const team = MatchTeamInfo(id: '1', name: '');
      expect(team.initial, '?');
    });
  });

  group('MatchPerformance', () {
    const homeTeam = MatchTeamInfo(id: 'home', name: 'Home Team');
    const awayTeam = MatchTeamInfo(id: 'away', name: 'Away Team');

    test('isWon returns true for won result', () {
      const match = MatchPerformance(
        matchId: '1',
        format: 'T20',
        matchDate: '2026-06-15',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        teamScores: [],
        playerResult: 'won',
        playerTeamId: 'home',
      );
      expect(match.isWon, isTrue);
      expect(match.isLost, isFalse);
    });

    test('isLost returns true for lost result', () {
      const match = MatchPerformance(
        matchId: '1',
        format: 'T20',
        matchDate: '2026-06-15',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        teamScores: [],
        playerResult: 'lost',
        playerTeamId: 'home',
      );
      expect(match.isLost, isTrue);
      expect(match.isWon, isFalse);
    });

    test('opponentTeam returns away when player is home', () {
      const match = MatchPerformance(
        matchId: '1',
        format: 'T20',
        matchDate: '2026-06-15',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        teamScores: [],
        playerResult: 'won',
        playerTeamId: 'home',
      );
      expect(match.opponentTeam.id, 'away');
    });

    test('opponentTeam returns home when player is away', () {
      const match = MatchPerformance(
        matchId: '1',
        format: 'T20',
        matchDate: '2026-06-15',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        teamScores: [],
        playerResult: 'lost',
        playerTeamId: 'away',
      );
      expect(match.opponentTeam.id, 'home');
    });
  });

  group('MatchHistoryResult', () {
    test('hasMore returns true when more pages exist', () {
      const result = MatchHistoryResult(
        matches: [],
        total: 30,
        page: 1,
        limit: 20,
      );
      expect(result.hasMore, isTrue);
    });

    test('hasMore returns false when on last page', () {
      const result = MatchHistoryResult(
        matches: [],
        total: 15,
        page: 1,
        limit: 20,
      );
      expect(result.hasMore, isFalse);
    });

    test('hasMore returns false when exactly at boundary', () {
      const result = MatchHistoryResult(
        matches: [],
        total: 20,
        page: 1,
        limit: 20,
      );
      expect(result.hasMore, isFalse);
    });
  });
}
