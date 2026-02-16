import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../../core/errors/exceptions.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  final SmartAuth _smartAuth = SmartAuth.instance;

  String? _verificationId;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<String?> getIdToken() => currentUser?.getIdToken() ?? Future.value();

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(AuthException error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    _startSmsRetriever();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) {
        onAutoVerified?.call(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(AuthException(e.message ?? 'Phone verification failed'));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<UserCredential> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      throw const AuthException('No verification ID. Call sendOtp first.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'OTP verification failed');
    }
  }

  /// Sign in anonymously (for testing/dev purposes).
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Anonymous sign-in failed');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _verificationId = null;
  }

  void _startSmsRetriever() {
    _smartAuth.getSmsWithRetrieverApi().then((_) {
      // SMS auto-read handled by Firebase's verificationCompleted callback.
      // SmartAuth provides the app hash for SMS Retriever API registration.
    });
  }

  void dispose() {
    _smartAuth.removeSmsRetrieverApiListener();
  }
}
