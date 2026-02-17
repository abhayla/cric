import '../../../../shared/data/sync/sync_service.dart';
import '../../data/datasources/scoring_local_datasource.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/playing_xi_player.dart';
import 'scoring_notifier.dart';

/// Wraps [ScoringNotifier] with local persistence and optional server sync.
///
/// Every mutation delegates to the notifier, then saves the state snapshot
/// to the local database (fire-and-forget). If a [SyncService] is provided,
/// deliveries are also enqueued for syncing to the server. The notifier
/// itself is unchanged, preserving all existing tests.
class ScoringPersistenceService {
  ScoringPersistenceService._({
    required ScoringNotifier notifier,
    required ScoringLocalDatasource datasource,
    SyncService? syncService,
  })  : _notifier = notifier,
        _datasource = datasource,
        _syncService = syncService;

  final ScoringNotifier _notifier;
  final ScoringLocalDatasource _datasource;
  final SyncService? _syncService;

  /// The current scoring state.
  ScoringState get state => _notifier.state;

  /// Direct access to the notifier (for read-only properties like bowlerOptions).
  ScoringNotifier get notifier => _notifier;

  /// Create a new scoring session and persist the initial state.
  static Future<ScoringPersistenceService> createNew({
    required ScoringNotifier notifier,
    required ScoringLocalDatasource datasource,
    SyncService? syncService,
  }) async {
    final service = ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
      syncService: syncService,
    );
    await datasource.saveState(notifier.state);
    syncService?.startPeriodicSync();
    return service;
  }

  /// Resume a scoring session from a saved snapshot.
  ///
  /// Returns null if no snapshot exists for the given matchId.
  static Future<ScoringPersistenceService?> resume({
    required String matchId,
    required ScoringLocalDatasource datasource,
    SyncService? syncService,
  }) async {
    final savedState = await datasource.loadState(matchId);
    if (savedState == null) return null;

    final notifier = ScoringNotifier(savedState);
    final service = ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
      syncService: syncService,
    );
    syncService?.startPeriodicSync();
    return service;
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
    _enqueueLastDelivery();
  }

  void recordWide({int additionalRuns = 0}) {
    _notifier.recordWide(additionalRuns: additionalRuns);
    _persistState();
    _enqueueLastDelivery();
  }

  void recordNoBall({int runsFromBat = 0}) {
    _notifier.recordNoBall(runsFromBat: runsFromBat);
    _persistState();
    _enqueueLastDelivery();
  }

  void recordBye({required int byeRuns}) {
    _notifier.recordBye(byeRuns: byeRuns);
    _persistState();
    _enqueueLastDelivery();
  }

  void recordLegBye({required int legByeRuns}) {
    _notifier.recordLegBye(legByeRuns: legByeRuns);
    _persistState();
    _enqueueLastDelivery();
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
    _enqueueLastDelivery();
  }

  void undoLastDelivery() {
    final lastId = _notifier.state.deliveryHistory.lastOrNull?.id;
    _notifier.undoLastDelivery();
    _persistState();
    if (lastId != null && _syncService != null) {
      _syncService!.enqueueUndo(
        matchId: _notifier.state.matchId,
        deliveryId: lastId,
      );
    }
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

  /// Dispose the service — stop sync timers.
  void dispose() {
    _syncService?.dispose();
  }

  // ── Internal ──

  /// Fire-and-forget persist — errors are silently swallowed to avoid
  /// interrupting the scoring flow.
  void _persistState() {
    _datasource.saveState(_notifier.state).catchError((_) {});
  }

  /// Enqueue the most recently recorded delivery for syncing to the server.
  void _enqueueLastDelivery() {
    if (_syncService == null) return;
    final delivery = _notifier.state.deliveryHistory.lastOrNull;
    if (delivery == null) return;
    final payload = delivery.toSyncPayload();
    payload['inningsNumber'] = _notifier.state.inningsNumber;
    _syncService!.enqueueDelivery(
      matchId: _notifier.state.matchId,
      deliveryId: delivery.id,
      payload: payload,
    );
  }
}
