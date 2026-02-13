import '../../../../core/utils/cricket_utils.dart';

/// Live bowling stats for a bowler in the current innings.
class BowlerSpell {
  const BowlerSpell({
    required this.playerId,
    required this.displayName,
    this.ballsBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.dotBalls = 0,
  });

  final String playerId;
  final String displayName;
  final int ballsBowled;
  final int maidens;
  final int runsConceded;
  final int wicketsTaken;
  final int wides;
  final int noBalls;
  final int dotBalls;

  /// Overs display string: "4.0", "3.2" format.
  String get oversDisplay => CricketUtils.formatOvers(ballsBowled);

  /// Economy rate: runs per over.
  double get economyRate {
    if (ballsBowled == 0) return 0;
    return (runsConceded / ballsBowled) * 6;
  }

  /// Bowling figures: "wickets-runs" format (e.g. "3-25").
  String get figures => '$wicketsTaken-$runsConceded';

  /// Create a copy with updated fields.
  BowlerSpell copyWith({
    int? ballsBowled,
    int? maidens,
    int? runsConceded,
    int? wicketsTaken,
    int? wides,
    int? noBalls,
    int? dotBalls,
  }) {
    return BowlerSpell(
      playerId: playerId,
      displayName: displayName,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wicketsTaken: wicketsTaken ?? this.wicketsTaken,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      dotBalls: dotBalls ?? this.dotBalls,
    );
  }
}
