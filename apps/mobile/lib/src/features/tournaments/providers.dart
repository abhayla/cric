import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'data/datasources/tournament_remote_datasource.dart';
import 'data/repositories/tournament_repository_impl.dart';
import 'domain/entities/fixture.dart';
import 'domain/entities/standing.dart';
import 'domain/entities/tournament.dart';
import 'domain/repositories/tournament_repository.dart';

/// Dio instance for tournaments feature.
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  try {
    final authDatasource = ref.read(firebaseAuthDatasourceProvider);
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await authDatasource.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Silently continue without auth
        }
        handler.next(options);
      },
    ));
  } catch (_) {
    // Provider not available (e.g., in test environment)
  }

  return dio;
});

/// Tournaments remote datasource.
final tournamentRemoteDatasourceProvider =
    Provider<TournamentRemoteDatasource>((ref) {
  return TournamentRemoteDatasource(dio: ref.watch(_dioProvider));
});

/// Tournaments repository.
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepositoryImpl(
    remoteDatasource: ref.watch(tournamentRemoteDatasourceProvider),
  );
});

/// Tournament detail state (fetches tournament by ID).
final tournamentDetailProvider =
    FutureProvider.family<Tournament, String>((ref, tournamentId) {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getTournament(tournamentId);
});

/// Tournaments list state.
final tournamentsListProvider =
    AsyncNotifierProvider<TournamentsListNotifier, TournamentListResult>(
  TournamentsListNotifier.new,
);

class TournamentsListNotifier extends AsyncNotifier<TournamentListResult> {
  @override
  Future<TournamentListResult> build() async {
    return _fetchTournaments();
  }

  Future<TournamentListResult> _fetchTournaments({int page = 1}) async {
    final repository = ref.read(tournamentRepositoryProvider);
    return repository.getTournaments(page: page);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTournaments());
  }
}

/// Tournament fixtures state.
final tournamentFixturesProvider =
    FutureProvider.family<List<Fixture>, String>((ref, tournamentId) {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getFixtures(tournamentId);
});

/// Tournament standings state.
final tournamentStandingsProvider =
    FutureProvider.family<StandingsResult, String>((ref, tournamentId) {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getStandings(tournamentId);
});

/// Tournament leaderboard state.
final tournamentLeaderboardProvider = FutureProvider.family<LeaderboardResult,
    ({String tournamentId, LeaderboardCategory category})>((ref, params) {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getLeaderboard(
    params.tournamentId,
    category: params.category,
  );
});
