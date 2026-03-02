import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/auth_interceptors.dart';

import '../../shared/data/sync/sync_service.dart';
import '../../shared/providers/database_provider.dart';
import 'data/datasources/match_remote_datasource.dart';
import 'data/datasources/scoring_local_datasource.dart';
import 'data/repositories/match_repository_impl.dart';
import 'domain/entities/match.dart';
import 'domain/repositories/match_repository.dart';
import 'presentation/notifiers/match_live_notifier.dart';

/// Dio instance for scoring feature.
///
/// Uses the server root as baseUrl so that both absolute URLs
/// (used by datasources: `${AppConstants.apiBaseUrl}/matches`)
/// and relative paths (used by SyncService: `/api/v1/matches/...`)
/// resolve correctly.
final _dioProvider = Provider<Dio>((ref) {
  // Extract server root from apiBaseUrl (strip /api/v1 suffix)
  const apiBase = AppConstants.apiBaseUrl; // e.g. http://10.0.2.2:3001/api/v1
  final serverRoot = apiBase.replaceAll(RegExp(r'/api/v\d+$'), '');
  final dio = Dio(BaseOptions(
    baseUrl: serverRoot,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  try {
    addAuthInterceptors(dio, ref.read(firebaseAuthDatasourceProvider));
  } catch (_) {
    // Provider not available (e.g., in test environment)
  }

  return dio;
});

/// Scoring local datasource for persistence.
final scoringLocalDatasourceProvider =
    Provider<ScoringLocalDatasource>((ref) {
  return ScoringLocalDatasource(scoringDao: ref.watch(scoringDaoProvider));
});

/// Match remote datasource.
final matchRemoteDatasourceProvider = Provider<MatchRemoteDatasource>((ref) {
  return MatchRemoteDatasource(dio: ref.watch(_dioProvider));
});

/// Match repository.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl(
    remoteDatasource: ref.watch(matchRemoteDatasourceProvider),
  );
});

/// Match detail state (fetches match by ID).
final matchDetailProvider =
    FutureProvider.family<Match, String>((ref, matchId) {
  final repository = ref.read(matchRepositoryProvider);
  return repository.getMatch(matchId);
});

/// Matches list state.
final matchesListProvider =
    AsyncNotifierProvider<MatchesListNotifier, MatchListResult>(
  MatchesListNotifier.new,
);

class MatchesListNotifier extends AsyncNotifier<MatchListResult> {
  @override
  Future<MatchListResult> build() async {
    return _fetchMatches();
  }

  Future<MatchListResult> _fetchMatches({int page = 1}) async {
    final repository = ref.read(matchRepositoryProvider);
    return repository.getMatches(page: page);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMatches());
  }
}

/// Match IDs that have active Drift snapshots (crash recovery candidates).
final resumableMatchIdsProvider = FutureProvider<List<String>>((ref) async {
  final datasource = ref.read(scoringLocalDatasourceProvider);
  return datasource.getResumableMatchIds();
});

/// Live match viewer state (WebSocket).
final matchLiveNotifierProvider =
    NotifierProvider<MatchLiveNotifier, LiveMatchState>(
  MatchLiveNotifier.new,
);

/// Sync service for pushing deliveries to the server.
final syncServiceProvider = Provider<SyncService>((ref) {
  final dao = ref.watch(scoringDaoProvider);
  final dio = ref.watch(_dioProvider);
  return SyncService(scoringDao: dao, dio: dio);
});
