import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cricscores/src/shared/providers/database_provider.dart';

import '../../app/providers.dart';
import '../../core/network/auth_interceptors.dart';
import 'data/datasources/team_local_datasource.dart';
import 'data/datasources/team_remote_datasource.dart';
import 'data/repositories/team_repository_impl.dart';
import 'domain/repositories/team_repository.dart';

/// Dio instance for teams feature.
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

/// Teams remote datasource.
final teamRemoteDatasourceProvider = Provider<TeamRemoteDatasource>((ref) {
  return TeamRemoteDatasource(dio: ref.watch(_dioProvider));
});

/// Teams local datasource (optional — null if DB not initialized).
final teamLocalDatasourceProvider = Provider<TeamLocalDatasource?>((ref) {
  try {
    final dao = ref.watch(teamsDaoProvider);
    return TeamLocalDatasource(teamsDao: dao);
  } catch (_) {
    // Database not yet initialized
    return null;
  }
});

/// Teams repository.
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(
    remoteDatasource: ref.watch(teamRemoteDatasourceProvider),
    localDatasource: ref.watch(teamLocalDatasourceProvider),
  );
});

/// Team detail state (fetches team + roster by ID).
final teamDetailProvider =
    FutureProvider.family<TeamDetail, String>((ref, teamId) {
  final repository = ref.read(teamRepositoryProvider);
  return repository.getTeam(teamId);
});

/// Teams list state.
final teamsListProvider =
    AsyncNotifierProvider<TeamsListNotifier, TeamListResult>(
  TeamsListNotifier.new,
);

class TeamsListNotifier extends AsyncNotifier<TeamListResult> {
  @override
  Future<TeamListResult> build() async {
    return _fetchTeams();
  }

  Future<TeamListResult> _fetchTeams({int page = 1}) async {
    final repository = ref.read(teamRepositoryProvider);
    return repository.getTeams(page: page);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTeams());
  }
}
