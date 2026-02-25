/// Verification helpers for Tournament Detail page — standings, fixtures, teams tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';

import '../helpers/navigation.dart';

/// Verify tournament detail page — standings, fixtures, and teams tabs.
Future<void> verifyTournamentDetail(
  WidgetTester tester, {
  int? expectedTeamCount,
  bool expectStandings = true,
}) async {
  // Switch to Overview tab (tab 0) — check standings
  await switchToTab(tester, 0);

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

  // Switch to Fixtures tab (tab 1) — verify fixture cards exist
  await switchToTab(tester, 1);
  final fixtureCards = find.byType(FixtureCard);
  final fixtureCount = fixtureCards.evaluate().length;
  expect(fixtureCount, greaterThan(0),
      reason: 'Tournament Fixtures tab should show at least one FixtureCard');
  print('  [verify-tournament] Fixtures tab: $fixtureCount FixtureCards');

  // Switch to Teams tab (tab 2)
  await switchToTab(tester, 2);

  if (expectedTeamCount != null) {
    // Tournament teams tab uses ListTile, not TeamCard
    final teamTiles = find.byType(ListTile);
    final tileCount = teamTiles.evaluate().length;
    expect(tileCount, greaterThanOrEqualTo(expectedTeamCount),
        reason: 'Tournament Teams tab should show at least $expectedTeamCount team ListTiles');
    print('  [verify-tournament] Teams tab: $tileCount ListTiles (expected >= $expectedTeamCount)');
  } else {
    print('  [verify-tournament] Teams tab loaded');
  }

  print('  [verify-tournament] Tournament detail verification complete');
}
