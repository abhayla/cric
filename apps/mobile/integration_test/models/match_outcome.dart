/// Captures the outcome of a scored match for verification and stat tracking.
library;

/// Per-player performance in a single match.
class PlayerPerformance {
  const PlayerPerformance({
    required this.playerName,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.wicketsTaken = 0,
  });

  final String playerName;
  final int runsScored;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int wicketsTaken;

  @override
  String toString() =>
      '$playerName: $runsScored($ballsFaced) 4s:$fours 6s:$sixes W:$wicketsTaken';
}

/// Full outcome of a completed match.
class MatchOutcome {
  const MatchOutcome({
    required this.homeTeam,
    required this.awayTeam,
    required this.firstInningsRuns,
    required this.firstInningsWickets,
    required this.secondInningsRuns,
    required this.secondInningsWickets,
    this.resultText,
    this.tournamentId,
    this.performances = const [],
  });

  final String homeTeam;
  final String awayTeam;
  final int firstInningsRuns;
  final int firstInningsWickets;
  final int secondInningsRuns;
  final int secondInningsWickets;
  final String? resultText;
  final String? tournamentId;
  final List<PlayerPerformance> performances;

  @override
  String toString() =>
      '$homeTeam vs $awayTeam: $firstInningsRuns/$firstInningsWickets vs '
      '$secondInningsRuns/$secondInningsWickets'
      '${resultText != null ? " — $resultText" : ""}';
}
