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
    expect(found, isTrue,
        reason: 'Expected player name "$expectedName" on profile');
    print('  [verify-profile] Hero: found name "$expectedName"');
  } else {
    // Just confirm the page loaded (no error state)
    expect(find.text('Something went wrong'), findsNothing);
    print('  [verify-profile] Hero: profile loaded (no error)');
  }

  // Extra settle to allow stats API call to complete
  await settle(tester, pumpCount: 20);
}

/// Verify the quick stats grid shows the four stat labels.
Future<void> verifyQuickStats(WidgetTester tester) async {
  expect(find.text('Matches'), findsAtLeastNWidgets(1));
  expect(find.text('Runs'), findsAtLeastNWidgets(1));
  expect(find.text('Wickets'), findsAtLeastNWidgets(1));
  expect(find.text('Catches'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Quick stats: Matches/Runs/Wickets/Catches present');
}

/// Verify the format selector chips are present.
///
/// Does not tap chips to avoid triggering API reloads that can slow down
/// the test. Just verifies the three format options render.
Future<void> verifyFormatSelector(WidgetTester tester) async {
  expect(find.text('All'), findsAtLeastNWidgets(1));
  expect(find.text('T20'), findsAtLeastNWidgets(1));
  expect(find.text('ODI'), findsAtLeastNWidgets(1));
  print('  [verify-profile] Format selector: All/T20/ODI chips present');
}

/// Verify the tab bar has Batting, Bowling, Fielding tabs.
Future<void> verifyTabBar(WidgetTester tester) async {
  expect(find.widgetWithText(Tab, 'Batting'), findsOneWidget);
  expect(find.widgetWithText(Tab, 'Bowling'), findsOneWidget);
  expect(find.widgetWithText(Tab, 'Fielding'), findsOneWidget);
  print('  [verify-profile] Tab bar: Batting/Bowling/Fielding present');
}

/// Tap a specific Tab widget by its label and wait for animation to complete.
Future<void> _tapTab(WidgetTester tester, String label) async {
  final tabFinder = find.widgetWithText(Tab, label);
  expect(tabFinder, findsOneWidget, reason: 'Tab "$label" should exist');
  await tester.tap(tabFinder);
  // Wait for tab animation (300ms default) + rendering
  await tester.pump(const Duration(milliseconds: 500));
  await settle(tester);
}

/// Verify the batting tab content (default visible tab).
///
/// Accepts either populated stats (Highest Score, Ducks) or the empty
/// state message. The scorer may or may not have career stats computed.
Future<void> verifyBattingTab(WidgetTester tester) async {
  await _tapTab(tester, 'Batting');

  final hasStats = find.text('Highest Score').evaluate().isNotEmpty;
  final hasEmpty =
      find.text('No batting stats available').evaluate().isNotEmpty;

  expect(
    hasStats || hasEmpty,
    isTrue,
    reason: 'Batting tab should show stats or empty message',
  );

  if (hasStats) {
    expect(find.text('Ducks'), findsAtLeastNWidgets(1));
    print(
        '  [verify-profile] Batting tab: stats present (Highest Score, Ducks)');
  } else {
    print('  [verify-profile] Batting tab: empty state (no batting stats)');
  }
}

/// Verify the bowling tab content by tapping into it.
Future<void> verifyBowlingTab(WidgetTester tester) async {
  await _tapTab(tester, 'Bowling');

  final hasStats = find.text('Best Bowling').evaluate().isNotEmpty;
  final hasEmpty =
      find.text('No bowling stats available').evaluate().isNotEmpty;

  expect(
    hasStats || hasEmpty,
    isTrue,
    reason: 'Bowling tab should show stats or empty message',
  );

  if (hasStats) {
    expect(find.text('Economy'), findsAtLeastNWidgets(1));
    print(
        '  [verify-profile] Bowling tab: stats present (Best Bowling, Economy)');
  } else {
    print('  [verify-profile] Bowling tab: empty state (no bowling stats)');
  }
}

/// Verify the fielding tab content by tapping into it.
Future<void> verifyFieldingTab(WidgetTester tester) async {
  await _tapTab(tester, 'Fielding');

  final hasStats = find.text('Direct Hits').evaluate().isNotEmpty;
  final hasEmpty =
      find.text('No fielding stats available').evaluate().isNotEmpty;

  expect(
    hasStats || hasEmpty,
    isTrue,
    reason: 'Fielding tab should show stats or empty message',
  );

  if (hasStats) {
    print('  [verify-profile] Fielding tab: stats present (Direct Hits)');
  } else {
    print('  [verify-profile] Fielding tab: empty state (no fielding stats)');
  }
}

/// Verify "View Match History" button navigates to match history page.
Future<void> verifyMatchHistoryNavigation(WidgetTester tester) async {
  // The button is pinned at the bottom of the page (outside the scroll),
  // so it should always be visible.
  final viewMatchHistory = find.text('View Match History');
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
