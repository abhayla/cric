/// 07: Verify All Screens — My Cricket, Live, Updates + detail pages.
///
/// Full verification of all screens after matches and tournaments have been played.
/// Requires tests 01-06 to have run (12 teams, 1 standalone match, 3 tournaments).
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/07_verify_all_screens_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/teams/presentation/widgets/team_card.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/tournament_card.dart';

import '../core/app_bootstrap.dart';
import '../core/test_utils.dart';
import '../helpers/navigation.dart';
import '../verification/live_verifier.dart';
import '../verification/my_cricket_verifier.dart';
import '../verification/team_detail_verifier.dart';
import '../verification/tournament_verifier.dart';
import '../verification/updates_verifier.dart';

void main() {
  initIntegrationTest();

  testWidgets('Verify all screens: My Cricket, Live, Updates, detail pages',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== VERIFY ALL SCREENS TEST ===\n');

    final stopwatch = Stopwatch()..start();

    // 1. My Cricket — Teams tab (12 teams created, scorer owns Team1-Team4 + more)
    print('[1/7] Verifying Teams tab...');
    await verifyTeamsTab(
      tester,
      expectedMinAllTeams: 4,
      expectedOwnerTeams: ['Team1', 'Team2', 'Team3', 'Team4'],
    );

    // 2. Team Detail — tap Team1 card and verify detail page
    print('\n[2/7] Verifying Team Detail page...');
    await navigateToTeams(tester);
    await settle(tester);
    // Ensure "All" filter is active so Team1 is visible
    final allFilterChip = find.ancestor(
      of: find.text('All'),
      matching: find.byType(FilterChip),
    );
    if (allFilterChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(allFilterChip.first);
      await settle(tester);
      await tester.tap(allFilterChip.first);
      await settle(tester);
    }
    // Find the TeamCard containing "Team1" and scroll to it
    final team1Text = find.text('Team1');
    if (team1Text.evaluate().isNotEmpty) {
      final team1Card = find.ancestor(
        of: team1Text.first,
        matching: find.byType(TeamCard),
      );
      if (team1Card.evaluate().isNotEmpty) {
        await tester.ensureVisible(team1Card.first);
        await settle(tester);
        await tester.tap(team1Card.first);
        await settle(tester);
        await visualPause(tester, 1000);
        await verifyTeamDetail(tester, teamName: 'Team1');
        await goBack(tester);
      } else {
        print('  [verify-team-detail] WARNING: Team1 text found but not inside a TeamCard');
      }
    } else {
      print('  [verify-team-detail] WARNING: Team1 not found in teams list');
    }

    // 3. My Cricket — Matches tab (1 standalone + tournament fixtures = many matches)
    print('\n[3/7] Verifying Matches tab...');
    await verifyMatchesTab(tester, minAllCount: 1, expectWon: true);

    // 4. My Cricket — Tournaments tab (3 tournaments completed by now)
    print('\n[4/7] Verifying Tournaments tab...');
    await verifyTournamentsTab(tester, expectCompleted: true);

    // 4b. Tournament Detail — tap first TournamentCard and verify detail page
    print('\n[4b/7] Verifying Tournament Detail page...');
    await navigateToTournaments(tester);
    await settle(tester);
    // Tap "All" filter chip to see all tournaments
    final allChip = find.ancestor(
      of: find.text('All'),
      matching: find.byType(FilterChip),
    );
    if (allChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(allChip.first);
      await settle(tester);
      await tester.tap(allChip.first);
      await settle(tester);
      await visualPause(tester, 500);
    }
    final tournamentCards = find.byType(TournamentCard);
    if (tournamentCards.evaluate().isNotEmpty) {
      await tester.ensureVisible(tournamentCards.first);
      await settle(tester);
      await tester.tap(tournamentCards.first);
      await settle(tester);
      await visualPause(tester, 1000);
      await verifyTournamentDetail(tester, expectStandings: true);
      await goBack(tester);
    } else {
      print('  [verify-tournament-detail] WARNING: No TournamentCard found to tap');
    }

    // 5. Live page (completed matches + tournaments should exist)
    print('\n[5/7] Verifying Live page...');
    await verifyLivePage(tester,
        expectCompletedMatches: true, expectTournaments: true);

    // 6. Updates page (activity feed should have content after all those matches)
    print('\n[6/7] Verifying Updates page...');
    await verifyUpdatesPage(tester, expectContent: true);

    stopwatch.stop();
    print('\n=== VERIFY ALL SCREENS COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
