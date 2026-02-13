import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/data/database/daos/teams_dao.dart';

void main() {
  late AppDatabase db;
  late TeamsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TeamsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  final now = DateTime(2024, 1, 15, 10, 30);

  UsersCompanion makeUser({
    required String id,
    required String firebaseUid,
    String displayName = 'Test User',
  }) {
    return UsersCompanion.insert(
      id: id,
      firebaseUid: firebaseUid,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
  }

  TeamsCompanion makeTeam({
    required String id,
    required String name,
    String createdBy = 'user-1',
    String? location,
  }) {
    return TeamsCompanion.insert(
      id: id,
      name: name,
      createdBy: createdBy,
      location: Value(location),
      createdAt: now,
      updatedAt: now,
    );
  }

  TeamRostersCompanion makeRosterEntry({
    required String id,
    required String teamId,
    required String playerId,
    String role = 'player',
  }) {
    return TeamRostersCompanion.insert(
      id: id,
      teamId: teamId,
      playerId: playerId,
      role: Value(role),
      joinedAt: now,
      updatedAt: now,
    );
  }

  group('TeamsDao - upsertTeam', () {
    test('inserts a new team', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Mumbai Warriors'));

      final teams = await dao.getAllTeams();
      expect(teams.length, 1);
      expect(teams.first.name, 'Mumbai Warriors');
    });

    test('updates existing team on conflict', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Old Name'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'New Name'));

      final teams = await dao.getAllTeams();
      expect(teams.length, 1);
      expect(teams.first.name, 'New Name');
    });
  });

  group('TeamsDao - upsertTeams', () {
    test('inserts multiple teams in batch', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeams([
        makeTeam(id: 'team-1', name: 'Alpha'),
        makeTeam(id: 'team-2', name: 'Bravo'),
        makeTeam(id: 'team-3', name: 'Charlie'),
      ]);

      final teams = await dao.getAllTeams();
      expect(teams.length, 3);
    });

    test('replaces existing teams in batch', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeams([
        makeTeam(id: 'team-1', name: 'Alpha'),
        makeTeam(id: 'team-2', name: 'Bravo'),
      ]);
      await dao.upsertTeams([
        makeTeam(id: 'team-1', name: 'Alpha Updated'),
      ]);

      final teams = await dao.getAllTeams();
      expect(teams.length, 2);
      expect(teams.any((t) => t.name == 'Alpha Updated'), isTrue);
    });
  });

  group('TeamsDao - getAllTeams', () {
    test('returns empty list when no teams', () async {
      final teams = await dao.getAllTeams();
      expect(teams, isEmpty);
    });

    test('returns teams ordered by name', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeams([
        makeTeam(id: 'team-c', name: 'Charlie'),
        makeTeam(id: 'team-a', name: 'Alpha'),
        makeTeam(id: 'team-b', name: 'Bravo'),
      ]);

      final teams = await dao.getAllTeams();
      expect(teams[0].name, 'Alpha');
      expect(teams[1].name, 'Bravo');
      expect(teams[2].name, 'Charlie');
    });
  });

  group('TeamsDao - getTeamById', () {
    test('returns team when found', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertTeam(
          makeTeam(id: 'team-1', name: 'Mumbai', location: 'Mumbai'));

      final team = await dao.getTeamById('team-1');
      expect(team, isNotNull);
      expect(team!.name, 'Mumbai');
      expect(team.location, 'Mumbai');
    });

    test('returns null when not found', () async {
      final team = await dao.getTeamById('nonexistent');
      expect(team, isNull);
    });
  });

  group('TeamsDao - roster operations', () {
    test('upsertRosterEntry inserts entry', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertUser(
          makeUser(id: 'player-1', firebaseUid: 'uid-p1', displayName: 'P1'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Team'));
      await dao.upsertRosterEntry(makeRosterEntry(
          id: 'r-1', teamId: 'team-1', playerId: 'player-1', role: 'captain'));

      final roster = await dao.getRosterForTeam('team-1');
      expect(roster.length, 1);
      expect(roster.first.roster.role, 'captain');
      expect(roster.first.user.displayName, 'P1');
    });

    test('upsertRosterEntries inserts multiple entries', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertUser(
          makeUser(id: 'player-1', firebaseUid: 'uid-p1', displayName: 'P1'));
      await dao.upsertUser(
          makeUser(id: 'player-2', firebaseUid: 'uid-p2', displayName: 'P2'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Team'));

      await dao.upsertRosterEntries([
        makeRosterEntry(id: 'r-1', teamId: 'team-1', playerId: 'player-1'),
        makeRosterEntry(id: 'r-2', teamId: 'team-1', playerId: 'player-2'),
      ]);

      final roster = await dao.getRosterForTeam('team-1');
      expect(roster.length, 2);
    });

    test('getRosterForTeam joins user data', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertUser(makeUser(
        id: 'player-1',
        firebaseUid: 'uid-p1',
        displayName: 'Virat Kohli',
      ));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Team'));
      await dao.upsertRosterEntry(
          makeRosterEntry(id: 'r-1', teamId: 'team-1', playerId: 'player-1'));

      final roster = await dao.getRosterForTeam('team-1');
      expect(roster.first.user.displayName, 'Virat Kohli');
      expect(roster.first.user.id, 'player-1');
    });

    test('getRosterForTeam returns empty for unknown team', () async {
      final roster = await dao.getRosterForTeam('nonexistent');
      expect(roster, isEmpty);
    });

    test('deleteRosterForTeam removes entries', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertUser(
          makeUser(id: 'player-1', firebaseUid: 'uid-p1', displayName: 'P1'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Team'));
      await dao.upsertRosterEntry(
          makeRosterEntry(id: 'r-1', teamId: 'team-1', playerId: 'player-1'));

      await dao.deleteRosterForTeam('team-1');

      final roster = await dao.getRosterForTeam('team-1');
      expect(roster, isEmpty);
    });

    test('deleteRosterForTeam only removes for specified team', () async {
      await dao.upsertUser(makeUser(id: 'user-1', firebaseUid: 'uid-1'));
      await dao.upsertUser(
          makeUser(id: 'player-1', firebaseUid: 'uid-p1', displayName: 'P1'));
      await dao.upsertTeam(makeTeam(id: 'team-1', name: 'Team 1'));
      await dao.upsertTeam(makeTeam(id: 'team-2', name: 'Team 2'));
      await dao.upsertRosterEntry(
          makeRosterEntry(id: 'r-1', teamId: 'team-1', playerId: 'player-1'));
      await dao.upsertRosterEntry(
          makeRosterEntry(id: 'r-2', teamId: 'team-2', playerId: 'player-1'));

      await dao.deleteRosterForTeam('team-1');

      final roster1 = await dao.getRosterForTeam('team-1');
      final roster2 = await dao.getRosterForTeam('team-2');
      expect(roster1, isEmpty);
      expect(roster2.length, 1);
    });
  });
}
