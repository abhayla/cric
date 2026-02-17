/// Tracks a single delivery as tapped through the UI.
///
/// Used to compare against the server's stored delivery records.
class DeliveryRecord {
  const DeliveryRecord({
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
    this.isMagicOver = false,
    required this.overNumber,
    required this.ballNumber,
  });

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
  final bool isMagicOver;
  final int overNumber;
  final int ballNumber;

  /// Whether this is a legal delivery.
  bool get isLegal => !isWide && !isNoBall;

  /// Total runs scored off this delivery.
  int get totalRuns =>
      runsFromBat + wideRuns + noBallRuns + byeRuns + legByeRuns;

  @override
  String toString() {
    if (isWicket) return 'W';
    if (isWide) return '${wideRuns > 1 ? wideRuns - 1 : ""}Wd';
    if (isNoBall) return '${runsFromBat > 0 ? runsFromBat : ""}Nb';
    if (isBye) return '${byeRuns}B';
    if (isLegBye) return '${legByeRuns}Lb';
    if (isBoundarySix) return '6';
    if (isBoundaryFour) return '4';
    if (runsFromBat == 0) return '.';
    return '$runsFromBat';
  }
}

/// Tracks all deliveries for a complete match.
class MatchRecord {
  MatchRecord({
    required this.matchId,
    this.tournamentId,
  });

  final String matchId;
  final String? tournamentId;
  final List<DeliveryRecord> firstInningsDeliveries = [];
  final List<DeliveryRecord> secondInningsDeliveries = [];
  int firstInningsRuns = 0;
  int firstInningsWickets = 0;
  int secondInningsRuns = 0;
  int secondInningsWickets = 0;
  String? winnerTeamId;
  String? resultType;

  /// All deliveries across both innings.
  List<DeliveryRecord> get allDeliveries =>
      [...firstInningsDeliveries, ...secondInningsDeliveries];

  /// Add a delivery to the current innings.
  void addDelivery(int inningsNumber, DeliveryRecord delivery) {
    if (inningsNumber == 1) {
      firstInningsDeliveries.add(delivery);
      firstInningsRuns += delivery.totalRuns;
      if (delivery.isWicket) firstInningsWickets++;
    } else {
      secondInningsDeliveries.add(delivery);
      secondInningsRuns += delivery.totalRuns;
      if (delivery.isWicket) secondInningsWickets++;
    }
  }

  @override
  String toString() =>
      'Match $matchId: ${firstInningsRuns}/${firstInningsWickets} vs '
      '${secondInningsRuns}/${secondInningsWickets} '
      '(${firstInningsDeliveries.length}+${secondInningsDeliveries.length} del)';
}
