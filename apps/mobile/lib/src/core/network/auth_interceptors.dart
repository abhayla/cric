import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/datasources/firebase_auth_datasource.dart';

/// Adds auth token injection (onRequest) and 401 sign-out (onError) to a Dio instance.
void addAuthInterceptors(Dio dio, FirebaseAuthDatasource authDatasource) {
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final token = await authDatasource.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Silently continue without auth
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {
          // Best-effort sign out
        }
      }
      handler.next(error);
    },
  ));
}
