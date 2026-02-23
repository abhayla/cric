import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/features/home/data/datasources/home_remote_datasource.dart';
import 'package:cricscores/src/features/home/data/repositories/home_repository_impl.dart';

class MockHomeRemoteDatasource extends Mock implements HomeRemoteDatasource {}

void main() {
  late MockHomeRemoteDatasource mockDatasource;
  late HomeRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockHomeRemoteDatasource();
    repository = HomeRepositoryImpl(remoteDatasource: mockDatasource);
  });

  final matchesResponse = {
    'matches': [
      {
        'id': 'match-1',
        'homeTeam': {'id': 'team-1', 'name': 'Mumbai'},
        'awayTeam': {'id': 'team-2', 'name': 'Chennai'},
        'format': 'T20',
        'totalOvers': 20,
        'status': 'live',
        'matchDate': '2026-03-15',
        'currentInnings': {
          'battingTeamId': 'team-1',
          'totalRuns': 120,
          'totalWickets': 3,
          'overs': '12.4',
        },
      },
    ],
    'total': 1,
    'page': 1,
  };

  group('getMatches', () {
    test('delegates to datasource', () async {
      when(() => mockDatasource.getMatches(
            status: any(named: 'status'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => matchesResponse);

      await repository.getMatches(status: 'live');

      verify(() => mockDatasource.getMatches(status: 'live')).called(1);
    });

    test('maps models to entities', () async {
      when(() => mockDatasource.getMatches(
            status: any(named: 'status'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => matchesResponse);

      final result = await repository.getMatches();

      expect(result.matches.length, 1);
      expect(result.matches.first.homeTeamName, 'Mumbai');
      expect(result.matches.first.awayTeamName, 'Chennai');
      expect(result.matches.first.currentInnings, isNotNull);
      expect(result.matches.first.currentInnings!.totalRuns, 120);
    });

    test('propagates exceptions from datasource', () async {
      when(() => mockDatasource.getMatches(
            status: any(named: 'status'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(const NetworkException());

      expect(
        () => repository.getMatches(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('passes pagination params', () async {
      when(() => mockDatasource.getMatches(
            status: any(named: 'status'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => {
            'matches': <Map<String, dynamic>>[],
            'total': 0,
            'page': 2,
          });

      await repository.getMatches(page: 2, limit: 10);

      verify(() => mockDatasource.getMatches(page: 2, limit: 10)).called(1);
    });
  });
}
