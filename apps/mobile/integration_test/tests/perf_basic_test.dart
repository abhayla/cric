/// Performance baseline test — measures timings across the full app flow.
///
/// Prerequisite: Teams must already exist on the server. Run
/// `01_team_setup_test.dart` first to create Team1 and Team2.
///
/// Scores a 5-over match (6 players per side) and navigates all screens.
/// Prints a formatted performance report at the end.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/perf_basic_test.dart -d emulator-5554
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
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../helpers/scoring.dart';
import '../flows/random_innings.dart';
import '../models/delivery_record.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Performance baseline: full app flow timing', (tester) async {
    final totalStopwatch = Stopwatch()..start();
    final rng = Random(42); // Deterministic for reproducible results

    // Use Team3 and Team4 (created by 01_team_setup_test with 11 players each).
    // Team1/Team2 may have incomplete rosters from prior failed runs.
    final team1 = allTeams[2]; // Team3 (11 players)
    final team2 = allTeams[3]; // Team4 (11 players)

    const totalOvers = 5;
    const playersPerSide = 6;

    // ── Phase 1: Cold Start ─────────────────────────────────────────
    final swColdStart = Stopwatch()..start();
    await pumpAppAndWaitForHome(tester);
    swColdStart.stop();
    print('  [perf] Cold Start: ${_fmt(swColdStart)}');

    // ── Phase 2: Verify Teams Exist ─────────────────────────────────
    final swTeamCheck = Stopwatch()..start();
    await navigateToTeams(tester);
    await settle(tester);

    // Tap "All" filter to see all teams
    final allChip = find.text('All');
    if (allChip.evaluate().isNotEmpty) {
      await tester.tap(allChip.first);
      await settle(tester);
      await visualPause(tester, 500);
    }

    // Verify Team1 and Team2 exist
    final team1Exists = find.text(team1.name);
    final team2Exists = find.text(team2.name);
    expect(team1Exists, findsAtLeast(1),
        reason: '${team1.name} must exist — run 01_team_setup_test first');
    expect(team2Exists, findsAtLeast(1),
        reason: '${team2.name} must exist — run 01_team_setup_test first');
    print('  [perf] Teams verified: ${team1.name}, ${team2.name}');

    swTeamCheck.stop();
    print('  [perf] Team Verification: ${_fmt(swTeamCheck)}');

    // ── Phase 3: Match Setup ────────────────────────────────────────
    final swMatchSetup = Stopwatch()..start();

    await navigateToMatchSetup(tester);

    await selectTeamInMatchSetup(tester, team1.name, isHome: true);
    await selectTeamInMatchSetup(tester, team2.name, isHome: false);

    // Set overs to 5
    final oversChip = find.widgetWithText(ChoiceChip, '5');
    if (oversChip.evaluate().isNotEmpty) {
      await tester.tap(oversChip.first);
      await settle(tester);
    }

    // Set players per side to 6
    final playersChip = find.widgetWithText(ChoiceChip, '6');
    if (playersChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(playersChip.first);
      await settle(tester);
      await tester.tap(playersChip.first);
      await settle(tester);
    }

    // Scroll down to Proceed to Toss
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -500));
      await settle(tester);
    }

    await completeMatchSetup(tester);

    swMatchSetup.stop();
    print('  [perf] Match Setup: ${_fmt(swMatchSetup)}');

    // ── Phase 4: Toss Wizard ────────────────────────────────────────
    final swToss = Stopwatch()..start();

    final opener1 = team1.players[0].name;
    final opener2 = team1.players[1].name;
    final openingBowler = team2.players[0].name;

    await completeTossWizard(
      tester,
      tossWinnerName: team1.name,
      battingOpener1: opener1,
      battingOpener2: opener2,
      openingBowler: openingBowler,
      playersPerSide: playersPerSide,
      chooseBat: true,
    );

    swToss.stop();
    print('  [perf] Toss Wizard: ${_fmt(swToss)}');

    // ── Phase 5: Score 1 Over (6 legal deliveries) ──────────────────
    final swFirstOver = Stopwatch()..start();
    final runSequence = [1, 0, 4, 2, 1, 0]; // Mix of runs
    for (final runs in runSequence) {
      await tapRun(tester, runs);
    }
    swFirstOver.stop();
    final avgPerDeliveryFirstOver =
        swFirstOver.elapsedMilliseconds / runSequence.length;
    print('  [perf] First Over (${runSequence.length} del): ${_fmt(swFirstOver)} '
        '(avg ${avgPerDeliveryFirstOver.toStringAsFixed(0)}ms/del)');

    // ── Phase 6: Undo + Redo ────────────────────────────────────────
    final swUndo = Stopwatch()..start();
    await tapUndo(tester);
    await settle(tester);
    await tapRun(tester, 0); // Re-record
    swUndo.stop();
    print('  [perf] Undo + Redo: ${_fmt(swUndo)}');

    // ── Phase 7: Over Transition (bowler selection) ─────────────────
    final swOverTransition = Stopwatch()..start();

    // The over just completed (6 balls scored above), bowler sheet should appear
    await selectBowler(tester, team2.players[1].name,
        fallbackNames: team2.players.map((p) => p.name).toList());

    swOverTransition.stop();
    print('  [perf] Over Transition: ${_fmt(swOverTransition)}');

    // ── Phase 8: Score to Innings End ───────────────────────────────
    final swInnings1 = Stopwatch()..start();

    final matchRecord = MatchRecord(matchId: 'perf');
    // Record the 6 deliveries from phase 5 (approximate — just for tracking)
    for (var i = 0; i < 6; i++) {
      matchRecord.addDelivery(1, DeliveryRecord(
        runsFromBat: runSequence[i],
        overNumber: 1,
        ballNumber: i + 1,
      ));
    }

    final bowlingNames = team2.players.map((p) => p.name).toList();
    final battingNames = team1.players.map((p) => p.name).toList();

    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 1,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingNames,
      batterNames: battingNames,
      random: rng,
    );

    swInnings1.stop();
    final inn1Deliveries = matchRecord.firstInningsDeliveries.length;
    // Subtract the 6 we manually added (phase 5)
    final inn1RemainingDel = inn1Deliveries - 6;
    print('  [perf] 1st Innings Remaining: ${_fmt(swInnings1)} '
        '($inn1RemainingDel del, '
        '${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets})');

    // ── Phase 9: Innings Transition ─────────────────────────────────
    final swInningsTransition = Stopwatch()..start();

    await waitForFinder(tester, find.byType(InningsTransitionModal),
        timeoutMs: 15000, intervalMs: 500);

    final transitionModal = find.byType(InningsTransitionModal);
    expect(transitionModal, findsOneWidget,
        reason: 'Innings transition modal should appear');

    await completeInningsTransition(
      tester,
      striker: team2.players[0].name,
      nonStriker: team2.players[1].name,
      bowler: team1.players[0].name,
    );

    swInningsTransition.stop();
    print('  [perf] Innings Transition: ${_fmt(swInningsTransition)}');

    // ── Phase 10: Score 2nd Innings ─────────────────────────────────
    final swInnings2 = Stopwatch()..start();

    final battingNames2 = team2.players.map((p) => p.name).toList();
    final bowlingNames2 = team1.players.map((p) => p.name).toList();

    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 2,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingNames2,
      batterNames: battingNames2,
      random: rng,
    );

    swInnings2.stop();
    final inn2Deliveries = matchRecord.secondInningsDeliveries.length;
    print('  [perf] 2nd Innings: ${_fmt(swInnings2)} '
        '($inn2Deliveries del, '
        '${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets})');

    // ── Phase 11: Match Complete ────────────────────────────────────
    final swMatchComplete = Stopwatch()..start();

    await settle(tester);
    await visualPause(tester, 3000);
    await settle(tester);

    // Wait for match complete modal
    if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
      for (var attempt = 0; attempt < 10; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
      }
    }

    final matchResult = await captureMatchCompleteResult(tester);
    await dismissMatchCompleteModal(tester);

    swMatchComplete.stop();
    print('  [perf] Match Complete: ${_fmt(swMatchComplete)}');

    // ── Phase 12: Navigation Sweep ──────────────────────────────────
    final swNavSweep = Stopwatch()..start();
    final navTimings = <String, int>{};

    Future<void> timeNav(String label, Future<void> Function() action) async {
      final sw = Stopwatch()..start();
      await action();
      await settle(tester);
      sw.stop();
      navTimings[label] = sw.elapsedMilliseconds;
    }

    await timeNav('Home', () => ensureOnMyCricketPage(tester));
    await timeNav('Teams', () => navigateToTeams(tester));
    await timeNav('Matches', () => navigateToMatches(tester));
    await timeNav('Live', () => navigateToLive(tester));
    await timeNav('Updates', () => navigateToUpdates(tester));
    await timeNav('Back to Home', () => ensureOnMyCricketPage(tester));

    swNavSweep.stop();
    print('  [perf] Navigation Sweep: ${_fmt(swNavSweep)}');

    // ── Performance Report ──────────────────────────────────────────
    totalStopwatch.stop();

    final inn1AvgMs = inn1Deliveries > 0
        ? (swFirstOver.elapsedMilliseconds + swInnings1.elapsedMilliseconds) /
            inn1Deliveries
        : 0;
    final inn2AvgMs =
        inn2Deliveries > 0 ? swInnings2.elapsedMilliseconds / inn2Deliveries : 0;
    final navScreens = navTimings.length;
    final navAvgMs =
        navScreens > 0 ? swNavSweep.elapsedMilliseconds / navScreens : 0;

    print('\n${"═" * 50}');
    print(' PERFORMANCE REPORT');
    print('═' * 50);
    print('Cold Start:           ${_fmtPad(swColdStart)}');
    print('Team Verification:    ${_fmtPad(swTeamCheck)}');
    print('Match Setup:          ${_fmtPad(swMatchSetup)}');
    print('Toss Wizard:          ${_fmtPad(swToss)}');
    print('First Over (6 del):   ${_fmtPad(swFirstOver)}  '
        '(avg ${avgPerDeliveryFirstOver.toStringAsFixed(0)}ms/del)');
    print('Undo + Redo:          ${_fmtPad(swUndo)}');
    print('Over Transition:      ${_fmtPad(swOverTransition)}');
    print('1st Innings Total:    ${_fmtPad(swFirstOver, swInnings1)}  '
        '($inn1Deliveries del, avg ${inn1AvgMs.toStringAsFixed(0)}ms/del)');
    print('Innings Transition:   ${_fmtPad(swInningsTransition)}');
    print('2nd Innings Total:    ${_fmtPad(swInnings2)}  '
        '($inn2Deliveries del, avg ${inn2AvgMs.toStringAsFixed(0)}ms/del)');
    print('Match Complete:       ${_fmtPad(swMatchComplete)}');
    print('Navigation Sweep:     ${_fmtPad(swNavSweep)}  '
        '($navScreens screens, avg ${navAvgMs.toStringAsFixed(0)}ms/screen)');

    // Individual nav timings
    for (final entry in navTimings.entries) {
      print('  → ${entry.key.padRight(16)} ${_msToStr(entry.value)}');
    }

    print('─' * 50);
    print('TOTAL:                ${_fmtPad(totalStopwatch)}');
    print('Match Result:         ${matchResult ?? "unknown"}');
    print('Score: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets} '
        'vs ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
    print('═' * 50);
  }, timeout: const Timeout(Duration(minutes: 30)));
}

/// Format a stopwatch as "X.Xs" (e.g. "12.3s").
String _fmt(Stopwatch sw) => '${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';

/// Format one or two stopwatches as right-padded string for the report.
String _fmtPad(Stopwatch sw1, [Stopwatch? sw2]) {
  final ms = sw1.elapsedMilliseconds + (sw2?.elapsedMilliseconds ?? 0);
  return _msToStr(ms).padRight(8);
}

/// Convert milliseconds to "X.Xs" string.
String _msToStr(int ms) => '${(ms / 1000).toStringAsFixed(1)}s';
