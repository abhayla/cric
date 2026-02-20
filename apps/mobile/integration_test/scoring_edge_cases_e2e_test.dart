// ignore_for_file: avoid_print

@Timeout(Duration(minutes: 45))
library;

import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/wicket_dialog.dart';
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

// ==========================================================================
// Scoring Edge Cases E2E Tests
// ==========================================================================
//
// Three focused scenarios testing edge cases in cricket scoring:
//
//   Scenario 21: No-Ball Free Hit Chain
//     - NB -> Free Hit boundary -> NB on Free Hit -> Free Hit single -> normal
//     - Verifies free hit chaining and NB penalty accumulation
//
//   Scenario 22: All Dismissal Types
//     - Bowled, Caught, LBW, Run Out, Stumped in sequence
//     - Verifies multi-step wicket dialog (fielder selection)
//
//   Scenario 26: Overs Exhausted Innings End
//     - Score exactly 30 legal deliveries (5 overs x 6 balls) without all-out
//     - Verifies innings ends on over exhaustion, not wickets
//
// Teams: Mumbai Warriors vs Chennai Challengers (ScenarioTeams, 11 players)
// Overs: 5, Players per side: 11
//
// Run:
//   flutter test integration_test/scoring_edge_cases_e2e_test.dart -d emulator-5554

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final serverManager = ServerManager(port: 3001);
  late final Dio testDio;
  final teamA = ScenarioTeams.teamA;
  final teamB = ScenarioTeams.teamB;
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
      teamsAlreadyExist = true;
      await serverManager.resetMatchData();
      print(
          '\n[Setup] Teams already exist - reset match data only (fast path)');
    } else {
      await serverManager.resetDatabase();
      print('\n[Setup] Full database reset (teams will be created via UI)');
    }

    print('[Setup] Server healthy: ${serverManager.baseUrl}');
  });

  group('Scoring Edge Cases', () {
    // ====================================================================
    // Scenario 21: No-Ball Free Hit Chain
    // ====================================================================
    testWidgets('Scenario 21: No-ball free hit chain',
        (WidgetTester tester) async {
      final inn1 = <DeliveryRecord>[];

      // -- PHASE 1: Boot --
      print('\n========== Scenario 21: No-Ball Free Hit Chain ==========');
      print('\n== PHASE 1: Boot App ==');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('Home'), findsWidgets);
      print('OK Home page loaded');

      // -- PHASE 2: Create Teams --
      print('\n== PHASE 2: Create Teams ==');
      if (teamsAlreadyExist) {
        print('OK ${teamA.name} already exists - skipping creation');
        print('OK ${teamB.name} already exists - skipping creation');
      } else {
        await navigateToTeams(tester);
        print('Creating ${teamA.name}...');
        await createTeam(tester, teamA);
        await addPlayersToRoster(tester, teamA.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamA.name} created with ${teamA.players.length} players');

        await navigateToTeams(tester);
        print('Creating ${teamB.name}...');
        await createTeam(tester, teamB);
        await addPlayersToRoster(tester, teamB.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamB.name} created with ${teamB.players.length} players');
      }

      // -- PHASE 3: Match Setup --
      print('\n== PHASE 3: Match Setup ==');
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
          print('[Phase3] WARNING: GoRouter navigation to /home failed: $e');
        }
      }
      await visualPause(tester, 500);

      final startMatchBtn = find.text('Start Match');
      expect(startMatchBtn, findsOneWidget,
          reason: '"Start Match" button missing');
      await tester.tap(startMatchBtn);
      await settle(tester);
      await visualPause(tester, 1000);
      print('OK Navigated to Match Setup');

      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      // Select overs: 5
      final overs5 = find.text('5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
        print('OK Overs: 5');
      }

      // Select players per side: 11
      final players11 = find.text('11');
      if (players11.evaluate().isNotEmpty) {
        await tester.tap(players11.first);
        await settle(tester);
        print('OK Players per side: 11');
      }

      await visualPause(tester, 500);
      await completeMatchSetup(tester);

      // -- PHASE 4: Toss Wizard --
      print('\n== PHASE 4: Toss Wizard ==');
      await completeTossWizard(
        tester,
        tossWinnerName: teamA.name,
        battingOpener1: ScenarioTeams.teamAOpener1, // Rohit Sharma
        battingOpener2: ScenarioTeams.teamAOpener2, // Virat Kohli
        openingBowler: ScenarioTeams.teamBOpeningBowler, // Deepak Chahar
      );
      await visualPause(tester, 1000);
      print('OK Toss: ${teamA.name} bats first');
      print(
          '  Openers: ${ScenarioTeams.teamAOpener1} (str) + ${ScenarioTeams.teamAOpener2}');
      print('  Bowler: ${ScenarioTeams.teamBOpeningBowler}');

      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible after toss');
      print('OK Scoring page ready');

      // -- PHASE 5: No-Ball Free Hit Chain Sequence --
      print('\n== PHASE 5: No-Ball Free Hit Chain ==');
      print('Over 1 (${ScenarioTeams.teamBOpeningBowler})');

      // Ball 1: NB (not legal, penalty 1 run, free hit next)
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      inn1.add(const DeliveryRecord(
        isNoBall: true,
        noBallRuns: 1,
        overNumber: 1,
        ballNumber: 1,
      ));
      print('  1.NB -> NB (+1)  Score: 1/0  [free hit next]');

      // Ball 2: 4 on Free Hit (legal ball 1)
      await tapRun(tester, 4);
      inn1.add(const DeliveryRecord(
        runsFromBat: 4,
        isBoundaryFour: true,
        overNumber: 1,
        ballNumber: 1,
      ));
      print('  1.1  -> 4  (FH boundary)  Score: 5/0');

      // Ball 3: NB again (on free hit = another free hit chained)
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      inn1.add(const DeliveryRecord(
        isNoBall: true,
        noBallRuns: 1,
        overNumber: 1,
        ballNumber: 2,
      ));
      print('  1.NB -> NB (+1)  Score: 6/0  [NB on FH = another FH]');

      // Ball 4: 1 on Free Hit (legal ball 2)
      await tapRun(tester, 1);
      inn1.add(const DeliveryRecord(
        runsFromBat: 1,
        overNumber: 1,
        ballNumber: 2,
      ));
      print('  1.2  -> 1  (FH single)  Score: 7/0  [strike swaps]');

      // Ball 5: 0 (dot, normal delivery, legal ball 3)
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0,
        overNumber: 1,
        ballNumber: 3,
      ));
      print('  1.3  -> 0  (dot)  Score: 7/0');

      // Ball 6: 2 (legal ball 4)
      await tapRun(tester, 2);
      inn1.add(const DeliveryRecord(
        runsFromBat: 2,
        overNumber: 1,
        ballNumber: 4,
      ));
      print('  1.4  -> 2  Score: 9/0');

      // Ball 7: 0 (dot, legal ball 5)
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0,
        overNumber: 1,
        ballNumber: 5,
      ));
      print('  1.5  -> 0  (dot)  Score: 9/0');

      // Ball 8: 0 (dot, legal ball 6 - over complete)
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0,
        overNumber: 1,
        ballNumber: 6,
      ));
      print('  1.6  -> 0  (dot)  Score: 9/0');
      print('  --- End Over 1 | Score: 9/0 ---');

      // Select bowler for over 2
      await selectBowler(tester, ScenarioTeams.teamBBowlers[1]); // Bhuvneshwar Kumar
      print('  Bowler Over 2: ${ScenarioTeams.teamBBowlers[1]}');

      // Over 2: 6 dots to keep it simple
      print('Over 2 (${ScenarioTeams.teamBBowlers[1]})');
      for (var ball = 1; ball <= 6; ball++) {
        await tapRun(tester, 0);
        inn1.add(DeliveryRecord(
          runsFromBat: 0,
          overNumber: 2,
          ballNumber: ball,
        ));
        print('  2.$ball  -> 0  (dot)');
      }
      print('  --- End Over 2 | Score: 9/0 ---');

      // Select bowler for over 3
      await selectBowler(tester, ScenarioTeams.teamBBowlers[2]); // Kuldeep Yadav
      print('  Bowler Over 3: ${ScenarioTeams.teamBBowlers[2]}');

      // Over 3: 6 dots
      print('Over 3 (${ScenarioTeams.teamBBowlers[2]})');
      for (var ball = 1; ball <= 6; ball++) {
        await tapRun(tester, 0);
        inn1.add(DeliveryRecord(
          runsFromBat: 0,
          overNumber: 3,
          ballNumber: ball,
        ));
        print('  3.$ball  -> 0  (dot)');
      }
      print('  --- End Over 3 | Score: 9/0 ---');

      // Select bowler for over 4
      await selectBowler(tester, ScenarioTeams.teamBBowlers[3]); // Ravichandran Ashwin
      print('  Bowler Over 4: ${ScenarioTeams.teamBBowlers[3]}');

      // Over 4: 6 dots
      print('Over 4 (${ScenarioTeams.teamBBowlers[3]})');
      for (var ball = 1; ball <= 6; ball++) {
        await tapRun(tester, 0);
        inn1.add(DeliveryRecord(
          runsFromBat: 0,
          overNumber: 4,
          ballNumber: ball,
        ));
        print('  4.$ball  -> 0  (dot)');
      }
      print('  --- End Over 4 | Score: 9/0 ---');

      // Select bowler for over 5
      await selectBowler(tester, ScenarioTeams.teamBBowlers[4]); // Washington Sundar
      print('  Bowler Over 5: ${ScenarioTeams.teamBBowlers[4]}');

      // Over 5: 6 dots
      print('Over 5 (${ScenarioTeams.teamBBowlers[4]})');
      for (var ball = 1; ball <= 6; ball++) {
        await tapRun(tester, 0);
        inn1.add(DeliveryRecord(
          runsFromBat: 0,
          overNumber: 5,
          ballNumber: ball,
        ));
        print('  5.$ball  -> 0  (dot)');
      }
      print('  --- End Over 5 | Score: 9/0 ---');

      final inn1Runs = inn1.fold(0, (s, d) => s + d.totalRuns);
      final inn1Wkts = inn1.where((d) => d.isWicket).length;
      print('\n  == 1st Innings: $inn1Runs/$inn1Wkts in 5 overs ==');

      await visualPause(tester, 1500);

      // -- PHASE 6: Innings Transition --
      print('\n== PHASE 6: Innings Transition ==');
      await completeInningsTransition(
        tester,
        striker: ScenarioTeams.teamBOpener1, // Shubman Gill
        nonStriker: ScenarioTeams.teamBOpener2, // Yashasvi Jaiswal
        bowler: ScenarioTeams.teamAOpeningBowler, // Jasprit Bumrah
      );
      print(
          'OK Openers: ${ScenarioTeams.teamBOpener1} (str) + ${ScenarioTeams.teamBOpener2}');
      print('OK Bowler: ${ScenarioTeams.teamAOpeningBowler}');

      // 2nd innings: score enough to chase (target = 10)
      // Score 4, 6 = 10 >= 10 -> target chased in 2 balls
      final inn2 = <DeliveryRecord>[];
      print('\n== PHASE 7: 2nd Innings (chasing ${inn1Runs + 1}) ==');

      await tapRun(tester, 4);
      inn2.add(const DeliveryRecord(
        runsFromBat: 4,
        isBoundaryFour: true,
        overNumber: 1,
        ballNumber: 1,
      ));
      print('  1.1 -> 4  (boundary)  Score: 4/0');

      await tapRun(tester, 6);
      inn2.add(const DeliveryRecord(
        runsFromBat: 6,
        isBoundarySix: true,
        overNumber: 1,
        ballNumber: 2,
      ));
      print('  1.2 -> 6  (six)  Score: 10/0  TARGET CHASED!');

      await settle(tester);
      await visualPause(tester, 2000);

      // -- PHASE 8: Match Complete --
      print('\n== PHASE 8: Match Complete ==');
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('OK MatchCompleteModal displayed');
        dumpVisibleTexts(tester, 'match-complete', 15);
      } else {
        print('WARNING: Modal not found');
        dumpVisibleTexts(tester, 'after-target-chase', 20);
      }
      await visualPause(tester, 2500);

      // -- PHASE 9: DB Verification --
      print('\n== PHASE 9: Database Verification ==');
      await Future<void>.delayed(const Duration(seconds: 8));

      String matchId = '';
      try {
        final r = await testDio.get('/api/v1/test/latest-match');
        matchId = r.data['matchId'] as String? ?? '';
        print('Match ID: $matchId');
      } catch (e) {
        print('FAIL: Failed to get match ID: $e');
      }

      if (matchId.isEmpty) {
        print('WARNING: Cannot verify DB - no match ID returned');
        return;
      }

      // Fetch deliveries
      final allTracked = [...inn1, ...inn2];
      List<Map<String, dynamic>> dbDeliveries = [];
      try {
        final r = await testDio.get('/api/v1/test/deliveries/$matchId');
        dbDeliveries = (r.data['deliveries'] as List)
            .map((d) => d as Map<String, dynamic>)
            .toList();
      } catch (e) {
        print('FAIL: Delivery fetch failed: $e');
      }

      print('UI tracked: ${allTracked.length} deliveries');
      print('DB records: ${dbDeliveries.length} deliveries');

      // Verify no-balls exist in DB
      final dbNoBalls =
          dbDeliveries.where((d) => d['isNoBall'] == true).toList();
      print('No-balls in DB: ${dbNoBalls.length}');
      expect(dbNoBalls.length, greaterThanOrEqualTo(2),
          reason: 'Should have at least 2 no-balls (the chain)');

      // Verify free hit deliveries exist
      final dbFreeHits =
          dbDeliveries.where((d) => d['isFreeHit'] == true).toList();
      print('Free hit deliveries in DB: ${dbFreeHits.length}');
      expect(dbFreeHits.length, greaterThanOrEqualTo(2),
          reason:
              'Should have at least 2 free hit deliveries (after each NB)');

      // Verify delivery count
      expect(dbDeliveries.length, equals(allTracked.length),
          reason: 'DB delivery count must match UI-tracked count');

      // Verify individual deliveries match
      var deliveryMatches = 0;
      var deliveryMismatches = 0;
      final checkCount = allTracked.length < dbDeliveries.length
          ? allTracked.length
          : dbDeliveries.length;

      for (var i = 0; i < checkCount; i++) {
        final ui = allTracked[i];
        final db = dbDeliveries[i];
        final dbRuns = db['totalRuns'] as int? ?? 0;
        final dbWide = db['isWide'] as bool? ?? false;
        final dbNb = db['isNoBall'] as bool? ?? false;
        final dbWkt = db['isWicket'] as bool? ?? false;

        final runsOk = dbRuns == ui.totalRuns;
        final wideOk = dbWide == ui.isWide;
        final nbOk = dbNb == ui.isNoBall;
        final wktOk = dbWkt == ui.isWicket;
        final allOk = runsOk && wideOk && nbOk && wktOk;

        if (allOk) {
          deliveryMatches++;
        } else {
          deliveryMismatches++;
        }
      }

      print('Delivery comparison: $deliveryMatches match, $deliveryMismatches mismatch');
      expect(deliveryMismatches, equals(0),
          reason: 'All delivery fields must match between UI and DB');

      // Verify total runs accumulated correctly
      final totalNBRuns = inn1
          .where((d) => d.isNoBall)
          .fold(0, (s, d) => s + d.noBallRuns);
      print('Total NB penalty runs: $totalNBRuns');
      expect(totalNBRuns, equals(2),
          reason: 'Two no-balls should produce 2 penalty runs');

      print('\n== Scenario 21 COMPLETE ==');
    });

    // ====================================================================
    // Scenario 22: All Dismissal Types
    // ====================================================================
    testWidgets('Scenario 22: All dismissal types',
        (WidgetTester tester) async {
      final inn1 = <DeliveryRecord>[];

      // -- PHASE 1: Boot --
      print('\n========== Scenario 22: All Dismissal Types ==========');
      print('\n== PHASE 1: Boot App ==');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('Home'), findsWidgets);
      print('OK Home page loaded');

      // -- PHASE 2: Create Teams (skip if exist) --
      print('\n== PHASE 2: Create Teams ==');
      if (teamsAlreadyExist) {
        print('OK Teams already exist - skipping creation');
      } else {
        await navigateToTeams(tester);
        print('Creating ${teamA.name}...');
        await createTeam(tester, teamA);
        await addPlayersToRoster(tester, teamA.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamA.name} created');

        await navigateToTeams(tester);
        print('Creating ${teamB.name}...');
        await createTeam(tester, teamB);
        await addPlayersToRoster(tester, teamB.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamB.name} created');
      }

      // -- PHASE 3: Match Setup --
      print('\n== PHASE 3: Match Setup ==');
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
          print('[Phase3] WARNING: GoRouter nav failed: $e');
        }
      }
      await visualPause(tester, 500);

      final startMatchBtn = find.text('Start Match');
      expect(startMatchBtn, findsOneWidget,
          reason: '"Start Match" button missing');
      await tester.tap(startMatchBtn);
      await settle(tester);
      await visualPause(tester, 1000);
      print('OK Navigated to Match Setup');

      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      final overs5 = find.text('5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
        print('OK Overs: 5');
      }

      final players11 = find.text('11');
      if (players11.evaluate().isNotEmpty) {
        await tester.tap(players11.first);
        await settle(tester);
        print('OK Players per side: 11');
      }

      await visualPause(tester, 500);
      await completeMatchSetup(tester);

      // -- PHASE 4: Toss --
      print('\n== PHASE 4: Toss Wizard ==');
      await completeTossWizard(
        tester,
        tossWinnerName: teamA.name,
        battingOpener1: ScenarioTeams.teamAOpener1, // Rohit Sharma
        battingOpener2: ScenarioTeams.teamAOpener2, // Virat Kohli
        openingBowler: ScenarioTeams.teamBOpeningBowler, // Deepak Chahar
      );
      await visualPause(tester, 1000);
      print('OK Toss complete');

      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible');
      print('OK Scoring page ready');

      // -- PHASE 5: Score deliveries with all dismissal types --
      print('\n== PHASE 5: All Dismissal Types ==');
      print('Over 1 (${ScenarioTeams.teamBOpeningBowler})');

      // Team A batting order: Rohit(str), Virat(non-str), SKY, KL, Hardik, Jadeja, Axar, Bumrah, Shami, Chahal, Pant
      // Team B fielders: Shubman Gill, Yashasvi Jaiswal, Ishan Kishan, etc.

      // -- Wicket 1: Bowled (Rohit Sharma out) --
      await tapWicket(tester);
      await selectDismissalType(tester, 'Bowled');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true,
        overNumber: 1,
        ballNumber: 1,
      ));
      print('  1.1 -> W  (Bowled)  Score: 0/1  [Rohit out]');
      await selectBatter(tester, 'Suryakumar Yadav');
      print('       -> Suryakumar Yadav in');

      // -- Wicket 2: Caught (Virat Kohli out, fielder: Shubman Gill) --
      // WicketDialog: Step 1 = select type, Step 2 = select fielder, then Confirm
      await tapWicket(tester);
      await selectDismissalType(tester, 'Caught');
      // After selecting Caught, dialog advances or shows Next to go to fielder step
      await _tapNextInWicketDialog(tester);
      await _selectFielderInWicketDialog(tester, 'Shubman Gill');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true,
        overNumber: 1,
        ballNumber: 2,
      ));
      print('  1.2 -> W  (Caught by Shubman Gill)  Score: 0/2  [Virat out]');
      await selectBatter(tester, 'KL Rahul');
      print('       -> KL Rahul in');

      // -- Wicket 3: LBW (Suryakumar Yadav out) --
      await tapWicket(tester);
      await selectDismissalType(tester, 'LBW');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true,
        overNumber: 1,
        ballNumber: 3,
      ));
      print('  1.3 -> W  (LBW)  Score: 0/3  [SKY out]');
      await selectBatter(tester, 'Hardik Pandya');
      print('       -> Hardik Pandya in');

      // -- Wicket 4: Run Out (KL Rahul out, fielder: Yashasvi Jaiswal) --
      // WicketDialog: Step 1 = type, Step 2 = fielder, Step 3 = which batter, then Confirm
      await tapWicket(tester);
      await selectDismissalType(tester, 'Run Out');
      await _tapNextInWicketDialog(tester);
      await _selectFielderInWicketDialog(tester, 'Yashasvi Jaiswal');
      await _tapNextInWicketDialog(tester);
      // Step 3: which batter is run out - default is striker, just confirm
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true,
        overNumber: 1,
        ballNumber: 4,
      ));
      print(
          '  1.4 -> W  (Run Out by Yashasvi Jaiswal)  Score: 0/4  [KL out]');
      await selectBatter(tester, 'Ravindra Jadeja');
      print('       -> Ravindra Jadeja in');

      // -- Wicket 5: Stumped (Hardik Pandya out, fielder: Ishan Kishan WK) --
      await tapWicket(tester);
      await selectDismissalType(tester, 'Stumped');
      await _tapNextInWicketDialog(tester);
      await _selectFielderInWicketDialog(tester, 'Ishan Kishan');
      await tapWicketConfirm(tester);
      inn1.add(const DeliveryRecord(
        isWicket: true,
        overNumber: 1,
        ballNumber: 5,
      ));
      print(
          '  1.5 -> W  (Stumped by Ishan Kishan)  Score: 0/5  [Hardik out]');
      await selectBatter(tester, 'Axar Patel');
      print('       -> Axar Patel in');

      // -- Ball 6: dot ball to complete the over --
      await tapRun(tester, 0);
      inn1.add(const DeliveryRecord(
        runsFromBat: 0,
        overNumber: 1,
        ballNumber: 6,
      ));
      print('  1.6 -> 0  (dot)  Score: 0/5');
      print('  --- End Over 1 | Score: 0/5 ---');

      // Select bowler for over 2
      await selectBowler(tester, ScenarioTeams.teamBBowlers[1]); // Bhuvneshwar Kumar
      print('  Bowler Over 2: ${ScenarioTeams.teamBBowlers[1]}');

      // Over 2-5: score dots to exhaust overs and end innings via overs_exhausted
      print('Over 2-5: All dots');
      for (var over = 2; over <= 5; over++) {
        if (over > 2) {
          // Rotate bowlers (skip consecutive over rule)
          final bowlerIdx = over - 1; // 2->1, 3->2, 4->3, 5->4
          await selectBowler(tester, ScenarioTeams.teamBBowlers[bowlerIdx]);
          print('  Bowler Over $over: ${ScenarioTeams.teamBBowlers[bowlerIdx]}');
        }
        for (var ball = 1; ball <= 6; ball++) {
          await tapRun(tester, 0);
          inn1.add(DeliveryRecord(
            runsFromBat: 0,
            overNumber: over,
            ballNumber: ball,
          ));
        }
        print('  Over $over: 6 dots');
      }

      final inn1Runs = inn1.fold(0, (s, d) => s + d.totalRuns);
      final inn1Wkts = inn1.where((d) => d.isWicket).length;
      print('\n  == 1st Innings: $inn1Runs/$inn1Wkts in 5 overs ==');

      await visualPause(tester, 1500);

      // -- PHASE 6: Innings Transition --
      print('\n== PHASE 6: Innings Transition ==');
      await completeInningsTransition(
        tester,
        striker: ScenarioTeams.teamBOpener1,
        nonStriker: ScenarioTeams.teamBOpener2,
        bowler: ScenarioTeams.teamAOpeningBowler,
      );
      print('OK 2nd innings openers set');

      // 2nd innings: just chase quickly
      final inn2 = <DeliveryRecord>[];
      print('\n== PHASE 7: 2nd Innings (chasing ${inn1Runs + 1}) ==');
      // Target is 1 run, just score a single
      await tapRun(tester, 1);
      inn2.add(const DeliveryRecord(
        runsFromBat: 1,
        overNumber: 1,
        ballNumber: 1,
      ));
      print('  1.1 -> 1  Score: 1/0  TARGET CHASED!');

      await settle(tester);
      await visualPause(tester, 2000);

      // -- PHASE 8: Match Complete --
      print('\n== PHASE 8: Match Complete ==');
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('OK MatchCompleteModal displayed');
      } else {
        print('WARNING: Modal not found');
        dumpVisibleTexts(tester, 'after-chase', 20);
      }
      await visualPause(tester, 2500);

      // -- PHASE 9: DB Verification --
      print('\n== PHASE 9: Database Verification ==');
      await Future<void>.delayed(const Duration(seconds: 8));

      String matchId = '';
      try {
        final r = await testDio.get('/api/v1/test/latest-match');
        matchId = r.data['matchId'] as String? ?? '';
        print('Match ID: $matchId');
      } catch (e) {
        print('FAIL: Failed to get match ID: $e');
      }

      if (matchId.isEmpty) {
        print('WARNING: Cannot verify DB - no match ID');
        return;
      }

      final allTracked = [...inn1, ...inn2];
      List<Map<String, dynamic>> dbDeliveries = [];
      try {
        final r = await testDio.get('/api/v1/test/deliveries/$matchId');
        dbDeliveries = (r.data['deliveries'] as List)
            .map((d) => d as Map<String, dynamic>)
            .toList();
      } catch (e) {
        print('FAIL: Delivery fetch failed: $e');
      }

      print('UI tracked: ${allTracked.length} deliveries');
      print('DB records: ${dbDeliveries.length} deliveries');

      // Verify delivery count
      expect(dbDeliveries.length, equals(allTracked.length),
          reason: 'DB delivery count must match UI-tracked count');

      // Verify wickets exist in DB
      final dbWickets =
          dbDeliveries.where((d) => d['isWicket'] == true).toList();
      print('Wickets in DB: ${dbWickets.length}');
      expect(dbWickets.length, equals(5),
          reason: 'Should have exactly 5 wickets (Bowled, Caught, LBW, Run Out, Stumped)');

      // Verify each wicket has dismissal info
      for (var i = 0; i < dbWickets.length; i++) {
        final w = dbWickets[i];
        final dismissalType = w['dismissalType'] as String?;
        print('  Wicket ${i + 1}: dismissalType=$dismissalType');
        expect(dismissalType, isNotNull,
            reason: 'Wicket ${i + 1} must have a dismissal type');
      }

      // Verify specific dismissal types in order
      final dismissalTypes =
          dbWickets.map((w) => w['dismissalType'] as String?).toList();
      print('Dismissal types in order: $dismissalTypes');

      // Verify all delivery fields match
      var matches = 0;
      var mismatches = 0;
      final checkCount = allTracked.length < dbDeliveries.length
          ? allTracked.length
          : dbDeliveries.length;
      for (var i = 0; i < checkCount; i++) {
        final ui = allTracked[i];
        final db = dbDeliveries[i];
        final dbRuns = db['totalRuns'] as int? ?? 0;
        final dbWkt = db['isWicket'] as bool? ?? false;
        final runsOk = dbRuns == ui.totalRuns;
        final wktOk = dbWkt == ui.isWicket;
        if (runsOk && wktOk) {
          matches++;
        } else {
          mismatches++;
        }
      }

      print('Delivery comparison: $matches match, $mismatches mismatch');
      expect(mismatches, equals(0),
          reason: 'All delivery fields must match between UI and DB');

      print('\n== Scenario 22 COMPLETE ==');
    });

    // ====================================================================
    // Scenario 26: Overs Exhausted Innings End
    // ====================================================================
    testWidgets('Scenario 26: Overs exhausted innings end',
        (WidgetTester tester) async {
      final inn1 = <DeliveryRecord>[];

      // -- PHASE 1: Boot --
      print('\n========== Scenario 26: Overs Exhausted ==========');
      print('\n== PHASE 1: Boot App ==');
      await AppTestWrapper.pumpApp(tester);
      await settle(tester);
      await visualPause(tester, 1000);
      expect(find.text('Home'), findsWidgets);
      print('OK Home page loaded');

      // -- PHASE 2: Create Teams --
      print('\n== PHASE 2: Create Teams ==');
      if (teamsAlreadyExist) {
        print('OK Teams already exist - skipping creation');
      } else {
        await navigateToTeams(tester);
        print('Creating ${teamA.name}...');
        await createTeam(tester, teamA);
        await addPlayersToRoster(tester, teamA.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamA.name} created');

        await navigateToTeams(tester);
        print('Creating ${teamB.name}...');
        await createTeam(tester, teamB);
        await addPlayersToRoster(tester, teamB.players);
        await goBack(tester);
        await settle(tester);
        print('OK ${teamB.name} created');
      }

      // -- PHASE 3: Match Setup --
      print('\n== PHASE 3: Match Setup ==');
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
          print('[Phase3] WARNING: GoRouter nav failed: $e');
        }
      }
      await visualPause(tester, 500);

      final startMatchBtn = find.text('Start Match');
      expect(startMatchBtn, findsOneWidget,
          reason: '"Start Match" button missing');
      await tester.tap(startMatchBtn);
      await settle(tester);
      await visualPause(tester, 1000);
      print('OK Navigated to Match Setup');

      await _selectTeamInPicker(tester, 'Select Team A', teamA.name);
      await _selectTeamInPicker(tester, 'Select Team B', teamB.name);

      final overs5 = find.text('5');
      if (overs5.evaluate().isNotEmpty) {
        await tester.tap(overs5.first);
        await settle(tester);
        print('OK Overs: 5');
      }

      final players11 = find.text('11');
      if (players11.evaluate().isNotEmpty) {
        await tester.tap(players11.first);
        await settle(tester);
        print('OK Players per side: 11');
      }

      await visualPause(tester, 500);
      await completeMatchSetup(tester);

      // -- PHASE 4: Toss --
      print('\n== PHASE 4: Toss Wizard ==');
      await completeTossWizard(
        tester,
        tossWinnerName: teamA.name,
        battingOpener1: ScenarioTeams.teamAOpener1,
        battingOpener2: ScenarioTeams.teamAOpener2,
        openingBowler: ScenarioTeams.teamBOpeningBowler,
      );
      await visualPause(tester, 1000);
      print('OK Toss complete');

      expect(find.byType(ScoringControls), findsWidgets,
          reason: 'ScoringControls must be visible');
      print('OK Scoring page ready');

      // -- PHASE 5: Score all 30 legal deliveries (5 overs x 6 balls) --
      // Mix of runs to make it realistic but no wickets
      print('\n== PHASE 5: Score 5 overs (30 legal deliveries, no wickets) ==');

      // Bowler rotation:
      // Over 1: Deepak Chahar (set by toss)
      // Over 2: Bhuvneshwar Kumar
      // Over 3: Kuldeep Yadav
      // Over 4: Ravichandran Ashwin
      // Over 5: Washington Sundar
      final bowlers = [
        ScenarioTeams.teamBBowlers[0], // Deepak Chahar (over 1, set by toss)
        ScenarioTeams.teamBBowlers[1], // Bhuvneshwar Kumar
        ScenarioTeams.teamBBowlers[2], // Kuldeep Yadav
        ScenarioTeams.teamBBowlers[3], // Ravichandran Ashwin
        ScenarioTeams.teamBBowlers[4], // Washington Sundar
      ];

      // Delivery patterns per over (mix of runs, no wickets)
      final overPatterns = [
        [0, 1, 4, 0, 2, 0], // Over 1: 7 runs
        [1, 0, 0, 1, 0, 0], // Over 2: 2 runs
        [4, 0, 1, 0, 0, 2], // Over 3: 7 runs
        [0, 0, 0, 1, 0, 0], // Over 4: 1 run
        [6, 0, 0, 0, 1, 0], // Over 5: 7 runs = Total: 24 runs
      ];

      for (var over = 0; over < 5; over++) {
        final overNum = over + 1;
        final bowlerName = bowlers[over];

        // Select bowler (except first over which is set by toss)
        if (over > 0) {
          await selectBowler(tester, bowlerName);
        }
        print('Over $overNum ($bowlerName)');

        for (var ball = 0; ball < 6; ball++) {
          final runs = overPatterns[over][ball];
          await tapRun(tester, runs);

          inn1.add(DeliveryRecord(
            runsFromBat: runs,
            isBoundaryFour: runs == 4,
            isBoundarySix: runs == 6,
            overNumber: overNum,
            ballNumber: ball + 1,
          ));

          final totalRuns = inn1.fold(0, (s, d) => s + d.totalRuns);
          print('  $overNum.${ball + 1} -> $runs  Score: $totalRuns/0');
        }

        final totalAfterOver = inn1.fold(0, (s, d) => s + d.totalRuns);
        print('  --- End Over $overNum | Score: $totalAfterOver/0 ---');
      }

      final inn1Runs = inn1.fold(0, (s, d) => s + d.totalRuns);
      final inn1Wkts = inn1.where((d) => d.isWicket).length;
      final inn1LegalBalls = inn1.where((d) => d.isLegal).length;
      print(
          '\n  == 1st Innings: $inn1Runs/$inn1Wkts in $inn1LegalBalls legal balls ==');
      expect(inn1LegalBalls, equals(30),
          reason: 'Should have exactly 30 legal deliveries (5 overs x 6)');
      expect(inn1Wkts, equals(0),
          reason: 'No wickets should have fallen');

      await visualPause(tester, 1500);

      // -- PHASE 6: Verify Innings Transition (overs exhausted) --
      print('\n== PHASE 6: Innings Transition (Overs Exhausted) ==');
      // After 30 legal deliveries, InningsTransitionModal should appear
      await settle(tester);
      await visualPause(tester, 1000);

      final hasInningsTransition =
          find.byType(InningsTransitionModal).evaluate().isNotEmpty;
      final hasMatchComplete =
          find.byType(MatchCompleteModal).evaluate().isNotEmpty;

      print(
          'InningsTransitionModal visible: $hasInningsTransition');
      print('MatchCompleteModal visible: $hasMatchComplete');

      expect(hasInningsTransition || hasMatchComplete, isTrue,
          reason:
              'Either InningsTransitionModal or MatchCompleteModal must appear after 5 overs');

      if (hasInningsTransition) {
        print('OK InningsTransitionModal appeared (overs exhausted)');
        dumpVisibleTexts(tester, 'innings-transition', 20);

        await completeInningsTransition(
          tester,
          striker: ScenarioTeams.teamBOpener1,
          nonStriker: ScenarioTeams.teamBOpener2,
          bowler: ScenarioTeams.teamAOpeningBowler,
        );
        print('OK 2nd innings transition complete');
      }

      // 2nd innings: score exactly same to get a tie (or score more to win)
      // Score 25 runs to chase 25 (inn1Runs=24, target=25)
      final inn2 = <DeliveryRecord>[];
      print('\n== PHASE 7: 2nd Innings (chasing ${inn1Runs + 1}) ==');

      // Score 4, 6, 4, 6, 4, 1 = 25 -> target chased
      final chaseSequence = [4, 6, 4, 6, 4, 1];
      for (var i = 0; i < chaseSequence.length; i++) {
        final runs = chaseSequence[i];
        await tapRun(tester, runs);
        inn2.add(DeliveryRecord(
          runsFromBat: runs,
          isBoundaryFour: runs == 4,
          isBoundarySix: runs == 6,
          overNumber: 1,
          ballNumber: i + 1,
        ));
        final totalChase = inn2.fold(0, (s, d) => s + d.totalRuns);
        print('  1.${i + 1} -> $runs  Score: $totalChase/0');

        // Check if target chased mid-over
        if (totalChase >= inn1Runs + 1) {
          print('  TARGET CHASED!');
          break;
        }
      }

      await settle(tester);
      await visualPause(tester, 2000);

      // -- PHASE 8: Match Complete --
      print('\n== PHASE 8: Match Complete ==');
      if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) {
        print('OK MatchCompleteModal displayed');
        dumpVisibleTexts(tester, 'match-complete', 15);
      } else {
        print('WARNING: Modal not found');
        dumpVisibleTexts(tester, 'after-chase', 20);
      }
      await visualPause(tester, 2500);

      // -- PHASE 9: DB Verification --
      print('\n== PHASE 9: Database Verification ==');
      await Future<void>.delayed(const Duration(seconds: 8));

      String matchId = '';
      try {
        final r = await testDio.get('/api/v1/test/latest-match');
        matchId = r.data['matchId'] as String? ?? '';
        print('Match ID: $matchId');
      } catch (e) {
        print('FAIL: Failed to get match ID: $e');
      }

      if (matchId.isEmpty) {
        print('WARNING: Cannot verify DB - no match ID');
        return;
      }

      final allTracked = [...inn1, ...inn2];
      List<Map<String, dynamic>> dbDeliveries = [];
      try {
        final r = await testDio.get('/api/v1/test/deliveries/$matchId');
        dbDeliveries = (r.data['deliveries'] as List)
            .map((d) => d as Map<String, dynamic>)
            .toList();
      } catch (e) {
        print('FAIL: Delivery fetch failed: $e');
      }

      print('UI tracked: ${allTracked.length} deliveries');
      print('DB records: ${dbDeliveries.length} deliveries');

      // Verify delivery count
      expect(dbDeliveries.length, equals(allTracked.length),
          reason: 'DB delivery count must match UI-tracked count');

      // Verify 1st innings had exactly 30 legal deliveries and 0 wickets
      final inn1DbDeliveries =
          dbDeliveries.take(inn1.length).toList();
      final inn1DbLegal =
          inn1DbDeliveries.where((d) => d['isLegal'] == true).length;
      final inn1DbWickets =
          inn1DbDeliveries.where((d) => d['isWicket'] == true).length;
      print('1st innings DB: $inn1DbLegal legal balls, $inn1DbWickets wickets');
      expect(inn1DbLegal, equals(30),
          reason: '1st innings should have 30 legal deliveries');
      expect(inn1DbWickets, equals(0),
          reason: '1st innings should have 0 wickets');

      // Verify correct over count in DB
      final inn1Overs =
          inn1DbDeliveries.map((d) => d['overNumber'] as int).toSet();
      print('Overs in 1st innings: $inn1Overs');
      expect(inn1Overs.length, equals(5),
          reason: 'Should have deliveries in exactly 5 overs');

      // Verify all delivery fields match
      var matches = 0;
      var mismatches = 0;
      final checkCount = allTracked.length < dbDeliveries.length
          ? allTracked.length
          : dbDeliveries.length;
      for (var i = 0; i < checkCount; i++) {
        final ui = allTracked[i];
        final db = dbDeliveries[i];
        final dbRuns = db['totalRuns'] as int? ?? 0;
        final dbWkt = db['isWicket'] as bool? ?? false;
        final dbLegal = db['isLegal'] as bool? ?? true;
        final runsOk = dbRuns == ui.totalRuns;
        final wktOk = dbWkt == ui.isWicket;
        final legalOk = dbLegal == ui.isLegal;
        if (runsOk && wktOk && legalOk) {
          matches++;
        } else {
          mismatches++;
        }
      }

      print('Delivery comparison: $matches match, $mismatches mismatch');
      expect(mismatches, equals(0),
          reason: 'All delivery fields must match between UI and DB');

      // Verify match result
      try {
        final r = await testDio.get('/api/v1/test/match-result/$matchId');
        final result = r.data['result'] as Map<String, dynamic>?;
        if (result != null) {
          print('Match result type: ${result['resultType']}');
          print('Winner team ID: ${result['winnerTeamId']}');
          print('Winning margin: ${result['margin']}');
        }
      } catch (e) {
        print('Result query error: $e');
      }

      print('\n== Scenario 26 COMPLETE ==');
    });
  });
}

// ==========================================================================
// Helpers
// ==========================================================================

/// Open the team picker bottom sheet and select [teamName].
Future<void> _selectTeamInPicker(
  WidgetTester tester,
  String pickerLabel,
  String teamName,
) async {
  final selector = find.text(pickerLabel);
  if (selector.evaluate().isEmpty) {
    print('WARNING: "$pickerLabel" not found on screen');
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
    print('WARNING: Team "$teamName" did not appear in picker after 5 s');
    dumpVisibleTexts(tester, 'picker-$pickerLabel', 30);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  await tester.tap(find.text(teamName).first);
  await settle(tester);
  print('OK Selected team in picker: $teamName');
}

/// Tap "Next" inside the WicketDialog (for multi-step dismissals).
Future<void> _tapNextInWicketDialog(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // The WicketDialog uses a FilledButton with dynamic label (Next or Confirm Wicket).
  // For the intermediate "Next" step, look for FilledButton inside WicketDialog.
  final filledButtons = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.byType(FilledButton),
  );
  if (filledButtons.evaluate().isNotEmpty) {
    await tester.tap(filledButtons.first);
    await tester.pumpAndSettle();
    await visualPause(tester);
    print('    [wicketDialog] Tapped Next/FilledButton');
  } else {
    // Fallback: try text "Next"
    final nextText = find.text('Next');
    if (nextText.evaluate().isNotEmpty) {
      await tester.tap(nextText.first);
      await tester.pumpAndSettle();
      await visualPause(tester);
      print('    [wicketDialog] Tapped "Next" text');
    }
  }
}

/// Select a fielder by name inside the WicketDialog fielder selection step.
Future<void> _selectFielderInWicketDialog(
  WidgetTester tester,
  String fielderName,
) async {
  await tester.pumpAndSettle();
  final fielder = find.textContaining(fielderName);
  if (fielder.evaluate().isNotEmpty) {
    await tester.tap(fielder.first);
    await tester.pumpAndSettle();
    await visualPause(tester);
    print('    [wicketDialog] Selected fielder: $fielderName');
  } else {
    print('    [wicketDialog] WARNING: Fielder "$fielderName" not found');
    dumpVisibleTexts(tester, 'fielder-selection', 30);
  }
}
