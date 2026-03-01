/// 10: Special Match Flows — Abandonment, Declaration, Super Over.
///
/// Three sequential matches using Team5 vs Team6, 5 overs, 6 players.
/// Tests match abandonment (D), innings declaration (E), and super over (F).
///
/// ## Test Ordering Dependencies
///
/// Requires test 01 to have created teams (Team5, Team6 with 6 players each).
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/10_special_match_flows_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/super_over_setup_wizard.dart';

import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../helpers/scoring.dart';
import '../flows/random_innings.dart';

void main() {
  initIntegrationTest();

  testWidgets('Special match flows: abandon, declare, super over',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== SPECIAL MATCH FLOWS TEST ===');
    print('Team5 vs Team6 | 5 overs | 6 players\n');

    final stopwatch = Stopwatch()..start();

    final team5 = allTeams[4]; // Team5
    final team6 = allTeams[5]; // Team6
    final team5Players = team5.players.map((p) => p.name).toList();
    final team6Players = team6.players.map((p) => p.name).toList();

    // ────────────────────────────────────────────────────────────────────
    // Match 1: Abandonment
    // ────────────────────────────────────────────────────────────────────
    print('\n--- MATCH 1: ABANDONMENT ---');

    // Navigate to match setup
    await navigateToMatchSetup(tester);

    // Select teams
    await selectTeamInMatchSetup(tester, 'Team5', isHome: true);
    await selectTeamInMatchSetup(tester, 'Team6', isHome: false);

    // Set overs to 5 (smallest available preset: [5, 10, 15, 20, 25, 50])
    final oversChip5 = find.widgetWithText(ChoiceChip, '5');
    if (oversChip5.evaluate().isNotEmpty) {
      await tester.tap(oversChip5.first);
      await settle(tester);
    }

    // Set players per side to 6
    final playersChip6 = find.widgetWithText(ChoiceChip, '6');
    if (playersChip6.evaluate().isNotEmpty) {
      await tester.ensureVisible(playersChip6.first);
      await settle(tester);
      await tester.tap(playersChip6.first);
      await settle(tester);
    }

    // Proceed to toss and start match
    await completeMatchSetup(tester);
    await completeTossWizard(
      tester,
      tossWinnerName: 'Team5',
      battingOpener1: team5Players[0],
      battingOpener2: team5Players[1],
      openingBowler: team6Players[0],
      playersPerSide: 6,
      chooseBat: true,
    );
    print('  [Match 1] Scoring page loaded, scoring a few deliveries...');

    // Score 4 deliveries (less than 1 over)
    await tapRun(tester, 1);
    await tapRun(tester, 4);
    await tapRun(tester, 0);
    await tapRun(tester, 2);
    print('  [Match 1] Scored 4 deliveries (1+4+0+2 = 7 runs)');

    // Abandon the match via PopupMenuButton
    final moreButton = find.byIcon(Icons.more_vert);
    expect(moreButton, findsAtLeast(1),
        reason: 'PopupMenuButton (more_vert) should be visible');
    await tester.tap(moreButton.first);
    await settle(tester);
    await visualPause(tester, 500);

    final abandonMenuItem = find.text('Abandon Match');
    expect(abandonMenuItem, findsOneWidget,
        reason: 'Abandon Match menu item should appear');
    await tester.tap(abandonMenuItem);
    await settle(tester);
    await visualPause(tester, 500);

    // Confirm abandon dialog
    final abandonButton = find.text('Abandon');
    expect(abandonButton, findsOneWidget,
        reason: 'Abandon confirmation button should appear');
    await tester.tap(abandonButton);
    await settle(tester);
    await visualPause(tester, 1000);
    await settle(tester);

    // Verify match complete modal shows abandoned result
    final abandonResult = await captureMatchCompleteResult(tester);
    expect(abandonResult, contains('Abandoned'),
        reason: 'Abandoned match should show "Abandoned" in result');
    print('  [Match 1] Result: $abandonResult');

    // Dismiss and navigate home
    await dismissMatchCompleteModal(tester);
    await settle(tester);
    await visualPause(tester, 500);

    // Navigate to home to verify abandoned match appears
    await ensureOnMyCricketPage(tester);
    await settle(tester);
    print('  [Match 1] ABANDONMENT TEST PASSED\n');

    // ────────────────────────────────────────────────────────────────────
    // Match 2: Declaration
    // ────────────────────────────────────────────────────────────────────
    print('--- MATCH 2: DECLARATION ---');

    // Navigate to match setup
    await navigateToMatchSetup(tester);

    // Select teams
    await selectTeamInMatchSetup(tester, 'Team5', isHome: true);
    await selectTeamInMatchSetup(tester, 'Team6', isHome: false);

    // Set overs to 5 (smallest available preset: [5, 10, 15, 20, 25, 50])
    final oversChip5b = find.widgetWithText(ChoiceChip, '5');
    if (oversChip5b.evaluate().isNotEmpty) {
      await tester.tap(oversChip5b.first);
      await settle(tester);
    }

    // Set players per side to 6
    final playersChip6b = find.widgetWithText(ChoiceChip, '6');
    if (playersChip6b.evaluate().isNotEmpty) {
      await tester.ensureVisible(playersChip6b.first);
      await settle(tester);
      await tester.tap(playersChip6b.first);
      await settle(tester);
    }

    // Proceed to toss and start match — Team5 bats first
    await completeMatchSetup(tester);
    await completeTossWizard(
      tester,
      tossWinnerName: 'Team5',
      battingOpener1: team5Players[0],
      battingOpener2: team5Players[1],
      openingBowler: team6Players[0],
      playersPerSide: 6,
      chooseBat: true,
    );
    print('  [Match 2] Scoring page loaded, scoring 1st innings...');

    // Score 1 full over + partial 2nd over deterministically
    // Over 1: 1,2,4,1,0,6 = 14 runs (6 balls)
    // Partial over 2: 2,1 = 3 runs (2 balls)
    // Total: 17 runs from 8 balls
    final inn1Runs = [1, 2, 4, 1, 0, 6, 2, 1];
    final ballsScored = await scoreDeterministicInnings(
      tester: tester,
      runsPerBall: inn1Runs,
      bowlerNames: team6Players,
      batterNames: team5Players,
    );
    print('  [Match 2] 1st innings: scored $ballsScored balls');

    // Check if innings ended early (shouldn't for 5-over match with 8 balls)
    if (find.byType(InningsTransitionModal).evaluate().isEmpty &&
        find.byType(MatchCompleteModal).evaluate().isEmpty) {
      // Declare innings via PopupMenuButton
      final moreButton2 = find.byIcon(Icons.more_vert);
      expect(moreButton2, findsAtLeast(1),
          reason: 'PopupMenuButton should be visible for declaration');
      await tester.tap(moreButton2.first);
      await settle(tester);
      await visualPause(tester, 500);

      final declareMenuItem = find.text('Declare Innings');
      expect(declareMenuItem, findsOneWidget,
          reason: 'Declare Innings menu item should appear in 1st innings');
      await tester.tap(declareMenuItem);
      await settle(tester);
      await visualPause(tester, 500);

      // Confirm declare dialog
      final declareButton = find.text('Declare');
      expect(declareButton, findsOneWidget,
          reason: 'Declare confirmation button should appear');
      await tester.tap(declareButton);
      await settle(tester);
      await visualPause(tester, 1000);
      await settle(tester);

      print('  [Match 2] 1st innings declared');
    }

    // Wait for innings transition modal
    await waitForFinder(
      tester,
      find.byType(InningsTransitionModal),
      timeoutMs: 15000,
      intervalMs: 500,
    );

    expect(find.byType(InningsTransitionModal), findsOneWidget,
        reason: 'InningsTransitionModal should appear after declaration');
    print('  [Match 2] InningsTransitionModal appeared');

    // Complete innings transition — Team6 bats, Team5 bowls
    await completeInningsTransition(
      tester,
      striker: team6Players[0],
      nonStriker: team6Players[1],
      bowler: team5Players[0],
    );

    // Score 2nd innings to completion (all dots = 0 runs, overs exhausted)
    // 5 overs × 6 balls = 30 balls of dots
    final inn2Runs = List.filled(30, 0);
    await scoreDeterministicInnings(
      tester: tester,
      runsPerBall: inn2Runs,
      bowlerNames: team5Players,
      batterNames: team6Players,
    );
    print('  [Match 2] 2nd innings scored (all dots)');

    // Capture result
    final declareResult = await captureMatchCompleteResult(tester);
    expect(declareResult, isNotNull,
        reason: 'Match should complete after 2nd innings');
    print('  [Match 2] Result: $declareResult');

    // Dismiss and navigate home
    await dismissMatchCompleteModal(tester);
    await settle(tester);
    await ensureOnMyCricketPage(tester);
    await settle(tester);
    print('  [Match 2] DECLARATION TEST PASSED\n');

    // ────────────────────────────────────────────────────────────────────
    // Match 3: Super Over (tied knockout match)
    // ────────────────────────────────────────────────────────────────────
    print('--- MATCH 3: SUPER OVER ---');

    // Navigate to match setup
    await navigateToMatchSetup(tester);

    // Select teams
    await selectTeamInMatchSetup(tester, 'Team5', isHome: true);
    await selectTeamInMatchSetup(tester, 'Team6', isHome: false);

    // Set overs to 5 (smallest available preset: [5, 10, 15, 20, 25, 50])
    final oversChip5c = find.widgetWithText(ChoiceChip, '5');
    if (oversChip5c.evaluate().isNotEmpty) {
      await tester.tap(oversChip5c.first);
      await settle(tester);
    }

    // Set players per side to 6
    final playersChip6c = find.widgetWithText(ChoiceChip, '6');
    if (playersChip6c.evaluate().isNotEmpty) {
      await tester.ensureVisible(playersChip6c.first);
      await settle(tester);
      await tester.tap(playersChip6c.first);
      await settle(tester);
    }

    // Open Advanced Settings (collapsed by default) to reveal Knockout toggle
    final advancedSettings = find.text('Advanced Settings');
    await tester.ensureVisible(advancedSettings.first);
    await settle(tester);
    await tester.tap(advancedSettings.first);
    await settle(tester);
    print('  [Match 3] Advanced Settings expanded');

    // Enable Knockout Match toggle (now visible after expanding)
    final knockoutToggle = find.text('Knockout Match');
    expect(knockoutToggle, findsOneWidget,
        reason: 'Knockout Match toggle should exist in Advanced Settings');
    await tester.ensureVisible(knockoutToggle.first);
    await settle(tester);
    // Find the SwitchListTile ancestor and tap it
    final switchTile = find.ancestor(
      of: knockoutToggle,
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(switchTile.first, warnIfMissed: false);
    await settle(tester);
    print('  [Match 3] Knockout Match toggle enabled');

    // Proceed to toss — Team5 bats first
    await completeMatchSetup(tester);
    await completeTossWizard(
      tester,
      tossWinnerName: 'Team5',
      battingOpener1: team5Players[0],
      battingOpener2: team5Players[1],
      openingBowler: team6Players[0],
      playersPerSide: 6,
      chooseBat: true,
    );
    print('  [Match 3] Scoring page loaded, scoring for a tie...');

    // Score 1st innings: all dots (30 balls × 0 runs = 0/0)
    final tieInn1 = List.filled(30, 0);
    await scoreDeterministicInnings(
      tester: tester,
      runsPerBall: tieInn1,
      bowlerNames: team6Players,
      batterNames: team5Players,
    );
    print('  [Match 3] 1st innings: 0/0 (all dots, 5 overs)');

    // Wait for innings transition
    await waitForFinder(
      tester,
      find.byType(InningsTransitionModal),
      timeoutMs: 15000,
      intervalMs: 500,
    );

    expect(find.byType(InningsTransitionModal), findsOneWidget,
        reason: 'InningsTransitionModal should appear after 1st innings');

    // Complete innings transition — Team6 bats, Team5 bowls
    await completeInningsTransition(
      tester,
      striker: team6Players[0],
      nonStriker: team6Players[1],
      bowler: team5Players[0],
    );

    // Score 2nd innings: all dots (30 balls × 0 runs = 0/0) → TIE
    final tieInn2 = List.filled(30, 0);
    await scoreDeterministicInnings(
      tester: tester,
      runsPerBall: tieInn2,
      bowlerNames: team5Players,
      batterNames: team6Players,
    );
    print('  [Match 3] 2nd innings: 0/0 (all dots, 5 overs) → TIE');

    // In a knockout match, a tie triggers needsSuperOver directly
    // (no MatchCompleteModal). The SuperOverSetupWizard appears automatically.
    await settle(tester, pumpCount: 20);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, pumpCount: 20);

    // Wait for SuperOverSetupWizard to appear
    final wizardFound = await waitForFinder(
      tester,
      find.byType(SuperOverSetupWizard),
      timeoutMs: 15000,
      intervalMs: 500,
    );
    expect(wizardFound, isTrue,
        reason: 'SuperOverSetupWizard should appear after tied knockout match');
    print('  [Match 3] SuperOverSetupWizard appeared');

    // Complete the wizard — select batters and bowler for SO innings 1
    // The wizard shows _state.bowlingTeamPlayers as batters (Team5 bowled 2nd)
    // and _state.battingTeamPlayers as bowlers (Team6 batted 2nd)
    await completeSuperOverWizard(
      tester,
      batter1: team5Players[0], // Team5 bats first in SO
      batter2: team5Players[1],
      bowler: team6Players[2], // Team6 bowls in SO innings 1
    );

    // Score super over innings 1: 1,1,0,0,0,0 = 2 runs
    print('  [Match 3] Super Over Innings 1: Team5 batting...');
    final soInn1 = [1, 1, 0, 0, 0, 0];
    await scoreDeterministicInnings(
      tester: tester,
      runsPerBall: soInn1,
      bowlerNames: team6Players,
      batterNames: team5Players,
    );
    print('  [Match 3] Super Over Innings 1: 2 runs');

    // After SO innings 1, InningsTransitionModal appears (inningsNumber == 1)
    await settle(tester, pumpCount: 20);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester, pumpCount: 20);

    await waitForFinder(
      tester,
      find.byType(InningsTransitionModal),
      timeoutMs: 15000,
      intervalMs: 500,
    );

    if (find.byType(InningsTransitionModal).evaluate().isNotEmpty) {
      // SO innings 2: Team6 bats, Team5 bowls
      await completeInningsTransition(
        tester,
        striker: team6Players[0],
        nonStriker: team6Players[1],
        bowler: team5Players[2],
      );
    }

    // Score super over innings 2: 4 = wins immediately (target 3, boundary chase)
    print('  [Match 3] Super Over Innings 2: Team6 batting (target: 3)...');
    await tapRun(tester, 4);
    print('  [Match 3] Super Over Innings 2: 4 runs — Team6 wins!');

    // Capture final result
    await settle(tester, pumpCount: 20);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, pumpCount: 20);

    final superOverResult = await captureMatchCompleteResult(tester);
    expect(superOverResult, isNotNull,
        reason: 'Match should have a result after super over');
    print('  [Match 3] Result: $superOverResult');

    // Dismiss and navigate home
    await dismissMatchCompleteModal(tester);
    await settle(tester);
    await ensureOnMyCricketPage(tester);
    await settle(tester);
    print('  [Match 3] SUPER OVER TEST PASSED\n');

    stopwatch.stop();
    print('=== SPECIAL MATCH FLOWS COMPLETE ===');
    print(
        'Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
