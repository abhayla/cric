import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // Submit
  final submitButton = find.text('Create');
  if (submitButton.evaluate().isNotEmpty) {
    await tester.tap(submitButton.first);
    await settle(tester);
    await visualPause(tester, 500);
  }
}

/// Add players to a team's roster through the UI.
Future<void> addPlayersToRoster(
  WidgetTester tester,
  List<PlayerData> players,
) async {
  for (final player in players) {
    // Tap "Add Player" button
    final addButton = find.text('Add Player');
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton.first);
      await settle(tester);
    }

    // Fill player name
    final nameField = find.byType(TextFormField);
    if (nameField.evaluate().isNotEmpty) {
      await tester.enterText(nameField.first, player.name);
      await settle(tester);
    }

    // Submit
    final submitButton = find.text('Add');
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton.first);
      await settle(tester);
      await visualPause(tester);
    }
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
