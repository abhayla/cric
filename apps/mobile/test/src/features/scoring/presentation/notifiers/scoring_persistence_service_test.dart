import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/data/datasources/scoring_local_datasource.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_persistence_service.dart';
import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/data/database/daos/scoring_dao.dart';
import 'package:cricapp/src/shared/data/websocket/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';

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

  group('WebSocket fast-path broadcasting', () {
    late _FakeWsChannel fakeChannel;
    late WebSocketClient wsClient;

    setUp(() {
      fakeChannel = _FakeWsChannel();
      wsClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) => fakeChannel,
        reconnectEnabled: false,
      );
    });

    tearDown(() {
      wsClient.dispose();
    });

    Future<ScoringPersistenceService> makeServiceWithWs() async {
      await wsClient.connect();
      final notifier = makeNotifier();
      return ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
        wsClient: wsClient,
      );
    }

    test('recordDelivery calls publishToMatch with score_update', () async {
      final service = await makeServiceWithWs();

      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);

      // Should have sent at least one publish_score message
      final publishMsgs = fakeChannel.sentMessages
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'publish_score')
          .toList();
      expect(publishMsgs, isNotEmpty);

      final payload = publishMsgs.first['payload'] as Map<String, dynamic>;
      expect(payload['type'], 'score_update');
      expect((payload['data'] as Map)['totalRuns'], 4);
    });

    test('recordWicket calls publishToMatch twice (score_update + wicket)', () async {
      final service = await makeServiceWithWs();

      service.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );

      final publishMsgs = fakeChannel.sentMessages
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'publish_score')
          .toList();

      // Should have score_update + wicket
      expect(publishMsgs.length, greaterThanOrEqualTo(2));

      final types = publishMsgs
          .map((m) => (m['payload'] as Map<String, dynamic>)['type'])
          .toList();
      expect(types, contains('score_update'));
      expect(types, contains('wicket'));
    });

    test('undoLastDelivery does NOT publish via WS', () async {
      final service = await makeServiceWithWs();

      service.recordDelivery(runsFromBat: 2);
      // Clear sent messages
      fakeChannel.sentMessages.clear();

      service.undoLastDelivery();

      final publishMsgs = fakeChannel.sentMessages
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'publish_score')
          .toList();
      expect(publishMsgs, isEmpty);
    });

    test('WS errors are swallowed and do not interrupt scoring', () async {
      // Create a client that will throw on publish
      final brokenChannel = _BrokenWsChannel();
      final brokenClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) => brokenChannel,
        reconnectEnabled: false,
      );
      await brokenClient.connect();

      final notifier = makeNotifier();
      final service = await ScoringPersistenceService.createNew(
        notifier: notifier,
        datasource: datasource,
        wsClient: brokenClient,
      );

      // Should not throw
      service.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      expect(service.state.totalRuns, 4);

      brokenClient.dispose();
    });
  });
}

// ── Test helpers for WebSocket ──

class _FakeWsChannel with StreamChannelMixin implements WebSocketChannel {
  final _incoming = StreamController<dynamic>();
  bool _closed = false;
  final List<String> sentMessages = [];

  @override
  WebSocketSink get sink => _FakeWsSink(this);

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  void _add(dynamic data) {
    if (!_closed) sentMessages.add(data as String);
  }

  Future<void> _close([int? code, String? reason]) async {
    _closed = true;
    await _incoming.close();
  }
}

class _FakeWsSink implements WebSocketSink {
  _FakeWsSink(this._channel);
  final _FakeWsChannel _channel;

  @override
  void add(dynamic data) => _channel._add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) =>
      _channel._close(closeCode, closeReason);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> addStream(Stream<dynamic> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<dynamic> get done => Future.value();
}

/// A broken WS channel whose sink always throws on add.
class _BrokenWsChannel with StreamChannelMixin implements WebSocketChannel {
  final _incoming = StreamController<dynamic>();

  @override
  WebSocketSink get sink => _BrokenSink();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;
}

class _BrokenSink implements WebSocketSink {
  @override
  void add(dynamic data) => throw Exception('WS broken');

  @override
  Future<void> close([int? closeCode, String? closeReason]) => Future.value();

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> addStream(Stream<dynamic> stream) async {}

  @override
  Future<dynamic> get done => Future.value();
}
