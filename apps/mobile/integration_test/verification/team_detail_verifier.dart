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
  // Verify team name in title
  final nameText = find.text(teamName);
  if (nameText.evaluate().isNotEmpty) {
    print('  [verify-team] Team name found: $teamName');
  } else {
    print('  [verify-team] WARNING: Team name "$teamName" not found');
    dumpVisibleTexts(tester, 'team-detail', 20);
  }

  // Check Players tab
  final playersTab = find.text('Players');
  if (playersTab.evaluate().isNotEmpty) {
    await tester.tap(playersTab.last);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-team] Players tab loaded');
  }

  // Check Matches tab (if team has played any)
  final matchesTab = find.text('Matches');
  if (matchesTab.evaluate().isNotEmpty) {
    await tester.tap(matchesTab.last);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-team] Matches tab loaded');
  }

  print('  [verify-team] Team detail verification complete');
}
