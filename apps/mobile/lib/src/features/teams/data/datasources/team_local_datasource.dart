import 'package:drift/drift.dart';

import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart' as db;
import 'package:cricscores/src/shared/data/database/daos/teams_dao.dart';

import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';

/// Local datasource for team data using Drift/SQLite.
class TeamLocalDatasource {
  TeamLocalDatasource({required this.teamsDao});

  final TeamsDao teamsDao;

  /// Cache a list of teams from the API response.
  Future<void> cacheTeams(List<Map<String, dynamic>> teamsJson) async {
    final companions = <db.TeamsCompanion>[];

    for (final json in teamsJson) {
      final now = DateTime.now();
      companions.add(db.TeamsCompanion.insert(
        id: json['id'] as String,
        name: json['name'] as String,
        createdBy: json['createdBy'] as String,
        location: Value(json['location'] as String?),
        logoUrl: Value(json['logoUrl'] as String?),
        isActive: Value(json['isActive'] as bool? ?? true),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : now,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : now,
      ));
    }

    await teamsDao.upsertTeams(companions);
  }

  /// Cache a team detail with its roster.
  Future<void> cacheTeamDetail(Map<String, dynamic> teamJson) async {
    final now = DateTime.now();

    // Cache the team
    await teamsDao.upsertTeam(db.TeamsCompanion.insert(
      id: teamJson['id'] as String,
      name: teamJson['name'] as String,
      createdBy: teamJson['createdBy'] as String,
      location: Value(teamJson['location'] as String?),
      logoUrl: Value(teamJson['logoUrl'] as String?),
      isActive: Value(teamJson['isActive'] as bool? ?? true),
      createdAt: teamJson['createdAt'] != null
          ? DateTime.parse(teamJson['createdAt'] as String)
          : now,
      updatedAt: teamJson['updatedAt'] != null
          ? DateTime.parse(teamJson['updatedAt'] as String)
          : now,
    ));

    // Cache roster entries + their user profiles
    final roster = teamJson['roster'] as List?;
    if (roster != null) {
      final teamId = teamJson['id'] as String;
      await teamsDao.deleteRosterForTeam(teamId);

      for (final entry in roster) {
        final r = entry as Map<String, dynamic>;
        final playerId = r['playerId'] as String;

        // Cache user profile
        await teamsDao.upsertUser(db.UsersCompanion.insert(
          id: playerId,
          firebaseUid: playerId, // Use playerId as placeholder UID
          displayName: r['displayName'] as String? ?? 'Unknown',
          phone: Value(r['phone'] as String?),
          battingStyle: Value(r['battingStyle'] as String?),
          bowlingStyle: Value(r['bowlingStyle'] as String?),
          playerRole: Value(r['playerRole'] as String?),
          avatarUrl: Value(r['avatarUrl'] as String?),
          createdAt: now,
          updatedAt: now,
        ));

        // Cache roster entry
        await teamsDao.upsertRosterEntry(db.TeamRostersCompanion.insert(
          id: r['id'] as String,
          teamId: teamId,
          playerId: playerId,
          jerseyNumber: Value(r['jerseyNumber'] as int?),
          role: Value(r['role'] as String? ?? 'player'),
          isActive: Value(r['isActive'] as bool? ?? true),
          joinedAt: r['joinedAt'] != null
              ? DateTime.parse(r['joinedAt'] as String)
              : now,
          updatedAt: now,
        ));
      }
    }
  }

  /// Get cached teams as domain entities.
  Future<List<Team>> getCachedTeams() async {
    final rows = await teamsDao.getAllTeams();
    return rows.map(_teamRowToEntity).toList();
  }

  /// Get a cached team with roster as domain entities.
  Future<TeamDetail?> getCachedTeamDetail(String teamId) async {
    final teamRow = await teamsDao.getTeamById(teamId);
    if (teamRow == null) return null;

    final rosterRows = await teamsDao.getRosterForTeam(teamId);
    return TeamDetail(
      team: _teamRowToEntity(teamRow),
      roster: rosterRows.map(_rosterRowToEntity).toList(),
    );
  }

  Team _teamRowToEntity(db.Team row) {
    return Team(
      id: row.id,
      name: row.name,
      createdBy: row.createdBy,
      isActive: row.isActive,
      playerCount: 0, // Not stored locally, recounted from roster
      role: TeamMemberRole.member, // Not stored locally
      location: row.location,
      logoUrl: row.logoUrl,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  RosterEntry _rosterRowToEntity(TeamRosterWithUser row) {
    return RosterEntry(
      id: row.roster.id,
      playerId: row.roster.playerId,
      displayName: row.user.displayName,
      rosterRole: RosterRole.fromApiValue(row.roster.role),
      isActive: row.roster.isActive,
      joinedAt: row.roster.joinedAt,
      jerseyNumber: row.roster.jerseyNumber,
      playerRole: PlayerRole.fromApiValue(row.user.playerRole),
      battingStyle: BattingStyle.fromApiValue(row.user.battingStyle),
      bowlingStyle: BowlingStyle.fromApiValue(row.user.bowlingStyle),
      phone: row.user.phone,
      avatarUrl: row.user.avatarUrl,
    );
  }
}
