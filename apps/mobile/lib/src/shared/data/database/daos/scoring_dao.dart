import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_tables.dart';
import '../tables/scoring_tables.dart';

part 'scoring_dao.g.dart';

/// DAO for scoring snapshots and sync queue operations.
@DriftAccessor(tables: [ScoringSnapshots, SyncQueue])
class ScoringDao extends DatabaseAccessor<AppDatabase>
    with _$ScoringDaoMixin {
  ScoringDao(super.db);

  // ── Snapshot operations ──

  /// Insert or update a scoring snapshot by matchId.
  Future<void> saveSnapshot(ScoringSnapshotsCompanion companion) {
    return into(scoringSnapshots).insertOnConflictUpdate(companion);
  }

  /// Load a snapshot for a specific match.
  Future<ScoringSnapshot?> loadSnapshot(String matchId) {
    return (select(scoringSnapshots)
          ..where((t) => t.matchId.equals(matchId)))
        .getSingleOrNull();
  }

  /// Get all active (in-progress) snapshots.
  Future<List<ScoringSnapshot>> getActiveSnapshots() {
    return (select(scoringSnapshots)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Mark a snapshot as inactive (match completed or abandoned).
  Future<void> deactivateSnapshot(String matchId) {
    return (update(scoringSnapshots)
          ..where((t) => t.matchId.equals(matchId)))
        .write(ScoringSnapshotsCompanion(
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete a snapshot entirely.
  Future<void> deleteSnapshot(String matchId) {
    return (delete(scoringSnapshots)
          ..where((t) => t.matchId.equals(matchId)))
        .go();
  }

  // ── Sync queue operations ──

  /// Insert a new sync queue entry.
  Future<int> enqueueSyncEntry(SyncQueueCompanion companion) {
    return into(syncQueue).insert(companion);
  }

  /// Get pending sync entries, ordered by creation time (FIFO).
  Future<List<SyncQueueData>> getPendingSyncEntries({int limit = 50}) {
    return (select(syncQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Mark a sync entry as synced.
  Future<void> markSynced(int entryId) {
    return (update(syncQueue)..where((t) => t.id.equals(entryId)))
        .write(const SyncQueueCompanion(status: Value('synced')));
  }

  /// Increment the retry count for a failed sync entry.
  Future<void> incrementRetry(int entryId) async {
    final entry = await (select(syncQueue)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (entry != null) {
      await (update(syncQueue)..where((t) => t.id.equals(entryId)))
          .write(SyncQueueCompanion(
        retryCount: Value(entry.retryCount + 1),
      ));
    }
  }

  /// Count of unsent (pending) sync entries.
  Future<int> getUnsyncedCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('pending'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get pending undo (delete) entries, ordered FIFO.
  Future<List<SyncQueueData>> getPendingUndoEntries({int limit = 50}) {
    return (select(syncQueue)
          ..where(
              (t) => t.status.equals('pending') & t.operation.equals('delete'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get pending create entries, ordered FIFO.
  Future<List<SyncQueueData>> getPendingCreateEntries({int limit = 300}) {
    return (select(syncQueue)
          ..where(
              (t) => t.status.equals('pending') & t.operation.equals('create'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Batch mark multiple entries as synced.
  Future<void> markMultipleSynced(List<int> entryIds) {
    return (update(syncQueue)
          ..where((t) => t.id.isIn(entryIds)))
        .write(const SyncQueueCompanion(status: Value('synced')));
  }

  /// Mark a sync entry as permanently failed.
  Future<void> markFailed(int entryId) {
    return (update(syncQueue)..where((t) => t.id.equals(entryId)))
        .write(const SyncQueueCompanion(status: Value('failed')));
  }

  /// Count of permanently failed sync entries.
  Future<int> getFailedCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('failed'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Reset all failed entries back to pending with retryCount=0.
  Future<void> retryFailedEntries() {
    return (update(syncQueue)..where((t) => t.status.equals('failed')))
        .write(const SyncQueueCompanion(
      status: Value('pending'),
      retryCount: Value(0),
    ));
  }

  /// Delete all synced entries (cleanup).
  Future<void> cleanupSyncedEntries() {
    return (delete(syncQueue)
          ..where((t) => t.status.equals('synced')))
        .go();
  }
}
