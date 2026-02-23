import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/features/player_profile/data/datasources/player_profile_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PlayerProfileRemoteDatasource datasource;

  setUp(() {
    mockDio = MockDio();
    datasource = PlayerProfileRemoteDatasource(dio: mockDio);
  });

  final profileJson = {
    'player': {
      'id': 'player-1',
      'displayName': 'Test Player',
      'teams': [],
    },
  };

  final statsJson = {
    'stats': {
      'format': 'T20',
      'matchesPlayed': 10,
      'totalRuns': 300,
    },
  };

  final matchesJson = {
    'matches': [
      {
        'matchId': 'match-1',
        'format': 'T20',
        'matchDate': '2026-06-15',
        'homeTeam': {'id': 'h', 'name': 'Home'},
        'awayTeam': {'id': 'a', 'name': 'Away'},
        'playerTeamId': 'h',
      },
    ],
    'total': 1,
    'page': 1,
    'limit': 20,
  };

  group('getProfile', () {
    test('returns profile data on success', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          data: profileJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await datasource.getProfile('player-1');
      expect(result['id'], 'player-1');
      expect(result['displayName'], 'Test Player');
    });

    test('throws ServerException on 404', () async {
      when(() => mockDio.get(any())).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            data: {'error': {'message': 'Player not found'}},
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => datasource.getProfile('nonexistent'),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws NetworkException on connection error', () async {
      when(() => mockDio.get(any())).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => datasource.getProfile('player-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getStats', () {
    test('returns stats data on success', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
        (_) async => Response(
          data: statsJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await datasource.getStats('player-1', format: 'T20');
      expect(result, isNotNull);
      expect(result!['matchesPlayed'], 10);
    });

    test('returns null when stats is null', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
        (_) async => Response(
          data: {'stats': null},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await datasource.getStats('player-1');
      expect(result, isNull);
    });

    test('throws ServerException on error', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            data: {'error': {'message': 'Not found'}},
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => datasource.getStats('nonexistent'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getMatchHistory', () {
    test('returns match history data on success', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
        (_) async => Response(
          data: matchesJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await datasource.getMatchHistory('player-1');
      expect(result['matches'], isA<List>());
      expect((result['matches'] as List).length, 1);
      expect(result['total'], 1);
    });

    test('passes query parameters correctly', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
        (_) async => Response(
          data: matchesJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await datasource.getMatchHistory(
        'player-1',
        page: 2,
        limit: 10,
        format: 'T20',
        result: 'won',
      );

      final captured = verify(
        () => mockDio.get(any(), queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(captured['page'], '2');
      expect(captured['limit'], '10');
      expect(captured['format'], 'T20');
      expect(captured['result'], 'won');
    });

    test('omits null query parameters', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
        (_) async => Response(
          data: matchesJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await datasource.getMatchHistory('player-1');

      final captured = verify(
        () => mockDio.get(any(), queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('format'), isFalse);
      expect(captured.containsKey('result'), isFalse);
    });

    test('throws NetworkException on timeout', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => datasource.getMatchHistory('player-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
