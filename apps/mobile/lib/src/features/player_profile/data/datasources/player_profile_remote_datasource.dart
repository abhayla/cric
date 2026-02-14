import 'package:dio/dio.dart';

import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/core/errors/exceptions.dart';

class PlayerProfileRemoteDatasource {
  PlayerProfileRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> getProfile(String playerId) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/players/$playerId',
      );
      return response.data['player'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>?> getStats(
    String playerId, {
    String format = 'all',
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/players/$playerId/stats',
        queryParameters: {'format': format},
      );
      return response.data['stats'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMatchHistory(
    String playerId, {
    int page = 1,
    int limit = 20,
    String? format,
    String? result,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/players/$playerId/matches',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (format != null) 'format': format,
          if (result != null) 'result': result,
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
