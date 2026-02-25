/// Verification helpers for the Live page — Matches and Tournaments sub-tabs
/// with Live/Completed/All filters.
library;

import 'package:flutter_test/flutter_test.dart';

import '../core/test_utils.dart';
import '../helpers/navigation.dart';

/// Verify the Live page with its sub-tabs and filter chips.
///
/// Set [expectCompletedMatches] to true if completed matches should exist
/// (e.g., after running match/tournament tests).
Future<void> verifyLivePage(
  WidgetTester tester, {
  bool expectCompletedMatches = false,
}) async {
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

      // After "Completed", verify at least one card if expected
      if (chipLabel == 'Completed' && expectCompletedMatches) {
        final cards = find.byType(Card);
        expect(cards, findsAtLeast(1),
            reason: 'Live > Matches > Completed should show at least one match card');
        print('  [verify-live] Completed matches: ${cards.evaluate().length} cards');
      }
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
