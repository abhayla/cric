import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/features/teams/data/datasources/team_local_datasource.dart';
import 'package:cricscores/src/features/teams/domain/entities/team.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart' hide Team;
import 'package:cricscores/src/shared/data/database/daos/teams_dao.dart';

void main() {
  late AppDatabase db;
  late TeamsDao dao;
  late TeamLocalDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TeamsDao(db);
    datasource = TeamLocalDatasource(teamsDao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> makeTeamJson({
    required String id,
    required String name,
    String createdBy = 'user-1',
    String? location,
  }) {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'location': location,
      'logoUrl': null,
      'isActive': true,
      'playerCount': 5,
      'role': 'owner',
      'createdAt': '2024-01-15T10:30:00Z',
      'updatedAt': '2024-01-15T10:30:00Z',
    };
  }

  Map<String, dynamic> makeRosterEntryJson({
    required String id,
    required String playerId,
    String displayName = 'Player',
    String role = 'player',
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) {
    return {
      'id': id,
      'playerId': playerId,
      'displayName': displayName,
      'role': role,
      'isActive': true,
      'joinedAt': '2024-01-15T10:30:00Z',
      'jerseyNumber': null,
      'playerRole': playerRole,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'phone': null,
      'avatarUrl': null,
    };
  }

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

  group('TeamLocalDatasource - cacheTeams', () {
    test('caches a list of teams', () async {
      await seedOwner();
      await datasource.cacheTeams([
        makeTeamJson(id: 'team-1', name: 'Alpha'),
        makeTeamJson(id: 'team-2', name: 'Bravo'),
      ]);

      final teams = await datasource.getCachedTeams();
      expect(teams.length, 2);
    });

    test('updates existing teams on re-cache', () async {
      await seedOwner();
      await datasource.cacheTeams([
        makeTeamJson(id: 'team-1', name: 'Old Name'),
      ]);
      await datasource.cacheTeams([
        makeTeamJson(id: 'team-1', name: 'New Name'),
      ]);

      final teams = await datasource.getCachedTeams();
      expect(teams.length, 1);
      expect(teams.first.name, 'New Name');
    });
  });

  group('TeamLocalDatasource - getCachedTeams', () {
    test('returns empty list when no teams cached', () async {
      final teams = await datasource.getCachedTeams();
      expect(teams, isEmpty);
    });

    test('returns teams as domain entities', () async {
      await seedOwner();
      await datasource.cacheTeams([
        makeTeamJson(
            id: 'team-1', name: 'Mumbai Warriors', location: 'Mumbai'),
      ]);

      final teams = await datasource.getCachedTeams();
      expect(teams.first, isA<Team>());
      expect(teams.first.name, 'Mumbai Warriors');
      expect(teams.first.location, 'Mumbai');
      expect(teams.first.isActive, isTrue);
    });
  });

  group('TeamLocalDatasource - cacheTeamDetail', () {
    test('caches team and roster', () async {
      await seedOwner();
      final teamJson = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson['roster'] = [
        makeRosterEntryJson(id: 'r-1', playerId: 'p-1', displayName: 'Virat'),
        makeRosterEntryJson(id: 'r-2', playerId: 'p-2', displayName: 'Rohit'),
      ];

      await datasource.cacheTeamDetail(teamJson);

      final detail = await datasource.getCachedTeamDetail('team-1');
      expect(detail, isNotNull);
      expect(detail!.team.name, 'Mumbai');
      expect(detail.roster.length, 2);
    });

    test('replaces old roster on re-cache', () async {
      await seedOwner();
      final teamJson1 = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson1['roster'] = [
        makeRosterEntryJson(id: 'r-1', playerId: 'p-1', displayName: 'Virat'),
        makeRosterEntryJson(id: 'r-2', playerId: 'p-2', displayName: 'Rohit'),
        makeRosterEntryJson(id: 'r-3', playerId: 'p-3', displayName: 'KL'),
      ];
      await datasource.cacheTeamDetail(teamJson1);

      // Re-cache with only 2 players
      final teamJson2 = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson2['roster'] = [
        makeRosterEntryJson(id: 'r-1', playerId: 'p-1', displayName: 'Virat'),
        makeRosterEntryJson(id: 'r-2', playerId: 'p-2', displayName: 'Rohit'),
      ];
      await datasource.cacheTeamDetail(teamJson2);

      final detail = await datasource.getCachedTeamDetail('team-1');
      expect(detail!.roster.length, 2);
    });

    test('caches roster with player roles', () async {
      await seedOwner();
      final teamJson = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson['roster'] = [
        makeRosterEntryJson(
          id: 'r-1',
          playerId: 'p-1',
          displayName: 'Virat',
          role: 'captain',
          playerRole: 'batter',
          battingStyle: 'right_hand',
        ),
      ];

      await datasource.cacheTeamDetail(teamJson);

      final detail = await datasource.getCachedTeamDetail('team-1');
      final player = detail!.roster.first;
      expect(player.rosterRole, RosterRole.captain);
      expect(player.playerRole, PlayerRole.batter);
      expect(player.battingStyle, BattingStyle.rightHand);
    });

    test('caches roster with bowling styles', () async {
      await seedOwner();
      final teamJson = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson['roster'] = [
        makeRosterEntryJson(
          id: 'r-1',
          playerId: 'p-1',
          displayName: 'Bumrah',
          playerRole: 'bowler',
          bowlingStyle: 'right_arm_fast',
        ),
      ];

      await datasource.cacheTeamDetail(teamJson);

      final detail = await datasource.getCachedTeamDetail('team-1');
      final player = detail!.roster.first;
      expect(player.playerRole, PlayerRole.bowler);
      expect(player.bowlingStyle, BowlingStyle.rightArmFast);
    });
  });

  group('TeamLocalDatasource - getCachedTeamDetail', () {
    test('returns null for unknown team', () async {
      final detail = await datasource.getCachedTeamDetail('nonexistent');
      expect(detail, isNull);
    });

    test('returns team with empty roster if no roster cached', () async {
      await seedOwner();
      await datasource.cacheTeams([
        makeTeamJson(id: 'team-1', name: 'Mumbai'),
      ]);

      final detail = await datasource.getCachedTeamDetail('team-1');
      expect(detail, isNotNull);
      expect(detail!.team.name, 'Mumbai');
      expect(detail.roster, isEmpty);
    });

    test('roster entries are RosterEntry domain entities', () async {
      await seedOwner();
      final teamJson = makeTeamJson(id: 'team-1', name: 'Mumbai');
      teamJson['roster'] = [
        makeRosterEntryJson(id: 'r-1', playerId: 'p-1', displayName: 'Test'),
      ];
      await datasource.cacheTeamDetail(teamJson);

      final detail = await datasource.getCachedTeamDetail('team-1');
      expect(detail!.roster.first, isA<RosterEntry>());
    });
  });
}
