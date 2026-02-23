import 'package:dio/dio.dart';

import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/core/errors/exceptions.dart';

class UpdatesRemoteDatasource {
  UpdatesRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> getActivityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/activity-feed',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markAsRead(List<String> eventIds) async {
    try {
      await dio.post(
        '${AppConstants.apiBaseUrl}/activity-feed/read',
        data: {'eventIds': eventIds},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/activity-feed/unread-count',
      );
      return (response.data as Map<String, dynamic>)['count'] as int;
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
