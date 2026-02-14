import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/websocket/websocket_client.dart';

/// Riverpod provider for the WebSocket client.
///
/// Disposes the client when the provider is disposed.
final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});
