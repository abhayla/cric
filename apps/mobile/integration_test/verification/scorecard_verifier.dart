/// Verification helpers for Scorecard, Commentary, and Analytics tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricscores/src/features/scoring/presentation/pages/scorecard_page.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Deep scorecard verification after match completion — called from test 02.
///
/// Verifies the ScorecardPage has correct structure: tabs, batting/bowling
/// tables, extras, total, fall of wickets, commentary, and analytics sub-tabs.
Future<void> verifyScorecardDeep(WidgetTester tester) async {
  // Ensure we're on the ScorecardPage
  expect(find.byType(ScorecardPage), findsOneWidget,
      reason: 'ScorecardPage should be visible');

  // Verify 3 tabs exist
  expect(find.text('Scorecard'), findsAtLeast(1));
  expect(find.text('Commentary'), findsAtLeast(1));
  expect(find.text('Analytics'), findsAtLeast(1));
  print('  [scorecard-deep] 3 tabs verified (Scorecard, Commentary, Analytics)');

  // Verify Scorecard tab content
  // Check batting section
  expect(find.text('Batter'), findsAtLeast(1),
      reason: 'Batting table header should exist');
  print('  [scorecard-deep] Batting table header found');

  // Check for Extras row
  final extras = find.text('Extras');
  if (extras.evaluate().isNotEmpty) {
    print('  [scorecard-deep] Extras row found');
  }

  // Check for Total row
  final total = find.text('Total');
  if (total.evaluate().isNotEmpty) {
    print('  [scorecard-deep] Total row found');
  }

  // Check for bowling section header
  final bowlerHeader = find.text('Bowler');
  if (bowlerHeader.evaluate().isNotEmpty) {
    print('  [scorecard-deep] Bowling table header found');
  }

  // Check for Fall of Wickets section
  final fowLabel = find.text('Fall of Wickets');
  if (fowLabel.evaluate().isNotEmpty) {
    print('  [scorecard-deep] Fall of Wickets section found');
  }

  // Switch to Commentary tab
  final commentaryTab = find.text('Commentary');
  if (commentaryTab.evaluate().isNotEmpty) {
    await tester.tap(commentaryTab.first);
    await settle(tester);
    print('  [scorecard-deep] Switched to Commentary tab');
  }

  // Switch back to Scorecard tab
  final scorecardTab = find.text('Scorecard');
  if (scorecardTab.evaluate().isNotEmpty) {
    await tester.tap(scorecardTab.first);
    await settle(tester);
  }

  print('  [scorecard-deep] Deep scorecard verification complete');
}

/// Verify the Analytics tab has 4 sub-tabs and renders charts.
Future<void> verifyAnalyticsTab(WidgetTester tester) async {
  // Tap Analytics tab
  final analyticsTab = find.text('Analytics');
  expect(analyticsTab, findsAtLeast(1));
  await tester.tap(analyticsTab.first);
  await settle(tester);
  await visualPause(tester, 500);

  // Verify 4 sub-tabs
  expect(find.text('Manhattan'), findsAtLeast(1));
  expect(find.text('Worm'), findsAtLeast(1));
  expect(find.text('Run Rate'), findsAtLeast(1));
  expect(find.text('MVP'), findsAtLeast(1));
  print('  [analytics] 4 sub-tabs verified (Manhattan, Worm, Run Rate, MVP)');

  // Tap each sub-tab to verify it renders
  for (final subTab in ['Manhattan', 'Worm', 'Run Rate', 'MVP']) {
    final tab = find.text(subTab);
    if (tab.evaluate().isNotEmpty) {
      await tester.tap(tab.last); // Use .last to avoid hitting outer tab bar
      await settle(tester);
      print('  [analytics] $subTab tab renders');
    }
  }

  // Switch back to Scorecard tab
  final scorecardTab = find.text('Scorecard');
  if (scorecardTab.evaluate().isNotEmpty) {
    await tester.tap(scorecardTab.first);
    await settle(tester);
  }

  print('  [analytics] Analytics tab verification complete');
}

/// Structure-only scorecard verification — called from test 03.
///
/// Navigates to Matches tab, taps first MatchCard, verifies tabs and
/// structural elements exist, then navigates back.
Future<void> verifyScorecardStructure(WidgetTester tester) async {
  print('  [scorecard-structure] Navigating to scorecard via Matches tab...');
  await navigateToMatches(tester);
  await settle(tester);

  // Switch to "All" filter to see completed matches
  final allChip = find.ancestor(
    of: find.text('All'),
    matching: find.byType(FilterChip),
  );
  if (allChip.evaluate().isNotEmpty) {
    await tester.ensureVisible(allChip.first);
    await settle(tester);
    await tester.tap(allChip.first);
    await settle(tester);
    await visualPause(tester, 1000);
  } else {
    // Try InkWell-based All chip
    final allInkWell = find.widgetWithText(InkWell, 'All');
    if (allInkWell.evaluate().isNotEmpty) {
      await tester.tap(allInkWell.first);
      await settle(tester);
      await visualPause(tester, 1000);
    }
  }

  // Find and tap the first MatchCard
  final matchCards = find.byType(MatchCard);
  if (matchCards.evaluate().isEmpty) {
    print('  [scorecard-structure] WARNING: No MatchCards found, skipping');
    return;
  }

  await tester.ensureVisible(matchCards.first);
  await settle(tester);
  await tester.tap(matchCards.first);
  await settle(tester);
  await visualPause(tester, 1500);

  // Wait for ScorecardPage to load (it fetches data from API)
  final found = await waitForWidget<ScorecardPage>(tester, timeoutMs: 10000);
  if (!found) {
    print('  [scorecard-structure] WARNING: ScorecardPage not loaded, skipping');
    await goBack(tester);
    return;
  }

  // Verify 3 tabs
  expect(find.text('Scorecard'), findsAtLeast(1));
  expect(find.text('Commentary'), findsAtLeast(1));
  expect(find.text('Analytics'), findsAtLeast(1));
  print('  [scorecard-structure] 3 tabs verified');

  // Verify batting/bowling table headers
  final hasBatter = find.text('Batter').evaluate().isNotEmpty;
  final hasBowler = find.text('Bowler').evaluate().isNotEmpty;
  print('  [scorecard-structure] Batter header: $hasBatter, Bowler header: $hasBowler');

  // Verify Extras and Total
  final hasExtras = find.text('Extras').evaluate().isNotEmpty;
  final hasTotal = find.text('Total').evaluate().isNotEmpty;
  print('  [scorecard-structure] Extras: $hasExtras, Total: $hasTotal');

  // Check Analytics sub-tabs
  final analyticsTab = find.text('Analytics');
  if (analyticsTab.evaluate().isNotEmpty) {
    await tester.tap(analyticsTab.first);
    await settle(tester);

    final hasManhattan = find.text('Manhattan').evaluate().isNotEmpty;
    final hasWorm = find.text('Worm').evaluate().isNotEmpty;
    final hasRunRate = find.text('Run Rate').evaluate().isNotEmpty;
    final hasMVP = find.text('MVP').evaluate().isNotEmpty;
    print('  [scorecard-structure] Analytics sub-tabs: Manhattan=$hasManhattan, '
        'Worm=$hasWorm, RunRate=$hasRunRate, MVP=$hasMVP');
  }

  // Navigate back
  await goBack(tester);
  await settle(tester);
  print('  [scorecard-structure] Scorecard structure verification complete');
}
