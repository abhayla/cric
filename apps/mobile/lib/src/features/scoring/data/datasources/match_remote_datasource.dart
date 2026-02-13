import 'package:dio/dio.dart';

import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/core/errors/exceptions.dart';

class MatchRemoteDatasource {
  MatchRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    required String format,
    required int totalOvers,
    required int ballTypeId,
    required String matchDate,
    String? venue,
    int? playersPerSide,
    int? maxOversPerBowler,
    int? wideRuns,
    int? noBallRuns,
    int? powerplayOvers,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/matches',
        data: {
          'homeTeamId': homeTeamId,
          'awayTeamId': awayTeamId,
          'format': format,
          'totalOvers': totalOvers,
          'ballTypeId': ballTypeId,
          'matchDate': matchDate,
          ?'venue': venue,
          ?'playersPerSide': playersPerSide,
          ?'maxOversPerBowler': maxOversPerBowler,
          ?'wideRuns': wideRuns,
          ?'noBallRuns': noBallRuns,
          ?'powerplayOvers': powerplayOvers,
        },
      );
      return response.data['match'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMatches({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/matches',
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMatch(String matchId) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/matches/$matchId',
      );
      return response.data['match'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> setPlayingXI(
    String matchId, {
    required String teamId,
    required List<String> playerIds,
    required String captainId,
    required String keeperId,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/matches/$matchId/playing-xi',
        data: {
          'teamId': teamId,
          'playerIds': playerIds,
          'captainId': captainId,
          'keeperId': keeperId,
        },
      );
      return (response.data['players'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> recordToss(
    String matchId, {
    required String winnerId,
    required String decision,
    required String openingStrikerId,
    required String openingNonStrikerId,
    required String openingBowlerId,
  }) async {
    try {
      final response = await dio.put(
        '${AppConstants.apiBaseUrl}/matches/$matchId/toss',
        data: {
          'winnerId': winnerId,
          'decision': decision,
          'openingStrikerId': openingStrikerId,
          'openingNonStrikerId': openingNonStrikerId,
          'openingBowlerId': openingBowlerId,
        },
      );
      return response.data['match'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = data is Map
        ? (data['error']?['message'] ?? 'Unknown error')
        : 'Request failed';

    return ServerException(message as String, null, statusCode);
  }
}
