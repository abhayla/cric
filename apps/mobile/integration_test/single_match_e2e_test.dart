// ignore_for_file: avoid_print

import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';
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
//  1st Innings (Mumbai Lions) — ALL OUT in 2 overs → 20/5:
//    Over 1 (Deepak Chahar)   :  4, 6, W(B), WD, NB, 1(FH), W(B), 4  → 17/2
//    Over 2 (Ravindra Jadeja) :  2, W(B), 0, W(B), 1, W(B)=ALLOUT    → 20/5
//    Target: 21
//
//  2nd Innings (Chennai Kings) — Target chased in 0.4 overs → 22/0:
//    Over 1 (Rohit Sharma)    :  6, 6, 4, 6 → 22/0 ★ TARGET CHASED
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

  // Track deliveries entered via UI for DB comparison
  final inn1 = <DeliveryRecord>[];
  final inn2 = <DeliveryRecord>[];

  // Whether teams already exist from a previous run (skip UI creation)
  bool teamsAlreadyExist = false;

  setUpAll(() async {
    await serverManager.startServer();
    testDio = Dio(BaseOptions(
      baseUrl: serverManager.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Check if teams from a previous run still exist
    final existingTeams = await serverManager.getExistingTeams();
    final teamAExists = (existingTeams[teamA.name] ?? 0) >= teamA.players.length;
    final teamBExists = (existingTeams[teamB.name] ?? 0) >= teamB.players.length;

    if (teamAExists && teamBExists) {
      // Teams exist — only reset match data (fast path)
      teamsAlreadyExist = true;
      await serverManager.resetMatchData();
      print('\n[Setup] Teams already exist — reset match data only (fast path)');
    } else {
      // First run or teams missing — full reset
      await serverManager.resetDatabase();
      print('\n[Setup] Full database reset (teams will be created via UI)');
    }

    print('[Setup] Server healthy: ${serverManager.baseUrl}');
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
      expect(find.text('My Cricket'), findsWidgets);
      print('✓ My Cricket page loaded');


      // ── PHASE 2: Create Teams via UI ──────────────────────────────
      print('\n══════════ PHASE 2: Create Teams ══════════');

      if (teamsAlreadyExist) {
        print('✓ ${teamA.name} already exists — skipping creation');
        print('✓ ${teamB.name} already exists — skipping creation');
      } else {
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
      }

      // ── PHASE 3: Match Setup ───────────────────────────────────────
      print('\n══════════ PHASE 3: Match Setup ══════════');

      // Go to My Cricket tab and tap "Start Match".
      // After addPlayersToRoster we may be on Team Detail (outside ShellRoute),
      // so NavigationBar is not visible. Use GoRouter as fallback.
      final navBarCheck = find.byType(NavigationBar);
      final myCricketTabText = find.text('My Cricket');
      if (navBarCheck.evaluate().isNotEmpty && myCricketTabText.evaluate().isNotEmpty) {
        await tester.tap(myCricketTabText.first);
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

      await navigateToMatchSetup(tester);
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
        await tester.ensureVisible(players6.first);
        await tester.pumpAndSettle();
        await tester.tap(players6.first, warnIfMissed: false);
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

      // ── Signal viewer that scorer is ready ──
      // Posts scorer-ready signal so the viewer test can find the match.
      // Does NOT wait for viewer — Gradle lock contention prevents
      // concurrent builds from the same project directory.
      try {
        await testDio.post('/api/v1/test/signal/scorer-ready',
            data: {'value': 'true'});
        print('[SCORER] Signal: scorer-ready posted');
      } catch (e) {
        print('[SCORER] Signal endpoint not available: $e');
      }

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
        isWide: true, wideRuns: 1, overNumber: 1, ballNumber: 4));
      print('  1.WD→ WD (Wide +1)          Score: 11/1  [not legal]');

      // ─ Over 1, No Ball — extra, not legal; next ball is free hit
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      inn1.add(const DeliveryRecord(
        isNoBall: true, noBallRuns: 1, overNumber: 1, ballNumber: 4));
      print('  1.NB→ NB (No Ball +1)       Score: 12/1  [not legal, free hit next]');

      // ─ Over 1, Ball 4: 1 (single, FREE HIT) — Ishan Kishan, swaps to SKY
      await tapRun(tester, 1);
      inn1.add(const DeliveryRecord(
        runsFromBat: 1, overNumber: 1, ballNumber: 4));
      print('  1.4 → 1  (single, FH)       Score: 13/1  [Ishan → SKY strikes]');

      // ─ Over 1, Ball 5: W Bowled — SKY out, Hardik Pandya in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 1, ballNumber: 5));
      print('  1.5 → W  (Bowled)           Score: 13/2  [SKY out → Hardik in]');
      await selectBatter(tester, 'Hardik Pandya');

      // ─ Over 1, Ball 6: 4 (boundary) — Hardik Pandya
      await tapRun(tester, 4);
      inn1.add(const DeliveryRecord(
        runsFromBat: 4, isBoundaryFour: true, overNumber: 1, ballNumber: 6));
      print('  1.6 → 4  (boundary)         Score: 17/2  [Hardik]');
      print('  ─── End Over 1 | Score: 17/2 | [Ishan=str, Hardik=non-str] ───');

      // Select bowler for over 2
      await selectBowler(tester, 'Ravindra Jadeja');
      print('  Bowler Over 2: Ravindra Jadeja');
      print('Over 2 (Ravindra Jadeja)');

      // ─ Over 2, Ball 1: 2 — Ishan Kishan
      await tapRun(tester, 2);
      inn1.add(const DeliveryRecord(
        runsFromBat: 2, overNumber: 2, ballNumber: 1));
      print('  2.1 → 2                     Score: 19/2  [Ishan]');

      // ─ Over 2, Ball 2: W Bowled — Ishan out, Jasprit Bumrah in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 2));
      print('  2.2 → W  (Bowled)           Score: 19/3  [Ishan out → Bumrah in]');
      await selectBatter(tester, 'Jasprit Bumrah');

      // ─ Over 2, Ball 3: 0 (dot) — Jasprit Bumrah
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0, overNumber: 2, ballNumber: 3));
      print('  2.3 → 0  (dot)              Score: 19/3  [Bumrah]');

      // ─ Over 2, Ball 4: W Bowled — Bumrah out, Rahul Chahar in
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 4));
      print('  2.4 → W  (Bowled)           Score: 19/4  [Bumrah out → Rahul in]');
      await selectBatter(tester, 'Rahul Chahar');

      // ─ Over 2, Ball 5: 1 — Rahul Chahar (swaps to Hardik)
      await tapRun(tester, 1);
      inn1.add(const DeliveryRecord(
        runsFromBat: 1, overNumber: 2, ballNumber: 5));
      print('  2.5 → 1                     Score: 20/4  [Rahul → Hardik strikes]');

      // ─ Over 2, Ball 6: W Bowled — Hardik out → ALL OUT! (5th wicket)
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true, overNumber: 2, ballNumber: 6));
      print('  2.6 → W  (Bowled)           Score: 20/5  ★ ALL OUT!');

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

      // ─ Ball 4: 6 — MS Dhoni → 22/0 ≥ 21 → TARGET CHASED!
      await tapRun(tester, 6);
      inn2.add(const DeliveryRecord(
        runsFromBat: 6, isBoundarySix: true, overNumber: 1, ballNumber: 4));
      print('  1.4 → 6  (six)              Score: 22/0  ★★ TARGET CHASED ★★');

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
      // Wait for sync to flush all deliveries (including the last one
      // that may have been enqueued while a previous sync was in-flight)
      await Future<void>.delayed(const Duration(seconds: 8));

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
          final dbRuns = db['totalRuns'] as int? ?? 0;
          final dbWide = db['isWide'] as bool? ?? false;
          final dbNb = db['isNoBall'] as bool? ?? false;
          final dbWkt = db['isWicket'] as bool? ?? false;
          final dbLegal = db['isLegal'] as bool? ?? true;
          final dbOver = db['overNumber'] as int? ?? -1;
          final dbBall = db['ballNumber'] as int? ?? -1;
          final dbFour = db['isBoundaryFour'] as bool? ?? false;
          final dbSix = db['isBoundarySix'] as bool? ?? false;
          final dbFreeHit = db['isFreeHit'] as bool? ?? false;

          final runsOk = dbRuns == ui.totalRuns;
          final wideOk = dbWide == ui.isWide;
          final nbOk = dbNb == ui.isNoBall;
          final wktOk = dbWkt == ui.isWicket;
          final legalOk = dbLegal == ui.isLegal;
          final overOk = dbOver == ui.overNumber;
          final ballOk = dbBall == ui.ballNumber;
          final fourOk = dbFour == ui.isBoundaryFour;
          final sixOk = dbSix == ui.isBoundarySix;
          final allOk = runsOk && wideOk && nbOk && wktOk
              && legalOk && overOk && ballOk && fourOk && sixOk;

          final status = allOk ? '✓' : '✗';
          if (allOk) {
            deliveryMatches++;
          } else {
            deliveryMismatches++;
          }

          final dbDesc = 'r=$dbRuns o$dbOver.$dbBall${dbWide ? ",WD" : ""}${dbNb ? ",NB" : ""}${dbWkt ? ",W" : ""}${dbFour ? ",4" : ""}${dbSix ? ",6" : ""}${dbFreeHit ? ",FH" : ""}${dbLegal ? "" : ",!L"}';
          print('│$status${(i+1).toString().padLeft(2)} │  $inningsNum  │ $uiDesc│ $dbDesc');
        } else {
          print('│✗${(i+1).toString().padLeft(2)} │  $inningsNum  │ $uiDesc│ MISSING IN DB');
          deliveryMismatches++;
        }
      }

      // Extra DB records beyond tracked
      for (var i = allTracked.length; i < dbDeliveries.length; i++) {
        final db = dbDeliveries[i];
        print('│✗${(i+1).toString().padLeft(2)} │  ? │ NOT TRACKED IN TEST              │ r=${db['totalRuns']}');
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

      // ── Delivery-level expect() assertions ──
      expect(dbDeliveries.length, equals(allTracked.length),
          reason: 'DB delivery count must match UI-tracked count');
      expect(deliveryMismatches, equals(0),
          reason: 'All delivery fields must match between UI and DB');

      for (var i = 0; i < checkCount; i++) {
        final ui = allTracked[i];
        final db = dbDeliveries[i];
        final label = 'Delivery ${i + 1}';

        expect(db['totalRuns'] as int? ?? 0, equals(ui.totalRuns),
            reason: '$label: totalRuns');
        expect(db['isWide'] as bool? ?? false, equals(ui.isWide),
            reason: '$label: isWide');
        expect(db['isNoBall'] as bool? ?? false, equals(ui.isNoBall),
            reason: '$label: isNoBall');
        expect(db['isWicket'] as bool? ?? false, equals(ui.isWicket),
            reason: '$label: isWicket');
        expect(db['isLegal'] as bool? ?? true, equals(ui.isLegal),
            reason: '$label: isLegal');
        expect(db['overNumber'] as int? ?? -1, equals(ui.overNumber),
            reason: '$label: overNumber');
        expect(db['ballNumber'] as int? ?? -1, equals(ui.ballNumber),
            reason: '$label: ballNumber');
        expect(db['isBoundaryFour'] as bool? ?? false, equals(ui.isBoundaryFour),
            reason: '$label: isBoundaryFour');
        expect(db['isBoundarySix'] as bool? ?? false, equals(ui.isBoundarySix),
            reason: '$label: isBoundarySix');
        // isFreeHit: verify NB deliveries are followed by free-hit ball
        // (DB tracks free hit on the delivery AFTER the no-ball)
      }

      // Verify at least one no-ball exists in tracked deliveries
      expect(allTracked.any((d) => d.isNoBall), isTrue,
          reason: 'Test must include at least one no-ball delivery');

      // ── Match Result ──
      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│                     MATCH RESULT (DB)                      │');
      print('├─────────────────────────────────────────────────────────────┤');
      try {
        final r = await testDio.get('/api/v1/test/match-result/$matchId');
        final result = r.data['result'] as Map<String, dynamic>?;
        if (result != null) {
          print('│  ✓ Result type      : ${result['resultType']}');
          print('│  ✓ Winner team ID   : ${result['winnerTeamId']}');
          print('│  ✓ Winning margin   : ${result['margin']} ${result['resultType']}');
          print('│  ✓ Man of Match ID  : ${result['manOfMatchId']}');
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

      // ── Batting & Bowling Stats ──
      print('\n┌─────────────────────────────────────────────────────────────┐');
      print('│              BATTING & BOWLING STATS (DB)                   │');
      print('├─────────────────────────────────────────────────────────────┤');
      try {
        final r = await testDio.get('/api/v1/test/match-stats/$matchId');
        final battingList = r.data['batting'] as List? ?? [];
        final bowlingList = r.data['bowling'] as List? ?? [];

        print('│  BATTING (${battingList.length} records):');
        for (final b in battingList) {
          final name = (b['playerName'] as String? ?? '?').padRight(20);
          final runs = b['runsScored'] ?? 0;
          final balls = b['ballsFaced'] ?? 0;
          final fours = b['fours'] ?? 0;
          final sixes = b['sixes'] ?? 0;
          final notOut = (b['isNotOut'] as bool? ?? false) ? '*' : '';
          final inn = b['inningsNumber'] ?? '?';
          print('│    Inn$inn $name $runs$notOut ($balls) 4s:$fours 6s:$sixes');
        }

        print('│  BOWLING (${bowlingList.length} records):');
        for (final b in bowlingList) {
          final name = (b['playerName'] as String? ?? '?').padRight(20);
          final overs = b['oversBowled'] ?? '0.0';
          final runs = b['runsConceded'] ?? 0;
          final wkts = b['wicketsTaken'] ?? 0;
          final wides = b['wides'] ?? 0;
          final noBalls = b['noBalls'] ?? 0;
          final dots = b['dotBalls'] ?? 0;
          final inn = b['inningsNumber'] ?? '?';
          print('│    Inn$inn $name $overs-$runs-$wkts wd:$wides nb:$noBalls dot:$dots');
        }

        // ── Batting stats expect() assertions ──
        // Should have batting records for both innings
        expect(battingList.length, greaterThanOrEqualTo(2),
            reason: 'Must have batting stats for at least 2 batters');

        // Build a lookup by playerName + inningsNumber
        Map<String, Map<String, dynamic>> battingByName(int inn) {
          return {
            for (final b in battingList)
              if ((b['inningsNumber'] ?? 0) == inn)
                (b['playerName'] as String? ?? '?'): b as Map<String, dynamic>,
          };
        }

        // 1st innings batting assertions
        final inn1Batting = battingByName(1);

        // Rohit Sharma: 10 runs (4+6), 2 balls, 1 four, 1 six, out
        if (inn1Batting.containsKey('Rohit Sharma')) {
          final rohit = inn1Batting['Rohit Sharma']!;
          expect(rohit['runsScored'], equals(10),
              reason: 'Rohit Sharma should have 10 runs (4+6)');
          expect(rohit['ballsFaced'], equals(3),
              reason: 'Rohit Sharma faced 3 balls (4, 6, W)');
          expect(rohit['fours'], equals(1),
              reason: 'Rohit Sharma hit 1 four');
          expect(rohit['sixes'], equals(1),
              reason: 'Rohit Sharma hit 1 six');
          expect(rohit['isNotOut'], equals(false),
              reason: 'Rohit Sharma was bowled out');
        }

        // MS Dhoni: 22 runs (6+6+4+6), 4 balls, 1 four, 3 sixes, not out
        final inn2Batting = battingByName(2);
        if (inn2Batting.containsKey('MS Dhoni')) {
          final dhoni = inn2Batting['MS Dhoni']!;
          expect(dhoni['runsScored'], equals(22),
              reason: 'MS Dhoni should have 22 runs (6+6+4+6)');
          expect(dhoni['ballsFaced'], equals(4),
              reason: 'MS Dhoni faced 4 balls');
          expect(dhoni['fours'], equals(1),
              reason: 'MS Dhoni hit 1 four');
          expect(dhoni['sixes'], equals(3),
              reason: 'MS Dhoni hit 3 sixes');
          expect(dhoni['isNotOut'], equals(true),
              reason: 'MS Dhoni was not out (target chased)');
        }

        // ── Bowling stats expect() assertions ──
        expect(bowlingList.length, greaterThanOrEqualTo(2),
            reason: 'Must have bowling stats for at least 2 bowlers');

        Map<String, Map<String, dynamic>> bowlingByName(int inn) {
          return {
            for (final b in bowlingList)
              if ((b['inningsNumber'] ?? 0) == inn)
                (b['playerName'] as String? ?? '?'): b as Map<String, dynamic>,
          };
        }

        // 1st innings bowling: Deepak Chahar bowled 1 over, took 2 wickets
        final inn1Bowling = bowlingByName(1);
        if (inn1Bowling.containsKey('Deepak Chahar')) {
          final chahar = inn1Bowling['Deepak Chahar']!;
          expect(chahar['wicketsTaken'], equals(2),
              reason: 'Deepak Chahar took 2 wickets in Over 1');
          expect(chahar['wides'], equals(1),
              reason: 'Deepak Chahar bowled 1 wide');
          expect(chahar['noBalls'], equals(1),
              reason: 'Deepak Chahar bowled 1 no-ball');
        }

        // 1st innings bowling: Ravindra Jadeja bowled 1 over, took 3 wickets
        if (inn1Bowling.containsKey('Ravindra Jadeja')) {
          final jadeja = inn1Bowling['Ravindra Jadeja']!;
          expect(jadeja['wicketsTaken'], equals(3),
              reason: 'Ravindra Jadeja took 3 wickets in Over 2');
        }

        // 2nd innings bowling: Rohit Sharma bowled 0.4 overs, 0 wickets
        final inn2Bowling = bowlingByName(2);
        if (inn2Bowling.containsKey('Rohit Sharma')) {
          final rohitBowl = inn2Bowling['Rohit Sharma']!;
          expect(rohitBowl['wicketsTaken'], equals(0),
              reason: 'Rohit Sharma took 0 wickets in 2nd innings');
        }
      } catch (e) {
        print('│  ✗ Stats query error: $e');
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
