import 'package:dio/dio.dart';

import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/core/errors/exceptions.dart';

class HomeRemoteDatasource {
  HomeRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> getMatches({
    String? status,
    int page = 1,
    int limit = 20,
    String? scope,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/matches',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'status': ?status,
          'scope': ?scope,
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
