import '../../data/datasources/scoring_local_datasource.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/playing_xi_player.dart';
import 'scoring_notifier.dart';

/// Wraps [ScoringNotifier] with local persistence.
///
/// Every mutation delegates to the notifier, then saves the state snapshot
/// to the local database (fire-and-forget). The notifier itself is unchanged,
/// preserving all existing tests.
class ScoringPersistenceService {
  ScoringPersistenceService._({
    required ScoringNotifier notifier,
    required ScoringLocalDatasource datasource,
  })  : _notifier = notifier,
        _datasource = datasource;

  final ScoringNotifier _notifier;
  final ScoringLocalDatasource _datasource;

  /// The current scoring state.
  ScoringState get state => _notifier.state;

  /// Direct access to the notifier (for read-only properties like bowlerOptions).
  ScoringNotifier get notifier => _notifier;

  /// Create a new scoring session and persist the initial state.
  static Future<ScoringPersistenceService> createNew({
    required ScoringNotifier notifier,
    required ScoringLocalDatasource datasource,
  }) async {
    final service = ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
    );
    await datasource.saveState(notifier.state);
    return service;
  }

  /// Resume a scoring session from a saved snapshot.
  ///
  /// Returns null if no snapshot exists for the given matchId.
  static Future<ScoringPersistenceService?> resume({
    required String matchId,
    required ScoringLocalDatasource datasource,
  }) async {
    final savedState = await datasource.loadState(matchId);
    if (savedState == null) return null;

    final notifier = ScoringNotifier(savedState);
    return ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
    );
  }

  // ── Delegated mutations with persistence ──

  void recordDelivery({
    required int runsFromBat,
    bool isBoundaryFour = false,
    bool isBoundarySix = false,
  }) {
    _notifier.recordDelivery(
      runsFromBat: runsFromBat,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
    );
    _persistState();
  }

  void recordWide({int additionalRuns = 0}) {
    _notifier.recordWide(additionalRuns: additionalRuns);
    _persistState();
  }

  void recordNoBall({int runsFromBat = 0}) {
    _notifier.recordNoBall(runsFromBat: runsFromBat);
    _persistState();
  }

  void recordBye({required int byeRuns}) {
    _notifier.recordBye(byeRuns: byeRuns);
    _persistState();
  }

  void recordLegBye({required int legByeRuns}) {
    _notifier.recordLegBye(legByeRuns: legByeRuns);
    _persistState();
  }

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
    _notifier.recordWicket(
      dismissalType: dismissalType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      fielderName: fielderName,
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      battersCrossed: battersCrossed,
    );
    _persistState();
  }

  void undoLastDelivery() {
    _notifier.undoLastDelivery();
    _persistState();
  }

  void selectNewBatter({
    required String playerId,
    required String displayName,
  }) {
    _notifier.selectNewBatter(playerId: playerId, displayName: displayName);
    _persistState();
  }

  void selectNewBowler({
    required String playerId,
    required String displayName,
  }) {
    _notifier.selectNewBowler(playerId: playerId, displayName: displayName);
    _persistState();
  }

  void swapStrike() {
    _notifier.swapStrike();
    _persistState();
  }

  void declareInnings() {
    _notifier.declareInnings();
    _persistState();
  }

  void startSecondInnings({
    required String strikerId,
    required String strikerName,
    required String nonStrikerId,
    required String nonStrikerName,
    required String bowlerId,
    required String bowlerName,
  }) {
    _notifier.startSecondInnings(
      strikerId: strikerId,
      strikerName: strikerName,
      nonStrikerId: nonStrikerId,
      nonStrikerName: nonStrikerName,
      bowlerId: bowlerId,
      bowlerName: bowlerName,
    );
    _persistState();
  }

  /// Mark the match as complete in local storage.
  Future<void> onMatchComplete() async {
    await _datasource.completeMatch(state.matchId);
  }

  // ── Internal ──

  /// Fire-and-forget persist — errors are silently swallowed to avoid
  /// interrupting the scoring flow.
  void _persistState() {
    _datasource.saveState(_notifier.state).catchError((_) {});
  }
}
