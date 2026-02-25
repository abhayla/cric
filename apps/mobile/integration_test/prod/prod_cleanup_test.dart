/// Production cleanup: delete all test teams via UI.
///
/// Navigates to My Cricket > Teams tab and deletes each test team
/// through the app's UI (team detail > More options > Delete Team).
///
/// 100% UI-driven — zero API calls.
///
/// Graceful fallback: if the Delete Team option isn't available in the UI,
/// skips the team with a counter and prints a summary at the end.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_cleanup_test.dart -d emulator-5556
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import '../helpers/match_flow_helpers.dart';
import '../helpers/tournament_flow_helpers.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Clean up all prod test data via UI', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== PROD CLEANUP: Deleting test teams via UI ===\n');

    final tracker = ErrorTracker();
    var deleted = 0;
    var skipped = 0;
    var notFound = 0;

    // Navigate to Teams tab
    await navigateToTeams(tester);

    // Known test team names
    final testTeamNames = prodTeams.map((t) => t.name).toSet();
    print('Looking for ${testTeamNames.length} test teams to delete...');
    print('Team names: ${testTeamNames.join(", ")}\n');

    // For each test team, find it in the list and delete via UI
    for (final teamName in testTeamNames) {
      if (tracker.hasError) break;

      try {
        // Scroll up first to reset position, then search
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, 300));
          await tester.pumpAndSettle();
        }

        // Try to find and tap the team in the list
        final teamFinder = find.text(teamName);
        if (teamFinder.evaluate().isEmpty) {
          // Scroll down to find teams that may be off-screen
          var found = false;
          for (var scroll = 0; scroll < 10; scroll++) {
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -200));
              await tester.pumpAndSettle();
            }
            if (find.text(teamName).evaluate().isNotEmpty) {
              found = true;
              break;
            }
          }
          if (!found) {
            print('  [NOT FOUND] $teamName — not in team list');
            notFound++;
            continue;
          }
        }

        // Tap to open team detail
        await tester.tap(find.text(teamName).first);
        await settle(tester);

        // Look for delete option in popup menu
        final moreButton = find.byTooltip('More options');
        if (moreButton.evaluate().isNotEmpty) {
          await tester.tap(moreButton.first);
          await settle(tester);

          final deleteOption = find.text('Delete Team');
          if (deleteOption.evaluate().isNotEmpty) {
            await tester.tap(deleteOption.first);
            await settle(tester);

            // Confirm deletion dialog
            final confirmDelete = find.text('Delete');
            if (confirmDelete.evaluate().isNotEmpty) {
              await tester.tap(confirmDelete.last);
              await settle(tester);
            }

            print('  [DELETED] $teamName');
            deleted++;
            tracker.recordSuccess('Deleted team: $teamName');
          } else {
            print('  [SKIP] $teamName — no Delete Team option in menu');
            skipped++;
            // Dismiss the popup menu
            await tester.tapAt(const Offset(10, 10));
            await settle(tester);
            // Navigate back
            final back = find.byType(BackButton);
            if (back.evaluate().isNotEmpty) {
              await tester.tap(back.first);
              await settle(tester);
            }
          }
        } else {
          print('  [SKIP] $teamName — no More options button');
          skipped++;
          final back = find.byType(BackButton);
          if (back.evaluate().isNotEmpty) {
            await tester.tap(back.first);
            await settle(tester);
          }
        }
      } catch (e) {
        tracker.recordError('Deleting team $teamName', e);
      }
    }

    print('\n=== CLEANUP SUMMARY ===');
    print('Deleted: $deleted');
    print('Skipped (no delete UI): $skipped');
    print('Not found in list: $notFound');
    print('Total teams checked: ${testTeamNames.length}');

    if (skipped > 0) {
      print(
          '\nNote: Team deletion may not be available in UI yet. '
          'Clean up manually or via server admin.');
    }

    print('');
    tracker.printSummary();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
