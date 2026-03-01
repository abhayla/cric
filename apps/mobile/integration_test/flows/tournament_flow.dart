/// Tournament flow — setup tournament + score all fixtures.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cricscores/src/features/tournaments/providers.dart';

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
/// the list of match outcomes. After each match, navigates back to
/// the tournament detail page via GoRouter before scanning for the next.
Future<List<MatchOutcome>> scoreAllFixtures({
  required WidgetTester tester,
  required List<TestTeam> teams,
  required int totalOvers,
  required int playersPerSide,
  required ErrorTracker tracker,
  required String tournamentName,
  Random? random,
}) async {
  final rng = random ?? Random();
  final outcomes = <MatchOutcome>[];
  var matchCount = 0;
  var consecutiveEmptyScans = 0;
  const maxEmptyScans = 6;

  // Extract tournament ID from current GoRouter location while on tournament detail.
  // URL pattern: /tournaments/:tournamentId
  final tournamentId = _extractTournamentId(tester);
  if (tournamentId != null) {
    print('[SCORING] Extracted tournament ID: $tournamentId');
  } else {
    print('[SCORING] WARNING: Could not extract tournament ID from route');
  }

  // Track scored fixture IDs so we skip stale fixture data (provider may cache).
  final scoredFixtureIds = <String>{};

  while (!tracker.hasError && consecutiveEmptyScans < maxEmptyScans) {
    // Ensure we're on the tournament detail page before scanning
    await _ensureOnTournamentDetail(tester, tournamentId);

    // Invalidate the fixtures provider to force a fresh API call.
    // Without this, the Riverpod FutureProvider.family caches stale data.
    if (tournamentId != null) {
      _invalidateFixturesProvider(tester, tournamentId);
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
    }

    final unplayed = await findFirstUnplayedFixture(
      tester,
      scoredFixtureIds: scoredFixtureIds,
    );

    if (unplayed == null) {
      consecutiveEmptyScans++;
      if (consecutiveEmptyScans < maxEmptyScans) {
        print('[SCORING] No unplayed fixtures found (scan $consecutiveEmptyScans/$maxEmptyScans). '
            'Refreshing via provider invalidation + tab switch...');

        // Invalidate both fixtures and tournament detail providers to force
        // fresh data from the server (knockout fixtures may have been generated
        // after all group matches completed).
        if (tournamentId != null) {
          _invalidateFixturesProvider(tester, tournamentId);
          try {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(Scaffold).first),
            );
            container.invalidate(tournamentDetailProvider(tournamentId));
            print('  [PROVIDER] Also invalidated tournamentDetailProvider');
          } catch (_) {}
        }

        // Tab switch to force UI rebuild
        await switchToTab(tester, 0);
        await tester.pump(const Duration(seconds: 2));
        await switchToTab(tester, 1);
        await settle(tester);
        // Wait longer for server to process and return knockout fixtures
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);
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
      scoredFixtureIds.add(unplayed.fixtureId);
      tracker.recordMatchCompleted(
          '$homeTeam vs $awayTeam${outcome.resultText != null ? " — ${outcome.resultText}" : ""}');
      print('  [COMPLETE] Match $matchCount done');
    } catch (e) {
      tracker.recordError('Match $matchCount: $homeTeam vs $awayTeam', e);
      return outcomes;
    }
  }

  // Guard: verify no unplayed fixtures remain
  if (!tracker.hasError) {
    await _ensureOnTournamentDetail(tester, tournamentId);
    if (tournamentId != null) {
      _invalidateFixturesProvider(tester, tournamentId);
      await settle(tester);
      await tester.pump(const Duration(seconds: 2));
    }
    final remaining = await findFirstUnplayedFixture(tester);
    expect(remaining, isNull,
        reason: 'All fixtures should be scored — found unplayed: '
            '${remaining?.homeTeamName ?? "?"} vs ${remaining?.awayTeamName ?? "?"}');
  }

  print('\n[SCORING] All fixtures complete. Total matches played: ${tracker.matchesCompleted}');
  return outcomes;
}

/// Extract tournament UUID from current GoRouter location.
String? _extractTournamentId(WidgetTester tester) {
  try {
    final routerState = GoRouterState.of(
      tester.element(find.byType(Scaffold).first),
    );
    final uri = routerState.uri.toString();
    final match = RegExp(
      r'/tournaments/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
      caseSensitive: false,
    ).firstMatch(uri);
    return match?.group(1);
  } catch (_) {
    return null;
  }
}

/// Invalidate the Riverpod fixtures provider to force a fresh API refetch.
void _invalidateFixturesProvider(WidgetTester tester, String tournamentId) {
  try {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.invalidate(tournamentFixturesProvider(tournamentId));
    print('  [PROVIDER] Invalidated tournamentFixturesProvider($tournamentId)');
  } catch (e) {
    print('  [PROVIDER] Could not invalidate fixtures provider: $e');
  }
}

/// Ensure the tester is on the tournament detail page.
///
/// Checks for DefaultTabController (tournament detail has one). If not found,
/// navigates directly via GoRouter using the tournament ID.
Future<void> _ensureOnTournamentDetail(
  WidgetTester tester,
  String? tournamentId,
) async {
  await settle(tester);

  // Check if we're already on tournament detail (TabBar + DefaultTabController)
  final tabBar = find.byType(TabBar);
  if (tabBar.evaluate().isNotEmpty) {
    try {
      final ctx = tester.element(tabBar.first);
      DefaultTabController.of(ctx);
      return; // Already on tournament detail
    } catch (_) {
      // Wrong page
    }
  }

  if (tournamentId == null) {
    print('  [NAV-RECOVERY] No tournament ID — cannot navigate back');
    return;
  }

  print('  [NAV-RECOVERY] Navigating to /tournaments/$tournamentId');
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).go('/tournaments/$tournamentId');
    await settle(tester);
    // Wait for tournament detail to load
    await visualPause(tester, 2000);
    await settle(tester);
    print('  [NAV-RECOVERY] GoRouter.go() to tournament detail complete');
  } catch (e) {
    print('  [NAV-RECOVERY] GoRouter navigation failed: $e');
  }
}
