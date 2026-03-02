import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_datasource.dart';
import '../models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({required this.remoteDatasource});

  final MatchRemoteDatasource remoteDatasource;

  @override
  Future<Match> createMatch(CreateMatchInput input) async {
    final data = await remoteDatasource.createMatch(
      homeTeamId: input.homeTeamId,
      awayTeamId: input.awayTeamId,
      format: input.format.apiValue,
      totalOvers: input.totalOvers,
      ballTypeId: input.ballTypeId,
      matchDate: input.matchDate,
      venue: input.venue,
      playersPerSide: input.playersPerSide,
      maxOversPerBowler: input.maxOversPerBowler,
      wideRuns: input.wideRuns,
      noBallRuns: input.noBallRuns,
      powerplayOvers: input.powerplayOvers,
    );
    return MatchModel.fromJson(data).toEntity();
  }

  @override
  Future<MatchListResult> getMatches({int page = 1, int limit = 20}) async {
    final data = await remoteDatasource.getMatches(page: page, limit: limit);
    final matchModels = (data['matches'] as List)
        .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return MatchListResult(
      matches: matchModels.map((m) => m.toEntity()).toList(),
      total: data['total'] as int,
      page: data['page'] as int,
    );
  }

  @override
  Future<Match> getMatch(String matchId) async {
    final data = await remoteDatasource.getMatch(matchId);
    return MatchModel.fromJson(data).toEntity();
  }

  @override
  Future<List<PlayingXIEntry>> setPlayingXI(
    String matchId,
    SetPlayingXIInput input,
  ) async {
    final data = await remoteDatasource.setPlayingXI(
      matchId,
      teamId: input.teamId,
      playerIds: input.playerIds,
      captainId: input.captainId,
      keeperId: input.keeperId,
    );
    return data
        .map((p) => PlayingXIModel.fromJson(p).toEntity())
        .toList();
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await remoteDatasource.deleteMatch(matchId);
  }

  @override
  Future<Match> recordToss(String matchId, RecordTossInput input) async {
    final data = await remoteDatasource.recordToss(
      matchId,
      winnerId: input.winnerId,
      decision: input.decision.apiValue,
      openingStrikerId: input.openingStrikerId,
      openingNonStrikerId: input.openingNonStrikerId,
      openingBowlerId: input.openingBowlerId,
    );
    return MatchModel.fromJson(data).toEntity();
  }
}
