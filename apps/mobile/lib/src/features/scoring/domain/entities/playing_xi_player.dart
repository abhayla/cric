/// A player in the Playing XI roster for the current match.
///
/// Lightweight identity class used by bottom sheets (Select Batter / Select Bowler)
/// to display the full squad. Separate from [BatterInnings] and [BowlerSpell]
/// which track live scoring stats.
class PlayingXIPlayer {
  const PlayingXIPlayer({
    required this.playerId,
    required this.displayName,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.isCaptain = false,
    this.isKeeper = false,
  });

  final String playerId;
  final String displayName;
  final String? playerRole;
  final String? battingStyle;
  final String? bowlingStyle;
  final bool isCaptain;
  final bool isKeeper;

  /// Initials from display name (up to 2 characters).
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Badge text: "(C)", "(WK)", "(C & WK)", or null.
  String? get badge {
    if (isCaptain && isKeeper) return '(C & WK)';
    if (isCaptain) return '(C)';
    if (isKeeper) return '(WK)';
    return null;
  }

  /// Short batting style label (e.g. "RHB", "LHB").
  String? get battingStyleShort => battingStyle;

  /// Formatted role label from snake_case role string.
  ///
  /// "batter" → "Batter"
  /// "wicketkeeper_batter" → "WK Batter"
  /// "all_rounder" → "All Rounder"
  String? get roleLabel {
    if (playerRole == null) return null;
    if (playerRole == 'wicketkeeper_batter') return 'WK Batter';
    return playerRole!
        .split('_')
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
