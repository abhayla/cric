// ignore_for_file: avoid_print

@Timeout(Duration(hours: 2))
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
// Pairs with full_t20_e2e_test.dart running on the first emulator (scorer).
// This viewer boots the app, waits for the scorer to signal readiness,
// navigates to the LiveMatchPage, and monitors ALL WebSocket updates.
//
// After every over boundary (overs display changes to X.0), prints a detailed
// sync report with batting/bowling snapshots, run rates, and team info.
//
// Verifies:
//   - WebSocket connection and state reception
//   - Monotonic invariants (runs/wickets non-decreasing within innings)
//   - Innings transitions detected
//   - Match completion received
//   - At least 20 updates for a full T20
//
// Run on second emulator (scorer on emulator-5554):
//   flutter test integration_test/full_t20_viewer_e2e_test.dart -d emulator-5556
//
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Full T20 VIEWER — monitor WebSocket live match updates with per-over reports',
    (WidgetTester tester) async {
      // ── PHASE 1: Boot App ──
      print('\n[VIEWER] ══════════ PHASE 1: Boot App ══════════');
      await AppTestWrapper.pumpAppAndWaitForHome(tester);
      print('[VIEWER] My Cricket page loaded');
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

      // ── PHASE 3: Wait for scorer-ready signal (up to 5 min for Gradle) ──
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

      // ── PHASE 6: Monitor live updates with per-over reports ──
      print('\n[VIEWER] ══════════ PHASE 6: Monitoring live updates ══════════');

      var updateCount = 0;
      var failCount = 0;
      var lastRuns = state.totalRuns;
      var lastWickets = state.totalWickets;
      var lastOvers = state.oversDisplay;
      var lastInnings = state.inningsNumber;
      var lastMatchComplete = state.isMatchComplete || joinedLate;
      var inningsTransitionsSeen = 0;
      var maxInnings = state.inningsNumber;
      final overReports = <String>[];

      // Monitor for up to 65 minutes (full T20 + generous buffer)
      final monitorDeadline = DateTime.now().add(const Duration(minutes: 65));

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

          // Detect innings transition — explicit (inningsNumber changed) or
          // implicit (runs/wickets dropped significantly, indicating a new
          // innings state arrived before the innings number updated).
          final explicitTransition = state.inningsNumber != lastInnings;
          final implicitTransition = !explicitTransition &&
              lastRuns > 20 &&
              state.totalRuns < lastRuns ~/ 2 &&
              state.totalWickets < lastWickets;

          if (explicitTransition || implicitTransition) {
            inningsTransitionsSeen++;
            maxInnings = state.inningsNumber;
            print('\n[VIEWER] ╔══════════════════════════════════════════╗');
            if (implicitTransition) {
              print('[VIEWER] ║   INNINGS TRANSITION (implicit)         ║');
              print('[VIEWER] ║   Runs dropped $lastRuns -> ${state.totalRuns}, '
                  'wkts $lastWickets -> ${state.totalWickets}  ║');
            } else {
              print('[VIEWER] ║   INNINGS ${state.inningsNumber} STARTED                          ║');
            }
            if (state.target != null) {
              print('[VIEWER] ║   Target: ${state.target}                                ║');
            }
            print('[VIEWER] ║   Batting: ${state.battingTeamName.padRight(28)} ║');
            print('[VIEWER] ║   Bowling: ${state.bowlingTeamName.padRight(28)} ║');
            print('[VIEWER] ╚══════════════════════════════════════════╝\n');
            // Reset tracking for new innings
            lastRuns = 0;
            lastWickets = 0;
          }

          // Invariant: runs and wickets must be non-decreasing within same innings
          // (skip check if we just detected a transition)
          if (!explicitTransition && !implicitTransition &&
              state.inningsNumber == lastInnings) {
            if (state.totalRuns < lastRuns) {
              failCount++;
              print('[VIEWER] FAIL: runs decreased '
                  '$lastRuns -> ${state.totalRuns} in Inn${state.inningsNumber}');
            }
            if (state.totalWickets < lastWickets) {
              failCount++;
              print('[VIEWER] FAIL: wickets decreased '
                  '$lastWickets -> ${state.totalWickets} in Inn${state.inningsNumber}');
            }
            expect(state.totalRuns, greaterThanOrEqualTo(lastRuns),
                reason: 'Runs must be non-decreasing within innings');
            expect(state.totalWickets, greaterThanOrEqualTo(lastWickets),
                reason: 'Wickets must be non-decreasing within innings');
          }

          // ── Per-over sync report ──
          // Detect over boundary: overs display ends with .0 and changed
          final isOverBoundary = state.oversDisplay != lastOvers &&
              state.oversDisplay.endsWith('.0') &&
              state.oversDisplay != '0.0';

          if (isOverBoundary || matchDone) {
            final report = _buildOverReport(
              state: state,
              updateNumber: updateCount,
              isMatchComplete: matchDone,
            );
            overReports.add(report);
            print(report);
          } else if (updateCount % 10 == 0) {
            // Periodic log every 10 updates to show progress
            print('[VIEWER] #$updateCount: '
                '${state.totalRuns}/${state.totalWickets} '
                '(${state.oversDisplay}) Inn${state.inningsNumber}'
                '${state.striker != null ? " [${state.striker!.name} ${state.striker!.runs}(${state.striker!.balls})]" : ""}');
          }

          lastRuns = state.totalRuns;
          lastWickets = state.totalWickets;
          lastOvers = state.oversDisplay;
          lastInnings = state.inningsNumber;
          lastMatchComplete = matchDone;
        }
      }

      if (!lastMatchComplete) {
        print('[VIEWER] WARNING: Match did not complete within 65 minutes');
      }

      // ── PHASE 7: Final Summary & Verification ──
      print('\n[VIEWER] ══════════ PHASE 7: Final Summary ══════════');

      print('\n┌────────────────────────────────────────────────────────────┐');
      print('│            FULL T20 VIEWER — SYNC REPORT                  │');
      print('├────────────────────────────────────────────────────────────┤');
      print('│  Total WebSocket updates received: ${updateCount.toString().padLeft(4)}                  │');
      print('│  Innings transitions seen:         ${inningsTransitionsSeen.toString().padLeft(4)}                  │');
      print('│  Max innings number:               ${maxInnings.toString().padLeft(4)}                  │');
      print('│  Over reports generated:           ${overReports.length.toString().padLeft(4)}                  │');
      print('│  Invariant violations (FAIL):      ${failCount.toString().padLeft(4)}                  │');
      print('│  Match completed:                  ${lastMatchComplete ? ' YES' : '  NO'}                  │');
      print('│  Final: Inn$lastInnings  $lastRuns/$lastWickets ($lastOvers)');
      if (state.matchResult != null) {
        print('│  Result: ${state.matchResult!.summary}');
      }
      print('│  Batting: ${state.battingTeamName}');
      print('│  Bowling: ${state.bowlingTeamName}');
      print('└────────────────────────────────────────────────────────────┘');

      // ── Assertions ──
      if (!joinedLate) {
        expect(updateCount, greaterThanOrEqualTo(20),
            reason:
                'Full T20 should produce at least 20 WebSocket updates (got $updateCount)');

        expect(inningsTransitionsSeen, greaterThanOrEqualTo(1),
            reason: 'Should detect at least one innings transition');

        expect(maxInnings, greaterThanOrEqualTo(2),
            reason: 'Should reach innings 2');

        expect(lastMatchComplete, isTrue,
            reason: 'Match should complete within the monitoring period');
      } else {
        print('[VIEWER] Joined late — skipping progression assertions');
        expect(updateCount, greaterThanOrEqualTo(1),
            reason: 'Should receive at least initial state when joining late');
      }

      expect(failCount, equals(0),
          reason: 'Invariant violations detected ($failCount FAILs). '
              'Runs and wickets must be non-decreasing within each innings.');

      print('\n[VIEWER] ╔════════════════════════════════════════════════╗');
      print('[VIEWER] ║   Full T20 Viewer verification complete.        ║');
      print('[VIEWER] ║   Updates: $updateCount | Transitions: $inningsTransitionsSeen | FAIL: $failCount     ║');
      print('[VIEWER] ║   Match Complete: $lastMatchComplete                      ║');
      if (joinedLate) {
        print('[VIEWER] ║   NOTE: Joined late — limited updates           ║');
      }
      print('[VIEWER] ╚════════════════════════════════════════════════╝');
    },
  );
}

/// Build a detailed sync report for an over boundary or match completion.
String _buildOverReport({
  required LiveMatchState state,
  required int updateNumber,
  required bool isMatchComplete,
}) {
  final buf = StringBuffer();
  final label = isMatchComplete ? 'MATCH COMPLETE' : 'Over ${state.oversDisplay}';

  buf.writeln('');
  buf.writeln('  ┌─── $label ── Inn ${state.inningsNumber} ── Update #$updateNumber ───');
  buf.writeln('  │ Score: ${state.totalRuns}/${state.totalWickets} (${state.oversDisplay} ov)');

  // Teams
  if (state.battingTeamName.isNotEmpty) {
    buf.writeln('  │ Batting: ${state.battingTeamName}  vs  ${state.bowlingTeamName}');
  }

  // Run rates
  if (state.currentRunRate != null) {
    buf.write('  │ CRR: ${state.currentRunRate!.toStringAsFixed(2)}');
    if (state.requiredRunRate != null) {
      buf.write('  |  RRR: ${state.requiredRunRate!.toStringAsFixed(2)}');
    }
    buf.writeln();
  }

  // Target (2nd innings)
  if (state.target != null) {
    final remaining = state.target! - state.totalRuns;
    buf.writeln('  │ Target: ${state.target}  |  Need: $remaining runs');
  }

  // Striker
  if (state.striker != null) {
    final s = state.striker!;
    buf.writeln('  │ Striker:     ${s.name.padRight(18)} '
        '${s.runs}(${s.balls})  4s:${s.fours} 6s:${s.sixes}  SR:${s.strikeRate.toStringAsFixed(1)}');
  }

  // Non-striker
  if (state.nonStriker != null) {
    final ns = state.nonStriker!;
    buf.writeln('  │ Non-striker: ${ns.name.padRight(18)} '
        '${ns.runs}(${ns.balls})  4s:${ns.fours} 6s:${ns.sixes}');
  }

  // Bowler
  if (state.bowler != null) {
    final b = state.bowler!;
    buf.writeln('  │ Bowler:      ${b.name.padRight(18)} '
        '${b.overs}-${b.maidens}-${b.runs}-${b.wickets}  Econ:${b.economy.toStringAsFixed(1)}');
  }

  // Special states
  if (state.isFreeHitPending) {
    buf.writeln('  │ ** FREE HIT PENDING **');
  }
  if (state.isMagicOver) {
    buf.writeln('  │ ** MAGIC OVER (${state.magicOverMultiplier}x) **');
  }

  // Match result
  if (isMatchComplete && state.matchResult != null) {
    buf.writeln('  │ Result: ${state.matchResult!.summary}');
  }

  buf.write('  └──────────────────────────────────────────────');

  return buf.toString();
}
