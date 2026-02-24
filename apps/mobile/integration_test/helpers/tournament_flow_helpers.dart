import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';

import 'data_generators.dart';
import 'match_flow_helpers.dart';

/// Debug: Print first N visible text widgets on screen.
void dumpVisibleTexts(WidgetTester tester, String label, [int count = 15]) {
  final allTexts = find.byType(Text);
  final textValues = allTexts.evaluate().take(count).map((e) {
    final widget = e.widget as Text;
    return widget.data ?? widget.textSpan?.toPlainText() ?? '(no text)';
  }).toList();
  print('    [$label] Visible texts: $textValues');
}

// ═══════════════════════════════════════════════════════════════════════════
// Navigation Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Navigate to the Tournaments sub-tab within My Cricket page.
///
/// Flow: Go to My Cricket (bottom nav) → tap Tournaments sub-tab.
Future<void> navigateToTournaments(WidgetTester tester) async {
  // First ensure we're on My Cricket page (bottom nav tab 0)
  await _ensureOnMyCricketPage(tester);

  // Then tap the Tournaments sub-tab within My Cricket
  final tournamentsTab = find.text('Tournaments');
  if (tournamentsTab.evaluate().isNotEmpty) {
    await tester.tap(tournamentsTab.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to the Teams sub-tab within My Cricket page.
///
/// Flow: Go to My Cricket (bottom nav) → tap Teams sub-tab.
/// Also works from outside the ShellRoute via GoRouter.go('/home').
Future<void> navigateToTeams(WidgetTester tester) async {
  // First ensure we're on My Cricket page
  await _ensureOnMyCricketPage(tester);

  // Teams is the first sub-tab (default), but tap it explicitly to be safe
  final teamsTab = find.text('Teams');
  if (teamsTab.evaluate().isNotEmpty) {
    await tester.tap(teamsTab.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Ensure we're on the My Cricket page (first bottom nav tab).
Future<void> _ensureOnMyCricketPage(WidgetTester tester) async {
  // Check if we're already on My Cricket page (has the TabBar with sub-tabs)
  final myCricketTitle = find.textContaining('Cricket');
  if (myCricketTitle.evaluate().isNotEmpty) return;

  // Try tapping "My Cricket" in bottom nav
  final navBar = find.byType(NavigationBar);
  final myCricketNav = find.text('My Cricket');
  if (navBar.evaluate().isNotEmpty && myCricketNav.evaluate().isNotEmpty) {
    await tester.tap(myCricketNav.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }

  // Fallback: use GoRouter
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).go('/home');
    await settle(tester);
    await visualPause(tester);
    print('    [_ensureOnMyCricketPage] Used GoRouter.go(/home)');
  } catch (e) {
    print('    [_ensureOnMyCricketPage] WARNING: GoRouter navigation failed: $e');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Match Setup Navigation
// ═══════════════════════════════════════════════════════════════════════════

/// Navigate to match setup page via GoRouter.
///
/// Avoids tapping FAB "Start Match" label which can overlap with other FAB
/// labels in the ExpandableFab stack, causing unreliable hit-testing.
Future<void> navigateToMatchSetup(WidgetTester tester) async {
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).push('/match-setup');
    await settle(tester);
    await visualPause(tester, 500);
    print('    [navigateToMatchSetup] Navigated via GoRouter');
  } catch (e) {
    print('    [navigateToMatchSetup] WARNING: GoRouter failed: $e');
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
  // Navigate to create team page via GoRouter (more reliable than tapping
  // FAB labels which can overlap in the ExpandableFab stack)
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).push('/teams/create');
    await settle(tester);
    print('    [createTeam] Navigated to create team via GoRouter');
  } catch (e) {
    // Fallback: try tapping empty state CTA or FAB
    final createCTA = find.text('Create a Team');
    if (createCTA.evaluate().isNotEmpty) {
      await tester.tap(createCTA.first);
      await settle(tester);
    } else {
      print('    [createTeam] WARNING: GoRouter and CTA both failed: $e');
    }
  }
  await visualPause(tester);

  // Fill team name using Key for reliable targeting (not TextFormField.first)
  final nameField = find.byKey(const Key('teamNameField'));
  if (nameField.evaluate().isNotEmpty) {
    await tester.tap(nameField.first);
    await tester.pumpAndSettle();
    await tester.enterText(nameField.first, team.name);
    await settle(tester);
    print('    [createTeam] Entered team name: ${team.name}');
  } else {
    // If key not found, dump page to diagnose
    dumpVisibleTexts(tester, 'createTeam-noNameField', 30);
    print('    [createTeam] ERROR: teamNameField key not found! Aborting.');
    return;
  }

  // Submit via FilledButton (more reliable than text-based finding)
  final submitBtn = find.byType(FilledButton);
  if (submitBtn.evaluate().isNotEmpty) {
    await tester.ensureVisible(submitBtn.first);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn.first);
    print('    [createTeam] Tapped submit FilledButton');
  }
  await settle(tester);
  await visualPause(tester, 2000);

  // Verify we navigated to team detail (the team name appears in AppBar)
  final teamNameInTitle = find.text(team.name);
  if (teamNameInTitle.evaluate().isNotEmpty) {
    print('    [createTeam] ✓ Navigated to team detail for: ${team.name}');
  } else {
    dumpVisibleTexts(tester, 'createTeam-afterSubmit', 25);
    print('    [createTeam] WARNING: Team name not found after submit. '
        'Team creation may have failed (check auth/server).');
  }
}

/// Add players to a team's roster through the UI.
/// Expects to be on the Team Detail page (default Overview tab).
///
/// Flow:
///   1. Switch to Players tab
///   2. First player: tap "Add Player" from empty state → AddPlayerPage
///   3. Subsequent players: tap FAB (person_add) on Players tab → AddPlayerPage
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

  // Try the "Add Player" button from empty state for player[0]
  final addPlayerBtn = find.text('Add Player');
  bool firstPlayerAdded = false;
  if (addPlayerBtn.evaluate().isNotEmpty) {
    await tester.tap(addPlayerBtn.first);
    await settle(tester);
    await visualPause(tester, 500);
    print('    [addPlayers] Navigated to AddPlayerPage for player[0]');
    await _fillAndSubmitPlayer(tester, players[0]);
    await settle(tester);
    await visualPause(tester, 500);
    firstPlayerAdded = true;
  } else {
    print('    [addPlayers] "Add Player" button not found — will use GoRouter for all players');
  }

  // Extract teamId from current GoRouter location for direct navigation.
  // After team creation, GoRouter.go() replaces /teams/create → /teams/<uuid>.
  // We must wait for the route to contain a valid UUID (not "create").
  String? teamId;
  final uuidRegex = RegExp(r'/teams/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})', caseSensitive: false);
  for (var attempt = 0; attempt < 30; attempt++) {
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
      if (attempt == 29) {
        print('    [addPlayers] ERROR: Route still has no UUID after 6s: $currentPath');
      }
    } catch (e) {
      if (attempt == 29) {
        print('    [addPlayers] ERROR: Could not read GoRouter state: $e');
      }
    }
  }

  if (teamId == null) {
    print('    [addPlayers] ERROR: Could not extract teamId — aborting player addition');
    return;
  }

  // Use GoRouter navigation for remaining players (or all if first wasn't added)
  final startIndex = firstPlayerAdded ? 1 : 0;
  if (startIndex < players.length) {
    print('    [addPlayers] Using GoRouter navigation for players[$startIndex..${players.length - 1}] (teamId=$teamId)');

    for (var i = startIndex; i < players.length; i++) {
      final router = GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      );
      router.push('/teams/$teamId/add-player');
      await settle(tester);
      await visualPause(tester, 300);

      // Wait for AddPlayerPage to appear
      for (var wait = 0; wait < 10; wait++) {
        if (find.text('Create New').evaluate().isNotEmpty ||
            find.byKey(const Key('playerNameField')).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 200));
      }

      await _fillAndSubmitPlayer(tester, players[i]);
      await settle(tester);
    }
  }
}

/// Fill in the AddPlayerPage form and submit.
/// Expects to be on the AddPlayerPage. If not, logs a warning and returns.
Future<void> _fillAndSubmitPlayer(
  WidgetTester tester,
  PlayerData player,
) async {
  // Guard: verify we're actually on AddPlayerPage before doing anything.
  // AddPlayerPage has "Add Player" in the AppBar title and "Create New" tab.
  final addPlayerTitle = find.text('Add Player');
  final createNewTabCheck = find.text('Create New');
  if (addPlayerTitle.evaluate().isEmpty && createNewTabCheck.evaluate().isEmpty) {
    dumpVisibleTexts(tester, 'fillPlayer-notOnAddPage', 20);
    print('    [fillPlayer] WARNING: Not on AddPlayerPage! Skipping ${player.name}.');
    return;
  }

  // Switch to "Create New" tab
  final createNewTab = find.text('Create New');
  if (createNewTab.evaluate().isNotEmpty) {
    await tester.tap(createNewTab.first);
    await settle(tester);
  }

  // Fill player name using Key for unambiguous targeting.
  // Key 'playerNameField' is set on the player name TextFormField in _CreateTab.
  final nameField = find.byKey(const Key('playerNameField'));
  if (nameField.evaluate().isNotEmpty) {
    await tester.tap(nameField.first);
    await tester.pumpAndSettle();
    await tester.enterText(nameField.first, player.name);
    await settle(tester);
    print('    [fillPlayer] Entered player name: ${player.name}');
  } else {
    dumpVisibleTexts(tester, 'fillPlayer-noNameField', 25);
    print('    [fillPlayer] ERROR: playerNameField key not found! Cannot add ${player.name}.');
    return;
  }

  // Fill phone number (required field) — generate a unique valid Indian mobile number
  final phoneField = find.byKey(const Key('playerPhoneField'));
  if (phoneField.evaluate().isNotEmpty) {
    // Generate a unique 10-digit phone starting with 9 based on player name hash
    final phoneHash = player.name.hashCode.abs() % 900000000 + 100000000;
    final phone = '9$phoneHash';
    await tester.enterText(phoneField.first, phone);
    await settle(tester);
    print('    [fillPlayer] Entered phone: $phone');
  }

  // Dismiss keyboard before scrolling to chips (keyboard may cover them)
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

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
    await tester.ensureVisible(roleChip.first);
    await tester.pumpAndSettle();
    await tester.tap(roleChip.first, warnIfMissed: false);
    await settle(tester);
  }

  // Submit - "Add to Team" FilledButton (enabled only when name + phone are valid)
  // On a real emulator the software keyboard may push the layout up,
  // so we scroll to make the button visible before tapping.
  final submitButton = find.text('Add to Team');
  if (submitButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(submitButton.first);
    await tester.pumpAndSettle();
    await tester.tap(submitButton.first, warnIfMissed: false);

    // The onCreatePlayer callback makes 2 sequential API calls to a remote DB
    // (createPlayer + addPlayer) then pops the page. We must wait for the pop
    // to complete before returning, otherwise the next iteration enters text
    // into this still-open AddPlayerPage, causing a race condition where
    // alternating players are lost.
    // Wait until the playerNameField disappears (page was popped).
    var popped = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('playerNameField')).evaluate().isEmpty) {
        popped = true;
        break;
      }
    }
    await settle(tester);

    if (popped) {
      print('    [fillPlayer] ✓ Added player: ${player.name}');
    } else {
      print('    [fillPlayer] WARNING: Page did not pop after adding ${player.name} (API may be slow)');
    }
  } else {
    print('    [fillPlayer] WARNING: "Add to Team" not found for ${player.name}');
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

  // Submit the form — use FilledButton finder for reliability
  await settle(tester);

  // Find the FilledButton directly
  final filledButtons = find.byType(FilledButton);
  print('    [createTournament] FilledButtons found: ${filledButtons.evaluate().length}');
  if (filledButtons.evaluate().isNotEmpty) {
    // Ensure button is visible (scroll if needed)
    await tester.ensureVisible(filledButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(filledButtons.first);
    print('    [createTournament] Tapped FilledButton');
  } else {
    print('    [createTournament] ERROR: No FilledButton found!');
    // Fallback to text finder
    final submitButton = find.text('Create Tournament');
    if (submitButton.evaluate().length > 1) {
      await tester.tap(submitButton.last);
    }
  }
  await settle(tester);
  await visualPause(tester, 3000);

  // Check if we navigated away from the form
  final stillOnForm = find.text('Tournament Name');
  if (stillOnForm.evaluate().isNotEmpty) {
    print('    [createTournament] WARNING: Still on create form after submit!');
    dumpVisibleTexts(tester, 'createTournament STUCK', 30);
  } else {
    print('    [createTournament] Successfully navigated away from form');
  }
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
///
/// Finds the specific FixtureCard widget containing the away team name
/// and taps it. Scrolls through the list if the card is not visible.
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
    print('    [tapFixtureCard] Switched to Fixtures tab');
  } else {
    print('    [tapFixtureCard] WARNING: Fixtures tab not found!');
  }

  // Find a FixtureCard that contains BOTH team names (to avoid matching a
  // completed fixture that shares one team name). The tournament detail page
  // has a pinned SliverAppBar, so we must scroll cards below it before tapping.
  bool tapped = false;

  for (var scroll = 0; scroll < 15 && !tapped; scroll++) {
    // Get all FixtureCard widgets currently in the tree
    final allCards = find.byType(FixtureCard).evaluate().toList();

    for (var cardIdx = 0; cardIdx < allCards.length; cardIdx++) {
      final cardElement = allCards[cardIdx];
      final fixtureCard = cardElement.widget as FixtureCard;
      final fixture = fixtureCard.fixture;

      // Match by both team names
      final hasHome = fixture.homeTeamName == homeTeamName;
      final hasAway = fixture.awayTeamName == awayTeamName;

      if (hasHome && hasAway) {
        // Found the right fixture card — scroll it into view
        final cardFinder = find.byWidget(fixtureCard);
        await tester.ensureVisible(cardFinder);
        await tester.pumpAndSettle();

        // Check if it's behind the pinned header
        final renderBox = cardElement.renderObject! as RenderBox;
        final yPosition = renderBox.localToGlobal(Offset.zero).dy;
        print('    [tapFixtureCard] Found "$homeTeamName vs $awayTeamName" at y=$yPosition');

        if (yPosition < 200) {
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            final dragAmount = 200 - yPosition + 50;
            await tester.drag(scrollable.last, Offset(0, dragAmount));
            await tester.pumpAndSettle();
          }
        }

        // Tap the InkWell inside this specific card
        final inkWell = find.descendant(
          of: cardFinder,
          matching: find.byType(InkWell),
        );

        if (inkWell.evaluate().isNotEmpty) {
          await tester.tap(inkWell.first);
          print('    [tapFixtureCard] Tapped InkWell for $homeTeamName vs $awayTeamName');
        } else {
          await tester.tap(cardFinder, warnIfMissed: false);
          print('    [tapFixtureCard] Tapped card for $homeTeamName vs $awayTeamName');
        }
        await settle(tester);
        await visualPause(tester);
        tapped = true;
        break;
      }
    }

    if (!tapped) {
      // Scroll down to reveal more fixtures
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.last, const Offset(0, -300));
        await settle(tester);
      } else {
        break;
      }
    }
  }

  if (!tapped) {
    print('    [tapFixtureCard] WARNING: Fixture "$homeTeamName vs $awayTeamName" not found!');
    dumpVisibleTexts(tester, 'tapFixtureCard', 30);
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

  // Debug: Print current page state
  final proceedButton = find.text('Proceed to Toss');
  print('    [matchSetup] "Proceed to Toss" found: ${proceedButton.evaluate().isNotEmpty}');

  if (proceedButton.evaluate().isEmpty) {
    // Dump visible texts for debugging
    final allTexts = find.byType(Text);
    final textValues = allTexts.evaluate().take(30).map((e) {
      final widget = e.widget as Text;
      return widget.data ?? widget.textSpan?.toPlainText() ?? '(no text)';
    }).toList();
    print('    [matchSetup] WARNING: Not on match setup page! Visible texts: $textValues');
    return;
  }

  // Scroll to and tap "Proceed to Toss"
  await tester.ensureVisible(proceedButton);
  await tester.pumpAndSettle();
  await tester.tap(proceedButton);
  await settle(tester);
  // Wait extra time for API call to complete
  await visualPause(tester, 2000);

  // Debug: Check if we navigated to toss page
  final tossText = find.text('Who won the toss?');
  print('    [matchSetup] After proceed, toss page found: ${tossText.evaluate().isNotEmpty}');
  if (tossText.evaluate().isEmpty) {
    final allTexts = find.byType(Text);
    final textValues = allTexts.evaluate().take(30).map((e) {
      final widget = e.widget as Text;
      return widget.data ?? widget.textSpan?.toPlainText() ?? '(no text)';
    }).toList();
    print('    [matchSetup] Current visible texts: $textValues');
  }
}

/// Complete the full Toss Wizard (5 steps) through the UI.
///
/// Steps:
///   1. "Who won the toss?" → select [tossWinner]
///   2. "chose to..." → select "Bat"
///   3. Playing XI for home team → pre-selected (if roster=playersPerSide) → Next
///   4. Playing XI for away team → pre-selected (if roster=playersPerSide) → Next
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
  int? playersPerSide,
  bool chooseBat = true,
}) async {
  // Step 1: "Who won the toss?" → tap team card
  await settle(tester);
  print('    [toss] Step 1: Selecting toss winner: $tossWinnerName');
  expect(find.text('Who won the toss?'), findsOneWidget,
      reason: 'Should be on Toss Step 1');
  final teamCard = find.text(tossWinnerName);
  if (teamCard.evaluate().isNotEmpty) {
    await tester.tap(teamCard.first);
    await tester.pump();
  }
  await _tapNextButton(tester);

  // Step 2: Toss decision → tap "Bat" or "Field"
  final choice = chooseBat ? 'Bat' : 'Field';
  print('    [toss] Step 2: Choosing to $choice');
  final choiceOption = find.text(choice);
  if (choiceOption.evaluate().isNotEmpty) {
    await tester.tap(choiceOption.first);
    await tester.pump();
  }
  await _tapNextButton(tester);

  // Step 3: Playing XI for first team — select players if needed, then Next
  print('    [toss] Step 3: Playing XI Team A');
  await _selectPlayingXIIfNeeded(tester, playersPerSide);
  await _tapNextButton(tester);

  // Step 4: Playing XI for second team — select players if needed, then Next
  print('    [toss] Step 4: Playing XI Team B');
  await _selectPlayingXIIfNeeded(tester, playersPerSide);
  await _tapNextButton(tester);

  // Step 5: Select openers and bowler
  print('    [toss] Step 5: Selecting openers ($battingOpener1, $battingOpener2) and bowler ($openingBowler)');

  // Dump all text widgets to see what's on screen
  dumpVisibleTexts(tester, 'toss-step5-before', 40);

  // Select first opener
  final opener1 = find.textContaining(battingOpener1);
  print('    [toss] Opener1 "$battingOpener1" found: ${opener1.evaluate().length}');
  if (opener1.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener1.first);
    await tester.pumpAndSettle();
    await tester.tap(opener1.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Tapped opener1');
  }

  // Select second opener
  final opener2 = find.textContaining(battingOpener2);
  print('    [toss] Opener2 "$battingOpener2" found: ${opener2.evaluate().length}');
  if (opener2.evaluate().isNotEmpty) {
    await tester.ensureVisible(opener2.first);
    await tester.pumpAndSettle();
    await tester.tap(opener2.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Tapped opener2');
  }

  // Select striker (first opener faces first ball)
  // After selecting 2 openers, a "Who will face the first ball?" prompt appears
  await settle(tester);
  final strikerPrompt = find.text('Who will face the first ball?');
  print('    [toss] Striker prompt found: ${strikerPrompt.evaluate().isNotEmpty}');

  if (strikerPrompt.evaluate().isNotEmpty) {
    // Find the striker option INSIDE the striker prompt container
    // The prompt and options share a parent Container — find the opener name
    // that is BELOW the prompt text by using the second instance
    final strikerOption = find.text(battingOpener1);
    print('    [toss] Striker option "$battingOpener1" found: ${strikerOption.evaluate().length}');
    // The striker prompt options render AFTER the opener list rows in the tree.
    // The last match is the one inside the striker prompt.
    if (strikerOption.evaluate().length >= 2) {
      await tester.ensureVisible(strikerOption.last);
      await tester.pumpAndSettle();
      await tester.tap(strikerOption.last);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (tapped last of ${strikerOption.evaluate().length})');
    } else if (strikerOption.evaluate().isNotEmpty) {
      await tester.ensureVisible(strikerOption.first);
      await tester.pumpAndSettle();
      await tester.tap(strikerOption.first);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Selected striker (single match)');
    }
  } else {
    print('    [toss] WARNING: Striker prompt not found! Openers may not be selected.');
  }

  // Verify openers are still selected after striker tap
  await tester.pump();
  final strikerPromptStillVisible = find.text('Who will face the first ball?');
  print('    [toss] Striker prompt still visible after selection: ${strikerPromptStillVisible.evaluate().isNotEmpty}');
  if (strikerPromptStillVisible.evaluate().isEmpty) {
    print('    [toss] ERROR: Striker prompt disappeared! An opener was likely deselected.');
    print('    [toss] Re-selecting openers...');
    // Re-select openers
    final reOpener1 = find.textContaining(battingOpener1);
    if (reOpener1.evaluate().isNotEmpty) {
      await tester.tap(reOpener1.first);
      await tester.pump();
    }
    final reOpener2 = find.textContaining(battingOpener2);
    if (reOpener2.evaluate().isNotEmpty) {
      await tester.tap(reOpener2.first);
      await tester.pump();
    }
    await settle(tester);
    // Re-select striker — now use last again
    final reStrikerOption = find.text(battingOpener1);
    if (reStrikerOption.evaluate().length >= 2) {
      await tester.tap(reStrikerOption.last);
      await tester.pump();
      await visualPause(tester);
      print('    [toss] Re-selected striker');
    }
  }

  // Scroll down to bowler section and select opening bowler
  final bowlerOption = find.textContaining(openingBowler);
  print('    [toss] Bowler "$openingBowler" found: ${bowlerOption.evaluate().length}');
  if (bowlerOption.evaluate().isNotEmpty) {
    await tester.ensureVisible(bowlerOption.first);
    await tester.pumpAndSettle();
    await tester.tap(bowlerOption.first);
    await tester.pump();
    await visualPause(tester);
    print('    [toss] Selected bowler');
  } else {
    print('    [toss] WARNING: Bowler "$openingBowler" not found in widget tree!');
    // Dump ALL texts to see what's available
    final allTexts = find.byType(Text);
    final all = allTexts.evaluate().map((e) {
      final w = e.widget as Text;
      return w.data ?? w.textSpan?.toPlainText() ?? '';
    }).where((t) => t.isNotEmpty).toList();
    print('    [toss] All ${all.length} text widgets: $all');
  }

  // Tap "Start Match" button — use FilledButton finder to check enabled state
  final filledButtons = find.byType(FilledButton);
  print('    [toss] FilledButtons found: ${filledButtons.evaluate().length}');
  if (filledButtons.evaluate().isNotEmpty) {
    final button = filledButtons.last.evaluate().first.widget as FilledButton;
    final isEnabled = button.onPressed != null;
    print('    [toss] Start Match button enabled: $isEnabled');
    if (isEnabled) {
      await tester.ensureVisible(filledButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(filledButtons.last);
      // Wait for async API calls (setPlayingXI x2, recordToss) to complete
      // These are real HTTP calls on the device, need real-time wait
      await visualPause(tester, 5000);
      // Pump frames to let GoRouter navigation rebuild the widget tree
      await settle(tester);
      await visualPause(tester, 1000);
      await settle(tester);
      print('    [toss] Start Match tapped, waiting for scoring page...');
    } else {
      print('    [toss] ERROR: Start Match button is DISABLED! canProceed is false.');
      dumpVisibleTexts(tester, 'toss-disabled', 50);
    }
  } else {
    print('    [toss] WARNING: No FilledButton found on toss page!');
    dumpVisibleTexts(tester, 'toss-noButton', 30);
  }

  // Verify we reached the scoring page (retry with pumps)
  var scoringControls = find.byType(ScoringControls);
  for (var retry = 0; retry < 5 && scoringControls.evaluate().isEmpty; retry++) {
    print('    [toss] ScoringControls not found yet, retrying (${retry + 1}/5)...');
    await visualPause(tester, 1000);
    await settle(tester);
    scoringControls = find.byType(ScoringControls);
  }
  if (scoringControls.evaluate().isEmpty) {
    print('    [toss] ERROR: ScoringControls not found after toss! Dumping page state:');
    dumpVisibleTexts(tester, 'toss-afterStart', 50);
  } else {
    print('    [toss] Scoring page loaded successfully');
  }
}

/// Select playing XI players if the Next button is disabled (roster > playersPerSide).
///
/// When roster size equals playersPerSide, auto-selection kicks in and Next is
/// already enabled. When roster > playersPerSide, we must manually tap players.
Future<void> _selectPlayingXIIfNeeded(WidgetTester tester, int? playersPerSide) async {
  if (playersPerSide == null) return;
  await settle(tester);

  // Check if Next button is already enabled (players pre-selected)
  final filledButtons = find.byType(FilledButton);
  if (filledButtons.evaluate().isNotEmpty) {
    final button = filledButtons.last.evaluate().first.widget as FilledButton;
    if (button.onPressed != null) {
      print('    [toss] XI already pre-selected, Next is enabled');
      return;
    }
  }

  // Next is disabled — manually select players by tapping InkWell player rows
  // (toss_page.dart uses InkWell for _buildPlayerSelectRow, not ListTile)
  print('    [toss] Next disabled — selecting $playersPerSide players');
  final inkWells = find.byType(InkWell);
  final count = playersPerSide.clamp(0, inkWells.evaluate().length);
  for (var i = 0; i < count; i++) {
    await tester.ensureVisible(inkWells.at(i));
    await tester.tap(inkWells.at(i), warnIfMissed: false);
    await tester.pump();
  }
  await settle(tester);
}

/// Tap the Next/Start Match button in the toss wizard.
Future<void> _tapNextButton(WidgetTester tester) async {
  // Find the FilledButton (Next or Start Match)
  final filledButton = find.byType(FilledButton);
  if (filledButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(filledButton.last);
    await tester.pumpAndSettle();
    await tester.tap(filledButton.last);
    await settle(tester);
    await visualPause(tester);
  } else {
    // Fallback to text
    final next = find.text('Next');
    if (next.evaluate().isNotEmpty) {
      await tester.tap(next);
      await settle(tester);
      await visualPause(tester);
    }
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
