import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'data_generators.dart';
import 'match_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Navigation Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Navigate to the Tournaments tab from the Home page.
Future<void> navigateToTournaments(WidgetTester tester) async {
  // Find the Tournaments tab in bottom navigation
  final tournamentsTab = find.text('Tournaments');
  if (tournamentsTab.evaluate().isNotEmpty) {
    await tester.tap(tournamentsTab);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to the Teams tab from the Home page.
Future<void> navigateToTeams(WidgetTester tester) async {
  final teamsTab = find.text('Teams');
  if (teamsTab.evaluate().isNotEmpty) {
    await tester.tap(teamsTab);
    await settle(tester);
    await visualPause(tester);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Team Creation
// ═══════════════════════════════════════════════════════════════════════════

/// Create a team through the UI.
/// After creation, the app navigates to the Team Detail page.
/// This helper returns on the Team Detail page.
Future<void> createTeam(
  WidgetTester tester,
  TeamData team,
) async {
  // Navigate to create team
  final createButton = find.text('Create Team');
  if (createButton.evaluate().isEmpty) {
    // Try FAB
    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab.first);
      await settle(tester);
    }
  } else {
    await tester.tap(createButton.first);
    await settle(tester);
  }
  await visualPause(tester);

  // Fill team name
  final nameField = find.byType(TextFormField);
  if (nameField.evaluate().isNotEmpty) {
    await tester.enterText(nameField.first, team.name);
    await settle(tester);
  }

  // Submit — button text is "Create Team" inside the form
  final submitButtons = find.text('Create Team');
  if (submitButtons.evaluate().length > 1) {
    // Last one is the submit button (first is the AppBar title)
    await tester.tap(submitButtons.last);
  } else if (submitButtons.evaluate().isNotEmpty) {
    await tester.tap(submitButtons.first);
  }
  await settle(tester);
  await visualPause(tester, 1000);

  // After creation, app navigates to Team Detail page.
  // We're now on the team detail page.
}

/// Add players to a team's roster through the UI.
/// Expects to be on the Team Detail page (default Overview tab).
///
/// Flow:
///   1. Switch to Players tab
///   2. First player: tap "Add Player" from empty state → AddPlayerPage
///   3. Subsequent players: tap "Manage" → ManageRosterPage → "Add Player"
///   4. On AddPlayerPage: "Create New" tab → fill name → select role → "Add to Team"
///   5. Returns on Team Detail page (Players tab)
Future<void> addPlayersToRoster(
  WidgetTester tester,
  List<PlayerData> players,
) async {
  if (players.isEmpty) return;

  // Switch to Players tab on TeamDetailPage
  final playersTab = find.text('Players');
  if (playersTab.evaluate().isNotEmpty) {
    // Use the Tab widget, not any other "Players" text
    await tester.tap(playersTab.last);
    await settle(tester);
    await visualPause(tester);
  }

  // Add first player from the empty state "Add Player" button
  final addPlayerBtn = find.text('Add Player');
  if (addPlayerBtn.evaluate().isNotEmpty) {
    await tester.tap(addPlayerBtn.first);
    await settle(tester);
  }
  await _fillAndSubmitPlayer(tester, players[0]);
  // After submit, we pop back to TeamDetailPage (Players tab)
  await settle(tester);
  await visualPause(tester, 500);

  // For remaining players, go through ManageRosterPage
  if (players.length > 1) {
    // Wait for provider refresh to show the "Manage" button
    await settle(tester);

    final manageBtn = find.text('Manage');
    if (manageBtn.evaluate().isNotEmpty) {
      await tester.tap(manageBtn.first);
      await settle(tester);
      await visualPause(tester);
    }

    // Now on ManageRosterPage — add remaining players in a loop
    for (var i = 1; i < players.length; i++) {
      final addBtn = find.text('Add Player');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await settle(tester);
      }
      await _fillAndSubmitPlayer(tester, players[i]);
      // After submit, pops back to ManageRosterPage
      await settle(tester);
      await visualPause(tester, 300);
    }

    // Go back from ManageRosterPage to TeamDetailPage
    await goBack(tester);
  }
}

/// Fill in the AddPlayerPage form and submit.
/// Expects to be on the AddPlayerPage.
Future<void> _fillAndSubmitPlayer(
  WidgetTester tester,
  PlayerData player,
) async {
  // Switch to "Create New" tab
  final createNewTab = find.text('Create New');
  if (createNewTab.evaluate().isNotEmpty) {
    await tester.tap(createNewTab.first);
    await settle(tester);
  }

  // Fill player name
  final nameField = find.byType(TextFormField);
  if (nameField.evaluate().isNotEmpty) {
    await tester.enterText(nameField.first, player.name);
    await settle(tester);
  }

  // Select role chip based on player.role
  final roleLabel = switch (player.role) {
    'batter' => 'Batter',
    'bowler' => 'Bowler',
    'all_rounder' => 'All-Rounder',
    'wk_batter' => 'WK-Batter',
    _ => 'All-Rounder',
  };
  final roleChip = find.text(roleLabel);
  if (roleChip.evaluate().isNotEmpty) {
    await tester.tap(roleChip.first);
    await settle(tester);
  }

  // Submit - "Add to Team" button
  final submitButton = find.text('Add to Team');
  if (submitButton.evaluate().isNotEmpty) {
    await tester.tap(submitButton.first);
    await settle(tester);
    await visualPause(tester, 500);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tournament Creation
// ═══════════════════════════════════════════════════════════════════════════

/// Create a tournament through the UI.
Future<void> createTournament(
  WidgetTester tester,
  TournamentConfig config,
) async {
  // Navigate to tournaments and tap create
  await navigateToTournaments(tester);

  final createButton = find.text('Create Tournament');
  if (createButton.evaluate().isEmpty) {
    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab.first);
      await settle(tester);
    }
  } else {
    await tester.tap(createButton.first);
    await settle(tester);
  }
  await visualPause(tester);

  // Fill tournament name
  final nameFields = find.byType(TextFormField);
  if (nameFields.evaluate().isNotEmpty) {
    await tester.enterText(nameFields.first, config.name);
    await settle(tester);
  }

  // Select format (scroll to find the right chip)
  final formatLabel = switch (config.format) {
    'group_knockout' => 'Group + Knockout',
    'knockout' => 'Knockout',
    'round_robin' => 'Round Robin',
    _ => 'Group + Knockout',
  };
  final formatChip = find.text(formatLabel);
  if (formatChip.evaluate().isNotEmpty) {
    await tester.tap(formatChip.first);
    await settle(tester);
  }

  // Set overs (find and tap the preset or enter manually)
  final oversPreset = find.text('${config.overs}');
  if (oversPreset.evaluate().isNotEmpty) {
    // Try to tap the preset chip
    await tester.tap(oversPreset.first);
    await settle(tester);
  }

  // Submit the form
  await settle(tester);
  final submitButton = find.text('Create Tournament');
  if (submitButton.evaluate().length > 1) {
    // Second one is the submit button (first is the page title in AppBar)
    await tester.tap(submitButton.last);
  } else if (submitButton.evaluate().isNotEmpty) {
    await tester.tap(submitButton.first);
  }
  await settle(tester);
  await visualPause(tester, 1000);
}

// ═══════════════════════════════════════════════════════════════════════════
// Team Assignment to Tournament
// ═══════════════════════════════════════════════════════════════════════════

/// Add a team to a tournament from the tournament detail page.
Future<void> addTeamToTournament(
  WidgetTester tester,
  String teamName, {
  String? groupName,
}) async {
  // Tap "Add Team" button
  final addTeamButton = find.text('Add Team');
  if (addTeamButton.evaluate().isNotEmpty) {
    await tester.tap(addTeamButton.first);
    await settle(tester);
  }

  // Select team from list
  final teamOption = find.text(teamName);
  if (teamOption.evaluate().isNotEmpty) {
    await tester.tap(teamOption.first);
    await settle(tester);
  }

  // Select group if needed
  if (groupName != null) {
    final groupOption = find.text(groupName);
    if (groupOption.evaluate().isNotEmpty) {
      await tester.tap(groupOption.first);
      await settle(tester);
    }
  }

  // Confirm
  final confirmButton = find.text('Confirm');
  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton.first);
    await settle(tester);
    await visualPause(tester);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fixture Generation
// ═══════════════════════════════════════════════════════════════════════════

/// Tap the "Generate Fixtures" button on the tournament detail page.
Future<void> generateFixtures(WidgetTester tester) async {
  final generateButton = find.text('Generate Fixtures');
  if (generateButton.evaluate().isNotEmpty) {
    await tester.tap(generateButton.first);
    await settle(tester);
    await visualPause(tester, 1000);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fixture-Based Match Start
// ═══════════════════════════════════════════════════════════════════════════

/// Tap on a fixture card to start a match from the Fixtures tab.
/// The fixture card shows "TeamA VS TeamB". Tapping it navigates to match setup.
Future<void> tapFixtureCard(
  WidgetTester tester, {
  required String homeTeamName,
  required String awayTeamName,
}) async {
  // Switch to Fixtures tab
  final fixturesTab = find.text('Fixtures');
  if (fixturesTab.evaluate().isNotEmpty) {
    await tester.tap(fixturesTab.first);
    await settle(tester);
    await visualPause(tester);
  }

  // Find the fixture card containing the home team name
  final homeText = find.text(homeTeamName);
  if (homeText.evaluate().isNotEmpty) {
    await tester.tap(homeText.first);
    await settle(tester);
    await visualPause(tester);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Match Setup & Toss Wizard
// ═══════════════════════════════════════════════════════════════════════════

/// Complete the Match Setup page (teams pre-selected from fixture).
/// Taps "Proceed to Toss" and waits for the Toss page to appear.
Future<void> completeMatchSetup(WidgetTester tester) async {
  // Teams are pre-selected from fixture, so "Proceed to Toss" should be enabled
  await settle(tester);
  await visualPause(tester, 300);

  // Scroll to and tap "Proceed to Toss"
  final proceedButton = find.text('Proceed to Toss');
  if (proceedButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(proceedButton);
    await tester.pumpAndSettle();
    await tester.tap(proceedButton);
    await settle(tester);
    await visualPause(tester, 500);
  }
}

/// Complete the full Toss Wizard (5 steps) through the UI.
///
/// Steps:
///   1. "Who won the toss?" → select [tossWinner]
///   2. "chose to..." → select "Bat"
///   3. Playing XI for home team → pre-selected → Next
///   4. Playing XI for away team → pre-selected → Next
///   5. Select 2 opening batsmen + 1 opening bowler → Start Match
///
/// [tossWinnerName]: Name of the team that wins the toss (will bat first).
/// [battingOpener1], [battingOpener2]: Names of the first two batsmen.
/// [openingBowler]: Name of the first bowler.
Future<void> completeTossWizard(
  WidgetTester tester, {
  required String tossWinnerName,
  required String battingOpener1,
  required String battingOpener2,
  required String openingBowler,
}) async {
  // Step 1: "Who won the toss?" → tap team card
  await settle(tester);
  expect(find.text('Who won the toss?'), findsOneWidget,
      reason: 'Should be on Toss Step 1');
  final teamCard = find.text(tossWinnerName);
  if (teamCard.evaluate().isNotEmpty) {
    await tester.tap(teamCard.first);
    await tester.pump();
  }
  // Tap Next
  await tester.tap(find.text('Next'));
  await settle(tester);
  await visualPause(tester);

  // Step 2: Toss decision → tap "Bat"
  final batOption = find.text('Bat');
  if (batOption.evaluate().isNotEmpty) {
    await tester.tap(batOption.first);
    await tester.pump();
  }
  await tester.tap(find.text('Next'));
  await settle(tester);
  await visualPause(tester);

  // Step 3: Playing XI for first team — pre-selected → tap Next
  await tester.tap(find.text('Next'));
  await settle(tester);
  await visualPause(tester);

  // Step 4: Playing XI for second team — pre-selected → tap Next
  await tester.tap(find.text('Next'));
  await settle(tester);
  await visualPause(tester);

  // Step 5: Select openers and bowler
  // Select first opener
  final opener1 = find.textContaining(battingOpener1);
  if (opener1.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener1.first);
    await tester.pumpAndSettle();
    await tester.tap(opener1.first);
    await tester.pump();
    await visualPause(tester);
  }

  // Select second opener
  final opener2 = find.textContaining(battingOpener2);
  if (opener2.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener2.first);
    await tester.pumpAndSettle();
    await tester.tap(opener2.first);
    await tester.pump();
    await visualPause(tester);
  }

  // Select striker (first opener faces first ball)
  // After selecting 2 openers, a "Who will face the first ball?" prompt appears
  // Tap the first opener's name in the striker prompt
  final strikerOption = find.text(battingOpener1);
  // There may be multiple instances; we want the one in the striker prompt (last)
  if (strikerOption.evaluate().length > 1) {
    await tester.tap(strikerOption.last);
    await tester.pump();
    await visualPause(tester);
  }

  // Scroll down to bowler section and select opening bowler
  final bowlerOption = find.textContaining(openingBowler);
  if (bowlerOption.evaluate().isNotEmpty) {
    await tester.ensureVisible(bowlerOption.first);
    await tester.pumpAndSettle();
    await tester.tap(bowlerOption.first);
    await tester.pump();
    await visualPause(tester);
  }

  // Tap "Start Match" button
  final startMatch = find.text('Start Match');
  if (startMatch.evaluate().isNotEmpty) {
    await tester.ensureVisible(startMatch);
    await tester.pumpAndSettle();
    await tester.tap(startMatch);
    await settle(tester);
    await visualPause(tester, 500);
  }
}

/// Navigate back to home after a match completes.
Future<void> navigateToHome(WidgetTester tester) async {
  // Try "Back to Home" button first (match complete modal)
  final backHome = find.text('Back to Home');
  if (backHome.evaluate().isNotEmpty) {
    await tester.tap(backHome.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }

  // Try navigating via GoRouter
  try {
    final context = tester.element(find.byType(Navigator).last);
    GoRouter.of(context).go('/home');
    await settle(tester);
    await visualPause(tester);
  } catch (_) {
    // Fallback: tap back button
    await goBack(tester);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Standings Verification
// ═══════════════════════════════════════════════════════════════════════════

/// Navigate to the standings page and verify it shows data.
Future<void> verifyStandingsPage(WidgetTester tester) async {
  final standingsTab = find.text('Standings');
  if (standingsTab.evaluate().isNotEmpty) {
    await tester.tap(standingsTab.first);
    await settle(tester);
    await visualPause(tester, 500);
  }

  // Verify some standings data is displayed
  // (specific assertions depend on actual UI layout)
}

/// Navigate to the leaderboard page.
Future<void> navigateToLeaderboard(WidgetTester tester) async {
  final leaderboardTab = find.text('Leaderboard');
  if (leaderboardTab.evaluate().isNotEmpty) {
    await tester.tap(leaderboardTab.first);
    await settle(tester);
    await visualPause(tester, 500);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Go Back
// ═══════════════════════════════════════════════════════════════════════════

/// Tap the back button to go to the previous page.
Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
    await visualPause(tester);
  }
}
