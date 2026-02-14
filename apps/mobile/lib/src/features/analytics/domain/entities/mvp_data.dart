// MVP (Most Valuable Player) data classes.
// Point system from SCORING_RULES.md Section 5.

/// A single player's MVP score breakdown.
class MvpPlayerScore {
  const MvpPlayerScore({
    required this.playerId,
    required this.displayName,
    required this.teamName,
    required this.teamId,
    required this.battingPoints,
    required this.bowlingPoints,
    required this.fieldingPoints,
    required this.totalPoints,
    required this.performanceSummary,
  });

  final String playerId;
  final String displayName;
  final String teamName;
  final String teamId;
  final double battingPoints;
  final double bowlingPoints;
  final double fieldingPoints;
  final double totalPoints;

  /// Human-readable summary, e.g. "54(38), 2/28, 1 ct".
  final String performanceSummary;
}

/// MVP rankings for a complete match.
class MatchMvpData {
  const MatchMvpData({required this.rankings});

  /// Players sorted descending by [MvpPlayerScore.totalPoints].
  final List<MvpPlayerScore> rankings;
}
