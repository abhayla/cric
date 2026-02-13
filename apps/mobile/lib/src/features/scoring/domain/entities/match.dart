/// Match status — mirrors server-side enum.
/// State machine: SETUP → TOSS → LIVE → INNINGS_BREAK → LIVE → COMPLETED
/// ABANDONED can occur from any state.
enum MatchStatus {
  setup('Setup', 'setup'),
  toss('Toss', 'toss'),
  live('Live', 'live'),
  inningsBreak('Innings Break', 'innings_break'),
  completed('Completed', 'completed'),
  abandoned('Abandoned', 'abandoned');

  const MatchStatus(this.label, this.apiValue);
  final String label;
  final String apiValue;

  /// Whether the match is actively in play.
  bool get isActive => this == live || this == inningsBreak;

  /// Whether the match has ended.
  bool get isFinished => this == completed || this == abandoned;

  static MatchStatus fromApiValue(String value) {
    return MatchStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => throw ArgumentError('Unknown match status: $value'),
    );
  }
}

/// Toss decision.
/// Note: API uses "bowl" but UI displays "Field" per cricket convention.
enum TossDecision {
  bat('Bat', 'bat'),
  field('Field', 'bowl');

  const TossDecision(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static TossDecision fromApiValue(String value) {
    return TossDecision.values.firstWhere(
      (d) => d.apiValue == value,
      orElse: () => throw ArgumentError('Unknown toss decision: $value'),
    );
  }
}

/// Match format.
enum MatchFormat {
  t20('T20', 'T20', 20),
  odi('ODI', 'ODI', 50),
  test('Test', 'test', null),
  custom('Custom', 'custom', null);

  const MatchFormat(this.label, this.apiValue, this.defaultOvers);
  final String label;
  final String apiValue;
  final int? defaultOvers;

  static MatchFormat fromApiValue(String value) {
    return MatchFormat.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => MatchFormat.custom,
    );
  }
}

/// Match entity — core domain object for a cricket match.
class Match {
  const Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.format,
    required this.totalOvers,
    required this.ballTypeId,
    required this.status,
    required this.playersPerSide,
    required this.wideRuns,
    required this.noBallRuns,
    required this.scorerId,
    required this.createdBy,
    required this.matchDate,
    required this.createdAt,
    required this.updatedAt,
    this.homeTeamName,
    this.awayTeamName,
    this.venue,
    this.tossWinnerId,
    this.tossDecision,
    this.maxOversPerBowler,
    this.powerplayOvers,
    this.tournamentId,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final MatchFormat format;
  final int totalOvers;
  final int ballTypeId;
  final MatchStatus status;
  final int playersPerSide;
  final int wideRuns;
  final int noBallRuns;
  final String scorerId;
  final String createdBy;
  final String matchDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields
  final String? homeTeamName;
  final String? awayTeamName;
  final String? venue;
  final String? tossWinnerId;
  final TossDecision? tossDecision;
  final int? maxOversPerBowler;
  final int? powerplayOvers;
  final String? tournamentId;

  /// Match title: "Home vs Away" or fallback "Match".
  String get title {
    if (homeTeamName != null && awayTeamName != null) {
      return '$homeTeamName vs $awayTeamName';
    }
    return 'Match';
  }

  /// Max overs per bowler: provided value or ceil(totalOvers/5).
  int get effectiveMaxOversPerBowler =>
      maxOversPerBowler ?? (totalOvers / 5).ceil();

  /// Whether this match belongs to a tournament.
  bool get isTournamentMatch => tournamentId != null;

  /// Whether the match is currently live.
  bool get isLive => status == MatchStatus.live;

  /// Whether the match is completed.
  bool get isCompleted => status == MatchStatus.completed;

  /// Human-readable format label.
  /// For standard formats (T20, ODI), returns the format name.
  /// For custom, returns "X Overs".
  String get formatLabel {
    if (format == MatchFormat.custom) return '$totalOvers Overs';
    return format.label;
  }

  // -- Validation helpers (static, used by UI forms) --

  /// Returns null if valid, error message if invalid.
  static String? validateOvers(int overs) {
    if (overs < 1 || overs > 50) return 'Overs must be between 1 and 50';
    return null;
  }

  /// Returns null if valid, error message if invalid.
  static String? validatePlayersPerSide(int players) {
    if (players < 2 || players > 11) {
      return 'Players per side must be between 2 and 11';
    }
    return null;
  }

  /// Returns null if valid, error message if invalid.
  static String? validateTeams(String homeTeamId, String awayTeamId) {
    if (homeTeamId == awayTeamId) {
      return 'Home and away teams must be different';
    }
    return null;
  }
}

/// A player entry in the Playing XI for a match.
class PlayingXIEntry {
  const PlayingXIEntry({
    required this.playerId,
    required this.displayName,
    required this.isCaptain,
    required this.isKeeper,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.battingOrder,
  });

  final String playerId;
  final String displayName;
  final bool isCaptain;
  final bool isKeeper;
  final String? playerRole;
  final String? battingStyle;
  final String? bowlingStyle;
  final int? battingOrder;

  /// Badge text: "(C)", "(WK)", "(C & WK)", or null.
  String? get badge {
    if (isCaptain && isKeeper) return '(C & WK)';
    if (isCaptain) return '(C)';
    if (isKeeper) return '(WK)';
    return null;
  }
}
