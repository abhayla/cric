import '../../domain/entities/career_stats.dart';
import '../../domain/entities/match_performance.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/repositories/player_profile_repository.dart';
import '../datasources/player_profile_remote_datasource.dart';
import '../models/career_stats_model.dart';
import '../models/match_performance_model.dart';
import '../models/player_profile_model.dart';

class PlayerProfileRepositoryImpl implements PlayerProfileRepository {
  PlayerProfileRepositoryImpl({required this.remoteDatasource});

  final PlayerProfileRemoteDatasource remoteDatasource;

  @override
  Future<PlayerProfile> getProfile(String playerId) async {
    final data = await remoteDatasource.getProfile(playerId);
    final model = PlayerProfileModel.fromJson(data);
    return model.toEntity();
  }

  @override
  Future<CareerStats?> getStats(
    String playerId, {
    String format = 'all',
  }) async {
    final data = await remoteDatasource.getStats(playerId, format: format);
    if (data == null) return null;
    final model = CareerStatsModel.fromJson({...data, 'format': format});
    return model.toEntity();
  }

  @override
  Future<MatchHistoryResult> getMatchHistory(
    String playerId, {
    int page = 1,
    int limit = 20,
    String? format,
    String? result,
  }) async {
    final data = await remoteDatasource.getMatchHistory(
      playerId,
      page: page,
      limit: limit,
      format: format,
      result: result,
    );

    final matchModels = (data['matches'] as List)
        .map((m) => MatchPerformanceModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return MatchHistoryResult(
      matches: matchModels.map((m) => m.toEntity()).toList(),
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
    );
  }
}
