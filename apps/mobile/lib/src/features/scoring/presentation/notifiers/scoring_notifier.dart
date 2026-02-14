import '../../../../core/constants/cricket_constants.dart';
import '../../../../core/utils/cricket_utils.dart';
import '../../../../core/utils/scoring_utils.dart';
import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/innings_data.dart';
import '../../domain/entities/over.dart';
import '../../domain/entities/playing_xi_player.dart';
import '../../domain/entities/wicket_info.dart';

/// A fall-of-wicket entry for the innings summary.
class FallOfWicket {
  const FallOfWicket({
    required this.wicketNumber,
    required this.scoreAtFall,
    required this.oversAtFall,
    required this.dismissedPlayerName,
  });

  final int wicketNumber;
  final int scoreAtFall;
  final String oversAtFall;
  final String dismissedPlayerName;
}

/// A bowler option for the Select Bowler bottom sheet.
///
/// Wraps a bowler's identity with eligibility status and optional spell stats.
class BowlerOption {
  const BowlerOption({
    required this.playerId,
    required this.displayName,
    required this.isEligible,
    this.ineligibleReason,
    this.spell,
    this.playerRole,
    this.bowlingStyle,
    this.isCaptain = false,
    this.isKeeper = false,
  });

  final String playerId;
  final String displayName;
  final bool isEligible;
  final String? ineligibleReason;
  final BowlerSpell? spell;
  final String? playerRole;
  final String? bowlingStyle;
  final bool isCaptain;
  final bool isKeeper;

  /// Initials from display name.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Badge text: "(C)", "(WK)", "(C & WK)", or null.
  String? get badge {
    if (isCaptain && isKeeper) return '(C & WK)';
    if (isCaptain) return '(C)';
    if (isKeeper) return '(WK)';
    return null;
  }
}

/// Snapshot of the 1st innings score, captured before 2nd innings transition.
///
/// Since [ScoringState] is entirely replaced when starting the 2nd innings,
/// this preserves the 1st innings data needed for the match complete modal.
class FirstInningsSummary {
  const FirstInningsSummary({
    required this.teamName,
    required this.teamId,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalBalls,
    required this.oversDisplay,
  });

  final String teamName;
  final String teamId;
  final int totalRuns;
  final int totalWickets;
  final int totalBalls;
  final String oversDisplay;

  /// Score display: "187/6" format.
  String get scoreDisplay => '$totalRuns/$totalWickets';
}

/// Result type for a completed match.
enum MatchResultType { runs, wickets, tie }

/// Computed match result after both innings are complete.
class MatchResult {
  const MatchResult({
    this.winnerTeamId,
    this.winnerTeamName,
    required this.resultType,
    this.margin,
    required this.resultDescription,
  });

  final String? winnerTeamId;
  final String? winnerTeamName;
  final MatchResultType resultType;
  final int? margin;
  final String resultDescription;
}

/// Sentinel for [ScoringState.copyWith] to distinguish "not provided" from "set to null".
const _unset = Object();

/// Complete state for the scoring page.
///
/// Contains all match context, player state, innings totals, and undo history.
/// Uses sentinel-based copyWith for nullable fields.
class ScoringState {
  ScoringState({
    // Match context (immutable per innings)
    required this.matchId,
    required this.inningsId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.inningsNumber,
    required this.totalOvers,
    required this.playersPerSide,
    this.wideRunsPenalty = CricketConstants.defaultWideRuns,
    this.noBallRunsPenalty = CricketConstants.defaultNoBallRuns,
    this.battingTeamName = '',
    this.bowlingTeamName = '',
    // Playing XI rosters
    this.battingTeamPlayers = const [],
    this.bowlingTeamPlayers = const [],
    this.maxOversPerBowler,
    // Current players
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
    // Innings totals
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalBalls = 0,
    this.totalExtras = 0,
    this.totalWides = 0,
    this.totalNoBalls = 0,
    this.totalByes = 0,
    this.totalLegByes = 0,
    this.target,
    // Over state
    this.isFreeHitPending = false,
    this.currentOverBalls = 0,
    this.currentOverDeliveries = const [],
    this.completedOvers = const [],
    // Player stats
    Map<String, BatterInnings>? batterStats,
    Map<String, BowlerSpell>? bowlerStats,
    this.lastBowlerId,
    // Completion
    this.isInningsComplete = false,
    this.isMatchComplete = false,
    this.completionReason,
    // UI state
    this.isProcessing = false,
    this.error,
    // Undo
    this.deliveryHistory = const [],
    this.undoBlockedByTransition = false,
    // 1st innings snapshot (populated after startSecondInnings)
    this.firstInningsSummary,
    this.firstInnings,
  })  : batterStats = batterStats ?? const {},
        bowlerStats = bowlerStats ?? const {};

  // ── Match context ──

  final String matchId;
  final String inningsId;
  final String battingTeamId;
  final String bowlingTeamId;
  final int inningsNumber;
  final int totalOvers;
  final int playersPerSide;
  final int wideRunsPenalty;
  final int noBallRunsPenalty;
  final String battingTeamName;
  final String bowlingTeamName;

  // ── Playing XI rosters ──

  final List<PlayingXIPlayer> battingTeamPlayers;
  final List<PlayingXIPlayer> bowlingTeamPlayers;
  final int? maxOversPerBowler;

  // ── Current players ──

  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;

  // ── Innings totals ──

  final int totalRuns;
  final int totalWickets;
  final int totalBalls;
  final int totalExtras;
  final int totalWides;
  final int totalNoBalls;
  final int totalByes;
  final int totalLegByes;
  final int? target;

  // ── Over state ──

  final bool isFreeHitPending;
  final int currentOverBalls;
  final List<Delivery> currentOverDeliveries;
  final List<Over> completedOvers;

  // ── Player stats ──

  final Map<String, BatterInnings> batterStats;
  final Map<String, BowlerSpell> bowlerStats;
  final String? lastBowlerId;

  // ── Completion ──

  final bool isInningsComplete;
  final bool isMatchComplete;
  final InningsCompletionReason? completionReason;

  // ── UI state ──

  final bool isProcessing;
  final String? error;

  // ── Undo ──

  final List<Delivery> deliveryHistory;
  final bool undoBlockedByTransition;

  // ── 1st innings snapshot ──

  final FirstInningsSummary? firstInningsSummary;

  /// Full 1st innings data for scorecard (populated after startSecondInnings).
  final InningsData? firstInnings;

  // ── Computed properties ──

  /// Overs display: "12.3" format.
  String get oversDisplay => CricketUtils.formatOvers(totalBalls);

  /// Current run rate.
  double get runRate => CricketUtils.currentRunRate(totalRuns, totalBalls);

  /// Runs needed to win (2nd innings chase).
  int? get runsNeeded {
    if (target == null) return null;
    final needed = target! - totalRuns;
    return needed > 0 ? needed : 0;
  }

  /// Balls remaining in the innings.
  int get ballsRemaining => (totalOvers * CricketConstants.ballsPerOver) - totalBalls;

  /// Required run rate for 2nd innings.
  double? get requiredRunRate {
    if (target == null) return null;
    final needed = runsNeeded;
    if (needed == null || needed == 0) return null;
    return CricketUtils.requiredRunRate(needed, ballsRemaining);
  }

  /// Current striker's batting stats.
  BatterInnings? get striker =>
      strikerId != null ? batterStats[strikerId] : null;

  /// Current non-striker's batting stats.
  BatterInnings? get nonStriker =>
      nonStrikerId != null ? batterStats[nonStrikerId] : null;

  /// Current bowler's spell stats.
  BowlerSpell? get currentBowler =>
      bowlerId != null ? bowlerStats[bowlerId] : null;

  /// Whether undo is available.
  bool get canUndo =>
      deliveryHistory.isNotEmpty && !isInningsComplete && !undoBlockedByTransition;

  /// Last delivery in history.
  Delivery? get lastDelivery =>
      deliveryHistory.isNotEmpty ? deliveryHistory.last : null;

  /// Whether a new batter needs to be selected.
  bool get needsNewBatter =>
      strikerId == null || nonStrikerId == null;

  /// Whether a new bowler needs to be selected.
  bool get needsNewBowler => bowlerId == null;

  /// Players from the batting team who haven't batted yet.
  List<PlayingXIPlayer> get yetToBatPlayers => battingTeamPlayers
      .where((p) => !batterStats.containsKey(p.playerId))
      .toList();

  /// Batters who retired hurt and can return.
  List<BatterInnings> get retiredHurtBatters => batterStats.values
      .where((b) => b.canReturn)
      .toList();

  /// Count of available batters (yet to bat + retired hurt).
  int get availableBatterCount =>
      yetToBatPlayers.length + retiredHurtBatters.length;

  /// Bowler options with eligibility for the Select Bowler sheet.
  List<BowlerOption> get bowlerOptions {
    final effectiveMax = maxOversPerBowler ??
        (totalOvers / 5).ceil();

    return bowlingTeamPlayers.map((p) {
      final spell = bowlerStats[p.playerId];
      final oversCompleted = spell != null
          ? spell.ballsBowled ~/ CricketConstants.ballsPerOver
          : 0;

      String? reason;
      if (p.playerId == lastBowlerId) {
        reason = 'Bowled last over';
      } else if (oversCompleted >= effectiveMax) {
        reason = 'Max overs reached';
      }

      return BowlerOption(
        playerId: p.playerId,
        displayName: p.displayName,
        isEligible: reason == null,
        ineligibleReason: reason,
        spell: spell,
        playerRole: p.playerRole,
        bowlingStyle: p.bowlingStyle,
        isCaptain: p.isCaptain,
        isKeeper: p.isKeeper,
      );
    }).toList();
  }

  /// Count of eligible bowlers.
  int get eligibleBowlerCount =>
      bowlerOptions.where((o) => o.isEligible).length;

  /// Score display: "185/6" format.
  String get scoreDisplay => '$totalRuns/$totalWickets';

  /// Current over number (1-based, in progress).
  int get currentOverNumber => (totalBalls ~/ CricketConstants.ballsPerOver) + 1;

  /// Fall of wickets computed from delivery history.
  List<FallOfWicket> get fallOfWickets {
    final result = <FallOfWicket>[];
    int runningTotal = 0;
    int legalBalls = 0;
    int wicketCount = 0;

    for (final del in deliveryHistory) {
      runningTotal += del.totalRuns;
      if (del.isLegal) legalBalls++;

      if (del.isWicket) {
        wicketCount++;
        final dismissedId = del.wicketInfo?.dismissedPlayerId ?? del.strikerId;
        final dismissedName =
            batterStats[dismissedId]?.displayName ?? dismissedId;
        result.add(FallOfWicket(
          wicketNumber: wicketCount,
          scoreAtFall: runningTotal,
          oversAtFall: CricketUtils.formatOvers(legalBalls),
          dismissedPlayerName: dismissedName,
        ));
      }
    }

    return result;
  }

  /// Computed match result — mirrors server's `completeMatch()` logic.
  ///
  /// Returns null if the match is not complete or first innings summary is missing.
  MatchResult? get matchResult {
    if (!isMatchComplete) return null;
    if (firstInningsSummary == null) return null;

    final firstRuns = firstInningsSummary!.totalRuns;
    final secondRuns = totalRuns;

    if (firstRuns > secondRuns) {
      // 1st batting team wins by runs
      final margin = firstRuns - secondRuns;
      return MatchResult(
        winnerTeamId: firstInningsSummary!.teamId,
        winnerTeamName: firstInningsSummary!.teamName,
        resultType: MatchResultType.runs,
        margin: margin,
        resultDescription:
            '${firstInningsSummary!.teamName} won by $margin runs',
      );
    } else if (secondRuns > firstRuns) {
      // 2nd batting team wins by wickets
      final margin = playersPerSide - 1 - totalWickets;
      return MatchResult(
        winnerTeamId: battingTeamId,
        winnerTeamName: battingTeamName,
        resultType: MatchResultType.wickets,
        margin: margin,
        resultDescription: '$battingTeamName won by $margin wickets',
      );
    } else {
      // Tie
      return const MatchResult(
        winnerTeamId: null,
        winnerTeamName: null,
        resultType: MatchResultType.tie,
        margin: null,
        resultDescription: 'Match Tied',
      );
    }
  }

  /// Sentinel-based copyWith for nullable fields.
  ScoringState copyWith({
    List<PlayingXIPlayer>? battingTeamPlayers,
    List<PlayingXIPlayer>? bowlingTeamPlayers,
    Object? maxOversPerBowler = _unset,
    Object? strikerId = _unset,
    Object? nonStrikerId = _unset,
    Object? bowlerId = _unset,
    int? totalRuns,
    int? totalWickets,
    int? totalBalls,
    int? totalExtras,
    int? totalWides,
    int? totalNoBalls,
    int? totalByes,
    int? totalLegByes,
    Object? target = _unset,
    bool? isFreeHitPending,
    int? currentOverBalls,
    List<Delivery>? currentOverDeliveries,
    List<Over>? completedOvers,
    Map<String, BatterInnings>? batterStats,
    Map<String, BowlerSpell>? bowlerStats,
    Object? lastBowlerId = _unset,
    bool? isInningsComplete,
    bool? isMatchComplete,
    Object? completionReason = _unset,
    bool? isProcessing,
    Object? error = _unset,
    List<Delivery>? deliveryHistory,
    bool? undoBlockedByTransition,
    Object? firstInningsSummary = _unset,
    Object? firstInnings = _unset,
  }) {
    return ScoringState(
      matchId: matchId,
      inningsId: inningsId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      inningsNumber: inningsNumber,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      wideRunsPenalty: wideRunsPenalty,
      noBallRunsPenalty: noBallRunsPenalty,
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      battingTeamPlayers:
          battingTeamPlayers ?? this.battingTeamPlayers,
      bowlingTeamPlayers:
          bowlingTeamPlayers ?? this.bowlingTeamPlayers,
      maxOversPerBowler: identical(maxOversPerBowler, _unset)
          ? this.maxOversPerBowler
          : maxOversPerBowler as int?,
      strikerId: identical(strikerId, _unset)
          ? this.strikerId
          : strikerId as String?,
      nonStrikerId: identical(nonStrikerId, _unset)
          ? this.nonStrikerId
          : nonStrikerId as String?,
      bowlerId: identical(bowlerId, _unset)
          ? this.bowlerId
          : bowlerId as String?,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWickets: totalWickets ?? this.totalWickets,
      totalBalls: totalBalls ?? this.totalBalls,
      totalExtras: totalExtras ?? this.totalExtras,
      totalWides: totalWides ?? this.totalWides,
      totalNoBalls: totalNoBalls ?? this.totalNoBalls,
      totalByes: totalByes ?? this.totalByes,
      totalLegByes: totalLegByes ?? this.totalLegByes,
      target: identical(target, _unset) ? this.target : target as int?,
      isFreeHitPending: isFreeHitPending ?? this.isFreeHitPending,
      currentOverBalls: currentOverBalls ?? this.currentOverBalls,
      currentOverDeliveries:
          currentOverDeliveries ?? this.currentOverDeliveries,
      completedOvers: completedOvers ?? this.completedOvers,
      batterStats: batterStats ?? this.batterStats,
      bowlerStats: bowlerStats ?? this.bowlerStats,
      lastBowlerId: identical(lastBowlerId, _unset)
          ? this.lastBowlerId
          : lastBowlerId as String?,
      isInningsComplete: isInningsComplete ?? this.isInningsComplete,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      completionReason: identical(completionReason, _unset)
          ? this.completionReason
          : completionReason as InningsCompletionReason?,
      isProcessing: isProcessing ?? this.isProcessing,
      error: identical(error, _unset) ? this.error : error as String?,
      deliveryHistory: deliveryHistory ?? this.deliveryHistory,
      undoBlockedByTransition:
          undoBlockedByTransition ?? this.undoBlockedByTransition,
      firstInningsSummary: identical(firstInningsSummary, _unset)
          ? this.firstInningsSummary
          : firstInningsSummary as FirstInningsSummary?,
      firstInnings: identical(firstInnings, _unset)
          ? this.firstInnings
          : firstInnings as InningsData?,
    );
  }
}

/// Scoring notifier — manages all scoring state transitions.
///
/// This notifier implements the client-side delivery pipeline, mirroring
/// the server's 10-step process on pure in-memory state.
///
/// Will be wired to a Riverpod provider in a later issue. Tests initialize
/// state directly.
class ScoringNotifier {
  ScoringNotifier(this._state);

  ScoringState _state;
  ScoringState get state => _state;

  // ── Public operations ──

  /// Record a normal delivery (runs from bat).
  void recordDelivery({
    required int runsFromBat,
    bool isBoundaryFour = false,
    bool isBoundarySix = false,
  }) {
    _processDelivery(
      runsFromBat: runsFromBat,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
    );
  }

  /// Record a wide delivery.
  void recordWide({int additionalRuns = 0}) {
    _processDelivery(
      isWide: true,
      wideRuns: _state.wideRunsPenalty + additionalRuns,
    );
  }

  /// Record a no-ball delivery.
  void recordNoBall({int runsFromBat = 0}) {
    _processDelivery(
      isNoBall: true,
      noBallRuns: _state.noBallRunsPenalty,
      runsFromBat: runsFromBat,
    );
  }

  /// Record a bye delivery.
  void recordBye({required int byeRuns}) {
    _processDelivery(isBye: true, byeRuns: byeRuns);
  }

  /// Record a leg-bye delivery.
  void recordLegBye({required int legByeRuns}) {
    _processDelivery(isLegBye: true, legByeRuns: legByeRuns);
  }

  /// Record a wicket delivery.
  void recordWicket({
    required DismissalType dismissalType,
    required String dismissedPlayerId,
    String? fielderId,
    String? fielderName,
    int runsFromBat = 0,
    bool isWide = false,
    int wideRuns = 0,
    bool battersCrossed = false,
  }) {
    final wicketInfo = WicketInfo(
      dismissedPlayerId: dismissedPlayerId,
      dismissalType: dismissalType,
      bowlerCredited: dismissalType.bowlerCredited,
      fielderId: fielderId,
      battersCrossed: battersCrossed,
    );

    _processDelivery(
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: isWide ? (_state.wideRunsPenalty + wideRuns) : 0,
      isWicket: true,
      wicketInfo: wicketInfo,
    );
  }

  /// Undo the last delivery.
  void undoLastDelivery() {
    if (!_state.canUndo) return;

    final lastDel = _state.deliveryHistory.last;
    final history = List<Delivery>.from(_state.deliveryHistory)..removeLast();

    // Reverse innings totals
    final newTotalRuns = _state.totalRuns - lastDel.totalRuns;
    var newTotalBalls = _state.totalBalls;
    var newTotalExtras = _state.totalExtras;
    var newTotalWides = _state.totalWides;
    var newTotalNoBalls = _state.totalNoBalls;
    var newTotalByes = _state.totalByes;
    var newTotalLegByes = _state.totalLegByes;
    var newTotalWickets = _state.totalWickets;

    if (lastDel.isLegal) newTotalBalls--;
    if (lastDel.isWide) {
      newTotalExtras -= lastDel.wideRuns;
      newTotalWides -= lastDel.wideRuns;
    }
    if (lastDel.isNoBall) {
      newTotalExtras -= lastDel.noBallRuns;
      newTotalNoBalls -= lastDel.noBallRuns;
    }
    if (lastDel.isBye) {
      newTotalExtras -= lastDel.byeRuns;
      newTotalByes -= lastDel.byeRuns;
    }
    if (lastDel.isLegBye) {
      newTotalExtras -= lastDel.legByeRuns;
      newTotalLegByes -= lastDel.legByeRuns;
    }
    if (lastDel.isWicket) newTotalWickets--;

    // Reverse batter stats
    final newBatterStats = Map<String, BatterInnings>.from(_state.batterStats);
    final strikerStats = newBatterStats[lastDel.strikerId];
    if (strikerStats != null && !lastDel.isWide) {
      var updatedBatter = strikerStats.copyWith(
        ballsFaced: strikerStats.ballsFaced - (lastDel.isLegal ? 1 : 0),
      );
      if (!lastDel.isBye && !lastDel.isLegBye) {
        updatedBatter = updatedBatter.copyWith(
          runsScored: strikerStats.runsScored - lastDel.runsFromBat,
          fours: strikerStats.fours - (lastDel.isBoundaryFour ? 1 : 0),
          sixes: strikerStats.sixes - (lastDel.isBoundarySix ? 1 : 0),
        );
      }
      if (lastDel.isWicket &&
          lastDel.wicketInfo?.dismissedPlayerId == lastDel.strikerId) {
        updatedBatter = updatedBatter.copyWith(isNotOut: true);
      }
      newBatterStats[lastDel.strikerId] = updatedBatter;
    }

    // Reverse bowler stats
    final newBowlerStats = Map<String, BowlerSpell>.from(_state.bowlerStats);
    final bowlerStat = newBowlerStats[lastDel.bowlerId];
    if (bowlerStat != null) {
      newBowlerStats[lastDel.bowlerId] = bowlerStat.copyWith(
        ballsBowled: bowlerStat.ballsBowled - (lastDel.isLegal ? 1 : 0),
        runsConceded: bowlerStat.runsConceded - lastDel.bowlerRunsConceded,
        wicketsTaken: bowlerStat.wicketsTaken -
            (lastDel.isWicket && (lastDel.wicketInfo?.bowlerCredited ?? false)
                ? 1
                : 0),
        wides: bowlerStat.wides - (lastDel.isWide ? 1 : 0),
        noBalls: bowlerStat.noBalls - (lastDel.isNoBall ? 1 : 0),
        dotBalls: bowlerStat.dotBalls - (lastDel.isDotBall ? 1 : 0),
      );
    }

    // Reverse strike change
    final shouldHaveSwapped = ScoringUtils.shouldSwapStrike(
      runsFromBat: lastDel.runsFromBat,
      isWide: lastDel.isWide,
      wideRuns: lastDel.wideRuns,
      isBye: lastDel.isBye,
      byeRuns: lastDel.byeRuns,
      isLegBye: lastDel.isLegBye,
      legByeRuns: lastDel.legByeRuns,
    );

    String? newStrikerId = lastDel.strikerId;
    String? newNonStrikerId = lastDel.nonStrikerId;

    if (lastDel.isWicket &&
        lastDel.wicketInfo?.dismissedPlayerId == lastDel.strikerId) {
      // Restore dismissed striker
      newStrikerId = lastDel.strikerId;
      newNonStrikerId = lastDel.nonStrikerId;
    } else if (shouldHaveSwapped) {
      // Reverse the swap that occurred
      newStrikerId = lastDel.strikerId;
      newNonStrikerId = lastDel.nonStrikerId;
    }

    // Update on-strike markers in batter stats
    for (final key in newBatterStats.keys) {
      newBatterStats[key] = newBatterStats[key]!.copyWith(
        isOnStrike: key == newStrikerId,
      );
    }

    // Reverse over state
    var newCurrentOverBalls = _state.currentOverBalls;
    var newCurrentOverDeliveries =
        List<Delivery>.from(_state.currentOverDeliveries);
    final newCompletedOvers = List<Over>.from(_state.completedOvers);

    if (newCurrentOverDeliveries.isNotEmpty &&
        newCurrentOverDeliveries.last.id == lastDel.id) {
      newCurrentOverDeliveries.removeLast();
    }
    if (lastDel.isLegal) newCurrentOverBalls--;

    // If we're undoing the first ball of a new over, reopen previous over
    // Use sentinels to track whether we need to restore bowler state
    String? restoredBowlerId;
    String? restoredLastBowlerId;
    bool overReopened = false;

    if (newCurrentOverBalls < 0 && newCompletedOvers.isNotEmpty) {
      final previousOver = newCompletedOvers.removeLast();
      newCurrentOverDeliveries =
          List<Delivery>.from(previousOver.deliveries);
      newCurrentOverBalls = previousOver.legalBalls - 1;
      if (newCurrentOverDeliveries.isNotEmpty) {
        newCurrentOverDeliveries.removeLast();
      }

      overReopened = true;

      // FIX 1: Restore bowlerId from reopened over
      restoredBowlerId = previousOver.bowlerId;

      // FIX 2: Restore lastBowlerId from the over before this one
      restoredLastBowlerId = newCompletedOvers.isNotEmpty
          ? newCompletedOvers.last.bowlerId
          : null;

      // FIX 3: Reverse maiden count if the reopened over was maiden
      if (previousOver.isMaiden) {
        final bowler = newBowlerStats[previousOver.bowlerId];
        if (bowler != null) {
          newBowlerStats[previousOver.bowlerId] = bowler.copyWith(
            maidens: bowler.maidens - 1,
          );
        }
      }
    }

    // Determine free hit state from previous delivery in history
    bool newFreeHitPending = false;
    if (history.isNotEmpty) {
      final prevDel = history.last;
      newFreeHitPending = ScoringUtils.isNextFreeHit(
        previousWasNoBall: prevDel.isNoBall,
        previousWasFreeHit: prevDel.isFreeHit,
        previousWasLegal: prevDel.isLegal,
      );
    }

    _state = _state.copyWith(
      totalRuns: newTotalRuns,
      totalBalls: newTotalBalls,
      totalWickets: newTotalWickets,
      totalExtras: newTotalExtras,
      totalWides: newTotalWides,
      totalNoBalls: newTotalNoBalls,
      totalByes: newTotalByes,
      totalLegByes: newTotalLegByes,
      strikerId: newStrikerId,
      nonStrikerId: newNonStrikerId,
      bowlerId: overReopened ? restoredBowlerId : _state.bowlerId,
      lastBowlerId: overReopened ? restoredLastBowlerId : _state.lastBowlerId,
      batterStats: newBatterStats,
      bowlerStats: newBowlerStats,
      currentOverBalls: newCurrentOverBalls,
      currentOverDeliveries: newCurrentOverDeliveries,
      completedOvers: newCompletedOvers,
      isFreeHitPending: newFreeHitPending,
      deliveryHistory: history,
      undoBlockedByTransition: false,
    );
  }

  /// Declare the current innings (1st innings only).
  void declareInnings() {
    if (_state.isInningsComplete) return;
    if (_state.inningsNumber != 1) return;

    _state = _state.copyWith(
      isInningsComplete: true,
      completionReason: InningsCompletionReason.declared,
    );
  }

  /// Start the 2nd innings after 1st innings completion.
  ///
  /// Creates a fresh state with swapped teams, target set, and opening
  /// players initialized.
  void startSecondInnings({
    required String strikerId,
    required String strikerName,
    required String nonStrikerId,
    required String nonStrikerName,
    required String bowlerId,
    required String bowlerName,
  }) {
    if (!_state.isInningsComplete) return;
    if (_state.inningsNumber >= 2) return;

    final target = _state.totalRuns + 1;

    // Capture 1st innings snapshot before replacing state
    final firstSummary = FirstInningsSummary(
      teamName: _state.battingTeamName,
      teamId: _state.battingTeamId,
      totalRuns: _state.totalRuns,
      totalWickets: _state.totalWickets,
      totalBalls: _state.totalBalls,
      oversDisplay: _state.oversDisplay,
    );

    // Capture full 1st innings data for scorecard
    final firstInningsData = InningsData.fromScoringState(_state);

    _state = ScoringState(
      matchId: _state.matchId,
      inningsId: '${_state.inningsId}-2',
      battingTeamId: _state.bowlingTeamId,
      bowlingTeamId: _state.battingTeamId,
      battingTeamName: _state.bowlingTeamName,
      bowlingTeamName: _state.battingTeamName,
      battingTeamPlayers: _state.bowlingTeamPlayers,
      bowlingTeamPlayers: _state.battingTeamPlayers,
      inningsNumber: 2,
      totalOvers: _state.totalOvers,
      playersPerSide: _state.playersPerSide,
      wideRunsPenalty: _state.wideRunsPenalty,
      noBallRunsPenalty: _state.noBallRunsPenalty,
      maxOversPerBowler: _state.maxOversPerBowler,
      target: target,
      firstInningsSummary: firstSummary,
      firstInnings: firstInningsData,
    );

    // Set up opening players
    selectNewBatter(playerId: strikerId, displayName: strikerName);
    selectNewBatter(playerId: nonStrikerId, displayName: nonStrikerName);
    selectNewBowler(playerId: bowlerId, displayName: bowlerName);
  }

  /// Manually swap strike (UI button).
  void swapStrike() {
    if (_state.strikerId == null || _state.nonStrikerId == null) return;

    final newBatterStats = Map<String, BatterInnings>.from(_state.batterStats);
    final oldStrikerId = _state.strikerId!;
    final oldNonStrikerId = _state.nonStrikerId!;

    if (newBatterStats.containsKey(oldStrikerId)) {
      newBatterStats[oldStrikerId] =
          newBatterStats[oldStrikerId]!.copyWith(isOnStrike: false);
    }
    if (newBatterStats.containsKey(oldNonStrikerId)) {
      newBatterStats[oldNonStrikerId] =
          newBatterStats[oldNonStrikerId]!.copyWith(isOnStrike: true);
    }

    _state = _state.copyWith(
      strikerId: oldNonStrikerId,
      nonStrikerId: oldStrikerId,
      batterStats: newBatterStats,
    );
  }

  /// Select a new batter (after wicket or to start).
  void selectNewBatter({
    required String playerId,
    required String displayName,
  }) {
    final newBatterStats = Map<String, BatterInnings>.from(_state.batterStats);
    newBatterStats[playerId] = BatterInnings(
      playerId: playerId,
      displayName: displayName,
      isOnStrike: _state.strikerId == null,
    );

    if (_state.strikerId == null) {
      _state = _state.copyWith(
        strikerId: playerId,
        batterStats: newBatterStats,
      );
    } else {
      _state = _state.copyWith(
        nonStrikerId: playerId,
        batterStats: newBatterStats,
      );
    }

    if (_state.deliveryHistory.isNotEmpty) {
      _state = _state.copyWith(undoBlockedByTransition: true);
    }
  }

  /// Select a new bowler (at start of over or after wicket).
  void selectNewBowler({
    required String playerId,
    required String displayName,
  }) {
    final newBowlerStats = Map<String, BowlerSpell>.from(_state.bowlerStats);
    if (!newBowlerStats.containsKey(playerId)) {
      newBowlerStats[playerId] = BowlerSpell(
        playerId: playerId,
        displayName: displayName,
      );
    }

    _state = _state.copyWith(
      bowlerId: playerId,
      bowlerStats: newBowlerStats,
    );

    if (_state.deliveryHistory.isNotEmpty) {
      _state = _state.copyWith(undoBlockedByTransition: true);
    }
  }

  // ── Internal pipeline ──

  void _processDelivery({
    int runsFromBat = 0,
    bool isWide = false,
    int wideRuns = 0,
    bool isNoBall = false,
    int noBallRuns = 0,
    bool isBye = false,
    int byeRuns = 0,
    bool isLegBye = false,
    int legByeRuns = 0,
    bool isWicket = false,
    bool isBoundaryFour = false,
    bool isBoundarySix = false,
    bool isPenalty = false,
    WicketInfo? wicketInfo,
  }) {
    if (_state.isInningsComplete) return;

    // Step 1: Determine legal status
    final isLegal = ScoringUtils.isLegalDelivery(
      isWide: isWide,
      isNoBall: isNoBall,
      isPenalty: isPenalty,
    );

    // Step 2: Calculate total runs
    final totalDeliveryRuns = ScoringUtils.calculateTotalRuns(
      runsFromBat: runsFromBat,
      wideRuns: wideRuns,
      noBallRuns: noBallRuns,
      byeRuns: byeRuns,
      legByeRuns: legByeRuns,
    );

    // Step 3: Create delivery record
    final delivery = Delivery(
      id: 'del-${_state.deliveryHistory.length + 1}',
      inningsId: _state.inningsId,
      overNumber: _state.currentOverNumber,
      ballNumber: _state.currentOverBalls + 1,
      sequenceNumber: _state.deliveryHistory.length + 1,
      strikerId: _state.strikerId ?? '',
      nonStrikerId: _state.nonStrikerId ?? '',
      bowlerId: _state.bowlerId ?? '',
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      isNoBall: isNoBall,
      noBallRuns: noBallRuns,
      isBye: isBye,
      byeRuns: byeRuns,
      isLegBye: isLegBye,
      legByeRuns: legByeRuns,
      isWicket: isWicket,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
      isFreeHit: _state.isFreeHitPending,
      isPenalty: isPenalty,
      wicketInfo: wicketInfo,
    );

    // Step 4: Update innings totals
    final newTotalRuns = _state.totalRuns + totalDeliveryRuns;
    final newTotalBalls = _state.totalBalls + (isLegal ? 1 : 0);
    var newTotalExtras = _state.totalExtras;
    var newTotalWides = _state.totalWides;
    var newTotalNoBalls = _state.totalNoBalls;
    var newTotalByes = _state.totalByes;
    var newTotalLegByes = _state.totalLegByes;
    var newTotalWickets = _state.totalWickets;

    if (isWide) {
      newTotalExtras += wideRuns;
      newTotalWides += wideRuns;
    }
    if (isNoBall) {
      newTotalExtras += noBallRuns;
      newTotalNoBalls += noBallRuns;
    }
    if (isBye) {
      newTotalExtras += byeRuns;
      newTotalByes += byeRuns;
    }
    if (isLegBye) {
      newTotalExtras += legByeRuns;
      newTotalLegByes += legByeRuns;
    }
    if (isWicket) newTotalWickets++;

    // Step 5: Update batter stats
    final newBatterStats = Map<String, BatterInnings>.from(_state.batterStats);
    if (_state.strikerId != null && !isWide) {
      final currentBatter = newBatterStats[_state.strikerId!];
      if (currentBatter != null) {
        var updatedBatter = currentBatter;
        if (isLegal) {
          updatedBatter = updatedBatter.copyWith(
            ballsFaced: currentBatter.ballsFaced + 1,
          );
        }
        if (!isBye && !isLegBye) {
          updatedBatter = updatedBatter.copyWith(
            runsScored: currentBatter.runsScored + runsFromBat,
            fours: currentBatter.fours + (isBoundaryFour ? 1 : 0),
            sixes: currentBatter.sixes + (isBoundarySix ? 1 : 0),
          );
        }
        if (isWicket &&
            wicketInfo?.dismissedPlayerId == _state.strikerId) {
          updatedBatter = updatedBatter.copyWith(
            isNotOut: false,
            dismissalType: wicketInfo?.dismissalType,
          );
        }
        newBatterStats[_state.strikerId!] = updatedBatter;
      }
    }

    // Step 6: Update bowler stats
    final newBowlerStats = Map<String, BowlerSpell>.from(_state.bowlerStats);
    if (_state.bowlerId != null) {
      final currentBowler = newBowlerStats[_state.bowlerId!];
      if (currentBowler != null) {
        final bowlerRunsConceded = runsFromBat + wideRuns + noBallRuns;
        newBowlerStats[_state.bowlerId!] = currentBowler.copyWith(
          ballsBowled: currentBowler.ballsBowled + (isLegal ? 1 : 0),
          runsConceded: currentBowler.runsConceded + bowlerRunsConceded,
          wicketsTaken: currentBowler.wicketsTaken +
              (isWicket && (wicketInfo?.bowlerCredited ?? false) ? 1 : 0),
          wides: currentBowler.wides + (isWide ? 1 : 0),
          noBalls: currentBowler.noBalls + (isNoBall ? 1 : 0),
          dotBalls: currentBowler.dotBalls +
              (totalDeliveryRuns == 0 && isLegal ? 1 : 0),
        );
      }
    }

    // Step 7: Calculate strike change
    final shouldSwap = ScoringUtils.shouldSwapStrike(
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      isBye: isBye,
      byeRuns: byeRuns,
      isLegBye: isLegBye,
      legByeRuns: legByeRuns,
    );

    String? newStrikerId = _state.strikerId;
    String? newNonStrikerId = _state.nonStrikerId;

    if (isWicket && wicketInfo != null) {
      // Wicket: mark dismissed, need new batter at striker end
      newStrikerId = null; // Needs new batter selection
      // Keep non-striker as is
    } else if (shouldSwap) {
      final temp = newStrikerId;
      newStrikerId = newNonStrikerId;
      newNonStrikerId = temp;
    }

    // Update on-strike markers
    for (final key in newBatterStats.keys) {
      newBatterStats[key] = newBatterStats[key]!.copyWith(
        isOnStrike: key == newStrikerId,
      );
    }

    // Step 8: Check over completion
    var newCurrentOverBalls = _state.currentOverBalls + (isLegal ? 1 : 0);
    var newCurrentOverDeliveries =
        List<Delivery>.from(_state.currentOverDeliveries)..add(delivery);
    final newCompletedOvers = List<Over>.from(_state.completedOvers);
    String? newLastBowlerId = _state.lastBowlerId;

    final overComplete = ScoringUtils.isOverComplete(newCurrentOverBalls);
    if (overComplete) {
      final isMaiden = ScoringUtils.isMaidenOver(newCurrentOverDeliveries);
      newCompletedOvers.add(Over(
        overNumber: _state.currentOverNumber,
        bowlerId: _state.bowlerId ?? '',
        bowlerName: newBowlerStats[_state.bowlerId]?.displayName ?? '',
        runsConceded: newCurrentOverDeliveries.fold(
          0,
          (sum, d) => sum + d.bowlerRunsConceded,
        ),
        wicketsTaken: newCurrentOverDeliveries.where((d) => d.isWicket).length,
        isMaiden: isMaiden,
        deliveries: List.unmodifiable(newCurrentOverDeliveries),
      ));

      // Update bowler maiden count
      if (isMaiden && _state.bowlerId != null) {
        final bowler = newBowlerStats[_state.bowlerId!];
        if (bowler != null) {
          newBowlerStats[_state.bowlerId!] = bowler.copyWith(
            maidens: bowler.maidens + 1,
          );
        }
      }

      newLastBowlerId = _state.bowlerId;
      newCurrentOverBalls = 0;
      newCurrentOverDeliveries = [];

      // End of over: swap strike (unless wicket already caused null striker)
      if (newStrikerId != null && newNonStrikerId != null) {
        final temp = newStrikerId;
        newStrikerId = newNonStrikerId;
        newNonStrikerId = temp;

        for (final key in newBatterStats.keys) {
          newBatterStats[key] = newBatterStats[key]!.copyWith(
            isOnStrike: key == newStrikerId,
          );
        }
      }

      // Need new bowler
    }

    // Step 9: Determine free hit state
    final newFreeHitPending = ScoringUtils.isNextFreeHit(
      previousWasNoBall: isNoBall,
      previousWasFreeHit: _state.isFreeHitPending,
      previousWasLegal: isLegal,
    );

    // Step 10: Check innings completion
    final completionReason = ScoringUtils.checkInningsCompletion(
      totalWickets: newTotalWickets,
      playersPerSide: _state.playersPerSide,
      totalBalls: newTotalBalls,
      totalOvers: _state.totalOvers,
      totalRuns: newTotalRuns,
      target: _state.target,
      inningsNumber: _state.inningsNumber,
    );

    final isInningsComplete = completionReason != null;
    final isMatchComplete = isInningsComplete && _state.inningsNumber >= 2;

    // Commit state
    _state = _state.copyWith(
      totalRuns: newTotalRuns,
      totalBalls: newTotalBalls,
      totalWickets: newTotalWickets,
      totalExtras: newTotalExtras,
      totalWides: newTotalWides,
      totalNoBalls: newTotalNoBalls,
      totalByes: newTotalByes,
      totalLegByes: newTotalLegByes,
      strikerId: newStrikerId,
      nonStrikerId: newNonStrikerId,
      bowlerId: overComplete ? null : _state.bowlerId,
      batterStats: newBatterStats,
      bowlerStats: newBowlerStats,
      currentOverBalls: newCurrentOverBalls,
      currentOverDeliveries: newCurrentOverDeliveries,
      completedOvers: newCompletedOvers,
      lastBowlerId: newLastBowlerId,
      isFreeHitPending: newFreeHitPending,
      isInningsComplete: isInningsComplete,
      isMatchComplete: isMatchComplete,
      completionReason: completionReason,
      deliveryHistory: [..._state.deliveryHistory, delivery],
      undoBlockedByTransition: false,
    );
  }
}
