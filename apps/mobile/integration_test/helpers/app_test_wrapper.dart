import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/app/app.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/providers/database_provider.dart';

/// Whether Firebase has been initialized in this test process.
bool _firebaseInitialized = false;

/// Firebase test phone numbers configured in Firebase Console.
/// Scorer uses device 1, viewer uses device 2 — distinct Firebase UIDs.
const testPhoneDevice1 = '9999999999';
const testPhoneDevice2 = '9999999998';

/// Fixed OTP code for both test phone numbers.
const testOtpCode = '123456';

/// Wraps the full CricScores in a ProviderScope for E2E testing.
///
/// Use [pumpApp] for single-device tests, [pumpAppAndWaitForHome] for
/// multi-device tests where Firebase init may be slower on real devices.
class AppTestWrapper {
  /// Initialize Firebase if not already done. Safe to call multiple times.
  static Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    try {
      await Firebase.initializeApp();
      _firebaseInitialized = true;
    } catch (e) {
      // Already initialized (e.g. hot restart) — that's fine
      if (e.toString().contains('already been initialized')) {
        _firebaseInitialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// Create and pump the full app with optional provider overrides.
  static Future<void> pumpApp(WidgetTester tester) async {
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
    // Use pump with fixed duration instead of pumpAndSettle to avoid
    // timeout from continuous animations (loading spinners, shimmers).
    // Give the app time to initialize, load route, and render.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Pump the app, go through Firebase phone auth with the test phone
  /// number, and wait for the My Cricket page to appear.
  ///
  /// [phoneNumber] defaults to [testPhoneDevice1]. Pass [testPhoneDevice2]
  /// for the viewer device so scorer and viewer have distinct Firebase UIDs.
  ///
  /// Polls for `find.text('My Cricket')` with a 180s timeout to accommodate
  /// real device Firebase init, which can be much slower than emulator.
  static Future<void> pumpAppAndWaitForHome(
    WidgetTester tester, {
    String phoneNumber = testPhoneDevice1,
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
    // If already authenticated (e.g. persistent Firebase session), skip login.
    await loginWithTestPhone(tester, phoneNumber: phoneNumber);

    // Poll for My Cricket text with 180s timeout
    final deadline = DateTime.now().add(const Duration(seconds: 180));
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
        'My Cricket page did not appear within 180s. '
        'Check Firebase init and network connectivity on this device.',
      );
    }
  }

  /// Log in using a Firebase test phone number (OTP: 123456).
  ///
  /// [phoneNumber] defaults to [testPhoneDevice1] (9999999999).
  /// Pass [testPhoneDevice2] (9999999998) for the viewer device.
  ///
  /// If the app is already past the login page (e.g. persistent auth session),
  /// this is a no-op.
  static Future<void> loginWithTestPhone(
    WidgetTester tester, {
    String phoneNumber = testPhoneDevice1,
  }) async {
    print('[loginWithTestPhone] Starting login with phone: $phoneNumber');

    // Wait a bit for the login page to appear after splash redirect
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Send OTP').evaluate().isNotEmpty) {
        print('[loginWithTestPhone] Login page appeared at ${i * 500}ms');
        break;
      }
      // Already on home? Skip login.
      if (find.text('My Cricket').evaluate().isNotEmpty) {
        print('[loginWithTestPhone] Already on home — skipping login');
        return;
      }
    }

    // If we're not on the login page, skip (already authenticated)
    if (find.text('Send OTP').evaluate().isEmpty) {
      print('[loginWithTestPhone] No Send OTP button — may be authenticated');
      return;
    }

    // Enter phone number
    final phoneField = find.byType(TextField);
    if (phoneField.evaluate().isEmpty) {
      print('[loginWithTestPhone] No TextField found on login page');
      return;
    }

    // Find the phone number TextField (the one with digits-only formatter,
    // not the country search field). It's the last TextField on the login page.
    await tester.enterText(phoneField.last, phoneNumber);
    await tester.pump(const Duration(milliseconds: 300));
    print('[loginWithTestPhone] Entered phone number');

    // Tap Send OTP
    final sendOtpButton = find.text('Send OTP');
    if (sendOtpButton.evaluate().isEmpty) {
      print('[loginWithTestPhone] Send OTP button not found after entering phone');
      return;
    }
    await tester.tap(sendOtpButton.first);
    print('[loginWithTestPhone] Tapped Send OTP');

    // Wait for OTP page or home (auto-verified test phone may skip OTP page)
    final otpDeadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(otpDeadline)) {
      await tester.pump(const Duration(milliseconds: 500));
      // Auto-verified — skipped directly to home
      if (find.text('My Cricket').evaluate().isNotEmpty) {
        print('[loginWithTestPhone] Auto-verified — landed on home');
        return;
      }
      if (find.text('Verify').evaluate().isNotEmpty &&
          find.text('Enter Verification Code').evaluate().isNotEmpty) {
        print('[loginWithTestPhone] OTP page appeared');
        break;
      }
    }

    if (find.text('Verify').evaluate().isEmpty) {
      // OTP page didn't appear — may have auto-verified (test phone)
      // or there was an error. Check if we're already on home.
      if (find.text('My Cricket').evaluate().isNotEmpty) return;
      throw TestFailure(
        'OTP page did not appear after tapping Send OTP (60s). '
        'Check Firebase test phone number configuration.',
      );
    }

    // Enter OTP digits one by one into the 6 individual TextFields
    // The OTP page has 6 single-digit TextFields
    final otpFields = find.byType(TextField);
    print('[loginWithTestPhone] Found ${otpFields.evaluate().length} TextFields on OTP page');
    if (otpFields.evaluate().length >= 6) {
      for (var i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), testOtpCode[i]);
        await tester.pump(const Duration(milliseconds: 100));
      }
      print('[loginWithTestPhone] Entered OTP digits');
    }

    // The OTP page auto-verifies on 6 digits (calls onVerify).
    // Firebase auth state change triggers GoRouter redirect to /home.
    // Wait for it to process (up to 30s for server registration + redirect).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('My Cricket').evaluate().isNotEmpty) {
        print('[loginWithTestPhone] Home page appeared after OTP verification');
        break;
      }
    }
  }

  /// Build the full app widget for integration testing.
  /// Call [_ensureFirebaseInitialized] before this if using Firebase features.
  static Widget buildApp() {
    final db = AppDatabase(NativeDatabase.memory());

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const CricScores(),
    );
  }
}
