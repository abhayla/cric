import '../../presentation/notifiers/scoring_notifier.dart';
import 'innings_data.dart';

/// Container for both innings data and match result — the complete scorecard.
///
/// Created after match completion, holds everything the ScorecardPage needs.
class ScorecardData {
  const ScorecardData({
    required this.matchId,
    required this.totalOvers,
    required this.playersPerSide,
    required this.firstInnings,
    required this.secondInnings,
    required this.matchResult,
    this.magicOverRunMultiplier = 1,
  });

  final String matchId;
  final int totalOvers;
  final int playersPerSide;
  final InningsData firstInnings;
  final InningsData secondInnings;
  final MatchResult matchResult;
  final int magicOverRunMultiplier;

  /// Create from the scoring state at match completion.
  ///
  /// Requires: match is complete, firstInnings data is available in state,
  /// and matchResult is computed.
  factory ScorecardData.fromScoringState(ScoringState state) {
    assert(state.isMatchComplete, 'Match must be complete to create ScorecardData');
    assert(state.firstInnings != null, 'First innings data must be available');
    assert(state.matchResult != null, 'Match result must be computed');

    return ScorecardData(
      matchId: state.matchId,
      totalOvers: state.totalOvers,
      playersPerSide: state.playersPerSide,
      firstInnings: state.firstInnings!,
      secondInnings: InningsData.fromScoringState(state),
      matchResult: state.matchResult!,
      magicOverRunMultiplier: state.magicOverRunMultiplier,
    );
  }
}
