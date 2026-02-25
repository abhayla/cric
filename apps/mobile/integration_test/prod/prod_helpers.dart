/// Shared utilities for production E2E tests.
///
/// **100% UI-driven — zero API calls.** All actions (team creation, player
/// addition, tournament creation, status transitions, team registration,
/// fixture generation, scoring) go through the app UI.
///
/// Error tracking: stops on first error, logs where it stopped for resume.
library;

import 'dart:math';

import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import '../helpers/data_generators.dart';
import '../helpers/delivery_record.dart';
import '../helpers/match_flow_helpers.dart';
import '../helpers/tournament_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants — 16 Teams, 96 Players
// ═══════════════════════════════════════════════════════════════════════════

/// Viewer account — added to Team 1's roster so he can view matches.
const _viewerPlayer = PlayerData(
  name: 'Abhay Kumar',
  role: 'all_rounder',
  phone: '9999999998',
);

/// All 16 team definitions with 6 players each (+1 viewer on Team 1).
/// Team 1-16, players T1Play1-T16Play6, phones 9999999101-9999999196.
/// Team 1 also has Abhay Kumar (9999999998) as a 7th roster member (viewer).
final List<TeamData> prodTeams = List.generate(16, (i) {
  final teamNum = i + 1;
  final players = List.generate(6, (j) {
    final playerNum = j + 1;
    final phoneNum = i * 6 + j + 101; // 101..196
    return PlayerData(
      name: 'T${teamNum}Play$playerNum',
      role: 'all_rounder',
      phone: '9999999$phoneNum',
    );
  });
  // Add viewer to Team 1's roster
  if (i == 0) players.add(_viewerPlayer);
  return TeamData(name: 'Team $teamNum', players: players);
});

/// Team names in order for easy index lookup.
final List<String> prodTeamNames = prodTeams.map((t) => t.name).toList();

// ═══════════════════════════════════════════════════════════════════════════
// Random Tournament Name Generator
// ═══════════════════════════════════════════════════════════════════════════

/// Generate a random tournament name with timestamp suffix.
String randomTournamentName() {
  const adjectives = [
    'Champions', 'Premier', 'Super', 'Masters', 'Royal',
    'Elite', 'Thunder', 'Victory', 'Blazing', 'Golden',
  ];
  const nouns = [
    'Trophy', 'League', 'Cup', 'Shield', 'Challenge',
    'Series', 'Open', 'Classic', 'Premier', 'Championship',
  ];
  final rng = Random();
  final adj = adjectives[rng.nextInt(adjectives.length)];
  final noun = nouns[rng.nextInt(nouns.length)];
  final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
  return '$adj $noun $suffix';
}

// ═══════════════════════════════════════════════════════════════════════════
// Error Tracking
// ═══════════════════════════════════════════════════════════════════════════

/// Tracks errors during test execution.
/// On first error, logs where it stopped so the test can be resumed.
class ErrorTracker {
  final List<String> errors = [];
  String? lastSuccessfulStep;
  int matchesCompleted = 0;
  int teamsCreated = 0;

  void recordSuccess(String step) {
    lastSuccessfulStep = step;
  }

  void recordTeamCreated(String teamName) {
    teamsCreated++;
    lastSuccessfulStep = 'Team created: $teamName ($teamsCreated/${prodTeams.length})';
  }

  void recordMatchCompleted(String description) {
    matchesCompleted++;
    lastSuccessfulStep = 'Match $matchesCompleted: $description';
  }

  void recordError(String step, Object error) {
    final msg = '[ERROR at $step] $error';
    errors.add(msg);
    print('\n${'=' * 60}');
    print('TEST STOPPED — ERROR DETECTED');
    print('Step: $step');
    print('Error: $error');
    print('Last successful step: $lastSuccessfulStep');
    print('Teams created: $teamsCreated');
    print('Matches completed: $matchesCompleted');
    print('${'=' * 60}\n');
  }

  bool get hasError => errors.isNotEmpty;

  void printSummary() {
    print('\n=== ERROR TRACKER SUMMARY ===');
    print('Teams created: $teamsCreated');
    print('Matches completed: $matchesCompleted');
    print('Last successful step: $lastSuccessfulStep');
    if (errors.isNotEmpty) {
      print('Errors (${errors.length}):');
      for (final e in errors) {
        print('  $e');
      }
    } else {
      print('No errors.');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Match Result Capture & Verification Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Capture the match result text from the MatchCompleteModal.
///
/// Waits for the modal to appear, then reads the `resultDescription` text
/// displayed in `headlineSmall` bold style. Returns the result string
/// (e.g. "Team 1 won by 5 runs") or null if not found.
Future<String?> captureMatchCompleteResult(WidgetTester tester) async {
  // Wait for MatchCompleteModal to appear
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
  }

  if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
    print('    [captureResult] No MatchCompleteModal found');
    return null;
  }

  // Scan descendant Text widgets for the result description
  final modalTexts = find.descendant(
    of: find.byType(MatchCompleteModal),
    matching: find.byType(Text),
  );

  String? result;
  for (final element in modalTexts.evaluate()) {
    final textWidget = element.widget as Text;
    final text = textWidget.data ?? textWidget.textSpan?.toPlainText();
    if (text != null &&
        (text.contains('won by') ||
            text.contains('Tied') ||
            text.contains('No Result') ||
            text.contains('Draw'))) {
      result = text;
      break;
    }
  }

  if (result != null) {
    print('    [captureResult] Match result: $result');
  } else {
    print('    [captureResult] Could not find result text in modal');
  }
  return result;
}

/// Verify tournament standings are populated on the Overview tab.
///
/// Switches to Overview tab (index 0), looks for 'Standings' heading
/// and 'View Full' link as evidence that standings data is present.
Future<void> verifyTournamentStandings(WidgetTester tester) async {
  // Switch to Overview tab (index 0)
  final tabBarFinder = find.byType(TabBar);
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(0); // Overview tab
    await tester.pumpAndSettle();
    await visualPause(tester);
  }

  // Look for standings section
  final standingsHeading = find.text('Standings');
  final viewFull = find.text('View Full');

  final hasStandings = standingsHeading.evaluate().isNotEmpty;
  final hasViewFull = viewFull.evaluate().isNotEmpty;

  if (hasStandings && hasViewFull) {
    print('  [standings] Verified: Standings section present with "View Full" link');
  } else if (hasStandings) {
    print('  [standings] Standings heading found but no "View Full" link');
  } else {
    print('  [standings] WARNING: Standings section not found on Overview tab');
  }
}

/// Tap the undo button on the scoring page.
///
/// Returns true if undo was successfully tapped, false if button was
/// not found or was disabled.
Future<bool> tapUndo(WidgetTester tester) async {
  final undoButton = find.byIcon(Icons.undo);
  if (undoButton.evaluate().isEmpty) {
    print('    [undo] Undo button not found');
    return false;
  }

  // Check if the button is enabled (IconButton.onPressed != null)
  final iconButtonFinder = find.ancestor(
    of: undoButton,
    matching: find.byType(IconButton),
  );
  if (iconButtonFinder.evaluate().isNotEmpty) {
    final iconButton = tester.widget<IconButton>(iconButtonFinder.first);
    if (iconButton.onPressed == null) {
      print('    [undo] Undo button is disabled');
      return false;
    }
  }

  await tester.tap(undoButton.first);
  await settle(tester);
  await visualPause(tester);
  print('    [undo] Undo tapped successfully');
  return true;
}

/// Select a team in the match setup page team picker.
///
/// Taps the team selector placeholder (e.g. 'Select Team A'), waits for the
/// bottom sheet with team list, then taps the team name.
Future<void> selectTeamInMatchSetup(
  WidgetTester tester,
  String teamName, {
  required bool isHome,
}) async {
  final placeholder = isHome ? 'Select Team A' : 'Select Team B';

  // Tap the team selector placeholder
  final selectorText = find.text(placeholder);
  if (selectorText.evaluate().isNotEmpty) {
    await tester.tap(selectorText.first);
  } else {
    // Team may already be selected — tap the team name to re-open picker
    final currentTeam = find.text(teamName);
    if (currentTeam.evaluate().isEmpty) {
      print('    [teamPicker] Neither placeholder "$placeholder" nor team name found');
      return;
    }
    // Already selected — nothing to do
    return;
  }
  await settle(tester);
  await visualPause(tester, 500);

  // Wait for bottom sheet to appear with team list
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final teamInList = find.text(teamName);
    if (teamInList.evaluate().length > 1) break; // Multiple = in list + header
    if (teamInList.evaluate().isNotEmpty) break;
  }
  await settle(tester);

  // Find and tap the team name in the bottom sheet ListTile
  final teamInSheet = find.text(teamName);
  if (teamInSheet.evaluate().isNotEmpty) {
    await tester.tap(teamInSheet.last); // Last = the one in the list (not header)
    await settle(tester);
    await visualPause(tester);
    print('    [teamPicker] Selected ${isHome ? "Team A" : "Team B"}: $teamName');
  } else {
    print('    [teamPicker] WARNING: "$teamName" not found in team picker');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Team Setup — 100% UI
// ═══════════════════════════════════════════════════════════════════════════

/// Create all 16 teams with 6 players each through the app UI.
/// Team 1 gets 7 players (6 + Abhay Kumar as viewer).
///
/// Uses the same flow a normal user would:
/// 1. Navigate to Teams tab
/// 2. Create Team (fill name → submit)
/// 3. Add players (Create New → fill name/phone/role → Add to Team)
/// 4. Navigate back to Teams list
/// 5. Repeat for next team
///
/// On error: stops immediately, logs progress for resume.
Future<void> createAllTeamsViaUI(
  WidgetTester tester,
  ErrorTracker tracker, {
  int startFromTeam = 0,
}) async {
  for (var i = startFromTeam; i < prodTeams.length; i++) {
    if (tracker.hasError) return;

    final team = prodTeams[i];
    print('\n[TEAM ${i + 1}/${prodTeams.length}] ${team.name}');

    try {
      // Create new team via UI
      await navigateToTeams(tester);
      await createTeam(tester, team);

      // Add players to roster
      await addPlayersToRoster(tester, team.players);

      // Navigate back for next team
      await _navigateBackToTeamsList(tester);

      tracker.recordTeamCreated(team.name);
      print('  [DONE] ${team.name} — ${team.players.length} players added');
    } catch (e) {
      tracker.recordError('Creating team ${team.name} (${i + 1}/${prodTeams.length})', e);
      return;
    }
  }
}

/// Navigate back from team detail to the teams list.
Future<void> _navigateBackToTeamsList(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }
  await navigateToTeams(tester);
}

// ═══════════════════════════════════════════════════════════════════════════
// Tournament Setup — 100% UI
// ═══════════════════════════════════════════════════════════════════════════

/// Group assignments for 4 groups x 4 teams (T1, T2).
const Map<String, List<int>> fourGroupAssignments = {
  'A': [0, 1, 2, 3],     // Team 1-4
  'B': [4, 5, 6, 7],     // Team 5-8
  'C': [8, 9, 10, 11],   // Team 9-12
  'D': [12, 13, 14, 15], // Team 13-16
};

/// Group assignments for 2 groups x 8 teams (T5).
const Map<String, List<int>> twoGroupAssignments = {
  'A': [0, 1, 2, 3, 4, 5, 6, 7],
  'B': [8, 9, 10, 11, 12, 13, 14, 15],
};

/// Set up a tournament entirely through the app UI.
///
/// Flow:
/// 1. Navigate to Tournaments tab → Create Tournament form
/// 2. Fill all form fields (name, format, overs, ball type, players/side, groups)
/// 3. Submit → lands on tournament detail page (draft status)
/// 4. Open Registration (popup menu)
/// 5. Add teams via bottom sheet (with group assignments if applicable)
/// 6. Generate Fixtures (Overview tab)
/// 7. Start Tournament (popup menu)
///
/// After this, the tester is on the tournament detail page in "live" status.
Future<void> setupTournamentViaUI({
  required WidgetTester tester,
  required String name,
  required String format,
  required int oversPerMatch,
  required ErrorTracker tracker,
  int ballTypeId = 2,
  int playersPerSide = 6,
  int numGroups = 1,
  int qualifyPerGroup = 2,
  Map<String, List<int>>? groupAssignments,
  List<int>? teamIndices,
}) async {
  if (tracker.hasError) return;

  print('\n[TOURNAMENT SETUP VIA UI] $name ($format, ${oversPerMatch}ov)');

  try {
    // 1. Create tournament via UI
    await createTournament(
      tester,
      TournamentConfig(
        name: name,
        format: format,
        overs: oversPerMatch,
        playersPerSide: playersPerSide,
        numGroups: numGroups,
        qualifyPerGroup: qualifyPerGroup,
        ballTypeId: ballTypeId,
      ),
    );
    print('  [UI] Tournament created');
    tracker.recordSuccess('Tournament "$name" created');

    // 2. Transition: draft → registration
    await transitionTournamentStatus(tester, 'Open Registration');
    print('  [UI] Status: draft → registration');

    // 3. Add teams via bottom sheet
    if (groupAssignments != null) {
      for (final entry in groupAssignments.entries) {
        final groupName = entry.key;
        for (final teamIdx in entry.value) {
          final teamName = prodTeamNames[teamIdx];
          await addTeamToTournament(tester, teamName, groupName: groupName);
        }
      }
    } else if (teamIndices != null) {
      for (final teamIdx in teamIndices) {
        final teamName = prodTeamNames[teamIdx];
        await addTeamToTournament(tester, teamName);
      }
    } else {
      // Add all 16 teams (no groups)
      for (final teamName in prodTeamNames) {
        await addTeamToTournament(tester, teamName);
      }
    }
    print('  [UI] All teams added');
    tracker.recordSuccess('Tournament "$name" teams added');

    // 4. Generate fixtures
    await generateFixtures(tester);
    print('  [UI] Fixtures generated');

    // 5. Transition: registration → live
    await transitionTournamentStatus(tester, 'Start Tournament');
    print('  [UI] Status: registration → live');

    tracker.recordSuccess('Tournament "$name" is now live');
    print('  [TOURNAMENT SETUP VIA UI COMPLETE] $name is now live');
  } catch (e) {
    tracker.recordError('Tournament setup "$name"', e);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fixture Scoring — 100% UI (no API calls)
// ═══════════════════════════════════════════════════════════════════════════

/// Score all fixtures in a tournament by navigating the Fixtures tab in the UI.
///
/// Repeatedly scans FixtureCard widgets on the Fixtures tab for unplayed
/// matches (fixture.matchId == null with both teams assigned). Taps each one,
/// scores it, returns to the tournament detail page, and repeats until no
/// more unplayed fixtures remain.
///
/// On error: stops immediately, logs match number and teams for resume.
Future<void> scoreAllFixturesViaUI({
  required WidgetTester tester,
  required int totalOvers,
  required ErrorTracker tracker,
  int playersPerSide = 6,
  Random? random,
  int startFromMatch = 0,
}) async {
  final rng = random ?? Random();
  var matchCount = 0;
  var consecutiveEmptyScans = 0;
  const maxEmptyScans = 5; // Stop after 5 scans with no unplayed fixtures (increased for knockout bracket propagation)

  while (!tracker.hasError && consecutiveEmptyScans < maxEmptyScans) {
    // Navigate to Fixtures tab and find the first unplayed fixture
    final unplayed = await _findFirstUnplayedFixture(tester);

    if (unplayed == null) {
      consecutiveEmptyScans++;
      if (consecutiveEmptyScans < maxEmptyScans) {
        print('[SCORING] No unplayed fixtures found (scan $consecutiveEmptyScans/$maxEmptyScans). '
            'Refreshing via tab switch...');
        // Switch to Overview tab then back to Fixtures to force data reload
        // (helps with knockout bracket propagation delays)
        final tabBarFinder = find.byType(TabBar);
        if (tabBarFinder.evaluate().isNotEmpty) {
          final tabBarContext = tester.element(tabBarFinder.first);
          DefaultTabController.of(tabBarContext).animateTo(0); // Overview tab
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
          DefaultTabController.of(tabBarContext).animateTo(1); // Fixtures tab
          await tester.pumpAndSettle();
        }
        await settle(tester);
        await tester.pump(const Duration(seconds: 3));
      }
      continue;
    }

    consecutiveEmptyScans = 0;
    matchCount++;

    // Skip matches below resume point
    if (matchCount <= startFromMatch) {
      print('[MATCH $matchCount] SKIP (resuming from match ${startFromMatch + 1})');
      continue;
    }

    final homeTeam = unplayed.homeTeamName;
    final awayTeam = unplayed.awayTeamName;
    print('\n[MATCH $matchCount] $homeTeam vs $awayTeam');

    try {
      final matchResult = await _playFixtureViaUI(
        tester: tester,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        random: rng,
      );

      final resultSuffix = matchResult != null ? ' — $matchResult' : '';
      tracker.recordMatchCompleted('$homeTeam vs $awayTeam$resultSuffix');
      print('  [COMPLETE] Match $matchCount done');
    } catch (e) {
      tracker.recordError(
        'Match $matchCount: $homeTeam vs $awayTeam',
        e,
      );
      return;
    }
  }

  print('\n[SCORING] All fixtures complete. Total matches played: ${tracker.matchesCompleted}');
}

/// Find the first unplayed fixture on the Fixtures tab.
/// Returns a record with homeTeamName and awayTeamName, or null if none found.
Future<_FixtureInfo?> _findFirstUnplayedFixture(WidgetTester tester) async {
  // Switch to Fixtures tab
  final tabBarFinder = find.byType(TabBar);
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(1); // Fixtures tab
    await tester.pumpAndSettle();
    await visualPause(tester);
  }

  // Scan FixtureCard widgets, scrolling through the list
  for (var scroll = 0; scroll < 20; scroll++) {
    final allCards = find.byType(FixtureCard).evaluate().toList();

    for (final cardElement in allCards) {
      final fixtureCard = cardElement.widget as FixtureCard;
      final fixture = fixtureCard.fixture;

      // Unplayed = no matchId, both teams assigned (not TBD/null)
      if (!fixture.hasMatch &&
          fixture.homeTeamName != null &&
          fixture.awayTeamName != null) {
        return _FixtureInfo(
          homeTeamName: fixture.homeTeamName!,
          awayTeamName: fixture.awayTeamName!,
        );
      }
    }

    // Scroll down to find more
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.last, const Offset(0, -300));
      await tester.pumpAndSettle();
    } else {
      break;
    }
  }

  return null;
}

/// Simple data class for fixture info extracted from UI.
class _FixtureInfo {
  _FixtureInfo({required this.homeTeamName, required this.awayTeamName});
  final String homeTeamName;
  final String awayTeamName;
}

/// Play a single fixture through the UI.
/// Returns the match result description if captured, or null.
Future<String?> _playFixtureViaUI({
  required WidgetTester tester,
  required String homeTeam,
  required String awayTeam,
  required int totalOvers,
  required int playersPerSide,
  required Random random,
}) async {
  // 1. Navigate to fixture and tap it
  await tapFixtureCard(tester, homeTeamName: homeTeam, awayTeamName: awayTeam);
  await settle(tester);

  // 2. Complete match setup (teams pre-selected from fixture)
  await completeMatchSetup(tester);

  // 3. Random toss: pick winner and decision
  final tossWinner = random.nextBool() ? homeTeam : awayTeam;
  final chooseBat = random.nextBool();
  final battingTeam = chooseBat ? tossWinner : (tossWinner == homeTeam ? awayTeam : homeTeam);
  final bowlingTeam = battingTeam == homeTeam ? awayTeam : homeTeam;

  // Get player names for batting and bowling teams
  final battingTeamData = prodTeams.firstWhere((t) => t.name == battingTeam);
  final bowlingTeamData = prodTeams.firstWhere((t) => t.name == bowlingTeam);

  final opener1 = battingTeamData.players[0].name;
  final opener2 = battingTeamData.players[1].name;
  final openingBowler = bowlingTeamData.players[0].name;

  print('  Toss: $tossWinner wins, chooses to ${chooseBat ? "Bat" : "Field"}');
  print('  Batting: $battingTeam ($opener1, $opener2)');
  print('  Bowling: $bowlingTeam ($openingBowler)');

  // 4. Complete toss wizard
  await completeTossWizard(
    tester,
    tossWinnerName: tossWinner,
    battingOpener1: opener1,
    battingOpener2: opener2,
    openingBowler: openingBowler,
    playersPerSide: playersPerSide,
    chooseBat: chooseBat,
  );

  // 5. Score first innings
  final matchRecord = MatchRecord(matchId: 'fixture');
  final bowlingPlayerNames = bowlingTeamData.players.map((p) => p.name).toList();
  final battingPlayerNames = battingTeamData.players.map((p) => p.name).toList();

  print('  [Innings 1] $battingTeam batting...');
  await playRandomInnings(
    tester: tester,
    matchRecord: matchRecord,
    inningsNumber: 1,
    totalOvers: totalOvers,
    playersPerSide: playersPerSide,
    bowlerNames: bowlingPlayerNames,
    batterNames: battingPlayerNames,
    random: random,
  );
  print('  [Innings 1] ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');

  // 6. Handle innings transition
  await settle(tester);
  final transitionModal = find.byType(InningsTransitionModal);
  if (transitionModal.evaluate().isNotEmpty) {
    final inn2Opener1 = bowlingTeamData.players[0].name;
    final inn2Opener2 = bowlingTeamData.players[1].name;
    final inn2Bowler = battingTeamData.players[0].name;

    await completeInningsTransition(
      tester,
      striker: inn2Opener1,
      nonStriker: inn2Opener2,
      bowler: inn2Bowler,
    );

    // 7. Score second innings
    final battingPlayerNames2 = bowlingTeamData.players.map((p) => p.name).toList();
    final bowlingPlayerNames2 = battingTeamData.players.map((p) => p.name).toList();

    print('  [Innings 2] $bowlingTeam batting (target: ${matchRecord.firstInningsRuns + 1})...');
    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 2,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingPlayerNames2,
      batterNames: battingPlayerNames2,
      random: random,
    );
    print('  [Innings 2] ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
  }

  // 8. Capture match result before dismissing modal (G2)
  await settle(tester);
  final matchResult = await captureMatchCompleteResult(tester);

  // 9. Dismiss match complete modal
  await _dismissMatchCompleteModal(tester);

  // 10. Navigate back to tournament detail page via browser back
  //     The match was opened from tournament detail, so popping should return there.
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
    await visualPause(tester, 1000);
    print('  [NAV] Returned to tournament detail via back button');
  } else {
    // Fallback: navigate home then back to tournaments
    await navigateToHome(tester);
    await settle(tester);
    await navigateToTournaments(tester);
    await settle(tester);
    print('  [NAV] Returned via home → tournaments fallback');
  }

  final resultSuffix = matchResult != null ? ' — $matchResult' : '';
  print('  Result: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets} '
      'vs ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}$resultSuffix');
  return matchResult;
}

/// Dismiss the match complete modal.
Future<void> _dismissMatchCompleteModal(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
  }

  if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
    print('    [matchComplete] No MatchCompleteModal found');
    return;
  }

  // Try "Back to Home" first
  final backHome = find.text('Back to Home');
  if (backHome.evaluate().isNotEmpty) {
    await tester.tap(backHome.first);
    await settle(tester);
    return;
  }

  // Try "Done" button
  final done = find.text('Done');
  if (done.evaluate().isNotEmpty) {
    await tester.tap(done.first);
    await settle(tester);
    return;
  }

  // Fallback: tap any FilledButton
  final buttons = find.byType(FilledButton);
  if (buttons.evaluate().isNotEmpty) {
    await tester.tap(buttons.first);
    await settle(tester);
  }
}
