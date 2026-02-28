import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../data/websocket/websocket_client.dart';

/// Riverpod provider for the WebSocket client.
///
/// Awaits the Firebase ID token so the server can authenticate the connection
/// and subscribe the user to their notification topic.
final websocketClientProvider = FutureProvider<WebSocketClient>((ref) async {
  final authDatasource = ref.read(firebaseAuthDatasourceProvider);
  final token = await authDatasource.getIdToken();
  final client = WebSocketClient(token: token);
  ref.onDispose(() => client.dispose());
  return client;
});
