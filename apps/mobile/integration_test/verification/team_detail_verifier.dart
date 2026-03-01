/// Verification helpers for Team Detail page — roster and match history.
library;

import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';

/// Verify team detail page — roster count and match history.
Future<void> verifyTeamDetail(
  WidgetTester tester, {
  required String teamName,
  int? expectedPlayerCount,
}) async {
  // Wait for team name to appear (async data load from API)
  final nameFound = await waitForFinder(
    tester,
    find.text(teamName),
    timeoutMs: 10000,
  );
  expect(nameFound, isTrue,
      reason: 'Team detail page should show team name "$teamName" after loading');
  print('  [verify-team] Team name found: $teamName');

  // Check Players tab
  final playersTab = find.text('Players');
  expect(playersTab, findsAtLeast(1),
      reason: 'Team detail page should have a "Players" tab');
  await tester.tap(playersTab.last);
  await settle(tester);
  await visualPause(tester, 500);
  print('  [verify-team] Players tab loaded');

  // Verify player count if expected
  if (expectedPlayerCount != null) {
    final playerCountText = find.text('$expectedPlayerCount players');
    expect(playerCountText, findsAtLeast(1),
        reason: 'Players tab should show "$expectedPlayerCount players" for team "$teamName"');
    print('  [verify-team] Player count verified: $expectedPlayerCount players');
  }

  // Check Matches tab (if team has played any — soft check)
  final matchesTab = find.text('Matches');
  if (matchesTab.evaluate().isNotEmpty) {
    await tester.tap(matchesTab.last);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-team] Matches tab loaded');
  }

  print('  [verify-team] Team detail verification complete');
}
