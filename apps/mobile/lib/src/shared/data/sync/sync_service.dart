import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/scoring_dao.dart';

/// Sync status for the UI indicator.
enum SyncStatus { allSynced, pending, error }

/// Background sync service that pushes locally queued deliveries to the server.
///
/// Maintains FIFO ordering: stops processing on first failure to preserve
/// delivery sequence.
class SyncService {
  SyncService({
    required ScoringDao scoringDao,
    required Dio dio,
    this.maxRetries = 5,
  })  : _dao = scoringDao,
        _dio = dio;

  final ScoringDao _dao;
  final Dio _dio;
  final int maxRetries;

  Timer? _timer;
  SyncStatus _status = SyncStatus.allSynced;
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  /// Current sync status.
  SyncStatus get status => _status;

  /// Number of pending (unsynced) entries.
  int get unsyncedCount => _unsyncedCount;

  /// Callback invoked when sync status changes.
  void Function()? onSyncStatusChanged;

  /// Enqueue a delivery for syncing to the server.
  Future<void> enqueueDelivery({
    required String matchId,
    required String deliveryId,
    required Map<String, dynamic> payload,
  }) async {
    await _dao.enqueueSyncEntry(SyncQueueCompanion.insert(
      entityType: 'delivery',
      entityId: deliveryId,
      operation: 'create',
      payload: jsonEncode({
        'matchId': matchId,
        ...payload,
      }),
      createdAt: DateTime.now(),
    ));
    await _refreshCount();
    // Attempt immediate sync (fire-and-forget)
    unawaited(processSyncQueue());
  }

  /// Enqueue an undo operation for syncing.
  Future<void> enqueueUndo({
    required String matchId,
    required String deliveryId,
  }) async {
    await _dao.enqueueSyncEntry(SyncQueueCompanion.insert(
      entityType: 'delivery',
      entityId: deliveryId,
      operation: 'delete',
      payload: jsonEncode({
        'matchId': matchId,
        'deliveryId': deliveryId,
      }),
      createdAt: DateTime.now(),
    ));
    await _refreshCount();
    unawaited(processSyncQueue());
  }

  /// Process all pending sync entries in FIFO order.
  ///
  /// Stops on first failure to maintain ordering.
  Future<void> processSyncQueue() async {
    if (_isSyncing) return; // Prevent concurrent processing
    _isSyncing = true;
    try {
      while (true) {
        final entries = await _dao.getPendingSyncEntries();
        if (entries.isEmpty) {
          _updateStatus(SyncStatus.allSynced);
          return;
        }

        _updateStatus(SyncStatus.pending);

        var hadFailure = false;
        for (final entry in entries) {
          if (entry.retryCount >= maxRetries) {
            // Skip entries that exceeded retry limit
            await _dao.markSynced(entry.id); // Mark as "done" to skip
            continue;
          }

          final success = await _syncEntry(entry);
          if (!success) {
            await _dao.incrementRetry(entry.id);
            _updateStatus(SyncStatus.error);
            hadFailure = true;
            break; // Stop on first failure to maintain FIFO
          }

          await _dao.markSynced(entry.id);
        }

        if (hadFailure) break;
        // Loop to pick up entries enqueued during this sync pass
      }

      await _refreshCount();
      if (_unsyncedCount == 0) {
        _updateStatus(SyncStatus.allSynced);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Start periodic background sync.
  void startPeriodicSync({Duration interval = const Duration(seconds: 10)}) {
    stopPeriodicSync();
    _timer = Timer.periodic(interval, (_) => processSyncQueue());
  }

  /// Stop periodic background sync.
  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clean up synced entries from the queue.
  Future<void> cleanup() async {
    await _dao.cleanupSyncedEntries();
  }

  /// Dispose the service — stop timers.
  void dispose() {
    stopPeriodicSync();
  }

  // ── Internal ──

  Future<bool> _syncEntry(SyncQueueData entry) async {
    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final matchId = payload['matchId'] as String;

      if (entry.operation == 'create') {
        final body = Map<String, dynamic>.from(payload);
        body.remove('matchId'); // matchId is in the URL, not the body
        await _dio.post(
          '/api/v1/matches/$matchId/deliveries',
          data: body,
        );
      } else if (entry.operation == 'delete') {
        final deliveryId = payload['deliveryId'] as String;
        await _dio.delete(
          '/api/v1/matches/$matchId/deliveries/$deliveryId',
        );
      }
      return true;
    } on DioException catch (e) {
      final responseBody = e.response?.data;
      debugPrint('[SyncService] DioException syncing ${entry.entityType} '
          '${entry.entityId}: status=${e.response?.statusCode} '
          'url=${e.requestOptions.uri} '
          'body=$responseBody');
      return false;
    } catch (e) {
      debugPrint('[SyncService] Error syncing ${entry.entityType} '
          '${entry.entityId}: $e');
      return false;
    }
  }

  Future<void> _refreshCount() async {
    _unsyncedCount = await _dao.getUnsyncedCount();
  }

  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onSyncStatusChanged?.call();
    }
  }
}
