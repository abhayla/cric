import '../../domain/entities/fixture.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_request.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';
import '../models/fixture_model.dart';
import '../models/standing_model.dart';
import '../models/tournament_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  TournamentRepositoryImpl({required this.remoteDatasource});

  final TournamentRemoteDatasource remoteDatasource;

  @override
  Future<Tournament> createTournament(CreateTournamentInput input) async {
    final data = await remoteDatasource.createTournament(
      name: input.name,
      format: input.format.apiValue,
      oversPerMatch: input.oversPerMatch,
      ballTypeId: input.ballTypeId,
      pointsWin: input.pointsWin,
      pointsTie: input.pointsTie,
      pointsNoResult: input.pointsNoResult,
      pointsLoss: input.pointsLoss,
      numGroups: input.numGroups,
      qualifyPerGroup: input.qualifyPerGroup,
      hasThirdPlaceMatch: input.hasThirdPlaceMatch,
      playersPerSide: input.playersPerSide,
      maxOversPerBowler: input.maxOversPerBowler,
      wideRuns: input.wideRuns,
      noBallRuns: input.noBallRuns,
      powerplayOvers: input.powerplayOvers,
      startDate: input.startDate,
      endDate: input.endDate,
    );
    return TournamentModel.fromJson(data).toEntity();
  }

  @override
  Future<TournamentListResult> getTournaments({
    int page = 1,
    int limit = 20,
    TournamentStatus? status,
  }) async {
    final data = await remoteDatasource.getTournaments(
      page: page,
      limit: limit,
      status: status?.apiValue,
    );
    final models = (data['tournaments'] as List)
        .map((t) => TournamentModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return TournamentListResult(
      tournaments: models.map((m) => m.toEntity()).toList(),
      total: data['total'] as int,
      page: data['page'] as int,
    );
  }

  @override
  Future<Tournament> getTournament(String tournamentId) async {
    final data = await remoteDatasource.getTournament(tournamentId);
    return TournamentModel.fromJson(data).toEntity();
  }

  @override
  Future<Tournament> updateTournament(
    String tournamentId,
    UpdateTournamentInput input,
  ) async {
    final updateData = <String, dynamic>{};
    if (input.name != null) updateData['name'] = input.name;
    if (input.oversPerMatch != null) {
      updateData['oversPerMatch'] = input.oversPerMatch;
    }
    if (input.ballTypeId != null) updateData['ballTypeId'] = input.ballTypeId;
    if (input.pointsWin != null) updateData['pointsWin'] = input.pointsWin;
    if (input.pointsTie != null) updateData['pointsTie'] = input.pointsTie;
    if (input.pointsNoResult != null) {
      updateData['pointsNoResult'] = input.pointsNoResult;
    }
    if (input.pointsLoss != null) updateData['pointsLoss'] = input.pointsLoss;
    if (input.numGroups != null) updateData['numGroups'] = input.numGroups;
    if (input.qualifyPerGroup != null) {
      updateData['qualifyPerGroup'] = input.qualifyPerGroup;
    }
    if (input.hasThirdPlaceMatch != null) {
      updateData['hasThirdPlaceMatch'] = input.hasThirdPlaceMatch;
    }
    if (input.playersPerSide != null) {
      updateData['playersPerSide'] = input.playersPerSide;
    }
    if (input.maxOversPerBowler != null) {
      updateData['maxOversPerBowler'] = input.maxOversPerBowler;
    }
    if (input.wideRuns != null) updateData['wideRuns'] = input.wideRuns;
    if (input.noBallRuns != null) updateData['noBallRuns'] = input.noBallRuns;
    if (input.powerplayOvers != null) {
      updateData['powerplayOvers'] = input.powerplayOvers;
    }
    if (input.startDate != null) updateData['startDate'] = input.startDate;
    if (input.endDate != null) updateData['endDate'] = input.endDate;

    final data = await remoteDatasource.updateTournament(
      tournamentId,
      updateData,
    );
    return TournamentModel.fromJson(data).toEntity();
  }

  @override
  Future<Tournament> transitionStatus(
    String tournamentId,
    TournamentStatus newStatus,
  ) async {
    final data = await remoteDatasource.transitionStatus(
      tournamentId,
      newStatus.apiValue,
    );
    return TournamentModel.fromJson(data).toEntity();
  }

  @override
  Future<TournamentTeam> addTeam(
    String tournamentId, {
    required String teamId,
    String? groupName,
    int? seedNumber,
  }) async {
    final data = await remoteDatasource.addTeam(
      tournamentId,
      teamId: teamId,
      groupName: groupName,
      seedNumber: seedNumber,
    );
    return TournamentTeamModel.fromJson(data).toEntity();
  }

  @override
  Future<TournamentRequest> registerTeam(
    String tournamentId, {
    required String teamId,
  }) async {
    final data = await remoteDatasource.registerTeam(
      tournamentId,
      teamId: teamId,
    );
    return _parseRequest(data);
  }

  @override
  Future<List<TournamentRequest>> getRequests(
    String tournamentId, {
    RequestStatus? status,
  }) async {
    final data = await remoteDatasource.getRequests(
      tournamentId,
      status: status?.apiValue,
    );
    return data.map(_parseRequest).toList();
  }

  @override
  Future<TournamentRequest> resolveRequest(
    String tournamentId,
    String requestId, {
    required RequestStatus status,
    String? groupName,
    int? seedNumber,
    String? rejectionReason,
  }) async {
    final data = await remoteDatasource.resolveRequest(
      tournamentId,
      requestId,
      status: status.apiValue,
      groupName: groupName,
      seedNumber: seedNumber,
      rejectionReason: rejectionReason,
    );
    return _parseRequest(data);
  }

  @override
  Future<void> removeTeam(String tournamentId, String teamId) async {
    await remoteDatasource.removeTeam(tournamentId, teamId);
  }

  @override
  Future<GenerateFixturesResult> generateFixtures(String tournamentId) async {
    final data = await remoteDatasource.generateFixtures(tournamentId);
    final fixtures = (data['fixtures'] as List)
        .map((f) => FixtureModel.fromJson(f as Map<String, dynamic>).toEntity())
        .toList();

    return GenerateFixturesResult(
      fixtures: fixtures,
      totalFixtures: data['totalFixtures'] as int,
    );
  }

  @override
  Future<List<Fixture>> getFixtures(
    String tournamentId, {
    RoundType? roundType,
    String? groupName,
  }) async {
    final data = await remoteDatasource.getFixtures(
      tournamentId,
      roundType: roundType?.apiValue,
      groupName: groupName,
    );
    return (data['fixtures'] as List)
        .map((f) => FixtureModel.fromJson(f as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Fixture> editFixture(
    String tournamentId,
    String fixtureId, {
    String? scheduledDate,
    String? scheduledTime,
    int? estimatedDurationMinutes,
    String? venue,
    String? homeTeamId,
    String? awayTeamId,
  }) async {
    final editData = <String, dynamic>{};
    if (scheduledDate != null) editData['scheduledDate'] = scheduledDate;
    if (scheduledTime != null) editData['scheduledTime'] = scheduledTime;
    if (estimatedDurationMinutes != null) {
      editData['estimatedDurationMinutes'] = estimatedDurationMinutes;
    }
    if (venue != null) editData['venue'] = venue;
    if (homeTeamId != null) editData['homeTeamId'] = homeTeamId;
    if (awayTeamId != null) editData['awayTeamId'] = awayTeamId;

    final data = await remoteDatasource.editFixture(
      tournamentId,
      fixtureId,
      editData,
    );
    return FixtureModel.fromJson(
      data['fixture'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<StandingsResult> getStandings(
    String tournamentId, {
    String? groupName,
  }) async {
    final data = await remoteDatasource.getStandings(
      tournamentId,
      groupName: groupName,
    );
    final standings = (data['standings'] as List)
        .map(
          (s) =>
              StandingModel.fromJson(s as Map<String, dynamic>).toEntity(),
        )
        .toList();

    final groups =
        (data['groups'] as List).map((g) => g as String).toList();

    return StandingsResult(standings: standings, groups: groups);
  }

  @override
  Future<LeaderboardResult> getLeaderboard(
    String tournamentId, {
    required LeaderboardCategory category,
    int limit = 10,
  }) async {
    final data = await remoteDatasource.getLeaderboard(
      tournamentId,
      category: category.apiValue,
      limit: limit,
    );

    final entries = (data['leaderboard'] as List)
        .map((e) => _parseLeaderboardEntry(e as Map<String, dynamic>))
        .toList();

    return LeaderboardResult(
      category: LeaderboardCategory.fromApiValue(data['category'] as String),
      leaderboard: entries,
    );
  }

  // -- Helpers --

  TournamentRequest _parseRequest(Map<String, dynamic> data) {
    return TournamentRequest(
      id: data['id'] as String,
      tournamentId: data['tournamentId'] as String,
      teamId: data['teamId'] as String,
      requestedBy: data['requestedBy'] as String,
      status: RequestStatus.fromApiValue(data['status'] as String),
      requestedAt: data['requestedAt'] != null
          ? DateTime.parse(data['requestedAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      teamName: data['teamName'] as String?,
      teamLocation: data['teamLocation'] as String?,
      rosterCount: data['rosterCount'] as int?,
      requestedByName: data['requestedByName'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.parse(data['resolvedAt'] as String)
          : null,
    );
  }

  LeaderboardEntry _parseLeaderboardEntry(Map<String, dynamic> data) {
    return LeaderboardEntry(
      rank: data['rank'] as int,
      playerId: data['playerId'] as String,
      playerName: data['playerName'] as String,
      teamName: data['teamName'] as String,
      value: (data['value'] as num).toDouble(),
      matches: data['matches'] as int,
      details: data['details'] as Map<String, dynamic>?,
    );
  }
}
