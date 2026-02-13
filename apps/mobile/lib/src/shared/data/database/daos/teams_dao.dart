import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/teams_table.dart';
import '../tables/users_table.dart';

part 'teams_dao.g.dart';

/// DAO for team and roster caching operations.
@DriftAccessor(tables: [Teams, TeamRosters, Users])
class TeamsDao extends DatabaseAccessor<AppDatabase> with _$TeamsDaoMixin {
  TeamsDao(super.db);

  /// Insert or update a team record.
  Future<void> upsertTeam(TeamsCompanion team) {
    return into(teams).insertOnConflictUpdate(team);
  }

  /// Insert or update multiple teams in a batch.
  Future<void> upsertTeams(List<TeamsCompanion> teamList) {
    return batch((b) {
      for (final team in teamList) {
        b.insert(teams, team, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Get all cached teams ordered by name.
  Future<List<Team>> getAllTeams() {
    return (select(teams)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get a team by ID.
  Future<Team?> getTeamById(String teamId) {
    return (select(teams)..where((t) => t.id.equals(teamId)))
        .getSingleOrNull();
  }

  /// Insert or update a user record (needed for roster joins).
  Future<void> upsertUser(UsersCompanion user) {
    return into(users).insertOnConflictUpdate(user);
  }

  /// Insert or update a roster entry.
  Future<void> upsertRosterEntry(TeamRostersCompanion entry) {
    return into(teamRosters).insertOnConflictUpdate(entry);
  }

  /// Insert or update multiple roster entries in a batch.
  Future<void> upsertRosterEntries(List<TeamRostersCompanion> entries) {
    return batch((b) {
      for (final entry in entries) {
        b.insert(teamRosters, entry, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Get roster entries for a team, joined with user data.
  Future<List<TeamRosterWithUser>> getRosterForTeam(String teamId) async {
    final query = select(teamRosters).join([
      innerJoin(users, users.id.equalsExp(teamRosters.playerId)),
    ])
      ..where(teamRosters.teamId.equals(teamId));

    final rows = await query.get();
    return rows.map((row) {
      return TeamRosterWithUser(
        roster: row.readTable(teamRosters),
        user: row.readTable(users),
      );
    }).toList();
  }

  /// Delete all roster entries for a team (before re-caching).
  Future<void> deleteRosterForTeam(String teamId) {
    return (delete(teamRosters)..where((r) => r.teamId.equals(teamId))).go();
  }
}

/// Combined team roster entry with user profile data.
class TeamRosterWithUser {
  const TeamRosterWithUser({
    required this.roster,
    required this.user,
  });

  final TeamRoster roster;
  final User user;
}
