/// Cumulative player/team stat accumulator for verification.
///
/// Collects per-player batting/bowling stats from match outcomes
/// so the verification layer can compare expected vs actual stats
/// shown on player profile pages.
library;

import '../models/match_outcome.dart';

/// Accumulated stats for a single player across all test matches.
class PlayerCumulativeStats {
  int matchesPlayed = 0;
  int runsScored = 0;
  int ballsFaced = 0;
  int fours = 0;
  int sixes = 0;
  int wicketsTaken = 0;
  int oversBowled = 0;
  int runsConceded = 0;

  @override
  String toString() =>
      'Bat: $runsScored($ballsFaced) 4s:$fours 6s:$sixes | '
      'Bowl: $wicketsTaken/$runsConceded ($oversBowled ov)';
}

/// Accumulates stats from match outcomes for later verification.
class StatTracker {
  final Map<String, PlayerCumulativeStats> _stats = {};

  /// Get or create stats for a player.
  PlayerCumulativeStats _getStats(String playerName) {
    return _stats.putIfAbsent(playerName, () => PlayerCumulativeStats());
  }

  /// Record a match outcome into cumulative stats.
  void recordMatch(MatchOutcome outcome) {
    for (final perf in outcome.performances) {
      final stats = _getStats(perf.playerName);
      stats.matchesPlayed++;
      stats.runsScored += perf.runsScored;
      stats.ballsFaced += perf.ballsFaced;
      stats.fours += perf.fours;
      stats.sixes += perf.sixes;
      stats.wicketsTaken += perf.wicketsTaken;
    }
  }

  /// Get cumulative stats for a player.
  PlayerCumulativeStats? getPlayerStats(String playerName) => _stats[playerName];

  /// Get all tracked players.
  Iterable<String> get trackedPlayers => _stats.keys;

  void printSummary() {
    print('\n=== STAT TRACKER SUMMARY ===');
    for (final entry in _stats.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  }
}
