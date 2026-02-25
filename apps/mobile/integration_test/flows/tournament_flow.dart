/// Tournament flow — setup tournament + score all fixtures.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_data.dart';
import '../config/tournament_presets.dart';
import '../core/error_tracker.dart';
import '../core/test_utils.dart';
import '../helpers/fixture_scanning.dart';
import '../helpers/navigation.dart';
import '../helpers/tournament_mgmt.dart';
import '../models/match_outcome.dart';
import 'standalone_match_flow.dart';

/// Set up a tournament entirely through the UI.
///
/// Creates tournament, opens registration, adds teams (with optional group
/// assignments), generates fixtures, and starts the tournament.
///
/// After this, the tester is on the tournament detail page in "live" status.
Future<void> setupTournament({
  required WidgetTester tester,
  required TournamentPreset preset,
  required String name,
  required ErrorTracker tracker,
  required List<TestTeam> teams,
  List<int>? teamIndices,
  Map<String, List<int>>? groupAssignments,
}) async {
  if (tracker.hasError) return;

  print('\n[TOURNAMENT SETUP] $name (${preset.format}, ${preset.overs}ov)');

  try {
    // Navigate to tournaments tab first
    await navigateToTournaments(tester);
    await settle(tester);

    // 1. Create tournament
    await createTournament(tester, preset, name);
    print('  [UI] Tournament created');
    tracker.recordSuccess('Tournament "$name" created');

    // 2. Open Registration
    await transitionTournamentStatus(tester, 'Open Registration');
    print('  [UI] Status: draft → registration');

    // 3. Add teams
    if (groupAssignments != null) {
      for (final entry in groupAssignments.entries) {
        final groupName = entry.key;
        for (final teamIdx in entry.value) {
          final teamName = teams[teamIdx].name;
          await addTeamToTournament(tester, teamName, groupName: groupName);
        }
      }
    } else if (teamIndices != null) {
      for (final teamIdx in teamIndices) {
        final teamName = teams[teamIdx].name;
        await addTeamToTournament(tester, teamName);
      }
    }
    print('  [UI] All teams added');
    tracker.recordSuccess('Tournament "$name" teams added');

    // 4. Generate fixtures
    await generateFixtures(tester);
    print('  [UI] Fixtures generated');

    // 5. Start Tournament
    await transitionTournamentStatus(tester, 'Start Tournament');
    print('  [UI] Status: registration → live');

    tracker.recordSuccess('Tournament "$name" is now live');
    print('  [TOURNAMENT SETUP COMPLETE] $name is now live');
  } catch (e) {
    tracker.recordError('Tournament setup "$name"', e);
  }
}

/// Score all fixtures in a tournament.
///
/// Repeatedly scans for unplayed fixtures, scores them, and returns
/// the list of match outcomes.
Future<List<MatchOutcome>> scoreAllFixtures({
  required WidgetTester tester,
  required List<TestTeam> teams,
  required int totalOvers,
  required int playersPerSide,
  required ErrorTracker tracker,
  Random? random,
}) async {
  final rng = random ?? Random();
  final outcomes = <MatchOutcome>[];
  var matchCount = 0;
  var consecutiveEmptyScans = 0;
  const maxEmptyScans = 5;

  while (!tracker.hasError && consecutiveEmptyScans < maxEmptyScans) {
    final unplayed = await findFirstUnplayedFixture(tester);

    if (unplayed == null) {
      consecutiveEmptyScans++;
      if (consecutiveEmptyScans < maxEmptyScans) {
        print('[SCORING] No unplayed fixtures found (scan $consecutiveEmptyScans/$maxEmptyScans). '
            'Refreshing via tab switch...');
        // Switch to Overview tab then back to Fixtures
        final tabBarFinder = find.byType(TabBar);
        if (tabBarFinder.evaluate().isNotEmpty) {
          final tabBarContext = tester.element(tabBarFinder.first);
          DefaultTabController.of(tabBarContext).animateTo(0);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
          DefaultTabController.of(tabBarContext).animateTo(1);
          await tester.pumpAndSettle();
        }
        await settle(tester);
        await tester.pump(const Duration(seconds: 3));
      }
      continue;
    }

    consecutiveEmptyScans = 0;
    matchCount++;

    final homeTeam = unplayed.homeTeamName;
    final awayTeam = unplayed.awayTeamName;
    print('\n[MATCH $matchCount] $homeTeam vs $awayTeam');

    try {
      // Tap the fixture card to start
      await tapFixtureCard(tester,
          homeTeamName: homeTeam, awayTeamName: awayTeam);
      await settle(tester);

      final outcome = await scoreFixtureMatch(
        tester: tester,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        allTeams: teams,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        random: rng,
      );

      outcomes.add(outcome);
      tracker.recordMatchCompleted(
          '$homeTeam vs $awayTeam${outcome.resultText != null ? " — ${outcome.resultText}" : ""}');
      print('  [COMPLETE] Match $matchCount done');
    } catch (e) {
      tracker.recordError('Match $matchCount: $homeTeam vs $awayTeam', e);
      return outcomes;
    }
  }

  print('\n[SCORING] All fixtures complete. Total matches played: ${tracker.matchesCompleted}');
  return outcomes;
}
