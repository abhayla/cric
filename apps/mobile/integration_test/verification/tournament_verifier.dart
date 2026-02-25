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
    expect(standingsHeading, findsAtLeast(1),
        reason: 'Tournament overview should show Standings section');
    print('  [verify-tournament] Standings section present');

    final viewFull = find.text('View Full');
    if (viewFull.evaluate().isNotEmpty) {
      print('  [verify-tournament] "View Full" link present');
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

    if (expectedTeamCount != null) {
      final teamCards = find.byType(Card);
      final cardCount = teamCards.evaluate().length;
      expect(cardCount, greaterThanOrEqualTo(expectedTeamCount),
          reason: 'Tournament Teams tab should show at least $expectedTeamCount teams');
      print('  [verify-tournament] Teams tab: $cardCount cards (expected >= $expectedTeamCount)');
    } else {
      print('  [verify-tournament] Teams tab loaded');
    }
  }

  print('  [verify-tournament] Tournament detail verification complete');
}
