/// Form interaction helpers — team creation, player addition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../config/test_data.dart';
import '../core/test_utils.dart';

/// Create a team through the UI.
/// After creation, the app navigates to the Team Detail page.
Future<void> createTeam(WidgetTester tester, TestTeam team) async {
  // Navigate to create team page via GoRouter
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).push('/teams/create');
    await settle(tester);
    print('    [createTeam] Navigated to create team via GoRouter');
  } catch (e) {
    final createCTA = find.text('Create a Team');
    if (createCTA.evaluate().isNotEmpty) {
      await tester.tap(createCTA.first);
      await settle(tester);
    } else {
      print('    [createTeam] WARNING: GoRouter and CTA both failed: $e');
    }
  }
  await visualPause(tester);

  // Fill team name using Key
  final nameField = find.byKey(const Key('teamNameField'));
  expect(nameField, findsOneWidget,
      reason: 'Create team page should have a teamNameField');
  await tester.tap(nameField.first);
  await tester.pumpAndSettle();
  await tester.enterText(nameField.first, team.name);
  await settle(tester);
  print('    [createTeam] Entered team name: ${team.name}');

  // Submit
  final submitBtn = find.byType(FilledButton);
  if (submitBtn.evaluate().isNotEmpty) {
    await tester.ensureVisible(submitBtn.first);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn.first);
    print('    [createTeam] Tapped submit FilledButton');
  }
  await settle(tester);
  await visualPause(tester, 2000);

  // Verify navigation to team detail
  final teamNameInTitle = find.text(team.name);
  if (teamNameInTitle.evaluate().isNotEmpty) {
    print('    [createTeam] Navigated to team detail for: ${team.name}');
  } else {
    dumpVisibleTexts(tester, 'createTeam-afterSubmit', 25);
    print('    [createTeam] WARNING: Team name not found after submit.');
  }
}

/// Add players to a team's roster through the UI.
/// Expects to be on the Team Detail page.
Future<void> addPlayersToRoster(
  WidgetTester tester,
  List<TestPlayer> players,
) async {
  if (players.isEmpty) return;

  // Switch to Players tab
  final playersTab = find.text('Players');
  if (playersTab.evaluate().isNotEmpty) {
    await tester.tap(playersTab.last);
    await settle(tester);
    await visualPause(tester);
  }

  // Try "Add Player" button from empty state for player[0]
  final addPlayerBtn = find.text('Add Player');
  bool firstPlayerAdded = false;
  if (addPlayerBtn.evaluate().isNotEmpty) {
    await tester.tap(addPlayerBtn.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('    [addPlayers] Navigated to AddPlayerPage for player[0]');
    await fillAndSubmitPlayer(tester, players[0]);
    await settle(tester);
    await visualPause(tester, 500);
    firstPlayerAdded = true;
  } else {
    print('    [addPlayers] "Add Player" button not found — will use GoRouter for all players');
  }

  // Extract teamId from current GoRouter location (poll up to 6s)
  String? teamId;
  final uuidRegex = RegExp(
    r'/teams/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
    caseSensitive: false,
  );
  final deadline = DateTime.now().add(const Duration(seconds: 6));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    try {
      final routerState = GoRouterState.of(
        tester.element(find.byType(Scaffold).first),
      );
      final currentPath = routerState.uri.toString();
      final match = uuidRegex.firstMatch(currentPath);
      if (match != null) {
        teamId = match.group(1);
        print('    [addPlayers] Extracted teamId=$teamId from $currentPath');
        break;
      }
    } catch (_) {
      // GoRouter may not be ready yet — retry
    }
  }
  expect(teamId, isNotNull,
      reason: 'Should extract teamId UUID from GoRouter location within 6s');

  // Use GoRouter navigation for remaining players
  final startIndex = firstPlayerAdded ? 1 : 0;
  if (startIndex < players.length) {
    print('    [addPlayers] Using GoRouter navigation for players[$startIndex..${players.length - 1}]');

    for (var i = startIndex; i < players.length; i++) {
      final router = GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      );
      router.push('/teams/$teamId/add-player');
      await settle(tester);
      await visualPause(tester, 300);

      // Wait for AddPlayerPage to appear
      await waitForText(tester, 'Create New', timeoutMs: 2000);

      await fillAndSubmitPlayer(tester, players[i]);
      await settle(tester);
    }
  }
}

/// Fill in the AddPlayerPage form and submit.
Future<void> fillAndSubmitPlayer(
  WidgetTester tester,
  TestPlayer player,
) async {
  // Guard: verify we're on AddPlayerPage
  final addPlayerTitle = find.text('Add Player');
  final createNewTabCheck = find.text('Create New');
  final onAddPlayerPage =
      addPlayerTitle.evaluate().isNotEmpty || createNewTabCheck.evaluate().isNotEmpty;
  expect(onAddPlayerPage, isTrue,
      reason: 'Should be on AddPlayerPage to add ${player.name}');

  // Switch to "Create New" tab
  final createNewTab = find.text('Create New');
  if (createNewTab.evaluate().isNotEmpty) {
    await tester.tap(createNewTab.first);
    await settle(tester);
  }

  // Fill player name
  final nameField = find.byKey(const Key('playerNameField'));
  expect(nameField, findsOneWidget,
      reason: 'Add player page should have playerNameField for ${player.name}');
  await tester.tap(nameField.first);
  await tester.pumpAndSettle();
  await tester.enterText(nameField.first, player.name);
  await settle(tester);
  print('    [fillPlayer] Entered player name: ${player.name}');

  // Fill phone number
  final phoneField = find.byKey(const Key('playerPhoneField'));
  if (phoneField.evaluate().isNotEmpty) {
    await tester.enterText(phoneField.first, player.phone);
    await settle(tester);
    print('    [fillPlayer] Entered phone: ${player.phone}');
  }

  // Dismiss keyboard before scrolling to chips
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Select role chip
  final roleLabel = switch (player.role) {
    'batter' => 'Batter',
    'bowler' => 'Bowler',
    'all_rounder' => 'All-Rounder',
    'wk_batter' => 'WK-Batter',
    _ => 'All-Rounder',
  };
  final roleChip = find.text(roleLabel);
  if (roleChip.evaluate().isNotEmpty) {
    await tester.ensureVisible(roleChip.first);
    await tester.pumpAndSettle();
    await tester.tap(roleChip.first, warnIfMissed: false);
    await settle(tester);
  }

  // Submit
  final submitButton = find.text('Add to Team');
  if (submitButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(submitButton.first);
    await tester.pumpAndSettle();
    await tester.tap(submitButton.first, warnIfMissed: false);

    // Wait for page pop (API calls complete)
    final popped = await waitForFinderGone(
        tester, find.byKey(const Key('playerNameField')),
        timeoutMs: 6000, intervalMs: 200);
    await settle(tester);

    if (popped) {
      print('    [fillPlayer] Added player: ${player.name}');
    } else {
      print('    [fillPlayer] WARNING: Page did not pop after adding ${player.name}');
    }
  } else {
    print('    [fillPlayer] WARNING: "Add to Team" not found for ${player.name}');
  }
}
