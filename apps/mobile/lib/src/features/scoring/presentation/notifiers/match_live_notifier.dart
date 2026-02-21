import 'dart:async';

import 'package:flutter/foundation.dart';
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
    this.battingTeamName = '',
    this.bowlingTeamName = '',
    this.isFreeHitPending = false,
    this.isMagicOver = false,
    this.magicOverMultiplier = 2,
    this.lastDeliveryCount = 0,
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
  final String battingTeamName;
  final String bowlingTeamName;
  final bool isFreeHitPending;
  final bool isMagicOver;
  final int magicOverMultiplier;
  final int lastDeliveryCount;

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
    String? battingTeamName,
    String? bowlingTeamName,
    bool? isFreeHitPending,
    bool? isMagicOver,
    int? magicOverMultiplier,
    int? lastDeliveryCount,
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
      battingTeamName: battingTeamName ?? this.battingTeamName,
      bowlingTeamName: bowlingTeamName ?? this.bowlingTeamName,
      isFreeHitPending: isFreeHitPending ?? this.isFreeHitPending,
      isMagicOver: isMagicOver ?? this.isMagicOver,
      magicOverMultiplier: magicOverMultiplier ?? this.magicOverMultiplier,
      lastDeliveryCount: lastDeliveryCount ?? this.lastDeliveryCount,
    );
  }
}

/// Notifier for live match viewing via WebSocket.
class MatchLiveNotifier extends Notifier<LiveMatchState> {
  StreamSubscription<WsServerMessage>? _messageSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  bool _refreshRequested = false;

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
    // Cache matchId and client before any async work — ref/state may be
    // disposed during teardown (e.g., integration test cleanup).
    final matchId = _safeMatchId;
    final client = _safeClient;

    if (matchId != null && client != null) {
      client.leaveMatch(matchId);
    }

    _messageSubscription?.cancel();
    _messageSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;

    if (client != null) {
      await client.disconnect();
    }

    // Guard against Riverpod ref being unmounted during async gap.
    try {
      state = const LiveMatchState();
    } catch (_) {
      // StateError or UnmountedRefException — provider already disposed.
    }
  }

  /// Safely read matchId without throwing if ref is already disposed.
  String? get _safeMatchId {
    try {
      return state.matchId;
    } catch (_) {
      // StateError or UnmountedRefException — provider already disposed.
      return null;
    }
  }

  /// Safely get WebSocket client without throwing if ref is already disposed.
  WebSocketClient? get _safeClient {
    try {
      return _client;
    } catch (_) {
      // UnmountedRefException — provider already disposed.
      return null;
    }
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
    _refreshRequested = false;
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
      battingTeamName: d.battingTeamName ?? '',
      bowlingTeamName: d.bowlingTeamName ?? '',
      isFreeHitPending: d.isFreeHitPending ?? false,
      isMagicOver: d.isMagicOver ?? false,
      magicOverMultiplier: d.magicOverMultiplier ?? 2,
      lastDeliveryCount: d.deliveryCount,
      clearError: true,
    );
  }

  void _handleScoreUpdate(WsScoreUpdateMessage msg) {
    final d = msg.data;
    final incoming = d.deliveryCount;

    // Gap detection: if deliveryCount is non-zero, check sequence
    if (incoming > 0 && incoming != state.lastDeliveryCount + 1) {
      // Gap detected — request full state refresh
      if (!_refreshRequested) {
        _refreshRequested = true;
        final matchId = state.matchId;
        if (matchId != null) {
          debugPrint('[WS] Gap detected: expected '
              '${state.lastDeliveryCount + 1}, got $incoming. '
              'Requesting match_state refresh.');
          _client.joinMatch(matchId);
        }
      }
      return;
    }

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
      battingTeamName: d.battingTeamName ?? state.battingTeamName,
      bowlingTeamName: d.bowlingTeamName ?? state.bowlingTeamName,
      isFreeHitPending: d.isFreeHitPending ?? false,
      isMagicOver: d.isMagicOver ?? false,
      magicOverMultiplier: d.magicOverMultiplier ?? state.magicOverMultiplier,
      lastDeliveryCount: incoming > 0 ? incoming : state.lastDeliveryCount,
      clearError: true,
    );
  }

  void _handleWicket(WsWicketMessage msg) {
    state = state.copyWith(wicketNotification: msg.data);
  }

  void _handleInningsComplete(WsInningsCompleteMessage msg) {
    // Only bump innings and reset score if this is NOT the final innings
    // (innings 2+ completion = match over, don't create phantom innings 3).
    if (msg.data.inningsNumber < 2) {
      final nextInnings = msg.data.inningsNumber + 1;
      state = state.copyWith(
        target: msg.data.target,
        inningsNumber: nextInnings,
        inningsCompleteInfo: msg.data,
        // Reset score counters for the new innings.
        totalRuns: 0,
        totalWickets: 0,
        oversDisplay: '0.0',
        clearStriker: true,
        clearNonStriker: true,
        clearBowler: true,
        clearCurrentRunRate: true,
        clearRequiredRunRate: true,
        currentOver: const [],
        isFreeHitPending: false,
        isMagicOver: false,
        lastDeliveryCount: 0,
      );
    } else {
      // Final innings — just record the completion info and target.
      state = state.copyWith(
        target: msg.data.target,
        inningsCompleteInfo: msg.data,
        isFreeHitPending: false,
        isMagicOver: false,
      );
    }
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
      isFreeHitPending: false,
    );
  }
}
