import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class FakePhoneAuthCredential extends Fake implements PhoneAuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late FirebaseAuthDatasource datasource;

  setUpAll(() {
    registerFallbackValue(FakePhoneAuthCredential());
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    datasource = FirebaseAuthDatasource(firebaseAuth: mockFirebaseAuth);
  });

  group('authStateChanges', () {
    test('returns FirebaseAuth authStateChanges stream', () {
      final controller = StreamController<User?>();
      when(() => mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => controller.stream);

      expect(datasource.authStateChanges, isA<Stream<User?>>());

      controller.close();
    });
  });

  group('currentUser', () {
    test('returns null when not signed in', () {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(datasource.currentUser, isNull);
    });

    test('returns User when signed in', () {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      expect(datasource.currentUser, mockUser);
    });
  });

  group('getIdToken', () {
    test('returns null when no current user', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      final token = await datasource.getIdToken();
      expect(token, isNull);
    });

    test('returns token when user is signed in', () async {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken()).thenAnswer((_) async => 'test-token');

      final token = await datasource.getIdToken();
      expect(token, 'test-token');
    });
  });

  group('verifyOtp', () {
    test('throws AuthException when no verification ID', () async {
      expect(
        () => datasource.verifyOtp('123456'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signOut', () {
    test('calls FirebaseAuth.signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await datasource.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}
