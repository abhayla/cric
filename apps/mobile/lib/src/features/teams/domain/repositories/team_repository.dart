import 'package:cricapp/src/features/teams/domain/entities/team.dart';

/// Paginated team list response.
class TeamListResult {
  const TeamListResult({
    required this.teams,
    required this.total,
    required this.page,
  });

  final List<Team> teams;
  final int total;
  final int page;
}

/// Team with full roster.
class TeamDetail {
  const TeamDetail({
    required this.team,
    required this.roster,
  });

  final Team team;
  final List<RosterEntry> roster;
}

/// Search result for a player.
class PlayerSearchResult {
  const PlayerSearchResult({
    required this.id,
    required this.displayName,
    this.phone,
    this.battingStyle,
    this.bowlingStyle,
    this.playerRole,
    this.location,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? phone;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? playerRole;
  final String? location;
  final String? avatarUrl;
}

/// Abstract repository interface for teams feature.
abstract class TeamRepository {
  /// Create a new team.
  Future<Team> createTeam({
    required String name,
    String? location,
    String? logoUrl,
  });

  /// Get paginated list of user's teams.
  Future<TeamListResult> getTeams({int page = 1, int limit = 20});

  /// Get team details with roster.
  Future<TeamDetail> getTeam(String teamId);

  /// Update team info.
  Future<Team> updateTeam(
    String teamId, {
    String? name,
    String? location,
    String? logoUrl,
  });

  /// Soft-delete a team.
  Future<void> deleteTeam(String teamId);

  /// Add player to team roster.
  Future<RosterEntry> addPlayer(
    String teamId, {
    required String playerId,
    int? jerseyNumber,
    String? role,
  });

  /// Remove player from team roster.
  Future<void> removePlayer(String teamId, String playerId);

  /// Search players by name.
  Future<List<PlayerSearchResult>> searchPlayers(String query, {int limit = 10});

  /// Search player by phone number.
  Future<PlayerSearchResult?> searchPlayerByPhone(String phone);

  /// Create a placeholder player profile.
  Future<PlayerSearchResult> createPlayer({
    required String displayName,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  });
}
