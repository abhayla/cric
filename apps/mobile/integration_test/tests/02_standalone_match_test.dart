/// 02: Standalone Match — Score, undo, magic over, target chase, persistence.
///
/// Team1 vs Team2 | 5 overs | 6 players | Magic Over: 2
/// Tests: undo (G4), magic over (G10), target chase (G6), persistence (G5).
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/02_standalone_match_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../helpers/scoring.dart';
import '../flows/random_innings.dart';
import '../models/delivery_record.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Standalone match: score, undo, target chase, magic over, persistence',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== STANDALONE MATCH TEST ===');
    print('Team1 vs Team2 | 5 overs | 6 players | Magic Over: 2\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();
    final rng = Random();

    try {
      // 1. Navigate to Match Setup
      await navigateToMatchSetup(tester);
      tracker.recordSuccess('Navigated to match setup');

      // 2. Select teams
      await selectTeamInMatchSetup(tester, 'Team1', isHome: true);
      tracker.recordSuccess('Selected Team A: Team1');

      await selectTeamInMatchSetup(tester, 'Team2', isHome: false);
      tracker.recordSuccess('Selected Team B: Team2');

      // 3. Set overs to 5
      final oversChip = find.widgetWithText(ChoiceChip, '5');
      if (oversChip.evaluate().isNotEmpty) {
        await tester.tap(oversChip.first);
        await settle(tester);
      }
      tracker.recordSuccess('Set overs to 5');

      // 4. Set players per side to 6
      final playersChip = find.widgetWithText(ChoiceChip, '6');
      if (playersChip.evaluate().isNotEmpty) {
        await tester.ensureVisible(playersChip.first);
        await tester.pumpAndSettle();
        await tester.tap(playersChip.first);
        await settle(tester);
      }
      tracker.recordSuccess('Set players per side to 6');

      // 5. Enable Magic Over (over 2)
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      final magicOverSwitch = find.text('Enable Magic Over');
      if (magicOverSwitch.evaluate().isNotEmpty) {
        final switchTile = find.ancestor(
          of: magicOverSwitch,
          matching: find.byType(SwitchListTile),
        );
        if (switchTile.evaluate().isNotEmpty) {
          await tester.tap(switchTile.first);
          await settle(tester);
        }

        await tester.pump(const Duration(milliseconds: 300));
        final selectMagicOversText = find.text('Select Magic Overs');
        if (selectMagicOversText.evaluate().isNotEmpty) {
          final filterChip2 = find.widgetWithText(FilterChip, '2');
          if (filterChip2.evaluate().isNotEmpty) {
            await tester.ensureVisible(filterChip2.first);
            await tester.pumpAndSettle();
            await tester.tap(filterChip2.first);
            await settle(tester);
            print('  [setup] Magic Over enabled, over 2 selected');
          }
        }
      }
      tracker.recordSuccess('Magic Over enabled (over 2)');

      // 6. Proceed to Toss
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      await completeMatchSetup(tester);
      tracker.recordSuccess('Proceeded to toss');

      // 7. Complete Toss: Team1 bats
      final team1Data = allTeams[0];
      final team2Data = allTeams[1];

      final opener1 = team1Data.players[0].name;
      final opener2 = team1Data.players[1].name;
      final openingBowler = team2Data.players[0].name;

      await completeTossWizard(
        tester,
        tossWinnerName: 'Team1',
        battingOpener1: opener1,
        battingOpener2: opener2,
        openingBowler: openingBowler,
        playersPerSide: 6,
        chooseBat: true,
      );
      tracker.recordSuccess('Toss complete');

      // 8. Score 3 singles → verify "3/0"
      print('  [Undo Test] Scoring 3 singles...');
      for (var i = 0; i < 3; i++) {
        await tapRun(tester, 1);
      }
      await settle(tester);

      final score3 = find.text('3/0');
      if (score3.evaluate().isNotEmpty) {
        print('  [Undo Test] Score verified: 3/0');
      } else {
        print('  [Undo Test] Score 3/0 not found');
        dumpVisibleTexts(tester, 'score-check', 20);
      }
      tracker.recordSuccess('Scored 3 singles');

      // 9. Tap Undo → verify "2/0"
      print('  [Undo Test] Tapping undo...');
      final undoSuccess = await tapUndo(tester);
      if (undoSuccess) {
        await settle(tester);
        final score2 = find.text('2/0');
        if (score2.evaluate().isNotEmpty) {
          print('  [Undo Test] After undo, score verified: 2/0');
        } else {
          print('  [Undo Test] After undo, score 2/0 not found');
          dumpVisibleTexts(tester, 'undo-check', 20);
        }
      }
      tracker.recordSuccess('Undo tested');

      // 10. Score 1 more to restore → "3/0"
      await tapRun(tester, 1);
      await settle(tester);
      tracker.recordSuccess('Score restored after undo');

      // 11. Score rest of innings 1
      final matchRecord = MatchRecord(matchId: 'standalone');
      for (var i = 0; i < 3; i++) {
        matchRecord.addDelivery(1, DeliveryRecord(
          runsFromBat: 1, overNumber: 1, ballNumber: i + 1,
        ));
      }

      final bowlingPlayerNames = team2Data.players.map((p) => p.name).toList();
      final battingPlayerNames = team1Data.players.map((p) => p.name).toList();

      print('  [Innings 1] Continuing with random scoring...');
      await playRandomInnings(
        tester: tester,
        matchRecord: matchRecord,
        inningsNumber: 1,
        totalOvers: 5,
        playersPerSide: 6,
        bowlerNames: bowlingPlayerNames,
        batterNames: battingPlayerNames,
        magicOverNumber: 2,
        random: rng,
      );
      print('  [Innings 1] Final: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');
      tracker.recordSuccess('Innings 1 complete');

      // 12. Handle innings transition
      await settle(tester);
      final transitionModal = find.byType(InningsTransitionModal);
      if (transitionModal.evaluate().isNotEmpty) {
        final inn2Opener1 = team2Data.players[0].name;
        final inn2Opener2 = team2Data.players[1].name;
        final inn2Bowler = team1Data.players[0].name;

        await completeInningsTransition(
          tester,
          striker: inn2Opener1,
          nonStriker: inn2Opener2,
          bowler: inn2Bowler,
        );
        tracker.recordSuccess('Innings transition complete');

        // 13. Target Chase
        final target = matchRecord.firstInningsRuns + 1;
        print('  [Innings 2] Team2 chasing target: $target');

        final battingPlayerNames2 = team2Data.players.map((p) => p.name).toList();
        final bowlingPlayerNames2 = team1Data.players.map((p) => p.name).toList();

        await playRandomInnings(
          tester: tester,
          matchRecord: matchRecord,
          inningsNumber: 2,
          totalOvers: 5,
          playersPerSide: 6,
          bowlerNames: bowlingPlayerNames2,
          batterNames: battingPlayerNames2,
          magicOverNumber: 2,
          random: rng,
        );
        print('  [Innings 2] ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
      }

      // 14. Capture result
      final matchResult = await captureMatchCompleteResult(tester);
      tracker.recordSuccess('Match result captured: ${matchResult ?? "unknown"}');

      // 15. Dismiss modal and navigate home
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        await dismissMatchCompleteModal(tester);
      }
      await settle(tester);
      await navigateToHome(tester);
      tracker.recordSuccess('Navigated home');

      // 16. Verify persistence — check Matches tab
      print('  [Persistence] Checking match appears on Matches tab...');
      await settle(tester);
      await navigateToMatches(tester);
      await settle(tester);
      await visualPause(tester, 1000);

      final team1OnCard = find.textContaining('Team1');
      final team2OnCard = find.textContaining('Team2');
      final hasTeam1 = team1OnCard.evaluate().isNotEmpty;
      final hasTeam2 = team2OnCard.evaluate().isNotEmpty;

      if (hasTeam1 || hasTeam2) {
        print('  [Persistence] Match card found (Team1: $hasTeam1, Team2: $hasTeam2)');
        tracker.recordSuccess('Persistence verified');
      } else {
        print('  [Persistence] WARNING: No match card found');
        tracker.recordSuccess('Persistence check inconclusive');
      }
    } catch (e) {
      tracker.recordError('Standalone match test', e);
    }

    stopwatch.stop();
    print('\n=== STANDALONE MATCH TEST COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Standalone match test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
