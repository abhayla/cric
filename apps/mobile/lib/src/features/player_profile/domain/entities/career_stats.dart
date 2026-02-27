/// Batting career statistics.
class BattingCareerStats {
  const BattingCareerStats({
    required this.matchesPlayed,
    required this.inningsBatted,
    required this.totalRuns,
    required this.highestScore,
    required this.notOuts,
    required this.fifties,
    required this.hundreds,
    required this.fours,
    required this.sixes,
    this.ducks = 0,
    this.battingAverage,
    this.battingStrikeRate,
  });

  final int matchesPlayed;
  final int inningsBatted;
  final int totalRuns;
  final int highestScore;
  final int notOuts;
  final int fifties;
  final int hundreds;
  final int fours;
  final int sixes;
  final int ducks;
  final double? battingAverage;
  final double? battingStrikeRate;

  /// Dismissals = innings - not outs.
  int get dismissals => inningsBatted - notOuts;

  /// Formatted highest score: "75*" if not out, "75" if out.
  /// Note: we don't track if highest was not-out, so just show raw number.
  String get highestScoreDisplay => highestScore.toString();

  /// Formatted average: "45.50" or "-".
  String get averageDisplay =>
      battingAverage != null ? battingAverage!.toStringAsFixed(2) : '-';

  /// Formatted strike rate: "125.00" or "-".
  String get strikeRateDisplay =>
      battingStrikeRate != null ? battingStrikeRate!.toStringAsFixed(2) : '-';
}

/// Bowling career statistics.
class BowlingCareerStats {
  const BowlingCareerStats({
    required this.inningsBowled,
    required this.oversBowled,
    required this.runsConceded,
    required this.wicketsTaken,
    required this.bestBowlingWickets,
    required this.bestBowlingRuns,
    required this.threeWicketHauls,
    required this.fiveWicketHauls,
    this.bowlingAverage,
    this.bowlingEconomy,
    this.bowlingStrikeRate,
  });

  final int inningsBowled;
  final String oversBowled;
  final int runsConceded;
  final int wicketsTaken;
  final int bestBowlingWickets;
  final int bestBowlingRuns;
  final int threeWicketHauls;
  final int fiveWicketHauls;
  final double? bowlingAverage;
  final double? bowlingEconomy;
  final double? bowlingStrikeRate;

  /// Formatted best bowling: "3/20" or "-".
  String get bestBowlingDisplay => bestBowlingWickets > 0
      ? '$bestBowlingWickets/$bestBowlingRuns'
      : '-';

  /// Formatted average: "25.00" or "-".
  String get averageDisplay =>
      bowlingAverage != null ? bowlingAverage!.toStringAsFixed(2) : '-';

  /// Formatted economy: "7.50" or "-".
  String get economyDisplay =>
      bowlingEconomy != null ? bowlingEconomy!.toStringAsFixed(2) : '-';

  /// Formatted strike rate: "18.00" or "-".
  String get strikeRateDisplay =>
      bowlingStrikeRate != null ? bowlingStrikeRate!.toStringAsFixed(2) : '-';
}

/// Fielding career statistics.
class FieldingCareerStats {
  const FieldingCareerStats({
    required this.catches,
    required this.runOuts,
    required this.stumpings,
    this.directHits = 0,
  });

  final int catches;
  final int runOuts;
  final int stumpings;
  final int directHits;

  /// Total dismissals contributed to.
  int get totalDismissals => catches + runOuts + stumpings;
}

/// Combined career stats for a player in a specific format.
class CareerStats {
  const CareerStats({
    required this.format,
    required this.batting,
    required this.bowling,
    required this.fielding,
  });

  final String format;
  final BattingCareerStats batting;
  final BowlingCareerStats bowling;
  final FieldingCareerStats fielding;
}
