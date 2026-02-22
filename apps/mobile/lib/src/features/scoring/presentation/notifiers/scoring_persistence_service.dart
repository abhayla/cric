import 'package:flutter/foundation.dart';

import '../../../../shared/data/sync/sync_service.dart';
import '../../../../shared/data/websocket/websocket_client.dart';
import '../../data/datasources/scoring_local_datasource.dart';
import '../../data/mappers/scoring_ws_mapper.dart';
import '../../domain/entities/delivery.dart';
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
    WebSocketClient? wsClient,
  })  : _notifier = notifier,
        _datasource = datasource,
        _syncService = syncService,
        _wsClient = wsClient;

  final ScoringNotifier _notifier;
  final ScoringLocalDatasource _datasource;
  final SyncService? _syncService;
  final WebSocketClient? _wsClient;

  /// The current scoring state.
  ScoringState get state => _notifier.state;

  /// Direct access to the notifier (for read-only properties like bowlerOptions).
  ScoringNotifier get notifier => _notifier;

  /// Access to the sync service for status monitoring.
  SyncService? get syncService => _syncService;

  /// Create a new scoring session and persist the initial state.
  static Future<ScoringPersistenceService> createNew({
    required ScoringNotifier notifier,
    required ScoringLocalDatasource datasource,
    SyncService? syncService,
    WebSocketClient? wsClient,
  }) async {
    final service = ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
      syncService: syncService,
      wsClient: wsClient,
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
    WebSocketClient? wsClient,
  }) async {
    final savedState = await datasource.loadState(matchId);
    if (savedState == null) return null;

    final notifier = ScoringNotifier(savedState);
    final service = ScoringPersistenceService._(
      notifier: notifier,
      datasource: datasource,
      syncService: syncService,
      wsClient: wsClient,
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
    _publishScoreUpdate();
  }

  void recordWide({int additionalRuns = 0}) {
    _notifier.recordWide(additionalRuns: additionalRuns);
    _persistState();
    _enqueueLastDelivery();
    _publishScoreUpdate();
  }

  void recordNoBall({int runsFromBat = 0, int byeRuns = 0, int legByeRuns = 0}) {
    _notifier.recordNoBall(runsFromBat: runsFromBat, byeRuns: byeRuns, legByeRuns: legByeRuns);
    _persistState();
    _enqueueLastDelivery();
    _publishScoreUpdate();
  }

  void recordBye({required int byeRuns}) {
    _notifier.recordBye(byeRuns: byeRuns);
    _persistState();
    _enqueueLastDelivery();
    _publishScoreUpdate();
  }

  void recordLegBye({required int legByeRuns}) {
    _notifier.recordLegBye(legByeRuns: legByeRuns);
    _persistState();
    _enqueueLastDelivery();
    _publishScoreUpdate();
  }

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
    _notifier.recordWicket(
      dismissalType: dismissalType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      fielderName: fielderName,
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      isNoBall: isNoBall,
      noBallRuns: noBallRuns,
      battersCrossed: battersCrossed,
      isDirectHit: isDirectHit,
    );
    _persistState();
    _enqueueLastDelivery();
    _publishScoreUpdate(fielderName: fielderName);
  }

  void undoLastDelivery() {
    final lastId = _notifier.state.deliveryHistory.lastOrNull?.id;
    _notifier.undoLastDelivery();
    _persistState();
    final syncService = _syncService;
    if (lastId != null && syncService != null) {
      syncService.enqueueUndo(
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

  void startSuperOver({
    required String strikerId,
    required String strikerName,
    required String nonStrikerId,
    required String nonStrikerName,
    required String bowlerId,
    required String bowlerName,
  }) {
    _notifier.startSuperOver(
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

  /// Publish score update via WebSocket fast path (fire-and-forget).
  void _publishScoreUpdate({String? fielderName}) {
    final wsClient = _wsClient;
    if (wsClient == null) return;
    try {
      final state = _notifier.state;
      final matchId = state.matchId;

      // Always send score_update
      wsClient.publishToMatch(matchId, buildScoreUpdatePayload(state));

      // Send wicket if the last delivery was a wicket
      final lastDelivery = state.lastDelivery;
      if (lastDelivery != null && lastDelivery.isWicket) {
        wsClient.publishToMatch(
          matchId,
          buildWicketPayload(state, lastDelivery, fielderName: fielderName),
        );
      }

      // Send innings_complete if innings just ended (but not match)
      if (state.isInningsComplete && !state.isMatchComplete) {
        wsClient.publishToMatch(
          matchId,
          buildInningsCompletePayload(state),
        );
      }

      // Send match_complete if match just ended
      if (state.isMatchComplete) {
        wsClient.publishToMatch(matchId, buildMatchCompletePayload(state));
      }
    } catch (e) {
      // Fire-and-forget — never interrupt scoring flow
      debugPrint('[ScoringPersistenceService] WS publish error: $e');
    }
  }

  /// Enqueue the most recently recorded delivery for syncing to the server.
  void _enqueueLastDelivery() {
    final syncService = _syncService;
    if (syncService == null) return;
    final delivery = _notifier.state.deliveryHistory.lastOrNull;
    if (delivery == null) return;
    final payload = delivery.toSyncPayload();
    payload['inningsNumber'] = _notifier.state.inningsNumber;
    syncService.enqueueDelivery(
      matchId: _notifier.state.matchId,
      deliveryId: delivery.id,
      payload: payload,
    );
  }
}
