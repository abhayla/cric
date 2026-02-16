import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
