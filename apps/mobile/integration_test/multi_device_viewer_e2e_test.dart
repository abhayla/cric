// ignore_for_file: avoid_print

import 'package:cricapp/src/app/router.dart';
import 'package:cricapp/src/core/constants/app_constants.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/match_live_notifier.dart';
import 'package:cricapp/src/features/scoring/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_test_wrapper.dart';
import 'helpers/expected_match_states.dart';
import 'helpers/match_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Multi-Device VIEWER Test — runs on a REAL Android device via USB
// ═══════════════════════════════════════════════════════════════════════════
//
// This test boots the app on a real device, polls the server for a live match
// (created by the scorer on the emulator), navigates to the LiveMatchPage,
// and verifies every WebSocket score update against expected states.
//
// The server address is passed via --dart-define:
//   --dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1
//   --dart-define=WS_BASE_URL=ws://<LAN_IP>:3001/ws
//
// Run:
//   flutter test integration_test/multi_device_viewer_e2e_test.dart \
//     -d <real-device-id> \
//     --dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1 \
//     --dart-define=WS_BASE_URL=ws://<LAN_IP>:3001/ws

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Multi-device VIEWER — verify WebSocket live match updates',
    (WidgetTester tester) async {
      // ── PHASE 1: Boot App ──
      print('\n[VIEWER] ══════════ PHASE 1: Boot App ══════════');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('Home'), findsWidgets);
      print('[VIEWER] Home page loaded');
      print('[VIEWER] API base: ${AppConstants.apiBaseUrl}');
      print('[VIEWER] WS base:  ${AppConstants.wsBaseUrl}');

      // ── PHASE 2: Create API client with LAN IP ──
      // AppConstants.apiBaseUrl is overridden via --dart-define to point
      // to the host machine's LAN IP (not 10.0.2.2).
      final serverRoot =
          AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
      final dio = Dio(BaseOptions(
        baseUrl: serverRoot,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      print('[VIEWER] Server root: $serverRoot');

      // ── PHASE 3: Poll for live match ──
      print('\n[VIEWER] ══════════ PHASE 3: Poll for live match ══════════');
      String matchId = '';
      final pollDeadline = DateTime.now().add(const Duration(seconds: 120));

      while (DateTime.now().isBefore(pollDeadline)) {
        try {
          final r = await dio.get('/api/v1/test/latest-match');
          final id = r.data['matchId'] as String?;
          if (id != null && id.isNotEmpty) {
            matchId = id;
            print('[VIEWER] Found match: $matchId');
            break;
          }
        } on DioException catch (e) {
          // 404 or connection error — match not created yet
          if (DateTime.now().second % 10 == 0) {
            print('[VIEWER] Waiting for match... (${e.type})');
          }
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      expect(matchId, isNotEmpty,
          reason: 'No match found within 120s — is the scorer running?');

      // ── PHASE 4: Navigate to LiveMatchPage ──
      print('\n[VIEWER] ══════════ PHASE 4: Navigate to /live/$matchId ══════════');

      // Use GoRouter to navigate to the live match page
      final ctx = tester.element(find.byType(Navigator).last);
      GoRouter.of(ctx).go(AppRoutes.liveMatchPath(matchId));
      await settle(tester);
      await visualPause(tester, 1000);
      print('[VIEWER] Navigated to LiveMatchPage');

      // ── PHASE 5: Wait for initial WebSocket connection ──
      print('\n[VIEWER] ══════════ PHASE 5: Wait for WebSocket ══════════');

      // Get the ProviderContainer from the widget tree
      final element = tester.element(find.byType(ProviderScope).first);
      final container = ProviderScope.containerOf(element);

      // Wait for initial match_state message (up to 15s)
      LiveMatchState state = container.read(matchLiveNotifierProvider);
      final wsDeadline = DateTime.now().add(const Duration(seconds: 15));
      while (state.status == null && DateTime.now().isBefore(wsDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        state = container.read(matchLiveNotifierProvider);
      }

      if (state.status != null) {
        print('[VIEWER] Initial state received: ${state.totalRuns}/${state.totalWickets} (${state.oversDisplay})');
      } else {
        print('[VIEWER] WARNING: No initial state after 15s — continuing anyway');
      }

      // ── PHASE 6: Poll for state changes ──
      print('\n[VIEWER] ══════════ PHASE 6: Monitoring live updates ══════════');

      final receivedStates = <_CapturedState>[];
      var lastRuns = state.totalRuns;
      var lastWickets = state.totalWickets;
      var lastOvers = state.oversDisplay;
      var lastInnings = state.inningsNumber;
      var lastMatchComplete = state.isMatchComplete;

      // Capture initial state if we got one
      if (state.status != null) {
        receivedStates.add(_CapturedState.fromLive(state));
        print('[VIEWER] Captured initial: ${state.totalRuns}/${state.totalWickets} (${state.oversDisplay}) Inn${state.inningsNumber}');
      }

      final monitorDeadline = DateTime.now().add(const Duration(minutes: 5));

      while (!lastMatchComplete && DateTime.now().isBefore(monitorDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        state = container.read(matchLiveNotifierProvider);

        // Detect change
        final changed = state.totalRuns != lastRuns ||
            state.totalWickets != lastWickets ||
            state.oversDisplay != lastOvers ||
            state.inningsNumber != lastInnings ||
            (state.isMatchComplete && !lastMatchComplete);

        if (changed) {
          receivedStates.add(_CapturedState.fromLive(state));

          final prefix = state.inningsNumber != lastInnings
              ? '** INNINGS ${state.inningsNumber} **'
              : '';
          print('[VIEWER] Update #${receivedStates.length}: '
              '${state.totalRuns}/${state.totalWickets} (${state.oversDisplay}) '
              'Inn${state.inningsNumber} $prefix'
              '${state.isMatchComplete ? "MATCH COMPLETE" : ""}'
              '${state.striker != null ? " [${state.striker!.name} ${state.striker!.runs}(${state.striker!.balls})]" : ""}');

          // Invariant checks within same innings
          if (state.inningsNumber == lastInnings) {
            expect(state.totalRuns, greaterThanOrEqualTo(lastRuns),
                reason: 'Runs must be non-decreasing within innings');
            expect(state.totalWickets, greaterThanOrEqualTo(lastWickets),
                reason: 'Wickets must be non-decreasing within innings');
          }

          lastRuns = state.totalRuns;
          lastWickets = state.totalWickets;
          lastOvers = state.oversDisplay;
          lastInnings = state.inningsNumber;
          lastMatchComplete = state.isMatchComplete;
        }
      }

      if (!lastMatchComplete) {
        print('[VIEWER] WARNING: Match did not complete within 5 minutes');
      }

      // ── PHASE 7: Verify against expected states ──
      print('\n[VIEWER] ══════════ PHASE 7: Verification ══════════');

      // Print verification report
      print('\n┌─────┬──────┬───────┬───────┬──────────┬──────────────────────────┬────────┐');
      print('│  #  │ Inn  │ Runs  │ Wkts  │  Overs   │ Striker                  │ Status │');
      print('├─────┼──────┼───────┼───────┼──────────┼──────────────────────────┼────────┤');

      var passCount = 0;
      var failCount = 0;
      var warnCount = 0;

      // We may receive more or fewer states than expected due to timing.
      // Match each expected state to the closest received state by content.
      for (final expected in expectedMatchStates) {
        final matching = _findBestMatch(receivedStates, expected);

        if (matching != null) {
          final runsOk = matching.totalRuns == expected.totalRuns;
          final wktsOk = matching.totalWickets == expected.totalWickets;
          final oversOk = matching.oversDisplay == expected.oversDisplay;
          final innOk = matching.inningsNumber == expected.inningsNumber;
          final allCoreOk = runsOk && wktsOk && oversOk && innOk;

          // Check player names if specified
          var playerOk = true;
          if (expected.strikerName != null && matching.strikerName != null) {
            playerOk = playerOk && matching.strikerName == expected.strikerName;
          }
          if (expected.nonStrikerName != null &&
              matching.nonStrikerName != null) {
            playerOk =
                playerOk && matching.nonStrikerName == expected.nonStrikerName;
          }
          if (expected.bowlerName != null && matching.bowlerName != null) {
            playerOk = playerOk && matching.bowlerName == expected.bowlerName;
          }

          final status = allCoreOk && playerOk
              ? '  PASS'
              : allCoreOk
                  ? '  WARN'
                  : ' FAIL';

          if (allCoreOk && playerOk) {
            passCount++;
          } else if (allCoreOk) {
            warnCount++;
          } else {
            failCount++;
          }

          final strikerInfo =
              matching.strikerName ?? '-';
          print(
              '│ ${expected.deliveryIndex.toString().padLeft(2)}  │  ${expected.inningsNumber}   │ ${matching.totalRuns.toString().padLeft(4)}  │ ${matching.totalWickets.toString().padLeft(4)}  │ ${matching.oversDisplay.padLeft(8)} │ ${strikerInfo.padRight(24)} │$status │');

          if (!allCoreOk) {
            if (!runsOk) {
              print(
                  '│     │      │ exp:${expected.totalRuns.toString().padLeft(3)} │       │          │                          │        │');
            }
            if (!wktsOk) {
              print(
                  '│     │      │       │exp:${expected.totalWickets.toString().padLeft(3)} │          │                          │        │');
            }
            if (!oversOk) {
              print(
                  '│     │      │       │       │exp:${expected.oversDisplay.padLeft(5)} │                          │        │');
            }
          }
        } else {
          failCount++;
          print(
              '│ ${expected.deliveryIndex.toString().padLeft(2)}  │  ${expected.inningsNumber}   │ ${expected.totalRuns.toString().padLeft(4)}  │ ${expected.totalWickets.toString().padLeft(4)}  │ ${expected.oversDisplay.padLeft(8)} │ EXPECTED BUT NOT RECEIVED│  MISS │');
        }
      }

      print('├─────┴──────┴───────┴───────┴──────────┴──────────────────────────┴────────┤');
      print('│ Total: ${expectedMatchStates.length} expected | Received: ${receivedStates.length} updates');
      print('│ PASS: $passCount | WARN: $warnCount | FAIL: $failCount');
      print('└──────────────────────────────────────────────────────────────────────────────┘');

      // ── Key checkpoint assertions ──
      print('\n[VIEWER] ── Key checkpoint assertions ──');

      // 1. Innings complete: target should be 21
      final inningsCompleteSt = receivedStates.where(
          (s) => s.inningsNumber == 1 && s.totalWickets == 5).toList();
      if (inningsCompleteSt.isNotEmpty) {
        print('[VIEWER] Innings complete state found: ${inningsCompleteSt.last.totalRuns}/5');
        expect(inningsCompleteSt.last.totalRuns, equals(20),
            reason: '1st innings should end at 20/5');
      }

      // 2. 2nd innings should have target set
      final inn2States =
          receivedStates.where((s) => s.inningsNumber == 2).toList();
      if (inn2States.isNotEmpty) {
        print('[VIEWER] 2nd innings states: ${inn2States.length}');
        final hasTarget = inn2States.any((s) => s.target == 21);
        if (hasTarget) {
          print('[VIEWER] Target 21 confirmed in 2nd innings');
        } else {
          print('[VIEWER] WARNING: Target 21 not found in 2nd innings states');
        }
      }

      // 3. Match result
      final matchCompleteState =
          receivedStates.where((s) => s.isMatchComplete).toList();
      if (matchCompleteState.isNotEmpty) {
        final result = matchCompleteState.last;
        print('[VIEWER] Match result: ${result.matchResultSummary}');
        if (result.matchResultSummary != null) {
          expect(
            result.matchResultSummary!.toLowerCase(),
            contains('chennai kings'),
            reason: 'Match result should mention Chennai Kings as winner',
          );
        }
      } else {
        print('[VIEWER] WARNING: No match complete state received');
      }

      // 4. Final score assertions
      if (receivedStates.isNotEmpty) {
        final lastState = receivedStates.last;
        print('[VIEWER] Final state: Inn${lastState.inningsNumber} '
            '${lastState.totalRuns}/${lastState.totalWickets} '
            '(${lastState.oversDisplay})');
      }

      // Soft assertion: we should have received at least 10 updates
      // (may miss some due to timing, but should get most)
      expect(receivedStates.length, greaterThanOrEqualTo(10),
          reason:
              'Should receive at least 10 WebSocket updates (got ${receivedStates.length})');

      print('\n[VIEWER] ╔════════════════════════════════════════╗');
      print('[VIEWER] ║   Viewer verification complete.         ║');
      print('[VIEWER] ║   PASS: $passCount  WARN: $warnCount  FAIL: $failCount${' ' * 14}║');
      print('[VIEWER] ╚════════════════════════════════════════╝');

      // Hard fail if more than 3 core field mismatches
      expect(failCount, lessThanOrEqualTo(3),
          reason:
              'Too many verification failures ($failCount). Check WebSocket delivery.');
    },
  );
}

/// Captured state snapshot from LiveMatchState.
class _CapturedState {
  _CapturedState({
    required this.inningsNumber,
    required this.totalRuns,
    required this.totalWickets,
    required this.oversDisplay,
    this.strikerName,
    this.strikerRuns,
    this.strikerBalls,
    this.strikerFours,
    this.strikerSixes,
    this.nonStrikerName,
    this.nonStrikerRuns,
    this.nonStrikerBalls,
    this.bowlerName,
    this.bowlerOvers,
    this.bowlerRuns,
    this.bowlerWickets,
    this.target,
    this.isMatchComplete = false,
    this.matchResultSummary,
  });

  factory _CapturedState.fromLive(LiveMatchState s) {
    return _CapturedState(
      inningsNumber: s.inningsNumber,
      totalRuns: s.totalRuns,
      totalWickets: s.totalWickets,
      oversDisplay: s.oversDisplay,
      strikerName: s.striker?.name,
      strikerRuns: s.striker?.runs,
      strikerBalls: s.striker?.balls,
      strikerFours: s.striker?.fours,
      strikerSixes: s.striker?.sixes,
      nonStrikerName: s.nonStriker?.name,
      nonStrikerRuns: s.nonStriker?.runs,
      nonStrikerBalls: s.nonStriker?.balls,
      bowlerName: s.bowler?.name,
      bowlerOvers: s.bowler?.overs,
      bowlerRuns: s.bowler?.runs,
      bowlerWickets: s.bowler?.wickets,
      target: s.target,
      isMatchComplete: s.isMatchComplete,
      matchResultSummary: s.matchResult?.summary,
    );
  }

  final int inningsNumber;
  final int totalRuns;
  final int totalWickets;
  final String oversDisplay;
  final String? strikerName;
  final int? strikerRuns;
  final int? strikerBalls;
  final int? strikerFours;
  final int? strikerSixes;
  final String? nonStrikerName;
  final int? nonStrikerRuns;
  final int? nonStrikerBalls;
  final String? bowlerName;
  final String? bowlerOvers;
  final int? bowlerRuns;
  final int? bowlerWickets;
  final int? target;
  final bool isMatchComplete;
  final String? matchResultSummary;
}

/// Find the best matching received state for an expected state.
/// Matches by innings + totalRuns + totalWickets + oversDisplay.
_CapturedState? _findBestMatch(
  List<_CapturedState> received,
  ExpectedLiveState expected,
) {
  // Exact match first
  for (final r in received) {
    if (r.inningsNumber == expected.inningsNumber &&
        r.totalRuns == expected.totalRuns &&
        r.totalWickets == expected.totalWickets &&
        r.oversDisplay == expected.oversDisplay) {
      return r;
    }
  }

  // Fallback: match by innings + runs + wickets (overs might differ slightly)
  for (final r in received) {
    if (r.inningsNumber == expected.inningsNumber &&
        r.totalRuns == expected.totalRuns &&
        r.totalWickets == expected.totalWickets) {
      return r;
    }
  }

  return null;
}
