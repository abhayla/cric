/// App bootstrap for integration tests — Firebase init, phone OTP login,
/// pump app and wait for home page.
///
/// Extracted from the old app_test_wrapper.dart (same logic, cleaner name).
library;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cricscores/src/app/app.dart';
import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/providers/database_provider.dart';

import '../config/constants.dart';

/// Initialize the integration test binding with fullyLive frame policy so
/// the UI is rendered on the device/emulator screen during test execution.
IntegrationTestWidgetsFlutterBinding initIntegrationTest() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  return binding;
}

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

/// Check that the prod server is reachable before starting the test.
///
/// Hits `GET /api/v1/health` with a 10s timeout. Fails fast with a clear
/// message if the server is down, instead of wasting minutes on timeouts.
Future<void> checkServerConnectivity() async {
  final serverRoot = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
  final dio = Dio(BaseOptions(
    baseUrl: serverRoot,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  try {
    final response = await dio.get('/api/v1/health');
    print('  [pre-check] Server reachable: ${response.statusCode}');
  } catch (e) {
    throw TestFailure(
      'Server unreachable at $serverRoot — cannot run E2E tests.\n'
      'Error: $e\n'
      'Check: Is the server running? Is cricscores.in DNS resolving? '
      'Is there network connectivity?',
    );
  }
}

/// Clear stale test signals on the server.
///
/// Call before multi-device tests to prevent stale signals from prior runs
/// causing premature synchronization. Uses `DELETE /api/v1/test/signals`.
Future<void> clearTestSignals() async {
  final serverRoot = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
  final dio = Dio(BaseOptions(
    baseUrl: serverRoot,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  try {
    await dio.delete('/api/v1/test/signals');
    print('  [pre-check] Stale test signals cleared');
  } catch (e) {
    // Non-fatal: endpoint may not exist yet
    print('  [pre-check] Could not clear signals (non-fatal): $e');
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
  final swTotal = Stopwatch()..start();

  // Step 0: Server connectivity pre-check (fail fast)
  await checkServerConnectivity();

  // Step 1: Firebase init
  final swFirebase = Stopwatch()..start();
  await _ensureFirebaseInitialized();
  swFirebase.stop();
  print('  [cold-start] 1. Firebase init: ${swFirebase.elapsedMilliseconds}ms');

  // Step 2: pumpWidget (build widget tree + create in-memory DB)
  final swPump = Stopwatch()..start();
  final db = AppDatabase(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const CricScores(),
    ),
  );
  swPump.stop();
  print('  [cold-start] 2. pumpWidget: ${swPump.elapsedMilliseconds}ms');

  // Keep screen on to prevent device sleep during long E2E tests.
  // Uses FLAG_KEEP_SCREEN_ON via platform channel in MainActivity.
  try {
    const screenChannel = MethodChannel('in.cricscores.app/screen');
    await screenChannel.invokeMethod('keepScreenOn');
    print('  [cold-start] Screen wakelock acquired');
  } catch (e) {
    print('  [cold-start] Screen wakelock failed (OK on emulator): $e');
  }

  // Step 3: Splash → login redirect
  final swSplash = Stopwatch()..start();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  swSplash.stop();
  print('  [cold-start] 3. Splash→login redirect: ${swSplash.elapsedMilliseconds}ms');

  // Steps 4-7 are inside _loginWithTestPhone
  await _loginWithTestPhone(tester, phoneNumber: phoneNumber);

  // Step 8: Poll for home page (GoRouter redirect after auth)
  final swHomePoll = Stopwatch()..start();
  final deadline = DateTime.now().add(
    const Duration(seconds: loginTimeoutSeconds),
  );
  var found = false;

  // Check if already on home (login may have landed us there)
  if (find.text('My Cricket').evaluate().isNotEmpty) {
    found = true;
  }

  while (!found && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      found = true;
      break;
    }
  }
  swHomePoll.stop();
  print('  [cold-start] 8. Home page poll: ${swHomePoll.elapsedMilliseconds}ms');

  // Step 9: Wait for server-side auth verify + background providers to settle.
  // After login, the app sends POST /auth/verify to register the user on the
  // server. Background providers (teams list, etc.) fire concurrently — if they
  // hit the server before auth/verify completes, they get 401 errors that crash
  // the test. A brief settle period prevents this race condition.
  final swSettle = Stopwatch()..start();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  swSettle.stop();
  print('  [cold-start] 9. Post-login settle: ${swSettle.elapsedMilliseconds}ms');

  swTotal.stop();
  print('  [cold-start] TOTAL: ${swTotal.elapsedMilliseconds}ms');

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

  // Step 4: Enter phone number
  final swPhoneEntry = Stopwatch()..start();
  final phoneField = find.byType(TextField);
  if (phoneField.evaluate().isEmpty) {
    print('[login] No TextField found on login page');
    return;
  }
  await tester.enterText(phoneField.last, phoneNumber);
  await tester.pump(const Duration(milliseconds: 300));
  swPhoneEntry.stop();
  print('  [cold-start] 4. Phone entry: ${swPhoneEntry.elapsedMilliseconds}ms');

  // Step 5: Tap Send OTP → wait for OTP page (Firebase round-trip)
  final swSendOtp = Stopwatch()..start();
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
      swSendOtp.stop();
      print('  [cold-start] 5. Send OTP → auto-verified: ${swSendOtp.elapsedMilliseconds}ms');
      print('[login] Auto-verified — landed on home');
      return;
    }
    if (find.text('Verify').evaluate().isNotEmpty &&
        find.text('Enter Verification Code').evaluate().isNotEmpty) {
      print('[login] OTP page appeared');
      break;
    }
  }
  swSendOtp.stop();
  print('  [cold-start] 5. Send OTP → OTP page: ${swSendOtp.elapsedMilliseconds}ms');

  if (find.text('Verify').evaluate().isEmpty) {
    if (find.text('My Cricket').evaluate().isNotEmpty) return;
    throw TestFailure(
      'OTP page did not appear after tapping Send OTP (60s). '
      'Check Firebase test phone number configuration.',
    );
  }

  // Step 6: Enter OTP digits
  // OTP page has 6 TextFields with maxLength=1 (digit boxes). The login page
  // phone field (no maxLength) may still exist in the GoRouter stack.
  // Filter by maxLength to target only OTP digit fields.
  final swOtpEntry = Stopwatch()..start();
  final otpFields = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLength == 1,
  );
  final otpFieldCount = otpFields.evaluate().length;
  print('[login] Found $otpFieldCount OTP TextFields (maxLength:1)');
  if (otpFieldCount >= 6) {
    for (var i = 0; i < 6; i++) {
      await tester.enterText(otpFields.at(i), testOtpCode[i]);
      await tester.pump(const Duration(milliseconds: 100));
    }
    print('[login] Entered OTP digits');
  }
  swOtpEntry.stop();
  print('  [cold-start] 6. OTP digit entry: ${swOtpEntry.elapsedMilliseconds}ms');

  // Tap the Verify button explicitly — auto-verify via onChanged may not
  // trigger reliably when enterText replaces field content in fullyLive mode.
  await tester.pump(const Duration(milliseconds: 300));
  final verifyButton = find.widgetWithText(FilledButton, 'Verify');
  if (verifyButton.evaluate().isNotEmpty) {
    final btn = tester.widget<FilledButton>(verifyButton.first);
    if (btn.onPressed != null) {
      await tester.tap(verifyButton.first);
      print('[login] Tapped Verify button (enabled)');
    } else {
      print('[login] Verify button DISABLED — pumping to let setState propagate');
      await tester.pump(const Duration(milliseconds: 500));
      final retryBtn = tester.widget<FilledButton>(verifyButton.first);
      if (retryBtn.onPressed != null) {
        retryBtn.onPressed!();
        print('[login] Verify invoked after pump');
      } else {
        print('[login] ERROR: Verify still disabled after pump');
      }
    }
  } else {
    print('[login] No Verify button found — relying on auto-verify');
  }

  // Step 7: Wait for OTP verification + GoRouter redirect to /home
  final swVerify = Stopwatch()..start();
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('My Cricket').evaluate().isNotEmpty) {
      print('[login] Home page appeared after OTP verification');
      break;
    }
  }
  swVerify.stop();
  print('  [cold-start] 7. OTP verify → home redirect: ${swVerify.elapsedMilliseconds}ms');
}
