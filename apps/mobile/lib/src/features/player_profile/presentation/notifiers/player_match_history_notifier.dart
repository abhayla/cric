import 'package:flutter/foundation.dart';

import '../../domain/entities/match_performance.dart';
import '../../domain/repositories/player_profile_repository.dart';

/// State for the player match history screen.
class PlayerMatchHistoryState {
  const PlayerMatchHistoryState({
    this.matches = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedResult,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<MatchPerformance> matches;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? selectedResult; // null = all, 'won', 'lost', 'tied', 'no_result'
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  PlayerMatchHistoryState copyWith({
    List<MatchPerformance>? matches,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? selectedResult,
    int? total,
    int? page,
    int? limit,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PlayerMatchHistoryState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      selectedResult:
          clearResult ? null : (selectedResult ?? this.selectedResult),
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Notifier for paginated match history with result filtering.
///
/// Used as a plain class with [ChangeNotifier] mixin for widget rebuilds.
class PlayerMatchHistoryNotifier with ChangeNotifier {
  PlayerMatchHistoryNotifier({
    required PlayerProfileRepository repository,
    required String playerId,
  })  : _repository = repository,
        _playerId = playerId;

  final PlayerProfileRepository _repository;
  final String _playerId;

  PlayerMatchHistoryState _state = const PlayerMatchHistoryState();
  PlayerMatchHistoryState get state => _state;

  /// Load the first page of matches.
  Future<void> loadMatches() async {
    _state = _state.copyWith(isLoading: true, clearError: true, page: 1);
    notifyListeners();
    try {
      final result = await _repository.getMatchHistory(
        _playerId,
        page: 1,
        limit: _state.limit,
        result: _state.selectedResult,
      );
      _state = _state.copyWith(
        matches: result.matches,
        total: result.total,
        page: result.page,
        isLoading: false,
      );
      notifyListeners();
    } on Exception catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Load the next page of matches (append).
  Future<void> loadMore() async {
    if (!_state.hasMore || _state.isLoadingMore) return;
    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();
    try {
      final nextPage = _state.page + 1;
      final result = await _repository.getMatchHistory(
        _playerId,
        page: nextPage,
        limit: _state.limit,
        result: _state.selectedResult,
      );
      _state = _state.copyWith(
        matches: [..._state.matches, ...result.matches],
        total: result.total,
        page: result.page,
        isLoadingMore: false,
      );
      notifyListeners();
    } on Exception catch (e) {
      _state = _state.copyWith(isLoadingMore: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Filter by result type. Null = all.
  Future<void> filterByResult(String? result) async {
    if (result == _state.selectedResult) return;
    if (result == null) {
      _state = _state.copyWith(clearResult: true);
    } else {
      _state = _state.copyWith(selectedResult: result);
    }
    await loadMatches();
  }
}
