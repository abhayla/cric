import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import 'data/datasources/tournament_remote_datasource.dart';
import 'data/repositories/tournament_repository_impl.dart';
import 'domain/entities/fixture.dart';
import 'domain/entities/tournament.dart';
import 'domain/repositories/tournament_repository.dart';

/// Tournaments remote datasource.
final tournamentRemoteDatasourceProvider =
    Provider<TournamentRemoteDatasource>((ref) {
  return TournamentRemoteDatasource(dio: ref.watch(authenticatedDioProvider));
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
    final sw = Stopwatch()..start();
    final repository = ref.read(tournamentRepositoryProvider);
    final result = repository.getTournaments(page: page);
    result.then((_) {
      sw.stop();
      if (kDebugMode) {
        debugPrint('[API-timing] GET /tournaments: ${sw.elapsedMilliseconds}ms');
      }
    });
    return result;
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
