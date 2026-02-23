import 'dart:async';
import 'dart:convert';

import 'package:cricscores/src/core/theme/app_colors.dart';
import 'package:cricscores/src/features/scoring/presentation/pages/live_match_page.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/batter_card.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/bowler_card.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/connection_status_banner.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/score_header.dart';
import 'package:cricscores/src/shared/data/websocket/websocket_client.dart';
import 'package:cricscores/src/shared/providers/websocket_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeChannel with StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final List<String> sentMessages = [];

  void addServerMessage(String msg) => _incoming.add(msg);

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
  late _FakeChannel fakeChannel;
  late WebSocketClient client;

  setUp(() {
    fakeChannel = _FakeChannel();
    client = WebSocketClient(
      url: 'ws://localhost:3000/ws',
      channelFactory: (_) => fakeChannel,
      reconnectEnabled: false,
    );
  });

  tearDown(() {
    client.dispose();
  });

  Widget buildPage(WidgetTester tester, {String matchId = 'test-match-1'}) {
    return ProviderScope(
      overrides: [
        websocketClientProvider.overrideWithValue(client),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.seed,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: LiveMatchPage(matchId: matchId),
      ),
    );
  }

  /// Dispose the WS client to cancel the ping timer before the test
  /// framework checks for pending timers during widget tree disposal.
  void cleanupClient() {
    client.dispose();
  }

  void sendMatchState({
    String status = 'LIVE',
    int inningsNumber = 1,
    int totalRuns = 120,
    int totalWickets = 3,
    String overs = '15.2',
    double? currentRunRate = 7.89,
    double? requiredRunRate,
    int? target,
    Map<String, dynamic>? striker,
    Map<String, dynamic>? nonStriker,
    Map<String, dynamic>? bowler,
    List<Map<String, dynamic>>? currentOver,
  }) {
    fakeChannel.addServerMessage(jsonEncode({
      'type': 'match_state',
      'matchId': 'test-match-1',
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
        'currentOver': currentOver ?? [],
        'recentDeliveries': [],
      },
    }));
  }

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

  group('LiveMatchPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      // Should show a loading/connecting state.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      cleanupClient();
    });

    testWidgets('joins match on init', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      // Should have sent join_match message.
      expect(fakeChannel.sentMessages, isNotEmpty);
      final sent = jsonDecode(fakeChannel.sentMessages.first);
      expect(sent['type'], 'join_match');
      expect(sent['matchId'], 'test-match-1');
      cleanupClient();
    });

    testWidgets('displays score after receiving match_state', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState(
        totalRuns: 120,
        totalWickets: 3,
      );
      await tester.pump();

      expect(find.text('120/3'), findsOneWidget);
      cleanupClient();
    });

    testWidgets('displays ScoreHeader widget', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState();
      await tester.pump();

      expect(find.byType(ScoreHeader), findsOneWidget);
      cleanupClient();
    });

    testWidgets('displays batter cards when striker/non-striker present',
        (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState(
        striker: sampleStriker,
        nonStriker: sampleNonStriker,
      );
      await tester.pump();

      expect(find.byType(BatterCard), findsNWidgets(2));
      expect(find.text('Kohli *'), findsOneWidget);
      expect(find.text('Rohit'), findsOneWidget);
      cleanupClient();
    });

    testWidgets('displays bowler card when bowler present', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState(bowler: sampleBowler);
      await tester.pump();

      expect(find.byType(BowlerCard), findsOneWidget);
      expect(find.text('Bumrah'), findsOneWidget);
      cleanupClient();
    });

    testWidgets('shows current over balls', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState(
        currentOver: [
          {'runs': 1, 'display': '1'},
          {'runs': 0, 'display': '.'},
          {'runs': 4, 'display': '4'},
        ],
      );
      await tester.pump();

      expect(find.text('1'), findsWidgets);
      expect(find.text('.'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      cleanupClient();
    });

    testWidgets('shows connection banner when disconnected', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      expect(find.byType(ConnectionStatusBanner), findsOneWidget);
      cleanupClient();
    });

    testWidgets('hides connection banner when connected with data',
        (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState();
      await tester.pump();

      // Banner exists but renders nothing for connected state.
      final banner = tester.widget<ConnectionStatusBanner>(
        find.byType(ConnectionStatusBanner),
      );
      expect(banner.status, ConnectionStatus.connected);
      cleanupClient();
    });

    testWidgets('displays match result when match completes', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState();
      await tester.pump();

      fakeChannel.addServerMessage(jsonEncode({
        'type': 'match_complete',
        'matchId': 'test-match-1',
        'data': {
          'winner': 'India',
          'resultType': 'runs',
          'margin': 25,
          'summary': 'India won by 25 runs',
        },
      }));
      await tester.pump();

      expect(find.text('India won by 25 runs'), findsOneWidget);
      cleanupClient();
    });

    testWidgets('displays innings complete info', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState();
      await tester.pump();

      fakeChannel.addServerMessage(jsonEncode({
        'type': 'innings_complete',
        'matchId': 'test-match-1',
        'data': {
          'inningsNumber': 1,
          'battingTeam': 'India',
          'totalRuns': 185,
          'totalWickets': 7,
          'overs': '20.0',
          'target': 186,
        },
      }));
      await tester.pump();

      // Should show target info.
      expect(find.textContaining('186'), findsWidgets);
      cleanupClient();
    });

    testWidgets('updates live when score_update arrives', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState(totalRuns: 100, totalWickets: 2);
      await tester.pump();

      expect(find.text('100/2'), findsOneWidget);

      fakeChannel.addServerMessage(jsonEncode({
        'type': 'score_update',
        'matchId': 'test-match-1',
        'data': {
          'totalRuns': 104,
          'totalWickets': 2,
          'overs': '12.4',
          'currentRunRate': 8.32,
          'requiredRunRate': null,
          'lastDelivery': {
            'runs': 4,
            'isWide': false,
            'isNoBall': false,
            'isBye': false,
            'isLegBye': false,
            'isWicket': false,
            'isBoundaryFour': true,
            'isBoundarySix': false,
            'description': 'FOUR!',
          },
          'striker': sampleStriker,
          'nonStriker': null,
          'bowler': sampleBowler,
          'currentOver': [
            {'runs': 4, 'display': '4'},
          ],
        },
      }));
      await tester.pump();

      expect(find.text('104/2'), findsOneWidget);
      cleanupClient();
    });

    testWidgets('has app bar with Live Match title', (tester) async {
      await tester.pumpWidget(buildPage(tester));
      await tester.pump();

      sendMatchState();
      await tester.pump();

      expect(find.text('Live Match'), findsOneWidget);
      cleanupClient();
    });
  });
}
