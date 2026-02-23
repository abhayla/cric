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
