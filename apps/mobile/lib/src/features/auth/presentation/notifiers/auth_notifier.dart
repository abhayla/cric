import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

enum AuthStatus { idle, sendingOtp, otpSent, verifyingOtp, verified, error }

class AuthUiState {
  const AuthUiState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.phoneNumber,
  });

  final AuthStatus status;
  final String? errorMessage;
  final String? phoneNumber;

  AuthUiState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? phoneNumber,
  }) {
    return AuthUiState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AuthNotifier extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  /// Send OTP to [phoneNumber]. Returns true if codeSent callback fires.
  Future<bool> sendOtp(String phoneNumber) async {
    state = AuthUiState(
      status: AuthStatus.sendingOtp,
      phoneNumber: phoneNumber,
    );

    final completer = Completer<bool>();
    final datasource = ref.read(firebaseAuthDatasourceProvider);

    try {
      await datasource.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          state = state.copyWith(status: AuthStatus.otpSent);
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (error) {
          state = AuthUiState(
            status: AuthStatus.error,
            errorMessage: error.message,
            phoneNumber: phoneNumber,
          );
          if (!completer.isCompleted) completer.complete(false);
        },
        onAutoVerified: (credential) async {
          // Auto-verification (e.g., SMS Retriever on Android).
          // Sign in directly with the credential.
          state = state.copyWith(status: AuthStatus.verifyingOtp);
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            await _registerWithServer();
            state = state.copyWith(status: AuthStatus.verified);
          } catch (e) {
            state = AuthUiState(
              status: AuthStatus.error,
              errorMessage: e.toString(),
              phoneNumber: phoneNumber,
            );
          }
          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } on AuthException catch (e) {
      state = AuthUiState(
        status: AuthStatus.error,
        errorMessage: e.message,
        phoneNumber: phoneNumber,
      );
      if (!completer.isCompleted) completer.complete(false);
    } catch (e) {
      state = AuthUiState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        phoneNumber: phoneNumber,
      );
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  /// Register the Firebase user with the backend server.
  /// This ensures a user record exists in the DB for authenticated API calls.
  Future<void> _registerWithServer() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      await dio.post(
        '${AppConstants.apiBaseUrl}/auth/verify',
        data: {'idToken': idToken},
      );
      if (kDebugMode) {
        debugPrint('[AuthNotifier] Server registration successful');
      }
    } catch (e) {
      // Non-fatal: user can still use the app, server calls will just fail
      if (kDebugMode) {
        debugPrint('[AuthNotifier] Server registration failed: $e');
      }
    }
  }

  /// Verify OTP [smsCode]. On success, Firebase auth state changes
  /// and GoRouter redirect navigates to /home.
  Future<bool> verifyOtp(String smsCode) async {
    state = state.copyWith(status: AuthStatus.verifyingOtp);

    try {
      final datasource = ref.read(firebaseAuthDatasourceProvider);
      await datasource.verifyOtp(smsCode);
      await _registerWithServer();
      state = state.copyWith(status: AuthStatus.verified);
      return true;
    } on AuthException catch (e) {
      state = AuthUiState(
        status: AuthStatus.error,
        errorMessage: e.message,
        phoneNumber: state.phoneNumber,
      );
      return false;
    } catch (e) {
      state = AuthUiState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        phoneNumber: state.phoneNumber,
      );
      return false;
    }
  }

  /// Re-send OTP to the same phone number.
  void resendOtp() {
    final phone = state.phoneNumber;
    if (phone != null) {
      if (kDebugMode) {
        debugPrint('[AuthNotifier] Resending OTP to $phone');
      }
      sendOtp(phone);
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthUiState(
        status: state.phoneNumber != null ? AuthStatus.otpSent : AuthStatus.idle,
        phoneNumber: state.phoneNumber,
      );
    }
  }
}
