import '../../features/analytics/domain/entities/mvp_data.dart';
import '../../features/scoring/domain/entities/batter_innings.dart';
import '../../features/scoring/domain/entities/bowler_spell.dart';
import '../../features/scoring/domain/entities/delivery.dart';
import '../../features/scoring/domain/entities/innings_data.dart';
import '../../features/scoring/domain/entities/scorecard_data.dart';

/// Compute MVP rankings for a completed match.
///
/// Implements the point system from SCORING_RULES.md Section 5.
MatchMvpData computeMvp(ScorecardData data) {
  final players = <String, _PlayerAccumulator>{};

  // Process first innings
  _processInnings(data.firstInnings, players, isFirstInnings: true);
  // Process second innings
  _processInnings(data.secondInnings, players, isFirstInnings: false);

  // Compute match average economy for bowling bonus
  final matchEconomy = _computeMatchAverageEconomy(data);

  // Calculate final points and build scores
  final scores = players.values.map((p) {
    final battingPts = _computeBattingPoints(p);
    final bowlingPts = _computeBowlingPoints(p, matchEconomy);
    final fieldingPts = _computeFieldingPoints(p);
    final total = battingPts + bowlingPts + fieldingPts;

    return MvpPlayerScore(
      playerId: p.playerId,
      displayName: p.displayName,
      teamName: p.teamName,
      teamId: p.teamId,
      battingPoints: battingPts,
      bowlingPoints: bowlingPts,
      fieldingPoints: fieldingPts,
      totalPoints: total,
      performanceSummary: _buildPerformanceSummary(p),
    );
  }).toList();

  // Sort: total descending, tiebreaker batting > bowling > fielding
  scores.sort((a, b) {
    final cmp = b.totalPoints.compareTo(a.totalPoints);
    if (cmp != 0) return cmp;
    final batCmp = b.battingPoints.compareTo(a.battingPoints);
    if (batCmp != 0) return batCmp;
    final bowlCmp = b.bowlingPoints.compareTo(a.bowlingPoints);
    if (bowlCmp != 0) return bowlCmp;
    return b.fieldingPoints.compareTo(a.fieldingPoints);
  });

  return MatchMvpData(rankings: scores);
}

/// Compute batting points per SCORING_RULES.md §5.1.
double computeBattingPoints(BatterInnings batter, double teamSR) {
  return _computeBattingPointsFromStats(
    runsScored: batter.runsScored,
    ballsFaced: batter.ballsFaced,
    fours: batter.fours,
    sixes: batter.sixes,
    teamSR: teamSR,
  );
}

/// Compute bowling points per SCORING_RULES.md §5.2.
double computeBowlingPoints(BowlerSpell bowler, double matchEconomy) {
  return _computeBowlingPointsFromStats(
    wicketsTaken: bowler.wicketsTaken,
    economyRate: bowler.economyRate,
    maidens: bowler.maidens,
    ballsBowled: bowler.ballsBowled,
    matchEconomy: matchEconomy,
  );
}

// ── Internal implementation ──────────────────────────────────────────────

void _processInnings(
  InningsData innings,
  Map<String, _PlayerAccumulator> players, {
  required bool isFirstInnings,
}) {
  final teamSR = _computeTeamStrikeRate(innings);

  // Batting
  for (final entry in innings.batterStats.entries) {
    final batter = entry.value;
    final p = players.putIfAbsent(
      batter.playerId,
      () => _PlayerAccumulator(
        playerId: batter.playerId,
        displayName: batter.displayName,
        teamName: innings.teamName,
        teamId: innings.teamId,
      ),
    );
    p.totalRuns += batter.runsScored;
    p.totalBallsFaced += batter.ballsFaced;
    p.totalFours += batter.fours;
    p.totalSixes += batter.sixes;
    p.teamSRs.add(teamSR);
    p.hasBatted = true;
  }

  // Bowling (bowlers are from the OTHER team)
  for (final entry in innings.bowlerStats.entries) {
    final bowler = entry.value;
    // Bowlers belong to the bowling team (opposite of innings batting team)
    // We need to find the bowler's team info
    final bowlerTeamName = innings.bowlingTeamPlayers.isNotEmpty
        ? _findPlayerTeamName(bowler.playerId, innings)
        : '';
    const bowlerTeamId = '';

    final p = players.putIfAbsent(
      bowler.playerId,
      () => _PlayerAccumulator(
        playerId: bowler.playerId,
        displayName: bowler.displayName,
        teamName: bowlerTeamName,
        teamId: bowlerTeamId,
      ),
    );
    p.totalWickets += bowler.wicketsTaken;
    p.totalBallsBowled += bowler.ballsBowled;
    p.totalRunsConceded += bowler.runsConceded;
    p.totalMaidens += bowler.maidens;
    p.hasBowled = true;
  }

  // Fielding (extract from deliveries with wicketInfo)
  for (final delivery in innings.deliveryHistory) {
    if (!delivery.isWicket || delivery.wicketInfo == null) continue;
    final wi = delivery.wicketInfo!;
    if (wi.fielderId == null) continue;

    final fielderId = wi.fielderId!;
    // Find fielder name from bowling team players
    final fielderName = _findFielderName(fielderId, innings);

    final p = players.putIfAbsent(
      fielderId,
      () => _PlayerAccumulator(
        playerId: fielderId,
        displayName: fielderName,
        teamName: '', // Will be set if player also bats/bowls
        teamId: '',
      ),
    );

    switch (wi.dismissalType) {
      case DismissalType.caught || DismissalType.caughtAndBowled:
        p.catches++;
      case DismissalType.stumped:
        p.stumpings++;
      case DismissalType.runOut:
        p.runOuts++;
      default:
        break;
    }
  }
}

String _findPlayerTeamName(String playerId, InningsData innings) {
  // Bowlers are in the bowlingTeamPlayers list
  for (final p in innings.bowlingTeamPlayers) {
    if (p.playerId == playerId) return ''; // Team name resolved via accumulator
  }
  return '';
}

String _findFielderName(String fielderId, InningsData innings) {
  for (final p in innings.bowlingTeamPlayers) {
    if (p.playerId == fielderId) return p.displayName;
  }
  return fielderId; // Fallback to ID
}

double _computeTeamStrikeRate(InningsData innings) {
  if (innings.totalBalls == 0) return 0;
  return (innings.totalRuns / innings.totalBalls) * 100;
}

double _computeMatchAverageEconomy(ScorecardData data) {
  int totalBallsBowled = 0;
  int totalRunsConceded = 0;

  for (final bowler in data.firstInnings.bowlerStats.values) {
    totalBallsBowled += bowler.ballsBowled;
    totalRunsConceded += bowler.runsConceded;
  }
  for (final bowler in data.secondInnings.bowlerStats.values) {
    totalBallsBowled += bowler.ballsBowled;
    totalRunsConceded += bowler.runsConceded;
  }

  if (totalBallsBowled == 0) return 0;
  return (totalRunsConceded / totalBallsBowled) * 6;
}

double _computeBattingPoints(_PlayerAccumulator p) {
  if (!p.hasBatted || p.totalBallsFaced == 0) return 0;

  return _computeBattingPointsFromStats(
    runsScored: p.totalRuns,
    ballsFaced: p.totalBallsFaced,
    fours: p.totalFours,
    sixes: p.totalSixes,
    teamSR: p.teamSRs.isEmpty ? 0 : p.teamSRs.first,
  );
}

double _computeBattingPointsFromStats({
  required int runsScored,
  required int ballsFaced,
  required int fours,
  required int sixes,
  required double teamSR,
}) {
  if (ballsFaced == 0) return 0;

  // Base: 1 point per 10 runs
  double points = runsScored / 10;

  // SR bonus/penalty (within 10% of team SR = neutral)
  final batterSR = (runsScored / ballsFaced) * 100;
  if (teamSR > 0) {
    final threshold = teamSR * 0.1;
    if (batterSR > teamSR + threshold) {
      points += 0.5;
    } else if (batterSR < teamSR - threshold) {
      points -= 0.5;
    }
  }

  // Milestone bonus (100 replaces 50, not additive)
  if (runsScored >= 100) {
    points += 5.0;
  } else if (runsScored >= 50) {
    points += 2.0;
  }

  // Boundary bonuses
  points += fours * 0.1;
  points += sixes * 0.2;

  return points;
}

double _computeBowlingPoints(_PlayerAccumulator p, double matchEconomy) {
  if (!p.hasBowled) return 0;

  return _computeBowlingPointsFromStats(
    wicketsTaken: p.totalWickets,
    economyRate:
        p.totalBallsBowled > 0
            ? (p.totalRunsConceded / p.totalBallsBowled) * 6
            : 0,
    maidens: p.totalMaidens,
    ballsBowled: p.totalBallsBowled,
    matchEconomy: matchEconomy,
  );
}

double _computeBowlingPointsFromStats({
  required int wicketsTaken,
  required double economyRate,
  required int maidens,
  required int ballsBowled,
  required double matchEconomy,
}) {
  if (ballsBowled == 0) return 0;

  // Base: 3 points per wicket
  double points = wicketsTaken * 3.0;

  // Economy bonus/penalty (within 0.5 of match average = neutral)
  if (matchEconomy > 0) {
    if (economyRate < matchEconomy - 0.5) {
      points += 1.0;
    } else if (economyRate > matchEconomy + 0.5) {
      points -= 1.0;
    }
  }

  // Maiden bonus
  points += maidens * 1.0;

  // Milestone bonus (5W replaces 3W, not additive)
  if (wicketsTaken >= 5) {
    points += 5.0;
  } else if (wicketsTaken >= 3) {
    points += 3.0;
  }

  return points;
}

double _computeFieldingPoints(_PlayerAccumulator p) {
  double points = 0;
  points += p.catches * 1.5;
  points += p.stumpings * 1.5;
  points += p.runOuts * 1.5;
  return points;
}

String _buildPerformanceSummary(_PlayerAccumulator p) {
  final parts = <String>[];

  if (p.hasBatted && p.totalBallsFaced > 0) {
    parts.add('${p.totalRuns}(${p.totalBallsFaced})');
  }

  if (p.hasBowled && p.totalBallsBowled > 0) {
    parts.add('${p.totalWickets}/${p.totalRunsConceded}');
  }

  final fieldingParts = <String>[];
  if (p.catches > 0) fieldingParts.add('${p.catches} ct');
  if (p.stumpings > 0) fieldingParts.add('${p.stumpings} st');
  if (p.runOuts > 0) fieldingParts.add('${p.runOuts} ro');
  if (fieldingParts.isNotEmpty) {
    parts.add(fieldingParts.join(', '));
  }

  return parts.isEmpty ? '-' : parts.join(', ');
}

class _PlayerAccumulator {
  _PlayerAccumulator({
    required this.playerId,
    required this.displayName,
    required this.teamName,
    required this.teamId,
  });

  final String playerId;
  final String displayName;
  String teamName;
  String teamId;

  // Batting
  bool hasBatted = false;
  int totalRuns = 0;
  int totalBallsFaced = 0;
  int totalFours = 0;
  int totalSixes = 0;
  List<double> teamSRs = [];

  // Bowling
  bool hasBowled = false;
  int totalWickets = 0;
  int totalBallsBowled = 0;
  int totalRunsConceded = 0;
  int totalMaidens = 0;

  // Fielding
  int catches = 0;
  int stumpings = 0;
  int runOuts = 0;
}
