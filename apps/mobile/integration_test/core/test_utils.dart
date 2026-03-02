/// Common test utility functions — settle, visual pause, widget waiting.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../config/constants.dart';

/// Pump a fixed number of frames to let the UI settle.
///
/// Uses pump-based settling instead of pumpAndSettle because the app has
/// infinite repeating animations (PulsingLiveDot) that prevent pumpAndSettle
/// from ever completing — it burns the full timeout (5s) on every call.
/// With hundreds of settle() calls per test, that alone exhausts the timeout.
///
/// 10 × 100ms = 1s of frame processing, enough for route transitions and
/// most UI animations to complete.
Future<void> settle(WidgetTester tester, {int pumpCount = 10}) async {
  for (var i = 0; i < pumpCount; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Visual pause for watching on device.
Future<void> visualPause(WidgetTester tester, [int ms = defaultPauseMs]) async {
  await tester.pump(Duration(milliseconds: ms));
}

/// Wait for a widget of type [T] to appear, up to [timeoutMs].
/// Returns true if found, false if timed out.
Future<bool> waitForWidget<T extends Widget>(
  WidgetTester tester, {
  int timeoutMs = 5000,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(T).evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Wait for text to appear on screen, up to [timeoutMs].
/// Returns true if found, false if timed out.
Future<bool> waitForText(
  WidgetTester tester,
  String text, {
  int timeoutMs = 5000,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.text(text).evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Wait for a [Finder] to match at least one widget, up to [timeoutMs].
/// Returns true if found, false if timed out.
Future<bool> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 5000,
  int intervalMs = 200,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(Duration(milliseconds: intervalMs));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Wait for a [Finder] to match zero widgets (disappear), up to [timeoutMs].
/// Returns true if gone, false if timed out.
Future<bool> waitForFinderGone(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 5000,
  int intervalMs = 200,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(Duration(milliseconds: intervalMs));
    if (finder.evaluate().isEmpty) return true;
  }
  return false;
}

/// Dismiss the soft keyboard and wait for it to animate away.
///
/// Must be called before tapping buttons that may be occluded by the keyboard.
/// Uses FocusManager to unfocus, then pumps frames for the dismiss animation.
Future<void> dismissKeyboard(WidgetTester tester) async {
  // Send 'done' action in case a text field is active
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
  // Unfocus any remaining focus to ensure keyboard is fully dismissed
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Conditional print that respects [verboseTestOutput].
///
/// Always prints if the message contains WARNING or ERROR.
/// Otherwise only prints when [verboseTestOutput] is true.
void testLog(String message) {
  if (verboseTestOutput ||
      message.contains('WARNING') ||
      message.contains('ERROR')) {
    // ignore: avoid_print
    print(message);
  }
}

/// Debug: Print first N visible text widgets on screen.
void dumpVisibleTexts(WidgetTester tester, String label, [int count = 15]) {
  final allTexts = find.byType(Text);
  final textValues = allTexts.evaluate().take(count).map((e) {
    final widget = e.widget as Text;
    return widget.data ?? widget.textSpan?.toPlainText() ?? '(no text)';
  }).toList();
  print('    [$label] Visible texts: $textValues');
}

/// Clear any active SnackBars by finding the ScaffoldMessenger and clearing them.
void clearSnackBars(WidgetTester tester) {
  final scaffoldMessengers = find.byType(ScaffoldMessenger);
  if (scaffoldMessengers.evaluate().isNotEmpty) {
    final state = tester.state<ScaffoldMessengerState>(scaffoldMessengers.first);
    state.clearSnackBars();
  }
}

/// Take a screenshot and save it to the device's external storage.
///
/// Uses [IntegrationTestWidgetsFlutterBinding.takeScreenshot] to capture
/// the current screen state. Saves as PNG to `/sdcard/screenshots/` on
/// Android for easy retrieval via `adb pull`.
///
/// Call this in error handlers or `addTearDown` to capture failure state.
Future<void> takeFailureScreenshot(String name) async {
  try {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final bytes = await binding.takeScreenshot(name);

    // Save to device storage for retrieval
    final dir = Directory('/sdcard/screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${name}_$timestamp.png');
    file.writeAsBytesSync(bytes);
    print('  [screenshot] Saved: ${file.path}');
  } catch (e) {
    // Screenshot failures should never break the test
    print('  [screenshot] Failed to capture "$name": $e');
  }
}

/// Wrap a test body with screenshot-on-failure.
///
/// If the test body throws, captures a screenshot before re-throwing.
/// Usage:
/// ```dart
/// testWidgets('my test', (tester) async {
///   await withScreenshotOnFailure('my-test', () async {
///     // test body...
///   });
/// });
/// ```
Future<void> withScreenshotOnFailure(
  String testName,
  Future<void> Function() body,
) async {
  try {
    await body();
  } catch (e) {
    await takeFailureScreenshot('FAIL_$testName');
    rethrow;
  }
}
