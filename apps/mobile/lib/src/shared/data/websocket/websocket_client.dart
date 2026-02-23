import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/app_constants.dart';
import 'ws_message_model.dart';

/// WebSocket connection status.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket client for live match updates.
///
/// Supports auto-reconnect with exponential backoff and room management.
class WebSocketClient {
  WebSocketClient({
    String? url,
    String? token,
    WebSocketChannel Function(Uri)? channelFactory,
    bool reconnectEnabled = true,
    int maxReconnectAttempts = AppConstants.wsReconnectMaxAttempts,
    int initialReconnectDelayMs = AppConstants.wsReconnectInitialDelayMs,
    int maxReconnectDelayMs = AppConstants.wsReconnectMaxDelayMs,
  })  : _url = url ?? AppConstants.wsBaseUrl,
        _token = token,
        _channelFactory = channelFactory ?? _defaultChannelFactory,
        _reconnectEnabled = reconnectEnabled,
        _maxReconnectAttempts = maxReconnectAttempts,
        _initialReconnectDelayMs = initialReconnectDelayMs,
        _maxReconnectDelayMs = maxReconnectDelayMs;

  final String _url;
  String? _token;
  final WebSocketChannel Function(Uri) _channelFactory;
  final bool _reconnectEnabled;
  final int _maxReconnectAttempts;
  final int _initialReconnectDelayMs;
  final int _maxReconnectDelayMs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;
  bool _disposed = false;

  final _messageController = StreamController<WsServerMessage>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _activeMatchId;

  /// Current connection status.
  ConnectionStatus get status => _status;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Stream of parsed server messages.
  Stream<WsServerMessage> get messages => _messageController.stream;

  /// Currently joined match room.
  String? get activeMatchId => _activeMatchId;

  /// Connect to the WebSocket server.
  Future<void> connect() async {
    if (_status == ConnectionStatus.connected || _disposed) return;

    _setStatus(ConnectionStatus.connecting);
    _manualDisconnect = false;

    try {
      final wsUrl = _token != null
          ? '$_url?token=${Uri.encodeComponent(_token!)}'
          : _url;
      _channel = _channelFactory(Uri.parse(wsUrl));
      _setStatus(ConnectionStatus.connected);
      _startPingTimer();

      _subscription = _channel!.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
      );
    } catch (e) {
      _setStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopPingTimer();
    _activeMatchId = null;
    await _cleanup();
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Join a match room to receive live updates.
  void joinMatch(String matchId) {
    if (_status != ConnectionStatus.connected) return;
    _activeMatchId = matchId;
    _send({'type': 'join_match', 'matchId': matchId});
  }

  /// Leave a match room.
  void leaveMatch(String matchId) {
    if (_status != ConnectionStatus.connected) return;
    _send({'type': 'leave_match', 'matchId': matchId});
    if (_activeMatchId == matchId) {
      _activeMatchId = null;
    }
  }

  /// Reset reconnect counter and attempt to connect.
  ///
  /// Use this when the user explicitly taps a retry/reconnect button.
  Future<void> reconnect() async {
    _reconnectAttempts = 0;
    _manualDisconnect = false;
    await connect();
    if (_status == ConnectionStatus.connected && _activeMatchId != null) {
      joinMatch(_activeMatchId!);
    }
  }

  /// Publish a score update to a match room (fast path for scorer).
  void publishToMatch(String matchId, Map<String, dynamic> payload) {
    if (_status != ConnectionStatus.connected) {
      if (kDebugMode) {
        debugPrint('[WS] Message dropped — not connected '
            '(status: $_status, type: ${payload['type']})');
      }
      return;
    }
    _send({'type': 'publish_score', 'matchId': matchId, 'payload': payload});
  }

  /// Update the auth token (e.g. after refresh).
  ///
  /// Takes effect on the next connection attempt.
  void updateToken(String? token) {
    _token = token;
  }

  /// Dispose all resources.
  void dispose() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopPingTimer();
    _status = ConnectionStatus.disconnected;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _disposed = true;
    _messageController.close();
    _statusController.close();
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_status == ConnectionStatus.connected) {
        _send({'type': 'ping'});
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _onData(dynamic data) {
    // Receiving data proves the connection is stable — reset reconnect counter.
    _reconnectAttempts = 0;
    if (data is String) {
      final message = parseServerMessage(data);
      _messageController.add(message);
    }
  }

  void _onDone() {
    _stopPingTimer();
    _cleanup();
    if (!_manualDisconnect && !_disposed) {
      _setStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _onError(Object error) {
    _stopPingTimer();
    _cleanup();
    if (!_manualDisconnect && !_disposed) {
      _setStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_reconnectEnabled || _manualDisconnect || _disposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    final delayMs = min(
      _initialReconnectDelayMs * pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelayMs,
    );

    _reconnectAttempts++;
    _setStatus(ConnectionStatus.reconnecting);

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_manualDisconnect || _disposed) return;
      await connect();
      // Re-join active room after reconnect.
      if (_status == ConnectionStatus.connected && _activeMatchId != null) {
        joinMatch(_activeMatchId!);
      }
    });
  }

  Future<void> _cleanup() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {
      // Ignore close errors.
    }
    _channel = null;
  }

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus && !_disposed) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  static WebSocketChannel _defaultChannelFactory(Uri uri) {
    return WebSocketChannel.connect(uri);
  }
}
