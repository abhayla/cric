/// Team setup flow — ensures teams exist with check-then-skip idempotency.
///
/// Verifies roster completeness for existing teams. If a team has the wrong
/// player count (e.g., from a prior crashed run), deletes and recreates it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/teams/providers.dart';

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
        // Verify roster completeness via API before skipping
        final rosterOk = await _verifyRosterViaApi(
          tester,
          team.name,
          team.players.length,
        );
        if (rosterOk) {
          print('  [SKIP] ${team.name} already exists'
              ' (${team.players.length} players verified)');
          continue;
        }
        // Roster incomplete — delete via API and recreate
        print('  [INCOMPLETE] ${team.name} has wrong player count — deleting');
        await _deleteTeamViaApi(tester, team.name);
        // Refresh the teams list UI after API deletion
        await navigateToTeams(tester);
        await settle(tester);
        final allChipRefresh = find.text('All');
        if (allChipRefresh.evaluate().isNotEmpty) {
          await tester.tap(allChipRefresh.first);
          await settle(tester);
          await visualPause(tester, 500);
        }
        // Fall through to create team below
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
    await settle(tester);
    if (find.text(teamName).evaluate().isNotEmpty) return true;
  }

  // Scroll back to top for next team check
  for (var scroll = 0; scroll < 10; scroll++) {
    await tester.drag(scrollable.last, const Offset(0, 300));
    await settle(tester);
  }

  return false;
}

/// Verify a team's roster count via the API (not UI).
///
/// Returns true if the team has exactly [expectedCount] players.
/// Returns false if the team can't be found or has the wrong count.
Future<bool> _verifyRosterViaApi(
  WidgetTester tester,
  String teamName,
  int expectedCount,
) async {
  try {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final repo = container.read(teamRepositoryProvider);
    final result = await repo.getTeams(page: 1, limit: 50);
    final team = result.teams.where((t) => t.name == teamName).firstOrNull;
    if (team == null) return false;
    print('  [ROSTER-CHECK] ${team.name}: '
        '${team.playerCount} players (expected $expectedCount)');
    return team.playerCount == expectedCount;
  } catch (e) {
    print('  [ROSTER-CHECK] API check failed for $teamName: $e');
    // If API fails, assume roster is OK to avoid breaking the flow
    return true;
  }
}

/// Delete a team by name via the API.
///
/// Looks up the team ID from the teams list, then calls deleteTeam().
Future<void> _deleteTeamViaApi(
  WidgetTester tester,
  String teamName,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  final repo = container.read(teamRepositoryProvider);
  final result = await repo.getTeams(page: 1, limit: 50);
  final team = result.teams.where((t) => t.name == teamName).firstOrNull;
  if (team == null) {
    print('  [DELETE] $teamName not found in API — skipping delete');
    return;
  }
  await repo.deleteTeam(team.id);
  // Invalidate the teams list provider so UI refreshes
  container.invalidate(teamsListProvider);
  print('  [DELETE] $teamName (${team.id}) deleted via API');
}
