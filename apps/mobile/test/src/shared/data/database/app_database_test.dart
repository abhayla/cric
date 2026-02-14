import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/shared/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('schema version is 2', () {
      expect(db.schemaVersion, 2);
    });

    test('all 9 tables are registered', () {
      expect(db.allTables.length, 9);
    });

    test('users table exists', () {
      expect(db.users, isNotNull);
    });

    test('teams table exists', () {
      expect(db.teams, isNotNull);
    });

    test('teamRosters table exists', () {
      expect(db.teamRosters, isNotNull);
    });

    test('matches table exists', () {
      expect(db.matches, isNotNull);
    });

    test('matchPlayers table exists', () {
      expect(db.matchPlayers, isNotNull);
    });

    test('ballTypes table exists', () {
      expect(db.ballTypes, isNotNull);
    });

    test('syncQueue table exists', () {
      expect(db.syncQueue, isNotNull);
    });

    test('localPreferences table exists', () {
      expect(db.localPreferences, isNotNull);
    });

    test('scoringSnapshots table exists', () {
      expect(db.scoringSnapshots, isNotNull);
    });
  });

  group('ball_types seeding', () {
    test('seeds 4 ball types on creation', () async {
      final types = await db.select(db.ballTypes).get();
      expect(types.length, 4);
    });

    test('seeds leather ball type', () async {
      final types = await db.select(db.ballTypes).get();
      expect(types.any((t) => t.name == 'leather'), isTrue);
    });

    test('seeds tennis ball type', () async {
      final types = await db.select(db.ballTypes).get();
      expect(types.any((t) => t.name == 'tennis'), isTrue);
    });

    test('seeds tape ball type', () async {
      final types = await db.select(db.ballTypes).get();
      expect(types.any((t) => t.name == 'tape'), isTrue);
    });

    test('seeds other ball type', () async {
      final types = await db.select(db.ballTypes).get();
      expect(types.any((t) => t.name == 'other'), isTrue);
    });
  });

  group('users table operations', () {
    test('can insert and query a user', () async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'firebase-uid-1',
            displayName: 'John Doe',
            createdAt: now,
            updatedAt: now,
          ));

      final users = await db.select(db.users).get();
      expect(users.length, 1);
      expect(users.first.id, 'user-1');
      expect(users.first.displayName, 'John Doe');
      expect(users.first.firebaseUid, 'firebase-uid-1');
    });

    test('can insert user with all fields', () async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-2',
            firebaseUid: 'firebase-uid-2',
            displayName: 'Jane Smith',
            phone: const Value('9876543210'),
            email: const Value('jane@example.com'),
            avatarUrl: const Value('https://example.com/avatar.jpg'),
            battingStyle: const Value('right_hand'),
            bowlingStyle: const Value('right_arm_fast'),
            playerRole: const Value('all_rounder'),
            location: const Value('Mumbai'),
            createdAt: now,
            updatedAt: now,
          ));

      final users = await db.select(db.users).get();
      expect(users.first.phone, '9876543210');
      expect(users.first.battingStyle, 'right_hand');
      expect(users.first.bowlingStyle, 'right_arm_fast');
      expect(users.first.playerRole, 'all_rounder');
      expect(users.first.location, 'Mumbai');
    });

    test('enforces unique firebase_uid', () async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'same-uid',
            displayName: 'First User',
            createdAt: now,
            updatedAt: now,
          ));

      expect(
        () => db.into(db.users).insert(UsersCompanion.insert(
              id: 'user-2',
              firebaseUid: 'same-uid',
              displayName: 'Second User',
              createdAt: now,
              updatedAt: now,
            )),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('teams table operations', () {
    Future<void> insertTestUser() async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'firebase-uid-1',
            displayName: 'Owner',
            createdAt: now,
            updatedAt: now,
          ));
    }

    test('can insert and query a team', () async {
      await insertTestUser();
      final now = DateTime.now();
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-1',
            name: 'Mumbai Warriors',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));

      final teams = await db.select(db.teams).get();
      expect(teams.length, 1);
      expect(teams.first.name, 'Mumbai Warriors');
      expect(teams.first.isActive, isTrue);
    });

    test('can insert team with optional fields', () async {
      await insertTestUser();
      final now = DateTime.now();
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-1',
            name: 'Delhi Strikers',
            createdBy: 'user-1',
            location: const Value('Delhi'),
            logoUrl: const Value('https://example.com/logo.png'),
            createdAt: now,
            updatedAt: now,
          ));

      final teams = await db.select(db.teams).get();
      expect(teams.first.location, 'Delhi');
      expect(teams.first.logoUrl, 'https://example.com/logo.png');
    });

    test('can upsert (replace) a team', () async {
      await insertTestUser();
      final now = DateTime.now();
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-1',
            name: 'Old Name',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));

      await db.into(db.teams).insertOnConflictUpdate(TeamsCompanion.insert(
            id: 'team-1',
            name: 'New Name',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));

      final teams = await db.select(db.teams).get();
      expect(teams.length, 1);
      expect(teams.first.name, 'New Name');
    });

    test('can delete a team', () async {
      await insertTestUser();
      final now = DateTime.now();
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-1',
            name: 'Mumbai Warriors',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));

      await (db.delete(db.teams)..where((t) => t.id.equals('team-1'))).go();

      final teams = await db.select(db.teams).get();
      expect(teams, isEmpty);
    });
  });

  group('team_rosters table operations', () {
    Future<void> insertTestData() async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'firebase-uid-1',
            displayName: 'Owner',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'player-1',
            firebaseUid: 'firebase-uid-p1',
            displayName: 'Player One',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-1',
            name: 'Mumbai Warriors',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));
    }

    test('can insert a roster entry', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.teamRosters).insert(TeamRostersCompanion.insert(
            id: 'roster-1',
            teamId: 'team-1',
            playerId: 'player-1',
            joinedAt: now,
            updatedAt: now,
          ));

      final rosters = await db.select(db.teamRosters).get();
      expect(rosters.length, 1);
      expect(rosters.first.teamId, 'team-1');
      expect(rosters.first.playerId, 'player-1');
      expect(rosters.first.role, 'player');
    });

    test('can query roster by team', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'player-2',
            firebaseUid: 'firebase-uid-p2',
            displayName: 'Player Two',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.teamRosters).insert(TeamRostersCompanion.insert(
            id: 'roster-1',
            teamId: 'team-1',
            playerId: 'player-1',
            joinedAt: now,
            updatedAt: now,
          ));
      await db.into(db.teamRosters).insert(TeamRostersCompanion.insert(
            id: 'roster-2',
            teamId: 'team-1',
            playerId: 'player-2',
            joinedAt: now,
            updatedAt: now,
          ));

      final rosters = await (db.select(db.teamRosters)
            ..where((r) => r.teamId.equals('team-1')))
          .get();
      expect(rosters.length, 2);
    });

    test('enforces unique team+player constraint', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.teamRosters).insert(TeamRostersCompanion.insert(
            id: 'roster-1',
            teamId: 'team-1',
            playerId: 'player-1',
            joinedAt: now,
            updatedAt: now,
          ));

      expect(
        () => db.into(db.teamRosters).insert(TeamRostersCompanion.insert(
              id: 'roster-2',
              teamId: 'team-1',
              playerId: 'player-1',
              joinedAt: now,
              updatedAt: now,
            )),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('matches table operations', () {
    Future<void> insertTestData() async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'uid-1',
            displayName: 'Scorer',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-a',
            name: 'Team A',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-b',
            name: 'Team B',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));
    }

    test('can insert a match', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.matches).insert(MatchesCompanion.insert(
            id: 'match-1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
            format: 'T20',
            totalOvers: 20,
            ballTypeId: 1,
            createdBy: 'user-1',
            matchDate: now,
            createdAt: now,
            updatedAt: now,
          ));

      final matches = await db.select(db.matches).get();
      expect(matches.length, 1);
      expect(matches.first.format, 'T20');
      expect(matches.first.totalOvers, 20);
      expect(matches.first.status, 'setup');
      expect(matches.first.playersPerSide, 11);
      expect(matches.first.wideRuns, 1);
      expect(matches.first.noBallRuns, 1);
    });

    test('can insert match with all optional fields', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.matches).insert(MatchesCompanion.insert(
            id: 'match-1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
            format: 'ODI',
            totalOvers: 50,
            ballTypeId: 1,
            venue: const Value('Wankhede Stadium'),
            tossWinnerId: const Value('team-a'),
            tossDecision: const Value('bat'),
            status: const Value('live'),
            scorerId: const Value('user-1'),
            playersPerSide: const Value(11),
            maxOversPerBowler: const Value(10),
            powerplayOvers: const Value(10),
            createdBy: 'user-1',
            matchDate: now,
            createdAt: now,
            updatedAt: now,
          ));

      final matches = await db.select(db.matches).get();
      expect(matches.first.venue, 'Wankhede Stadium');
      expect(matches.first.tossWinnerId, 'team-a');
      expect(matches.first.tossDecision, 'bat');
      expect(matches.first.status, 'live');
      expect(matches.first.maxOversPerBowler, 10);
      expect(matches.first.powerplayOvers, 10);
    });
  });

  group('match_players table operations', () {
    Future<void> insertTestData() async {
      final now = DateTime.now();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'user-1',
            firebaseUid: 'uid-1',
            displayName: 'Scorer',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'player-1',
            firebaseUid: 'uid-p1',
            displayName: 'Player',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: 'team-a',
            name: 'Team A',
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.matches).insert(MatchesCompanion.insert(
            id: 'match-1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-a',
            format: 'T20',
            totalOvers: 20,
            ballTypeId: 1,
            createdBy: 'user-1',
            matchDate: now,
            createdAt: now,
            updatedAt: now,
          ));
    }

    test('can insert a match player', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.matchPlayers).insert(MatchPlayersCompanion.insert(
            id: 'mp-1',
            matchId: 'match-1',
            teamId: 'team-a',
            playerId: 'player-1',
            createdAt: now,
            updatedAt: now,
          ));

      final players = await db.select(db.matchPlayers).get();
      expect(players.length, 1);
      expect(players.first.isPlaying, isTrue);
      expect(players.first.isCaptain, isFalse);
      expect(players.first.isKeeper, isFalse);
    });

    test('enforces unique match+team+player constraint', () async {
      await insertTestData();
      final now = DateTime.now();
      await db.into(db.matchPlayers).insert(MatchPlayersCompanion.insert(
            id: 'mp-1',
            matchId: 'match-1',
            teamId: 'team-a',
            playerId: 'player-1',
            createdAt: now,
            updatedAt: now,
          ));

      expect(
        () =>
            db.into(db.matchPlayers).insert(MatchPlayersCompanion.insert(
                  id: 'mp-2',
                  matchId: 'match-1',
                  teamId: 'team-a',
                  playerId: 'player-1',
                  createdAt: now,
                  updatedAt: now,
                )),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('sync_queue table operations', () {
    test('can insert a sync entry', () async {
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            entityType: 'team',
            entityId: 'team-1',
            operation: 'create',
            payload: '{"name":"Test"}',
            createdAt: DateTime.now(),
          ));

      final entries = await db.select(db.syncQueue).get();
      expect(entries.length, 1);
      expect(entries.first.entityType, 'team');
      expect(entries.first.status, 'pending');
      expect(entries.first.retryCount, 0);
    });

    test('auto-increments id', () async {
      final now = DateTime.now();
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            entityType: 'team',
            entityId: 'team-1',
            operation: 'create',
            payload: '{}',
            createdAt: now,
          ));
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            entityType: 'match',
            entityId: 'match-1',
            operation: 'update',
            payload: '{}',
            createdAt: now,
          ));

      final entries = await db.select(db.syncQueue).get();
      expect(entries[0].id, 1);
      expect(entries[1].id, 2);
    });

    test('can query pending entries', () async {
      final now = DateTime.now();
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            entityType: 'team',
            entityId: 'team-1',
            operation: 'create',
            payload: '{}',
            createdAt: now,
          ));
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
            entityType: 'match',
            entityId: 'match-1',
            operation: 'update',
            payload: '{}',
            status: const Value('synced'),
            createdAt: now,
          ));

      final pending = await (db.select(db.syncQueue)
            ..where((s) => s.status.equals('pending')))
          .get();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'team');
    });
  });

  group('local_preferences table operations', () {
    test('can insert and query a preference', () async {
      await db.into(db.localPreferences).insert(
            LocalPreferencesCompanion.insert(
              key: 'last_sync_timestamp',
              value: '2024-01-01T00:00:00Z',
            ),
          );

      final prefs = await db.select(db.localPreferences).get();
      expect(prefs.length, 1);
      expect(prefs.first.key, 'last_sync_timestamp');
      expect(prefs.first.value, '2024-01-01T00:00:00Z');
    });

    test('can upsert a preference', () async {
      await db.into(db.localPreferences).insert(
            LocalPreferencesCompanion.insert(
              key: 'theme',
              value: 'light',
            ),
          );

      await db.into(db.localPreferences).insertOnConflictUpdate(
            LocalPreferencesCompanion.insert(
              key: 'theme',
              value: 'dark',
            ),
          );

      final prefs = await db.select(db.localPreferences).get();
      expect(prefs.length, 1);
      expect(prefs.first.value, 'dark');
    });

    test('enforces primary key on key column', () async {
      await db.into(db.localPreferences).insert(
            LocalPreferencesCompanion.insert(
              key: 'setting',
              value: 'value1',
            ),
          );

      expect(
        () => db.into(db.localPreferences).insert(
              LocalPreferencesCompanion.insert(
                key: 'setting',
                value: 'value2',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
