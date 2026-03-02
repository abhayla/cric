/// Base exception for CricScores.
class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Server responded with an error.
class ServerException extends AppException {
  const ServerException(super.message, [super.code, this.statusCode]);

  final int? statusCode;
}

/// Network/connectivity error.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Local database error.
class CacheException extends AppException {
  const CacheException([super.message = 'Cache operation failed']);
}

/// Authentication error.
class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed']);
}

/// Converts any error to a user-friendly message for SnackBars.
///
/// Handles [NetworkException], [AuthException], [ServerException],
/// and Dio errors. Falls back to a generic message for unknown errors.
String toUserFriendlyMessage(Object error) {
  if (error is NetworkException) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (error is AuthException) {
    return 'Session expired. Please log in again.';
  }
  if (error is ServerException) {
    final statusCode = (error).statusCode;
    if (statusCode == null) return 'Something went wrong. Please try again.';
    return switch (statusCode) {
      401 => 'Session expired. Please log in again.',
      403 => 'You don\'t have permission for this action.',
      404 => 'The requested data was not found.',
      409 => 'This already exists or conflicts with existing data.',
      >= 500 => 'Something went wrong on our end. Please try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
  // Handle raw DioException (when repos don't convert)
  final errorStr = error.runtimeType.toString();
  if (errorStr.contains('DioException') || errorStr.contains('Dio')) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('connection') || msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
