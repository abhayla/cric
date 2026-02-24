import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/data/datasources/firebase_auth_datasource.dart';

/// Firebase Auth datasource singleton.
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>(
  (ref) => FirebaseAuthDatasource(),
);

/// Stream of Firebase auth state changes.
/// Includes a 5-second timeout so the app doesn't hang on splash
/// when Firebase can't reach the network (e.g. emulator without internet).
final authStateProvider = StreamProvider<User?>((ref) {
  final datasource = ref.watch(firebaseAuthDatasourceProvider);
  final controller = StreamController<User?>();
  var hasEmitted = false;

  final sub = datasource.authStateChanges.listen(
    (user) {
      hasEmitted = true;
      controller.add(user);
    },
    onError: (Object error) {
      hasEmitted = true;
      controller.addError(error);
    },
  );

  // If Firebase doesn't emit within 5 seconds (e.g. no network on fresh
  // install), emit null so the router redirects to login instead of
  // staying stuck on splash forever.
  Future.delayed(const Duration(seconds: 5), () {
    if (!hasEmitted && !controller.isClosed) {
      controller.add(null);
    }
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// The current authenticated user's server-assigned UUID.
/// Fetches from GET /auth/me using the Firebase ID token.
/// Returns null if not authenticated or if the server call fails.
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  try {
    final idToken = await user.getIdToken();
    if (idToken == null) return null;

    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Authorization': 'Bearer $idToken'},
    ));

    final response = await dio.get('/auth/me');
    final userId = response.data['user']?['id'] as String?;
    return userId;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[currentUserIdProvider] Failed to fetch user ID: $e');
    }
    return null;
  }
});
