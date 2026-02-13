/// Tournament format types — mirrors server-side enum.
enum TournamentFormat {
  roundRobin('Round Robin', 'round_robin'),
  knockout('Knockout', 'knockout'),
  groupKnockout('Group + KO', 'group_knockout');

  const TournamentFormat(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static TournamentFormat fromApiValue(String value) {
    return TournamentFormat.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => throw ArgumentError('Unknown tournament format: $value'),
    );
  }
}

/// Tournament status — mirrors server-side enum.
/// State machine: DRAFT -> REGISTRATION -> LIVE -> COMPLETED
enum TournamentStatus {
  draft('Draft', 'draft'),
  registration('Registration', 'registration'),
  live('Live', 'live'),
  completed('Completed', 'completed');

  const TournamentStatus(this.label, this.apiValue);
  final String label;
  final String apiValue;

  /// Whether the tournament is accepting changes (settings, teams).
  bool get isEditable => this == draft || this == registration;

  /// Whether the tournament has ended.
  bool get isFinished => this == completed;

  /// Whether the tournament has active matches.
  bool get isActive => this == live;

  /// Valid next statuses from current state.
  List<TournamentStatus> get validTransitions {
    switch (this) {
      case draft:
        return [registration];
      case registration:
        return [live];
      case live:
        return [completed];
      case completed:
        return [];
    }
  }

  /// Whether a transition to [target] is valid.
  bool canTransitionTo(TournamentStatus target) =>
      validTransitions.contains(target);

  static TournamentStatus fromApiValue(String value) {
    return TournamentStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => throw ArgumentError('Unknown tournament status: $value'),
    );
  }
}

/// Tournament entity — core domain object for a cricket tournament.
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.oversPerMatch,
    required this.ballTypeId,
    required this.status,
    required this.pointsWin,
    required this.pointsTie,
    required this.pointsNoResult,
    required this.pointsLoss,
    required this.numGroups,
    required this.qualifyPerGroup,
    required this.hasThirdPlaceMatch,
    required this.playersPerSide,
    required this.wideRuns,
    required this.noBallRuns,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.maxOversPerBowler,
    this.powerplayOvers,
    this.startDate,
    this.endDate,
    this.teamCount,
    this.teams,
    this.groups,
  });

  final String id;
  final String name;
  final TournamentFormat format;
  final int oversPerMatch;
  final int ballTypeId;
  final TournamentStatus status;
  final int pointsWin;
  final int pointsTie;
  final int pointsNoResult;
  final int pointsLoss;
  final int numGroups;
  final int qualifyPerGroup;
  final bool hasThirdPlaceMatch;
  final int playersPerSide;
  final int wideRuns;
  final int noBallRuns;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields
  final int? maxOversPerBowler;
  final int? powerplayOvers;
  final String? startDate;
  final String? endDate;
  final int? teamCount;
  final List<TournamentTeam>? teams;
  final List<TournamentGroup>? groups;

  /// Max overs per bowler: provided value or ceil(oversPerMatch/5).
  int get effectiveMaxOversPerBowler =>
      maxOversPerBowler ?? (oversPerMatch / 5).ceil();

  /// Whether the tournament uses group stages.
  bool get hasGroupStage => format == TournamentFormat.groupKnockout;

  /// Whether the tournament uses knockout rounds.
  bool get hasKnockoutStage =>
      format == TournamentFormat.knockout ||
      format == TournamentFormat.groupKnockout;

  /// Whether points system is relevant (not for pure knockout).
  bool get hasPointsSystem => format != TournamentFormat.knockout;

  /// Whether the current user can edit this tournament.
  bool get isEditable => status.isEditable;

  /// Format label including overs: "Round Robin · 20 Overs".
  String get formatLabel => '${format.label} · $oversPerMatch Overs';

  /// Date range string: "1 Mar - 15 Mar 2026" or null.
  String? get dateRange {
    if (startDate == null && endDate == null) return null;
    if (startDate != null && endDate != null) {
      return '$startDate - $endDate';
    }
    return startDate ?? endDate;
  }

  // -- Validation helpers (static, used by UI forms) --

  static String? validateName(String name) {
    if (name.length < 2 || name.length > 100) {
      return 'Name must be between 2 and 100 characters';
    }
    return null;
  }

  static String? validateOvers(int overs) {
    if (overs < 1 || overs > 50) return 'Overs must be between 1 and 50';
    return null;
  }

  static String? validatePlayersPerSide(int players) {
    if (players < 2 || players > 11) {
      return 'Players per side must be between 2 and 11';
    }
    return null;
  }

  static String? validatePoints(int points) {
    if (points < 0 || points > 10) {
      return 'Points must be between 0 and 10';
    }
    return null;
  }

  static String? validateNumGroups(int groups) {
    if (groups < 1 || groups > 8) {
      return 'Number of groups must be between 1 and 8';
    }
    return null;
  }

  static String? validateQualifyPerGroup(int qualify) {
    if (qualify < 1 || qualify > 4) {
      return 'Qualify per group must be between 1 and 4';
    }
    return null;
  }

  static String? validateWideRuns(int runs) {
    if (runs < 1 || runs > 5) return 'Wide runs must be between 1 and 5';
    return null;
  }

  static String? validateNoBallRuns(int runs) {
    if (runs < 1 || runs > 5) return 'No-ball runs must be between 1 and 5';
    return null;
  }

  static String? validatePowerplayOvers(int? powerplay, int totalOvers) {
    if (powerplay == null) return null;
    if (powerplay < 1 || powerplay > totalOvers) {
      return 'Powerplay overs must be between 1 and $totalOvers';
    }
    return null;
  }

  static String? validateMaxOversPerBowler(int? maxOvers, int totalOvers) {
    if (maxOvers == null) return null;
    if (maxOvers < 1 || maxOvers > totalOvers) {
      return 'Max overs per bowler must be between 1 and $totalOvers';
    }
    return null;
  }
}

/// A team entry in a tournament.
class TournamentTeam {
  const TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.joinedAt,
    required this.updatedAt,
    this.groupName,
    this.seedNumber,
    this.teamName,
  });

  final String id;
  final String tournamentId;
  final String teamId;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final String? groupName;
  final int? seedNumber;
  final String? teamName;
}

/// A group definition in a group+knockout tournament.
class TournamentGroup {
  const TournamentGroup({
    required this.name,
    this.teamCount,
  });

  final String name;
  final int? teamCount;
}
