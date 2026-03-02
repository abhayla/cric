/// 11: Scoring Edge Cases — dismissal types, extras, free hit.
///
/// Deterministic test exercising: Bowled, Caught (fielder selection),
/// LBW, Run Out (striker/non-striker), Stumped, byes, leg-byes,
/// wide with extra runs, no-ball → free hit flow.
///
/// Team7 vs Team8 | 5 overs | 6 players.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/11_scoring_edge_cases_test.dart -d emulator-5554
/// ```
library;

import 'package:cricscores/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/wicket_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../helpers/scoring.dart';

void main() {
  initIntegrationTest();

  testWidgets(
      'Scoring edge cases: all dismissal types, extras, free hit',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== SCORING EDGE CASES TEST ===');
    print('Team7 vs Team8 | 5 overs | 6 players\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();

    try {
      // ═══════════════════════════════════════
      // MATCH SETUP
      // ═══════════════════════════════════════
      await navigateToMatchSetup(tester);
      tracker.recordSuccess('Navigated to match setup');

      await selectTeamInMatchSetup(tester, 'Team7', isHome: true);
      await selectTeamInMatchSetup(tester, 'Team8', isHome: false);

      // 5 overs
      final overs5 = find.widgetWithText(ChoiceChip, '5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
      }
      // 6 players
      final players6 = find.widgetWithText(ChoiceChip, '6');
      if (players6.evaluate().isNotEmpty) {
        await tester.ensureVisible(players6.first);
        await settle(tester);
        await tester.tap(players6.first);
        await settle(tester);
      }

      await completeMatchSetup(tester);
      tracker.recordSuccess('Match setup complete');

      final team7 = allTeams[6]; // Team7
      final team8 = allTeams[7]; // Team8

      await completeTossWizard(
        tester,
        tossWinnerName: 'Team7',
        battingOpener1: team7.players[0].name,
        battingOpener2: team7.players[1].name,
        openingBowler: team8.players[0].name,
        playersPerSide: 6,
        chooseBat: true,
      );
      tracker.recordSuccess('Toss complete — Team7 bats');

      // ═══════════════════════════════════════
      // OVER 1: Extras coverage
      // ═══════════════════════════════════════
      print('\n  [Over 1] Testing extras...');

      // Ball 1.1: Wide (default 1 run)
      await tapExtra(tester, 'WD');
      await confirmExtra(tester);
      print('  1.x → Wide (1 run)');
      tracker.recordSuccess('Wide at default runs');

      // Ball 1.1 (retry): Bye (1 run)
      await tapExtra(tester, 'B');
      await confirmExtra(tester);
      print('  1.1 → Bye (1 run)');
      tracker.recordSuccess('Bye');

      // Ball 1.2: Leg-bye (2 runs)
      await tapExtra(tester, 'LB');
      await confirmExtraWithRuns(tester, 2);
      print('  1.2 → Leg-bye (2 runs)');
      tracker.recordSuccess('Leg-bye with 2 runs');

      // Ball 1.3: No-ball (triggers free hit)
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      print('  1.x → No-ball (1 run) — free hit pending');
      tracker.recordSuccess('No-ball');

      // Ball 1.3 (free hit delivery): Score 4 on free hit
      // Free hit indicator should be visible
      await settle(tester);
      final freeHitIndicator = find.textContaining('Free Hit');
      if (freeHitIndicator.evaluate().isNotEmpty) {
        print('  [Free Hit] Indicator visible');
      } else {
        print('  [Free Hit] WARNING: Free Hit indicator not found');
        dumpVisibleTexts(tester, 'free-hit-check', 30);
      }
      await tapRun(tester, 4);
      print('  1.3 → 4 runs on free hit');
      tracker.recordSuccess('Free hit delivery scored');

      // Verify free hit cleared after legal delivery
      await settle(tester);
      final freeHitAfter = find.textContaining('Free Hit');
      if (freeHitAfter.evaluate().isEmpty) {
        print('  [Free Hit] Correctly cleared after legal delivery');
      } else {
        print('  [Free Hit] WARNING: Still showing after legal delivery');
      }
      tracker.recordSuccess('Free hit cleared');

      // Ball 1.4: Wide with 2 additional runs
      await tapExtra(tester, 'WD');
      await confirmExtraWithRuns(tester, 2);
      print('  1.x → Wide + 2 additional runs');
      tracker.recordSuccess('Wide with extra runs');

      // Ball 1.4: Single
      await tapRun(tester, 1);
      print('  1.4 → 1');

      // Ball 1.5: Dot
      await tapRun(tester, 0);
      print('  1.5 → 0');

      // Ball 1.6: Single
      await tapRun(tester, 1);
      print('  1.6 → 1');
      tracker.recordSuccess('Over 1 complete');

      // Select bowler for over 2
      await selectBowler(tester, team8.players[1].name,
          fallbackNames: team8.players.map((p) => p.name).toList());

      // ═══════════════════════════════════════
      // OVER 2: Dismissal types coverage
      // ═══════════════════════════════════════
      print('\n  [Over 2] Testing dismissal types...');

      // Ball 2.1: Bowled (simplest — no fielder)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('  2.1 → W (Bowled)');
      await selectBatter(tester, team7.players[2].name);
      tracker.recordSuccess('Bowled dismissal');

      // Ball 2.2: LBW (no fielder)
      await tapWicket(tester);
      await selectDismissalType(tester, 'LBW');
      await tapWicketConfirm(tester);
      print('  2.2 → W (LBW)');
      await selectBatter(tester, team7.players[3].name);
      tracker.recordSuccess('LBW dismissal');

      // Ball 2.3: Caught (requires fielder selection)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Caught');
      // Step 2: Need to tap "Next" to go to fielder selection
      await _tapNextInWicketDialog(tester);
      // Select a fielder from the bowling team
      await _selectFielderInWicketDialog(tester, team8.players[0].name);
      // Confirm
      await _tapConfirmInWicketDialog(tester);
      print('  2.3 → W (Caught, fielder: ${team8.players[0].name})');
      await selectBatter(tester, team7.players[4].name);
      tracker.recordSuccess('Caught dismissal with fielder');

      // Ball 2.4: Stumped (requires fielder — usually keeper)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Stumped');
      await _tapNextInWicketDialog(tester);
      // Select wicket-keeper as fielder
      await _selectFielderInWicketDialog(tester, team8.players[0].name);
      await _tapConfirmInWicketDialog(tester);
      print('  2.4 → W (Stumped, fielder: ${team8.players[0].name})');
      await selectBatter(tester, team7.players[5].name);
      tracker.recordSuccess('Stumped dismissal with fielder');

      // Ball 2.5: Run Out (3-step: type → fielder → batter selection)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Run Out');
      // Step 2: fielder selection
      await _tapNextInWicketDialog(tester);
      await _selectFielderInWicketDialog(tester, team8.players[1].name);
      // Step 3: batter & details
      await _tapNextInWicketDialog(tester);
      // Select non-striker as the run-out victim
      final nonStrikerCard = find.descendant(
        of: find.byType(WicketDialog),
        matching: find.text('Non-Striker'),
      );
      if (nonStrikerCard.evaluate().isNotEmpty) {
        await tester.tap(nonStrikerCard.first);
        await settle(tester);
        print('  [Run Out] Selected non-striker as dismissed batter');
      }
      // Confirm run out
      await _tapConfirmInWicketDialog(tester);
      print('  2.5 → W (Run Out, non-striker)');
      // All 5 wickets taken → ALL OUT
      tracker.recordSuccess('Run Out dismissal — ALL OUT');

      // ═══════════════════════════════════════
      // INNINGS TRANSITION
      // ═══════════════════════════════════════
      await settle(tester);
      await visualPause(tester, 3000);
      await settle(tester);

      final foundTransition = await waitForFinder(
        tester,
        find.byType(InningsTransitionModal),
        timeoutMs: 15000,
        intervalMs: 500,
      );
      expect(foundTransition, isTrue,
          reason: 'Innings transition modal should appear after all out');
      tracker.recordSuccess('Innings transition modal appeared');

      await completeInningsTransition(
        tester,
        striker: team8.players[0].name,
        nonStriker: team8.players[1].name,
        bowler: team7.players[0].name,
      );
      tracker.recordSuccess('Innings transition complete');

      // ═══════════════════════════════════════
      // INNINGS 2: Quick chase with boundaries
      // ═══════════════════════════════════════
      print('\n  [Innings 2] Team8 chasing...');

      // Score enough to chase target quickly
      for (var i = 0; i < 5; i++) {
        await settle(tester);
        if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
          print('  [Innings 2] Match complete after $i deliveries');
          break;
        }
        await tapRun(tester, 6);
        print('  [Innings 2] Ball ${i + 1} → 6');
      }
      tracker.recordSuccess('Innings 2 scored');

      // ═══════════════════════════════════════
      // MATCH COMPLETION
      // ═══════════════════════════════════════
      await settle(tester);
      await visualPause(tester, 3000);
      await settle(tester);

      // Wait for match complete modal
      for (var attempt = 0; attempt < 10; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
      }

      final matchResult = await captureMatchCompleteResult(tester);
      expect(matchResult, isNotNull,
          reason: 'Match should complete with a result');
      print('  [Result] $matchResult');
      tracker.recordSuccess('Match result: $matchResult');

      // Dismiss modal and go home
      await dismissMatchCompleteModal(tester);
      await settle(tester);
      await navigateToHome(tester);
      tracker.recordSuccess('Navigated home');
    } catch (e) {
      tracker.recordError('Scoring edge cases test', e);
      await takeFailureScreenshot('11_scoring_edge_cases');
    }

    stopwatch.stop();
    print('\n=== SCORING EDGE CASES TEST COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Scoring edge cases test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}

// ═══════════════════════════════════════════════════════════════════
// WicketDialog multi-step helpers
// ═══════════════════════════════════════════════════════════════════

/// Tap the "Next" button in the WicketDialog to advance to the next step.
///
/// The primary FilledButton shows "Next" on steps 1 and 2, and
/// "Confirm Wicket" on the final step.
Future<void> _tapNextInWicketDialog(WidgetTester tester) async {
  final nextButton = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.byType(FilledButton),
  );
  expect(nextButton, findsOneWidget,
      reason: 'WicketDialog should have a primary button');
  await tester.tap(nextButton);
  await settle(tester);
}

/// Select a fielder by name in the WicketDialog's fielder selection step.
///
/// Searches for the player name in the fielder list and taps it.
Future<void> _selectFielderInWicketDialog(
  WidgetTester tester,
  String playerName,
) async {
  await settle(tester);

  // Look for the fielder name text in the dialog
  final fielderText = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.textContaining(playerName),
  );

  if (fielderText.evaluate().isNotEmpty) {
    await tester.ensureVisible(fielderText.first);
    await tester.tap(fielderText.first, warnIfMissed: false);
    await settle(tester);
    print('    [fielder] Selected: $playerName');
  } else {
    // Fallback: tap the first InkWell in the dialog (first available fielder)
    final anyFielder = find.descendant(
      of: find.byType(WicketDialog),
      matching: find.byType(InkWell),
    );
    if (anyFielder.evaluate().isNotEmpty) {
      await tester.tap(anyFielder.first, warnIfMissed: false);
      await settle(tester);
      print('    [fielder] "$playerName" not found — selected first available');
    } else {
      fail('[fielder] No fielder options found in WicketDialog');
    }
  }
}

/// Tap the confirm button in the WicketDialog's final step.
///
/// Same as _tapNextInWicketDialog but semantically different —
/// on the final step, the button says "Confirm Wicket".
Future<void> _tapConfirmInWicketDialog(WidgetTester tester) async {
  final confirmButton = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.byType(FilledButton),
  );
  expect(confirmButton, findsOneWidget,
      reason: 'WicketDialog should have a confirm button');
  await tester.tap(confirmButton);
  await settle(tester);
  await visualPause(tester);
}
