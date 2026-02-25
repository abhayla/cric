/// App bootstrap for integration tests — Firebase init, phone OTP login,
/// pump app and wait for home page.
///
/// Extracted from the old app_test_wrapper.dart (same logic, cleaner name).
library;

import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/app/app.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/providers/database_provider.dart';

import '../config/constants.dart';

/// Whether Firebase has been initialized in this test process.
bool _firebaseInitialized = false;

/// Initialize Firebase if not already done. Safe to call multiple times.
Future<void> _ensureFirebaseInitialized() async {
  if (_firebaseInitialized) return;
  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
  } catch (e) {
    if (e.toString().contains('already been initialized')) {
      _firebaseInitialized = true;
    } else {
      rethrow;
    }
  }
}

/// Pump the app, log in via Firebase phone auth with the given phone number,
/// and wait for the My Cricket page to appear.
///
/// [phoneNumber] defaults to scorer phone (9999999999). Pass viewer phone
/// (9999999998) for the viewer device so scorer and viewer have distinct UIDs.
///
/// Polls for `find.text('My Cricket')` with a 180s timeout to accommodate
/// real device Firebase init, which can be much slower than emulator.
Future<void> pumpAppAndWaitForHome(
  WidgetTester tester, {
  String phoneNumber = scorerPhone,
}) async {
  await _ensureFirebaseInitialized();
  final db = AppDatabase(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const CricScores(),
    ),
  );

  // Wait for initial route to render (splash → login redirect)
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Try to log in with Firebase test phone number.
  await _loginWithTestPhone(tester, phoneNumber: phoneNumber);

  // Poll for My Cricket text with timeout
  final deadline = DateTime.now().add(
    const Duration(seconds: loginTimeoutSeconds),
  );
  var found = false;

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      found = true;
      break;
    }
  }

  if (!found) {
    throw TestFailure(
      'My Cricket page did not appear within ${loginTimeoutSeconds}s. '
      'Check Firebase init and network connectivity on this device.',
    );
  }
}

/// Log in using a Firebase test phone number (OTP: 123456).
///
/// If the app is already past the login page (persistent auth session),
/// this is a no-op.
Future<void> _loginWithTestPhone(
  WidgetTester tester, {
  required String phoneNumber,
}) async {
  print('[login] Starting login with phone: $phoneNumber');

  // Wait for the login page to appear after splash redirect
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('Send OTP').evaluate().isNotEmpty) {
      print('[login] Login page appeared at ${i * 500}ms');
      break;
    }
    // Already on home? Skip login.
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      print('[login] Already on home — skipping login');
      return;
    }
  }

  // If we're not on the login page, skip (already authenticated)
  if (find.text('Send OTP').evaluate().isEmpty) {
    print('[login] No Send OTP button — may be authenticated');
    return;
  }

  // Enter phone number (use the last TextField — the phone input, not country search)
  final phoneField = find.byType(TextField);
  if (phoneField.evaluate().isEmpty) {
    print('[login] No TextField found on login page');
    return;
  }
  await tester.enterText(phoneField.last, phoneNumber);
  await tester.pump(const Duration(milliseconds: 300));
  print('[login] Entered phone number');

  // Tap Send OTP
  final sendOtpButton = find.text('Send OTP');
  if (sendOtpButton.evaluate().isEmpty) {
    print('[login] Send OTP button not found after entering phone');
    return;
  }
  await tester.tap(sendOtpButton.first);
  print('[login] Tapped Send OTP');

  // Wait for OTP page or home (auto-verified test phone may skip OTP page)
  final otpDeadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(otpDeadline)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      print('[login] Auto-verified — landed on home');
      return;
    }
    if (find.text('Verify').evaluate().isNotEmpty &&
        find.text('Enter Verification Code').evaluate().isNotEmpty) {
      print('[login] OTP page appeared');
      break;
    }
  }

  if (find.text('Verify').evaluate().isEmpty) {
    if (find.text('My Cricket').evaluate().isNotEmpty) return;
    throw TestFailure(
      'OTP page did not appear after tapping Send OTP (60s). '
      'Check Firebase test phone number configuration.',
    );
  }

  // Enter OTP digits one by one into the 6 individual TextFields
  final otpFields = find.byType(TextField);
  print('[login] Found ${otpFields.evaluate().length} TextFields on OTP page');
  if (otpFields.evaluate().length >= 6) {
    for (var i = 0; i < 6; i++) {
      await tester.enterText(otpFields.at(i), testOtpCode[i]);
      await tester.pump(const Duration(milliseconds: 100));
    }
    print('[login] Entered OTP digits');
  }

  // Wait for OTP auto-verify + GoRouter redirect to /home
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      print('[login] Home page appeared after OTP verification');
      break;
    }
  }
}
