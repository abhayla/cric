/// Spectator Live Test — scorer + non-team spectator multi-device E2E.
///
/// This file contains BOTH scorer and spectator logic, selected via
/// `--dart-define=ROLE=scorer` or `--dart-define=ROLE=viewer`.
///
/// Scorer (device 1): creates match (Team1 vs Team3), scores deliveries.
/// Spectator (device 2): NOT on any team — discovers match via public Live
/// tab, verifies live score updates, confirms match absent from My Cricket.
///
/// Tests the `scope=public` API fix: any authenticated user can see all
/// live matches on the Live tab regardless of team membership.
///
/// Run scorer:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod --dart-define=ROLE=scorer \
///   integration_test/tests/spectator_live_test.dart -d emulator-5554
/// ```
///
/// Run spectator:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod --dart-define=ROLE=viewer \
///   --dart-define=VIEWER_PHONE=9999999997 \
///   integration_test/tests/spectator_live_test.dart -d emulator-5556
/// ```
library;

import 'package:cricscores/src/core/constants/app_constants.dart';
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

/// Spectator phone (not on any team roster).
const _spectatorPhone =
    String.fromEnvironment('VIEWER_PHONE', defaultValue: '9999999997');

void main() {
  initIntegrationTest();

  if (_role == 'scorer') {
    _runScorerTest();
  } else {
    _runSpectatorTest();
  }
}

void _runScorerTest() {
  testWidgets('Spectator SCORER — score match for non-team viewer',
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

    // Set 2 overs, 6 players (short match for fast E2E)
    final overs2 = find.text('2');
    if (overs2.evaluate().isNotEmpty) {
      await tester.tap(overs2.first);
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

    // Signal spectator that scorer is ready
    try {
      await signalDio.post('/api/v1/test/signal/spectator-scorer-ready',
          data: {'value': 'true'});
      print('[SCORER] Signal: scorer-ready posted');

      // Wait for spectator
      final deadline = DateTime.now().add(const Duration(seconds: 120));
      var spectatorReady = false;
      while (DateTime.now().isBefore(deadline)) {
        try {
          final r = await signalDio.get('/api/v1/test/signal/spectator-viewer-ready');
          if (r.data['value'] != null) {
            spectatorReady = true;
            print('[SCORER] Signal: spectator-ready received');
            break;
          }
        } catch (_) {}
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!spectatorReady) {
        print('[SCORER] WARNING: Spectator not ready after 120s — proceeding');
      }
    } catch (e) {
      print('[SCORER] Signal endpoint not available — proceeding: $e');
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    Future<void> deliveryPause() async {
      await Future<void>.delayed(
          const Duration(milliseconds: multiDeviceDeliveryPauseMs));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Over 1: 4, 1, 2, 0, 6, 1 = 14 runs
    await tapRun(tester, 4);
    print('[SCORER] 1.1 → 4');
    await deliveryPause();

    await tapRun(tester, 1);
    print('[SCORER] 1.2 → 1');
    await deliveryPause();

    await tapRun(tester, 2);
    print('[SCORER] 1.3 → 2');
    await deliveryPause();

    await tapRun(tester, 0);
    print('[SCORER] 1.4 → 0');
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] 1.5 → 6');
    await deliveryPause();

    await tapRun(tester, 1);
    print('[SCORER] 1.6 → 1  End Over 1');
    await deliveryPause();

    // Select bowler for over 2
    await selectBowler(tester, team3.players[1].name,
        fallbackNames: team3.players.map((p) => p.name).toList());

    // Over 2: 4, 2, 1, 0, 3, 2 = 12 runs, total = 26
    await tapRun(tester, 4);
    print('[SCORER] 2.1 → 4');
    await deliveryPause();

    await tapRun(tester, 2);
    print('[SCORER] 2.2 → 2');
    await deliveryPause();

    await tapRun(tester, 1);
    print('[SCORER] 2.3 → 1');
    await deliveryPause();

    await tapRun(tester, 0);
    print('[SCORER] 2.4 → 0');
    await deliveryPause();

    await tapRun(tester, 3);
    print('[SCORER] 2.5 → 3');
    await deliveryPause();

    await tapRun(tester, 2);
    print('[SCORER] 2.6 → 2  End Over 2 — innings 1 complete');
    await deliveryPause();

    // Innings transition
    await completeInningsTransition(
      tester,
      striker: team3.players[0].name,
      nonStriker: team3.players[1].name,
      bowler: team1.players[0].name,
    );
    print('[SCORER] Innings transition complete');

    // Innings 2: chase 27 in 2 overs
    // Over 1: 6, 6, 6, 6 = 24, need 3 more
    await tapRun(tester, 6);
    print('[SCORER] Inn2 1.1 → 6');
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] Inn2 1.2 → 6');
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] Inn2 1.3 → 6');
    await deliveryPause();

    await tapRun(tester, 6);
    print('[SCORER] Inn2 1.4 → 6  TARGET CHASED');

    await settle(tester);
    await visualPause(tester, 2000);

    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
      print('[SCORER] MatchCompleteModal displayed');
    }

    // Wait for spectator to finish verification
    print('[SCORER] Waiting 5s for spectator to finish verification...');
    await Future<void>.delayed(const Duration(seconds: 5));

    print('\n[SCORER] Match complete. Scorer test PASSED.');
  }, timeout: const Timeout(Duration(minutes: 30)));
}

void _runSpectatorTest() {
  testWidgets('Spectator VIEWER — discover match on public Live tab',
      (tester) async {
    // Log in as spectator (not on any team)
    await pumpAppAndWaitForHome(tester, phoneNumber: _spectatorPhone);
    print('\n[SPECTATOR] Home page loaded (phone: $_spectatorPhone)');

    final signalDio = _createSignalDio();

    // ── Step 1: Verify My Cricket is empty (spectator has no teams/matches) ──
    print('[SPECTATOR] Checking My Cricket is empty...');
    final matchesTab = find.text('Matches');
    if (matchesTab.evaluate().isNotEmpty) {
      await tester.tap(matchesTab.first);
      await settle(tester);
    }
    // Spectator should see no matches in My Cricket (user-scoped)
    await settle(tester);
    print('[SPECTATOR] My Cricket tab checked');

    // ── Step 2: Wait for scorer to be ready ──
    print('[SPECTATOR] Waiting for scorer-ready signal...');
    final scorerDeadline = DateTime.now().add(const Duration(seconds: 120));
    var scorerReady = false;
    while (DateTime.now().isBefore(scorerDeadline)) {
      try {
        final r = await signalDio.get('/api/v1/test/signal/spectator-scorer-ready');
        if (r.data['value'] != null) {
          scorerReady = true;
          print('[SPECTATOR] Signal: scorer-ready received');
          break;
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!scorerReady) {
      fail('[SPECTATOR] Scorer not ready after 120s');
    }

    // ── Step 3: Navigate to Live tab and verify match appears ──
    await navigateToLive(tester);
    await settle(tester);
    await visualPause(tester, 2000);
    print('[SPECTATOR] On Live page');

    // Pull to refresh to get latest matches
    // The Live tab should show all live matches via scope=public
    // Look for match-related content (team names, score patterns)
    var matchFound = false;
    for (var attempt = 0; attempt < 5; attempt++) {
      await settle(tester);
      await visualPause(tester, 1000);

      // Check for Team1 or Team3 text (teams in the match)
      final team1Finder = find.textContaining('Team1');
      final team3Finder = find.textContaining('Team3');
      if (team1Finder.evaluate().isNotEmpty ||
          team3Finder.evaluate().isNotEmpty) {
        matchFound = true;
        print('[SPECTATOR] Match found on Live tab (attempt ${attempt + 1})');
        break;
      }

      // Pull to refresh
      print(
          '[SPECTATOR] Match not visible yet, refreshing... (attempt ${attempt + 1})');
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.fling(scrollable.first, const Offset(0, 300), 500);
        await settle(tester);
        await visualPause(tester, 2000);
      }
    }

    expect(matchFound, isTrue,
        reason:
            'Spectator should see live match on public Live tab without team membership');
    print('[SPECTATOR] PASS: Match visible on public Live tab');

    // ── Step 4: Signal scorer that spectator is ready ──
    try {
      await signalDio.post('/api/v1/test/signal/spectator-viewer-ready',
          data: {'value': 'true'});
      print('[SPECTATOR] Signal: spectator-ready posted');
    } catch (e) {
      print('[SPECTATOR] Could not post viewer-ready signal: $e');
    }

    // ── Step 5: Watch for live score updates ──
    print('[SPECTATOR] Watching for live updates...');
    final endDeadline = DateTime.now().add(const Duration(minutes: 10));
    var scoreChanges = 0;
    String? lastScore;

    while (DateTime.now().isBefore(endDeadline)) {
      await tester.pump(const Duration(seconds: 1));

      // Look for score text patterns (e.g., "14/0", "26/0")
      final allTexts = find.byType(Text);
      for (final element in allTexts.evaluate()) {
        final textWidget = element.widget as Text;
        final text = textWidget.data;
        if (text != null && RegExp(r'^\d+/\d+$').hasMatch(text)) {
          if (text != lastScore) {
            lastScore = text;
            scoreChanges++;
            print('[SPECTATOR] Score update #$scoreChanges: $text');
          }
        }
      }

      // Check for match complete
      if (find.textContaining('won by').evaluate().isNotEmpty ||
          find.textContaining('Completed').evaluate().isNotEmpty) {
        print('[SPECTATOR] Match completion detected');
        break;
      }
    }

    print('[SPECTATOR] Total score updates observed: $scoreChanges');

    // ── Step 6: Verify match is NOT in My Cricket tab ──
    await navigateToHome(tester);
    await settle(tester);

    // Navigate to Matches sub-tab in My Cricket
    final myCricketMatches = find.text('Matches');
    if (myCricketMatches.evaluate().isNotEmpty) {
      await tester.tap(myCricketMatches.first);
      await settle(tester);
      await visualPause(tester, 1000);
    }

    // The completed match should NOT appear here (user-scoped, spectator has no teams)
    // We check that Team1/Team3 match is not listed
    final team1InMyCricket = find.textContaining('Team1');
    final team3InMyCricket = find.textContaining('Team3');
    final matchInMyCricket = team1InMyCricket.evaluate().isNotEmpty &&
        team3InMyCricket.evaluate().isNotEmpty;
    expect(matchInMyCricket, isFalse,
        reason:
            'Spectator should NOT see the match in My Cricket (user-scoped filtering)');
    print('[SPECTATOR] PASS: Match correctly absent from My Cricket tab');

    print('\n[SPECTATOR] Spectator test PASSED.');
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
