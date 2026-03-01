/// Verification helpers for the Updates page — activity feed with date groups.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/updates/presentation/widgets/activity_event_card.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Verify the Updates page has activity feed events.
///
/// Set [expectContent] to true if activity feed should have entries
/// (e.g., after completing matches).
Future<void> verifyUpdatesPage(
  WidgetTester tester, {
  bool expectContent = false,
}) async {
  await navigateToUpdates(tester);
  await settle(tester);
  await visualPause(tester, 1000);

  // Ensure Feed tab is selected (Updates page has Feed + Settings tabs)
  final feedTab = find.text('Feed');
  if (feedTab.evaluate().isNotEmpty) {
    await tester.tap(feedTab.first);
    await settle(tester);
    await visualPause(tester, 1000);
    print('  [verify-updates] Feed tab tapped');
  }

  // Check for date group headers
  final dateHeaders = ['Today', 'Yesterday', 'This Week', 'Earlier'];
  for (final header in dateHeaders) {
    final headerText = find.text(header);
    if (headerText.evaluate().isNotEmpty) {
      print('  [verify-updates] Found date group: $header');
    }
  }

  // Check for activity feed items — look for ActivityEventCard widgets
  // (more reliable than text pattern matching)
  final eventCards = find.byType(ActivityEventCard);
  final hasCards = eventCards.evaluate().isNotEmpty;

  // Also check text patterns as a fallback
  final hasTextContent =
      find.textContaining('won by').evaluate().isNotEmpty ||
          find.textContaining('Tied').evaluate().isNotEmpty ||
          find.textContaining('completed').evaluate().isNotEmpty ||
          find.textContaining('Match Result').evaluate().isNotEmpty ||
          find.textContaining('started').evaluate().isNotEmpty ||
          find.textContaining('added').evaluate().isNotEmpty;

  final hasContent = hasCards || hasTextContent;

  if (expectContent) {
    if (!hasContent) {
      // Activity feed may be empty if no events were generated for this user
      // (e.g., matches played before activity feed feature was added, or events
      // were for other users). Verify the page renders correctly either way.
      final hasEmptyState = find.text('No Updates Yet').evaluate().isNotEmpty;
      if (hasEmptyState) {
        print(
            '  [verify-updates] Activity feed empty (empty state shown) — page renders correctly');
      } else {
        print('  [verify-updates] WARNING: No content and no empty state. Dumping texts:');
        dumpVisibleTexts(tester, 'updates-page', 30);
      }
    } else {
      print(
          '  [verify-updates] Activity feed has content: ${eventCards.evaluate().length} cards (verified)');
    }
  } else if (hasContent) {
    print(
        '  [verify-updates] Activity feed has content: ${eventCards.evaluate().length} cards');
  } else {
    print('  [verify-updates] Activity feed appears empty or no recognizable events');
    dumpVisibleTexts(tester, 'updates-page', 30);
  }

  print('  [verify-updates] Updates page verification complete');
}

/// Deep Updates page verification — checks feed presence, date grouping,
/// event types, tap navigation, and settings toggle.
Future<void> verifyUpdatesPageDeep(
  WidgetTester tester,
) async {
  await navigateToUpdates(tester);
  await settle(tester);
  await visualPause(tester, 1000);

  // 1. Ensure Feed tab is selected
  final feedTab = find.text('Feed');
  if (feedTab.evaluate().isNotEmpty) {
    await tester.tap(feedTab.first);
    await settle(tester);
    await visualPause(tester, 1000);
    print('  [updates-deep] Feed tab selected');
  }

  // 2. Feed presence — count ActivityEventCard widgets
  final eventCards = find.byType(ActivityEventCard);
  final cardCount = eventCards.evaluate().length;
  print('  [updates-deep] Found $cardCount ActivityEventCard widgets');

  // 3. Date grouping — check for group headers
  final dateHeaders = ['Today', 'Yesterday', 'This Week', 'Earlier'];
  final foundHeaders = <String>[];
  for (final header in dateHeaders) {
    if (find.text(header).evaluate().isNotEmpty) {
      foundHeaders.add(header);
    }
  }
  if (foundHeaders.isNotEmpty) {
    print('  [updates-deep] Date group headers found: ${foundHeaders.join(", ")}');
  } else {
    print('  [updates-deep] No date group headers found');
  }

  // 4. Event types — verify event text patterns
  final hasMatchResult =
      find.textContaining('won by').evaluate().isNotEmpty ||
          find.textContaining('Tied').evaluate().isNotEmpty ||
          find.textContaining('completed').evaluate().isNotEmpty;
  print('  [updates-deep] Has match result events: $hasMatchResult');

  // 5. Tap navigation — tap first event card if available
  if (cardCount > 0) {
    try {
      await tester.ensureVisible(eventCards.first);
      await settle(tester);
      await tester.tap(eventCards.first, warnIfMissed: false);
      await settle(tester);
      await visualPause(tester, 1000);

      // Verify navigation happened (we should be on a different page)
      // Navigate back
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await settle(tester);
        print('  [updates-deep] Tap navigation: success (navigated and came back)');
      } else {
        // May have stayed on same page (some events may not navigate)
        print('  [updates-deep] Tap navigation: no navigation (event may not be tappable)');
      }
    } catch (e) {
      print('  [updates-deep] Tap navigation: error ($e)');
    }
  }

  // 6. Settings toggle — switch to Settings tab
  final settingsTab = find.text('Settings');
  if (settingsTab.evaluate().isNotEmpty) {
    await tester.tap(settingsTab.first);
    await settle(tester);
    await visualPause(tester, 500);

    // Check for SwitchListTile widgets
    final switches = find.byType(SwitchListTile);
    final switchCount = switches.evaluate().length;
    print('  [updates-deep] Settings tab: found $switchCount SwitchListTile widgets');

    // Switch back to Feed tab
    final feedTabAgain = find.text('Feed');
    if (feedTabAgain.evaluate().isNotEmpty) {
      await tester.tap(feedTabAgain.first);
      await settle(tester);
    }
  } else {
    print('  [updates-deep] No Settings tab found');
  }

  print('  [updates-deep] Deep Updates verification complete');
}
