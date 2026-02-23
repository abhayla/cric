import 'package:cricscores/src/features/player_profile/data/models/match_performance_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchPerformanceModel', () {
    final fullJson = {
      'matchId': 'match-1',
      'format': 'T20',
      'matchDate': '2026-06-15',
      'venue': 'Wankhede Stadium',
      'homeTeam': {'id': 'home-1', 'name': 'Mumbai Indians', 'logoUrl': 'mi.png'},
      'awayTeam': {'id': 'away-1', 'name': 'Chennai Super Kings'},
      'teamScores': [
        {'teamId': 'home-1', 'teamName': 'Mumbai Indians', 'runs': 180, 'wickets': 5, 'overs': '20.0'},
        {'teamId': 'away-1', 'teamName': 'Chennai Super Kings', 'runs': 170, 'wickets': 8, 'overs': '20.0'},
      ],
      'result': {
        'winnerTeamId': 'home-1',
        'resultType': 'runs',
        'margin': 10,
        'summary': 'Won by 10 runs',
      },
      'playerResult': 'won',
      'playerTeamId': 'home-1',
      'batting': {
        'runsScored': 75,
        'ballsFaced': 45,
        'fours': 8,
        'sixes': 3,
        'isNotOut': true,
        'strikeRate': '166.67',
      },
      'bowling': {
        'oversBowled': '4.0',
        'runsConceded': 30,
        'wicketsTaken': 2,
        'maidens': 0,
        'economyRate': '7.50',
      },
      'fielding': {
        'catches': 1,
        'runOuts': 0,
        'stumpings': 0,
      },
    };

    test('fromJson parses complete match performance', () {
      final model = MatchPerformanceModel.fromJson(fullJson);
      expect(model.matchId, 'match-1');
      expect(model.format, 'T20');
      expect(model.matchDate, '2026-06-15');
      expect(model.venue, 'Wankhede Stadium');
      expect(model.homeTeam.name, 'Mumbai Indians');
      expect(model.awayTeam.name, 'Chennai Super Kings');
      expect(model.teamScores.length, 2);
      expect(model.result, isNotNull);
      expect(model.result!.resultType, 'runs');
      expect(model.playerResult, 'won');
      expect(model.batting, isNotNull);
      expect(model.batting!.runsScored, 75);
      expect(model.bowling, isNotNull);
      expect(model.bowling!.wicketsTaken, 2);
      expect(model.fielding, isNotNull);
      expect(model.fielding!.catches, 1);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'matchId': 'match-2',
        'format': 'ODI',
        'matchDate': '2026-07-01',
        'homeTeam': {'id': 'h', 'name': 'Team A'},
        'awayTeam': {'id': 'a', 'name': 'Team B'},
        'playerTeamId': 'h',
      };

      final model = MatchPerformanceModel.fromJson(minimalJson);
      expect(model.venue, isNull);
      expect(model.result, isNull);
      expect(model.batting, isNull);
      expect(model.bowling, isNull);
      expect(model.fielding, isNull);
      expect(model.teamScores, isEmpty);
      expect(model.playerResult, 'no_result');
    });

    test('toEntity converts all fields correctly', () {
      final model = MatchPerformanceModel.fromJson(fullJson);
      final entity = model.toEntity();

      expect(entity.matchId, 'match-1');
      expect(entity.format, 'T20');
      expect(entity.homeTeam.name, 'Mumbai Indians');
      expect(entity.homeTeam.logoUrl, 'mi.png');
      expect(entity.awayTeam.logoUrl, isNull);
      expect(entity.teamScores.length, 2);
      expect(entity.teamScores.first.runs, 180);
      expect(entity.result!.summary, 'Won by 10 runs');
      expect(entity.isWon, isTrue);
      expect(entity.batting!.scoreDisplay, '75* (45)');
      expect(entity.bowling!.figuresDisplay, '2/30 (4.0)');
    });
  });

  group('PersonalBattingModel', () {
    test('toEntity converts strikeRate string to double', () {
      const model = PersonalBattingModel(
        runsScored: 50,
        ballsFaced: 30,
        strikeRate: '166.67',
      );
      final entity = model.toEntity();
      expect(entity.strikeRate, closeTo(166.67, 0.01));
    });

    test('toEntity handles null strikeRate', () {
      const model = PersonalBattingModel(
        runsScored: 0,
        ballsFaced: 0,
      );
      final entity = model.toEntity();
      expect(entity.strikeRate, isNull);
    });
  });

  group('PersonalBowlingModel', () {
    test('toEntity converts economyRate string to double', () {
      const model = PersonalBowlingModel(
        oversBowled: '4.0',
        runsConceded: 30,
        wicketsTaken: 2,
        economyRate: '7.50',
      );
      final entity = model.toEntity();
      expect(entity.economyRate, closeTo(7.5, 0.01));
    });
  });

  group('TeamScoreModel', () {
    test('toEntity preserves all fields', () {
      const model = TeamScoreModel(
        teamId: 't1',
        teamName: 'Team 1',
        runs: 200,
        wickets: 7,
        overs: '50.0',
      );
      final entity = model.toEntity();
      expect(entity.scoreDisplay, '200/7 (50.0)');
    });
  });
}
