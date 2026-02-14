import '../../../../core/utils/cricket_utils.dart';
import '../../presentation/notifiers/scoring_notifier.dart';
import 'batter_innings.dart';
import 'bowler_spell.dart';
import 'delivery.dart';
import 'playing_xi_player.dart';

/// Complete snapshot of an innings — used by the Scorecard page.
///
/// Captures everything needed to render scorecard tabs: batter stats, bowler
/// stats, extras breakdown, fall of wickets, delivery history, and roster.
/// Created via [InningsData.fromScoringState] before state is replaced.
class InningsData {
  const InningsData({
    required this.teamName,
    required this.teamId,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalBalls,
    required this.totalWides,
    required this.totalNoBalls,
    required this.totalByes,
    required this.totalLegByes,
    required this.totalExtras,
    required this.batterStats,
    required this.bowlerStats,
    required this.fallOfWickets,
    required this.deliveryHistory,
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
  });

  final String teamName;
  final String teamId;
  final int totalRuns;
  final int totalWickets;
  final int totalBalls;
  final int totalWides;
  final int totalNoBalls;
  final int totalByes;
  final int totalLegByes;
  final int totalExtras;
  final Map<String, BatterInnings> batterStats;
  final Map<String, BowlerSpell> bowlerStats;
  final List<FallOfWicket> fallOfWickets;
  final List<Delivery> deliveryHistory;
  final List<PlayingXIPlayer> battingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;

  /// Score display: "187/6" format.
  String get scoreDisplay => '$totalRuns/$totalWickets';

  /// Overs display: "12.3" format.
  String get oversDisplay => CricketUtils.formatOvers(totalBalls);

  /// Current run rate.
  double get runRate => CricketUtils.currentRunRate(totalRuns, totalBalls);

  /// Extras display: "15 (wd 5, nb 4, b 3, lb 3)" format.
  String get extrasDisplay {
    final parts = <String>[];
    if (totalWides > 0) parts.add('wd $totalWides');
    if (totalNoBalls > 0) parts.add('nb $totalNoBalls');
    if (totalByes > 0) parts.add('b $totalByes');
    if (totalLegByes > 0) parts.add('lb $totalLegByes');
    if (parts.isEmpty) return '0';
    return '$totalExtras (${parts.join(', ')})';
  }

  /// Batting order derived from delivery history (first appearance as striker).
  List<BatterInnings> get battingOrder {
    final seen = <String>{};
    final order = <BatterInnings>[];

    for (final delivery in deliveryHistory) {
      if (!seen.contains(delivery.strikerId)) {
        seen.add(delivery.strikerId);
        final stats = batterStats[delivery.strikerId];
        if (stats != null) order.add(stats);
      }
      if (!seen.contains(delivery.nonStrikerId)) {
        seen.add(delivery.nonStrikerId);
        final stats = batterStats[delivery.nonStrikerId];
        if (stats != null) order.add(stats);
      }
    }

    // Add any remaining batters not in delivery history (e.g. walked in but didn't face)
    for (final entry in batterStats.entries) {
      if (!seen.contains(entry.key)) {
        order.add(entry.value);
      }
    }

    return order;
  }

  /// Players from the batting team who haven't batted yet.
  List<PlayingXIPlayer> get yetToBatPlayers {
    return battingTeamPlayers
        .where((p) => !batterStats.containsKey(p.playerId))
        .toList();
  }

  /// Bowlers ordered by first appearance in delivery history.
  List<BowlerSpell> get bowlingOrder {
    final seen = <String>{};
    final order = <BowlerSpell>[];

    for (final delivery in deliveryHistory) {
      if (!seen.contains(delivery.bowlerId)) {
        seen.add(delivery.bowlerId);
        final stats = bowlerStats[delivery.bowlerId];
        if (stats != null) order.add(stats);
      }
    }

    // Add any remaining bowlers not in delivery history
    for (final entry in bowlerStats.entries) {
      if (!seen.contains(entry.key)) {
        order.add(entry.value);
      }
    }

    return order;
  }

  /// Create from the current scoring state — captures a full snapshot.
  factory InningsData.fromScoringState(ScoringState state) {
    return InningsData(
      teamName: state.battingTeamName,
      teamId: state.battingTeamId,
      totalRuns: state.totalRuns,
      totalWickets: state.totalWickets,
      totalBalls: state.totalBalls,
      totalWides: state.totalWides,
      totalNoBalls: state.totalNoBalls,
      totalByes: state.totalByes,
      totalLegByes: state.totalLegByes,
      totalExtras: state.totalExtras,
      batterStats: Map.unmodifiable(state.batterStats),
      bowlerStats: Map.unmodifiable(state.bowlerStats),
      fallOfWickets: List.unmodifiable(state.fallOfWickets),
      deliveryHistory: List.unmodifiable(state.deliveryHistory),
      battingTeamPlayers: List.unmodifiable(state.battingTeamPlayers),
      bowlingTeamPlayers: List.unmodifiable(state.bowlingTeamPlayers),
    );
  }
}
