/// Verification helpers for the Live page — Matches and Tournaments sub-tabs
/// with Live/Completed/All filters.
library;

import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Verify the Live page with its sub-tabs and filter chips.
Future<void> verifyLivePage(WidgetTester tester) async {
  await navigateToLive(tester);
  await settle(tester);

  // Check Matches sub-tab (usually default)
  final matchesTab = find.text('Matches');
  if (matchesTab.evaluate().isNotEmpty) {
    await tester.tap(matchesTab.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-live] Matches sub-tab tapped');
  }

  // Check filter chips on Matches
  for (final chipLabel in ['Live', 'Completed', 'All']) {
    final chip = find.text(chipLabel);
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip.first);
      await settle(tester);
      await visualPause(tester, 500);
      print('  [verify-live] Matches > $chipLabel chip tapped');
    }
  }

  // Check Tournaments sub-tab
  final tournamentsTab = find.text('Tournaments');
  if (tournamentsTab.evaluate().isNotEmpty) {
    await tester.tap(tournamentsTab.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('  [verify-live] Tournaments sub-tab tapped');
  }

  // Check filter chips on Tournaments
  for (final chipLabel in ['Live', 'Completed', 'All']) {
    final chip = find.text(chipLabel);
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip.first);
      await settle(tester);
      await visualPause(tester, 500);
      print('  [verify-live] Tournaments > $chipLabel chip tapped');
    }
  }

  print('  [verify-live] Live page verification complete');
}
