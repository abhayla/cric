import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/features/home/data/datasources/home_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late HomeRemoteDatasource datasource;

  setUp(() {
    mockDio = MockDio();
    datasource = HomeRemoteDatasource(dio: mockDio);
  });

  final matchJson = {
    'id': 'match-1',
    'homeTeam': {'id': 'team-1', 'name': 'Mumbai'},
    'awayTeam': {'id': 'team-2', 'name': 'Chennai'},
    'format': 'T20',
    'totalOvers': 20,
    'status': 'live',
    'matchDate': '2026-03-15',
  };

  group('getMatches', () {
    test('returns list of match data on success', () async {
      when(
        () => mockDio.get(
          '${AppConstants.apiBaseUrl}/matches',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'matches': [matchJson],
            'total': 1,
            'page': 1,
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getMatches();

      expect(result['matches'], isA<List>());
      expect((result['matches'] as List).length, 1);
      expect(result['total'], 1);
    });

    test('passes status filter as query param', () async {
      when(
        () => mockDio.get(
          '${AppConstants.apiBaseUrl}/matches',
          queryParameters: {
            'page': '1',
            'limit': '20',
            'status': 'live',
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'matches': [], 'total': 0, 'page': 1},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await datasource.getMatches(status: 'live');

      verify(
        () => mockDio.get(
          '${AppConstants.apiBaseUrl}/matches',
          queryParameters: {
            'page': '1',
            'limit': '20',
            'status': 'live',
          },
        ),
      ).called(1);
    });

    test('throws NetworkException on connection error', () async {
      when(
        () => mockDio.get(
          '${AppConstants.apiBaseUrl}/matches',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => datasource.getMatches(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on server error', () async {
      when(
        () => mockDio.get(
          '${AppConstants.apiBaseUrl}/matches',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            data: {
              'error': {'message': 'Internal server error'},
            },
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => datasource.getMatches(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
