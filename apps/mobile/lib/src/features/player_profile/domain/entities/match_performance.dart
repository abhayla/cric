/// A team's score in a match innings.
class TeamScore {
  const TeamScore({
    required this.teamId,
    required this.teamName,
    required this.runs,
    required this.wickets,
    required this.overs,
  });

  final String teamId;
  final String teamName;
  final int runs;
  final int wickets;
  final String overs;

  /// Formatted score: "150/5 (20.0)"
  String get scoreDisplay => '$runs/$wickets ($overs)';
}

/// Match result summary.
class MatchResultSummary {
  const MatchResultSummary({
    required this.resultType,
    required this.summary,
    this.winnerTeamId,
    this.margin,
  });

  final String resultType;
  final String summary;
  final String? winnerTeamId;
  final int? margin;
}

/// Personal batting performance in a match.
class PersonalBatting {
  const PersonalBatting({
    required this.runsScored,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.isNotOut,
    this.strikeRate,
  });

  final int runsScored;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isNotOut;
  final double? strikeRate;

  /// Formatted score: "75* (45)" or "30 (20)".
  String get scoreDisplay {
    final notOutMarker = isNotOut ? '*' : '';
    return '$runsScored$notOutMarker ($ballsFaced)';
  }
}

/// Personal bowling performance in a match.
class PersonalBowling {
  const PersonalBowling({
    required this.oversBowled,
    required this.runsConceded,
    required this.wicketsTaken,
    required this.maidens,
    this.economyRate,
  });

  final String oversBowled;
  final int runsConceded;
  final int wicketsTaken;
  final int maidens;
  final double? economyRate;

  /// Formatted bowling: "2/25 (4.0)".
  String get figuresDisplay => '$wicketsTaken/$runsConceded ($oversBowled)';
}

/// Personal fielding performance in a match.
class PersonalFielding {
  const PersonalFielding({
    required this.catches,
    required this.runOuts,
    required this.stumpings,
  });

  final int catches;
  final int runOuts;
  final int stumpings;

  /// Whether there were any fielding contributions.
  bool get hasContributions => catches > 0 || runOuts > 0 || stumpings > 0;
}

/// Team info for match display.
class MatchTeamInfo {
  const MatchTeamInfo({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;

  /// First letter of team name for avatar fallback.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// A single match performance entry in player's match history.
class MatchPerformance {
  const MatchPerformance({
    required this.matchId,
    required this.format,
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    required this.teamScores,
    required this.playerResult,
    required this.playerTeamId,
    this.venue,
    this.result,
    this.batting,
    this.bowling,
    this.fielding,
  });

  final String matchId;
  final String format;
  final String matchDate;
  final String? venue;
  final MatchTeamInfo homeTeam;
  final MatchTeamInfo awayTeam;
  final List<TeamScore> teamScores;
  final MatchResultSummary? result;
  final String playerResult; // 'won', 'lost', 'tied', 'no_result'
  final String playerTeamId;
  final PersonalBatting? batting;
  final PersonalBowling? bowling;
  final PersonalFielding? fielding;

  /// Whether the player won this match.
  bool get isWon => playerResult == 'won';

  /// Whether the player lost this match.
  bool get isLost => playerResult == 'lost';

  /// Opponent team (the team the player didn't play for).
  MatchTeamInfo get opponentTeam =>
      playerTeamId == homeTeam.id ? awayTeam : homeTeam;
}

/// Paginated match history result.
class MatchHistoryResult {
  const MatchHistoryResult({
    required this.matches,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<MatchPerformance> matches;
  final int total;
  final int page;
  final int limit;

  /// Whether there are more pages.
  bool get hasMore => page * limit < total;
}
