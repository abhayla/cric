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

  /// Create a player (user) via API. Returns the player ID.
  Future<String> createPlayerApi(String displayName, {String? playerRole}) async {
    final response = await _dio.post('/api/v1/players', data: {
      'displayName': displayName,
      if (playerRole != null) 'playerRole': playerRole,
    });
    return response.data['player']['id'] as String;
  }

  /// Create a team via API. Returns the team ID.
  Future<String> createTeamApi(String name) async {
    final response = await _dio.post('/api/v1/teams', data: {'name': name});
    return response.data['team']['id'] as String;
  }

  /// Add a player to a team roster via API.
  Future<void> addPlayerToTeamApi(String teamId, String playerId) async {
    await _dio.post('/api/v1/teams/$teamId/players', data: {
      'playerId': playerId,
    });
  }

  /// Create a tournament via API. Returns the tournament ID.
  Future<String> createTournamentApi({
    required String name,
    required String format,
    required int oversPerMatch,
    int ballTypeId = 1,
    int? numGroups,
    int? qualifyPerGroup,
    int? playersPerSide,
  }) async {
    final response = await _dio.post('/api/v1/tournaments', data: {
      'name': name,
      'format': format,
      'oversPerMatch': oversPerMatch,
      'ballTypeId': ballTypeId,
      if (numGroups != null) 'numGroups': numGroups,
      if (qualifyPerGroup != null) 'qualifyPerGroup': qualifyPerGroup,
      if (playersPerSide != null) 'playersPerSide': playersPerSide,
    });
    return response.data['tournament']['id'] as String;
  }

  /// Add a team to a tournament via API.
  Future<void> addTeamToTournamentApi(
    String tournamentId,
    String teamId, {
    String? groupName,
  }) async {
    await _dio.post('/api/v1/tournaments/$tournamentId/teams', data: {
      'teamId': teamId,
      if (groupName != null) 'groupName': groupName,
    });
  }

  /// Generate fixtures for a tournament via API.
  Future<void> generateFixturesApi(String tournamentId) async {
    await _dio.post('/api/v1/tournaments/$tournamentId/fixtures/generate');
  }

  /// Get fixtures for a tournament via API.
  Future<List<Map<String, dynamic>>> getFixturesApi(String tournamentId) async {
    final response = await _dio.get('/api/v1/tournaments/$tournamentId/fixtures');
    return (response.data['fixtures'] as List).cast<Map<String, dynamic>>();
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
