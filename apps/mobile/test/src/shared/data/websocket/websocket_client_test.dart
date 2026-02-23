import 'dart:async';
import 'dart:convert';

import 'package:cricscores/src/shared/data/websocket/websocket_client.dart';
import 'package:cricscores/src/shared/data/websocket/ws_message_model.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Fake WebSocket channel backed by stream controllers.
class FakeWebSocketChannel with StreamChannelMixin implements WebSocketChannel {
  FakeWebSocketChannel();

  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  bool _closed = false;
  int? lastCloseCode;
  String? lastCloseReason;

  /// Simulate server sending a message to client.
  void addServerMessage(String message) {
    if (!_closed) {
      _incoming.add(message);
    }
  }

  /// Simulate server closing the connection.
  void closeFromServer({int? code, String? reason}) {
    _incoming.close();
  }

  /// Messages sent by the client.
  List<String> get sentMessages => _sentMessages;
  final List<String> _sentMessages = [];

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  int? get closeCode => lastCloseCode;

  @override
  String? get closeReason => lastCloseReason;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  void _add(dynamic data) {
    if (!_closed) {
      _sentMessages.add(data as String);
    }
  }

  Future<void> _close([int? code, String? reason]) async {
    _closed = true;
    lastCloseCode = code;
    lastCloseReason = reason;
    await _incoming.close();
  }
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._channel);
  final FakeWebSocketChannel _channel;

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

void main() {
  late FakeWebSocketChannel fakeChannel;
  late WebSocketClient client;

  setUp(() {
    fakeChannel = FakeWebSocketChannel();
    client = WebSocketClient(
      url: 'ws://localhost:3000/ws',
      channelFactory: (_) => fakeChannel,
      reconnectEnabled: false,
    );
  });

  tearDown(() {
    client.dispose();
  });

  group('Connection lifecycle', () {
    test('initial status is disconnected', () {
      expect(client.status, ConnectionStatus.disconnected);
    });

    test('connect changes status to connected', () async {
      await client.connect();
      // Allow stream events to propagate.
      await Future.delayed(Duration.zero);

      expect(client.status, ConnectionStatus.connected);
    });

    test('disconnect changes status to disconnected', () async {
      await client.connect();

      await client.disconnect();

      expect(client.status, ConnectionStatus.disconnected);
    });

    test('dispose disconnects and closes streams', () async {
      await client.connect();

      client.dispose();

      expect(client.status, ConnectionStatus.disconnected);
    });

    test('connect while already connected is a no-op', () async {
      await client.connect();

      // Second connect should not throw or create new channel.
      await client.connect();

      expect(client.status, ConnectionStatus.connected);
    });
  });

  group('Sending messages', () {
    test('joinMatch sends JSON message', () async {
      await client.connect();

      client.joinMatch('match-123');

      expect(fakeChannel.sentMessages, hasLength(1));
      final sent = jsonDecode(fakeChannel.sentMessages.first);
      expect(sent['type'], 'join_match');
      expect(sent['matchId'], 'match-123');
    });

    test('leaveMatch sends JSON message', () async {
      await client.connect();

      client.leaveMatch('match-123');

      expect(fakeChannel.sentMessages, hasLength(1));
      final sent = jsonDecode(fakeChannel.sentMessages.first);
      expect(sent['type'], 'leave_match');
      expect(sent['matchId'], 'match-123');
    });

    test('joinMatch while disconnected does nothing', () {
      client.joinMatch('match-123');
      expect(fakeChannel.sentMessages, isEmpty);
    });
  });

  group('Receiving messages', () {
    test('stream emits parsed WsServerMessage', () async {
      await client.connect();

      final messages = <WsServerMessage>[];
      client.messages.listen(messages.add);

      fakeChannel.addServerMessage(jsonEncode({
        'type': 'match_state',
        'matchId': 'm1',
        'data': {
          'status': 'LIVE',
          'inningsNumber': 1,
          'totalRuns': 100,
          'totalWickets': 2,
          'overs': '12.3',
          'currentRunRate': 8.11,
          'requiredRunRate': null,
          'target': null,
          'striker': null,
          'nonStriker': null,
          'bowler': null,
          'currentOver': <Map<String, dynamic>>[],
          'recentDeliveries': <Map<String, dynamic>>[],
        },
      }));

      await Future.delayed(Duration.zero);

      expect(messages, hasLength(1));
      expect(messages.first, isA<WsMatchStateMessage>());
    });

    test('malformed JSON emits WsErrorMessage', () async {
      await client.connect();

      final messages = <WsServerMessage>[];
      client.messages.listen(messages.add);

      fakeChannel.addServerMessage('not json');

      await Future.delayed(Duration.zero);

      expect(messages, hasLength(1));
      expect(messages.first, isA<WsErrorMessage>());
    });

    test('multiple messages emitted in order', () async {
      await client.connect();

      final messages = <WsServerMessage>[];
      client.messages.listen(messages.add);

      fakeChannel.addServerMessage(jsonEncode({
        'type': 'error',
        'message': 'first',
      }));
      fakeChannel.addServerMessage(jsonEncode({
        'type': 'error',
        'message': 'second',
      }));

      await Future.delayed(Duration.zero);

      expect(messages, hasLength(2));
      expect((messages[0] as WsErrorMessage).message, 'first');
      expect((messages[1] as WsErrorMessage).message, 'second');
    });
  });

  group('Auto-reconnect', () {
    test('reconnects on server close when enabled', () async {
      var connectCount = 0;
      FakeWebSocketChannel? currentChannel;

      final reconnectClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) {
          connectCount++;
          currentChannel = FakeWebSocketChannel();
          return currentChannel!;
        },
        reconnectEnabled: true,
        maxReconnectAttempts: 3,
        initialReconnectDelayMs: 10,
        maxReconnectDelayMs: 50,
      );

      await reconnectClient.connect();
      expect(connectCount, 1);

      // Simulate server closing connection.
      currentChannel!.closeFromServer();

      // Wait for reconnect attempt.
      await Future.delayed(const Duration(milliseconds: 100));

      expect(connectCount, greaterThan(1));

      reconnectClient.dispose();
    });

    test('does not reconnect after manual disconnect', () async {
      var connectCount = 0;

      final reconnectClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) {
          connectCount++;
          return FakeWebSocketChannel();
        },
        reconnectEnabled: true,
        maxReconnectAttempts: 3,
        initialReconnectDelayMs: 10,
        maxReconnectDelayMs: 50,
      );

      await reconnectClient.connect();
      expect(connectCount, 1);

      await reconnectClient.disconnect();

      await Future.delayed(const Duration(milliseconds: 100));

      // Should not have reconnected.
      expect(connectCount, 1);

      reconnectClient.dispose();
    });

    test('re-joins active room after reconnect', () async {
      FakeWebSocketChannel? currentChannel;

      final reconnectClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) {
          currentChannel = FakeWebSocketChannel();
          return currentChannel!;
        },
        reconnectEnabled: true,
        maxReconnectAttempts: 3,
        initialReconnectDelayMs: 10,
        maxReconnectDelayMs: 50,
      );

      await reconnectClient.connect();
      reconnectClient.joinMatch('match-abc');

      // First channel had join message.
      final firstChannel = currentChannel!;
      expect(firstChannel.sentMessages, hasLength(1));

      // Wait for reconnection to complete by listening for connected status.
      final reconnected = Completer<void>();
      final sub = reconnectClient.statusStream.listen((status) {
        if (status == ConnectionStatus.connected && !reconnected.isCompleted) {
          reconnected.complete();
        }
      });

      // Simulate server close to trigger reconnect.
      firstChannel.closeFromServer();

      // Wait for reconnect.
      await reconnected.future.timeout(const Duration(seconds: 2));
      // Allow microtask for re-join.
      await Future.delayed(const Duration(milliseconds: 20));

      // After reconnect, the new channel should have re-joined.
      final secondChannel = currentChannel!;
      expect(secondChannel, isNot(same(firstChannel)));
      final rejoinMsg = secondChannel.sentMessages
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'join_match')
          .toList();
      expect(rejoinMsg, isNotEmpty);
      expect(rejoinMsg.first['matchId'], 'match-abc');

      await sub.cancel();
      reconnectClient.dispose();
    });

    test('stops reconnecting after max attempts', () async {
      var connectCount = 0;

      // Channel factory that always fails (stream closes immediately).
      final reconnectClient = WebSocketClient(
        url: 'ws://localhost:3000/ws',
        channelFactory: (_) {
          connectCount++;
          final ch = FakeWebSocketChannel();
          // Close immediately to simulate repeated failures.
          Future.microtask(() => ch.closeFromServer());
          return ch;
        },
        reconnectEnabled: true,
        maxReconnectAttempts: 3,
        initialReconnectDelayMs: 10,
        maxReconnectDelayMs: 20,
      );

      await reconnectClient.connect();

      // Wait enough time for all retries.
      await Future.delayed(const Duration(milliseconds: 500));

      // 1 initial + up to 3 reconnect attempts = 4 max.
      expect(connectCount, lessThanOrEqualTo(5));

      reconnectClient.dispose();
    });
  });

  group('publishToMatch', () {
    test('sends correct JSON when connected', () async {
      await client.connect();

      client.publishToMatch('match-1', {'type': 'score_update', 'data': {'totalRuns': 42}});

      expect(fakeChannel.sentMessages, hasLength(1));
      final sent = jsonDecode(fakeChannel.sentMessages.first) as Map<String, dynamic>;
      expect(sent['type'], 'publish_score');
      expect(sent['matchId'], 'match-1');
      expect(sent['payload']['type'], 'score_update');
      expect(sent['payload']['data']['totalRuns'], 42);
    });

    test('does nothing when disconnected', () {
      client.publishToMatch('match-1', {'type': 'score_update'});
      expect(fakeChannel.sentMessages, isEmpty);
    });
  });

  group('activeMatchId', () {
    test('tracks active match', () async {
      await client.connect();

      expect(client.activeMatchId, isNull);

      client.joinMatch('match-1');
      expect(client.activeMatchId, 'match-1');

      client.leaveMatch('match-1');
      expect(client.activeMatchId, isNull);
    });
  });
}
