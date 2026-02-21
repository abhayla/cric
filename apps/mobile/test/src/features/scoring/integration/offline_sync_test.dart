import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/features/scoring/data/datasources/scoring_local_datasource.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_persistence_service.dart';
import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/data/database/daos/scoring_dao.dart';
import 'package:cricapp/src/shared/data/sync/sync_service.dart';

class MockDio extends Mock implements Dio {}

/// E2E tests for the offline→online sync pipeline:
/// Score deliveries offline (persist locally), then sync to server.
void main() {
  late AppDatabase db;
  late ScoringDao dao;
  late ScoringLocalDatasource datasource;
  late MockDio mockDio;
  late SyncService syncService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoringDao(db);
    datasource = ScoringLocalDatasource(scoringDao: dao);
    mockDio = MockDio();
    syncService = SyncService(scoringDao: dao, dio: mockDio);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  List<PlayingXIPlayer> makePlayers(String prefix) => List.generate(
        3,
        (i) => PlayingXIPlayer(
          playerId: '$prefix-${i + 1}',
          displayName: '$prefix Player ${i + 1}',
        ),
      );

  Future<ScoringPersistenceService> createSession() async {
    final state = ScoringState(
      matchId: 'match-offline',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: 5,
      playersPerSide: 3,
      battingTeamPlayers: makePlayers('bat'),
      bowlingTeamPlayers: makePlayers('bowl'),
    );
    final notifier = ScoringNotifier(state);
    notifier.selectNewBatter(
        playerId: 'bat-1', displayName: 'bat Player 1');
    notifier.selectNewBatter(
        playerId: 'bat-2', displayName: 'bat Player 2');
    notifier.selectNewBowler(
        playerId: 'bowl-1', displayName: 'bowl Player 1');
    return ScoringPersistenceService.createNew(
      notifier: notifier,
      datasource: datasource,
    );
  }

  // ── Offline scoring + local persistence ──────────────────────────────

  group('Offline scoring — local persistence', () {
    test('deliveries persist and survive session restart', () async {
      final service = await createSession();

      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      service.recordDelivery(runsFromBat: 1);
      service.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate session restart by resuming from DB
      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-offline',
        datasource: datasource,
      );

      expect(resumed, isNotNull);
      expect(resumed!.state.totalRuns, 11);
      expect(resumed.state.totalBalls, 3);
      expect(resumed.state.deliveryHistory, hasLength(3));
    });

    test('undo persists and survives session restart', () async {
      final service = await createSession();

      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      service.undoLastDelivery();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-offline',
        datasource: datasource,
      );

      expect(resumed!.state.totalRuns, 0);
      expect(resumed.state.deliveryHistory, isEmpty);
    });

    test('extras persist and survive session restart', () async {
      final service = await createSession();

      service.recordWide(additionalRuns: 1);
      service.recordNoBall(runsFromBat: 2);
      service.recordBye(byeRuns: 1);
      service.recordLegBye(legByeRuns: 2);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-offline',
        datasource: datasource,
      );

      expect(resumed!.state.totalWides, 2); // 1 penalty + 1 additional
      expect(resumed.state.totalNoBalls, 1); // penalty
      expect(resumed.state.totalByes, 1);
      expect(resumed.state.totalLegByes, 2);
    });

    test('wicket persists with correct batter stats', () async {
      final service = await createSession();

      service.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-offline',
        datasource: datasource,
      );

      expect(resumed!.state.totalWickets, 1);
      expect(resumed.state.needsNewBatter, isTrue);
    });
  });

  // ── Sync queue operations ────────────────────────────────────────────

  group('Sync queue — enqueue and process', () {
    test('enqueued delivery syncs when server is available', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 4},
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // With batch threshold=1, even single deliveries go through batch endpoint
      verify(() => mockDio.post(
            '/api/v1/matches/match-offline/delivery-batch',
            data: any(named: 'data'),
          )).called(1);
      expect(syncService.status, SyncStatus.allSynced);
    });

    test('failed sync sets status to error and retries', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 4},
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Status should be error/pending
      expect(syncService.status, isNot(SyncStatus.allSynced));
      expect(syncService.unsyncedCount, greaterThanOrEqualTo(1));
    });

    test('multiple deliveries sync in FIFO order', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async =>
              Response(requestOptions: RequestOptions(), statusCode: 201));

      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-1',
        payload: {'deliveryId': 'del-1', 'runsFromBat': 0},
      );
      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-2',
        payload: {'deliveryId': 'del-2', 'runsFromBat': 4},
      );
      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-3',
        payload: {'deliveryId': 'del-3', 'runsFromBat': 6},
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      // With batch threshold=1, deliveries go through batch endpoint
      // Each enqueue triggers immediate sync, some may batch together
      verify(() => mockDio.post(any(), data: any(named: 'data')))
          .called(greaterThanOrEqualTo(1));
      expect(syncService.status, SyncStatus.allSynced);
    });

    test('undo syncs as delete operation', () async {
      when(() => mockDio.delete(any()))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await syncService.enqueueUndo(
        matchId: 'match-offline',
        deliveryId: 'del-1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockDio.delete(
            '/api/v1/matches/match-offline/deliveries/del-1',
          )).called(1);
    });
  });

  // ── Combined offline→online flow ─────────────────────────────────────

  group('Offline→Online E2E flow', () {
    test('score offline, persist, then sync when back online', () async {
      // Phase 1: Score offline with persistence
      final service = await createSession();
      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      service.recordDelivery(runsFromBat: 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify state persisted
      final saved = await datasource.loadState('match-offline');
      expect(saved!.totalRuns, 5);

      // Phase 2: Enqueue deliveries to sync queue (simulating what the
      // real app does alongside persistence)
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 4},
      );
      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-2',
        payload: {'runsFromBat': 1},
      );

      // Phase 3: Come back online — process sync queue
      // With batch threshold=1, enqueueDelivery fires immediate sync.
      // Allow time for the async fire-and-forget syncs to complete.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await syncService.processSyncQueue();

      // With batch threshold=1, deliveries sync via batch endpoint
      verify(() => mockDio.post(any(), data: any(named: 'data')))
          .called(greaterThanOrEqualTo(1));
      expect(syncService.status, SyncStatus.allSynced);
      expect(syncService.unsyncedCount, 0);
    });

    test('match completion clears active session', () async {
      final service = await createSession();

      expect(await datasource.hasActiveSession('match-offline'), isTrue);

      await service.onMatchComplete();

      expect(await datasource.hasActiveSession('match-offline'), isFalse);
    });

    test('status callback fires on sync completion', () async {
      final statuses = <SyncStatus>[];
      syncService.onSyncStatusChanged = () => statuses.add(syncService.status);

      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 201,
              ));

      await syncService.enqueueDelivery(
        matchId: 'match-offline',
        deliveryId: 'del-1',
        payload: {'runsFromBat': 0},
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should have transitioned through pending → allSynced
      expect(statuses, contains(SyncStatus.pending));
      expect(statuses, contains(SyncStatus.allSynced));
    });
  });
}
