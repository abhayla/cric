import 'package:flutter/foundation.dart';

import '../../domain/entities/career_stats.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/repositories/player_profile_repository.dart';

/// State for the player profile screen.
class PlayerProfileState {
  const PlayerProfileState({
    this.profile,
    this.stats,
    this.isLoading = false,
    this.isStatsLoading = false,
    this.error,
    this.selectedFormat = 'all',
  });

  final PlayerProfile? profile;
  final CareerStats? stats;
  final bool isLoading;
  final bool isStatsLoading;
  final String? error;
  final String selectedFormat;

  PlayerProfileState copyWith({
    PlayerProfile? profile,
    CareerStats? stats,
    bool? isLoading,
    bool? isStatsLoading,
    String? error,
    String? selectedFormat,
    bool clearError = false,
    bool clearStats = false,
  }) {
    return PlayerProfileState(
      profile: profile ?? this.profile,
      stats: clearStats ? null : (stats ?? this.stats),
      isLoading: isLoading ?? this.isLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      error: clearError ? null : (error ?? this.error),
      selectedFormat: selectedFormat ?? this.selectedFormat,
    );
  }
}

/// Notifier for loading player profile and career stats.
///
/// Used as a plain class — not a Riverpod provider type.
/// Extend [ChangeNotifier] from Flutter foundation for widget rebuilds.
class PlayerProfileNotifier with ChangeNotifier {
  PlayerProfileNotifier({
    required PlayerProfileRepository repository,
    required String playerId,
  })  : _repository = repository,
        _playerId = playerId;

  final PlayerProfileRepository _repository;
  final String _playerId;

  PlayerProfileState _state = const PlayerProfileState();
  PlayerProfileState get state => _state;

  /// Load player profile and initial stats.
  Future<void> loadProfile() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();
    try {
      final profile = await _repository.getProfile(_playerId);
      _state = _state.copyWith(profile: profile, isLoading: false);
      notifyListeners();
      await loadStats(_state.selectedFormat);
    } on Exception catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Load career stats for the selected format.
  Future<void> loadStats(String format) async {
    _state = _state.copyWith(
      isStatsLoading: true,
      selectedFormat: format,
      clearError: true,
    );
    notifyListeners();
    try {
      final stats = await _repository.getStats(_playerId, format: format);
      _state = _state.copyWith(stats: stats, isStatsLoading: false);
      notifyListeners();
    } on Exception catch (e) {
      _state = _state.copyWith(isStatsLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Switch format and reload stats.
  Future<void> switchFormat(String format) async {
    if (format == _state.selectedFormat) return;
    await loadStats(format);
  }
}
