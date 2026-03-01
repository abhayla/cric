import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';

/// Ball type enum — mirrors server seed data (ball_types table).
enum BallType {
  leather(1, 'Leather'),
  tennis(2, 'Tennis'),
  tape(3, 'Tape'),
  other(4, 'Other');

  const BallType(this.id, this.label);
  final int id;
  final String label;
}

/// Form state for the Match Setup page.
class MatchSetupState {
  MatchSetupState({
    this.homeTeamId,
    this.homeTeamName,
    this.awayTeamId,
    this.awayTeamName,
    this.totalOvers = 20,
    this.playersPerSide = 11,
    this.ballTypeId = 1,
    String? matchDate,
    this.venue,
    this.wideRuns = 1,
    this.noBallRuns = 1,
    this.maxOversPerBowler,
    this.powerplayOvers,
    this.magicOverEnabled = false,
    this.magicOverNumbers = const [],
    this.magicOverRunMultiplier = 2,
    this.magicOverWicketPenalty = -5,
    this.isAdvancedOpen = false,
    this.isSubmitting = false,
    this.error,
    this.isKnockoutMatch = false,
  }) : matchDate = matchDate ?? _todayFormatted();

  final String? homeTeamId;
  final String? homeTeamName;
  final String? awayTeamId;
  final String? awayTeamName;
  final int totalOvers;
  final int playersPerSide;
  final int ballTypeId;
  final String matchDate;
  final String? venue;
  final int wideRuns;
  final int noBallRuns;
  final int? maxOversPerBowler;
  final int? powerplayOvers;
  final bool magicOverEnabled;
  final List<int> magicOverNumbers;
  final int magicOverRunMultiplier;
  final int magicOverWicketPenalty;
  final bool isAdvancedOpen;
  final bool isSubmitting;
  final String? error;
  final bool isKnockoutMatch;

  /// Today's date in yyyy-MM-dd format.
  static String _todayFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Whether both different teams are selected and format is valid.
  bool get isValid {
    if (homeTeamId == null || awayTeamId == null) return false;
    if (homeTeamId == awayTeamId) return false;
    if (totalOvers < 1 || totalOvers > 50) return false;
    if (playersPerSide < 2 || playersPerSide > 11) return false;
    if (magicOverEnabled && magicOverNumbers.isEmpty) return false;
    return true;
  }

  /// Error message for magic over selection.
  String? get magicOverError {
    if (magicOverEnabled && magicOverNumbers.isEmpty) {
      return 'Select at least one magic over';
    }
    return null;
  }

  /// Error message for team selection.
  String? get teamsError {
    if (homeTeamId != null &&
        awayTeamId != null &&
        homeTeamId == awayTeamId) {
      return 'Home and away teams must be different';
    }
    return null;
  }

  /// Error message for overs.
  String? get oversError {
    if (totalOvers < 1 || totalOvers > 50) {
      return 'Overs must be between 1 and 50';
    }
    return null;
  }

  /// Error message for players per side.
  String? get playersError {
    if (playersPerSide < 2 || playersPerSide > 11) {
      return 'Players per side must be between 2 and 11';
    }
    return null;
  }

  /// Detect match format from overs count.
  MatchFormat get detectedFormat {
    if (totalOvers == 20) return MatchFormat.t20;
    if (totalOvers == 50) return MatchFormat.odi;
    return MatchFormat.custom;
  }

  /// Convert state to CreateMatchInput for API submission.
  CreateMatchInput toCreateMatchInput() {
    return CreateMatchInput(
      homeTeamId: homeTeamId!,
      awayTeamId: awayTeamId!,
      format: detectedFormat,
      totalOvers: totalOvers,
      ballTypeId: ballTypeId,
      matchDate: matchDate,
      venue: venue,
      playersPerSide: playersPerSide,
      wideRuns: wideRuns,
      noBallRuns: noBallRuns,
      maxOversPerBowler: maxOversPerBowler,
      powerplayOvers: powerplayOvers,
      magicOverNumbers: magicOverEnabled ? magicOverNumbers : null,
      magicOverRunMultiplier: magicOverEnabled ? magicOverRunMultiplier : null,
      magicOverWicketPenalty: magicOverEnabled ? magicOverWicketPenalty : null,
    );
  }

  /// Create a copy with updated fields.
  MatchSetupState copyWith({
    String? homeTeamId,
    String? homeTeamName,
    String? awayTeamId,
    String? awayTeamName,
    int? totalOvers,
    int? playersPerSide,
    int? ballTypeId,
    String? matchDate,
    String? venue,
    int? wideRuns,
    int? noBallRuns,
    int? maxOversPerBowler,
    int? powerplayOvers,
    bool? magicOverEnabled,
    List<int>? magicOverNumbers,
    int? magicOverRunMultiplier,
    int? magicOverWicketPenalty,
    bool? isAdvancedOpen,
    bool? isSubmitting,
    String? error,
    bool? isKnockoutMatch,
  }) {
    return MatchSetupState(
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      totalOvers: totalOvers ?? this.totalOvers,
      playersPerSide: playersPerSide ?? this.playersPerSide,
      ballTypeId: ballTypeId ?? this.ballTypeId,
      matchDate: matchDate ?? this.matchDate,
      venue: venue ?? this.venue,
      wideRuns: wideRuns ?? this.wideRuns,
      noBallRuns: noBallRuns ?? this.noBallRuns,
      maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
      powerplayOvers: powerplayOvers ?? this.powerplayOvers,
      magicOverEnabled: magicOverEnabled ?? this.magicOverEnabled,
      magicOverNumbers: magicOverNumbers ?? this.magicOverNumbers,
      magicOverRunMultiplier: magicOverRunMultiplier ?? this.magicOverRunMultiplier,
      magicOverWicketPenalty: magicOverWicketPenalty ?? this.magicOverWicketPenalty,
      isAdvancedOpen: isAdvancedOpen ?? this.isAdvancedOpen,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      isKnockoutMatch: isKnockoutMatch ?? this.isKnockoutMatch,
    );
  }
}
