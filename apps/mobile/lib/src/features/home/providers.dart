import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/home_remote_datasource.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';

/// Dio instance for home feature.
final _dioProvider = Provider<Dio>((ref) {
  return Dio();
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
