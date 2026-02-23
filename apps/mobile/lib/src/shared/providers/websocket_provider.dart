import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../data/websocket/websocket_client.dart';

/// Riverpod provider for the WebSocket client.
///
/// Passes the current Firebase ID token so the server can authenticate
/// publish_score messages. Anonymous viewers connect without a token.
final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final authDatasource = ref.read(firebaseAuthDatasourceProvider);
  final client = WebSocketClient();

  // Fetch the ID token asynchronously and update the client.
  // The token will be used on the next connect() call.
  authDatasource.getIdToken().then((token) {
    if (token != null) {
      client.updateToken(token);
    }
  });

  ref.onDispose(() => client.dispose());
  return client;
});
