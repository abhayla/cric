// ignore_for_file: avoid_print

@Timeout(Duration(hours: 1))
library;

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
import 'helpers/match_flow_helpers.dart';

// =============================================================================
// Full T20 VIEWER Test — runs on a SECOND emulator watching the scorer
// =============================================================================
//
// Pairs with full_t20_e2e_test.dart running on the first emulator.
// This viewer boots the app, waits for the scorer to signal readiness,
// navigates to the LiveMatchPage, and monitors WebSocket updates.
//
// Verifies:
//   - WebSocket connection and state reception
//   - Monotonic invariants (runs/wickets non-decreasing within innings)
//   - Innings transitions detected
//   - Match completion received
//
// Run:
//   flutter test integration_test/full_t20_viewer_e2e_test.dart -d emulator-5556 --timeout 60m
//
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Full T20 VIEWER — monitor WebSocket live match updates',
    (WidgetTester tester) async {
      // ── PHASE 1: Boot App ──
      print('\n[VIEWER] ══════════ PHASE 1: Boot App ══════════');
      await AppTestWrapper.pumpAppAndWaitForHome(tester);
      print('[VIEWER] Home page loaded');
      print('[VIEWER] API base: ${AppConstants.apiBaseUrl}');
      print('[VIEWER] WS base:  ${AppConstants.wsBaseUrl}');

      // ── PHASE 2: Create API client ──
      final serverRoot =
          AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
      final dio = Dio(BaseOptions(
        baseUrl: serverRoot,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      print('[VIEWER] Server root: $serverRoot');

      // ── PHASE 3: Wait for scorer-ready signal ──
      print('\n[VIEWER] ══════════ PHASE 3: Wait for scorer-ready signal ══════════');
      String matchId = '';
      final pollDeadline = DateTime.now().add(const Duration(minutes: 5));

      while (DateTime.now().isBefore(pollDeadline)) {
        try {
          final r = await dio.get('/api/v1/test/signal/scorer-ready');
          if (r.data['value'] != null) {
            print('[VIEWER] Scorer ready signal received');
            break;
          }
        } on DioException catch (e) {
          if (DateTime.now().second % 15 == 0) {
            print('[VIEWER] Waiting for scorer-ready... (${e.type})');
          }
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      // Get the match ID
      try {
        final r = await dio.get('/api/v1/test/latest-match');
        final id = r.data['matchId'] as String?;
        if (id != null && id.isNotEmpty) {
          matchId = id;
          print('[VIEWER] Found match: $matchId');
        }
      } on DioException catch (e) {
        print('[VIEWER] Failed to get latest match: ${e.type}');
      }

      expect(matchId, isNotEmpty,
          reason: 'No match found — is the scorer running?');

      // ── PHASE 4: Navigate to LiveMatchPage ──
      print('\n[VIEWER] ══════════ PHASE 4: Navigate to /live/$matchId ══════════');

      final ctx = tester.element(find.byType(Navigator).last);
      GoRouter.of(ctx).go(AppRoutes.liveMatchPath(matchId));
      await settle(tester);
      await visualPause(tester, 1000);
      print('[VIEWER] Navigated to LiveMatchPage');

      // ── PHASE 5: Wait for WebSocket connection ──
      print('\n[VIEWER] ══════════ PHASE 5: Wait for WebSocket ══════════');

      final element = tester.element(find.byType(Scaffold).first);
      final container = ProviderScope.containerOf(element);

      LiveMatchState state = container.read(matchLiveNotifierProvider);
      final wsDeadline = DateTime.now().add(const Duration(seconds: 30));
      while (state.status == null && DateTime.now().isBefore(wsDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        state = container.read(matchLiveNotifierProvider);
      }

      final bool joinedLate = state.status == 'completed';
      if (state.status != null) {
        print('[VIEWER] Initial state: ${state.totalRuns}/${state.totalWickets} '
            '(${state.oversDisplay}) Inn${state.inningsNumber}'
            '${joinedLate ? " [COMPLETED — joined late]" : ""}');
      } else {
        print('[VIEWER] WARNING: No initial state after 30s');
      }

      // Signal scorer that viewer is connected
      try {
        await dio.post('/api/v1/test/signal/viewer-ready',
            data: {'value': 'true'});
        print('[VIEWER] Signal: viewer-ready posted');
      } catch (e) {
        print('[VIEWER] Failed to post viewer-ready signal: $e');
      }

      // ── PHASE 6: Monitor live updates ──
      print('\n[VIEWER] ══════════ PHASE 6: Monitoring live updates ══════════');

      var updateCount = 0;
      var lastRuns = state.totalRuns;
      var lastWickets = state.totalWickets;
      var lastOvers = state.oversDisplay;
      var lastInnings = state.inningsNumber;
      var lastMatchComplete = state.isMatchComplete || joinedLate;
      var inningsTransitionsSeen = 0;
      var maxInnings = state.inningsNumber;

      // Monitor for up to 15 minutes (full T20 can take ~10 min on emulator)
      final monitorDeadline = DateTime.now().add(const Duration(minutes: 15));

      while (!lastMatchComplete && DateTime.now().isBefore(monitorDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
        state = container.read(matchLiveNotifierProvider);

        final matchDone = state.isMatchComplete || state.status == 'completed';
        final changed = state.totalRuns != lastRuns ||
            state.totalWickets != lastWickets ||
            state.oversDisplay != lastOvers ||
            state.inningsNumber != lastInnings ||
            (matchDone && !lastMatchComplete);

        if (changed) {
          updateCount++;

          // Detect innings transition
          if (state.inningsNumber != lastInnings) {
            inningsTransitionsSeen++;
            maxInnings = state.inningsNumber;
            print('[VIEWER] ** INNINGS ${state.inningsNumber} STARTED **');
          }

          // Invariant: runs and wickets must be non-decreasing within same innings
          if (state.inningsNumber == lastInnings) {
            if (state.totalRuns < lastRuns) {
              print('[VIEWER] INVARIANT VIOLATION: runs decreased '
                  '$lastRuns -> ${state.totalRuns}');
            }
            expect(state.totalRuns, greaterThanOrEqualTo(lastRuns),
                reason: 'Runs must be non-decreasing within innings');
            expect(state.totalWickets, greaterThanOrEqualTo(lastWickets),
                reason: 'Wickets must be non-decreasing within innings');
          }

          // Log every 5th update to avoid spam (full T20 = ~250 updates)
          if (updateCount % 5 == 0 || matchDone || state.inningsNumber != lastInnings) {
            print('[VIEWER] #$updateCount: '
                '${state.totalRuns}/${state.totalWickets} '
                '(${state.oversDisplay}) Inn${state.inningsNumber}'
                '${matchDone ? " MATCH COMPLETE" : ""}'
                '${state.striker != null ? " [${state.striker!.name} ${state.striker!.runs}(${state.striker!.balls})]" : ""}');
          }

          lastRuns = state.totalRuns;
          lastWickets = state.totalWickets;
          lastOvers = state.oversDisplay;
          lastInnings = state.inningsNumber;
          lastMatchComplete = matchDone;
        }
      }

      // ── PHASE 7: Verification ──
      print('\n[VIEWER] ══════════ PHASE 7: Verification ══════════');

      print('[VIEWER] Total WebSocket updates received: $updateCount');
      print('[VIEWER] Innings transitions seen: $inningsTransitionsSeen');
      print('[VIEWER] Max innings number: $maxInnings');
      print('[VIEWER] Match completed: $lastMatchComplete');
      print('[VIEWER] Final state: Inn$lastInnings '
          '$lastRuns/$lastWickets ($lastOvers)');

      // Assertions
      if (!joinedLate) {
        // Should receive meaningful number of updates for a full T20
        expect(updateCount, greaterThanOrEqualTo(20),
            reason:
                'Full T20 should produce at least 20 WebSocket updates (got $updateCount)');

        // Should see at least one innings transition
        expect(inningsTransitionsSeen, greaterThanOrEqualTo(1),
            reason: 'Should detect at least one innings transition');

        // Should see both innings
        expect(maxInnings, greaterThanOrEqualTo(2),
            reason: 'Should reach innings 2');

        // Match should complete
        expect(lastMatchComplete, isTrue,
            reason: 'Match should complete within the monitoring period');
      } else {
        print('[VIEWER] Joined late — skipping progression assertions');
        expect(updateCount, greaterThanOrEqualTo(1),
            reason: 'Should receive at least initial state when joining late');
      }

      print('\n[VIEWER] ╔════════════════════════════════════════════╗');
      print('[VIEWER] ║   Full T20 Viewer verification complete.    ║');
      print('[VIEWER] ║   Updates: $updateCount | Transitions: $inningsTransitionsSeen     ║');
      print('[VIEWER] ║   Match Complete: $lastMatchComplete                  ║');
      if (joinedLate) {
        print('[VIEWER] ║   NOTE: Joined late — limited updates       ║');
      }
      print('[VIEWER] ╚════════════════════════════════════════════╝');
    },
  );
}
