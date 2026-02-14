import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/match_remote_datasource.dart';
import 'data/repositories/match_repository_impl.dart';
import 'domain/entities/match.dart';
import 'domain/repositories/match_repository.dart';
import 'presentation/notifiers/match_live_notifier.dart';

/// Dio instance for scoring feature.
final _dioProvider = Provider<Dio>((ref) {
  return Dio();
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

/// Live match viewer state (WebSocket).
final matchLiveNotifierProvider =
    NotifierProvider<MatchLiveNotifier, LiveMatchState>(
  MatchLiveNotifier.new,
);
