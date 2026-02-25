/// Team setup flow — ensures teams exist with check-then-skip idempotency.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_data.dart';
import '../core/error_tracker.dart';
import '../core/test_utils.dart';
import '../helpers/forms.dart';
import '../helpers/navigation.dart';

/// Ensure all given teams exist. If a team already exists, skip it.
///
/// Navigates to Teams tab > "All" filter, checks for each team name.
/// If not found, creates via UI.
Future<void> ensureTeamsExist(
  WidgetTester tester,
  List<TestTeam> teams,
  ErrorTracker tracker,
) async {
  for (var i = 0; i < teams.length; i++) {
    if (tracker.hasError) return;

    final team = teams[i];
    print('\n[TEAM ${i + 1}/${teams.length}] ${team.name}');

    try {
      // Navigate to Teams tab
      await navigateToTeams(tester);
      await settle(tester);

      // Tap "All" filter chip to see all teams
      final allChip = find.text('All');
      if (allChip.evaluate().isNotEmpty) {
        await tester.tap(allChip.first);
        await settle(tester);
        await visualPause(tester, 500);
      }

      // Check if team already exists by looking for its name
      final teamExists = await _teamExistsInList(tester, team.name);

      if (teamExists) {
        print('  [SKIP] ${team.name} already exists');
        continue;
      }

      // Team doesn't exist — create it
      await createTeam(tester, team);
      await addPlayersToRoster(tester, team.players);

      // Verify player count on team detail Players tab before leaving
      final playersTab = find.text('Players');
      if (playersTab.evaluate().isNotEmpty) {
        await tester.tap(playersTab.last);
        await settle(tester);
        await visualPause(tester, 500);
      }
      final expectedCount = team.players.length;
      final playerCountText = find.text('$expectedCount players');
      expect(playerCountText, findsAtLeast(1),
          reason: '${team.name} should show "$expectedCount players" on Players tab');
      print('  [VERIFY] ${team.name}: $expectedCount players confirmed');

      await navigateBackToTeamsList(tester);

      tracker.recordTeamCreated(team.name);
      print('  [DONE] ${team.name} — ${team.players.length} players added');
    } catch (e) {
      tracker.recordError(
        'Creating team ${team.name} (${i + 1}/${teams.length})',
        e,
      );
      return;
    }
  }
}

/// Check if a team name exists in the visible teams list.
/// Scrolls through the list to find it.
Future<bool> _teamExistsInList(WidgetTester tester, String teamName) async {
  // First check immediate visibility
  if (find.text(teamName).evaluate().isNotEmpty) return true;

  // Scroll through the list to find it
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return false;

  for (var scroll = 0; scroll < 10; scroll++) {
    await tester.drag(scrollable.last, const Offset(0, -300));
    await tester.pumpAndSettle();
    if (find.text(teamName).evaluate().isNotEmpty) return true;
  }

  // Scroll back to top for next team check
  for (var scroll = 0; scroll < 10; scroll++) {
    await tester.drag(scrollable.last, const Offset(0, 300));
    await tester.pumpAndSettle();
  }

  return false;
}
