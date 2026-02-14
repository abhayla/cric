import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/features/player_profile/data/datasources/player_profile_remote_datasource.dart';
import 'package:cricapp/src/features/player_profile/data/repositories/player_profile_repository_impl.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/match_performance.dart';

class MockPlayerProfileRemoteDatasource extends Mock
    implements PlayerProfileRemoteDatasource {}

void main() {
  late MockPlayerProfileRemoteDatasource mockDatasource;
  late PlayerProfileRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockPlayerProfileRemoteDatasource();
    repository = PlayerProfileRepositoryImpl(remoteDatasource: mockDatasource);
  });

  final profileData = {
    'id': 'player-1',
    'displayName': 'Virat Kohli',
    'playerRole': 'batter',
    'battingStyle': 'right_hand',
    'bowlingStyle': 'right_arm_medium',
    'location': 'Delhi',
    'teams': [
      {
        'teamId': 'team-1',
        'teamName': 'RCB',
        'role': 'captain',
      },
    ],
  };

  final statsData = {
    'format': 'T20',
    'matchesPlayed': 10,
    'totalRuns': 450,
    'highestScore': 82,
    'battingAverage': '56.25',
    'wicketsTaken': 3,
    'catches': 5,
  };

  group('getProfile', () {
    test('returns PlayerProfile entity', () async {
      when(() => mockDatasource.getProfile(any()))
          .thenAnswer((_) async => profileData);

      final result = await repository.getProfile('player-1');

      expect(result, isA<PlayerProfile>());
      expect(result.id, 'player-1');
      expect(result.displayName, 'Virat Kohli');
      expect(result.teams.length, 1);
      expect(result.teams.first.teamName, 'RCB');
      verify(() => mockDatasource.getProfile('player-1')).called(1);
    });

    test('propagates exceptions from datasource', () async {
      when(() => mockDatasource.getProfile(any()))
          .thenThrow(Exception('Server error'));

      expect(
        () => repository.getProfile('player-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getStats', () {
    test('returns CareerStats entity', () async {
      when(() => mockDatasource.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => statsData);

      final result = await repository.getStats('player-1', format: 'T20');

      expect(result, isA<CareerStats>());
      expect(result!.format, 'T20');
      expect(result.batting.totalRuns, 450);
      expect(result.batting.highestScore, 82);
      expect(result.fielding.catches, 5);
    });

    test('returns null when datasource returns null', () async {
      when(() => mockDatasource.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => null);

      final result = await repository.getStats('player-1');
      expect(result, isNull);
    });

    test('passes format parameter to datasource', () async {
      when(() => mockDatasource.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => statsData);

      await repository.getStats('player-1', format: 'ODI');

      verify(() => mockDatasource.getStats('player-1', format: 'ODI')).called(1);
    });
  });

  group('getMatchHistory', () {
    test('returns MatchHistoryResult with entities', () async {
      when(() => mockDatasource.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            format: any(named: 'format'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => {
            'matches': [
              {
                'matchId': 'match-1',
                'format': 'T20',
                'matchDate': '2026-06-15',
                'homeTeam': {'id': 'h', 'name': 'Home'},
                'awayTeam': {'id': 'a', 'name': 'Away'},
                'playerTeamId': 'h',
                'playerResult': 'won',
              },
            ],
            'total': 1,
            'page': 1,
            'limit': 20,
          });

      final result = await repository.getMatchHistory('player-1');

      expect(result, isA<MatchHistoryResult>());
      expect(result.matches.length, 1);
      expect(result.matches.first.matchId, 'match-1');
      expect(result.total, 1);
      expect(result.page, 1);
    });

    test('passes all parameters to datasource', () async {
      when(() => mockDatasource.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            format: any(named: 'format'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => {
            'matches': [],
            'total': 0,
            'page': 2,
            'limit': 10,
          });

      await repository.getMatchHistory(
        'player-1',
        page: 2,
        limit: 10,
        format: 'T20',
        result: 'won',
      );

      verify(() => mockDatasource.getMatchHistory(
            'player-1',
            page: 2,
            limit: 10,
            format: 'T20',
            result: 'won',
          )).called(1);
    });

    test('returns empty list when no matches', () async {
      when(() => mockDatasource.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            format: any(named: 'format'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => {
            'matches': [],
            'total': 0,
            'page': 1,
            'limit': 20,
          });

      final result = await repository.getMatchHistory('player-1');
      expect(result.matches, isEmpty);
      expect(result.total, 0);
    });

    test('propagates exceptions from datasource', () async {
      when(() => mockDatasource.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            format: any(named: 'format'),
            result: any(named: 'result'),
          )).thenThrow(Exception('Network error'));

      expect(
        () => repository.getMatchHistory('player-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
