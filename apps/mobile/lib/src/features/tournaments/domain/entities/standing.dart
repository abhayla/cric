/// Standing entity — a team's position in tournament standings.
class Standing {
  const Standing({
    required this.tournamentId,
    required this.teamId,
    required this.played,
    required this.won,
    required this.lost,
    required this.tied,
    required this.noResult,
    required this.points,
    required this.nrr,
    required this.totalRunsScored,
    required this.totalOversFaced,
    required this.totalRunsConceded,
    required this.totalOversBowled,
    this.groupName,
    this.position,
    this.teamName,
  });

  final String tournamentId;
  final String teamId;
  final int played;
  final int won;
  final int lost;
  final int tied;
  final int noResult;
  final int points;
  final double nrr;
  final int totalRunsScored;
  final double totalOversFaced;
  final int totalRunsConceded;
  final double totalOversBowled;

  // Optional fields
  final String? groupName;
  final int? position;
  final String? teamName;

  /// Whether NRR is positive.
  bool get hasPositiveNrr => nrr > 0;

  /// Formatted NRR string: "+1.250" or "-0.500".
  String get formattedNrr {
    final sign = nrr >= 0 ? '+' : '';
    return '$sign${nrr.toStringAsFixed(3)}';
  }
}
