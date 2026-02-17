import 'package:dio/dio.dart';

import 'delivery_record.dart';

/// Calls test verification API endpoints to verify DB state.
///
/// Used after each match to ensure the Flutter UI taps produced
/// correct delivery records, match results, and standings in PostgreSQL.
class DbVerifier {
  DbVerifier({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final String baseUrl;
  final Dio _dio;

  /// Verify all deliveries for a match against tracked taps.
  Future<DeliveryVerificationResult> verifyMatchDeliveries(
    String matchId,
    List<DeliveryRecord> expectedDeliveries,
  ) async {
    final response = await _dio.get('/api/v1/test/deliveries/$matchId');
    final serverDeliveries = response.data['deliveries'] as List;

    final mismatches = <String>[];

    if (serverDeliveries.length != expectedDeliveries.length) {
      mismatches.add(
        'Delivery count mismatch: server=${serverDeliveries.length}, '
        'expected=${expectedDeliveries.length}',
      );
    }

    final checkCount =
        serverDeliveries.length < expectedDeliveries.length
            ? serverDeliveries.length
            : expectedDeliveries.length;

    for (var i = 0; i < checkCount; i++) {
      final server = serverDeliveries[i] as Map<String, dynamic>;
      final expected = expectedDeliveries[i];

      if (server['total_runs'] != expected.totalRuns) {
        mismatches.add(
          'Delivery ${i + 1}: totalRuns server=${server['total_runs']} '
          'expected=${expected.totalRuns}',
        );
      }
      if (server['is_wicket'] != expected.isWicket) {
        mismatches.add(
          'Delivery ${i + 1}: isWicket server=${server['is_wicket']} '
          'expected=${expected.isWicket}',
        );
      }
      if (server['is_wide'] != expected.isWide) {
        mismatches.add(
          'Delivery ${i + 1}: isWide server=${server['is_wide']} '
          'expected=${expected.isWide}',
        );
      }
      if (server['is_no_ball'] != expected.isNoBall) {
        mismatches.add(
          'Delivery ${i + 1}: isNoBall server=${server['is_no_ball']} '
          'expected=${expected.isNoBall}',
        );
      }
    }

    return DeliveryVerificationResult(
      passed: mismatches.isEmpty,
      mismatches: mismatches,
      serverCount: serverDeliveries.length,
      expectedCount: expectedDeliveries.length,
    );
  }

  /// Verify match result record exists with correct winner.
  Future<MatchResultVerification> verifyMatchResult(
    String matchId, {
    String? expectedWinnerTeamId,
    String? expectedResultType,
  }) async {
    final response = await _dio.get('/api/v1/test/match-result/$matchId');
    final result = response.data['result'] as Map<String, dynamic>?;

    if (result == null) {
      return const MatchResultVerification(
        passed: false,
        message: 'No match result record found',
      );
    }

    final mismatches = <String>[];

    if (expectedWinnerTeamId != null &&
        result['winner_team_id'] != expectedWinnerTeamId) {
      mismatches.add(
        'Winner: server=${result['winner_team_id']} '
        'expected=$expectedWinnerTeamId',
      );
    }

    if (expectedResultType != null &&
        result['result_type'] != expectedResultType) {
      mismatches.add(
        'ResultType: server=${result['result_type']} '
        'expected=$expectedResultType',
      );
    }

    return MatchResultVerification(
      passed: mismatches.isEmpty,
      message: mismatches.isEmpty
          ? 'Match result verified'
          : mismatches.join('; '),
    );
  }

  /// Verify tournament standings for all teams.
  Future<StandingsVerification> verifyStandings(
    String tournamentId, {
    int expectedTeamCount = 16,
  }) async {
    final response =
        await _dio.get('/api/v1/test/standings/$tournamentId');
    final standings = response.data['standings'] as List;

    final mismatches = <String>[];

    if (standings.length != expectedTeamCount) {
      mismatches.add(
        'Team count: server=${standings.length} '
        'expected=$expectedTeamCount',
      );
    }

    // Verify all teams have valid data
    for (final standing in standings) {
      final s = standing as Map<String, dynamic>;
      final teamId = s['team_id'] as String?;

      if ((s['played'] as int?) == null || (s['played'] as int) < 0) {
        mismatches.add('Team $teamId: invalid played count');
      }
    }

    return StandingsVerification(
      passed: mismatches.isEmpty,
      mismatches: mismatches,
      teamCount: standings.length,
    );
  }

  /// Verify match awards (MOTM, best batsman, best bowler).
  Future<MatchAwardsVerification> verifyMatchAwards(
    String matchId,
  ) async {
    final response = await _dio.get('/api/v1/test/match-awards/$matchId');
    final manOfMatchId = response.data['manOfMatchId'] as String?;
    final awards = response.data['awards'] as Map<String, dynamic>?;

    return MatchAwardsVerification(
      passed: manOfMatchId != null && awards != null,
      manOfMatchId: manOfMatchId,
      bestBatsmanId: awards?['bestBatsmanId'] as String?,
      bestBatsmanRuns: (awards?['bestBatsmanRuns'] as num?)?.toInt() ?? 0,
      bestBowlerId: awards?['bestBowlerId'] as String?,
      bestBowlerWickets: (awards?['bestBowlerWickets'] as num?)?.toInt() ?? 0,
    );
  }

  /// Verify tournament leaderboard.
  Future<LeaderboardVerification> verifyLeaderboard(
    String tournamentId, {
    String category = 'runs',
  }) async {
    final response = await _dio.get(
      '/api/v1/test/leaderboard/$tournamentId',
      queryParameters: {'category': category},
    );
    final leaderboard = response.data['leaderboard'] as List;

    return LeaderboardVerification(
      passed: leaderboard.isNotEmpty,
      entryCount: leaderboard.length,
      topPlayer: leaderboard.isNotEmpty
          ? (leaderboard[0] as Map<String, dynamic>)['playerName'] as String?
          : null,
      topValue: leaderboard.isNotEmpty
          ? ((leaderboard[0] as Map<String, dynamic>)[
                  category == 'runs' ? 'totalRuns' : 'totalWickets'] as num?)
              ?.toDouble()
          : null,
    );
  }
}

/// Result of delivery verification.
class DeliveryVerificationResult {
  const DeliveryVerificationResult({
    required this.passed,
    required this.mismatches,
    required this.serverCount,
    required this.expectedCount,
  });

  final bool passed;
  final List<String> mismatches;
  final int serverCount;
  final int expectedCount;

  @override
  String toString() => passed
      ? 'PASS: $serverCount deliveries verified'
      : 'FAIL: ${mismatches.join(', ')}';
}

/// Result of match result verification.
class MatchResultVerification {
  const MatchResultVerification({
    required this.passed,
    required this.message,
  });

  final bool passed;
  final String message;

  @override
  String toString() => passed ? 'PASS: $message' : 'FAIL: $message';
}

/// Result of standings verification.
class StandingsVerification {
  const StandingsVerification({
    required this.passed,
    required this.mismatches,
    required this.teamCount,
  });

  final bool passed;
  final List<String> mismatches;
  final int teamCount;

  @override
  String toString() => passed
      ? 'PASS: $teamCount teams verified'
      : 'FAIL: ${mismatches.join(', ')}';
}

/// Result of match awards verification.
class MatchAwardsVerification {
  const MatchAwardsVerification({
    required this.passed,
    this.manOfMatchId,
    this.bestBatsmanId,
    this.bestBatsmanRuns = 0,
    this.bestBowlerId,
    this.bestBowlerWickets = 0,
  });

  final bool passed;
  final String? manOfMatchId;
  final String? bestBatsmanId;
  final int bestBatsmanRuns;
  final String? bestBowlerId;
  final int bestBowlerWickets;

  @override
  String toString() => passed
      ? 'PASS: MOTM=$manOfMatchId, BestBat=$bestBatsmanId ($bestBatsmanRuns runs), '
        'BestBowl=$bestBowlerId ($bestBowlerWickets wkts)'
      : 'FAIL: Awards not computed';
}

/// Result of leaderboard verification.
class LeaderboardVerification {
  const LeaderboardVerification({
    required this.passed,
    required this.entryCount,
    this.topPlayer,
    this.topValue,
  });

  final bool passed;
  final int entryCount;
  final String? topPlayer;
  final double? topValue;

  @override
  String toString() => passed
      ? 'PASS: $entryCount entries, top=$topPlayer ($topValue)'
      : 'FAIL: empty leaderboard';
}
