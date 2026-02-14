import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/data/datasources/scoring_local_datasource.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_persistence_service.dart';
import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/data/database/daos/scoring_dao.dart';

void main() {
  late AppDatabase db;
  late ScoringDao dao;
  late ScoringLocalDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoringDao(db);
    datasource = ScoringLocalDatasource(scoringDao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  List<PlayingXIPlayer> makeBattingTeam() => [
        const PlayingXIPlayer(playerId: 'bat-1', displayName: 'Opener 1'),
        const PlayingXIPlayer(playerId: 'bat-2', displayName: 'Opener 2'),
        const PlayingXIPlayer(playerId: 'bat-3', displayName: 'Batter 3'),
        const PlayingXIPlayer(playerId: 'bat-4', displayName: 'Batter 4'),
        const PlayingXIPlayer(playerId: 'bat-5', displayName: 'Batter 5'),
        const PlayingXIPlayer(playerId: 'bat-6', displayName: 'Batter 6'),
        const PlayingXIPlayer(playerId: 'bat-7', displayName: 'Batter 7'),
        const PlayingXIPlayer(playerId: 'bat-8', displayName: 'Batter 8'),
        const PlayingXIPlayer(playerId: 'bat-9', displayName: 'Batter 9'),
        const PlayingXIPlayer(playerId: 'bat-10', displayName: 'Batter 10'),
        const PlayingXIPlayer(playerId: 'bat-11', displayName: 'Batter 11'),
      ];

  List<PlayingXIPlayer> makeBowlingTeam() => [
        const PlayingXIPlayer(playerId: 'bowl-1', displayName: 'Bowler 1'),
        const PlayingXIPlayer(playerId: 'bowl-2', displayName: 'Bowler 2'),
        const PlayingXIPlayer(playerId: 'bowl-3', displayName: 'Bowler 3'),
        const PlayingXIPlayer(playerId: 'bowl-4', displayName: 'Bowler 4'),
        const PlayingXIPlayer(playerId: 'bowl-5', displayName: 'Bowler 5'),
        const PlayingXIPlayer(playerId: 'bowl-6', displayName: 'Bowler 6'),
        const PlayingXIPlayer(playerId: 'bowl-7', displayName: 'Bowler 7'),
        const PlayingXIPlayer(playerId: 'bowl-8', displayName: 'Bowler 8'),
        const PlayingXIPlayer(playerId: 'bowl-9', displayName: 'Bowler 9'),
        const PlayingXIPlayer(playerId: 'bowl-10', displayName: 'Bowler 10'),
        const PlayingXIPlayer(playerId: 'bowl-11', displayName: 'Bowler 11'),
      ];

  ScoringNotifier makeNotifier() {
    final state = ScoringState(
      matchId: 'match-1',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: 20,
      playersPerSide: 11,
      battingTeamPlayers: makeBattingTeam(),
      bowlingTeamPlayers: makeBowlingTeam(),
    );
    final notifier = ScoringNotifier(state);
    notifier.selectNewBatter(playerId: 'bat-1', displayName: 'Opener 1');
    notifier.selectNewBatter(playerId: 'bat-2', displayName: 'Opener 2');
    notifier.selectNewBowler(playerId: 'bowl-1', displayName: 'Bowler 1');
    return notifier;
  }

  group('ScoringPersistenceService.createNew', () {
    test('saves initial state to database', () async {
      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      expect(service.state.matchId, 'match-1');
      final loaded = await datasource.loadState('match-1');
      expect(loaded, isNotNull);
      expect(loaded!.strikerId, 'bat-1');
    });

    test('state matches notifier state', () async {
      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      expect(identical(service.state, notifier.state), true);
    });
  });

  group('ScoringPersistenceService.resume', () {
    test('returns service with restored state', () async {
      final notifier = makeNotifier();
      await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-1',
        datasource: datasource,
      );

      expect(resumed, isNotNull);
      expect(resumed!.state.matchId, 'match-1');
      expect(resumed.state.strikerId, 'bat-1');
      expect(resumed.state.nonStrikerId, 'bat-2');
      expect(resumed.state.bowlerId, 'bowl-1');
    });

    test('returns null when no snapshot exists', () async {
      final resumed = await ScoringPersistenceService.resume(
        matchId: 'non-existent',
        datasource: datasource,
      );
      expect(resumed, isNull);
    });
  });

  group('Delegated mutations', () {
    late ScoringPersistenceService service;

    setUp(() async {
      final notifier = makeNotifier();
      service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );
    });

    test('recordDelivery updates state and persists', () async {
      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      expect(service.state.totalRuns, 4);
      // Wait for fire-and-forget persist
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 4);
    });

    test('recordWide updates state and persists', () async {
      service.recordWide(additionalRuns: 2);

      expect(service.state.totalRuns, 3); // 1 penalty + 2 additional
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 3);
    });

    test('recordNoBall updates state and persists', () async {
      service.recordNoBall(runsFromBat: 2);

      expect(service.state.totalRuns, 3); // 1 penalty + 2 bat
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 3);
    });

    test('recordBye updates state and persists', () async {
      service.recordBye(byeRuns: 2);

      expect(service.state.totalRuns, 2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 2);
    });

    test('recordLegBye updates state and persists', () async {
      service.recordLegBye(legByeRuns: 3);

      expect(service.state.totalRuns, 3);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 3);
    });

    test('recordWicket updates state and persists', () async {
      service.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );

      expect(service.state.totalWickets, 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalWickets, 1);
    });

    test('undoLastDelivery updates state and persists', () async {
      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      service.undoLastDelivery();

      expect(service.state.totalRuns, 0);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.totalRuns, 0);
    });

    test('swapStrike updates state and persists', () async {
      service.swapStrike();

      expect(service.state.strikerId, 'bat-2');
      expect(service.state.nonStrikerId, 'bat-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.strikerId, 'bat-2');
    });

    test('selectNewBatter updates state and persists', () async {
      service.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      service.selectNewBatter(playerId: 'bat-3', displayName: 'Batter 3');

      expect(service.state.strikerId, 'bat-3');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.strikerId, 'bat-3');
    });

    test('selectNewBowler updates state and persists', () async {
      // Bowl a full over to need a new bowler
      for (var i = 0; i < 6; i++) {
        service.recordDelivery(runsFromBat: 0);
      }
      service.selectNewBowler(playerId: 'bowl-2', displayName: 'Bowler 2');

      expect(service.state.bowlerId, 'bowl-2');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.bowlerId, 'bowl-2');
    });

    test('declareInnings updates state and persists', () async {
      service.declareInnings();

      expect(service.state.isInningsComplete, true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.isInningsComplete, true);
    });

    test('startSecondInnings updates state and persists', () async {
      service.declareInnings();
      service.startSecondInnings(
        strikerId: 'bowl-1',
        strikerName: 'Bowler 1',
        nonStrikerId: 'bowl-2',
        nonStrikerName: 'Bowler 2',
        bowlerId: 'bat-1',
        bowlerName: 'Opener 1',
      );

      expect(service.state.inningsNumber, 2);
      expect(service.state.battingTeamName, 'Team Beta');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await datasource.loadState('match-1');
      expect(loaded!.inningsNumber, 2);
    });
  });

  group('onMatchComplete', () {
    test('deactivates the snapshot', () async {
      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      await service.onMatchComplete();
      expect(await datasource.hasActiveSession('match-1'), false);
    });
  });

  group('notifier access', () {
    test('notifier getter exposes the underlying notifier', () async {
      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      expect(identical(service.notifier, notifier), true);
    });
  });

  group('resume restores full state', () {
    test('resumes after deliveries were recorded', () async {
      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
      );

      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      service.recordDelivery(runsFromBat: 1);
      service.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resumed = await ScoringPersistenceService.resume(
        matchId: 'match-1',
        datasource: datasource,
      );

      expect(resumed, isNotNull);
      expect(resumed!.state.totalRuns, 11);
      expect(resumed.state.deliveryHistory.length, 3);
    });
  });
}
