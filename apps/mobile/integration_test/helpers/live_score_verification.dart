/// Cross-device score verification helpers for multi-device E2E tests.
///
/// Provides signal-driven milestone verification: the scorer signals expected
/// scores at innings-complete and match-complete checkpoints, and the
/// viewer/spectator polls for these signals and verifies the scores on screen.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';

/// Expected score data at a match milestone checkpoint.
class ScoreCheckpoint {
  ScoreCheckpoint({
    required this.inn1Runs,
    required this.inn1Wkts,
    required this.inn1Overs,
    this.inn2Runs,
    this.inn2Wkts,
    this.inn2Overs,
    this.result,
  });

  factory ScoreCheckpoint.fromSignalValue(String value) {
    final map = jsonDecode(value) as Map<String, dynamic>;
    return ScoreCheckpoint(
      inn1Runs: map['inn1Runs'] as int,
      inn1Wkts: map['inn1Wkts'] as int,
      inn1Overs: map['inn1Overs'] as String,
      inn2Runs: map['inn2Runs'] as int?,
      inn2Wkts: map['inn2Wkts'] as int?,
      inn2Overs: map['inn2Overs'] as String?,
      result: map['result'] as String?,
    );
  }

  final int inn1Runs;
  final int inn1Wkts;
  final String inn1Overs;
  final int? inn2Runs;
  final int? inn2Wkts;
  final String? inn2Overs;
  final String? result;

  String toSignalValue() => jsonEncode({
        'inn1Runs': inn1Runs,
        'inn1Wkts': inn1Wkts,
        'inn1Overs': inn1Overs,
        if (inn2Runs != null) 'inn2Runs': inn2Runs,
        if (inn2Wkts != null) 'inn2Wkts': inn2Wkts,
        if (inn2Overs != null) 'inn2Overs': inn2Overs,
        if (result != null) 'result': result,
      });

  @override
  String toString() {
    final parts = ['inn1=$inn1Runs/$inn1Wkts($inn1Overs)'];
    if (inn2Runs != null) {
      parts.add('inn2=$inn2Runs/$inn2Wkts($inn2Overs)');
    }
    if (result != null) {
      parts.add('result=$result');
    }
    return parts.join(' ');
  }
}

/// Polls a signal endpoint until the value is non-null.
/// Returns the value string. Throws [TestFailure] on timeout.
Future<String> pollForSignal(
  Dio dio,
  String name, {
  int timeoutSeconds = 120,
  String role = 'VIEWER',
}) async {
  print('[$role] Polling for $name signal...');
  final deadline =
      DateTime.now().add(Duration(seconds: timeoutSeconds));

  while (DateTime.now().isBefore(deadline)) {
    try {
      final r = await dio.get('/api/v1/test/signal/$name');
      final value = r.data['value'];
      if (value != null) {
        print('[$role] Signal $name received: $value');
        return value as String;
      }
    } catch (e) {
      print('[$role] Signal poll error ($name): $e');
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  fail('[$role] Timed out waiting for signal "$name" after ${timeoutSeconds}s');
}

/// Verifies expected scores appear on the Live page.
///
/// Waits up to [timeoutSeconds] for the expected score text to appear.
/// If the match has moved from the "Live" filter to "Completed", taps the
/// "All" filter chip and retries.
Future<void> verifyScoreOnLivePage(
  WidgetTester tester,
  ScoreCheckpoint checkpoint, {
  String role = 'VIEWER',
  int timeoutSeconds = 30,
}) async {
  print('[$role] Checkpoint received: $checkpoint');

  // Verify innings 1 score
  final inn1Score = '${checkpoint.inn1Runs}/${checkpoint.inn1Wkts}';
  await _waitForScoreText(tester, inn1Score, role: role, timeoutSeconds: timeoutSeconds);
  print('[$role] Verified: innings 1 score "$inn1Score" found on screen');

  // Verify innings 2 score if present
  if (checkpoint.inn2Runs != null && checkpoint.inn2Wkts != null) {
    final inn2Score = '${checkpoint.inn2Runs}/${checkpoint.inn2Wkts}';
    await _waitForScoreText(tester, inn2Score, role: role, timeoutSeconds: 15);
    print('[$role] Verified: innings 2 score "$inn2Score" found on screen');
  }

  // Verify result text if present
  if (checkpoint.result != null) {
    await _waitForResultText(tester, role: role, timeoutSeconds: 15);
    print('[$role] Verified: match result "won by" found on screen');
  }
}

/// Waits for a specific score text (e.g. "10/5") to appear on screen.
/// If not found within half the timeout, tries switching to "All" filter.
Future<void> _waitForScoreText(
  WidgetTester tester,
  String scoreText, {
  required String role,
  int timeoutSeconds = 30,
}) async {
  final halfTimeout = timeoutSeconds ~/ 2;

  // Phase 1: scan current view
  for (var i = 0; i < halfTimeout; i++) {
    await tester.pump(const Duration(seconds: 1));
    if (_findScoreText(tester, scoreText)) return;
  }

  // Phase 2: try switching to "All" filter and scan again
  print('[$role] Score "$scoreText" not found in current filter, trying "All"...');
  await _tapFilterChip(tester, 'All');

  for (var i = 0; i < halfTimeout; i++) {
    await tester.pump(const Duration(seconds: 1));
    if (_findScoreText(tester, scoreText)) return;
  }

  // Dump visible texts for debugging before failing
  dumpVisibleTexts(tester, 'score-verification-$scoreText', 40);
  fail('[$role] Expected score "$scoreText" not found on screen after ${timeoutSeconds}s');
}

/// Waits for "won by" result text to appear on screen.
Future<void> _waitForResultText(
  WidgetTester tester, {
  required String role,
  int timeoutSeconds = 15,
}) async {
  for (var i = 0; i < timeoutSeconds; i++) {
    await tester.pump(const Duration(seconds: 1));
    if (find.textContaining('won by').evaluate().isNotEmpty) return;
  }

  // Also check for other result patterns (tied, no result)
  if (find.textContaining('Tied').evaluate().isNotEmpty ||
      find.textContaining('No Result').evaluate().isNotEmpty) {
    return;
  }

  dumpVisibleTexts(tester, 'result-verification', 40);
  fail('[$role] Expected result text ("won by") not found after ${timeoutSeconds}s');
}

/// Checks if a specific score text exists in any Text widget on screen.
bool _findScoreText(WidgetTester tester, String scoreText) {
  for (final element in find.byType(Text).evaluate()) {
    final textWidget = element.widget as Text;
    final text = textWidget.data;
    if (text != null && text == scoreText) return true;
  }
  return false;
}

/// Taps a FilterChip with the given label text.
Future<void> _tapFilterChip(WidgetTester tester, String label) async {
  final chipFinder = find.widgetWithText(FilterChip, label);
  if (chipFinder.evaluate().isNotEmpty) {
    await tester.tap(chipFinder.first);
    await settle(tester);
  } else {
    // Try ChoiceChip as an alternative
    final choiceFinder = find.widgetWithText(ChoiceChip, label);
    if (choiceFinder.evaluate().isNotEmpty) {
      await tester.tap(choiceFinder.first);
      await settle(tester);
    } else {
      // Last resort: tap the text directly
      final textFinder = find.text(label);
      if (textFinder.evaluate().isNotEmpty) {
        await tester.tap(textFinder.first);
        await settle(tester);
      }
    }
  }
}
