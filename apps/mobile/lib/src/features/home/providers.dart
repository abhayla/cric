import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import 'data/datasources/home_remote_datasource.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';

/// Home remote datasource.
final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(dio: ref.watch(authenticatedDioProvider));
});

/// Home repository.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    remoteDatasource: ref.watch(homeRemoteDatasourceProvider),
  );
});

/// Fetch live matches.
final liveMatchesProvider = FutureProvider<MatchListResult>((ref) {
  final repository = ref.read(homeRepositoryProvider);
  return repository.getMatches(status: 'live');
});

/// Fetch matches filtered by optional status ('live', 'completed', or null for all).
final matchesByStatusProvider =
    FutureProvider.family<MatchListResult, String?>((ref, status) {
  final repository = ref.read(homeRepositoryProvider);
  return repository.getMatches(status: status);
});

/// Fetch recent completed matches (latest 5).
final recentMatchesProvider = FutureProvider<MatchListResult>((ref) {
  final repository = ref.read(homeRepositoryProvider);
  return repository.getMatches(status: 'completed', limit: 5);
});

/// Fetch all matches for match history page.
final allMatchesProvider =
    FutureProvider.family<MatchListResult, int>((ref, page) async {
  final sw = Stopwatch()..start();
  final repository = ref.read(homeRepositoryProvider);
  final result = await repository.getMatches(page: page);
  sw.stop();
  if (kDebugMode) {
    debugPrint('[API-timing] GET /matches (page=$page): ${sw.elapsedMilliseconds}ms');
  }
  return result;
});
