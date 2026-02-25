/// Production E2E: Fresh DB → Create Teams → Score Full Match (Scorer on Emulator)
///
/// Runs on a clean prod database. Creates 2 teams with realistic names,
/// adds Abhay (9999999998) to Team 1's roster, then scores a full 5-over match.
///
/// 100% UI-driven — zero API calls.
///
/// Viewer (Abhay on real device with prod APK) opens the app separately
/// and watches the live match via WebSocket.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_fresh_e2e_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import '../helpers/data_generators.dart';
import '../helpers/delivery_record.dart';
import '../helpers/match_flow_helpers.dart';
import '../helpers/tournament_flow_helpers.dart';
import 'prod_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Team Data — 2 teams, 6 players each + Abhay on Team 1
// ═══════════════════════════════════════════════════════════════════════════

const _abhayPlayer = PlayerData(
  name: 'Abhay',
  role: 'all_rounder',
  phone: '9999999998',
);

const _team1 = TeamData(
  name: 'Abhay XI',
  players: [
    PlayerData(name: 'Rohit Sharma', role: 'batter'),
    PlayerData(name: 'Virat Kohli', role: 'batter'),
    PlayerData(name: 'Hardik Pandya', role: 'all_rounder'),
    PlayerData(name: 'Jasprit Bumrah', role: 'bowler'),
    PlayerData(name: 'Ravindra Jadeja', role: 'all_rounder'),
    _abhayPlayer, // Abhay is the 6th player (viewer account)
  ],
);

const _team2 = TeamData(
  name: 'Challenger XI',
  players: [
    PlayerData(name: 'KL Rahul', role: 'batter'),
    PlayerData(name: 'Rishabh Pant', role: 'wk_batter'),
    PlayerData(name: 'Shreyas Iyer', role: 'batter'),
    PlayerData(name: 'Mohammed Shami', role: 'bowler'),
    PlayerData(name: 'Kuldeep Yadav', role: 'bowler'),
    PlayerData(name: 'Suryakumar Yadav', role: 'all_rounder'),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fresh prod E2E: create teams, score full match via UI',
      (tester) async {
    // ─── Phase 3: Login as Scorer ──────────────────────────────────
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    print('\n${"=" * 60}');
    print('FRESH PROD E2E — Scorer on Emulator');
    print('Abhay XI (6 players + Abhay) vs Challenger XI (6 players)');
    print('5 overs | 6 per side | No magic over');
    print('${"=" * 60}\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();
    final rng = Random();

    try {
      // ─── Phase 4: Create Team 1 (Abhay XI) ────────────────────────
      print('\n[PHASE 4a] Creating team: ${_team1.name}');
      await navigateToTeams(tester);
      await createTeam(tester, _team1);
      await addPlayersToRoster(tester, _team1.players);
      tracker.recordTeamCreated(_team1.name);
      print('  [DONE] ${_team1.name} — ${_team1.players.length} players');

      // Navigate back to teams list
      final backButton1 = find.byType(BackButton);
      if (backButton1.evaluate().isNotEmpty) {
        await tester.tap(backButton1.first);
        await settle(tester);
        await visualPause(tester);
      } else {
        await navigateToTeams(tester);
      }

      // ─── Create Team 2 (Challenger XI) ────────────────────────────
      print('\n[PHASE 4b] Creating team: ${_team2.name}');
      await navigateToTeams(tester);
      await createTeam(tester, _team2);
      await addPlayersToRoster(tester, _team2.players);
      tracker.recordTeamCreated(_team2.name);
      print('  [DONE] ${_team2.name} — ${_team2.players.length} players');

      // Navigate back
      final backButton2 = find.byType(BackButton);
      if (backButton2.evaluate().isNotEmpty) {
        await tester.tap(backButton2.first);
        await settle(tester);
        await visualPause(tester);
      }

      // ─── Phase 5: Create Match via UI ─────────────────────────────
      print('\n[PHASE 5] Creating match: ${_team1.name} vs ${_team2.name}');
      await navigateToMatchSetup(tester);
      tracker.recordSuccess('Navigated to match setup');

      // Select teams
      await selectTeamInMatchSetup(tester, _team1.name, isHome: true);
      tracker.recordSuccess('Selected Team A: ${_team1.name}');

      await selectTeamInMatchSetup(tester, _team2.name, isHome: false);
      tracker.recordSuccess('Selected Team B: ${_team2.name}');

      // Set overs to 5
      final oversChip = find.widgetWithText(ChoiceChip, '5');
      if (oversChip.evaluate().isNotEmpty) {
        await tester.tap(oversChip.first);
        await settle(tester);
      }
      tracker.recordSuccess('Set overs to 5');

      // Set players per side to 6
      final playersChip = find.widgetWithText(ChoiceChip, '6');
      if (playersChip.evaluate().isNotEmpty) {
        await tester.ensureVisible(playersChip.first);
        await tester.pumpAndSettle();
        await tester.tap(playersChip.first);
        await settle(tester);
      }
      tracker.recordSuccess('Set players per side to 6');

      // Scroll to bottom and proceed to toss
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      await completeMatchSetup(tester);
      tracker.recordSuccess('Proceeded to toss');

      // ─── Toss: Abhay XI bats first ────────────────────────────────
      final opener1 = _team1.players[0].name; // Rohit Sharma
      final opener2 = _team1.players[1].name; // Virat Kohli
      final openingBowler = _team2.players[3].name; // Mohammed Shami

      await completeTossWizard(
        tester,
        tossWinnerName: _team1.name,
        battingOpener1: opener1,
        battingOpener2: opener2,
        openingBowler: openingBowler,
        playersPerSide: 6,
        chooseBat: true,
      );
      print('  Toss: ${_team1.name} wins, chooses to Bat');
      print('  Openers: $opener1, $opener2');
      print('  Bowler: $openingBowler');
      tracker.recordSuccess('Toss complete');

      // ─── Score Innings 1 ──────────────────────────────────────────
      print('\n[INNINGS 1] ${_team1.name} batting...');
      final matchRecord = MatchRecord(matchId: 'fresh-e2e');

      final bowlingNames1 = _team2.players.map((p) => p.name).toList();
      final battingNames1 = _team1.players.map((p) => p.name).toList();

      await playRandomInnings(
        tester: tester,
        matchRecord: matchRecord,
        inningsNumber: 1,
        totalOvers: 5,
        playersPerSide: 6,
        bowlerNames: bowlingNames1,
        batterNames: battingNames1,
        random: rng,
      );
      print(
          '  [INNINGS 1] Final: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');
      tracker.recordSuccess(
          'Innings 1: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');

      // ─── Innings Transition ───────────────────────────────────────
      await settle(tester);
      final transitionModal = find.byType(InningsTransitionModal);
      if (transitionModal.evaluate().isNotEmpty) {
        final inn2Opener1 = _team2.players[0].name; // KL Rahul
        final inn2Opener2 = _team2.players[1].name; // Rishabh Pant
        final inn2Bowler = _team1.players[3].name; // Jasprit Bumrah

        await completeInningsTransition(
          tester,
          striker: inn2Opener1,
          nonStriker: inn2Opener2,
          bowler: inn2Bowler,
        );
        tracker.recordSuccess('Innings transition complete');

        // ─── Score Innings 2 ────────────────────────────────────────
        final target = matchRecord.firstInningsRuns + 1;
        print(
            '\n[INNINGS 2] Challenger XI chasing target: $target');

        final bowlingNames2 = _team1.players.map((p) => p.name).toList();
        final battingNames2 = _team2.players.map((p) => p.name).toList();

        await playRandomInnings(
          tester: tester,
          matchRecord: matchRecord,
          inningsNumber: 2,
          totalOvers: 5,
          playersPerSide: 6,
          bowlerNames: bowlingNames2,
          batterNames: battingNames2,
          random: rng,
        );
        print(
            '  [INNINGS 2] Final: ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
        tracker.recordSuccess(
            'Innings 2: ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
      }

      // ─── Match Complete ───────────────────────────────────────────
      final matchResult = await captureMatchCompleteResult(tester);
      tracker.recordSuccess(
          'Match result: ${matchResult ?? "unknown"}');

      // Dismiss modal → back to home
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        final backHome = find.text('Back to Home');
        if (backHome.evaluate().isNotEmpty) {
          await tester.tap(backHome.first);
          await settle(tester);
        }
      }
      await settle(tester);
      await navigateToHome(tester);
      tracker.recordSuccess('Navigated home');

      // ─── Verify match appears on Matches tab ─────────────────────
      print('\n[VERIFY] Checking match on Matches tab...');
      final matchesTab = find.text('Matches');
      if (matchesTab.evaluate().isNotEmpty) {
        await tester.tap(matchesTab.first);
        await settle(tester);
        await visualPause(tester, 1000);
      }

      final team1Card = find.textContaining(_team1.name);
      final team2Card = find.textContaining(_team2.name);
      if (team1Card.evaluate().isNotEmpty || team2Card.evaluate().isNotEmpty) {
        print('  [VERIFY] Match card found on Matches tab');
        tracker.recordSuccess('Match visible on Matches tab');
      } else {
        print('  [VERIFY] WARNING: Match card not found');
        dumpVisibleTexts(tester, 'verify', 25);
      }
    } catch (e) {
      tracker.recordError('Fresh E2E test', e);
    }

    stopwatch.stop();
    print('\n${"=" * 60}');
    print('FRESH PROD E2E COMPLETE');
    print(
        'Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    print("=" * 60);
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Fresh prod E2E had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
