import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/app.dart';

/// Wraps the full CricApp in a ProviderScope for E2E testing.
///
/// In debug mode, the router already skips auth and goes to /home.
/// This wrapper can provide Riverpod overrides for testing.
class AppTestWrapper {
  /// Create and pump the full app with optional provider overrides.
  static Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CricApp(),
      ),
    );
    // Use pump with fixed duration instead of pumpAndSettle to avoid
    // timeout from continuous animations (loading spinners, shimmers).
    // Give the app time to initialize, load route, and render home page.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Build the full app widget for integration testing.
  static Widget buildApp() {
    return const ProviderScope(
      child: CricApp(),
    );
  }
}
