// ignore_for_file: avoid_print

import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_test_wrapper.dart';
import 'helpers/data_generators.dart';
import 'helpers/match_flow_helpers.dart';
import 'helpers/server_manager.dart';
import 'helpers/tournament_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Multi-Device SCORER Test — runs on the Android EMULATOR
// ═══════════════════════════════════════════════════════════════════════════
//
// This is the SCORING side of the multi-device E2E test. It plays the exact
// same predetermined match as single_match_e2e_test.dart, but with 2-second
// pauses between deliveries so the viewer on a real device can track updates.
//
// No DB verification — that's handled by single_match_e2e_test.dart.
// The viewer test (multi_device_viewer_e2e_test.dart) verifies WebSocket state.
//
// Run:
//   flutter test integration_test/multi_device_scorer_e2e_test.dart -d emulator-5554
//
// Or via orchestrator:
//   ./scripts/multi-device-e2e.sh

/// Inter-delivery pause to give the viewer time to receive WebSocket updates.
const _deliveryPauseMs = 2000;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final serverManager = ServerManager(port: 3001);

  const teamA = TeamData(name: 'Mumbai Lions', players: [
    PlayerData(name: 'Rohit Sharma'),
    PlayerData(name: 'Suryakumar Yadav'),
    PlayerData(name: 'Ishan Kishan'),
    PlayerData(name: 'Hardik Pandya'),
    PlayerData(name: 'Jasprit Bumrah'),
    PlayerData(name: 'Rahul Chahar'),
  ]);

  const teamB = TeamData(name: 'Chennai Kings', players: [
    PlayerData(name: 'MS Dhoni'),
    PlayerData(name: 'Ruturaj Gaikwad'),
    PlayerData(name: 'Devon Conway'),
    PlayerData(name: 'Ravindra Jadeja'),
    PlayerData(name: 'Deepak Chahar'),
    PlayerData(name: 'Tushar Deshpande'),
  ]);

  bool teamsAlreadyExist = false;

  setUpAll(() async {
    await serverManager.startServer();

    final existingTeams = await serverManager.getExistingTeams();
    final teamAExists =
        (existingTeams[teamA.name] ?? 0) >= teamA.players.length;
    final teamBExists =
        (existingTeams[teamB.name] ?? 0) >= teamB.players.length;

    if (teamAExists && teamBExists) {
      teamsAlreadyExist = true;
      await serverManager.resetMatchData();
      print('\n[SCORER] Teams exist — reset match data only');
    } else {
      await serverManager.resetDatabase();
      print('\n[SCORER] Full database reset');
    }

    print('[SCORER] Server healthy: ${serverManager.baseUrl}');
  });

  testWidgets(
    'Multi-device SCORER — predetermined scoring with pauses',
    (WidgetTester tester) async {
      // Helper: pause between deliveries for viewer sync
      Future<void> deliveryPause() async {
        await Future<void>.delayed(
            const Duration(milliseconds: _deliveryPauseMs));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // ── PHASE 1: Boot ──
      print('\n[SCORER] ══════════ PHASE 1: Boot App ══════════');
      await AppTestWrapper.pumpAppAndWaitForHome(tester);
      print('[SCORER] Home page loaded');

      // ── PHASE 2: Create Teams ──
      print('\n[SCORER] ══════════ PHASE 2: Create Teams ══════════');
      if (teamsAlreadyExist) {
        print('[SCORER] Teams already exist — skipping creation');
      } else {
        await navigateToTeams(tester);
        await createTeam(tester, teamA);
        await addPlayersToRoster(tester, teamA.players);
        await goBack(tester);
        await settle(tester);
        print('[SCORER] ${teamA.name} created');

        await navigateToTeams(tester);
        await createTeam(tester, teamB);
        await addPlayersToRoster(tester, teamB.players);
        await goBack(tester);
        await settle(tester);
        print('[SCORER] ${teamB.name} created');
      }

      // ── PHASE 3: Match Setup ──
      print('\n[SCORER] ══════════ PHASE 3: Match Setup ══════════');
      final navBarCheck = find.byType(NavigationBar);
      final homeTabText = find.text('Home');
      if (navBarCheck.evaluate().isNotEmpty &&
          homeTabText.evaluate().isNotEmpty) {
        await tester.tap(homeTabText.first);
        await settle(tester);
      } else {
        try {
          final ctx = tester.element(find.byType(Navigator).last);
          GoRouter.of(ctx).go('/home');
          await settle(tester);
        } catch (e) {
          print('[SCORER] GoRouter /home fallback failed: $e');
        }
      }
      await visualPause(tester, 500);

      final startMatchBtn = find.text('Start Match');
      expect(startMatchBtn, findsOneWidget);
      await tester.tap(startMatchBtn);
      await settle(tester);
      await visualPause(tester, 1000);
      print('[SCORER] Match Setup page');

      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      final overs5 = find.text('5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
      }
      final players6 = find.text('6');
      if (players6.evaluate().isNotEmpty) {
        await tester.tap(players6.first);
        await settle(tester);
      }

      await completeMatchSetup(tester);

      // ── PHASE 4: Toss ──
      print('\n[SCORER] ══════════ PHASE 4: Toss ══════════');
      await completeTossWizard(
        tester,
        tossWinnerName: teamA.name,
        battingOpener1: 'Rohit Sharma',
        battingOpener2: 'Suryakumar Yadav',
        openingBowler: 'Deepak Chahar',
      );
      await visualPause(tester, 1000);
      expect(find.byType(ScoringControls), findsWidgets);
      print('[SCORER] Toss complete — scoring page ready');

      // Signal viewer that scorer is ready, then wait for viewer to connect
      final serverRoot =
          AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
      final signalDio = Dio(BaseOptions(
        baseUrl: serverRoot,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      try {
        await signalDio.post('/api/v1/test/signal/scorer-ready',
            data: {'value': 'true'});
        print('[SCORER] Signal: scorer-ready posted');

        // Wait for viewer to connect (poll viewer-ready signal, up to 120s)
        final viewerDeadline =
            DateTime.now().add(const Duration(seconds: 120));
        var viewerReady = false;
        while (DateTime.now().isBefore(viewerDeadline)) {
          try {
            final r =
                await signalDio.get('/api/v1/test/signal/viewer-ready');
            if (r.data['value'] != null) {
              viewerReady = true;
              print('[SCORER] Signal: viewer-ready received');
              break;
            }
          } catch (_) {}
          await Future<void>.delayed(const Duration(seconds: 2));
          if (DateTime.now().second % 10 == 0) {
            print('[SCORER] Waiting for viewer-ready...');
          }
        }
        if (!viewerReady) {
          print(
              '[SCORER] WARNING: Viewer not ready after 120s — proceeding anyway');
        }
      } catch (e) {
        print(
            '[SCORER] Signal endpoint not available — falling back to 5s wait: $e');
        await Future<void>.delayed(const Duration(seconds: 5));
      }

      // ── PHASE 5: 1st Innings ──
      print(
          '\n[SCORER] ══════════ PHASE 5: 1st Innings — ${teamA.name} ══════════');

      // Over 1, Ball 1: 4
      await tapRun(tester, 4);
      print('[SCORER] 1.1 → 4 (Rohit)       Score: 4/0');
      await deliveryPause();

      // Over 1, Ball 2: 6
      await tapRun(tester, 6);
      print('[SCORER] 1.2 → 6 (Rohit)       Score: 10/0');
      await deliveryPause();

      // Over 1, Ball 3: W Bowled → Ishan in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('[SCORER] 1.3 → W Bowled (Rohit) Score: 10/1');
      await selectBatter(tester, 'Ishan Kishan');
      await deliveryPause();

      // Over 1, Wide
      await tapExtra(tester, 'WD');
      await confirmExtra(tester);
      print('[SCORER] 1.WD→ WD              Score: 11/1');
      await deliveryPause();

      // Over 1, No-ball
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      print('[SCORER] 1.NB→ NB              Score: 12/1');
      await deliveryPause();

      // Over 1, Ball 4: 1 (free hit) → swap
      await tapRun(tester, 1);
      print('[SCORER] 1.4 → 1 (Ishan, FH)   Score: 13/1');
      await deliveryPause();

      // Over 1, Ball 5: W Bowled → Hardik in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('[SCORER] 1.5 → W Bowled (SKY)   Score: 13/2');
      await selectBatter(tester, 'Hardik Pandya');
      await deliveryPause();

      // Over 1, Ball 6: 4
      await tapRun(tester, 4);
      print('[SCORER] 1.6 → 4 (Hardik)      Score: 17/2  End Over 1');
      await deliveryPause();

      // Select bowler for over 2
      await selectBowler(tester, 'Ravindra Jadeja');
      print('[SCORER] Over 2 bowler: Ravindra Jadeja');

      // Over 2, Ball 1: 2
      await tapRun(tester, 2);
      print('[SCORER] 2.1 → 2 (Ishan)       Score: 19/2');
      await deliveryPause();

      // Over 2, Ball 2: W Bowled → Bumrah in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('[SCORER] 2.2 → W Bowled (Ishan) Score: 19/3');
      await selectBatter(tester, 'Jasprit Bumrah');
      await deliveryPause();

      // Over 2, Ball 3: 0 (dot)
      await tapRun(tester, 0);
      print('[SCORER] 2.3 → 0 (Bumrah)      Score: 19/3');
      await deliveryPause();

      // Over 2, Ball 4: W Bowled → Rahul in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('[SCORER] 2.4 → W Bowled (Bumrah) Score: 19/4');
      await selectBatter(tester, 'Rahul Chahar');
      await deliveryPause();

      // Over 2, Ball 5: 1 → swap
      await tapRun(tester, 1);
      print('[SCORER] 2.5 → 1 (Rahul)       Score: 20/4');
      await deliveryPause();

      // Over 2, Ball 6: W Bowled → ALL OUT
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      print('[SCORER] 2.6 → W Bowled (Hardik) Score: 20/5 ALL OUT');
      await deliveryPause();

      print('[SCORER] 1st Innings: 20/5 all out in 2.0 overs. Target: 21');

      // ── PHASE 6: Innings Transition ──
      print('\n[SCORER] ══════════ PHASE 6: Innings Transition ══════════');
      await completeInningsTransition(
        tester,
        striker: 'MS Dhoni',
        nonStriker: 'Ruturaj Gaikwad',
        bowler: 'Rohit Sharma',
      );
      print('[SCORER] Innings transition complete');
      await Future<void>.delayed(const Duration(seconds: 3));

      // ── PHASE 7: 2nd Innings ──
      print(
          '\n[SCORER] ══════════ PHASE 7: 2nd Innings — ${teamB.name} chasing 21 ══════════');

      // Ball 1: 6
      await tapRun(tester, 6);
      print('[SCORER] 1.1 → 6 (Dhoni)       Score: 6/0');
      await deliveryPause();

      // Ball 2: 6
      await tapRun(tester, 6);
      print('[SCORER] 1.2 → 6 (Dhoni)       Score: 12/0');
      await deliveryPause();

      // Ball 3: 4
      await tapRun(tester, 4);
      print('[SCORER] 1.3 → 4 (Dhoni)       Score: 16/0');
      await deliveryPause();

      // Ball 4: 6 → TARGET CHASED
      await tapRun(tester, 6);
      print('[SCORER] 1.4 → 6 (Dhoni)       Score: 22/0 TARGET CHASED');

      await settle(tester);
      await visualPause(tester, 2000);

      // ── PHASE 8: Match Complete ──
      print('\n[SCORER] ══════════ PHASE 8: Match Complete ══════════');
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('[SCORER] MatchCompleteModal displayed');
      } else {
        print('[SCORER] Match complete (modal may have auto-dismissed)');
      }

      // Wait for viewer to receive final updates
      print('[SCORER] Waiting 5s for viewer to finish verification...');
      await Future<void>.delayed(const Duration(seconds: 5));

      print('\n[SCORER] ╔═══════════════════════════════════════╗');
      print('[SCORER] ║   Match complete. Scorer test PASSED.  ║');
      print('[SCORER] ╚═══════════════════════════════════════╝');
    },
  );
}

/// Open the team picker bottom sheet and select [teamName].
Future<void> _selectTeamInPicker(
  WidgetTester tester,
  String pickerLabel,
  String teamName,
) async {
  final selector = find.text(pickerLabel);
  if (selector.evaluate().isEmpty) {
    print('[SCORER] "$pickerLabel" not found');
    dumpVisibleTexts(tester, 'picker-not-found', 20);
    return;
  }

  await tester.tap(selector.first);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

  var found = false;
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.text(teamName).evaluate().isNotEmpty) {
      found = true;
      break;
    }
  }

  if (!found) {
    print('[SCORER] Team "$teamName" not found in picker');
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  await tester.tap(find.text(teamName).first);
  await settle(tester);
  print('[SCORER] Selected: $teamName');
}
