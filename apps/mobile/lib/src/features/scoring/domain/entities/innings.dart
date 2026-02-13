import '../../../../core/utils/cricket_utils.dart';
import 'delivery.dart';

/// Innings entity — tracks the state of a team's batting innings.
class Innings {
  const Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalBalls = 0,
    this.totalExtras = 0,
    this.totalWides = 0,
    this.totalNoBalls = 0,
    this.totalByes = 0,
    this.totalLegByes = 0,
    this.penaltyRuns = 0,
    this.isCompleted = false,
    this.completionReason,
    this.target,
    this.isSuperOver = false,
    this.superOverNumber,
    this.battingTeamName,
    this.bowlingTeamName,
  });

  final String id;
  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int totalWickets;
  final int totalBalls;
  final int totalExtras;
  final int totalWides;
  final int totalNoBalls;
  final int totalByes;
  final int totalLegByes;
  final int penaltyRuns;
  final bool isCompleted;
  final InningsCompletionReason? completionReason;
  final int? target;
  final bool isSuperOver;
  final int? superOverNumber;
  final String? battingTeamName;
  final String? bowlingTeamName;

  /// Overs display string: "12.3" format.
  String get oversDisplay => CricketUtils.formatOvers(totalBalls);

  /// Current run rate: runs per over.
  double get runRate => CricketUtils.currentRunRate(totalRuns, totalBalls);

  /// Runs needed to win (2nd innings only).
  /// Returns null if no target set.
  int? get runsNeeded {
    if (target == null) return null;
    final needed = target! - totalRuns;
    return needed > 0 ? needed : 0;
  }

  /// Whether this is the first innings.
  bool get isFirstInnings => inningsNumber == 1;

  /// Whether this is the second innings.
  bool get isSecondInnings => inningsNumber == 2;
}
