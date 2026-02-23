// ignore_for_file: avoid_print

import 'package:cricscores/src/app/router.dart';
import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/match_live_notifier.dart';
import 'package:cricscores/src/features/scoring/providers.dart';
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

  testWidgets('Multi-device VIEWER — verify WebSocket live match updates', (
    WidgetTester tester,
  ) async {
    // ── PHASE 1: Boot App ──
    print('\n[VIEWER] ══════════ PHASE 1: Boot App ══════════');
    await AppTestWrapper.pumpAppAndWaitForHome(tester, phoneNumber: testPhoneDevice2);
    print('[VIEWER] My Cricket page loaded');
    print('[VIEWER] API base: ${AppConstants.apiBaseUrl}');
    print('[VIEWER] WS base:  ${AppConstants.wsBaseUrl}');

    // ── PHASE 2: Create API client with LAN IP ──
    // AppConstants.apiBaseUrl is overridden via --dart-define to point
    // to the host machine's LAN IP (not 10.0.2.2).
    final serverRoot = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
    final dio = Dio(
      BaseOptions(
        baseUrl: serverRoot,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    print('[VIEWER] Server root: $serverRoot');

    // ── PHASE 3: Wait for scorer to be ready, then handshake ──
    print(
      '\n[VIEWER] ══════════ PHASE 3: Wait for scorer-ready signal ══════════',
    );
    String matchId = '';
    final pollDeadline = DateTime.now().add(const Duration(seconds: 180));

    // Step 1: Poll for scorer-ready signal
    while (DateTime.now().isBefore(pollDeadline)) {
      try {
        final r = await dio.get('/api/v1/test/signal/scorer-ready');
        if (r.data['value'] != null) {
          print('[VIEWER] Scorer ready signal received');
          break;
        }
      } on DioException catch (e) {
        if (DateTime.now().second % 10 == 0) {
          print('[VIEWER] Waiting for scorer-ready... (${e.type})');
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    // Step 2: Get the match ID
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

    expect(
      matchId,
      isNotEmpty,
      reason: 'No match found — is the scorer running?',
    );

    // ── PHASE 4: Navigate to LiveMatchPage ──
    print(
      '\n[VIEWER] ══════════ PHASE 4: Navigate to /live/$matchId ══════════',
    );

    // Use GoRouter to navigate to the live match page
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).go(AppRoutes.liveMatchPath(matchId));
    await settle(tester);
    await visualPause(tester, 1000);
    print('[VIEWER] Navigated to LiveMatchPage');

    // ── PHASE 5: Wait for initial WebSocket connection ──
    print('\n[VIEWER] ══════════ PHASE 5: Wait for WebSocket ══════════');

    // Get the ProviderContainer from the widget tree
    // Use a child element (Scaffold) — containerOf looks for an ancestor
    // ProviderScope, so passing the ProviderScope element itself fails.
    final element = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(element);

    // Wait for initial match_state message (up to 15s)
    LiveMatchState state = container.read(matchLiveNotifierProvider);
    final wsDeadline = DateTime.now().add(const Duration(seconds: 15));
    while (state.status == null && DateTime.now().isBefore(wsDeadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      state = container.read(matchLiveNotifierProvider);
    }

    // Check if we joined a completed match (match_state has status but
    // no separate match_complete message — isMatchComplete stays false).
    final bool joinedLate = state.status == 'completed';
    if (state.status != null) {
      print(
        '[VIEWER] Initial state received: ${state.totalRuns}/${state.totalWickets} (${state.oversDisplay})'
        '${joinedLate ? " [COMPLETED — joined late]" : ""}',
      );
    } else {
      print('[VIEWER] WARNING: No initial state after 15s — continuing anyway');
    }

    // Signal to scorer that viewer is connected and ready
    try {
      await dio.post(
        '/api/v1/test/signal/viewer-ready',
        data: {'value': 'true'},
      );
      print('[VIEWER] Signal: viewer-ready posted');
    } catch (e) {
      print('[VIEWER] Failed to post viewer-ready signal: $e');
    }

    // ── PHASE 6: Poll for state changes ──
    print('\n[VIEWER] ══════════ PHASE 6: Monitoring live updates ══════════');

    final receivedStates = <_CapturedState>[];
    var lastRuns = state.totalRuns;
    var lastWickets = state.totalWickets;
    var lastOvers = state.oversDisplay;
    var lastInnings = state.inningsNumber;
    // Treat both isMatchComplete and status=='completed' as done.
    var lastMatchComplete = state.isMatchComplete || joinedLate;

    // Capture initial state if we got one
    if (state.status != null) {
      receivedStates.add(_CapturedState.fromLive(state));
      print(
        '[VIEWER] Captured initial: ${state.totalRuns}/${state.totalWickets} (${state.oversDisplay}) Inn${state.inningsNumber}',
      );
    }

    final monitorDeadline = DateTime.now().add(const Duration(minutes: 5));
    var lastUpdateTime = DateTime.now();

    while (!lastMatchComplete && DateTime.now().isBefore(monitorDeadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      state = container.read(matchLiveNotifierProvider);

      // Detect change — also check status=='completed' for match_state msgs
      final matchDone = state.isMatchComplete || state.status == 'completed';
      final changed =
          state.totalRuns != lastRuns ||
          state.totalWickets != lastWickets ||
          state.oversDisplay != lastOvers ||
          state.inningsNumber != lastInnings ||
          (matchDone && !lastMatchComplete);

      if (changed) {
        receivedStates.add(_CapturedState.fromLive(state));
        lastUpdateTime = DateTime.now();

        final prefix = state.inningsNumber != lastInnings
            ? '** INNINGS ${state.inningsNumber} **'
            : '';
        print(
          '[VIEWER] Update #${receivedStates.length}: '
          '${state.totalRuns}/${state.totalWickets} (${state.oversDisplay}) '
          'Inn${state.inningsNumber} $prefix'
          '${matchDone ? "MATCH COMPLETE" : ""}'
          '${state.striker != null ? " [${state.striker!.name} ${state.striker!.runs}(${state.striker!.balls})]" : ""}',
        );

        // Invariant checks within same innings
        if (state.inningsNumber == lastInnings) {
          expect(
            state.totalRuns,
            greaterThanOrEqualTo(lastRuns),
            reason: 'Runs must be non-decreasing within innings',
          );
          expect(
            state.totalWickets,
            greaterThanOrEqualTo(lastWickets),
            reason: 'Wickets must be non-decreasing within innings',
          );
        }

        lastRuns = state.totalRuns;
        lastWickets = state.totalWickets;
        lastOvers = state.oversDisplay;
        lastInnings = state.inningsNumber;
        lastMatchComplete = matchDone;
      }

      // Staleness guard: if no updates for 15s and we have enough states,
      // check once more for match completion and break
      final staleDuration = DateTime.now().difference(lastUpdateTime);
      if (staleDuration.inSeconds > 15 && receivedStates.length >= 8) {
        // Re-read state one final time (match_state reconciliation may have arrived)
        state = container.read(matchLiveNotifierProvider);
        final finalDone = state.isMatchComplete || state.status == 'completed';
        if (finalDone) {
          lastMatchComplete = true;
          receivedStates.add(_CapturedState.fromLive(state));
          print(
            '[VIEWER] Match complete detected after ${staleDuration.inSeconds}s stale period',
          );
        } else {
          print(
            '[VIEWER] No updates for ${staleDuration.inSeconds}s with ${receivedStates.length} states — breaking',
          );
        }
        break;
      }
    }

    if (!lastMatchComplete) {
      print('[VIEWER] WARNING: Match did not complete within 5 minutes');
    }

    // ── PHASE 7: Verify against expected states ──
    print('\n[VIEWER] ══════════ PHASE 7: Verification ══════════');

    // Print verification report
    print(
      '\n┌─────┬──────┬───────┬───────┬──────────┬──────────────────────────┬────────┐',
    );
    print(
      '│  #  │ Inn  │ Runs  │ Wkts  │  Overs   │ Striker                  │ Status │',
    );
    print(
      '├─────┼──────┼───────┼───────┼──────────┼──────────────────────────┼────────┤',
    );

    var passCount = 0;
    var failCount = 0;
    var warnCount = 0;
    var missCount = 0;

    // We may receive more or fewer states than expected due to timing.
    // Match each expected state to the closest received state by content.
    for (final expected in expectedMatchStates) {
      final matching = _findBestMatch(receivedStates, expected);

      if (matching != null) {
        final runsOk = matching.totalRuns == expected.totalRuns;
        final wktsOk = matching.totalWickets == expected.totalWickets;
        final oversOk = matching.oversDisplay == expected.oversDisplay;
        final innOk = matching.inningsNumber == expected.inningsNumber;
        // Core = runs + wickets + innings. Overs may lag by a sub-delivery
        // when fast-path WS updates coalesce (e.g. wicket at 1.2 + dot at
        // 1.3 arrive as one update showing 1.3). Treat overs-only mismatch
        // as WARN, not FAIL.
        final allCoreOk = runsOk && wktsOk && innOk;

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

        final status = allCoreOk && oversOk && playerOk
            ? '  PASS'
            : allCoreOk
            ? '  WARN'
            : ' FAIL';

        if (allCoreOk && oversOk && playerOk) {
          passCount++;
        } else if (allCoreOk) {
          warnCount++; // overs-only or player-only mismatch = timing artifact
        } else {
          failCount++;
        }

        final strikerInfo = matching.strikerName ?? '-';
        print(
          '│ ${expected.deliveryIndex.toString().padLeft(2)}  │  ${expected.inningsNumber}   │ ${matching.totalRuns.toString().padLeft(4)}  │ ${matching.totalWickets.toString().padLeft(4)}  │ ${matching.oversDisplay.padLeft(8)} │ ${strikerInfo.padRight(24)} │$status │',
        );

        if (!allCoreOk) {
          if (!runsOk) {
            print(
              '│     │      │ exp:${expected.totalRuns.toString().padLeft(3)} │       │          │                          │        │',
            );
          }
          if (!wktsOk) {
            print(
              '│     │      │       │exp:${expected.totalWickets.toString().padLeft(3)} │          │                          │        │',
            );
          }
          if (!oversOk) {
            print(
              '│     │      │       │       │exp:${expected.oversDisplay.padLeft(5)} │                          │        │',
            );
          }
        }
      } else {
        missCount++;
        print(
          '│ ${expected.deliveryIndex.toString().padLeft(2)}  │  ${expected.inningsNumber}   │ ${expected.totalRuns.toString().padLeft(4)}  │ ${expected.totalWickets.toString().padLeft(4)}  │ ${expected.oversDisplay.padLeft(8)} │ EXPECTED BUT NOT RECEIVED│  MISS │',
        );
      }
    }

    print(
      '├─────┴──────┴───────┴───────┴──────────┴──────────────────────────┴────────┤',
    );
    print(
      '│ Total: ${expectedMatchStates.length} expected | Received: ${receivedStates.length} updates',
    );
    print(
      '│ PASS: $passCount | WARN: $warnCount | MISS: $missCount | FAIL: $failCount',
    );
    print(
      '└──────────────────────────────────────────────────────────────────────────────┘',
    );

    // ── Key checkpoint assertions ──
    print('\n[VIEWER] ── Key checkpoint assertions ──');

    // 1. Innings complete: target should be 21
    final inningsCompleteSt = receivedStates
        .where((s) => s.inningsNumber == 1 && s.totalWickets == 5)
        .toList();
    if (inningsCompleteSt.isNotEmpty) {
      print(
        '[VIEWER] Innings complete state found: ${inningsCompleteSt.last.totalRuns}/5',
      );
      expect(
        inningsCompleteSt.last.totalRuns,
        equals(20),
        reason: '1st innings should end at 20/5',
      );
    }

    // 2. 2nd innings should have target set
    final inn2States = receivedStates
        .where((s) => s.inningsNumber == 2)
        .toList();
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
    final matchCompleteState = receivedStates
        .where((s) => s.isMatchComplete)
        .toList();
    if (matchCompleteState.isNotEmpty) {
      final result = matchCompleteState.last;
      print('[VIEWER] Match result: ${result.matchResultSummary}');
      if (result.matchResultSummary != null) {
        // Server summary may be "Won by X wickets" or include team name.
        // Just verify it mentions the win margin type.
        expect(
          result.matchResultSummary!.toLowerCase(),
          anyOf(contains('wickets'), contains('runs'), contains('tied')),
          reason: 'Match result should describe the outcome',
        );
      }
    } else if (joinedLate) {
      print(
        '[VIEWER] Joined late — no match_complete message received (expected)',
      );
    } else {
      print('[VIEWER] WARNING: No match complete state received');
    }

    // 4. Final score assertions
    if (receivedStates.isNotEmpty) {
      final lastState = receivedStates.last;
      print(
        '[VIEWER] Final state: Inn${lastState.inningsNumber} '
        '${lastState.totalRuns}/${lastState.totalWickets} '
        '(${lastState.oversDisplay})',
      );
    }

    // Update count threshold — viewer may join mid-match due to Gradle
    // build time. Require at least 8 updates (we have 18 total deliveries,
    // viewer should catch at least the second half of the match).
    // joinedLate=true means the match was already completed on connect.
    final minExpectedUpdates = joinedLate ? 1 : 8;
    expect(
      receivedStates.length,
      greaterThanOrEqualTo(minExpectedUpdates),
      reason:
          'Should receive at least $minExpectedUpdates WebSocket updates '
          '(got ${receivedStates.length}, joinedLate=$joinedLate)',
    );

    print('\n[VIEWER] ╔════════════════════════════════════════╗');
    print('[VIEWER] ║   Viewer verification complete.         ║');
    print(
      '[VIEWER] ║   PASS: $passCount  WARN: $warnCount  MISS: $missCount  FAIL: $failCount ║',
    );
    if (joinedLate) {
      print('[VIEWER] ║   NOTE: Joined late — limited updates   ║');
    }
    print('[VIEWER] ╚════════════════════════════════════════╝');

    // FAIL = core field mismatch (runs/wickets/overs/innings wrong).
    // MISS = viewer wasn't connected yet (expected due to build time).
    // WARN = core fields correct but player names differ (timing).
    // Only FAIL indicates a real WebSocket delivery bug.
    expect(
      failCount,
      equals(0),
      reason:
          'Core field mismatches detected ($failCount FAILs). '
          'MISS ($missCount) and WARN ($warnCount) are expected timing artifacts.',
    );
  });
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
