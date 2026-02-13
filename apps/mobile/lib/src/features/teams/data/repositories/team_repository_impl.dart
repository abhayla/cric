import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_local_datasource.dart';
import '../datasources/team_remote_datasource.dart';
import '../models/team_model.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl({
    required this.remoteDatasource,
    this.localDatasource,
  });

  final TeamRemoteDatasource remoteDatasource;
  final TeamLocalDatasource? localDatasource;

  @override
  Future<Team> createTeam({
    required String name,
    String? location,
    String? logoUrl,
  }) async {
    final data = await remoteDatasource.createTeam(
      name: name,
      location: location,
      logoUrl: logoUrl,
    );
    return TeamModel.fromJson(data).toEntity();
  }

  @override
  Future<TeamListResult> getTeams({int page = 1, int limit = 20}) async {
    try {
      final data = await remoteDatasource.getTeams(page: page, limit: limit);
      final teamModels = (data['teams'] as List)
          .map((t) => TeamModel.fromJson(t as Map<String, dynamic>))
          .toList();

      // Cache teams locally
      if (localDatasource != null) {
        await localDatasource!.cacheTeams(
          (data['teams'] as List).cast<Map<String, dynamic>>(),
        );
      }

      return TeamListResult(
        teams: teamModels.map((m) => m.toEntity()).toList(),
        total: data['total'] as int,
        page: data['page'] as int,
      );
    } catch (e) {
      // Fallback to local cache on failure
      if (localDatasource != null) {
        final cachedTeams = await localDatasource!.getCachedTeams();
        if (cachedTeams.isNotEmpty) {
          return TeamListResult(
            teams: cachedTeams,
            total: cachedTeams.length,
            page: 1,
          );
        }
      }
      rethrow;
    }
  }

  @override
  Future<TeamDetail> getTeam(String teamId) async {
    try {
      final data = await remoteDatasource.getTeam(teamId);
      final teamModel = TeamModel.fromJson(data);
      final rosterModels = (data['roster'] as List)
          .map((r) => RosterEntryModel.fromJson(r as Map<String, dynamic>))
          .toList();

      // Cache team detail + roster locally
      if (localDatasource != null) {
        await localDatasource!.cacheTeamDetail(data);
      }

      return TeamDetail(
        team: teamModel.toEntity(),
        roster: rosterModels.map((m) => m.toEntity()).toList(),
      );
    } catch (e) {
      // Fallback to local cache on failure
      if (localDatasource != null) {
        final cached = await localDatasource!.getCachedTeamDetail(teamId);
        if (cached != null) {
          return cached;
        }
      }
      rethrow;
    }
  }

  @override
  Future<Team> updateTeam(
    String teamId, {
    String? name,
    String? location,
    String? logoUrl,
  }) async {
    final data = await remoteDatasource.updateTeam(
      teamId,
      name: name,
      location: location,
      logoUrl: logoUrl,
    );
    return TeamModel.fromJson(data).toEntity();
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await remoteDatasource.deleteTeam(teamId);
  }

  @override
  Future<RosterEntry> addPlayer(
    String teamId, {
    required String playerId,
    int? jerseyNumber,
    String? role,
  }) async {
    final data = await remoteDatasource.addPlayer(
      teamId,
      playerId: playerId,
      jerseyNumber: jerseyNumber,
      role: role,
    );
    return RosterEntryModel.fromJson(data).toEntity();
  }

  @override
  Future<void> removePlayer(String teamId, String playerId) async {
    await remoteDatasource.removePlayer(teamId, playerId);
  }

  @override
  Future<List<PlayerSearchResult>> searchPlayers(
    String query, {
    int limit = 10,
  }) async {
    final data = await remoteDatasource.searchPlayers(query, limit: limit);
    return data
        .map((p) => PlayerSearchResultModel.fromJson(p))
        .map((m) => PlayerSearchResult(
              id: m.id,
              displayName: m.displayName,
              phone: m.phone,
              battingStyle: m.battingStyle,
              bowlingStyle: m.bowlingStyle,
              playerRole: m.playerRole,
              location: m.location,
              avatarUrl: m.avatarUrl,
            ))
        .toList();
  }

  @override
  Future<PlayerSearchResult?> searchPlayerByPhone(String phone) async {
    final data = await remoteDatasource.searchPlayerByPhone(phone);
    if (data == null) return null;
    final m = PlayerSearchResultModel.fromJson(data);
    return PlayerSearchResult(
      id: m.id,
      displayName: m.displayName,
      phone: m.phone,
      battingStyle: m.battingStyle,
      bowlingStyle: m.bowlingStyle,
      playerRole: m.playerRole,
      location: m.location,
      avatarUrl: m.avatarUrl,
    );
  }

  @override
  Future<PlayerSearchResult> createPlayer({
    required String displayName,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    final data = await remoteDatasource.createPlayer(
      displayName: displayName,
      phone: phone,
      playerRole: playerRole,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
    );
    final m = PlayerSearchResultModel.fromJson(data);
    return PlayerSearchResult(
      id: m.id,
      displayName: m.displayName,
      phone: m.phone,
      battingStyle: m.battingStyle,
      bowlingStyle: m.bowlingStyle,
      playerRole: m.playerRole,
      location: m.location,
      avatarUrl: m.avatarUrl,
    );
  }
}
