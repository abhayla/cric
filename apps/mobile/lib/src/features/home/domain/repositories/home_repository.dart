import '../entities/match_list_item.dart';

/// Result container for paginated match lists.
class MatchListResult {
  const MatchListResult({
    required this.matches,
    required this.total,
    required this.page,
  });

  final List<MatchListItem> matches;
  final int total;
  final int page;
}

/// Abstract repository interface for home feature.
abstract class HomeRepository {
  /// Get paginated matches with optional status filter.
  /// [scope] controls visibility: 'public' returns all matches, 'user' (default)
  /// returns only matches where the user is scorer or a match player.
  Future<MatchListResult> getMatches({
    String? status,
    int page = 1,
    int limit = 20,
    String? scope,
  });
}
