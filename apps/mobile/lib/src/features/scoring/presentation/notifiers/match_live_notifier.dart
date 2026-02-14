import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/websocket/websocket_client.dart';
import '../../../../shared/data/websocket/ws_message_model.dart';
import '../../../../shared/providers/websocket_provider.dart';

/// Read-only live match state for viewers watching via WebSocket.
class LiveMatchState {
  const LiveMatchState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.matchId,
    this.status,
    this.inningsNumber = 1,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.oversDisplay = '0.0',
    this.currentRunRate,
    this.requiredRunRate,
    this.target,
    this.striker,
    this.nonStriker,
    this.bowler,
    this.currentOver = const [],
    this.recentDeliveries = const [],
    this.lastDeliveryDescription,
    this.wicketNotification,
    this.inningsCompleteInfo,
    this.matchResult,
    this.error,
  });

  final ConnectionStatus connectionStatus;
  final String? matchId;
  final String? status;
  final int inningsNumber;
  final int totalRuns;
  final int totalWickets;
  final String oversDisplay;
  final double? currentRunRate;
  final double? requiredRunRate;
  final int? target;
  final WsPlayerBattingSnapshot? striker;
  final WsPlayerBattingSnapshot? nonStriker;
  final WsPlayerBowlingSnapshot? bowler;
  final List<WsOverBallDisplay> currentOver;
  final List<WsOverBallDisplay> recentDeliveries;
  final String? lastDeliveryDescription;
  final WsWicketData? wicketNotification;
  final WsInningsCompleteData? inningsCompleteInfo;
  final WsMatchCompleteData? matchResult;
  final String? error;

  bool get isMatchComplete => matchResult != null;

  LiveMatchState copyWith({
    ConnectionStatus? connectionStatus,
    String? matchId,
    String? status,
    int? inningsNumber,
    int? totalRuns,
    int? totalWickets,
    String? oversDisplay,
    double? currentRunRate,
    double? requiredRunRate,
    int? target,
    WsPlayerBattingSnapshot? striker,
    WsPlayerBattingSnapshot? nonStriker,
    WsPlayerBowlingSnapshot? bowler,
    List<WsOverBallDisplay>? currentOver,
    List<WsOverBallDisplay>? recentDeliveries,
    String? lastDeliveryDescription,
    WsWicketData? wicketNotification,
    WsInningsCompleteData? inningsCompleteInfo,
    WsMatchCompleteData? matchResult,
    String? error,
    // Sentinel flags for nullable fields.
    bool clearMatchId = false,
    bool clearStatus = false,
    bool clearCurrentRunRate = false,
    bool clearRequiredRunRate = false,
    bool clearTarget = false,
    bool clearStriker = false,
    bool clearNonStriker = false,
    bool clearBowler = false,
    bool clearLastDelivery = false,
    bool clearWicketNotification = false,
    bool clearInningsComplete = false,
    bool clearMatchResult = false,
    bool clearError = false,
  }) {
    return LiveMatchState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      matchId: clearMatchId ? null : (matchId ?? this.matchId),
      status: clearStatus ? null : (status ?? this.status),
      inningsNumber: inningsNumber ?? this.inningsNumber,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWickets: totalWickets ?? this.totalWickets,
      oversDisplay: oversDisplay ?? this.oversDisplay,
      currentRunRate: clearCurrentRunRate
          ? null
          : (currentRunRate ?? this.currentRunRate),
      requiredRunRate: clearRequiredRunRate
          ? null
          : (requiredRunRate ?? this.requiredRunRate),
      target: clearTarget ? null : (target ?? this.target),
      striker: clearStriker ? null : (striker ?? this.striker),
      nonStriker: clearNonStriker ? null : (nonStriker ?? this.nonStriker),
      bowler: clearBowler ? null : (bowler ?? this.bowler),
      currentOver: currentOver ?? this.currentOver,
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      lastDeliveryDescription: clearLastDelivery
          ? null
          : (lastDeliveryDescription ?? this.lastDeliveryDescription),
      wicketNotification: clearWicketNotification
          ? null
          : (wicketNotification ?? this.wicketNotification),
      inningsCompleteInfo: clearInningsComplete
          ? null
          : (inningsCompleteInfo ?? this.inningsCompleteInfo),
      matchResult:
          clearMatchResult ? null : (matchResult ?? this.matchResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for live match viewing via WebSocket.
class MatchLiveNotifier extends Notifier<LiveMatchState> {
  StreamSubscription<WsServerMessage>? _messageSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  @override
  LiveMatchState build() {
    ref.onDispose(() {
      _messageSubscription?.cancel();
      _statusSubscription?.cancel();
    });
    return const LiveMatchState();
  }

  WebSocketClient get _client => ref.read(websocketClientProvider);

  /// Connect to WebSocket and join the match room.
  Future<void> joinMatch(String matchId) async {
    state = state.copyWith(matchId: matchId);

    await _client.connect();

    _statusSubscription?.cancel();
    _statusSubscription = _client.statusStream.listen(_onStatusChange);

    _messageSubscription?.cancel();
    _messageSubscription = _client.messages.listen(_onMessage);

    state = state.copyWith(
      connectionStatus: _client.status,
    );

    _client.joinMatch(matchId);
  }

  /// Leave match room and reset state.
  Future<void> leaveMatch() async {
    if (state.matchId != null) {
      _client.leaveMatch(state.matchId!);
    }

    _messageSubscription?.cancel();
    _messageSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;

    await _client.disconnect();

    state = const LiveMatchState();
  }

  /// Clear the wicket notification banner.
  void dismissWicketNotification() {
    state = state.copyWith(clearWicketNotification: true);
  }

  void _onStatusChange(ConnectionStatus status) {
    state = state.copyWith(connectionStatus: status);
  }

  void _onMessage(WsServerMessage message) {
    switch (message) {
      case WsMatchStateMessage():
        _handleMatchState(message);
      case WsScoreUpdateMessage():
        _handleScoreUpdate(message);
      case WsWicketMessage():
        _handleWicket(message);
      case WsInningsCompleteMessage():
        _handleInningsComplete(message);
      case WsMatchCompleteMessage():
        _handleMatchComplete(message);
      case WsDeliveryUndoneMessage():
        _handleDeliveryUndone(message);
      case WsErrorMessage():
        state = state.copyWith(error: message.message);
    }
  }

  void _handleMatchState(WsMatchStateMessage msg) {
    final d = msg.data;
    state = state.copyWith(
      status: d.status,
      inningsNumber: d.inningsNumber,
      totalRuns: d.totalRuns,
      totalWickets: d.totalWickets,
      oversDisplay: d.overs,
      currentRunRate: d.currentRunRate,
      clearCurrentRunRate: d.currentRunRate == null,
      requiredRunRate: d.requiredRunRate,
      clearRequiredRunRate: d.requiredRunRate == null,
      target: d.target,
      clearTarget: d.target == null,
      striker: d.striker,
      clearStriker: d.striker == null,
      nonStriker: d.nonStriker,
      clearNonStriker: d.nonStriker == null,
      bowler: d.bowler,
      clearBowler: d.bowler == null,
      currentOver: d.currentOver,
      recentDeliveries: d.recentDeliveries,
      clearError: true,
    );
  }

  void _handleScoreUpdate(WsScoreUpdateMessage msg) {
    final d = msg.data;
    state = state.copyWith(
      totalRuns: d.totalRuns,
      totalWickets: d.totalWickets,
      oversDisplay: d.overs,
      currentRunRate: d.currentRunRate,
      clearCurrentRunRate: d.currentRunRate == null,
      requiredRunRate: d.requiredRunRate,
      clearRequiredRunRate: d.requiredRunRate == null,
      striker: d.striker,
      clearStriker: d.striker == null,
      nonStriker: d.nonStriker,
      clearNonStriker: d.nonStriker == null,
      bowler: d.bowler,
      clearBowler: d.bowler == null,
      currentOver: d.currentOver,
      lastDeliveryDescription: d.lastDelivery.description,
      clearError: true,
    );
  }

  void _handleWicket(WsWicketMessage msg) {
    state = state.copyWith(wicketNotification: msg.data);
  }

  void _handleInningsComplete(WsInningsCompleteMessage msg) {
    state = state.copyWith(
      target: msg.data.target,
      inningsCompleteInfo: msg.data,
    );
  }

  void _handleMatchComplete(WsMatchCompleteMessage msg) {
    state = state.copyWith(matchResult: msg.data);
  }

  void _handleDeliveryUndone(WsDeliveryUndoneMessage msg) {
    final score = msg.data.updatedScore;
    state = state.copyWith(
      totalRuns: score.runs,
      totalWickets: score.wickets,
      oversDisplay: score.overs,
      currentOver: msg.data.currentOver,
    );
  }
}
