import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import 'data/datasources/player_profile_remote_datasource.dart';
import 'data/repositories/player_profile_repository_impl.dart';
import 'domain/entities/career_stats.dart';
import 'domain/entities/match_performance.dart';
import 'domain/entities/player_profile.dart';
import 'domain/repositories/player_profile_repository.dart';

/// Player profile remote datasource.
final playerProfileRemoteDatasourceProvider =
    Provider<PlayerProfileRemoteDatasource>((ref) {
  return PlayerProfileRemoteDatasource(dio: ref.watch(authenticatedDioProvider));
});

/// Player profile repository.
final playerProfileRepositoryProvider =
    Provider<PlayerProfileRepository>((ref) {
  return PlayerProfileRepositoryImpl(
    remoteDatasource: ref.watch(playerProfileRemoteDatasourceProvider),
  );
});

/// Fetch player profile by ID.
final playerProfileProvider =
    FutureProvider.family<PlayerProfile, String>((ref, playerId) {
  final repository = ref.read(playerProfileRepositoryProvider);
  return repository.getProfile(playerId);
});

/// Fetch player career stats (defaults to 'all' format).
final playerStatsProvider =
    FutureProvider.family<CareerStats?, String>((ref, playerId) {
  final repository = ref.read(playerProfileRepositoryProvider);
  return repository.getStats(playerId);
});

/// Fetch player match history.
final playerMatchHistoryProvider =
    FutureProvider.family<MatchHistoryResult, String>((ref, playerId) {
  final repository = ref.read(playerProfileRepositoryProvider);
  return repository.getMatchHistory(playerId);
});
