import 'dart:convert';

import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/bowler_spell.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/innings_data.dart';
import '../../domain/entities/over.dart';
import '../../domain/entities/playing_xi_player.dart';
import '../../domain/entities/wicket_info.dart';
import '../../presentation/notifiers/scoring_notifier.dart';

/// Serialize a [ScoringState] to a JSON string.
String scoringStateToJsonString(ScoringState state) {
  return jsonEncode(_scoringStateToMap(state));
}

/// Deserialize a JSON string back to [ScoringState].
ScoringState scoringStateFromJsonString(String jsonString) {
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  return _scoringStateFromMap(map);
}

// ── ScoringState ──

Map<String, dynamic> _scoringStateToMap(ScoringState state) {
  return {
    'matchId': state.matchId,
    'inningsId': state.inningsId,
    'battingTeamId': state.battingTeamId,
    'bowlingTeamId': state.bowlingTeamId,
    'inningsNumber': state.inningsNumber,
    'totalOvers': state.totalOvers,
    'playersPerSide': state.playersPerSide,
    'wideRunsPenalty': state.wideRunsPenalty,
    'noBallRunsPenalty': state.noBallRunsPenalty,
    'magicOverNumbers': state.magicOverNumbers,
    'magicOverRunMultiplier': state.magicOverRunMultiplier,
    'magicOverWicketPenalty': state.magicOverWicketPenalty,
    'battingTeamName': state.battingTeamName,
    'bowlingTeamName': state.bowlingTeamName,
    'battingTeamPlayers':
        state.battingTeamPlayers.map(_playingXIPlayerToMap).toList(),
    'bowlingTeamPlayers':
        state.bowlingTeamPlayers.map(_playingXIPlayerToMap).toList(),
    'maxOversPerBowler': state.maxOversPerBowler,
    'strikerId': state.strikerId,
    'nonStrikerId': state.nonStrikerId,
    'bowlerId': state.bowlerId,
    'totalRuns': state.totalRuns,
    'totalWickets': state.totalWickets,
    'totalBalls': state.totalBalls,
    'totalExtras': state.totalExtras,
    'totalWides': state.totalWides,
    'totalNoBalls': state.totalNoBalls,
    'totalByes': state.totalByes,
    'totalLegByes': state.totalLegByes,
    'target': state.target,
    'isFreeHitPending': state.isFreeHitPending,
    'currentOverBalls': state.currentOverBalls,
    'currentOverDeliveries':
        state.currentOverDeliveries.map(_deliveryToMap).toList(),
    'completedOvers': state.completedOvers.map(_overToMap).toList(),
    'batterStats': state.batterStats.map(
      (k, v) => MapEntry(k, _batterInningsToMap(v)),
    ),
    'bowlerStats': state.bowlerStats.map(
      (k, v) => MapEntry(k, _bowlerSpellToMap(v)),
    ),
    'lastBowlerId': state.lastBowlerId,
    'isInningsComplete': state.isInningsComplete,
    'isMatchComplete': state.isMatchComplete,
    'completionReason': state.completionReason?.apiValue,
    'isProcessing': state.isProcessing,
    'error': state.error,
    'deliveryHistory': state.deliveryHistory.map(_deliveryToMap).toList(),
    'undoBlockedByTransition': state.undoBlockedByTransition,
    'firstInningsSummary': state.firstInningsSummary != null
        ? _firstInningsSummaryToMap(state.firstInningsSummary!)
        : null,
    'firstInnings': state.firstInnings != null
        ? _inningsDataToMap(state.firstInnings!)
        : null,
  };
}

ScoringState _scoringStateFromMap(Map<String, dynamic> m) {
  return ScoringState(
    matchId: m['matchId'] as String,
    inningsId: m['inningsId'] as String,
    battingTeamId: m['battingTeamId'] as String,
    bowlingTeamId: m['bowlingTeamId'] as String,
    inningsNumber: m['inningsNumber'] as int,
    totalOvers: m['totalOvers'] as int,
    playersPerSide: m['playersPerSide'] as int,
    wideRunsPenalty: m['wideRunsPenalty'] as int? ?? 1,
    noBallRunsPenalty: m['noBallRunsPenalty'] as int? ?? 1,
    magicOverNumbers: m['magicOverNumbers'] != null
        ? (m['magicOverNumbers'] as List<dynamic>).map((e) => e as int).toList()
        : m['magicOverNumber'] != null ? [m['magicOverNumber'] as int] : null,
    magicOverRunMultiplier: m['magicOverRunMultiplier'] as int? ?? 2,
    magicOverWicketPenalty: m['magicOverWicketPenalty'] as int? ?? -5,
    battingTeamName: m['battingTeamName'] as String? ?? '',
    bowlingTeamName: m['bowlingTeamName'] as String? ?? '',
    battingTeamPlayers: (m['battingTeamPlayers'] as List<dynamic>?)
            ?.map((e) => _playingXIPlayerFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    bowlingTeamPlayers: (m['bowlingTeamPlayers'] as List<dynamic>?)
            ?.map((e) => _playingXIPlayerFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    maxOversPerBowler: m['maxOversPerBowler'] as int?,
    strikerId: m['strikerId'] as String?,
    nonStrikerId: m['nonStrikerId'] as String?,
    bowlerId: m['bowlerId'] as String?,
    totalRuns: m['totalRuns'] as int? ?? 0,
    totalWickets: m['totalWickets'] as int? ?? 0,
    totalBalls: m['totalBalls'] as int? ?? 0,
    totalExtras: m['totalExtras'] as int? ?? 0,
    totalWides: m['totalWides'] as int? ?? 0,
    totalNoBalls: m['totalNoBalls'] as int? ?? 0,
    totalByes: m['totalByes'] as int? ?? 0,
    totalLegByes: m['totalLegByes'] as int? ?? 0,
    target: m['target'] as int?,
    isFreeHitPending: m['isFreeHitPending'] as bool? ?? false,
    currentOverBalls: m['currentOverBalls'] as int? ?? 0,
    currentOverDeliveries: (m['currentOverDeliveries'] as List<dynamic>?)
            ?.map((e) => _deliveryFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    completedOvers: (m['completedOvers'] as List<dynamic>?)
            ?.map((e) => _overFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    batterStats: (m['batterStats'] as Map<String, dynamic>?)?.map(
          (k, v) =>
              MapEntry(k, _batterInningsFromMap(v as Map<String, dynamic>)),
        ) ??
        {},
    bowlerStats: (m['bowlerStats'] as Map<String, dynamic>?)?.map(
          (k, v) =>
              MapEntry(k, _bowlerSpellFromMap(v as Map<String, dynamic>)),
        ) ??
        {},
    lastBowlerId: m['lastBowlerId'] as String?,
    isInningsComplete: m['isInningsComplete'] as bool? ?? false,
    isMatchComplete: m['isMatchComplete'] as bool? ?? false,
    completionReason: m['completionReason'] != null
        ? InningsCompletionReason.fromApiValue(m['completionReason'] as String)
        : null,
    isProcessing: m['isProcessing'] as bool? ?? false,
    error: m['error'] as String?,
    deliveryHistory: (m['deliveryHistory'] as List<dynamic>?)
            ?.map((e) => _deliveryFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    undoBlockedByTransition: m['undoBlockedByTransition'] as bool? ?? false,
    firstInningsSummary: m['firstInningsSummary'] != null
        ? _firstInningsSummaryFromMap(
            m['firstInningsSummary'] as Map<String, dynamic>)
        : null,
    firstInnings: m['firstInnings'] != null
        ? _inningsDataFromMap(m['firstInnings'] as Map<String, dynamic>)
        : null,
  );
}

// ── PlayingXIPlayer ──

Map<String, dynamic> _playingXIPlayerToMap(PlayingXIPlayer p) {
  return {
    'playerId': p.playerId,
    'displayName': p.displayName,
    'playerRole': p.playerRole,
    'battingStyle': p.battingStyle,
    'bowlingStyle': p.bowlingStyle,
    'isCaptain': p.isCaptain,
    'isKeeper': p.isKeeper,
  };
}

PlayingXIPlayer _playingXIPlayerFromMap(Map<String, dynamic> m) {
  return PlayingXIPlayer(
    playerId: m['playerId'] as String,
    displayName: m['displayName'] as String,
    playerRole: m['playerRole'] as String?,
    battingStyle: m['battingStyle'] as String?,
    bowlingStyle: m['bowlingStyle'] as String?,
    isCaptain: m['isCaptain'] as bool? ?? false,
    isKeeper: m['isKeeper'] as bool? ?? false,
  );
}

// ── Delivery ──

Map<String, dynamic> _deliveryToMap(Delivery d) {
  return {
    'id': d.id,
    'inningsId': d.inningsId,
    'overNumber': d.overNumber,
    'ballNumber': d.ballNumber,
    'sequenceNumber': d.sequenceNumber,
    'strikerId': d.strikerId,
    'nonStrikerId': d.nonStrikerId,
    'bowlerId': d.bowlerId,
    'runsFromBat': d.runsFromBat,
    'isWide': d.isWide,
    'wideRuns': d.wideRuns,
    'isNoBall': d.isNoBall,
    'noBallRuns': d.noBallRuns,
    'isBye': d.isBye,
    'byeRuns': d.byeRuns,
    'isLegBye': d.isLegBye,
    'legByeRuns': d.legByeRuns,
    'isWicket': d.isWicket,
    'isBoundaryFour': d.isBoundaryFour,
    'isBoundarySix': d.isBoundarySix,
    'isFreeHit': d.isFreeHit,
    'isPenalty': d.isPenalty,
    'isMagicOverDelivery': d.isMagicOverDelivery,
    'magicOverPenaltyApplied': d.magicOverPenaltyApplied,
    'wicketInfo':
        d.wicketInfo != null ? _wicketInfoToMap(d.wicketInfo!) : null,
    'timestamp': d.timestamp.millisecondsSinceEpoch,
  };
}

Delivery _deliveryFromMap(Map<String, dynamic> m) {
  return Delivery(
    id: m['id'] as String,
    inningsId: m['inningsId'] as String,
    overNumber: m['overNumber'] as int,
    ballNumber: m['ballNumber'] as int,
    sequenceNumber: m['sequenceNumber'] as int,
    strikerId: m['strikerId'] as String,
    nonStrikerId: m['nonStrikerId'] as String,
    bowlerId: m['bowlerId'] as String,
    runsFromBat: m['runsFromBat'] as int? ?? 0,
    isWide: m['isWide'] as bool? ?? false,
    wideRuns: m['wideRuns'] as int? ?? 0,
    isNoBall: m['isNoBall'] as bool? ?? false,
    noBallRuns: m['noBallRuns'] as int? ?? 0,
    isBye: m['isBye'] as bool? ?? false,
    byeRuns: m['byeRuns'] as int? ?? 0,
    isLegBye: m['isLegBye'] as bool? ?? false,
    legByeRuns: m['legByeRuns'] as int? ?? 0,
    isWicket: m['isWicket'] as bool? ?? false,
    isBoundaryFour: m['isBoundaryFour'] as bool? ?? false,
    isBoundarySix: m['isBoundarySix'] as bool? ?? false,
    isFreeHit: m['isFreeHit'] as bool? ?? false,
    isPenalty: m['isPenalty'] as bool? ?? false,
    isMagicOverDelivery: m['isMagicOverDelivery'] as bool? ?? false,
    magicOverPenaltyApplied: m['magicOverPenaltyApplied'] as int? ?? 0,
    wicketInfo: m['wicketInfo'] != null
        ? _wicketInfoFromMap(m['wicketInfo'] as Map<String, dynamic>)
        : null,
    timestamp: m['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int)
        : null,
  );
}

// ── WicketInfo ──

Map<String, dynamic> _wicketInfoToMap(WicketInfo w) {
  return {
    'dismissedPlayerId': w.dismissedPlayerId,
    'dismissalType': w.dismissalType.id,
    'bowlerCredited': w.bowlerCredited,
    'fielderId': w.fielderId,
    'battersCrossed': w.battersCrossed,
  };
}

WicketInfo _wicketInfoFromMap(Map<String, dynamic> m) {
  return WicketInfo(
    dismissedPlayerId: m['dismissedPlayerId'] as String,
    dismissalType: DismissalType.fromId(m['dismissalType'] as int),
    bowlerCredited: m['bowlerCredited'] as bool,
    fielderId: m['fielderId'] as String?,
    battersCrossed: m['battersCrossed'] as bool?,
  );
}

// ── BatterInnings ──

Map<String, dynamic> _batterInningsToMap(BatterInnings b) {
  return {
    'playerId': b.playerId,
    'displayName': b.displayName,
    'runsScored': b.runsScored,
    'ballsFaced': b.ballsFaced,
    'fours': b.fours,
    'sixes': b.sixes,
    'isNotOut': b.isNotOut,
    'isOnStrike': b.isOnStrike,
    'isRetiredHurt': b.isRetiredHurt,
    'dismissalType': b.dismissalType?.id,
    'dismissedByName': b.dismissedByName,
    'fielderName': b.fielderName,
  };
}

BatterInnings _batterInningsFromMap(Map<String, dynamic> m) {
  return BatterInnings(
    playerId: m['playerId'] as String,
    displayName: m['displayName'] as String,
    runsScored: m['runsScored'] as int? ?? 0,
    ballsFaced: m['ballsFaced'] as int? ?? 0,
    fours: m['fours'] as int? ?? 0,
    sixes: m['sixes'] as int? ?? 0,
    isNotOut: m['isNotOut'] as bool? ?? true,
    isOnStrike: m['isOnStrike'] as bool? ?? false,
    isRetiredHurt: m['isRetiredHurt'] as bool? ?? false,
    dismissalType: m['dismissalType'] != null
        ? DismissalType.fromId(m['dismissalType'] as int)
        : null,
    dismissedByName: m['dismissedByName'] as String?,
    fielderName: m['fielderName'] as String?,
  );
}

// ── BowlerSpell ──

Map<String, dynamic> _bowlerSpellToMap(BowlerSpell b) {
  return {
    'playerId': b.playerId,
    'displayName': b.displayName,
    'ballsBowled': b.ballsBowled,
    'maidens': b.maidens,
    'runsConceded': b.runsConceded,
    'wicketsTaken': b.wicketsTaken,
    'wides': b.wides,
    'noBalls': b.noBalls,
    'dotBalls': b.dotBalls,
  };
}

BowlerSpell _bowlerSpellFromMap(Map<String, dynamic> m) {
  return BowlerSpell(
    playerId: m['playerId'] as String,
    displayName: m['displayName'] as String,
    ballsBowled: m['ballsBowled'] as int? ?? 0,
    maidens: m['maidens'] as int? ?? 0,
    runsConceded: m['runsConceded'] as int? ?? 0,
    wicketsTaken: m['wicketsTaken'] as int? ?? 0,
    wides: m['wides'] as int? ?? 0,
    noBalls: m['noBalls'] as int? ?? 0,
    dotBalls: m['dotBalls'] as int? ?? 0,
  );
}

// ── Over ──

Map<String, dynamic> _overToMap(Over o) {
  return {
    'overNumber': o.overNumber,
    'bowlerId': o.bowlerId,
    'bowlerName': o.bowlerName,
    'runsConceded': o.runsConceded,
    'wicketsTaken': o.wicketsTaken,
    'isMaiden': o.isMaiden,
    'deliveries': o.deliveries.map(_deliveryToMap).toList(),
  };
}

Over _overFromMap(Map<String, dynamic> m) {
  return Over(
    overNumber: m['overNumber'] as int,
    bowlerId: m['bowlerId'] as String,
    bowlerName: m['bowlerName'] as String,
    runsConceded: m['runsConceded'] as int? ?? 0,
    wicketsTaken: m['wicketsTaken'] as int? ?? 0,
    isMaiden: m['isMaiden'] as bool? ?? false,
    deliveries: (m['deliveries'] as List<dynamic>?)
            ?.map((e) => _deliveryFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// ── FirstInningsSummary ──

Map<String, dynamic> _firstInningsSummaryToMap(FirstInningsSummary s) {
  return {
    'teamName': s.teamName,
    'teamId': s.teamId,
    'totalRuns': s.totalRuns,
    'totalWickets': s.totalWickets,
    'totalBalls': s.totalBalls,
    'oversDisplay': s.oversDisplay,
  };
}

FirstInningsSummary _firstInningsSummaryFromMap(Map<String, dynamic> m) {
  return FirstInningsSummary(
    teamName: m['teamName'] as String,
    teamId: m['teamId'] as String,
    totalRuns: m['totalRuns'] as int,
    totalWickets: m['totalWickets'] as int,
    totalBalls: m['totalBalls'] as int,
    oversDisplay: m['oversDisplay'] as String,
  );
}

// ── InningsData ──

Map<String, dynamic> _inningsDataToMap(InningsData d) {
  return {
    'teamName': d.teamName,
    'teamId': d.teamId,
    'totalRuns': d.totalRuns,
    'totalWickets': d.totalWickets,
    'totalBalls': d.totalBalls,
    'totalWides': d.totalWides,
    'totalNoBalls': d.totalNoBalls,
    'totalByes': d.totalByes,
    'totalLegByes': d.totalLegByes,
    'totalExtras': d.totalExtras,
    'batterStats': d.batterStats.map(
      (k, v) => MapEntry(k, _batterInningsToMap(v)),
    ),
    'bowlerStats': d.bowlerStats.map(
      (k, v) => MapEntry(k, _bowlerSpellToMap(v)),
    ),
    'fallOfWickets': d.fallOfWickets.map(_fallOfWicketToMap).toList(),
    'deliveryHistory': d.deliveryHistory.map(_deliveryToMap).toList(),
    'battingTeamPlayers':
        d.battingTeamPlayers.map(_playingXIPlayerToMap).toList(),
    'bowlingTeamPlayers':
        d.bowlingTeamPlayers.map(_playingXIPlayerToMap).toList(),
  };
}

InningsData _inningsDataFromMap(Map<String, dynamic> m) {
  return InningsData(
    teamName: m['teamName'] as String,
    teamId: m['teamId'] as String,
    totalRuns: m['totalRuns'] as int,
    totalWickets: m['totalWickets'] as int,
    totalBalls: m['totalBalls'] as int,
    totalWides: m['totalWides'] as int? ?? 0,
    totalNoBalls: m['totalNoBalls'] as int? ?? 0,
    totalByes: m['totalByes'] as int? ?? 0,
    totalLegByes: m['totalLegByes'] as int? ?? 0,
    totalExtras: m['totalExtras'] as int? ?? 0,
    batterStats: (m['batterStats'] as Map<String, dynamic>?)?.map(
          (k, v) =>
              MapEntry(k, _batterInningsFromMap(v as Map<String, dynamic>)),
        ) ??
        {},
    bowlerStats: (m['bowlerStats'] as Map<String, dynamic>?)?.map(
          (k, v) =>
              MapEntry(k, _bowlerSpellFromMap(v as Map<String, dynamic>)),
        ) ??
        {},
    fallOfWickets: (m['fallOfWickets'] as List<dynamic>?)
            ?.map(
                (e) => _fallOfWicketFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    deliveryHistory: (m['deliveryHistory'] as List<dynamic>?)
            ?.map((e) => _deliveryFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    battingTeamPlayers: (m['battingTeamPlayers'] as List<dynamic>?)
            ?.map(
                (e) => _playingXIPlayerFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    bowlingTeamPlayers: (m['bowlingTeamPlayers'] as List<dynamic>?)
            ?.map(
                (e) => _playingXIPlayerFromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// ── FallOfWicket ──

Map<String, dynamic> _fallOfWicketToMap(FallOfWicket f) {
  return {
    'wicketNumber': f.wicketNumber,
    'scoreAtFall': f.scoreAtFall,
    'oversAtFall': f.oversAtFall,
    'dismissedPlayerName': f.dismissedPlayerName,
  };
}

FallOfWicket _fallOfWicketFromMap(Map<String, dynamic> m) {
  return FallOfWicket(
    wicketNumber: m['wicketNumber'] as int,
    scoreAtFall: m['scoreAtFall'] as int,
    oversAtFall: m['oversAtFall'] as String,
    dismissedPlayerName: m['dismissedPlayerName'] as String,
  );
}
