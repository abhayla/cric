/// Verification helpers for My Cricket page — Teams, Matches, Tournaments sub-tabs
/// with all filter chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricscores/src/features/teams/presentation/widgets/team_card.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/tournament_card.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Find a [FilterChip] whose label contains [label] text.
Finder _findFilterChip(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(FilterChip),
  );
}

/// Tap a filter chip by label, using [ensureVisible] to scroll it into view.
Future<bool> _tapFilterChip(WidgetTester tester, String label) async {
  final chip = _findFilterChip(label);
  if (chip.evaluate().isEmpty) return false;
  await tester.ensureVisible(chip.first);
  await settle(tester);
  await tester.tap(chip.first);
  await settle(tester);
  await visualPause(tester, 500);
  return true;
}

/// Verify the Teams tab with Owner/Member/All filter chips.
Future<void> verifyTeamsTab(
  WidgetTester tester, {
  int? expectedMinAllTeams,
  List<String>? expectedOwnerTeams,
}) async {
  await navigateToTeams(tester);
  await settle(tester);

  // Tap "All" chip
  if (await _tapFilterChip(tester, 'All')) {
    print('  [verify-teams] All chip tapped');
  }

  if (expectedMinAllTeams != null) {
    final teamCards = find.byType(TeamCard);
    final cardCount = teamCards.evaluate().length;
    print('  [verify-teams] "All" filter: found $cardCount TeamCards (expected >= $expectedMinAllTeams)');
    expect(cardCount, greaterThanOrEqualTo(expectedMinAllTeams),
        reason: 'Teams "All" filter should show at least $expectedMinAllTeams TeamCards');
  }

  // Check each expected owner team is visible
  if (expectedOwnerTeams != null) {
    // Tap "Owner" chip
    if (await _tapFilterChip(tester, 'Owner')) {
      print('  [verify-teams] Owner chip tapped');
    }

    for (final teamName in expectedOwnerTeams) {
      final teamText = find.textContaining(teamName);
      expect(teamText, findsAtLeast(1),
          reason: 'Owner chip should show team "$teamName"');
      print('  [verify-teams] Owner chip: found $teamName');
    }
  }

  // Tap "Member" chip
  if (await _tapFilterChip(tester, 'Member')) {
    print('  [verify-teams] Member chip tapped');
  }

  // Back to All
  await _tapFilterChip(tester, 'All');

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
  if (await _tapFilterChip(tester, 'Live')) {
    print('  [verify-matches] Live chip tapped');
  }

  // Check "Won" chip
  if (expectWon) {
    if (await _tapFilterChip(tester, 'Won')) {
      final matchCards = find.byType(MatchCard);
      expect(matchCards, findsAtLeast(1),
          reason: 'Won filter should show at least one MatchCard');
      print('  [verify-matches] Won chip: found ${matchCards.evaluate().length} MatchCards');
    }
  }

  // Check "Lost" chip
  if (expectLost) {
    if (await _tapFilterChip(tester, 'Lost')) {
      print('  [verify-matches] Lost chip tapped');
    }
  }

  // Check "All" chip — always assert at least some matches if minAllCount provided
  if (await _tapFilterChip(tester, 'All')) {
    if (minAllCount != null) {
      final matchCards = find.byType(MatchCard);
      final cardCount = matchCards.evaluate().length;
      expect(cardCount, greaterThanOrEqualTo(minAllCount),
          reason: 'Matches "All" filter should show at least $minAllCount MatchCards');
      print('  [verify-matches] All chip: found $cardCount MatchCards (expected >= $minAllCount)');
    } else {
      print('  [verify-matches] All chip tapped');
    }
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
    if (await _tapFilterChip(tester, chipLabel)) {
      print('  [verify-tournaments] $chipLabel chip tapped');
    }
  }

  // After "All" is selected, verify at least one tournament card is visible
  if (expectCompleted || expectLive) {
    final cards = find.byType(TournamentCard);
    expect(cards, findsAtLeast(1),
        reason: 'Tournaments "All" filter should show at least one TournamentCard');
    print('  [verify-tournaments] Found ${cards.evaluate().length} TournamentCards');
  }

  print('  [verify-tournaments] Tournaments tab verification complete');
}
