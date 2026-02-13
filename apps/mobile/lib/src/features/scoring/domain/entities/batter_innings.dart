import 'delivery.dart';

/// Live batting stats for a batter in the current innings.
class BatterInnings {
  const BatterInnings({
    required this.playerId,
    required this.displayName,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isNotOut = true,
    this.isOnStrike = false,
    this.isRetiredHurt = false,
    this.dismissalType,
    this.dismissedByName,
    this.fielderName,
  });

  final String playerId;
  final String displayName;
  final int runsScored;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isNotOut;
  final bool isOnStrike;
  final bool isRetiredHurt;
  final DismissalType? dismissalType;
  final String? dismissedByName;
  final String? fielderName;

  /// Strike rate: (runs / balls) * 100.
  double get strikeRate {
    if (ballsFaced == 0) return 0;
    return (runsScored / ballsFaced) * 100;
  }

  /// Whether this batter is currently at the crease (not out and not retired).
  bool get isActive => isNotOut && !isRetiredHurt;

  /// Whether this retired hurt batter can return.
  bool get canReturn => isRetiredHurt && isNotOut;

  /// Scorecard dismissal description.
  ///
  /// Examples:
  ///   "b Bumrah" (bowled)
  ///   "c Kohli b Bumrah" (caught)
  ///   "lbw b Bumrah" (LBW)
  ///   "run out (Jadeja)" (run out)
  ///   "st Pant b Ashwin" (stumped)
  ///   "hit wkt b Bumrah" (hit wicket)
  ///   "c & b Bumrah" (caught & bowled)
  ///   "retired hurt" (retired hurt)
  ///   "retired out" (retired out)
  ///   "not out" (still batting)
  String get dismissalDescription {
    if (isNotOut && !isRetiredHurt) return 'not out';
    if (dismissalType == null) return 'not out';

    switch (dismissalType!) {
      case DismissalType.bowled:
        return 'b ${dismissedByName ?? ''}';
      case DismissalType.caught:
        return 'c ${fielderName ?? ''} b ${dismissedByName ?? ''}';
      case DismissalType.lbw:
        return 'lbw b ${dismissedByName ?? ''}';
      case DismissalType.runOut:
        return 'run out (${fielderName ?? ''})';
      case DismissalType.stumped:
        return 'st ${fielderName ?? ''} b ${dismissedByName ?? ''}';
      case DismissalType.hitWicket:
        return 'hit wkt b ${dismissedByName ?? ''}';
      case DismissalType.caughtAndBowled:
        return 'c & b ${dismissedByName ?? ''}';
      case DismissalType.retiredHurt:
        return 'retired hurt';
      case DismissalType.retiredOut:
        return 'retired out';
      case DismissalType.timedOut:
        return 'timed out';
      case DismissalType.obstructingField:
        return 'obstructing field';
    }
  }

  /// Create a copy with updated fields.
  BatterInnings copyWith({
    int? runsScored,
    int? ballsFaced,
    int? fours,
    int? sixes,
    bool? isNotOut,
    bool? isOnStrike,
    bool? isRetiredHurt,
    DismissalType? dismissalType,
    String? dismissedByName,
    String? fielderName,
  }) {
    return BatterInnings(
      playerId: playerId,
      displayName: displayName,
      runsScored: runsScored ?? this.runsScored,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isNotOut: isNotOut ?? this.isNotOut,
      isOnStrike: isOnStrike ?? this.isOnStrike,
      isRetiredHurt: isRetiredHurt ?? this.isRetiredHurt,
      dismissalType: dismissalType ?? this.dismissalType,
      dismissedByName: dismissedByName ?? this.dismissedByName,
      fielderName: fielderName ?? this.fielderName,
    );
  }
}
