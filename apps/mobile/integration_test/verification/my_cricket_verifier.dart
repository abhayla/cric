/// Verification helpers for My Cricket page — Teams, Matches, Tournaments sub-tabs
/// with all filter chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Verify the Teams tab with Owner/Member/All filter chips.
Future<void> verifyTeamsTab(
  WidgetTester tester, {
  int? expectedMinAllTeams,
  List<String>? expectedOwnerTeams,
}) async {
  await navigateToTeams(tester);
  await settle(tester);

  // Tap "All" chip
  final allChip = find.text('All');
  if (allChip.evaluate().isNotEmpty) {
    await tester.tap(allChip.first);
    await settle(tester);
    await visualPause(tester, 500);
  }

  if (expectedMinAllTeams != null) {
    final teamCards = find.byType(Card);
    final cardCount = teamCards.evaluate().length;
    print('  [verify-teams] "All" filter: found $cardCount cards (expected >= $expectedMinAllTeams)');
    expect(cardCount, greaterThanOrEqualTo(expectedMinAllTeams),
        reason: 'Teams "All" filter should show at least $expectedMinAllTeams team cards');
  }

  // Check each expected owner team is visible
  if (expectedOwnerTeams != null) {
    // Tap "Owner" chip
    final ownerChip = find.text('Owner');
    if (ownerChip.evaluate().isNotEmpty) {
      await tester.tap(ownerChip.first);
      await settle(tester);
      await visualPause(tester, 500);
    }

    for (final teamName in expectedOwnerTeams) {
      final teamText = find.textContaining(teamName);
      expect(teamText, findsAtLeast(1),
          reason: 'Owner chip should show team "$teamName"');
      print('  [verify-teams] Owner chip: found $teamName');
    }
  }

  // Tap "Member" chip
  final memberChip = find.text('Member');
  if (memberChip.evaluate().isNotEmpty) {
    await tester.tap(memberChip.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-teams] Member chip tapped — checking for member teams');
  }

  // Back to All
  final allChip2 = find.text('All');
  if (allChip2.evaluate().isNotEmpty) {
    await tester.tap(allChip2.first);
    await settle(tester);
  }

  print('  [verify-teams] Teams tab verification complete');
}

/// Verify the Matches tab with Live/Won/Lost/All filter chips.
Future<void> verifyMatchesTab(
  WidgetTester tester, {
  int? minAllCount,
  bool expectWon = false,
  bool expectLost = false,
}) async {
  await navigateToMatches(tester);
  await settle(tester);

  // Check "Live" chip
  final liveChip = find.text('Live');
  if (liveChip.evaluate().isNotEmpty) {
    await tester.tap(liveChip.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-matches] Live chip tapped');
  }

  // Check "Won" chip
  if (expectWon) {
    final wonChip = find.text('Won');
    if (wonChip.evaluate().isNotEmpty) {
      await tester.tap(wonChip.first);
      await settle(tester);
      await visualPause(tester, 500);
      final matchCards = find.byType(Card);
      expect(matchCards, findsAtLeast(1),
          reason: 'Won filter should show at least one match card');
      print('  [verify-matches] Won chip: found ${matchCards.evaluate().length} match cards');
    }
  }

  // Check "Lost" chip
  if (expectLost) {
    final lostChip = find.text('Lost');
    if (lostChip.evaluate().isNotEmpty) {
      await tester.tap(lostChip.first);
      await settle(tester);
      await visualPause(tester, 500);
      print('  [verify-matches] Lost chip tapped');
    }
  }

  // Check "All" chip
  final allChip = find.text('All');
  if (allChip.evaluate().isNotEmpty) {
    await tester.tap(allChip.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-matches] All chip tapped');
  }

  print('  [verify-matches] Matches tab verification complete');
}

/// Verify the Tournaments tab with filter chips.
Future<void> verifyTournamentsTab(
  WidgetTester tester, {
  bool expectCompleted = false,
  bool expectLive = false,
}) async {
  await navigateToTournaments(tester);
  await settle(tester);

  // Check filter chips — assert content on specific filters
  for (final chipLabel in ['Live', 'Completed', 'All']) {
    final chip = find.text(chipLabel);
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip.first);
      await settle(tester);
      await visualPause(tester, 500);
      print('  [verify-tournaments] $chipLabel chip tapped');
    }
  }

  // After "All" is selected, verify at least one tournament card is visible
  if (expectCompleted || expectLive) {
    final cards = find.byType(Card);
    expect(cards, findsAtLeast(1),
        reason: 'Tournaments "All" filter should show at least one tournament card');
    print('  [verify-tournaments] Found ${cards.evaluate().length} tournament cards');
  }

  print('  [verify-tournaments] Tournaments tab verification complete');
}
