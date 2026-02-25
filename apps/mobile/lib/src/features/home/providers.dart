import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/network/auth_interceptors.dart';
import 'data/datasources/home_remote_datasource.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';

/// Dio instance for home feature.
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  try {
    addAuthInterceptors(dio, ref.read(firebaseAuthDatasourceProvider));
  } catch (_) {
    // Provider not available (e.g., in test environment)
  }

  return dio;
});

/// Home remote datasource.
final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(dio: ref.watch(_dioProvider));
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
    FutureProvider.family<MatchListResult, int>((ref, page) {
  final repository = ref.read(homeRepositoryProvider);
  return repository.getMatches(page: page);
});
