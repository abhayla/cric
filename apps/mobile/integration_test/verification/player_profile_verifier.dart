/// Verification helpers for Player Profile page.
///
/// STUB — Player Profile page is "Coming Soon". Infrastructure ready
/// for when it ships. Will compare StatTracker expected values against
/// profile UI.
library;

import 'package:flutter_test/flutter_test.dart';

import '../core/stat_tracker.dart';
import '../core/test_utils.dart';

/// Verify player profile page shows correct career stats.
///
/// Currently a no-op stub. Will be implemented when the Player Profile
/// page ships.
Future<void> verifyPlayerProfile(
  WidgetTester tester, {
  required String playerName,
  StatTracker? statTracker,
}) async {
  print('  [verify-profile] STUB: Player Profile page not yet implemented');
  print('  [verify-profile] Would verify stats for: $playerName');

  if (statTracker != null) {
    final stats = statTracker.getPlayerStats(playerName);
    if (stats != null) {
      print('  [verify-profile] Expected stats: $stats');
    }
  }

  await settle(tester);
}
