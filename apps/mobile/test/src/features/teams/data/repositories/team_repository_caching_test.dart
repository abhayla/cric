import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/features/teams/data/datasources/team_local_datasource.dart';
import 'package:cricscores/src/features/teams/data/datasources/team_remote_datasource.dart';
import 'package:cricscores/src/features/teams/data/repositories/team_repository_impl.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/data/database/daos/teams_dao.dart';

class MockTeamRemoteDatasource extends Mock implements TeamRemoteDatasource {}

void main() {
  late AppDatabase db;
  late TeamsDao dao;
  late TeamLocalDatasource localDatasource;
  late MockTeamRemoteDatasource remoteDatasource;
  late TeamRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TeamsDao(db);
    localDatasource = TeamLocalDatasource(teamsDao: dao);
    remoteDatasource = MockTeamRemoteDatasource();
    repository = TeamRepositoryImpl(
      remoteDatasource: remoteDatasource,
      localDatasource: localDatasource,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // Seed a user for FK constraints
  Future<void> seedOwner() async {
    await dao.upsertUser(UsersCompanion.insert(
      id: 'user-1',
      firebaseUid: 'uid-1',
      displayName: 'Owner',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  }

  group('getTeams caching', () {
    test('returns remote data and caches locally', () async {
      await seedOwner();
      when(() => remoteDatasource.getTeams(page: 1, limit: 20)).thenAnswer(
        (_) async => {
          'teams': [
            {
              'id': 'team-1',
              'name': 'Mumbai Warriors',
              'createdBy': 'user-1',
              'location': 'Mumbai',
              'logoUrl': null,
              'isActive': true,
              'playerCount': 11,
              'role': 'owner',
              'createdAt': '2024-01-15T10:00:00Z',
              'updatedAt': '2024-01-15T10:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
        },
      );

      final result = await repository.getTeams();
      expect(result.teams.length, 1);
      expect(result.teams.first.name, 'Mumbai Warriors');

      // Verify cached locally
      final cached = await localDatasource.getCachedTeams();
      expect(cached.length, 1);
      expect(cached.first.name, 'Mumbai Warriors');
    });

    test('falls back to local cache when remote fails', () async {
      await seedOwner();
      // Pre-cache some data
      await localDatasource.cacheTeams([
        {
          'id': 'team-1',
          'name': 'Cached Team',
          'createdBy': 'user-1',
          'location': null,
          'logoUrl': null,
          'isActive': true,
          'createdAt': '2024-01-15T10:00:00Z',
          'updatedAt': '2024-01-15T10:00:00Z',
        },
      ]);

      when(() => remoteDatasource.getTeams(page: 1, limit: 20))
          .thenThrow(const NetworkException());

      final result = await repository.getTeams();
      expect(result.teams.length, 1);
      expect(result.teams.first.name, 'Cached Team');
    });

    test('rethrows when remote fails and no local cache', () async {
      when(() => remoteDatasource.getTeams(page: 1, limit: 20))
          .thenThrow(const NetworkException());

      expect(
        () => repository.getTeams(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getTeam caching', () {
    test('returns remote data and caches team detail', () async {
      await seedOwner();
      when(() => remoteDatasource.getTeam('team-1')).thenAnswer(
        (_) async => {
          'id': 'team-1',
          'name': 'Mumbai Warriors',
          'createdBy': 'user-1',
          'location': 'Mumbai',
          'logoUrl': null,
          'isActive': true,
          'playerCount': 2,
          'role': 'owner',
          'createdAt': '2024-01-15T10:00:00Z',
          'updatedAt': '2024-01-15T10:00:00Z',
          'roster': [
            {
              'id': 'r-1',
              'playerId': 'p-1',
              'displayName': 'Player One',
              'role': 'captain',
              'isActive': true,
              'joinedAt': '2024-01-15T10:00:00Z',
              'jerseyNumber': 18,
              'playerRole': 'batter',
              'battingStyle': 'right_hand',
              'bowlingStyle': null,
              'phone': null,
              'avatarUrl': null,
            },
          ],
        },
      );

      final result = await repository.getTeam('team-1');
      expect(result.team.name, 'Mumbai Warriors');
      expect(result.roster.length, 1);

      // Verify cached locally
      final cached = await localDatasource.getCachedTeamDetail('team-1');
      expect(cached, isNotNull);
      expect(cached!.roster.length, 1);
      expect(cached.roster.first.displayName, 'Player One');
    });

    test('falls back to local cache when remote fails', () async {
      await seedOwner();
      // Pre-cache team detail
      await localDatasource.cacheTeamDetail({
        'id': 'team-1',
        'name': 'Cached Team',
        'createdBy': 'user-1',
        'location': null,
        'logoUrl': null,
        'isActive': true,
        'createdAt': '2024-01-15T10:00:00Z',
        'updatedAt': '2024-01-15T10:00:00Z',
        'roster': [
          {
            'id': 'r-1',
            'playerId': 'p-1',
            'displayName': 'Cached Player',
            'role': 'player',
            'isActive': true,
            'joinedAt': '2024-01-15T10:00:00Z',
            'jerseyNumber': null,
            'playerRole': null,
            'battingStyle': null,
            'bowlingStyle': null,
            'phone': null,
            'avatarUrl': null,
          },
        ],
      });

      when(() => remoteDatasource.getTeam('team-1'))
          .thenThrow(const NetworkException());

      final result = await repository.getTeam('team-1');
      expect(result.team.name, 'Cached Team');
      expect(result.roster.length, 1);
      expect(result.roster.first.displayName, 'Cached Player');
    });

    test('rethrows when remote fails and no local cache', () async {
      when(() => remoteDatasource.getTeam('team-1'))
          .thenThrow(const NetworkException());

      expect(
        () => repository.getTeam('team-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('repository without local datasource', () {
    test('works without local datasource', () async {
      final repoWithoutLocal = TeamRepositoryImpl(
        remoteDatasource: remoteDatasource,
      );

      when(() => remoteDatasource.getTeams(page: 1, limit: 20)).thenAnswer(
        (_) async => {
          'teams': [
            {
              'id': 'team-1',
              'name': 'Remote Team',
              'createdBy': 'user-1',
              'location': null,
              'logoUrl': null,
              'isActive': true,
              'playerCount': 0,
              'role': 'member',
              'createdAt': '2024-01-15T10:00:00Z',
              'updatedAt': '2024-01-15T10:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
        },
      );

      final result = await repoWithoutLocal.getTeams();
      expect(result.teams.length, 1);
      expect(result.teams.first.name, 'Remote Team');
    });

    test('rethrows on failure without local datasource', () async {
      final repoWithoutLocal = TeamRepositoryImpl(
        remoteDatasource: remoteDatasource,
      );

      when(() => remoteDatasource.getTeams(page: 1, limit: 20))
          .thenThrow(const NetworkException());

      expect(
        () => repoWithoutLocal.getTeams(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
