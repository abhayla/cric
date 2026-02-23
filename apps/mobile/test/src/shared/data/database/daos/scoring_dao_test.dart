import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/data/database/daos/scoring_dao.dart';

void main() {
  late AppDatabase db;
  late ScoringDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoringDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  final now = DateTime(2024, 6, 15, 14, 30);

  ScoringSnapshotsCompanion makeSnapshot({
    String matchId = 'match-1',
    int inningsNumber = 1,
    String stateJson = '{"matchId":"match-1"}',
    bool isActive = true,
    DateTime? updatedAt,
  }) {
    return ScoringSnapshotsCompanion.insert(
      matchId: matchId,
      inningsNumber: inningsNumber,
      stateJson: stateJson,
      isActive: Value(isActive),
      updatedAt: updatedAt ?? now,
    );
  }

  SyncQueueCompanion makeSyncEntry({
    String entityType = 'delivery',
    String entityId = 'del-1',
    String operation = 'create',
    String payload = '{}',
    int retryCount = 0,
    String status = 'pending',
    DateTime? createdAt,
  }) {
    return SyncQueueCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      retryCount: Value(retryCount),
      status: Value(status),
      createdAt: createdAt ?? now,
    );
  }

  group('ScoringDao — Snapshot operations', () {
    test('saveSnapshot inserts a new snapshot', () async {
      await dao.saveSnapshot(makeSnapshot());
      final result = await dao.loadSnapshot('match-1');
      expect(result, isNotNull);
      expect(result!.matchId, 'match-1');
      expect(result.inningsNumber, 1);
      expect(result.stateJson, '{"matchId":"match-1"}');
      expect(result.isActive, true);
    });

    test('saveSnapshot upserts on conflict (same matchId)', () async {
      await dao.saveSnapshot(makeSnapshot());
      await dao.saveSnapshot(makeSnapshot(
        inningsNumber: 2,
        stateJson: '{"matchId":"match-1","innings":2}',
      ));
      final result = await dao.loadSnapshot('match-1');
      expect(result, isNotNull);
      expect(result!.inningsNumber, 2);
      expect(result.stateJson, '{"matchId":"match-1","innings":2}');
    });

    test('loadSnapshot returns null for non-existent match', () async {
      final result = await dao.loadSnapshot('non-existent');
      expect(result, isNull);
    });

    test('getActiveSnapshots returns only active snapshots', () async {
      await dao.saveSnapshot(makeSnapshot(matchId: 'match-1'));
      await dao.saveSnapshot(makeSnapshot(
        matchId: 'match-2',
        isActive: false,
      ));
      await dao.saveSnapshot(makeSnapshot(matchId: 'match-3'));

      final active = await dao.getActiveSnapshots();
      expect(active.length, 2);
      expect(active.map((s) => s.matchId), containsAll(['match-1', 'match-3']));
    });

    test('getActiveSnapshots orders by updatedAt descending', () async {
      await dao.saveSnapshot(makeSnapshot(
        matchId: 'match-old',
        updatedAt: DateTime(2024, 1, 1),
      ));
      await dao.saveSnapshot(makeSnapshot(
        matchId: 'match-new',
        updatedAt: DateTime(2024, 6, 15),
      ));

      final active = await dao.getActiveSnapshots();
      expect(active.first.matchId, 'match-new');
      expect(active.last.matchId, 'match-old');
    });

    test('deactivateSnapshot sets isActive to false', () async {
      await dao.saveSnapshot(makeSnapshot());
      await dao.deactivateSnapshot('match-1');
      final result = await dao.loadSnapshot('match-1');
      expect(result!.isActive, false);
    });

    test('deleteSnapshot removes the snapshot', () async {
      await dao.saveSnapshot(makeSnapshot());
      await dao.deleteSnapshot('match-1');
      final result = await dao.loadSnapshot('match-1');
      expect(result, isNull);
    });

    test('getActiveSnapshots returns empty when none active', () async {
      await dao.saveSnapshot(makeSnapshot(isActive: false));
      final active = await dao.getActiveSnapshots();
      expect(active, isEmpty);
    });
  });

  group('ScoringDao — Sync queue operations', () {
    test('enqueueSyncEntry inserts and returns id', () async {
      final id = await dao.enqueueSyncEntry(makeSyncEntry());
      expect(id, greaterThan(0));
    });

    test('getPendingSyncEntries returns only pending entries', () async {
      await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-1'));
      await dao.enqueueSyncEntry(makeSyncEntry(
        entityId: 'del-2',
        status: 'synced',
      ));
      await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-3'));

      final pending = await dao.getPendingSyncEntries();
      expect(pending.length, 2);
      expect(pending.map((e) => e.entityId), containsAll(['del-1', 'del-3']));
    });

    test('getPendingSyncEntries orders by createdAt FIFO', () async {
      await dao.enqueueSyncEntry(makeSyncEntry(
        entityId: 'del-first',
        createdAt: DateTime(2024, 1, 1),
      ));
      await dao.enqueueSyncEntry(makeSyncEntry(
        entityId: 'del-second',
        createdAt: DateTime(2024, 6, 15),
      ));

      final pending = await dao.getPendingSyncEntries();
      expect(pending.first.entityId, 'del-first');
      expect(pending.last.entityId, 'del-second');
    });

    test('getPendingSyncEntries respects limit', () async {
      for (var i = 0; i < 10; i++) {
        await dao.enqueueSyncEntry(makeSyncEntry(
          entityId: 'del-$i',
          createdAt: now.add(Duration(seconds: i)),
        ));
      }
      final pending = await dao.getPendingSyncEntries(limit: 3);
      expect(pending.length, 3);
    });

    test('markSynced updates status to synced', () async {
      final id = await dao.enqueueSyncEntry(makeSyncEntry());
      await dao.markSynced(id);
      final pending = await dao.getPendingSyncEntries();
      expect(pending, isEmpty);
    });

    test('incrementRetry increases retry count by 1', () async {
      final id = await dao.enqueueSyncEntry(makeSyncEntry());
      await dao.incrementRetry(id);
      await dao.incrementRetry(id);
      final entries = await dao.getPendingSyncEntries();
      expect(entries.first.retryCount, 2);
    });

    test('getUnsyncedCount returns count of pending entries', () async {
      await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-1'));
      await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-2'));
      await dao.enqueueSyncEntry(makeSyncEntry(
        entityId: 'del-3',
        status: 'synced',
      ));
      final count = await dao.getUnsyncedCount();
      expect(count, 2);
    });

    test('getUnsyncedCount returns 0 when no pending', () async {
      final count = await dao.getUnsyncedCount();
      expect(count, 0);
    });

    test('cleanupSyncedEntries deletes only synced entries', () async {
      await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-1'));
      final id2 = await dao.enqueueSyncEntry(makeSyncEntry(entityId: 'del-2'));
      await dao.markSynced(id2);

      await dao.cleanupSyncedEntries();

      final pending = await dao.getPendingSyncEntries();
      expect(pending.length, 1);
      expect(pending.first.entityId, 'del-1');
    });

    test('cleanupSyncedEntries is no-op when nothing synced', () async {
      await dao.enqueueSyncEntry(makeSyncEntry());
      await dao.cleanupSyncedEntries();
      final count = await dao.getUnsyncedCount();
      expect(count, 1);
    });
  });
}
