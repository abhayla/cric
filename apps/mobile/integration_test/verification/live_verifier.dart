/// Verification helpers for the Live page — Matches and Tournaments sub-tabs
/// with Live/Completed/All filters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';
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

/// Tap a [Tab] widget inside a [TabBar] by its text label.
Future<bool> _tapTabBarTab(WidgetTester tester, String label) async {
  final tabBar = find.byType(TabBar);
  if (tabBar.evaluate().isEmpty) return false;
  final tab = find.descendant(of: tabBar.first, matching: find.text(label));
  if (tab.evaluate().isEmpty) return false;
  await tester.ensureVisible(tab.first);
  await settle(tester);
  await tester.tap(tab.first);
  await settle(tester);
  await visualPause(tester, 500);
  return true;
}

/// Verify the Live page with its sub-tabs and filter chips.
///
/// Set [expectCompletedMatches] to true if completed matches should exist
/// (e.g., after running match/tournament tests).
/// Set [expectTournaments] to true if tournaments should exist on "All" filter.
Future<void> verifyLivePage(
  WidgetTester tester, {
  bool expectCompletedMatches = false,
  bool expectTournaments = false,
}) async {
  await navigateToLive(tester);
  await settle(tester);

  // Check Matches sub-tab (usually default) — tap via TabBar
  if (await _tapTabBarTab(tester, 'Matches')) {
    print('  [verify-live] Matches sub-tab tapped');
  }

  // Check filter chips on Matches — use FilterChip finder to avoid
  // hitting the AppBar title "Live" or bottom nav "Live" label.
  for (final chipLabel in ['Live', 'Completed', 'All']) {
    if (await _tapFilterChip(tester, chipLabel)) {
      print('  [verify-live] Matches > $chipLabel chip tapped');

      // After "Completed", verify at least one card if expected
      if (chipLabel == 'Completed' && expectCompletedMatches) {
        final cards = find.byType(MatchCard);
        expect(cards, findsAtLeast(1),
            reason: 'Live > Matches > Completed should show at least one MatchCard');
        print('  [verify-live] Completed matches: ${cards.evaluate().length} MatchCards');
      }
    } else {
      print('  [verify-live] Matches > $chipLabel chip not found');
    }
  }

  // Check Tournaments sub-tab — tap via TabBar
  if (await _tapTabBarTab(tester, 'Tournaments')) {
    print('  [verify-live] Tournaments sub-tab tapped');
  }

  // Check filter chips on Tournaments
  for (final chipLabel in ['Live', 'Completed', 'All']) {
    if (await _tapFilterChip(tester, chipLabel)) {
      print('  [verify-live] Tournaments > $chipLabel chip tapped');

      // After "All", verify at least one tournament card if expected
      if (chipLabel == 'All' && expectTournaments) {
        final cards = find.byType(TournamentCard);
        expect(cards, findsAtLeast(1),
            reason: 'Live > Tournaments > All should show at least one TournamentCard');
        print('  [verify-live] Tournaments All: ${cards.evaluate().length} TournamentCards');
      }
    } else {
      print('  [verify-live] Tournaments > $chipLabel chip not found');
    }
  }

  print('  [verify-live] Live page verification complete');
}
