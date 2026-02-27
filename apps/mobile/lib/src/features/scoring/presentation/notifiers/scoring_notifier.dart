import 'package:uuid/uuid.dart';

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
    this.magicOverNumbers,
    this.magicOverRunMultiplier = 2,
    this.magicOverWicketPenalty = -5,
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
    // Super over
    this.isKnockoutMatch = false,
    this.isSuperOver = false,
    this.superOverNumber = 0,
    this.needsSuperOver = false,
    this.previousSuperOverBowlerIds = const [],
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
  final List<int>? magicOverNumbers;
  final int magicOverRunMultiplier;
  final int magicOverWicketPenalty;
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

  // ── Super Over ──

  /// Whether this is a knockout/tournament match (enables super over on tie).
  final bool isKnockoutMatch;

  /// Whether this innings is part of a super over.
  final bool isSuperOver;

  /// Current super over number (1-based, 0 = not a super over).
  final int superOverNumber;

  /// Whether the match needs a super over (set when tied knockout).
  final bool needsSuperOver;

  /// Bowler IDs from previous super overs (ineligible for next SO).
  final List<String> previousSuperOverBowlerIds;

  // ── Computed properties ──

  /// Whether the current over is a magic over.
  bool get isMagicOver =>
      magicOverNumbers != null && magicOverNumbers!.contains(currentOverNumber);

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
    bool? isKnockoutMatch,
    bool? isSuperOver,
    int? superOverNumber,
    bool? needsSuperOver,
    List<String>? previousSuperOverBowlerIds,
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
      magicOverNumbers: magicOverNumbers,
      magicOverRunMultiplier: magicOverRunMultiplier,
      magicOverWicketPenalty: magicOverWicketPenalty,
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
      isKnockoutMatch: isKnockoutMatch ?? this.isKnockoutMatch,
      isSuperOver: isSuperOver ?? this.isSuperOver,
      superOverNumber: superOverNumber ?? this.superOverNumber,
      needsSuperOver: needsSuperOver ?? this.needsSuperOver,
      previousSuperOverBowlerIds:
          previousSuperOverBowlerIds ?? this.previousSuperOverBowlerIds,
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
  ScoringNotifier(this._state) {
    // Initialize mutable backing collections from initial state
    _deliveries = List<Delivery>.of(_state.deliveryHistory);
    _batterStats = Map<String, BatterInnings>.of(_state.batterStats);
    _bowlerStats = Map<String, BowlerSpell>.of(_state.bowlerStats);
    _completedOvers = List<Over>.of(_state.completedOvers);
    _currentOverDeliveries = List<Delivery>.of(_state.currentOverDeliveries);
    // Initialize fall-of-wickets cache from existing state
    _cachedFallOfWickets.addAll(_state.fallOfWickets);
  }

  static const _uuid = Uuid();

  ScoringState _state;
  ScoringState get state => _state;

  // ── Mutable backing collections (O(1) mutations instead of O(n) copies) ──
  late List<Delivery> _deliveries;
  late Map<String, BatterInnings> _batterStats;
  late Map<String, BowlerSpell> _bowlerStats;
  late List<Over> _completedOvers;
  late List<Delivery> _currentOverDeliveries;
  final List<FallOfWicket> _cachedFallOfWickets = [];

  /// Cached fall of wickets — maintained incrementally by _processDelivery/undo.
  List<FallOfWicket> get fallOfWickets => List.unmodifiable(_cachedFallOfWickets);

  /// Reinitialize mutable backing fields from current _state.
  /// Called after wholesale state replacement (startSecondInnings, startSuperOver).
  void _reinitMutableFields() {
    _deliveries = List<Delivery>.of(_state.deliveryHistory);
    _batterStats = Map<String, BatterInnings>.of(_state.batterStats);
    _bowlerStats = Map<String, BowlerSpell>.of(_state.bowlerStats);
    _completedOvers = List<Over>.of(_state.completedOvers);
    _currentOverDeliveries = List<Delivery>.of(_state.currentOverDeliveries);
    _cachedFallOfWickets.clear();
  }

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
  ///
  /// Supports optional [byeRuns] or [legByeRuns] for NB+bye/leg-bye combos
  /// (ball doesn't hit bat on a no-ball). Cannot have both bye and leg-bye,
  /// and cannot have bat runs with bye/leg-bye runs simultaneously.
  void recordNoBall({
    int runsFromBat = 0,
    int byeRuns = 0,
    int legByeRuns = 0,
  }) {
    assert(!(byeRuns > 0 && legByeRuns > 0), 'Cannot have both bye and leg-bye');
    assert(!(runsFromBat > 0 && (byeRuns > 0 || legByeRuns > 0)),
        'Cannot have bat runs with bye/leg-bye runs');
    _processDelivery(
      isNoBall: true,
      noBallRuns: _state.noBallRunsPenalty,
      runsFromBat: runsFromBat,
      isBye: byeRuns > 0,
      byeRuns: byeRuns,
      isLegBye: legByeRuns > 0,
      legByeRuns: legByeRuns,
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
    bool isNoBall = false,
    int noBallRuns = 0,
    bool battersCrossed = false,
    bool isDirectHit = false,
  }) {
    final wicketInfo = WicketInfo(
      dismissedPlayerId: dismissedPlayerId,
      dismissalType: dismissalType,
      bowlerCredited: dismissalType.bowlerCredited,
      fielderId: fielderId,
      battersCrossed: battersCrossed,
      isDirectHit: isDirectHit,
    );

    _processDelivery(
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: isWide ? (_state.wideRunsPenalty + wideRuns) : 0,
      isNoBall: isNoBall,
      noBallRuns: isNoBall ? (_state.noBallRunsPenalty + noBallRuns) : 0,
      isWicket: true,
      wicketInfo: wicketInfo,
    );
  }

  /// Undo the last delivery.
  void undoLastDelivery() {
    if (!_state.canUndo) return;

    final lastDel = _deliveries.last;
    _deliveries.removeLast();

    // Reverse fall-of-wickets cache
    if (lastDel.isWicket && _cachedFallOfWickets.isNotEmpty) {
      _cachedFallOfWickets.removeLast();
    }

    // Reverse innings totals (also reverse magic over wicket penalty)
    final newTotalRuns = _state.totalRuns - lastDel.totalRuns - lastDel.magicOverPenaltyApplied;
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
    if (lastDel.isWicket &&
        (lastDel.wicketInfo?.dismissalType.isRealWicket ?? true)) {
      newTotalWickets--;
    }

    // Reverse batter stats
    final strikerStats = _batterStats[lastDel.strikerId];
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
        if (lastDel.wicketInfo?.dismissalType == DismissalType.retiredHurt) {
          updatedBatter = updatedBatter.copyWith(isRetiredHurt: false);
        } else {
          updatedBatter = updatedBatter.copyWith(isNotOut: true);
        }
      }
      _batterStats[lastDel.strikerId] = updatedBatter;
    }

    // Reverse bowler stats
    final bowlerStat = _bowlerStats[lastDel.bowlerId];
    if (bowlerStat != null) {
      _bowlerStats[lastDel.bowlerId] = bowlerStat.copyWith(
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

    // Reverse strike change — use original (pre-multiplied) runs for magic over
    final undoMultiplier = lastDel.isMagicOverDelivery ? _state.magicOverRunMultiplier : 1;
    final undoRunsFromBat = lastDel.isMagicOverDelivery && lastDel.runsFromBat > 0
        ? lastDel.runsFromBat ~/ undoMultiplier
        : lastDel.runsFromBat;
    final undoWideRuns = lastDel.isMagicOverDelivery && lastDel.wideRuns > 0
        ? lastDel.wideRuns ~/ undoMultiplier
        : lastDel.wideRuns;
    final undoByeRuns = lastDel.isMagicOverDelivery && lastDel.byeRuns > 0
        ? lastDel.byeRuns ~/ undoMultiplier
        : lastDel.byeRuns;
    final undoLegByeRuns = lastDel.isMagicOverDelivery && lastDel.legByeRuns > 0
        ? lastDel.legByeRuns ~/ undoMultiplier
        : lastDel.legByeRuns;
    final shouldHaveSwapped = ScoringUtils.shouldSwapStrike(
      runsFromBat: undoRunsFromBat,
      isWide: lastDel.isWide,
      wideRuns: undoWideRuns,
      isBye: lastDel.isBye,
      byeRuns: undoByeRuns,
      isLegBye: lastDel.isLegBye,
      legByeRuns: undoLegByeRuns,
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
    for (final key in _batterStats.keys) {
      _batterStats[key] = _batterStats[key]!.copyWith(
        isOnStrike: key == newStrikerId,
      );
    }

    // Reverse over state
    var newCurrentOverBalls = _state.currentOverBalls;

    if (_currentOverDeliveries.isNotEmpty &&
        _currentOverDeliveries.last.id == lastDel.id) {
      _currentOverDeliveries.removeLast();
    }
    if (lastDel.isLegal) newCurrentOverBalls--;

    // If we're undoing the first ball of a new over, reopen previous over
    // Use sentinels to track whether we need to restore bowler state
    String? restoredBowlerId;
    String? restoredLastBowlerId;
    bool overReopened = false;

    if (newCurrentOverBalls < 0 && _completedOvers.isNotEmpty) {
      final previousOver = _completedOvers.removeLast();
      _currentOverDeliveries = List<Delivery>.of(previousOver.deliveries);
      newCurrentOverBalls = previousOver.legalBalls - 1;
      if (_currentOverDeliveries.isNotEmpty) {
        _currentOverDeliveries.removeLast();
      }

      overReopened = true;

      // FIX 1: Restore bowlerId from reopened over
      restoredBowlerId = previousOver.bowlerId;

      // FIX 2: Restore lastBowlerId from the over before this one
      restoredLastBowlerId = _completedOvers.isNotEmpty
          ? _completedOvers.last.bowlerId
          : null;

      // FIX 3: Reverse maiden count if the reopened over was maiden
      if (previousOver.isMaiden) {
        final bowler = _bowlerStats[previousOver.bowlerId];
        if (bowler != null) {
          _bowlerStats[previousOver.bowlerId] = bowler.copyWith(
            maidens: bowler.maidens - 1,
          );
        }
      }
    }

    // Determine free hit state from previous delivery in history
    bool newFreeHitPending = false;
    if (_deliveries.isNotEmpty) {
      final prevDel = _deliveries.last;
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
      batterStats: _batterStats,
      bowlerStats: _bowlerStats,
      currentOverBalls: newCurrentOverBalls,
      currentOverDeliveries: _currentOverDeliveries,
      completedOvers: _completedOvers,
      isFreeHitPending: newFreeHitPending,
      deliveryHistory: _deliveries,
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
      magicOverNumbers: _state.magicOverNumbers,
      magicOverRunMultiplier: _state.magicOverRunMultiplier,
      magicOverWicketPenalty: _state.magicOverWicketPenalty,
      target: target,
      firstInningsSummary: firstSummary,
      firstInnings: firstInningsData,
    );
    _reinitMutableFields();

    // Set up opening players
    selectNewBatter(playerId: strikerId, displayName: strikerName);
    selectNewBatter(playerId: nonStrikerId, displayName: nonStrikerName);
    selectNewBowler(playerId: bowlerId, displayName: bowlerName);
  }

  /// Manually swap strike (UI button).
  void swapStrike() {
    if (_state.strikerId == null || _state.nonStrikerId == null) return;

    final oldStrikerId = _state.strikerId!;
    final oldNonStrikerId = _state.nonStrikerId!;

    if (_batterStats.containsKey(oldStrikerId)) {
      _batterStats[oldStrikerId] =
          _batterStats[oldStrikerId]!.copyWith(isOnStrike: false);
    }
    if (_batterStats.containsKey(oldNonStrikerId)) {
      _batterStats[oldNonStrikerId] =
          _batterStats[oldNonStrikerId]!.copyWith(isOnStrike: true);
    }

    _state = _state.copyWith(
      strikerId: oldNonStrikerId,
      nonStrikerId: oldStrikerId,
      batterStats: _batterStats,
    );
  }

  /// Select a new batter (after wicket or to start).
  /// If the player was retired hurt, their stats are preserved.
  void selectNewBatter({
    required String playerId,
    required String displayName,
  }) {
    final existing = _batterStats[playerId];

    if (existing != null && existing.canReturn) {
      // Returning retired-hurt batter: preserve stats, clear retired flag
      _batterStats[playerId] = existing.copyWith(
        isRetiredHurt: false,
        isOnStrike: _state.strikerId == null,
      );
    } else {
      _batterStats[playerId] = BatterInnings(
        playerId: playerId,
        displayName: displayName,
        isOnStrike: _state.strikerId == null,
      );
    }

    if (_state.strikerId == null) {
      _state = _state.copyWith(
        strikerId: playerId,
        batterStats: _batterStats,
      );
    } else {
      _state = _state.copyWith(
        nonStrikerId: playerId,
        batterStats: _batterStats,
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
    if (!_bowlerStats.containsKey(playerId)) {
      _bowlerStats[playerId] = BowlerSpell(
        playerId: playerId,
        displayName: displayName,
      );
    }

    _state = _state.copyWith(
      bowlerId: playerId,
      bowlerStats: _bowlerStats,
    );

    if (_state.deliveryHistory.isNotEmpty) {
      _state = _state.copyWith(undoBlockedByTransition: true);
    }
  }

  /// Start a super over after a tied knockout match.
  ///
  /// Resets state for a 1-over, 3-player (2 wickets = all out) mini-match.
  /// The team that batted second in the main match bats first in the SO.
  void startSuperOver({
    required String strikerId,
    required String strikerName,
    required String nonStrikerId,
    required String nonStrikerName,
    required String bowlerId,
    required String bowlerName,
  }) {
    if (!_state.needsSuperOver && !_state.isMatchComplete) return;

    final newSuperOverNumber = _state.superOverNumber + 1;
    final prevBowlerIds = [..._state.previousSuperOverBowlerIds];
    if (_state.bowlerId != null && _state.isSuperOver) {
      prevBowlerIds.add(_state.bowlerId!);
    }

    // Capture current innings summary for the SO
    final firstSummary = FirstInningsSummary(
      teamName: _state.battingTeamName,
      teamId: _state.battingTeamId,
      totalRuns: _state.totalRuns,
      totalWickets: _state.totalWickets,
      totalBalls: _state.totalBalls,
      oversDisplay: _state.oversDisplay,
    );

    _state = ScoringState(
      matchId: _state.matchId,
      inningsId: '${_state.matchId}-so$newSuperOverNumber-1',
      battingTeamId: _state.bowlingTeamId,
      bowlingTeamId: _state.battingTeamId,
      battingTeamName: _state.bowlingTeamName,
      bowlingTeamName: _state.battingTeamName,
      battingTeamPlayers: _state.bowlingTeamPlayers,
      bowlingTeamPlayers: _state.battingTeamPlayers,
      inningsNumber: 1,
      totalOvers: 1,
      playersPerSide: 3, // 2 wickets = all out
      wideRunsPenalty: _state.wideRunsPenalty,
      noBallRunsPenalty: _state.noBallRunsPenalty,
      isKnockoutMatch: true,
      isSuperOver: true,
      superOverNumber: newSuperOverNumber,
      previousSuperOverBowlerIds: prevBowlerIds,
      firstInningsSummary: firstSummary,
    );
    _reinitMutableFields();

    // Set up opening players
    selectNewBatter(playerId: strikerId, displayName: strikerName);
    selectNewBatter(playerId: nonStrikerId, displayName: nonStrikerName);
    selectNewBowler(playerId: bowlerId, displayName: bowlerName);
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
    var totalDeliveryRuns = ScoringUtils.calculateTotalRuns(
      runsFromBat: runsFromBat,
      wideRuns: wideRuns,
      noBallRuns: noBallRuns,
      byeRuns: byeRuns,
      legByeRuns: legByeRuns,
    );

    // Step 2.5: Magic Over — configurable multiplier
    final isMagicOver = _state.isMagicOver;
    final multiplier = isMagicOver ? _state.magicOverRunMultiplier : 1;
    if (isMagicOver && totalDeliveryRuns > 0) {
      totalDeliveryRuns *= multiplier;
    }

    // Multiplied individual components for stats
    final effectiveRunsFromBat = isMagicOver && runsFromBat > 0
        ? runsFromBat * multiplier
        : runsFromBat;
    final effectiveWideRuns = isMagicOver && wideRuns > 0
        ? wideRuns * multiplier
        : wideRuns;
    final effectiveNoBallRuns = isMagicOver && noBallRuns > 0
        ? noBallRuns * multiplier
        : noBallRuns;
    final effectiveByeRuns = isMagicOver && byeRuns > 0
        ? byeRuns * multiplier
        : byeRuns;
    final effectiveLegByeRuns = isMagicOver && legByeRuns > 0
        ? legByeRuns * multiplier
        : legByeRuns;

    // Step 3: Create delivery record (stores doubled values for correct undo)
    final delivery = Delivery(
      id: _uuid.v4(),
      inningsId: _state.inningsId,
      overNumber: _state.currentOverNumber,
      ballNumber: _state.currentOverBalls + 1,
      sequenceNumber: _state.deliveryHistory.length + 1,
      strikerId: _state.strikerId ?? '',
      nonStrikerId: _state.nonStrikerId ?? '',
      bowlerId: _state.bowlerId ?? '',
      runsFromBat: effectiveRunsFromBat,
      isWide: isWide,
      wideRuns: effectiveWideRuns,
      isNoBall: isNoBall,
      noBallRuns: effectiveNoBallRuns,
      isBye: isBye,
      byeRuns: effectiveByeRuns,
      isLegBye: isLegBye,
      legByeRuns: effectiveLegByeRuns,
      isWicket: isWicket,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
      isFreeHit: _state.isFreeHitPending,
      isPenalty: isPenalty,
      isMagicOverDelivery: isMagicOver,
      magicOverPenaltyApplied: isMagicOver && isWicket ? _state.magicOverWicketPenalty : 0,
      wicketInfo: wicketInfo,
    );

    // Step 4: Update innings totals
    // Apply magic over wicket penalty (negative value deducted from total)
    final magicOverPenalty = isMagicOver && isWicket ? _state.magicOverWicketPenalty : 0;
    final newTotalRuns = _state.totalRuns + totalDeliveryRuns + magicOverPenalty;
    final newTotalBalls = _state.totalBalls + (isLegal ? 1 : 0);
    var newTotalExtras = _state.totalExtras;
    var newTotalWides = _state.totalWides;
    var newTotalNoBalls = _state.totalNoBalls;
    var newTotalByes = _state.totalByes;
    var newTotalLegByes = _state.totalLegByes;
    var newTotalWickets = _state.totalWickets;

    if (isWide) {
      newTotalExtras += effectiveWideRuns;
      newTotalWides += effectiveWideRuns;
    }
    if (isNoBall) {
      newTotalExtras += effectiveNoBallRuns;
      newTotalNoBalls += effectiveNoBallRuns;
    }
    if (isBye) {
      newTotalExtras += effectiveByeRuns;
      newTotalByes += effectiveByeRuns;
    }
    if (isLegBye) {
      newTotalExtras += effectiveLegByeRuns;
      newTotalLegByes += effectiveLegByeRuns;
    }
    if (isWicket && (wicketInfo?.dismissalType.isRealWicket ?? true)) {
      newTotalWickets++;
    }

    // Step 4.5: Update fall-of-wickets cache
    if (isWicket) {
      final dismissedId = wicketInfo?.dismissedPlayerId ?? _state.strikerId ?? '';
      final dismissedName =
          _batterStats[dismissedId]?.displayName ?? dismissedId;
      _cachedFallOfWickets.add(FallOfWicket(
        wicketNumber: _cachedFallOfWickets.length + 1,
        scoreAtFall: newTotalRuns,
        oversAtFall: CricketUtils.formatOvers(newTotalBalls),
        dismissedPlayerName: dismissedName,
      ));
    }

    // Step 5: Update batter stats (mutate in place)
    if (_state.strikerId != null && !isWide) {
      final currentBatter = _batterStats[_state.strikerId!];
      if (currentBatter != null) {
        var updatedBatter = currentBatter;
        if (isLegal) {
          updatedBatter = updatedBatter.copyWith(
            ballsFaced: currentBatter.ballsFaced + 1,
          );
        }
        if (!isBye && !isLegBye) {
          updatedBatter = updatedBatter.copyWith(
            runsScored: currentBatter.runsScored + effectiveRunsFromBat,
            fours: currentBatter.fours + (isBoundaryFour ? 1 : 0),
            sixes: currentBatter.sixes + (isBoundarySix ? 1 : 0),
          );
        }
        if (isWicket &&
            wicketInfo?.dismissedPlayerId == _state.strikerId) {
          if (wicketInfo?.dismissalType == DismissalType.retiredHurt) {
            updatedBatter = updatedBatter.copyWith(
              isRetiredHurt: true,
              dismissalType: wicketInfo?.dismissalType,
            );
          } else {
            updatedBatter = updatedBatter.copyWith(
              isNotOut: false,
              dismissalType: wicketInfo?.dismissalType,
            );
          }
        }
        _batterStats[_state.strikerId!] = updatedBatter;
      }
    }

    // Step 6: Update bowler stats (mutate in place)
    if (_state.bowlerId != null) {
      final currentBowler = _bowlerStats[_state.bowlerId!];
      if (currentBowler != null) {
        final bowlerRunsConceded = effectiveRunsFromBat + effectiveWideRuns + effectiveNoBallRuns;
        _bowlerStats[_state.bowlerId!] = currentBowler.copyWith(
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
    for (final key in _batterStats.keys) {
      _batterStats[key] = _batterStats[key]!.copyWith(
        isOnStrike: key == newStrikerId,
      );
    }

    // Step 8: Check over completion (mutate in place)
    var newCurrentOverBalls = _state.currentOverBalls + (isLegal ? 1 : 0);
    _currentOverDeliveries.add(delivery);
    String? newLastBowlerId = _state.lastBowlerId;

    final overComplete = ScoringUtils.isOverComplete(newCurrentOverBalls);
    if (overComplete) {
      final isMaiden = ScoringUtils.isMaidenOver(_currentOverDeliveries);
      _completedOvers.add(Over(
        overNumber: _state.currentOverNumber,
        bowlerId: _state.bowlerId ?? '',
        bowlerName: _bowlerStats[_state.bowlerId]?.displayName ?? '',
        runsConceded: _currentOverDeliveries.fold(
          0,
          (sum, d) => sum + d.bowlerRunsConceded,
        ),
        wicketsTaken: _currentOverDeliveries.where((d) => d.isWicket).length,
        isMaiden: isMaiden,
        deliveries: List.unmodifiable(_currentOverDeliveries),
      ));

      // Update bowler maiden count
      if (isMaiden && _state.bowlerId != null) {
        final bowler = _bowlerStats[_state.bowlerId!];
        if (bowler != null) {
          _bowlerStats[_state.bowlerId!] = bowler.copyWith(
            maidens: bowler.maidens + 1,
          );
        }
      }

      newLastBowlerId = _state.bowlerId;
      newCurrentOverBalls = 0;
      _currentOverDeliveries = [];

      // End of over: swap strike (unless wicket already caused null striker)
      if (newStrikerId != null && newNonStrikerId != null) {
        final temp = newStrikerId;
        newStrikerId = newNonStrikerId;
        newNonStrikerId = temp;

        for (final key in _batterStats.keys) {
          _batterStats[key] = _batterStats[key]!.copyWith(
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
    var isMatchComplete = isInningsComplete && _state.inningsNumber >= 2;

    // Check for super over: if match is complete, it's a tie, and knockout
    bool triggerSuperOver = false;
    if (isMatchComplete && _state.isKnockoutMatch && _state.firstInningsSummary != null) {
      final firstRuns = _state.firstInningsSummary!.totalRuns;
      if (newTotalRuns == firstRuns) {
        // Tie in a knockout — need super over instead of completing
        triggerSuperOver = true;
        isMatchComplete = false;
      }
    }

    // Append to delivery history (O(1) amortized)
    _deliveries.add(delivery);

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
      batterStats: _batterStats,
      bowlerStats: _bowlerStats,
      currentOverBalls: newCurrentOverBalls,
      currentOverDeliveries: _currentOverDeliveries,
      completedOvers: _completedOvers,
      lastBowlerId: newLastBowlerId,
      isFreeHitPending: newFreeHitPending,
      isInningsComplete: isInningsComplete,
      isMatchComplete: isMatchComplete,
      completionReason: completionReason,
      deliveryHistory: _deliveries,
      undoBlockedByTransition: false,
      needsSuperOver: triggerSuperOver,
    );
  }
}
