import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'auth_interceptors.dart';

/// Shared authenticated Dio instance for all feature API calls.
///
/// Enables HTTP keep-alive connection reuse across features instead of
/// each feature opening separate TCP connections to the same server.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  try {
    addAuthInterceptors(dio, ref.read(firebaseAuthDatasourceProvider));
  } catch (_) {
    // Provider not available (e.g., in test environment)
  }

  return dio;
});
