import 'dart:async';
import 'dart:convert';

import 'package:cricapp/src/features/scoring/presentation/notifiers/match_live_notifier.dart';
import 'package:cricapp/src/features/scoring/providers.dart';
import 'package:cricapp/src/shared/data/websocket/websocket_client.dart';
import 'package:cricapp/src/shared/data/websocket/ws_message_model.dart';
import 'package:cricapp/src/shared/providers/websocket_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:stream_channel/stream_channel.dart';

/// Minimal fake WebSocket channel for notifier tests.
class _FakeChannel with StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final List<String> sentMessages = [];

  void addServerMessage(String msg) => _incoming.add(msg);
  void closeFromServer() => _incoming.close();

  @override
  WebSocketSink get sink => _FakeSink(this);

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

class _FakeSink implements WebSocketSink {
  _FakeSink(this._channel);
  final _FakeChannel _channel;

  @override
  void add(dynamic data) => _channel.sentMessages.add(data as String);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    await _channel._incoming.close();
  }

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

void main() {
  late ProviderContainer container;
  late WebSocketClient client;
  late _FakeChannel fakeChannel;

  setUp(() {
    fakeChannel = _FakeChannel();
    client = WebSocketClient(
      url: 'ws://localhost:3000/ws',
      channelFactory: (_) => fakeChannel,
      reconnectEnabled: false,
    );
    container = ProviderContainer(
      overrides: [
        websocketClientProvider.overrideWithValue(client),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    client.dispose();
  });

  MatchLiveNotifier readNotifier() {
    return container.read(matchLiveNotifierProvider.notifier);
  }

  LiveMatchState readState() {
    return container.read(matchLiveNotifierProvider);
  }

  void sendMessage(Map<String, dynamic> json) {
    fakeChannel.addServerMessage(jsonEncode(json));
  }

  Map<String, dynamic> matchStateJson({
    String status = 'LIVE',
    int inningsNumber = 1,
    int totalRuns = 100,
    int totalWickets = 2,
    String overs = '12.3',
    double? currentRunRate = 8.11,
    double? requiredRunRate,
    int? target,
    Map<String, dynamic>? striker,
    Map<String, dynamic>? nonStriker,
    Map<String, dynamic>? bowler,
    List<Map<String, dynamic>>? currentOver,
    List<Map<String, dynamic>>? recentDeliveries,
  }) =>
      {
        'type': 'match_state',
        'matchId': 'm1',
        'data': {
          'status': status,
          'inningsNumber': inningsNumber,
          'totalRuns': totalRuns,
          'totalWickets': totalWickets,
          'overs': overs,
          'currentRunRate': currentRunRate,
          'requiredRunRate': requiredRunRate,
          'target': target,
          'striker': striker,
          'nonStriker': nonStriker,
          'bowler': bowler,
          'currentOver': currentOver ?? <Map<String, dynamic>>[],
          'recentDeliveries': recentDeliveries ?? <Map<String, dynamic>>[],
        },
      };

  final sampleStriker = {
    'id': 'p1',
    'name': 'Kohli',
    'runs': 56,
    'balls': 38,
    'fours': 6,
    'sixes': 2,
    'strikeRate': 147.37,
  };

  final sampleNonStriker = {
    'id': 'p2',
    'name': 'Rohit',
    'runs': 30,
    'balls': 22,
    'fours': 4,
    'sixes': 0,
    'strikeRate': 136.36,
  };

  final sampleBowler = {
    'id': 'b1',
    'name': 'Bumrah',
    'overs': '3.2',
    'maidens': 0,
    'runs': 24,
    'wickets': 1,
    'economy': 7.2,
  };

  group('Initial state', () {
    test('starts with disconnected status and null fields', () {
      final state = readState();

      expect(state.connectionStatus, ConnectionStatus.disconnected);
      expect(state.matchId, isNull);
      expect(state.status, isNull);
      expect(state.totalRuns, 0);
      expect(state.totalWickets, 0);
      expect(state.striker, isNull);
      expect(state.bowler, isNull);
      expect(state.currentOver, isEmpty);
    });
  });

  group('joinMatch', () {
    test('connects and sends join_match message', () async {
      final notifier = readNotifier();

      await notifier.joinMatch('m1');
      await Future.delayed(Duration.zero);

      expect(client.status, ConnectionStatus.connected);
      expect(fakeChannel.sentMessages, isNotEmpty);
      final sent = jsonDecode(fakeChannel.sentMessages.first);
      expect(sent['type'], 'join_match');
      expect(sent['matchId'], 'm1');
    });

    test('updates matchId in state', () async {
      final notifier = readNotifier();

      await notifier.joinMatch('m1');

      final state = readState();
      expect(state.matchId, 'm1');
    });
  });

  group('match_state message', () {
    test('populates all state fields', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson(
        striker: sampleStriker,
        nonStriker: sampleNonStriker,
        bowler: sampleBowler,
        currentOver: [
          {'runs': 1, 'display': '1'},
          {'runs': 0, 'display': '.'},
        ],
      ));
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.status, 'LIVE');
      expect(state.inningsNumber, 1);
      expect(state.totalRuns, 100);
      expect(state.totalWickets, 2);
      expect(state.oversDisplay, '12.3');
      expect(state.currentRunRate, 8.11);
      expect(state.striker, isNotNull);
      expect(state.striker!.name, 'Kohli');
      expect(state.nonStriker, isNotNull);
      expect(state.bowler, isNotNull);
      expect(state.currentOver, hasLength(2));
    });

    test('handles 2nd innings with target', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson(
        inningsNumber: 2,
        totalRuns: 50,
        totalWickets: 1,
        overs: '6.0',
        requiredRunRate: 9.5,
        target: 186,
      ));
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.inningsNumber, 2);
      expect(state.target, 186);
      expect(state.requiredRunRate, 9.5);
    });
  });

  group('score_update message', () {
    test('updates score and player snapshots', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      // First set initial state.
      sendMessage(matchStateJson(
        striker: sampleStriker,
        bowler: sampleBowler,
      ));
      await Future.delayed(Duration.zero);

      // Then score update.
      sendMessage({
        'type': 'score_update',
        'matchId': 'm1',
        'data': {
          'totalRuns': 101,
          'totalWickets': 2,
          'overs': '12.4',
          'currentRunRate': 8.14,
          'requiredRunRate': null,
          'lastDelivery': {
            'runs': 1,
            'isWide': false,
            'isNoBall': false,
            'isBye': false,
            'isLegBye': false,
            'isWicket': false,
            'isBoundaryFour': false,
            'isBoundarySix': false,
            'description': 'Single',
          },
          'striker': {
            'id': 'p1',
            'name': 'Kohli',
            'runs': 57,
            'balls': 39,
            'fours': 6,
            'sixes': 2,
            'strikeRate': 146.15,
          },
          'nonStriker': null,
          'bowler': sampleBowler,
          'currentOver': [
            {'runs': 1, 'display': '1'},
          ],
        },
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.totalRuns, 101);
      expect(state.totalWickets, 2);
      expect(state.oversDisplay, '12.4');
      expect(state.striker!.runs, 57);
      expect(state.lastDeliveryDescription, 'Single');
      expect(state.currentOver, hasLength(1));
    });
  });

  group('wicket message', () {
    test('stores wicket notification', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson());
      await Future.delayed(Duration.zero);

      sendMessage({
        'type': 'wicket',
        'matchId': 'm1',
        'data': {
          'dismissedPlayer': 'Rohit Sharma',
          'dismissalType': 'caught',
          'fielder': 'Smith',
          'bowler': 'Starc',
          'description': 'c Smith b Starc',
          'teamScore': '100/3',
          'overs': '12.4',
        },
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.wicketNotification, isNotNull);
      expect(state.wicketNotification!.dismissedPlayer, 'Rohit Sharma');
      expect(state.wicketNotification!.description, 'c Smith b Starc');
    });
  });

  group('innings_complete message', () {
    test('sets target and innings complete info', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson());
      await Future.delayed(Duration.zero);

      sendMessage({
        'type': 'innings_complete',
        'matchId': 'm1',
        'data': {
          'inningsNumber': 1,
          'battingTeam': 'India',
          'totalRuns': 185,
          'totalWickets': 7,
          'overs': '20.0',
          'target': 186,
        },
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.target, 186);
      expect(state.inningsCompleteInfo, isNotNull);
      expect(state.inningsCompleteInfo!.battingTeam, 'India');
    });
  });

  group('match_complete message', () {
    test('sets match result', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson());
      await Future.delayed(Duration.zero);

      sendMessage({
        'type': 'match_complete',
        'matchId': 'm1',
        'data': {
          'winner': 'India',
          'resultType': 'runs',
          'margin': 25,
          'summary': 'India won by 25 runs',
        },
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.matchResult, isNotNull);
      expect(state.matchResult!.summary, 'India won by 25 runs');
      expect(state.isMatchComplete, true);
    });
  });

  group('delivery_undone message', () {
    test('updates score from undo data', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson(totalRuns: 100, totalWickets: 2));
      await Future.delayed(Duration.zero);

      sendMessage({
        'type': 'delivery_undone',
        'matchId': 'm1',
        'data': {
          'inningsId': 'inn1',
          'removedDeliveryId': 'del1',
          'updatedScore': {
            'runs': 99,
            'wickets': 2,
            'overs': '12.2',
          },
          'updatedBatterStats': null,
          'updatedBowlerStats': null,
          'currentOver': [
            {'runs': 0, 'display': '.'},
          ],
        },
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.totalRuns, 99);
      expect(state.oversDisplay, '12.2');
      expect(state.currentOver, hasLength(1));
    });
  });

  group('error message', () {
    test('sets error string', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage({
        'type': 'error',
        'message': 'Match not found',
      });
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.error, 'Match not found');
    });
  });

  group('leaveMatch', () {
    test('disconnects and resets state', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson(totalRuns: 100));
      await Future.delayed(Duration.zero);

      await notifier.leaveMatch();

      final state = readState();
      expect(state.matchId, isNull);
      expect(state.totalRuns, 0);
      expect(state.status, isNull);
    });
  });

  group('connection status', () {
    test('reflects client connection status', () async {
      final notifier = readNotifier();

      expect(readState().connectionStatus, ConnectionStatus.disconnected);

      await notifier.joinMatch('m1');

      expect(readState().connectionStatus, ConnectionStatus.connected);
    });
  });

  group('dismissWicketNotification', () {
    test('clears wicket notification', () async {
      final notifier = readNotifier();
      await notifier.joinMatch('m1');

      sendMessage(matchStateJson());
      await Future.delayed(Duration.zero);

      sendMessage({
        'type': 'wicket',
        'matchId': 'm1',
        'data': {
          'dismissedPlayer': 'Test',
          'dismissalType': 'bowled',
          'fielder': null,
          'bowler': 'Bowler',
          'description': 'b Bowler',
          'teamScore': '10/1',
          'overs': '2.0',
        },
      });
      await Future.delayed(Duration.zero);

      expect(readState().wicketNotification, isNotNull);

      notifier.dismissWicketNotification();

      expect(readState().wicketNotification, isNull);
    });
  });
}
