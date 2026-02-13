import 'package:dio/dio.dart';

import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/core/errors/exceptions.dart';

class TournamentRemoteDatasource {
  TournamentRemoteDatasource({required this.dio});

  final Dio dio;
  static const _base = '${AppConstants.apiBaseUrl}/tournaments';

  // -- CRUD --

  Future<Map<String, dynamic>> createTournament({
    required String name,
    required String format,
    required int oversPerMatch,
    required int ballTypeId,
    int? pointsWin,
    int? pointsTie,
    int? pointsNoResult,
    int? pointsLoss,
    int? numGroups,
    int? qualifyPerGroup,
    bool? hasThirdPlaceMatch,
    int? playersPerSide,
    int? maxOversPerBowler,
    int? wideRuns,
    int? noBallRuns,
    int? powerplayOvers,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await dio.post(
        _base,
        data: {
          'name': name,
          'format': format,
          'oversPerMatch': oversPerMatch,
          'ballTypeId': ballTypeId,
          ?'pointsWin': pointsWin,
          ?'pointsTie': pointsTie,
          ?'pointsNoResult': pointsNoResult,
          ?'pointsLoss': pointsLoss,
          ?'numGroups': numGroups,
          ?'qualifyPerGroup': qualifyPerGroup,
          ?'hasThirdPlaceMatch': hasThirdPlaceMatch,
          ?'playersPerSide': playersPerSide,
          ?'maxOversPerBowler': maxOversPerBowler,
          ?'wideRuns': wideRuns,
          ?'noBallRuns': noBallRuns,
          ?'powerplayOvers': powerplayOvers,
          ?'startDate': startDate,
          ?'endDate': endDate,
        },
      );
      return response.data['tournament'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await dio.get(
        _base,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          ?'status': status,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTournament(String tournamentId) async {
    try {
      final response = await dio.get('$_base/$tournamentId');
      return response.data['tournament'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateTournament(
    String tournamentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('$_base/$tournamentId', data: data);
      return response.data['tournament'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> transitionStatus(
    String tournamentId,
    String newStatus,
  ) async {
    try {
      final response = await dio.put(
        '$_base/$tournamentId/status',
        data: {'status': newStatus},
      );
      return response.data['tournament'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // -- Team Management --

  Future<Map<String, dynamic>> addTeam(
    String tournamentId, {
    required String teamId,
    String? groupName,
    int? seedNumber,
  }) async {
    try {
      final response = await dio.post(
        '$_base/$tournamentId/teams',
        data: {
          'teamId': teamId,
          ?'groupName': groupName,
          ?'seedNumber': seedNumber,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerTeam(
    String tournamentId, {
    required String teamId,
  }) async {
    try {
      final response = await dio.post(
        '$_base/$tournamentId/register',
        data: {'teamId': teamId},
      );
      return response.data['request'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getRequests(
    String tournamentId, {
    String? status,
  }) async {
    try {
      final response = await dio.get(
        '$_base/$tournamentId/requests',
        queryParameters: {?'status': status},
      );
      return (response.data['requests'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> resolveRequest(
    String tournamentId,
    String requestId, {
    required String status,
    String? groupName,
    int? seedNumber,
    String? rejectionReason,
  }) async {
    try {
      final response = await dio.put(
        '$_base/$tournamentId/requests/$requestId',
        data: {
          'status': status,
          ?'groupName': groupName,
          ?'seedNumber': seedNumber,
          ?'rejectionReason': rejectionReason,
        },
      );
      return response.data['request'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> removeTeam(String tournamentId, String teamId) async {
    try {
      await dio.delete('$_base/$tournamentId/teams/$teamId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // -- Fixtures --

  Future<Map<String, dynamic>> generateFixtures(String tournamentId) async {
    try {
      final response = await dio.post('$_base/$tournamentId/fixtures/generate');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getFixtures(
    String tournamentId, {
    String? roundType,
    String? groupName,
  }) async {
    try {
      final response = await dio.get(
        '$_base/$tournamentId/fixtures',
        queryParameters: {
          ?'roundType': roundType,
          ?'groupName': groupName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> editFixture(
    String tournamentId,
    String fixtureId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '$_base/$tournamentId/fixtures/$fixtureId',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // -- Standings & Leaderboard --

  Future<Map<String, dynamic>> getStandings(
    String tournamentId, {
    String? groupName,
  }) async {
    try {
      final response = await dio.get(
        '$_base/$tournamentId/standings',
        queryParameters: {?'groupName': groupName},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getLeaderboard(
    String tournamentId, {
    required String category,
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '$_base/$tournamentId/leaderboard',
        queryParameters: {
          'category': category,
          'limit': limit.toString(),
        },
      );
      return response.data as Map<String, dynamic>;
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
