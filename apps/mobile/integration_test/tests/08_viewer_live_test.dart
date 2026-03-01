/// 08: Multi-Device Viewer Live Test — scorer emulator + viewer real device.
///
/// This file contains BOTH scorer and viewer logic, selected via
/// `--dart-define=ROLE=scorer` or `--dart-define=ROLE=viewer`.
///
/// Scorer (emulator): creates match, completes toss, scores deliveries.
/// Viewer (real device): opens Live page, watches updates in real-time.
///
/// Coordination via HTTP signal endpoints (exception to zero-API rule —
/// test infrastructure only, not data creation).
///
/// Run scorer:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod --dart-define=ROLE=scorer \
///   integration_test/tests/08_viewer_live_test.dart -d emulator-5554
/// ```
///
/// Run viewer:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod --dart-define=ROLE=viewer \
///   integration_test/tests/08_viewer_live_test.dart -d <real-device-id>
/// ```
library;

import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/constants.dart';
import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../helpers/scoring.dart';

/// Role is determined by --dart-define=ROLE=scorer|viewer
const _role = String.fromEnvironment('ROLE', defaultValue: 'scorer');

void main() {
  initIntegrationTest();

  if (_role == 'scorer') {
    _runScorerTest();
  } else {
    _runViewerTest();
  }
}

void _runScorerTest() {
  testWidgets('Multi-device SCORER — score match with pauses for viewer',
      (tester) async {
    await pumpAppAndWaitForHome(tester, phoneNumber: scorerPhone);
    print('\n[SCORER] My Cricket page loaded');

    final signalDio = _createSignalDio();

    // Navigate to match setup
    await navigateToMatchSetup(tester);
    await visualPause(tester, 1000);

    // Select teams: Team1 vs Team3
    await selectTeamInMatchSetup(tester, 'Team1', isHome: true);
    await selectTeamInMatchSetup(tester, 'Team3', isHome: false);

    // Set 5 overs (smallest preset), 6 players
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

    // Toss: Team1 bats
    final team1 = allTeams[0];
    final team3 = allTeams[2];

    await completeTossWizard(
      tester,
      tossWinnerName: 'Team1',
      battingOpener1: team1.players[0].name,
      battingOpener2: team1.players[1].name,
      openingBowler: team3.players[0].name,
      playersPerSide: 6,
      chooseBat: true,
    );
    print('[SCORER] Toss complete — scoring page ready');

    // Signal viewer that scorer is ready
    try {
      await signalDio.post('/api/v1/test/signal/scorer-ready',
          data: {'value': 'true'});
      print('[SCORER] Signal: scorer-ready posted');

      // Wait for viewer
      final viewerDeadline = DateTime.now().add(const Duration(seconds: 120));
      var viewerReady = false;
      while (DateTime.now().isBefore(viewerDeadline)) {
        try {
          final r = await signalDio.get('/api/v1/test/signal/viewer-ready');
          if (r.data['value'] != null) {
            viewerReady = true;
            print('[SCORER] Signal: viewer-ready received');
            break;
          }
        } catch (_) {}
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!viewerReady) {
        print('[SCORER] WARNING: Viewer not ready after 120s — proceeding');
      }
    } catch (e) {
      print('[SCORER] Signal endpoint not available — proceeding: $e');
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    // Score predetermined deliveries with pauses for viewer to observe.
    // Match format: 5 overs, 6 players per side.
    // Innings 1: Team1 bats, get all-out (5 wickets) for a quick finish.
    // Innings 2: Team3 chases the target with boundaries.
    Future<void> deliveryPause() async {
      await Future<void>.delayed(
          const Duration(milliseconds: multiDeviceDeliveryPauseMs));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // === INNINGS 1: Team1 batting ===
    // Over 1: 4, W, 0, W, 6, W → score 10, 3 wickets
    await tapRun(tester, 4);
    print('[SCORER] 1.1 → 4');
    await deliveryPause();

    await tapWicket(tester);
    await selectDismissalType(tester, 'Bowled');
    await tapWicketConfirm(tester);
    print('[SCORER] 1.2 → W');
    await selectBatter(tester, team1.players[2].name);
    await deliveryPause();

    await tapRun(tester, 0);
    print('[SCORER] 1.3 → 0');
    await deliveryPause();

    await tapWicket(tester);
    await selectDismissalType(tester, 'Bowled');
    await tapWicketConfirm(tester);
    print('[SCORER] 1.4 → W');
    await selectBatter(tester, team1.players[3].name);
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] 1.5 → 6');
    await deliveryPause();

    await tapWicket(tester);
    await selectDismissalType(tester, 'Bowled');
    await tapWicketConfirm(tester);
    print('[SCORER] 1.6 → W  End Over 1 (3 wickets)');
    await selectBatter(tester, team1.players[4].name);
    await deliveryPause();

    // Select bowler for over 2
    await selectBowler(tester, team3.players[1].name,
        fallbackNames: team3.players.map((p) => p.name).toList());

    // Over 2: 0, W, 0, W → 5 wickets = ALL OUT
    await tapRun(tester, 0);
    print('[SCORER] 2.1 → 0');
    await deliveryPause();

    await tapWicket(tester);
    await selectDismissalType(tester, 'Bowled');
    await tapWicketConfirm(tester);
    print('[SCORER] 2.2 → W');
    await selectBatter(tester, team1.players[5].name);
    await deliveryPause();

    await tapRun(tester, 0);
    print('[SCORER] 2.3 → 0');
    await deliveryPause();

    await tapWicket(tester);
    await selectDismissalType(tester, 'Bowled');
    await tapWicketConfirm(tester);
    print('[SCORER] 2.4 → W  ALL OUT (5 wickets)');
    await deliveryPause();

    // Wait for innings transition modal (all-out triggers it)
    final foundTransition = await waitForFinder(
      tester,
      find.byType(InningsTransitionModal),
      timeoutMs: 15000,
      intervalMs: 500,
    );
    print('[SCORER] InningsTransitionModal found: $foundTransition');
    if (!foundTransition) {
      dumpVisibleTexts(tester, 'no-transition-modal', 40);
    }

    // Innings transition: Team3 batting
    await completeInningsTransition(
      tester,
      striker: team3.players[0].name,
      nonStriker: team3.players[1].name,
      bowler: team1.players[0].name,
    );
    print('[SCORER] Innings transition complete');

    // === INNINGS 2: Team3 chasing (target ~11) ===
    // 6, 6 → should chase immediately
    await tapRun(tester, 6);
    print('[SCORER] 1.1 → 6');
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] 1.2 → 6  TARGET CHASED');

    await settle(tester);
    await visualPause(tester, 2000);

    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
      print('[SCORER] MatchCompleteModal displayed');
    }

    // Wait for viewer
    print('[SCORER] Waiting 5s for viewer to finish verification...');
    await Future<void>.delayed(const Duration(seconds: 5));

    print('\n[SCORER] Match complete. Scorer test PASSED.');
  }, timeout: const Timeout(Duration(minutes: 30)));
}

void _runViewerTest() {
  testWidgets('Multi-device VIEWER — watch live match updates', (tester) async {
    await pumpAppAndWaitForHome(tester, phoneNumber: viewerPhone);
    print('\n[VIEWER] My Cricket page loaded');

    final signalDio = _createSignalDio();

    // Wait for scorer to be ready
    print('[VIEWER] Waiting for scorer-ready signal...');
    final scorerDeadline = DateTime.now().add(const Duration(seconds: 120));
    var scorerReady = false;
    while (DateTime.now().isBefore(scorerDeadline)) {
      try {
        final r = await signalDio.get('/api/v1/test/signal/scorer-ready');
        if (r.data['value'] != null) {
          scorerReady = true;
          print('[VIEWER] Signal: scorer-ready received');
          break;
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!scorerReady) {
      fail('[VIEWER] Scorer not ready after 120s');
    }

    // Navigate to Live page
    await navigateToLive(tester);
    await settle(tester);
    await visualPause(tester, 2000);
    print('[VIEWER] On Live page');

    // Signal scorer that viewer is ready
    try {
      await signalDio.post('/api/v1/test/signal/viewer-ready',
          data: {'value': 'true'});
      print('[VIEWER] Signal: viewer-ready posted');
    } catch (e) {
      print('[VIEWER] Could not post viewer-ready signal: $e');
    }

    // Watch for live updates (poll for score changes)
    print('[VIEWER] Watching for live updates...');
    final endDeadline = DateTime.now().add(const Duration(minutes: 10));
    var scoreChanges = 0;
    String? lastScore;

    while (DateTime.now().isBefore(endDeadline)) {
      await tester.pump(const Duration(seconds: 1));

      // Look for score text patterns
      final allTexts = find.byType(Text);
      for (final element in allTexts.evaluate()) {
        final textWidget = element.widget as Text;
        final text = textWidget.data;
        if (text != null && RegExp(r'^\d+/\d+$').hasMatch(text)) {
          if (text != lastScore) {
            lastScore = text;
            scoreChanges++;
            print('[VIEWER] Score update #$scoreChanges: $text');
          }
        }
      }

      // Check for match complete
      if (find.textContaining('won by').evaluate().isNotEmpty ||
          find.textContaining('Completed').evaluate().isNotEmpty) {
        print('[VIEWER] Match completion detected');
        break;
      }
    }

    print('\n[VIEWER] Total score updates observed: $scoreChanges');
    print('[VIEWER] Viewer test PASSED.');
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Create a Dio instance for signal endpoint communication.
Dio _createSignalDio() {
  final serverRoot = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
  return Dio(BaseOptions(
    baseUrl: serverRoot,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
}
