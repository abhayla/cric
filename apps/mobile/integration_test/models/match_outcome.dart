/// Captures the outcome of a scored match for verification.
library;

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
  });

  final String homeTeam;
  final String awayTeam;
  final int firstInningsRuns;
  final int firstInningsWickets;
  final int secondInningsRuns;
  final int secondInningsWickets;
  final String? resultText;
  final String? tournamentId;

  @override
  String toString() =>
      '$homeTeam vs $awayTeam: $firstInningsRuns/$firstInningsWickets vs '
      '$secondInningsRuns/$secondInningsWickets'
      '${resultText != null ? " — $resultText" : ""}';
}
