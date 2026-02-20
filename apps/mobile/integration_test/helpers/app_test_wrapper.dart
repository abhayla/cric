import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/app.dart';
import 'package:cricapp/src/shared/data/database/app_database.dart';
import 'package:cricapp/src/shared/providers/database_provider.dart';

/// Wraps the full CricApp in a ProviderScope for E2E testing.
///
/// In debug mode, the router already skips auth and goes to /home.
/// This wrapper provides an in-memory Drift database override so
/// the scoring page (and other local DB features) work correctly.
class AppTestWrapper {
  /// Create and pump the full app with optional provider overrides.
  static Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const CricApp(),
      ),
    );
    // Use pump with fixed duration instead of pumpAndSettle to avoid
    // timeout from continuous animations (loading spinners, shimmers).
    // Give the app time to initialize, load route, and render home page.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Pump the app and wait for the Home page to appear.
  ///
  /// Polls for `find.text('Home')` with a 180s timeout to accommodate
  /// real device Firebase init, which can be much slower than emulator.
  /// Use this in multi-device tests; use [pumpApp] for single-device tests.
  static Future<void> pumpAppAndWaitForHome(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const CricApp(),
      ),
    );

    // Poll for Home text with 180s timeout
    final deadline = DateTime.now().add(const Duration(seconds: 180));
    var found = false;

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Home').evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }

    if (!found) {
      throw TestFailure(
        'Home page did not appear within 180s. '
        'Check Firebase init and network connectivity on this device.',
      );
    }
  }

  /// Build the full app widget for integration testing.
  static Widget buildApp() {
    final db = AppDatabase(NativeDatabase.memory());

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const CricApp(),
    );
  }
}
