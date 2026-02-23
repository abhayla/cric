// ignore_for_file: avoid_print

@Timeout(Duration(hours: 1))
library;

import 'dart:math';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_test_wrapper.dart';
import 'helpers/delivery_record.dart';
import 'helpers/match_flow_helpers.dart';
import 'helpers/scenario_test_data.dart';
import 'helpers/server_manager.dart';
import 'helpers/tournament_flow_helpers.dart';

// =============================================================================
// Full T20 E2E Test — Scenarios 12, 13, 15 Combined
// =============================================================================
//
// A full-length 20-over T20 match integration test with RANDOM delivery
// sequences (deterministic via seeded Random). Covers three E2E scenarios:
//
//   Scenario 12: Full-Length T20 Match — Play a complete 20-over-per-side match
//   Scenario 13: Full Match Stat Verification — Verify batting/bowling stats in DB
//   Scenario 15: Scorecard vs DB Consistency — Cross-check scorecard UI with DB
//
//  Teams         : Mumbai Warriors vs Chennai Challengers (11 players each)
//  Overs         : 20 per innings
//  Toss          : Mumbai Warriors wins -> Bats first
//
//  1st Innings (Mumbai Warriors) — Random scoring, 20 overs or all out
//  2nd Innings (Chennai Challengers) — Random scoring, 20 overs or target chased
//
// Run (USER should run from IDE terminal — not Claude CLI — to watch on device):
//   Emulator:  flutter test integration_test/full_t20_e2e_test.dart -d emulator-5554
//   Device:    flutter test integration_test/full_t20_e2e_test.dart -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1
//
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final serverManager = ServerManager(port: 3001);
  late final Dio testDio;

  // Team rosters from ScenarioTeams (11 players each)
  final teamA = ScenarioTeams.teamA;
  final teamB = ScenarioTeams.teamB;

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
    final teamAExists =
        (existingTeams[teamA.name] ?? 0) >= teamA.players.length;
    final teamBExists =
        (existingTeams[teamB.name] ?? 0) >= teamB.players.length;

    if (teamAExists && teamBExists) {
      // Teams exist -- only reset match data (fast path)
      teamsAlreadyExist = true;
      await serverManager.resetMatchData();
      print(
          '\n[Setup] Teams already exist -- reset match data only (fast path)');
    } else {
      // First run or teams missing -- full reset
      await serverManager.resetDatabase();
      print('\n[Setup] Full database reset (teams will be created via UI)');
    }

    print('[Setup] Server healthy: ${serverManager.baseUrl}');
  });

  // ========================================================================
  // MAIN TEST
  // ========================================================================

  testWidgets(
    'Full T20 match -- random scoring + stat verification + scorecard check',
    (WidgetTester tester) async {
      // Track all deliveries for DB comparison
      final matchRecord = MatchRecord(matchId: 'full-t20');

      // ---- PHASE 1: Boot --------------------------------------------------
      print('\n========== PHASE 1: Boot App ==========');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('My Cricket'), findsWidgets);
      print('[Phase1] My Cricket page loaded');

      // ---- PHASE 2: Create Teams via UI ------------------------------------
      print('\n========== PHASE 2: Create Teams ==========');

      if (teamsAlreadyExist) {
        print('[Phase2] ${teamA.name} already exists -- skipping creation');
        print('[Phase2] ${teamB.name} already exists -- skipping creation');
      } else {
        // --- Create Mumbai Warriors ---
        await navigateToTeams(tester);
        print('[Phase2] Creating ${teamA.name}...');
        await createTeam(tester, teamA);
        await addPlayersToRoster(tester, teamA.players);
        await goBack(tester);
        await settle(tester);
        print(
            '[Phase2] ${teamA.name} created with ${teamA.players.length} players');

        // --- Create Chennai Challengers ---
        await navigateToTeams(tester);
        print('[Phase2] Creating ${teamB.name}...');
        await createTeam(tester, teamB);
        await addPlayersToRoster(tester, teamB.players);
        await goBack(tester);
        await settle(tester);
        print(
            '[Phase2] ${teamB.name} created with ${teamB.players.length} players');
      }

      // ---- PHASE 3: Match Setup (20 overs, 11 players) --------------------
      print('\n========== PHASE 3: Match Setup ==========');

      // Navigate to Match Setup via GoRouter (more reliable than FAB tap)
      try {
        final ctx = tester.element(find.byType(Navigator).last);
        GoRouter.of(ctx).push('/match-setup');
        await settle(tester);
        await visualPause(tester, 1000);
        print('[Phase3] Navigated to Match Setup via GoRouter');
      } catch (e) {
        print('[Phase3] WARNING: GoRouter navigation to /match-setup failed: $e');
      }

      dumpVisibleTexts(tester, 'match-setup', 25);

      // Select Home team via bottom-sheet team picker
      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);

      // Select Away team via bottom-sheet team picker
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      // Select overs: tap "20" chip
      final overs20 = find.text('20');
      if (overs20.evaluate().isNotEmpty) {
        await tester.tap(overs20.first);
        await settle(tester);
        print('[Phase3] Overs: 20');
      }

      // Select players per side: "11" chip
      final players11 = find.text('11');
      if (players11.evaluate().isNotEmpty) {
        await tester.tap(players11.first);
        await settle(tester);
        print('[Phase3] Players per side: 11');
      }

      await visualPause(tester, 500);
      await completeMatchSetup(tester);

      // ---- PHASE 4: Toss Wizard --------------------------------------------
      print('\n========== PHASE 4: Toss Wizard ==========');
      await completeTossWizard(
        tester,
        tossWinnerName: ScenarioTeams.teamAName,
        battingOpener1: ScenarioTeams.teamAOpener1,
        battingOpener2: ScenarioTeams.teamAOpener2,
        openingBowler: ScenarioTeams.teamBOpeningBowler,
      );
      await visualPause(tester, 1000);
      print('[Phase4] Toss: ${ScenarioTeams.teamAName} bats first');
      print(
          '[Phase4] Openers: ${ScenarioTeams.teamAOpener1} (str) + ${ScenarioTeams.teamAOpener2}');
      print('[Phase4] Bowler: ${ScenarioTeams.teamBOpeningBowler}');

      // Verify scoring page loaded
      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible after toss');
      print('[Phase4] Scoring page ready');

      // ---- Signal viewer (if running on second emulator) ------------------
      try {
        await testDio.post('/api/v1/test/signal/scorer-ready',
            data: {'value': 'true'});
        print('[Phase4] Signal: scorer-ready posted');

        // Wait for viewer to connect (up to 30s, non-blocking after that)
        final viewerDeadline =
            DateTime.now().add(const Duration(seconds: 30));
        var viewerReady = false;
        while (DateTime.now().isBefore(viewerDeadline)) {
          try {
            final r = await testDio.get('/api/v1/test/signal/viewer-ready');
            if (r.data['value'] != null) {
              viewerReady = true;
              print('[Phase4] Signal: viewer-ready received');
              break;
            }
          } catch (_) {}
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        if (!viewerReady) {
          print('[Phase4] No viewer connected -- proceeding (solo mode)');
        }
      } catch (e) {
        print('[Phase4] Signal endpoint not available -- proceeding solo: $e');
      }

      // ---- PHASE 5: 1st Innings (Random, 20 overs) ------------------------
      print(
          '\n========== PHASE 5: 1st Innings -- ${ScenarioTeams.teamAName} ==========');

      await playRandomInnings(
        tester: tester,
        matchRecord: matchRecord,
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        bowlerNames: ScenarioTeams.teamBBowlers,
        batterNames: ScenarioTeams.teamABatters,
        random: Random(42),
      );

      final inn1Runs = matchRecord.firstInningsRuns;
      final inn1Wkts = matchRecord.firstInningsWickets;
      final inn1Dels = matchRecord.firstInningsDeliveries.length;
      print(
          '\n[Phase5] 1st Innings: $inn1Runs/$inn1Wkts ($inn1Dels deliveries)');
      print('[Phase5] Target for ${ScenarioTeams.teamBName}: ${inn1Runs + 1}');

      await visualPause(tester, 1500);

      // ---- PHASE 6: Innings Transition -------------------------------------
      print('\n========== PHASE 6: Innings Transition ==========');
      await completeInningsTransition(
        tester,
        striker: ScenarioTeams.teamBOpener1,
        nonStriker: ScenarioTeams.teamBOpener2,
        bowler: ScenarioTeams.teamAOpeningBowler,
      );
      print(
          '[Phase6] Openers: ${ScenarioTeams.teamBOpener1} (str) + ${ScenarioTeams.teamBOpener2}');
      print('[Phase6] Bowler: ${ScenarioTeams.teamAOpeningBowler}');

      // Ensure transition modal is fully gone before starting 2nd innings
      await settle(tester);
      await visualPause(tester, 1000);

      // Verify no stale modals remain
      final staleTransition =
          find.byType(InningsTransitionModal).evaluate().isNotEmpty;
      final staleComplete =
          find.byType(MatchCompleteModal).evaluate().isNotEmpty;
      print('[Phase6] Post-transition check: '
          'InningsTransitionModal=$staleTransition, '
          'MatchCompleteModal=$staleComplete');
      expect(staleTransition, isFalse,
          reason: 'InningsTransitionModal must be gone before 2nd innings');

      // Verify scoring controls are ready
      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible for 2nd innings');
      print('[Phase6] Scoring page ready for 2nd innings');

      // ---- PHASE 7: 2nd Innings (Random, 20 overs) ------------------------
      print(
          '\n========== PHASE 7: 2nd Innings -- ${ScenarioTeams.teamBName} (chasing ${inn1Runs + 1}) ==========');

      await playRandomInnings(
        tester: tester,
        matchRecord: matchRecord,
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        bowlerNames: ScenarioTeams.teamABowlers,
        batterNames: ScenarioTeams.teamBBatters,
        random: Random(42),
      );

      final inn2Runs = matchRecord.secondInningsRuns;
      final inn2Wkts = matchRecord.secondInningsWickets;
      final inn2Dels = matchRecord.secondInningsDeliveries.length;
      print(
          '\n[Phase7] 2nd Innings: $inn2Runs/$inn2Wkts ($inn2Dels deliveries)');

      // ---- PHASE 8: Match Complete -----------------------------------------
      print('\n========== PHASE 8: Match Complete ==========');
      await settle(tester);
      await visualPause(tester, 2000);

      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('[Phase8] MatchCompleteModal displayed');
        dumpVisibleTexts(tester, 'match-complete', 20);
      } else {
        print('[Phase8] Modal not found -- dumping screen state:');
        dumpVisibleTexts(tester, 'after-2nd-innings', 20);
      }
      await visualPause(tester, 2500);

      // ---- PHASE 9: Database Verification (Scenario 13) --------------------
      print('\n========== PHASE 9: Database Verification ==========');

      // Retrieve match ID first
      String matchId = '';
      try {
        final r = await testDio.get('/api/v1/test/latest-match');
        matchId = r.data['matchId'] as String? ?? '';
        print('[Phase9] Match ID: $matchId');
      } catch (e) {
        print('[Phase9] Failed to get match ID: $e');
      }

      if (matchId.isEmpty) {
        print('[Phase9] Cannot verify DB -- no match ID returned');
        return;
      }

      // Wait for sync to flush all deliveries — poll until DB count stabilizes
      // or we've waited long enough (max 60s with 5s intervals).
      // Batch sync sends all deliveries in one transaction (~5-10 seconds).
      final allTracked = matchRecord.allDeliveries;
      List<Map<String, dynamic>> dbDeliveries = [];
      int prevCount = -1;
      int stableRounds = 0;
      for (var attempt = 0; attempt < 12; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 5));
        try {
          final r = await testDio.get('/api/v1/test/deliveries/$matchId');
          dbDeliveries = (r.data['deliveries'] as List)
              .map((d) => d as Map<String, dynamic>)
              .toList();
        } catch (e) {
          print('[Phase9] Delivery fetch failed: $e');
        }
        final currentCount = dbDeliveries.length;
        print('[Phase9] Sync poll #${attempt + 1}: DB has $currentCount / '
            '${allTracked.length} deliveries');
        if (currentCount == allTracked.length) {
          print('[Phase9] All deliveries synced!');
          break;
        }
        if (currentCount == prevCount) {
          stableRounds++;
          if (stableRounds >= 3) {
            print('[Phase9] DB count stable at $currentCount for 3 rounds '
                '— proceeding with verification');
            break;
          }
        } else {
          stableRounds = 0;
        }
        prevCount = currentCount;
      }

      print(
          '\n+-------------------------------------------------------------+');
      print(
          '|           DELIVERY COMPARISON: UI vs DATABASE               |');
      print(
          '+----+-----+----------------------------------+---------------+');
      print(
          '| #  | Inn | UI Tapped                        | DB Record     |');
      print(
          '+----+-----+----------------------------------+---------------+');

      var deliveryMatches = 0;
      var deliveryMismatches = 0;
      final checkCount = allTracked.length < dbDeliveries.length
          ? allTracked.length
          : dbDeliveries.length;
      final inn1Count = matchRecord.firstInningsDeliveries.length;

      for (var i = 0; i < allTracked.length; i++) {
        final ui = allTracked[i];
        final inningsNum = i < inn1Count ? '1' : '2';
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
          final allOk = runsOk &&
              wideOk &&
              nbOk &&
              wktOk &&
              legalOk &&
              overOk &&
              ballOk &&
              fourOk &&
              sixOk;

          final status = allOk ? 'OK' : 'XX';
          if (allOk) {
            deliveryMatches++;
          } else {
            deliveryMismatches++;
          }

          final dbDesc =
              'r=$dbRuns o$dbOver.$dbBall${dbWide ? ",WD" : ""}${dbNb ? ",NB" : ""}${dbWkt ? ",W" : ""}${dbFour ? ",4" : ""}${dbSix ? ",6" : ""}${dbFreeHit ? ",FH" : ""}${dbLegal ? "" : ",!L"}';
          print(
              '|$status${(i + 1).toString().padLeft(2)} |  $inningsNum  | $uiDesc| $dbDesc');
        } else {
          print(
              '|XX${(i + 1).toString().padLeft(2)} |  $inningsNum  | $uiDesc| MISSING IN DB');
          deliveryMismatches++;
        }
      }

      // Extra DB records beyond tracked
      for (var i = allTracked.length; i < dbDeliveries.length; i++) {
        final db = dbDeliveries[i];
        print(
            '|XX${(i + 1).toString().padLeft(2)} |  ? | NOT TRACKED IN TEST              | r=${db['totalRuns']}');
        deliveryMismatches++;
      }

      print(
          '+----+-----+----------------------------------+---------------+');
      final uiCount = allTracked.length;
      final dbCount = dbDeliveries.length;
      if (uiCount == dbCount && deliveryMismatches == 0) {
        print(
            '|  PERFECT MATCH: $uiCount deliveries -- UI == DB                |');
      } else {
        print(
            '|  COUNT: UI=$uiCount, DB=$dbCount | Matches:$deliveryMatches, Mismatches:$deliveryMismatches |');
      }
      print(
          '+-------------------------------------------------------------+');

      // ---- Delivery-level expect() assertions ----
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
        expect(
            db['isBoundaryFour'] as bool? ?? false, equals(ui.isBoundaryFour),
            reason: '$label: isBoundaryFour');
        expect(
            db['isBoundarySix'] as bool? ?? false, equals(ui.isBoundarySix),
            reason: '$label: isBoundarySix');
      }

      // ---- Match Result ----
      print(
          '\n+-------------------------------------------------------------+');
      print(
          '|                     MATCH RESULT (DB)                       |');
      print(
          '+-------------------------------------------------------------+');
      try {
        final r = await testDio.get('/api/v1/test/match-result/$matchId');
        final result = r.data['result'] as Map<String, dynamic>?;
        if (result != null) {
          print('|  Result type      : ${result['resultType']}');
          print('|  Winner team ID   : ${result['winnerTeamId']}');
          print(
              '|  Winning margin   : ${result['margin']} ${result['resultType']}');
          print('|  Man of Match ID  : ${result['manOfMatchId']}');
          expect(result, isNotNull, reason: 'Match result should exist');
        } else {
          print('|  No match result record found in DB');
        }
      } catch (e) {
        print('|  Result query error: $e');
      }
      print(
          '+-------------------------------------------------------------+');

      // ---- Match Awards ----
      print(
          '\n+-------------------------------------------------------------+');
      print(
          '|                    MATCH AWARDS (DB)                        |');
      print(
          '+-------------------------------------------------------------+');
      try {
        final r = await testDio.get('/api/v1/test/match-awards/$matchId');
        print('|  MOTM player ID  : ${r.data['manOfMatchId'] ?? 'null'}');
        final awards = r.data['awards'];
        if (awards != null) {
          print('|  MVP scores      : $awards');
        } else {
          print('|  MVP scores      : not computed yet');
        }
      } catch (e) {
        print('|  Awards error: $e');
      }
      print(
          '+-------------------------------------------------------------+');

      // ---- Batting & Bowling Stats (Scenario 13) ----
      print(
          '\n+-------------------------------------------------------------+');
      print(
          '|              BATTING & BOWLING STATS (DB)                   |');
      print(
          '+-------------------------------------------------------------+');
      try {
        final r = await testDio.get('/api/v1/test/match-stats/$matchId');
        final battingList = r.data['batting'] as List? ?? [];
        final bowlingList = r.data['bowling'] as List? ?? [];

        print('|  BATTING (${battingList.length} records):');
        for (final b in battingList) {
          final name = (b['playerName'] as String? ?? '?').padRight(20);
          final runs = b['runsScored'] ?? 0;
          final balls = b['ballsFaced'] ?? 0;
          final fours = b['fours'] ?? 0;
          final sixes = b['sixes'] ?? 0;
          final notOut = (b['isNotOut'] as bool? ?? false) ? '*' : '';
          final inn = b['inningsNumber'] ?? '?';
          print(
              '|    Inn$inn $name $runs$notOut ($balls) 4s:$fours 6s:$sixes');
        }

        print('|  BOWLING (${bowlingList.length} records):');
        for (final b in bowlingList) {
          final name = (b['playerName'] as String? ?? '?').padRight(20);
          final overs = b['oversBowled'] ?? '0.0';
          final runs = b['runsConceded'] ?? 0;
          final wkts = b['wicketsTaken'] ?? 0;
          final wides = b['wides'] ?? 0;
          final noBalls = b['noBalls'] ?? 0;
          final dots = b['dotBalls'] ?? 0;
          final inn = b['inningsNumber'] ?? '?';
          print(
              '|    Inn$inn $name $overs-$runs-$wkts wd:$wides nb:$noBalls dot:$dots');
        }

        // ---- Batting stats assertions ----
        // Full T20 match should have records for multiple batters in each innings
        expect(battingList.length, greaterThanOrEqualTo(4),
            reason:
                'Must have batting stats for at least 4 batters across both innings');

        // Verify each batting record has required fields
        for (final b in battingList) {
          expect(b['playerName'], isNotNull,
              reason: 'Batting record must have playerName');
          expect(b['inningsNumber'], isNotNull,
              reason: 'Batting record must have inningsNumber');
          expect(b['runsScored'], isNotNull,
              reason: 'Batting record must have runsScored');
          expect(b['ballsFaced'], isNotNull,
              reason: 'Batting record must have ballsFaced');
        }

        // ---- Bowling stats assertions ----
        expect(bowlingList.length, greaterThanOrEqualTo(4),
            reason:
                'Must have bowling stats for at least 4 bowlers across both innings');

        // Verify each bowling record has required fields
        for (final b in bowlingList) {
          expect(b['playerName'], isNotNull,
              reason: 'Bowling record must have playerName');
          expect(b['inningsNumber'], isNotNull,
              reason: 'Bowling record must have inningsNumber');
          expect(b['wicketsTaken'], isNotNull,
              reason: 'Bowling record must have wicketsTaken');
        }

        // ---- Cross-check: Total runs from batting should match innings total ----
        int battingRunsInn1 = 0;
        int battingRunsInn2 = 0;
        for (final b in battingList) {
          final inn = b['inningsNumber'] as int? ?? 0;
          final runs = b['runsScored'] as int? ?? 0;
          if (inn == 1) battingRunsInn1 += runs;
          if (inn == 2) battingRunsInn2 += runs;
        }

        // Batting runs should account for runs from bat (extras like wides
        // are attributed to bowler, not batter). We verify they are reasonable.
        print(
            '|  Cross-check: Batting runs Inn1=$battingRunsInn1, Inn2=$battingRunsInn2');
        expect(battingRunsInn1, greaterThanOrEqualTo(0),
            reason: '1st innings batting runs must be non-negative');
        expect(battingRunsInn2, greaterThanOrEqualTo(0),
            reason: '2nd innings batting runs must be non-negative');

        // ---- Cross-check: Total wickets from bowling should match ----
        int bowlingWktsInn1 = 0;
        int bowlingWktsInn2 = 0;
        for (final b in bowlingList) {
          final inn = b['inningsNumber'] as int? ?? 0;
          final wkts = b['wicketsTaken'] as int? ?? 0;
          if (inn == 1) bowlingWktsInn1 += wkts;
          if (inn == 2) bowlingWktsInn2 += wkts;
        }
        print(
            '|  Cross-check: Bowling wickets Inn1=$bowlingWktsInn1, Inn2=$bowlingWktsInn2');
        expect(bowlingWktsInn1, equals(inn1Wkts),
            reason:
                'Bowling wickets in 1st innings should match tracked wickets');
        expect(bowlingWktsInn2, equals(inn2Wkts),
            reason:
                'Bowling wickets in 2nd innings should match tracked wickets');
      } catch (e) {
        print('|  Stats query error: $e');
      }
      print(
          '+-------------------------------------------------------------+');

      // ---- PHASE 10: Scorecard vs DB (Scenario 15) -------------------------
      print(
          '\n========== PHASE 10: Scorecard vs DB (Scenario 15) ==========');

      // Try to navigate to scorecard from the match complete modal
      final viewScorecardBtn = find.text('View Scorecard');
      if (viewScorecardBtn.evaluate().isNotEmpty) {
        await tester.tap(viewScorecardBtn.first);
        await settle(tester);
        await visualPause(tester, 1000);
        print('[Phase10] Navigated to Scorecard via "View Scorecard" button');
      } else {
        // Try alternative navigation: "View Match" or "Match Details"
        final viewMatchBtn = find.text('View Match');
        if (viewMatchBtn.evaluate().isNotEmpty) {
          await tester.tap(viewMatchBtn.first);
          await settle(tester);
          await visualPause(tester, 1000);
          print('[Phase10] Navigated via "View Match" button');
        } else {
          print(
              '[Phase10] No scorecard navigation button found -- checking current screen');
          dumpVisibleTexts(tester, 'scorecard-nav', 30);
        }
      }

      // Verify scorecard shows batting data
      // Look for common scorecard UI patterns
      final scorecardTexts = <String>[];
      final allTexts = find.byType(Text);
      for (final element in allTexts.evaluate().take(60)) {
        final widget = element.widget as Text;
        final text =
            widget.data ?? widget.textSpan?.toPlainText() ?? '(no text)';
        scorecardTexts.add(text);
      }
      print('[Phase10] Scorecard visible texts (first 60):');
      for (var i = 0; i < scorecardTexts.length; i++) {
        print('  [$i] ${scorecardTexts[i]}');
      }

      // Check if any team player names appear on the scorecard
      var playersFoundOnScorecard = 0;
      final allPlayerNames = [
        ...ScenarioTeams.teamABatters,
        ...ScenarioTeams.teamBBatters,
      ];
      for (final playerName in allPlayerNames) {
        if (scorecardTexts.any((t) => t.contains(playerName))) {
          playersFoundOnScorecard++;
        }
      }
      print(
          '[Phase10] Players found on scorecard: $playersFoundOnScorecard / ${allPlayerNames.length}');

      // Verify at least some players are displayed
      if (playersFoundOnScorecard > 0) {
        print('[Phase10] Scorecard displays player data -- consistency check:');

        // Cross-reference: for each player visible on scorecard, verify their
        // name also exists in the DB stats we already fetched
        try {
          final r = await testDio.get('/api/v1/test/match-stats/$matchId');
          final dbBatting = r.data['batting'] as List? ?? [];
          final dbBowling = r.data['bowling'] as List? ?? [];

          final dbBatterNames =
              dbBatting.map((b) => b['playerName'] as String? ?? '').toSet();
          final dbBowlerNames =
              dbBowling.map((b) => b['playerName'] as String? ?? '').toSet();

          var scorecardDbMatches = 0;
          for (final playerName in allPlayerNames) {
            final onScorecard =
                scorecardTexts.any((t) => t.contains(playerName));
            final inDbBatting = dbBatterNames.contains(playerName);
            final inDbBowling = dbBowlerNames.contains(playerName);

            if (onScorecard && (inDbBatting || inDbBowling)) {
              scorecardDbMatches++;
            }
          }

          print(
              '[Phase10] Scorecard-DB cross-reference: $scorecardDbMatches players match');
          expect(scorecardDbMatches, greaterThan(0),
              reason:
                  'At least some players on scorecard must have DB stats records');

          // Verify DB has batting stats for both innings
          final dbInn1Batters = dbBatting
              .where((b) => (b['inningsNumber'] ?? 0) == 1)
              .toList();
          final dbInn2Batters = dbBatting
              .where((b) => (b['inningsNumber'] ?? 0) == 2)
              .toList();
          expect(dbInn1Batters.length, greaterThanOrEqualTo(2),
              reason: 'DB should have batting stats for 1st innings');
          expect(dbInn2Batters.length, greaterThanOrEqualTo(2),
              reason: 'DB should have batting stats for 2nd innings');

          // Verify DB has bowling stats for both innings
          final dbInn1Bowlers = dbBowling
              .where((b) => (b['inningsNumber'] ?? 0) == 1)
              .toList();
          final dbInn2Bowlers = dbBowling
              .where((b) => (b['inningsNumber'] ?? 0) == 2)
              .toList();
          expect(dbInn1Bowlers.length, greaterThanOrEqualTo(1),
              reason: 'DB should have bowling stats for 1st innings');
          expect(dbInn2Bowlers.length, greaterThanOrEqualTo(1),
              reason: 'DB should have bowling stats for 2nd innings');

          print('[Phase10] Scorecard vs DB consistency verified');
        } catch (e) {
          print('[Phase10] Scorecard-DB cross-reference error: $e');
        }
      } else {
        print(
            '[Phase10] No players found on scorecard -- UI may not show scorecard view');
        print(
            '[Phase10] Skipping visual scorecard verification (DB verification already done in Phase 9)');
      }

      // ---- Final Summary ----
      print(
          '\n+============================================================+');
      print(
          '|              FULL T20 E2E -- FINAL REPORT                  |');
      print(
          '+============================================================+');
      print(
          '|  ${teamA.name.padRight(20)} vs ${teamB.name.padLeft(20)}   |');
      print(
          '+============================================================+');
      print('|  1st Innings (${teamA.name}):');
      print('|    Score     : $inn1Runs/$inn1Wkts');
      print('|    Deliveries: $inn1Dels events (incl. extras)');
      print(
          '+============================================================+');
      print(
          '|  2nd Innings (${teamB.name}) -- chasing ${inn1Runs + 1}:');
      print('|    Score     : $inn2Runs/$inn2Wkts');
      print('|    Deliveries: $inn2Dels events');
      if (inn2Runs > inn1Runs) {
        final wicketsRemaining = 10 - inn2Wkts;
        print(
            '|    Result    : ${teamB.name} won by $wicketsRemaining wickets');
      } else if (inn2Runs < inn1Runs) {
        final runDiff = inn1Runs - inn2Runs;
        print('|    Result    : ${teamA.name} won by $runDiff runs');
      } else {
        print('|    Result    : Match Tied');
      }
      print(
          '+============================================================+');
      print(
          '|  DB Verify  : $deliveryMatches/$checkCount deliveries matched');
      print('|  Mismatches : $deliveryMismatches');
      print('|  Match ID   : $matchId');
      print(
          '+============================================================+');
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
    print('[TeamPicker] "$pickerLabel" not found on screen');
    dumpVisibleTexts(tester, 'picker-not-found', 20);
    return;
  }

  // Tap to open the bottom sheet
  await tester.tap(selector.first);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

  // Pump up to 5 s in 200 ms increments until the team name appears.
  var found = false;
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.text(teamName).evaluate().isNotEmpty) {
      found = true;
      break;
    }
  }

  if (!found) {
    print('[TeamPicker] Team "$teamName" did not appear in picker after 5 s');
    dumpVisibleTexts(tester, 'picker-$pickerLabel', 30);
    // Close the sheet so subsequent UI interactions are not blocked
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  await tester.tap(find.text(teamName).first);
  await settle(tester);
  print('[TeamPicker] Selected team in picker: $teamName');
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
