import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/scoring_dao.dart';

/// Sync status for the UI indicator.
enum SyncStatus { allSynced, pending, error }

/// Minimum number of create entries to trigger batch mode.
const _batchThreshold = 6;

/// Background sync service that pushes locally queued deliveries to the server.
///
/// Two-phase processing:
///   Phase A: Process undo (delete) entries individually (FIFO, stop on failure)
///   Phase B: Process create entries — batch if >= 6 entries, single otherwise
///
/// Entries exceeding maxRetries are marked as 'failed' (not silently synced).
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
  int _failedCount = 0;
  bool _isSyncing = false;

  /// Current sync status.
  SyncStatus get status => _status;

  /// Number of pending (unsynced) entries.
  int get unsyncedCount => _unsyncedCount;

  /// Number of permanently failed entries.
  int get failedCount => _failedCount;

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

  /// Process all pending sync entries.
  ///
  /// Phase A: undo entries individually (FIFO, stop on failure)
  /// Phase B: create entries — batch if >= threshold, single otherwise
  Future<void> processSyncQueue() async {
    if (_isSyncing) return; // Prevent concurrent processing
    _isSyncing = true;
    try {
      // ── Phase A: Process undo entries individually ──
      final undoOk = await _processUndoEntries();
      if (!undoOk) {
        await _refreshCount();
        return;
      }

      // ── Phase B: Process create entries ──
      await _processCreateEntries();

      await _refreshCount();
      if (_unsyncedCount == 0) {
        _updateStatus(SyncStatus.allSynced);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Reset all failed entries to pending for retry.
  Future<void> retryFailed() async {
    await _dao.retryFailedEntries();
    await _refreshCount();
    unawaited(processSyncQueue());
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

  // ── Internal: Phase A — Undo entries ──

  /// Process undo entries one-by-one (FIFO). Returns false if stopped on failure.
  Future<bool> _processUndoEntries() async {
    while (true) {
      final undoEntries = await _dao.getPendingUndoEntries(limit: 50);
      if (undoEntries.isEmpty) return true;

      _updateStatus(SyncStatus.pending);

      for (final entry in undoEntries) {
        if (entry.retryCount >= maxRetries) {
          await _dao.markFailed(entry.id);
          _updateStatus(SyncStatus.error);
          continue;
        }

        final success = await _syncEntry(entry);
        if (!success) {
          await _dao.incrementRetry(entry.id);
          _updateStatus(SyncStatus.error);
          return false; // Stop on first failure to maintain FIFO
        }
        await _dao.markSynced(entry.id);
      }
    }
  }

  // ── Internal: Phase B — Create entries ──

  Future<void> _processCreateEntries() async {
    while (true) {
      final createEntries = await _dao.getPendingCreateEntries(limit: 300);
      if (createEntries.isEmpty) return;

      _updateStatus(SyncStatus.pending);

      // Filter out entries that exceeded max retries
      final viable = <SyncQueueData>[];
      for (final entry in createEntries) {
        if (entry.retryCount >= maxRetries) {
          await _dao.markFailed(entry.id);
          continue;
        }
        viable.add(entry);
      }

      if (viable.isEmpty) return;

      if (viable.length >= _batchThreshold) {
        final success = await _syncBatch(viable);
        if (!success) {
          _updateStatus(SyncStatus.error);
          return; // Stop — will retry next cycle
        }
      } else {
        // Single mode for small queues (live scoring)
        var hadFailure = false;
        for (final entry in viable) {
          final success = await _syncEntry(entry);
          if (!success) {
            await _dao.incrementRetry(entry.id);
            _updateStatus(SyncStatus.error);
            hadFailure = true;
            break; // Stop on first failure to maintain FIFO
          }
          await _dao.markSynced(entry.id);
        }
        if (hadFailure) return;
      }
    }
  }

  // ── Internal: Batch sync ──

  Future<bool> _syncBatch(List<SyncQueueData> entries) async {
    // Group entries by matchId
    final byMatch = <String, List<SyncQueueData>>{};
    for (final entry in entries) {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final matchId = payload['matchId'] as String;
      byMatch.putIfAbsent(matchId, () => []).add(entry);
    }

    for (final mapEntry in byMatch.entries) {
      final matchId = mapEntry.key;
      final matchEntries = mapEntry.value;

      // Build batch payload
      final deliveryBodies = <Map<String, dynamic>>[];
      for (final entry in matchEntries) {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
        final body = Map<String, dynamic>.from(payload);
        body.remove('matchId');
        deliveryBodies.add(body);
      }

      try {
        await _dio.post(
          '/api/v1/matches/$matchId/deliveries/batch',
          data: {'deliveries': deliveryBodies},
        );
        // Success — mark all entries as synced
        await _dao
            .markMultipleSynced(matchEntries.map((e) => e.id).toList());
      } on DioException catch (e) {
        debugPrint('[SyncService] Batch sync failed for match=$matchId: '
            'status=${e.response?.statusCode} body=${e.response?.data}');
        // Increment retry for all entries in this failed batch
        for (final entry in matchEntries) {
          await _dao.incrementRetry(entry.id);
        }
        return false;
      } catch (e) {
        debugPrint('[SyncService] Batch sync error for match=$matchId: $e');
        for (final entry in matchEntries) {
          await _dao.incrementRetry(entry.id);
        }
        return false;
      }
    }
    return true;
  }

  // ── Internal: Single entry sync ──

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
    _failedCount = await _dao.getFailedCount();
  }

  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onSyncStatusChanged?.call();
    }
  }
}
