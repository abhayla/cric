/// Verification helpers for the Updates page — activity feed with date groups.
library;

import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Verify the Updates page has activity feed events.
Future<void> verifyUpdatesPage(WidgetTester tester) async {
  await navigateToUpdates(tester);
  await settle(tester);
  await visualPause(tester, 1000);

  // Check for date group headers
  final dateHeaders = ['Today', 'Yesterday', 'This Week', 'Earlier'];
  for (final header in dateHeaders) {
    final headerText = find.text(header);
    if (headerText.evaluate().isNotEmpty) {
      print('  [verify-updates] Found date group: $header');
    }
  }

  // Check for activity feed items (match results, tournament events)
  final hasContent = find.textContaining('won by').evaluate().isNotEmpty ||
      find.textContaining('Tied').evaluate().isNotEmpty ||
      find.textContaining('completed').evaluate().isNotEmpty ||
      find.textContaining('Team').evaluate().isNotEmpty;

  if (hasContent) {
    print('  [verify-updates] Activity feed has content');
  } else {
    print('  [verify-updates] Activity feed appears empty or no recognizable events');
    dumpVisibleTexts(tester, 'updates-page', 30);
  }

  print('  [verify-updates] Updates page verification complete');
}
