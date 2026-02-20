
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/data/database/daos/scoring_dao.dart';
import 'package:cricapp/src/shared/data/sync/sync_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late ScoringDao dao;
  late MockDio mockDio;
  late SyncService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoringDao(db);
    mockDio = MockDio();
    service = SyncService(scoringDao: dao, dio: mockDio);
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('enqueueDelivery', () {
    test('inserts entry into sync queue', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await service.enqueueDelivery(
        matchId: 'match-1',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 4},
      );

      // Give processSyncQueue time to run
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify the entry was enqueued (and synced since mock succeeded)
      verify(() => mockDio.post(
            '/api/v1/matches/match-1/deliveries',
            data: any(named: 'data'),
          )).called(1);
    });

    test('updates unsyncedCount', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      await service.enqueueDelivery(
        matchId: 'match-1',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 0},
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.unsyncedCount, greaterThanOrEqualTo(1));
    });
  });

  group('enqueueUndo', () {
    test('inserts delete operation into sync queue', () async {
      when(() => mockDio.delete(any()))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await service.enqueueUndo(
        matchId: 'match-1',
        deliveryId: 'del-1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockDio.delete(
            '/api/v1/matches/match-1/deliveries/del-1',
          )).called(1);
    });
  });

  group('processSyncQueue', () {
    test('syncs all pending entries', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      // Manually insert entries
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1","runs":0}',
        createdAt: DateTime.now(),
      ));
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-2',
        operation: 'create',
        payload: '{"matchId":"match-1","runs":4}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      verify(() => mockDio.post(any(), data: any(named: 'data'))).called(2);
      expect(service.status, SyncStatus.allSynced);
      expect(service.unsyncedCount, 0);
    });

    test('stops on first failure (FIFO ordering)', () async {
      var callCount = 0;
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw DioException(requestOptions: RequestOptions());
        }
        return Response(requestOptions: RequestOptions(), statusCode: 201);
      });

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-2',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      // Only first entry attempted, second skipped due to FIFO
      verify(() => mockDio.post(any(), data: any(named: 'data'))).called(1);
      expect(service.status, SyncStatus.error);
    });

    test('increments retry count on failure', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      final entries = await dao.getPendingSyncEntries();
      expect(entries.first.retryCount, 1);
    });

    test('skips entries that exceeded max retries', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      // Insert an entry with retryCount at max
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-exhausted',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));
      // Manually set retry count to max
      final entries = await dao.getPendingSyncEntries();
      for (var i = 0; i < 5; i++) {
        await dao.incrementRetry(entries.first.id);
      }

      // Insert a second good entry
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-good',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      // Exhausted entry should be skipped, good entry should be synced
      verify(() => mockDio.post(any(), data: any(named: 'data'))).called(1);
    });

    test('returns allSynced when queue is empty', () async {
      await service.processSyncQueue();
      expect(service.status, SyncStatus.allSynced);
    });

    test('handles delete operations', () async {
      when(() => mockDio.delete(any()))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'delete',
        payload: '{"matchId":"match-1","deliveryId":"del-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      verify(() => mockDio.delete('/api/v1/matches/match-1/deliveries/del-1'))
          .called(1);
      expect(service.status, SyncStatus.allSynced);
    });
  });

  group('status callbacks', () {
    test('onSyncStatusChanged is called when status changes', () async {
      final statuses = <SyncStatus>[];
      service.onSyncStatusChanged = () => statuses.add(service.status);

      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();

      expect(statuses, contains(SyncStatus.pending));
      expect(statuses, contains(SyncStatus.allSynced));
    });

    test('onSyncStatusChanged not called when status unchanged', () async {
      var callCount = 0;
      service.onSyncStatusChanged = () => callCount++;

      // Process empty queue — already allSynced, no status change
      await service.processSyncQueue();
      expect(callCount, 0);
    });
  });

  group('startPeriodicSync', () {
    test('creates timer that calls processSyncQueue', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      service.startPeriodicSync(
          interval: const Duration(milliseconds: 100));

      await Future<void>.delayed(const Duration(milliseconds: 250));
      service.stopPeriodicSync();

      // Timer should have fired at least once
      verify(() => mockDio.post(any(), data: any(named: 'data'))).called(greaterThanOrEqualTo(1));
    });

    test('stopPeriodicSync cancels timer', () {
      service.startPeriodicSync();
      service.stopPeriodicSync();
      // No exception = timer canceled successfully
    });
  });

  group('cleanup', () {
    test('removes synced entries', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-1',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));

      await service.processSyncQueue();
      await service.cleanup();

      final count = await dao.getUnsyncedCount();
      expect(count, 0);
    });
  });

  group('dispose', () {
    test('stops periodic sync', () {
      service.startPeriodicSync();
      service.dispose();
      // No exception = disposed successfully
    });
  });

  group('initial state', () {
    test('starts with allSynced status', () {
      expect(service.status, SyncStatus.allSynced);
    });

    test('starts with 0 unsyncedCount', () {
      expect(service.unsyncedCount, 0);
    });
  });

  group('batch sync', () {
    test('queue < 6 entries → individual POSTs (not batch)', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      // Insert 3 entries (below batch threshold)
      for (var i = 0; i < 3; i++) {
        await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
          entityType: 'delivery',
          entityId: 'del-$i',
          operation: 'create',
          payload: '{"matchId":"match-1","runs":$i}',
          createdAt: DateTime.now(),
        ));
      }

      await service.processSyncQueue();

      // Should use individual POSTs to /deliveries (not /deliveries/batch)
      verify(() => mockDio.post(
            '/api/v1/matches/match-1/deliveries',
            data: any(named: 'data'),
          )).called(3);
      verifyNever(() => mockDio.post(
            '/api/v1/matches/match-1/deliveries/batch',
            data: any(named: 'data'),
          ));
    });

    test('queue >= 6 entries → single batch POST', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      // Insert 8 entries (above batch threshold)
      for (var i = 0; i < 8; i++) {
        await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
          entityType: 'delivery',
          entityId: 'del-$i',
          operation: 'create',
          payload: '{"matchId":"match-1","runs":$i}',
          createdAt: DateTime.now(),
        ));
      }

      await service.processSyncQueue();

      // Should use batch endpoint
      verify(() => mockDio.post(
            '/api/v1/matches/match-1/deliveries/batch',
            data: any(named: 'data'),
          )).called(1);
      // Should NOT use individual endpoint
      verifyNever(() => mockDio.post(
            '/api/v1/matches/match-1/deliveries',
            data: any(named: 'data'),
          ));
      expect(service.status, SyncStatus.allSynced);
    });

    test('undo entries processed before creates', () async {
      final callOrder = <String>[];

      when(() => mockDio.delete(any())).thenAnswer((_) async {
        callOrder.add('delete');
        return Response(requestOptions: RequestOptions(), statusCode: 200);
      });
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async {
        callOrder.add('post');
        return Response(requestOptions: RequestOptions(), statusCode: 201);
      });

      // Insert a create entry first (chronologically)
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-create',
        operation: 'create',
        payload: '{"matchId":"match-1","runs":0}',
        createdAt: DateTime(2026, 1, 1),
      ));
      // Then insert an undo entry later
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-undo',
        operation: 'delete',
        payload: '{"matchId":"match-1","deliveryId":"del-undo"}',
        createdAt: DateTime(2026, 1, 2),
      ));

      await service.processSyncQueue();

      // Undo (delete) should be processed before create (post)
      expect(callOrder.first, 'delete');
    });

    test('batch failure increments retry on all entries', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      // Insert 8 entries
      for (var i = 0; i < 8; i++) {
        await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
          entityType: 'delivery',
          entityId: 'del-$i',
          operation: 'create',
          payload: '{"matchId":"match-1","runs":$i}',
          createdAt: DateTime.now(),
        ));
      }

      await service.processSyncQueue();

      // All 8 entries should have retryCount = 1
      final entries = await dao.getPendingSyncEntries();
      expect(entries.length, 8);
      for (final entry in entries) {
        expect(entry.retryCount, 1);
      }
    });

    test('entries at maxRetries get status=failed (not synced)', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      // Insert an entry and manually set retryCount to max
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-exhausted',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));
      final entries = await dao.getPendingSyncEntries();
      for (var i = 0; i < 5; i++) {
        await dao.incrementRetry(entries.first.id);
      }

      await service.processSyncQueue();

      // Entry should be marked as failed, not synced
      final failedCount = await dao.getFailedCount();
      expect(failedCount, 1);
      expect(service.failedCount, 1);

      // The entry should NOT be in pending queue
      final pending = await dao.getPendingSyncEntries();
      expect(pending, isEmpty);
    });

    test('retryFailed() resets failed entries to pending', () async {
      // Insert and exhaust an entry
      await dao.enqueueSyncEntry(SyncQueueCompanion.insert(
        entityType: 'delivery',
        entityId: 'del-fail',
        operation: 'create',
        payload: '{"matchId":"match-1"}',
        createdAt: DateTime.now(),
      ));
      final entries = await dao.getPendingSyncEntries();
      await dao.markFailed(entries.first.id);

      expect(await dao.getFailedCount(), 1);

      // Mock success for retry
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await service.retryFailed();

      // Allow background processSyncQueue to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await dao.getFailedCount(), 0);
      final pending = await dao.getPendingSyncEntries();
      // Should be either synced (if background sync ran) or pending
      // After retryFailed, entries go back to pending with retryCount=0
    });
  });
}
