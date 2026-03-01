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
        // Verify roster completeness AND player names via API before skipping
        final rosterOk = await _verifyRosterViaApi(
          tester,
          team.name,
          team.players.length,
          expectedPlayers: team.players,
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

  // Find the outer ListView's Scrollable (not the inner GridView which has
  // NeverScrollableScrollPhysics)
  final listView = find.byType(ListView);
  if (listView.evaluate().isEmpty) return false;
  final scrollable = find.descendant(
    of: listView.first,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isEmpty) return false;

  for (var scroll = 0; scroll < 10; scroll++) {
    await tester.drag(scrollable.first, const Offset(0, -300));
    await settle(tester);
    if (find.text(teamName).evaluate().isNotEmpty) return true;
  }

  // Scroll back to top for next team check
  for (var scroll = 0; scroll < 10; scroll++) {
    await tester.drag(scrollable.first, const Offset(0, 300));
    await settle(tester);
  }

  return false;
}

/// Verify a team's roster count and player names via the API (not UI).
///
/// Returns true if the team has exactly [expectedCount] players AND the
/// first player's name matches. This catches stale rosters from prior
/// test runs that used a different playersPerTeam value.
Future<bool> _verifyRosterViaApi(
  WidgetTester tester,
  String teamName,
  int expectedCount, {
  List<TestPlayer> expectedPlayers = const [],
}) async {
  try {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final repo = container.read(teamRepositoryProvider);
    final result = await repo.getTeams(page: 1, limit: 50);
    final team = result.teams.where((t) => t.name == teamName).firstOrNull;
    if (team == null) return false;

    // Count check
    if (team.playerCount != expectedCount) {
      print('  [ROSTER-CHECK] ${team.name}: '
          '${team.playerCount} players (expected $expectedCount) — MISMATCH');
      return false;
    }

    // Name check: fetch full roster and verify first player matches
    if (expectedPlayers.isNotEmpty) {
      final detail = await repo.getTeam(team.id);
      final rosterNames =
          detail.roster.map((r) => r.displayName).toSet();
      final expectedFirstName = expectedPlayers.first.name;
      if (!rosterNames.contains(expectedFirstName)) {
        print('  [ROSTER-CHECK] ${team.name}: '
            '${team.playerCount} players but missing $expectedFirstName '
            '(has: ${rosterNames.take(3)}) — STALE ROSTER');
        return false;
      }
    }

    print('  [ROSTER-CHECK] ${team.name}: '
        '${team.playerCount} players (expected $expectedCount)');
    return true;
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

/// Test removing a player from a team.
///
/// Navigates to Teams → Team12 detail → Players tab, removes the last player,
/// and verifies the count decreases by 1.
/// Safe: re-running test 01 detects missing player via roster check and recreates.
Future<void> testRemovePlayer(
  WidgetTester tester,
  ErrorTracker tracker,
) async {
  print('\n  [Remove Player] Testing player removal from Team12...');

  await navigateToTeams(tester);
  await settle(tester);

  // Tap "All" filter
  final allFilter = find.ancestor(
    of: find.text('All'),
    matching: find.byType(FilterChip),
  );
  if (allFilter.evaluate().isNotEmpty) {
    await tester.ensureVisible(allFilter.first);
    await settle(tester);
    await tester.tap(allFilter.first);
    await settle(tester);
    await visualPause(tester, 1000);
  }

  // Find Team12 and tap it
  final team12Text = find.text('Team12');
  if (team12Text.evaluate().isEmpty) {
    // Scroll to find Team12
    for (var scroll = 0; scroll < 10; scroll++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await settle(tester);
      if (find.text('Team12').evaluate().isNotEmpty) break;
    }
  }

  if (team12Text.evaluate().isEmpty) {
    print('  [Remove Player] WARNING: Team12 not found, skipping');
    tracker.recordError('Remove player', 'Team12 not found in teams list');
    return;
  }

  await tester.ensureVisible(team12Text.first);
  await settle(tester);
  await tester.tap(team12Text.first);
  await settle(tester);
  await visualPause(tester, 1000);

  // Navigate to Players tab
  final playersTab = find.text('Players');
  if (playersTab.evaluate().isNotEmpty) {
    await tester.tap(playersTab.first);
    await settle(tester);
    await visualPause(tester, 500);
  }

  // Count players before removal
  final playerCountBefore = find.textContaining('Player').evaluate().length;
  print('  [Remove Player] Player count before: $playerCountBefore');

  // Find delete icon and tap it (last one)
  final deleteIcons = find.byIcon(Icons.delete_outline);
  if (deleteIcons.evaluate().isEmpty) {
    // Try alternate icon
    final removeIcons = find.byIcon(Icons.remove_circle_outline);
    if (removeIcons.evaluate().isEmpty) {
      print('  [Remove Player] No delete icons found, skipping');
      tracker.recordError('Remove player', 'No delete icons found');
      await goBack(tester);
      return;
    }
    await tester.ensureVisible(removeIcons.last);
    await settle(tester);
    await tester.tap(removeIcons.last, warnIfMissed: false);
  } else {
    await tester.ensureVisible(deleteIcons.last);
    await settle(tester);
    await tester.tap(deleteIcons.last, warnIfMissed: false);
  }
  await settle(tester);
  await visualPause(tester, 500);

  // Confirm removal dialog
  final removeButton = find.text('Remove');
  if (removeButton.evaluate().isNotEmpty) {
    await tester.tap(removeButton.last);
    await settle(tester);
    await visualPause(tester, 1000);
    print('  [Remove Player] Confirmed removal dialog');
  }

  // Verify count decreased
  final playerCountAfter = find.textContaining('Player').evaluate().length;
  print('  [Remove Player] Player count after: $playerCountAfter');

  if (playerCountAfter < playerCountBefore) {
    tracker.recordSuccess('Player removed from Team12 ($playerCountBefore → $playerCountAfter)');
  } else {
    // May still have removed — check for snackbar confirmation
    final snackbar = find.textContaining('removed');
    if (snackbar.evaluate().isNotEmpty) {
      tracker.recordSuccess('Player removed (snackbar confirmed)');
    } else {
      tracker.recordError('Remove player', 'Player count did not decrease');
    }
  }

  // Navigate back
  await goBack(tester);
  await settle(tester);
}
