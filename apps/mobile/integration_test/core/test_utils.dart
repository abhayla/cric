/// Common test utility functions — settle, visual pause, widget waiting.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/constants.dart';

/// Like pumpAndSettle but with a timeout — won't hang on infinite animations.
Future<void> settle(WidgetTester tester, {int fallbackMs = settleTimeoutMs}) async {
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  } catch (_) {
    for (var i = 0; i < (fallbackMs ~/ 100); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
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
