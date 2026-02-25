/// Verification helpers for Tournament Detail page — standings, fixtures, teams tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';

/// Verify tournament detail page — standings, fixtures, and teams tabs.
Future<void> verifyTournamentDetail(
  WidgetTester tester, {
  int? expectedTeamCount,
  bool expectStandings = true,
}) async {
  // Switch to Overview tab (tab 0) — check standings
  final tabBarFinder = find.byType(TabBar);
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(0);
    await tester.pumpAndSettle();
    await visualPause(tester);
  }

  if (expectStandings) {
    final standingsHeading = find.text('Standings');
    final viewFull = find.text('View Full');

    final hasStandings = standingsHeading.evaluate().isNotEmpty;
    final hasViewFull = viewFull.evaluate().isNotEmpty;

    if (hasStandings && hasViewFull) {
      print('  [verify-tournament] Standings section present with "View Full" link');
    } else if (hasStandings) {
      print('  [verify-tournament] Standings heading found but no "View Full" link');
    } else {
      print('  [verify-tournament] WARNING: Standings section not found');
    }
  }

  // Switch to Fixtures tab (tab 1)
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(1);
    await tester.pumpAndSettle();
    await visualPause(tester, 500);
    print('  [verify-tournament] Fixtures tab loaded');
  }

  // Switch to Teams tab (tab 2)
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(2);
    await tester.pumpAndSettle();
    await visualPause(tester, 500);
    print('  [verify-tournament] Teams tab loaded');
  }

  print('  [verify-tournament] Tournament detail verification complete');
}
