/// Verification helpers for Player Profile page.
///
/// Verifies hero section, quick stats, format selector, tab bar,
/// batting/bowling/fielding tabs, and match history navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';

/// Verify the profile hero section loaded with the player's name.
///
/// If [expectedName] is provided, waits for that exact text.
/// Otherwise just waits for the Player Profile page to finish loading.
Future<void> verifyProfileHero(
  WidgetTester tester, {
  String? expectedName,
}) async {
  // Wait for loading to finish
  await waitForFinderGone(
    tester,
    find.byType(CircularProgressIndicator),
    timeoutMs: 15000,
  );
  await settle(tester);

  if (expectedName != null) {
    final found = await waitForText(tester, expectedName, timeoutMs: 10000);
    expect(found, isTrue, reason: 'Expected player name "$expectedName" on profile');
    print('  [verify-profile] Hero: found name "$expectedName"');
  } else {
    // Just confirm the page loaded (no error state)
    expect(find.text('Something went wrong'), findsNothing);
    print('  [verify-profile] Hero: profile loaded (no error)');
  }
}

/// Verify the quick stats grid shows the four stat labels.
Future<void> verifyQuickStats(WidgetTester tester) async {
  expect(find.text('Matches'), findsAtLeastNWidgets(1));
  expect(find.text('Runs'), findsAtLeastNWidgets(1));
  expect(find.text('Wickets'), findsAtLeastNWidgets(1));
  expect(find.text('Catches'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Quick stats: Matches/Runs/Wickets/Catches present');
}

/// Verify the format selector chips are present and tappable.
Future<void> verifyFormatSelector(WidgetTester tester) async {
  expect(find.text('All'), findsAtLeastNWidgets(1));
  expect(find.text('T20'), findsAtLeastNWidgets(1));
  expect(find.text('ODI'), findsAtLeastNWidgets(1));

  // Tap T20 chip and verify it still renders
  await tester.tap(find.text('T20').first);
  await settle(tester);
  expect(find.text('T20'), findsAtLeastNWidgets(1));

  // Tap back to All
  await tester.tap(find.text('All').first);
  await settle(tester);
  print('  [verify-profile] Format selector: All/T20/ODI chips present and tappable');
}

/// Verify the tab bar has Batting, Bowling, Fielding tabs.
Future<void> verifyTabBar(WidgetTester tester) async {
  expect(find.text('Batting'), findsAtLeastNWidgets(1));
  expect(find.text('Bowling'), findsAtLeastNWidgets(1));
  expect(find.text('Fielding'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Tab bar: Batting/Bowling/Fielding present');
}

/// Verify the batting tab content (default visible tab).
Future<void> verifyBattingTab(WidgetTester tester) async {
  // Batting tab is the default — should already be visible
  expect(find.text('Highest Score'), findsAtLeastNWidgets(1));
  expect(find.text('Ducks'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Batting tab: Highest Score/Ducks present');
}

/// Verify the bowling tab content by tapping into it.
Future<void> verifyBowlingTab(WidgetTester tester) async {
  await tester.tap(find.text('Bowling').first);
  await settle(tester);

  expect(find.text('Best Bowling'), findsAtLeastNWidgets(1));
  expect(find.text('Economy'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Bowling tab: Best Bowling/Economy present');
}

/// Verify the fielding tab content by tapping into it.
Future<void> verifyFieldingTab(WidgetTester tester) async {
  await tester.tap(find.text('Fielding').first);
  await settle(tester);

  expect(find.text('Catches'), findsAtLeastNWidgets(1));
  expect(find.text('Direct Hits'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Fielding tab: Catches/Direct Hits present');
}

/// Verify "View Match History" button navigates to match history page.
Future<void> verifyMatchHistoryNavigation(WidgetTester tester) async {
  // Scroll down to find the button (it's at the bottom)
  final viewMatchHistory = find.text('View Match History');

  // The button may be off-screen — try scrolling
  if (viewMatchHistory.evaluate().isEmpty) {
    // Scroll down in the page
    await tester.drag(find.byType(Scaffold).first, const Offset(0, -200));
    await settle(tester);
  }

  expect(viewMatchHistory, findsOneWidget);
  await tester.tap(viewMatchHistory);
  await settle(tester);

  // Wait for Match History page
  final found = await waitForText(tester, 'Match History', timeoutMs: 10000);
  expect(found, isTrue, reason: 'Match History page should appear');
  print('  [verify-profile] Match History: navigated successfully');

  // Go back to profile
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
  }
  print('  [verify-profile] Match History: returned to profile');
}
