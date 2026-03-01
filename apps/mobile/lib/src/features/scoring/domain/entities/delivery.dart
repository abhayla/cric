import 'wicket_info.dart';

/// Dismissal types — mirrors server seed data.
///
/// IDs match the `dismissal_types` table in PostgreSQL for client-server parity.
/// Types 10-11 are deferred to post-MVP (greyed out in wicket dialog).
enum DismissalType {
  bowled(1, 'Bowled', 'b', requiresFielder: false, bowlerCredited: true),
  caught(2, 'Caught', 'c', requiresFielder: true, bowlerCredited: true),
  lbw(3, 'LBW', 'lbw', requiresFielder: false, bowlerCredited: true),
  runOut(4, 'Run Out', 'ro', requiresFielder: true, bowlerCredited: false),
  stumped(5, 'Stumped', 'st', requiresFielder: true, bowlerCredited: true),
  hitWicket(6, 'Hit Wicket', 'hw', requiresFielder: false, bowlerCredited: true),
  caughtAndBowled(
    7,
    'Caught & Bowled',
    'c&b',
    requiresFielder: false,
    bowlerCredited: true,
  ),
  retiredHurt(
    8,
    'Retired Hurt',
    'rh',
    requiresFielder: false,
    bowlerCredited: false,
  ),
  retiredOut(
    9,
    'Retired Out',
    'ret',
    requiresFielder: false,
    bowlerCredited: false,
  ),
  timedOut(
    10,
    'Timed Out',
    'to',
    requiresFielder: false,
    bowlerCredited: false,
  ),
  obstructingField(
    11,
    'Obstructing Field',
    'of',
    requiresFielder: false,
    bowlerCredited: false,
  );

  const DismissalType(
    this.id,
    this.label,
    this.code, {
    required this.requiresFielder,
    required this.bowlerCredited,
  });

  /// Matches `dismissal_types.id` in PostgreSQL.
  final int id;

  /// Display label (e.g. "Caught & Bowled").
  final String label;

  /// Short code for notation (e.g. "c&b").
  final String code;

  /// Whether a fielder must be selected for this dismissal.
  final bool requiresFielder;

  /// Whether the bowler is credited with this wicket.
  final bool bowlerCredited;

  /// Whether this dismissal type is active in MVP (id <= 9).
  bool get isMvpActive => id <= 9;

  /// Whether this counts as a "real" wicket for all-out purposes.
  /// Retired hurt/out don't count toward the all-out threshold.
  bool get isRealWicket =>
      this != retiredHurt && this != retiredOut && isMvpActive;

  /// Whether this dismissal is valid on a free hit delivery.
  /// Only run out is possible on a free hit.
  bool get isValidOnFreeHit => this == runOut;

  /// Whether this dismissal is valid on a wide delivery.
  /// Only stumped and run out are possible on a wide.
  bool get isValidOnWide => this == stumped || this == runOut;

  /// Whether this dismissal is valid on a no-ball delivery.
  /// Only run out is possible on a no-ball.
  bool get isValidOnNoBall => this == runOut;

  /// Create from server seed data ID.
  static DismissalType fromId(int id) {
    return DismissalType.values.firstWhere(
      (d) => d.id == id,
      orElse: () => throw ArgumentError('Unknown dismissal type id: $id'),
    );
  }

  /// Create from short code.
  static DismissalType fromCode(String code) {
    return DismissalType.values.firstWhere(
      (d) => d.code == code,
      orElse: () => throw ArgumentError('Unknown dismissal type code: $code'),
    );
  }
}

/// Reason why an innings was completed.
enum InningsCompletionReason {
  allOut('all_out', 'All Out'),
  oversExhausted('overs_exhausted', 'Overs Exhausted'),
  targetChased('target_chased', 'Target Chased'),
  declared('declared', 'Declared'),
  abandoned('abandoned', 'Abandoned');

  const InningsCompletionReason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static InningsCompletionReason fromApiValue(String value) {
    return InningsCompletionReason.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () =>
          throw ArgumentError('Unknown innings completion reason: $value'),
    );
  }
}

/// Delivery entity — the atomic unit for all scoring.
///
/// Mirrors the `deliveries` table in PostgreSQL.
/// Every ball bowled (legal or not) is stored as a delivery record.
class Delivery {
  Delivery({
    required this.id,
    required this.inningsId,
    required this.overNumber,
    required this.ballNumber,
    required this.sequenceNumber,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.runsFromBat = 0,
    this.isWide = false,
    this.wideRuns = 0,
    this.isNoBall = false,
    this.noBallRuns = 0,
    this.isBye = false,
    this.byeRuns = 0,
    this.isLegBye = false,
    this.legByeRuns = 0,
    this.isWicket = false,
    this.isBoundaryFour = false,
    this.isBoundarySix = false,
    this.isFreeHit = false,
    this.isPenalty = false,
    this.isMagicOverDelivery = false,
    this.magicOverPenaltyApplied = 0,
    this.wicketInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String inningsId;
  final int overNumber;
  final int ballNumber;
  final int sequenceNumber;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsFromBat;
  final bool isWide;
  final int wideRuns;
  final bool isNoBall;
  final int noBallRuns;
  final bool isBye;
  final int byeRuns;
  final bool isLegBye;
  final int legByeRuns;
  final bool isWicket;
  final bool isBoundaryFour;
  final bool isBoundarySix;
  final bool isFreeHit;
  final bool isPenalty;
  final bool isMagicOverDelivery;
  final int magicOverPenaltyApplied;
  final WicketInfo? wicketInfo;
  final DateTime timestamp;

  /// Whether this is a legal delivery (counts toward over completion).
  bool get isLegal => !isWide && !isNoBall && !isPenalty;

  /// Total runs scored off this delivery.
  int get totalRuns =>
      runsFromBat + wideRuns + noBallRuns + byeRuns + legByeRuns;

  /// Whether any extras were scored.
  bool get isExtra => isWide || isNoBall || isBye || isLegBye;

  /// Whether this is a dot ball (0 total runs, legal delivery).
  bool get isDotBall => totalRuns == 0 && isLegal;

  /// Runs conceded by the bowler.
  /// Includes bat runs + wides + no-balls. Excludes byes/leg-byes.
  int get bowlerRunsConceded => runsFromBat + wideRuns + noBallRuns;

  /// Build a payload map for syncing to the server REST API.
  ///
  /// The caller must add `inningsNumber` to the returned map.
  Map<String, dynamic> toSyncPayload() => {
        'id': id,
        'overNumber': overNumber,
        'ballNumber': ballNumber,
        'strikerId': strikerId,
        'nonStrikerId': nonStrikerId,
        'bowlerId': bowlerId,
        'runsFromBat': runsFromBat,
        'isWide': isWide,
        'wideRuns': wideRuns,
        'isNoBall': isNoBall,
        'noBallRuns': noBallRuns,
        'isBye': isBye,
        'byeRuns': byeRuns,
        'isLegBye': isLegBye,
        'legByeRuns': legByeRuns,
        'isWicket': isWicket,
        'isBoundaryFour': isBoundaryFour,
        'isBoundarySix': isBoundarySix,
        'isPenalty': isPenalty,
        if (wicketInfo != null)
          'wicket': {
            'dismissedPlayerId': wicketInfo!.dismissedPlayerId,
            'dismissalTypeId': wicketInfo!.dismissalType.id,
            if (wicketInfo!.fielderId != null) 'fielderId': wicketInfo!.fielderId,
            'bowlerCredited': wicketInfo!.bowlerCredited,
            if (wicketInfo!.isDirectHit) 'isDirectHit': true,
          },
      };

  /// Cricket notation for this delivery.
  ///
  /// Examples: ".", "1", "4", "6", "W", "Wd", "1Wd", "Nb", "1Nb", "B", "Lb"
  String get notation {
    if (isPenalty) return 'P';
    if (isWicket) return 'W';
    if (isWide) {
      final additionalRuns = wideRuns > 1 ? '${wideRuns - 1}' : '';
      return '${additionalRuns}Wd';
    }
    if (isNoBall) {
      final batRuns = runsFromBat > 0 ? '$runsFromBat' : '';
      return '${batRuns}Nb';
    }
    if (isBye) {
      return '${byeRuns}B';
    }
    if (isLegBye) {
      return '${legByeRuns}Lb';
    }
    if (isBoundarySix) return '6';
    if (isBoundaryFour) return '4';
    if (runsFromBat == 0) return '.';
    return '$runsFromBat';
  }
}
