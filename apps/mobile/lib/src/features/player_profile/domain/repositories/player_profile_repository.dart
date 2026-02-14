import '../entities/career_stats.dart';
import '../entities/match_performance.dart';
import '../entities/player_profile.dart';

/// Abstract repository interface for player profile feature.
abstract class PlayerProfileRepository {
  /// Get player profile with team affiliations.
  Future<PlayerProfile> getProfile(String playerId);

  /// Get player career stats for a specific format (or 'all').
  Future<CareerStats?> getStats(String playerId, {String format = 'all'});

  /// Get paginated match history for a player.
  Future<MatchHistoryResult> getMatchHistory(
    String playerId, {
    int page = 1,
    int limit = 20,
    String? format,
    String? result,
  });
}
