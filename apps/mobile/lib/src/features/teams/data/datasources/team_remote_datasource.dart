import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/core/errors/exceptions.dart';
import '../models/team_model.dart';

class TeamRemoteDatasource {
  TeamRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> createTeam({
    required String name,
    String? location,
    String? logoUrl,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/teams',
        data: {
          'name': name,
          if (location != null) 'location': location,
          if (logoUrl != null) 'logoUrl': logoUrl,
        },
      );
      return response.data['team'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTeams({int page = 1, int limit = 20}) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/teams',
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTeam(String teamId) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/teams/$teamId',
      );
      return response.data['team'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateTeam(
    String teamId, {
    String? name,
    String? location,
    String? logoUrl,
  }) async {
    try {
      final response = await dio.put(
        '${AppConstants.apiBaseUrl}/teams/$teamId',
        data: {
          if (name != null) 'name': name,
          if (location != null) 'location': location,
          if (logoUrl != null) 'logoUrl': logoUrl,
        },
      );
      return response.data['team'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await dio.delete('${AppConstants.apiBaseUrl}/teams/$teamId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> addPlayer(
    String teamId, {
    required String playerId,
    int? jerseyNumber,
    String? role,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/teams/$teamId/players',
        data: {
          'playerId': playerId,
          if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
          if (role != null) 'role': role,
        },
      );
      return response.data['rosterEntry'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> removePlayer(String teamId, String playerId) async {
    try {
      await dio.delete(
        '${AppConstants.apiBaseUrl}/teams/$teamId/players/$playerId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchPlayers(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/players/search',
        queryParameters: {'q': query, 'limit': limit.toString()},
      );
      return (response.data['players'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>?> searchPlayerByPhone(String phone) async {
    try {
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/players/search-by-phone',
        queryParameters: {'phone': phone},
      );
      return response.data['player'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createPlayer({
    required String displayName,
    String? phone,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/players',
        data: {
          'displayName': displayName,
          if (phone != null) 'phone': phone,
          if (playerRole != null) 'playerRole': playerRole,
          if (battingStyle != null) 'battingStyle': battingStyle,
          if (bowlingStyle != null) 'bowlingStyle': bowlingStyle,
        },
      );
      return response.data['player'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadImage(XFile file) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/uploads/image',
        data: formData,
      );
      return response.data['url'] as String;
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
    final message = data is Map ? (data['error']?['message'] ?? 'Unknown error') : 'Request failed';

    return ServerException(message as String, null, statusCode);
  }
}
