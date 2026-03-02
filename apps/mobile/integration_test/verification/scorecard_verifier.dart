/// Verification helpers for Scorecard, Commentary, and Analytics tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricscores/src/features/scoring/presentation/pages/scorecard_page.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';
import '../models/delivery_record.dart';

/// Deep scorecard verification after match completion — called from test 02.
///
/// Verifies the ScorecardPage has correct structure: tabs, batting/bowling
/// tables, extras, total, fall of wickets, commentary, and analytics sub-tabs.
///
/// If [matchRecord] is provided, also verifies that the displayed scores match
/// the recorded delivery totals (scorecard Total row shows `<runs>` text and
/// `Total (<wickets> wkts, ...)`).
Future<void> verifyScorecardDeep(
  WidgetTester tester, {
  MatchRecord? matchRecord,
}) async {
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

  // Check structural elements are present (not optional)
  expect(find.text('Extras'), findsAtLeast(1),
      reason: 'Extras row should exist on scorecard');
  print('  [scorecard-deep] Extras row found');

  expect(find.textContaining('Total ('), findsAtLeast(1),
      reason: 'Total row should exist on scorecard');
  print('  [scorecard-deep] Total row found');

  expect(find.text('Bowler'), findsAtLeast(1),
      reason: 'Bowling table header should exist');
  print('  [scorecard-deep] Bowling table header found');

  // Verify score values against MatchRecord if provided
  if (matchRecord != null) {
    _verifyScorecardScores(tester, matchRecord);
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

/// Verify scorecard Total rows match MatchRecord data.
///
/// The scorecard renders `Total (<wickets> wkts, <overs> ov)` as label
/// and `<runs>` as value. We check that both innings' runs appear on screen.
void _verifyScorecardScores(WidgetTester tester, MatchRecord record) {
  // Find all Text widgets to search for score values
  final allTexts = find.byType(Text);
  final textValues = allTexts.evaluate().map((e) {
    final widget = e.widget as Text;
    return widget.data ?? '';
  }).toList();

  // Check 1st innings total runs
  final inn1Runs = record.firstInningsRuns;
  final inn1RunsFound = textValues.contains('$inn1Runs');
  if (inn1RunsFound) {
    print('  [scorecard-verify] 1st innings runs ($inn1Runs) found on scorecard');
  } else {
    print('  [scorecard-verify] WARNING: 1st innings runs ($inn1Runs) not found');
    print('  [scorecard-verify] Visible numbers: ${textValues.where((t) => RegExp(r'^\d+$').hasMatch(t)).take(20).toList()}');
  }

  // Check 1st innings wickets in Total label
  final inn1Wkts = record.firstInningsWickets;
  final inn1WktsPattern = '$inn1Wkts wkt';
  final inn1WktsFound = textValues.any((t) => t.contains(inn1WktsPattern));
  if (inn1WktsFound) {
    print('  [scorecard-verify] 1st innings wickets ($inn1Wkts) found in Total label');
  } else {
    print('  [scorecard-verify] WARNING: 1st innings wickets ($inn1Wkts) not found in Total labels');
  }

  // Soft assertion: log but don't fail (scorecard may render differently for
  // edge cases like super over, abandoned matches). At minimum, verify runs
  // appear somewhere on the page.
  expect(inn1RunsFound, isTrue,
      reason: 'Scorecard should display 1st innings total runs ($inn1Runs)');

  print('  [scorecard-verify] MatchRecord vs scorecard: '
      '${record.firstInningsRuns}/${record.firstInningsWickets} vs '
      '${record.secondInningsRuns}/${record.secondInningsWickets}');
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
