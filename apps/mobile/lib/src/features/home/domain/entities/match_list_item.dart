/// Lightweight match data for list cards (not the full scoring entity).
class MatchListItem {
  MatchListItem({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.format,
    required this.totalOvers,
    required this.status,
    required this.matchDate,
    this.venue,
    this.currentInnings,
    this.firstInnings,
    this.secondInnings,
    this.result,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final String format;
  final int totalOvers;
  final String status;
  final String matchDate;
  final String? venue;
  final InningsSnapshot? currentInnings;
  final InningsSnapshot? firstInnings;
  final InningsSnapshot? secondInnings;
  final String? result;

  String get title => '$homeTeamName vs $awayTeamName';

  bool get isLive => status == 'live' || status == 'innings_break';

  bool get isCompleted => status == 'completed';
}

/// Current innings snapshot for match cards.
class InningsSnapshot {
  const InningsSnapshot({
    required this.battingTeamId,
    required this.totalRuns,
    required this.totalWickets,
    required this.overs,
  });

  final String battingTeamId;
  final int totalRuns;
  final int totalWickets;
  final String overs;

  String get scoreDisplay => '$totalRuns/$totalWickets';
}
