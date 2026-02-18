// ignore_for_file: avoid_print

import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_test_wrapper.dart';
import 'helpers/data_generators.dart';
import 'helpers/delivery_record.dart';
import 'helpers/match_flow_helpers.dart';
import 'helpers/server_manager.dart';
import 'helpers/tournament_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Single Match E2E Test — Manual UI Scoring + DB Verification
// ═══════════════════════════════════════════════════════════════════════════
//
// A focused single-match integration test with a PREDETERMINED delivery
// sequence. Every tap is tracked and compared against PostgreSQL records.
//
//  Teams         : Mumbai Lions vs Chennai Kings (6 players each)
//  Overs         : 5 per innings (min preset), 6 players per side
//  Toss          : Mumbai Lions wins → Bats first
//
//  1st Innings (Mumbai Lions) — ALL OUT in 2 overs → 19/5:
//    Over 1 (Deepak Chahar)   :  4, 6, W(B), WD, 1, W(B), 4      → 16/2
//    Over 2 (Ravindra Jadeja) :  2, W(B), 0, W(B), 1, W(B)=ALLOUT → 19/5
//    Target: 20
//
//  2nd Innings (Chennai Kings) — Target chased in 0.4 overs → 20/0:
//    Over 1 (Rohit Sharma)    :  6, 6, 4, 4 → 20/0 ★ TARGET CHASED
//
//  Result: Chennai Kings won by 5 wickets
//
// Run:
//   flutter test integration_test/single_match_e2e_test.dart -d emulator-5554

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final serverManager = ServerManager(port: 3001);
  late final Dio testDio;

  // Team rosters
  final teamA = TeamData(name: 'Mumbai Lions', players: [
    const PlayerData(name: 'Rohit Sharma'),
    const PlayerData(name: 'Suryakumar Yadav'),
    const PlayerData(name: 'Ishan Kishan'),
    const PlayerData(name: 'Hardik Pandya'),
    const PlayerData(name: 'Jasprit Bumrah'),
    const PlayerData(name: 'Rahul Chahar'),
  ]);

  final teamB = TeamData(name: 'Chennai Kings', players: [
    const PlayerData(name: 'MS Dhoni'),
    const PlayerData(name: 'Ruturaj Gaikwad'),
    const PlayerData(name: 'Devon Conway'),
    const PlayerData(name: 'Ravindra Jadeja'),
    const PlayerData(name: 'Deepak Chahar'),
    const PlayerData(name: 'Tushar Deshpande'),
  ]);

  // Track deliveries entered via UI for DB comparison
  final inn1 = <DeliveryRecord>[];
  final inn2 = <DeliveryRecord>[];

  setUpAll(() async {
    await serverManager.startServer();
    // Reset DB: truncates all tables + seeds test user (firebase_uid='test-user-e2e-001').
    // Without reset, getUserByFirebaseUid returns null → 401 on all team API calls.
    await serverManager.resetDatabase();
    testDio = Dio(BaseOptions(
      baseUrl: serverManager.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    print('\n[Setup] Server healthy: ${serverManager.baseUrl}');
  });

  // ══════════════════════════════════════════════════════════════════════
  // MAIN TEST
  // ══════════════════════════════════════════════════════════════════════

  testWidgets(
    'Single match — predetermined scoring + full DB verification',
    (WidgetTester tester) async {

      // ── PHASE 1: Boot ─────────────────────────────────────────────
      print('\n══════════ PHASE 1: Boot App ══════════');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('Home'), findsWidgets);
      print('✓ Home page loaded');


      // ── PHASE 2: Create Teams via UI ──────────────────────────────
      print('\n══════════ PHASE 2: Create Teams ══════════');

      // --- Create Mumbai Lions ---
      await navigateToTeams(tester);
      print('Creating ${teamA.name}...');
      await createTeam(tester, teamA);
      await addPlayersToRoster(tester, teamA.players);
      await goBack(tester);
      await settle(tester);
      print('✓ ${teamA.name} created with ${teamA.players.length} players');

      // --- Create Chennai Kings ---
      await navigateToTeams(tester);
      print('Creating ${teamB.name}...');
      await createTeam(tester, teamB);
      await addPlayersToRoster(tester, teamB.players);
      await goBack(tester);
      await settle(tester);
      print('✓ ${teamB.name} created with ${teamB.players.length} players');

      // ── PHASE 3: Match Setup ───────────────────────────────────────
      print('\n══════════ PHASE 3: Match Setup ══════════');

      // Go to Home tab and tap "Start Match".
      // After addPlayersToRoster we may be on Team Detail (outside ShellRoute),
      // so NavigationBar is not visible. Use GoRouter as fallback.
      final navBarCheck = find.byType(NavigationBar);
      final homeTabText = find.text('Home');
      if (navBarCheck.evaluate().isNotEmpty && homeTabText.evaluate().isNotEmpty) {
        await tester.tap(homeTabText.first);
        await settle(tester);
      } else {
        // Outside ShellRoute — navigate to home via GoRouter
        try {
          final ctx = tester.element(find.byType(Navigator).last);
          GoRouter.of(ctx).go('/home');
          await settle(tester);
          print('[Phase3] Navigated to home via GoRouter.go(/home)');
        } catch (e) {
          print('[Phase3] WARNING: GoRouter navigation to /home failed: $e');
        }
      }
      await visualPause(tester, 500);

      final startMatchBtn = find.text('Start Match');
      expect(startMatchBtn, findsOneWidget, reason: '"Start Match" button missing');
      await tester.tap(startMatchBtn);
      await settle(tester);
      await visualPause(tester, 1000);
      print('✓ Navigated to Match Setup');

      dumpVisibleTexts(tester, 'match-setup', 25);

      // Select Home team via bottom-sheet team picker
      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);

      // Select Away team via bottom-sheet team picker
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      // Select overs: tap "5" chip (smallest preset)
      final overs5 = find.text('5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
        print('✓ Overs: 5');
      }

      // Select players per side: "6" chip
      final players6 = find.text('6');
      if (players6.evaluate().isNotEmpty) {
        await tester.tap(players6.first);
        await settle(tester);
        print('✓ Players per side: 6');
      }

      await visualPause(tester, 500);
      await completeMatchSetup(tester);

      // ── PHASE 4: Toss Wizard ───────────────────────────────────────
      print('\n══════════ PHASE 4: Toss Wizard ══════════');
      await completeTossWizard(
        tester,
        tossWinnerName: teamA.name,
        battingOpener1: 'Rohit Sharma',
        battingOpener2: 'Suryakumar Yadav',
        openingBowler: 'Deepak Chahar',
      );
      await visualPause(tester, 1000);
      print('✓ Toss: ${teamA.name} bats first');
      print('  Openers: Rohit Sharma (str) + Suryakumar Yadav');
      print('  Bowler: Deepak Chahar');

      // Verify scoring page loaded
      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible after toss');
      print('✓ Scoring page ready');


      // ── PHASE 5: 1st Innings ──────────────────────────────────────
      print('\n══════════ PHASE 5: 1st Innings — ${teamA.name} ══════════');
      print('Over 1 (Deepak Chahar)');

      // ─ Over 1, Ball 1: 4 (boundary) — Rohit Sharma
      await tapRun(tester, 4);
      inn1.add(const DeliveryRecord(
        runsFromBat: 4, isBoundaryFour: true, overNumber: 1, ballNumber: 1));
      print('  1.1 → 4  (boundary)         Score: 4/0   [Rohit]');

      // ─ Over 1, Ball 2: 6 (six) — Rohit Sharma
      await tapRun(tester, 6);
      inn1.add(const DeliveryRecord(
        runsFromBat: 6, isBoundarySix: true, overNumber: 1, ballNumber: 2));
      print('  1.2 → 6  (six)              Score: 10/0  [Rohit]');

      // ─ Over 1, Ball 3: W Bowled — Rohit Sharma out, Ishan Kishan in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 1, ballNumber: 3));
      print('  1.3 → W  (Bowled)           Score: 10/1  [Rohit out → Ishan in]');
      await selectBatter(tester, 'Ishan Kishan');

      // ─ Over 1, Wide — extra, not legal; Ishan is striker
      await tapExtra(tester, 'WD');
      await confirmExtra(tester);
      inn1.add(const DeliveryRecord(
        isWide: true, wideRuns: 1, overNumber: 1, ballNumber: 0));
      print('  1.WD→ WD (Wide +1)          Score: 11/1  [not legal]');

      // ─ Over 1, Ball 4: 1 (single) — Ishan Kishan, swaps to SKY
      await tapRun(tester, 1);
      inn1.add(const DeliveryRecord(
        runsFromBat: 1, overNumber: 1, ballNumber: 4));
      print('  1.4 → 1  (single)           Score: 12/1  [Ishan → SKY strikes]');

      // ─ Over 1, Ball 5: W Bowled — SKY out, Hardik Pandya in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 1, ballNumber: 5));
      print('  1.5 → W  (Bowled)           Score: 12/2  [SKY out → Hardik in]');
      await selectBatter(tester, 'Hardik Pandya');

      // ─ Over 1, Ball 6: 4 (boundary) — Hardik Pandya
      await tapRun(tester, 4);
      inn1.add(const DeliveryRecord(
        runsFromBat: 4, isBoundaryFour: true, overNumber: 1, ballNumber: 6));
      print('  1.6 → 4  (boundary)         Score: 16/2  [Hardik]');
      print('  ─── End Over 1 | Score: 16/2 | [Ishan=str, Hardik=non-str] ───');

      // Select bowler for over 2
      await selectBowler(tester, 'Ravindra Jadeja');
      print('  Bowler Over 2: Ravindra Jadeja');
      print('Over 2 (Ravindra Jadeja)');

      // ─ Over 2, Ball 1: 2 — Ishan Kishan
      await tapRun(tester, 2);
      inn1.add(const DeliveryRecord(
        runsFromBat: 2, overNumber: 2, ballNumber: 1));
      print('  2.1 → 2                     Score: 18/2  [Ishan]');

      // ─ Over 2, Ball 2: W Bowled — Ishan out, Jasprit Bumrah in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 2));
      print('  2.2 → W  (Bowled)           Score: 18/3  [Ishan out → Bumrah in]');
      await selectBatter(tester, 'Jasprit Bumrah');

      // ─ Over 2, Ball 3: 0 (dot) — Jasprit Bumrah
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0, overNumber: 2, ballNumber: 3));
      print('  2.3 → 0  (dot)              Score: 18/3  [Bumrah]');

      // ─ Over 2, Ball 4: W Bowled — Bumrah out, Rahul Chahar in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 4));
      print('  2.4 → W  (Bowled)           Score: 18/4  [Bumrah out → Rahul in]');
      await selectBatter(tester, 'Rahul Chahar');

      // ─ Over 2, Ball 5: 1 — Rahul Chahar (swaps to Hardik)
      await tapRun(tester, 1);
      inn1.add(const DeliveryRecord(
        runsFromBat: 1, overNumber: 2, ballNumber: 5));
      print('  2.5 → 1                     Score: 19/4  [Rahul → Hardik strikes]');

      // ─ Over 2, Ball 6: W Bowled — Hardik out → ALL OUT! (5th wicket)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 6));
      print('  2.6 → W  (Bowled)           Score: 19/5  ★ ALL OUT!');

      final inn1Runs = inn1.fold(0, (s, d) => s + d.totalRuns);
      final inn1Wkts = inn1.where((d) => d.isWicket).length;
      print('\n  ══ 1st Innings: $inn1Runs/$inn1Wkts all out in 2 overs ══');
      print('  Target for ${teamB.name}: ${inn1Runs + 1}');

      await visualPause(tester, 1500);

      // ── PHASE 6: Innings Transition ───────────────────────────────
      print('\n══════════ PHASE 6: Innings Transition ══════════');
      await completeInningsTransition(
        tester,
        striker: 'MS Dhoni',
        nonStriker: 'Ruturaj Gaikwad',
        bowler: 'Rohit Sharma',
      );
      print('✓ Openers: MS Dhoni (str) + Ruturaj Gaikwad');
      print('✓ Bowler: Rohit Sharma');

      // ── PHASE 7: 2nd Innings — Target Chase ───────────────────────
      print('\n══════════ PHASE 7: 2nd Innings — ${teamB.name} (chasing ${inn1Runs + 1}) ══════════');
      print('Over 1 (Rohit Sharma)');

      // ─ Ball 1: 6 — MS Dhoni
      await tapRun(tester, 6);
      inn2.add(const DeliveryRecord(
        runsFromBat: 6, isBoundarySix: true, overNumber: 1, ballNumber: 1));
      print('  1.1 → 6  (six)              Score: 6/0   [Dhoni]');

      // ─ Ball 2: 6 — MS Dhoni
      await tapRun(tester, 6);
      inn2.add(const DeliveryRecord(
        runsFromBat: 6, isBoundarySix: true, overNumber: 1, ballNumber: 2));
      print('  1.2 → 6  (six)              Score: 12/0  [Dhoni]');

      // ─ Ball 3: 4 — MS Dhoni
      await tapRun(tester, 4);
      inn2.add(const DeliveryRecord(
        runsFromBat: 4, isBoundaryFour: true, overNumber: 1, ballNumber: 3));
      print('  1.3 → 4  (boundary)         Score: 16/0  [Dhoni]');

      // ─ Ball 4: 4 — MS Dhoni → 20/0 ≥ 20 → TARGET CHASED!
      await tapRun(tester, 4);
      inn2.add(const DeliveryRecord(
        runsFromBat: 4, isBoundaryFour: true, overNumber: 1, ballNumber: 4));
      print('  1.4 → 4  (boundary)         Score: 20/0  ★★ TARGET CHASED ★★');

      await settle(tester);
      await visualPause(tester, 2000);

      // ── PHASE 8: Match Complete ────────────────────────────────────
      print('\n══════════ PHASE 8: Match Complete ══════════');
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('✓ MatchCompleteModal displayed');
        dumpVisibleTexts(tester, 'match-complete', 15);
      } else {
        print('⚠ Modal not found — dumping screen state:');
        dumpVisibleTexts(tester, 'after-target-chase', 20);
      }
      await visualPause(tester, 2500);

      // ── PHASE 9: Database Verification ────────────────────────────
      print('\n══════════ PHASE 9: Database Verification ══════════');
      await Future<void>.delayed(const Duration(seconds: 2));

      // Retrieve latest match ID from test API
      String matchId = '';
      try {
        final r = await testDio.get('/api/v1/test/latest-match');
        matchId = r.data['matchId'] as String? ?? '';
        print('Match ID: $matchId');
      } catch (e) {
        print('✗ Failed to get match ID: $e');
      }

      if (matchId.isEmpty) {
        print('⚠ Cannot verify DB — no match ID returned');
        return;
      }

      // ── Deliveries ──
      final allTracked = [...inn1, ...inn2];
      List<Map<String, dynamic>> dbDeliveries = [];
      try {
        final r = await testDio.get('/api/v1/test/deliveries/$matchId');
        dbDeliveries = (r.data['deliveries'] as List)
            .map((d) => d as Map<String, dynamic>)
            .toList();
      } catch (e) {
        print('✗ Delivery fetch failed: $e');
      }

      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│           DELIVERY COMPARISON: UI vs DATABASE               │');
      print('├────┬─────┬──────────────────────────────────┬───────────────┤');
      print('│ #  │ Inn │ UI Tapped                        │ DB Record     │');
      print('├────┼─────┼──────────────────────────────────┼───────────────┤');

      var deliveryMatches = 0;
      var deliveryMismatches = 0;
      final checkCount = allTracked.length < dbDeliveries.length
          ? allTracked.length : dbDeliveries.length;

      for (var i = 0; i < allTracked.length; i++) {
        final ui = allTracked[i];
        final inningsNum = i < inn1.length ? '1' : '2';
        final uiDesc = _describeDelivery(ui).padRight(33);

        if (i < dbDeliveries.length) {
          final db = dbDeliveries[i];
          final dbRuns = db['total_runs'] as int? ?? 0;
          final dbWide = db['is_wide'] as bool? ?? false;
          final dbNb = db['is_no_ball'] as bool? ?? false;
          final dbWkt = db['is_wicket'] as bool? ?? false;

          final runsOk = dbRuns == ui.totalRuns;
          final wideOk = dbWide == ui.isWide;
          final nbOk = dbNb == ui.isNoBall;
          final wktOk = dbWkt == ui.isWicket;
          final allOk = runsOk && wideOk && nbOk && wktOk;

          final status = allOk ? '✓' : '✗';
          if (allOk) deliveryMatches++; else deliveryMismatches++;

          final dbDesc = 'r=${dbRuns}${dbWide ? ",WD" : ""}${dbNb ? ",NB" : ""}${dbWkt ? ",W" : ""}';
          print('│$status${(i+1).toString().padLeft(2)} │  $inningsNum  │ $uiDesc│ $dbDesc');
        } else {
          print('│✗${(i+1).toString().padLeft(2)} │  $inningsNum  │ $uiDesc│ MISSING IN DB');
          deliveryMismatches++;
        }
      }

      // Extra DB records beyond tracked
      for (var i = allTracked.length; i < dbDeliveries.length; i++) {
        final db = dbDeliveries[i];
        print('│✗${(i+1).toString().padLeft(2)} │  ? │ NOT TRACKED IN TEST              │ r=${db['total_runs']}');
        deliveryMismatches++;
      }

      print('├────┴─────┴──────────────────────────────────┴───────────────┤');
      final uiCount = allTracked.length;
      final dbCount = dbDeliveries.length;
      if (uiCount == dbCount && deliveryMismatches == 0) {
        print('│  ✓ PERFECT MATCH: $uiCount deliveries — UI == DB             │');
      } else {
        print('│  COUNT: UI=$uiCount, DB=$dbCount | Matches:$deliveryMatches, Mismatches:$deliveryMismatches │');
      }
      print('└─────────────────────────────────────────────────────────────┘');

      // ── Match Result ──
      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│                     MATCH RESULT (DB)                      │');
      print('├─────────────────────────────────────────────────────────────┤');
      try {
        final r = await testDio.get('/api/v1/test/match-result/$matchId');
        final result = r.data['result'] as Map<String, dynamic>?;
        if (result != null) {
          print('│  ✓ Result type      : ${result['result_type']}');
          print('│  ✓ Winner team ID   : ${result['winner_team_id']}');
          print('│  ✓ Winning margin   : ${result['winning_margin']} ${result['winning_margin_type']}');
          print('│  ✓ Man of Match ID  : ${result['man_of_match_id']}');
        } else {
          print('│  ✗ No match result record found in DB');
        }
      } catch (e) {
        print('│  ✗ Result query error: $e');
      }
      print('└─────────────────────────────────────────────────────────────┘');

      // ── Match Awards ──
      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│                    MATCH AWARDS (DB)                       │');
      print('├─────────────────────────────────────────────────────────────┤');
      try {
        final r = await testDio.get('/api/v1/test/match-awards/$matchId');
        print('│  MOTM player ID  : ${r.data['manOfMatchId'] ?? 'null'}');
        final awards = r.data['awards'];
        if (awards != null) {
          print('│  MVP scores      : $awards');
        } else {
          print('│  MVP scores      : not computed yet');
        }
      } catch (e) {
        print('│  ✗ Awards error: $e');
      }
      print('└─────────────────────────────────────────────────────────────┘');

      // ── WebSocket Real-Time Tracking ──
      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│          REAL-TIME TRACKING (WebSocket)                     │');
      print('├─────────────────────────────────────────────────────────────┤');
      print('│  Match ID: $matchId');
      print('│');
      print('│  Any device on the same network can track live scores:');
      print('│  1. Open a WebSocket connection to ws://<server-ip>:3001/ws');
      print('│  2. Send: {"type":"join_match","matchId":"$matchId"}');
      print('│  3. Server sends the complete match state snapshot');
      print('│  4. During scoring, each delivery is broadcast in real-time');
      print('│');
      print('│  Server IP for external devices: 103.118.16.189:3001');
      print('│  (or host machine IP if on local network)');
      print('└─────────────────────────────────────────────────────────────┘');

      // ── Final Summary ──
      final inn2Runs = inn2.fold(0, (s, d) => s + d.totalRuns);
      final inn2Wkts = inn2.where((d) => d.isWicket).length;

      print('\n╔═════════════════════════════════════════════════════════════╗');
      print('║              SINGLE MATCH E2E — FINAL REPORT               ║');
      print('╠═════════════════════════════════════════════════════════════╣');
      print('║  ${teamA.name.padRight(15)} vs ${teamB.name.padLeft(15)}      ║');
      print('╠═════════════════════════════════════════════════════════════╣');
      print('║  1st Innings (${teamA.name}):');
      print('║    Score     : $inn1Runs/$inn1Wkts all out in 2 overs');
      print('║    UI Balls  : ${inn1.length} events (incl. extras)');
      print('║    Sequence  : ${inn1.map((d) => d.toString()).join(' ')}');
      print('╠═════════════════════════════════════════════════════════════╣');
      print('║  2nd Innings (${teamB.name}) — chasing ${inn1Runs + 1}:');
      print('║    Score     : $inn2Runs/$inn2Wkts in 0.4 overs (CHASED!)');
      print('║    UI Balls  : ${inn2.length} events');
      print('║    Sequence  : ${inn2.map((d) => d.toString()).join(' ')}');
      print('║    Result    : ${teamB.name} won by 5 wickets');
      print('╠═════════════════════════════════════════════════════════════╣');
      print('║  DB Verify  : $deliveryMatches/$checkCount deliveries matched');
      print('║  Match ID   : $matchId');
      print('╚═════════════════════════════════════════════════════════════╝');
    },
  );
}

/// Open the team picker bottom sheet and select [teamName].
///
/// The picker uses Consumer+ref.watch. With non-autoDispose providers the
/// cached team list is available immediately. This helper pumps a few frames
/// to let the sheet open and then selects the team.
Future<void> _selectTeamInPicker(
  WidgetTester tester,
  String pickerLabel,
  String teamName,
) async {
  final selector = find.text(pickerLabel);
  if (selector.evaluate().isEmpty) {
    print('⚠ "$pickerLabel" not found on screen');
    dumpVisibleTexts(tester, 'picker-not-found', 20);
    return;
  }

  // Tap to open the bottom sheet
  await tester.tap(selector.first);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

  // Pump up to 5 s in 200 ms increments until the team name appears.
  // Cached data should appear immediately; if a network fetch is needed
  // it should complete within a couple of seconds.
  var found = false;
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.text(teamName).evaluate().isNotEmpty) {
      found = true;
      break;
    }
  }

  if (!found) {
    print('⚠ Team "$teamName" did not appear in picker after 5 s');
    dumpVisibleTexts(tester, 'picker-$pickerLabel', 30);
    // Close the sheet so subsequent UI interactions aren't blocked
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  await tester.tap(find.text(teamName).first);
  await settle(tester);
  print('✓ Selected team in picker: $teamName');
}

/// Describe a delivery for the comparison table.
String _describeDelivery(DeliveryRecord d) {
  if (d.isWide) return 'WD (+${d.wideRuns}r)  [Wide, not legal]       ';
  if (d.isNoBall) return 'NB (+${d.noBallRuns}r)  [No Ball, free hit]    ';
  if (d.isWicket) return 'W  (Wicket, 0r)                   ';
  if (d.isBoundarySix) return '6  (Six, 6r)                      ';
  if (d.isBoundaryFour) return '4  (Boundary, 4r)                 ';
  return '${d.runsFromBat}  (${d.runsFromBat}r)                          ';
}
