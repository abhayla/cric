import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/datasources/firebase_auth_datasource.dart';

/// Firebase Auth datasource singleton.
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>(
  (ref) => FirebaseAuthDatasource(),
);

/// Stream of Firebase auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  final datasource = ref.watch(firebaseAuthDatasourceProvider);
  return datasource.authStateChanges;
});
