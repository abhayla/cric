import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Manages the Bun test server lifecycle for E2E tests.
///
/// Spawns a Bun server process, waits for it to be healthy,
/// and provides database reset capabilities.
class ServerManager {
  ServerManager({
    this.serverDir = 'D:/Abhay/VibeCoding/cric/apps/server',
    this.port = 3001,
    this.healthTimeout = const Duration(seconds: 30),
  });

  final String serverDir;
  final int port;
  final Duration healthTimeout;

  Process? _process;
  late final Dio _dio;

  String get baseUrl => 'http://localhost:$port';

  /// Start the Bun server and wait for health check.
  Future<void> startServer() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    // Check if already running
    if (await _isHealthy()) {
      print('[ServerManager] Server already running on port $port');
      return;
    }

    print('[ServerManager] Starting Bun server on port $port...');
    _process = await Process.start(
      'bun',
      ['run', 'src/index.ts'],
      workingDirectory: serverDir,
      environment: {
        ...Platform.environment,
        'PORT': '$port',
        'NODE_ENV': 'test',
        'DATABASE_URL': 'postgresql://localhost:5432/cricapp_test_e2e',
      },
    );

    // Forward stderr for debugging
    _process!.stderr.transform(const SystemEncoding().decoder).listen(
      (line) => print('[Server STDERR] $line'),
    );

    // Wait for health
    final deadline = DateTime.now().add(healthTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isHealthy()) {
        print('[ServerManager] Server healthy on port $port');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw StateError('Server failed to start within ${healthTimeout.inSeconds}s');
  }

  /// Stop the server process.
  Future<void> stopServer() async {
    if (_process != null) {
      print('[ServerManager] Stopping server...');
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _process = null;
    }
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
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
