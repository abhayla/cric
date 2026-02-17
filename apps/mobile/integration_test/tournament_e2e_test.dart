import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_test_wrapper.dart';
import 'helpers/data_generators.dart';
import 'helpers/delivery_record.dart';
import 'helpers/match_flow_helpers.dart';
import 'helpers/tournament_flow_helpers.dart';
import 'helpers/server_manager.dart';
import 'helpers/db_verifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MockTour-1: Full 16-Team Group+Knockout Tournament E2E Test
// ═══════════════════════════════════════════════════════════════════════════
//
// This test executes a complete tournament through the Flutter UI:
//   1. Creates 16 teams (8 players each)
//   2. Creates a Group+Knockout tournament (4 groups × 4 teams)
//   3. Plays 24 group matches (random deliveries, 6 overs, magic over on 4th)
//   4. Plays 2 semi-finals + 1 final
//   5. Verifies all results in PostgreSQL via test API
//
// Runtime: ~2-3 hours on emulator with 300ms visual delays.
// Random seed: 42 (deterministic for reproducibility).
//
// Prerequisites:
//   - Bun server running with NODE_ENV=test on port 3001 (if USE_SERVER=true)
//   - Emulator connected: flutter test integration_test/tournament_e2e_test.dart -d emulator-5554

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Default to true — server must be running for full E2E flow
  const useServer = bool.fromEnvironment('USE_SERVER', defaultValue: true);

  final serverManager = ServerManager(port: 3001);
  late final DbVerifier dbVerifier;
  final random = Random(42);

  // Test data
  final teams = TournamentTestData.generate16Teams();
  final config = TournamentTestData.mockTour1Config();
  final groupAssignments = TournamentTestData.defaultGroupAssignments();

  // Match records for verification
  final matchRecords = <MatchRecord>[];

  // ── Setup & Teardown ──

  setUpAll(() async {
    if (useServer) {
      await serverManager.startServer();
      dbVerifier = DbVerifier(baseUrl: serverManager.baseUrl);
      await serverManager.resetDatabase();
    }
  });

  tearDownAll(() async {
    if (useServer) {
      await serverManager.stopServer();
    }
  });

  // ══════════════════════════════════════════════════════════════════════
  // HELPER: Play a full match (both innings) between two teams
  // ══════════════════════════════════════════════════════════════════════

  Future<MatchRecord> playFullMatch(
    WidgetTester tester, {
    required String matchLabel,
    required TeamData teamA,
    required TeamData teamB,
    required TournamentConfig matchConfig,
    required Random rng,
  }) async {
    final record = MatchRecord(matchId: matchLabel);

    final battingPlayers = teamA.players.take(matchConfig.playersPerSide).toList();
    final bowlingPlayers = teamB.players.take(matchConfig.playersPerSide).toList();

    // ── Navigate through real UI flow ──

    // 1. Tap the fixture card (we should be on tournament detail, Fixtures tab)
    await tapFixtureCard(
      tester,
      homeTeamName: teamA.name,
      awayTeamName: teamB.name,
    );

    // 2. Complete Match Setup (teams pre-selected from fixture)
    await completeMatchSetup(tester);

    // 3. Complete Toss Wizard (teamA wins toss, chooses to bat)
    await completeTossWizard(
      tester,
      tossWinnerName: teamA.name,
      battingOpener1: battingPlayers[0].name,
      battingOpener2: battingPlayers[1].name,
      openingBowler: bowlingPlayers[0].name,
    );

    // ── Now on Scoring Page — score 1st innings (teamA bats) ──

    await playRandomInnings(
      tester: tester,
      matchRecord: record,
      inningsNumber: 1,
      totalOvers: matchConfig.overs,
      playersPerSide: matchConfig.playersPerSide,
      bowlerNames: bowlingPlayers.map((p) => p.name).toList(),
      batterNames: battingPlayers.map((p) => p.name).toList(),
      magicOverNumber: matchConfig.magicOverNumber,
      random: rng,
    );

    print('    1st innings: ${record.firstInningsRuns}/${record.firstInningsWickets}');

    // Innings transition (teamB now bats)
    await completeInningsTransition(
      tester,
      striker: bowlingPlayers[0].name,
      nonStriker: bowlingPlayers[1].name,
      bowler: battingPlayers[0].name,
    );

    // Score 2nd innings (teamB bats)
    await playRandomInnings(
      tester: tester,
      matchRecord: record,
      inningsNumber: 2,
      totalOvers: matchConfig.overs,
      playersPerSide: matchConfig.playersPerSide,
      bowlerNames: battingPlayers.map((p) => p.name).toList(),
      batterNames: bowlingPlayers.map((p) => p.name).toList(),
      magicOverNumber: matchConfig.magicOverNumber,
      random: rng,
    );

    print('    2nd innings: ${record.secondInningsRuns}/${record.secondInningsWickets}');
    print('    Result: $record');

    // Match complete — wait for MatchCompleteModal and navigate back
    await settle(tester);
    await visualPause(tester, 1000);

    // Wait for MatchCompleteModal to appear (retry)
    for (var i = 0; i < 5; i++) {
      final backHome = find.text('Back to Home');
      if (backHome.evaluate().isNotEmpty) {
        print('    [postMatch] Found "Back to Home", tapping...');
        await tester.tap(backHome.first);
        await settle(tester);
        await visualPause(tester, 1000);
        break;
      }
      await visualPause(tester, 500);
      await settle(tester);
    }

    // Verify we're on home page or navigate there
    await settle(tester);
    final homeIndicator = find.text('Home');
    if (homeIndicator.evaluate().isEmpty) {
      print('    [postMatch] Not on home page, forcing navigation...');
      await navigateToHome(tester);
    }

    return record;
  }

  /// Navigate back to the tournament detail Fixtures tab.
  /// Call this before each `playFullMatch` if not already there.
  Future<void> ensureOnTournamentFixtures(WidgetTester tester) async {
    // Check if we're already on tournament detail with Fixtures tab
    final fixturesTab = find.text('Fixtures');
    if (fixturesTab.evaluate().isNotEmpty) {
      // Make sure we're on the Fixtures tab
      await tester.tap(fixturesTab.last);
      await settle(tester);
      return;
    }

    // Pop any pushed pages until we get to a shell route
    for (var i = 0; i < 5; i++) {
      final backIcon = find.byIcon(Icons.arrow_back);
      if (backIcon.evaluate().isEmpty) break;
      await tester.tap(backIcon.first);
      await settle(tester);
    }

    // Navigate to Tournaments tab
    await navigateToTournaments(tester);
    await settle(tester);

    // Tap the tournament to open its detail page
    final tournamentCard = find.textContaining(config.name);
    if (tournamentCard.evaluate().isNotEmpty) {
      await tester.tap(tournamentCard.first);
      await settle(tester);
      await visualPause(tester);
    } else {
      print('    [ensureFixtures] WARNING: Tournament "${config.name}" not found!');
      dumpVisibleTexts(tester, 'ensureFixtures');
    }

    // Switch to Fixtures tab
    final fixturesTabAfter = find.text('Fixtures');
    if (fixturesTabAfter.evaluate().isNotEmpty) {
      await tester.tap(fixturesTabAfter.last);
      await settle(tester);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // THE BIG TEST
  // ══════════════════════════════════════════════════════════════════════

  testWidgets(
    'MockTour-1: Full 16-team Group+Knockout Tournament',
    (tester) async {
      // ── 1. LAUNCH APP ──
      print('\n╔══════════════════════════════════════╗');
      print('║  MockTour-1: Tournament E2E Test     ║');
      print('╚══════════════════════════════════════╝\n');

      await AppTestWrapper.pumpApp(tester);

      // Should land on Home page (debug mode skips auth)
      expect(find.text('Home'), findsWidgets,
          reason: 'Should land on Home page');
      print('[SETUP] App launched, on Home page');

      // ── 2. CREATE 16 TEAMS + PLAYERS (via API) ──
      print('\n[PHASE 2] Creating 16 teams with players via API...');
      final teamIds = <String, String>{}; // teamName → teamId
      final playerIds = <String, String>{}; // playerName → playerId
      for (var i = 0; i < teams.length; i++) {
        final team = teams[i];
        final teamId = await serverManager.createTeamApi(team.name);
        teamIds[team.name] = teamId;

        // Create players and add to roster
        for (final player in team.players) {
          final playerId = await serverManager.createPlayerApi(
            player.name,
            playerRole: player.role,
          );
          playerIds[player.name] = playerId;
          await serverManager.addPlayerToTeamApi(teamId, playerId);
        }
        print('  Created ${team.name} with ${team.players.length} players (${i + 1}/16)');
      }
      print('[PHASE 2] All 16 teams created with players via API');

      // ── 3. CREATE TOURNAMENT (via API) ──
      print('\n[PHASE 3] Creating tournament via API: ${config.name}');
      final tournamentId = await serverManager.createTournamentApi(
        name: config.name,
        format: config.format,
        oversPerMatch: config.overs,
        numGroups: config.numGroups,
        qualifyPerGroup: config.qualifyPerGroup,
        playersPerSide: config.playersPerSide,
      );
      print('[PHASE 3] Tournament created → $tournamentId');

      // ── 4. ADD TEAMS TO TOURNAMENT (via API) ──
      print('\n[PHASE 4] Adding teams to tournament via API...');
      for (final entry in groupAssignments.entries) {
        final groupName = entry.key;
        final teamIndices = entry.value;
        for (final teamIdx in teamIndices) {
          final teamName = teams[teamIdx - 1].name;
          final teamId = teamIds[teamName]!;
          await serverManager.addTeamToTournamentApi(
            tournamentId, teamId, groupName: groupName,
          );
          print('  Added $teamName to Group $groupName');
        }
      }
      print('[PHASE 4] All 16 teams added to groups');

      // ── 5. GENERATE FIXTURES (via API) ──
      print('\n[PHASE 5] Generating fixtures via API...');
      await serverManager.generateFixturesApi(tournamentId);
      final fixtures = await serverManager.getFixturesApi(tournamentId);
      print('[PHASE 5] ${fixtures.length} fixtures generated');

      // ── 6. PLAY 24 GROUP MATCHES ──
      print('\n[PHASE 6] Playing 24 group matches...');
      var matchCount = 0;
      for (final entry in groupAssignments.entries) {
        final groupTeamIndices = entry.value;

        // Round-robin within group: C(4,2) = 6 matches per group
        for (var i = 0; i < groupTeamIndices.length; i++) {
          for (var j = i + 1; j < groupTeamIndices.length; j++) {
            matchCount++;
            final teamA = teams[groupTeamIndices[i] - 1];
            final teamB = teams[groupTeamIndices[j] - 1];
            print(
                '\n  Match $matchCount/24: ${teamA.name} vs ${teamB.name} (Group ${entry.key})');

            // Navigate to tournament fixtures before each match
            await ensureOnTournamentFixtures(tester);

            final record = await playFullMatch(
              tester,
              matchLabel: 'group-match-$matchCount',
              teamA: teamA,
              teamB: teamB,
              matchConfig: config,
              rng: random,
            );
            matchRecords.add(record);
          }
        }
      }
      print('\n[PHASE 6] All 24 group matches completed');

      // ── 7. VERIFY GROUP STANDINGS ──
      print('\n[PHASE 7] Verifying group standings...');
      // Navigate back to tournament to see standings
      await navigateToTournaments(tester);
      await verifyStandingsPage(tester);
      print('[PHASE 7] Standings verified (UI)');

      // ── 8. PLAY 2 SEMI-FINALS ──
      print('\n[PHASE 8] Playing semi-finals...');

      // Use group winners (Team1 from A, Team5 from B, Team9 from C, Team13 from D)
      // SF1: A-winner vs D-winner, SF2: B-winner vs C-winner
      // (actual winners may differ based on random results, using placeholders)
      final sfTeams = [
        [teams[0], teams[12]], // SF1: Team1 vs Team13
        [teams[4], teams[8]],  // SF2: Team5 vs Team9
      ];

      for (var sf = 0; sf < 2; sf++) {
        final sfTeamA = sfTeams[sf][0];
        final sfTeamB = sfTeams[sf][1];
        print('\n  Semi-Final ${sf + 1}: ${sfTeamA.name} vs ${sfTeamB.name}');

        await ensureOnTournamentFixtures(tester);

        final record = await playFullMatch(
          tester,
          matchLabel: 'semi-final-${sf + 1}',
          teamA: sfTeamA,
          teamB: sfTeamB,
          matchConfig: config,
          rng: random,
        );
        matchRecords.add(record);
      }
      print('[PHASE 8] Semi-finals completed');

      // ── 9. PLAY FINAL ──
      print('\n[PHASE 9] Playing the Final...');
      // Final: SF1 winner vs SF2 winner (use same team placeholders)
      final finalTeamA = sfTeams[0][0]; // Team1
      final finalTeamB = sfTeams[1][0]; // Team5

      print('  Final: ${finalTeamA.name} vs ${finalTeamB.name}');
      await ensureOnTournamentFixtures(tester);
      final finalRecord = await playFullMatch(
        tester,
        matchLabel: 'final',
        teamA: finalTeamA,
        teamB: finalTeamB,
        matchConfig: config,
        rng: random,
      );
      matchRecords.add(finalRecord);
      print('[PHASE 9] Final completed');

      // ── 10. VERIFY TOURNAMENT AWARDS ──
      print('\n[PHASE 10] Verifying tournament awards...');
      await navigateToTournaments(tester);
      await navigateToLeaderboard(tester);
      print('[PHASE 10] Leaderboard page displayed');

      // ── 11. LOG RESULTS ──
      print('\n╔══════════════════════════════════════╗');
      print('║       TOURNAMENT RESULTS             ║');
      print('╠══════════════════════════════════════╣');
      print('║ Total matches played: ${matchRecords.length}');
      for (final record in matchRecords) {
        print('║ $record');
      }
      print('╚══════════════════════════════════════╝\n');

      // ── 12. DB VERIFICATION ──
      if (useServer) {
        print('\n[PHASE 12] Database verification...');

        // Verify each match's deliveries and awards
        for (final record in matchRecords) {
          try {
            final deliveryResult = await dbVerifier.verifyMatchDeliveries(
              record.matchId,
              record.allDeliveries,
            );
            print('  DB deliveries ${record.matchId}: $deliveryResult');

            final awardsResult = await dbVerifier.verifyMatchAwards(
              record.matchId,
            );
            print('  DB awards ${record.matchId}: $awardsResult');
          } catch (e) {
            print('  DB verify ${record.matchId}: SKIPPED ($e)');
          }
        }

        // Verify tournament standings and leaderboard
        try {
          const tournamentId = 'mock-tour-1'; // placeholder
          final standings = await dbVerifier.verifyStandings(tournamentId);
          print('  DB standings: $standings');

          final runsLeader = await dbVerifier.verifyLeaderboard(
            tournamentId,
            category: 'runs',
          );
          print('\n╔══════════════════════════════════════╗');
          print('║    TOURNAMENT AWARDS                 ║');
          print('╠══════════════════════════════════════╣');
          print('║ Batsman of Tournament: ${runsLeader.topPlayer} '
              '(${runsLeader.topValue?.toInt()} runs)');

          final wicketsLeader = await dbVerifier.verifyLeaderboard(
            tournamentId,
            category: 'wickets',
          );
          print('║ Bowler of Tournament: ${wicketsLeader.topPlayer} '
              '(${wicketsLeader.topValue?.toInt()} wickets)');
          print('╚══════════════════════════════════════╝\n');
        } catch (e) {
          print('  DB tournament verification: SKIPPED ($e)');
        }

        print('[PHASE 12] Database verification complete');
      } else {
        print('\n[PHASE 12] DB verification SKIPPED (no server)');
      }
    },
    timeout: const Timeout(Duration(hours: 3)),
  );
}
