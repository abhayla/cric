/// Round type for tournament fixtures — mirrors server-side enum.
enum RoundType {
  group('Group', 'group'),
  quarterFinal('Quarter Final', 'quarter_final'),
  semiFinal('Semi Final', 'semi_final'),
  final_('Final', 'final'),
  thirdPlace('3rd Place', 'third_place');

  const RoundType(this.label, this.apiValue);
  final String label;
  final String apiValue;

  /// Whether this is a knockout round (not group stage).
  bool get isKnockout => this != group;

  static RoundType fromApiValue(String value) {
    return RoundType.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => throw ArgumentError('Unknown round type: $value'),
    );
  }
}

/// Fixture entity — a scheduled match within a tournament.
class Fixture {
  const Fixture({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.roundType,
    required this.fixtureOrder,
    required this.homeTeamId,
    required this.awayTeamId,
    this.matchId,
    this.groupName,
    this.homeTeamName,
    this.awayTeamName,
    this.scheduledDate,
    this.scheduledTime,
    this.estimatedDurationMinutes,
    this.venue,
    this.result,
  });

  final String id;
  final String tournamentId;
  final int roundNumber;
  final RoundType roundType;
  final int fixtureOrder;
  final String homeTeamId;
  final String awayTeamId;

  // Optional fields
  final String? matchId;
  final String? groupName;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? scheduledDate;
  final String? scheduledTime;
  final int? estimatedDurationMinutes;
  final String? venue;
  final FixtureResult? result;

  /// Whether this fixture has an associated match (started).
  bool get hasMatch => matchId != null;

  /// Whether this fixture has been completed.
  bool get isCompleted => result != null;

  /// Match title: "Home vs Away" or "TBD vs TBD".
  String get title {
    final home = homeTeamName ?? 'TBD';
    final away = awayTeamName ?? 'TBD';
    return '$home vs $away';
  }

  /// Schedule description: "1 Mar 2026, 2:30 PM" or "TBD".
  String? get scheduleDescription {
    if (scheduledDate == null) return null;
    if (scheduledTime != null) {
      return '$scheduledDate at $scheduledTime';
    }
    return scheduledDate;
  }
}

/// Result of a completed fixture.
class FixtureResult {
  const FixtureResult({
    required this.winner,
    required this.summary,
  });

  final String winner;
  final String summary;
}
