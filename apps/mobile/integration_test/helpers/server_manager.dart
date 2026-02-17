import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Manages connectivity to an externally-running Bun test server for E2E tests.
///
/// On Android emulator, `localhost` refers to the emulator itself.
/// Use `10.0.2.2` to reach the host machine where the server runs.
///
/// Start the server manually BEFORE running E2E tests:
/// ```bash
/// cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
/// ```
class ServerManager {
  ServerManager({
    this.port = 3001,
    this.healthTimeout = const Duration(seconds: 30),
  });

  final int port;
  final Duration healthTimeout;

  late final Dio _dio;

  /// On Android emulator, 10.0.2.2 maps to host machine's localhost.
  /// On real device or desktop, use localhost.
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }

  /// Verify the externally-started server is reachable and healthy.
  Future<void> startServer() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    print('[ServerManager] Checking server at $baseUrl ...');

    final deadline = DateTime.now().add(healthTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isHealthy()) {
        print('[ServerManager] Server healthy at $baseUrl');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw StateError(
      'Server not reachable at $baseUrl within ${healthTimeout.inSeconds}s.\n'
      'Start it manually: cd apps/server && PORT=$port NODE_ENV=test bun run src/index.ts',
    );
  }

  /// No-op — server is managed externally.
  Future<void> stopServer() async {
    print('[ServerManager] Server managed externally — not stopping.');
  }

  /// Reset the test database: truncate all tables, re-seed master data.
  Future<void> resetDatabase() async {
    print('[ServerManager] Resetting database...');
    try {
      await _dio.post('/api/v1/test/reset-db');
      print('[ServerManager] Database reset complete');
    } catch (e) {
      print('[ServerManager] Database reset failed: $e');
      rethrow;
    }
  }

  /// Check if the server is healthy.
  Future<bool> _isHealthy() async {
    try {
      final response = await _dio.get('/api/v1/test/health');
      return response.statusCode != null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
