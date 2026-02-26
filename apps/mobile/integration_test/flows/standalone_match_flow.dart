/// Standalone match flow — full match lifecycle from setup to result.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';

import '../config/test_data.dart';
import '../core/test_utils.dart';
import '../helpers/match_setup.dart';
import '../helpers/modals.dart';
import '../helpers/navigation.dart';
import '../models/delivery_record.dart';
import '../models/match_outcome.dart';
import 'random_innings.dart';

/// Score a full standalone match between two teams.
///
/// Returns a [MatchOutcome] with the result.
Future<MatchOutcome> scoreStandaloneMatch({
  required WidgetTester tester,
  required TestTeam homeTeamData,
  required TestTeam awayTeamData,
  required int totalOvers,
  required int playersPerSide,
  int? magicOverNumber,
  Random? random,
}) async {
  final rng = random ?? Random();
  final matchRecord = MatchRecord(matchId: 'standalone');

  // Random toss
  final tossWinner = rng.nextBool() ? homeTeamData.name : awayTeamData.name;
  final chooseBat = rng.nextBool();
  final battingTeam = chooseBat
      ? (tossWinner == homeTeamData.name ? homeTeamData : awayTeamData)
      : (tossWinner == homeTeamData.name ? awayTeamData : homeTeamData);
  final bowlingTeam = battingTeam.name == homeTeamData.name ? awayTeamData : homeTeamData;

  final opener1 = battingTeam.players[0].name;
  final opener2 = battingTeam.players[1].name;
  final openingBowler = bowlingTeam.players[0].name;

  print('  Toss: $tossWinner wins, chooses to ${chooseBat ? "Bat" : "Field"}');
  print('  Batting: ${battingTeam.name} ($opener1, $opener2)');
  print('  Bowling: ${bowlingTeam.name} ($openingBowler)');

  // Complete toss wizard
  await completeTossWizard(
    tester,
    tossWinnerName: tossWinner,
    battingOpener1: opener1,
    battingOpener2: opener2,
    openingBowler: openingBowler,
    playersPerSide: playersPerSide,
    chooseBat: chooseBat,
  );

  // Score first innings
  final bowlingPlayerNames = bowlingTeam.players.map((p) => p.name).toList();
  final battingPlayerNames = battingTeam.players.map((p) => p.name).toList();

  print('  [Innings 1] ${battingTeam.name} batting...');
  await playRandomInnings(
    tester: tester,
    matchRecord: matchRecord,
    inningsNumber: 1,
    totalOvers: totalOvers,
    playersPerSide: playersPerSide,
    bowlerNames: bowlingPlayerNames,
    batterNames: battingPlayerNames,
    magicOverNumber: magicOverNumber,
    random: rng,
  );
  print('  [Innings 1] ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');

  // Wait for innings transition modal (may take a moment after server sync)
  await waitForFinder(tester, find.byType(InningsTransitionModal),
      timeoutMs: 15000, intervalMs: 500);

  final transitionModal = find.byType(InningsTransitionModal);
  if (transitionModal.evaluate().isNotEmpty) {
    final inn2Opener1 = bowlingTeam.players[0].name;
    final inn2Opener2 = bowlingTeam.players[1].name;
    final inn2Bowler = battingTeam.players[0].name;

    await completeInningsTransition(
      tester,
      striker: inn2Opener1,
      nonStriker: inn2Opener2,
      bowler: inn2Bowler,
    );

    // Score second innings
    final battingPlayerNames2 = bowlingTeam.players.map((p) => p.name).toList();
    final bowlingPlayerNames2 = battingTeam.players.map((p) => p.name).toList();

    print('  [Innings 2] ${bowlingTeam.name} batting (target: ${matchRecord.firstInningsRuns + 1})...');
    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 2,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingPlayerNames2,
      batterNames: battingPlayerNames2,
      magicOverNumber: magicOverNumber,
      random: rng,
    );
    print('  [Innings 2] ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
  }

  // Capture result
  await settle(tester);
  final matchResult = await captureMatchCompleteResult(tester);

  print('  Result: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets} '
      'vs ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}'
      '${matchResult != null ? " — $matchResult" : ""}');

  return MatchOutcome(
    homeTeam: homeTeamData.name,
    awayTeam: awayTeamData.name,
    firstInningsRuns: matchRecord.firstInningsRuns,
    firstInningsWickets: matchRecord.firstInningsWickets,
    secondInningsRuns: matchRecord.secondInningsRuns,
    secondInningsWickets: matchRecord.secondInningsWickets,
    resultText: matchResult,
  );
}

/// Score a fixture match from a tournament's Fixtures tab.
///
/// This wraps the full flow: tap fixture → match setup → toss → score → result.
/// Navigates back to tournament detail after completion.
Future<MatchOutcome> scoreFixtureMatch({
  required WidgetTester tester,
  required String homeTeam,
  required String awayTeam,
  required List<TestTeam> allTeams,
  required int totalOvers,
  required int playersPerSide,
  Random? random,
}) async {
  final rng = random ?? Random();

  // Complete match setup (teams pre-selected from fixture)
  await completeMatchSetup(tester);

  // Random toss
  final tossWinner = rng.nextBool() ? homeTeam : awayTeam;
  final chooseBat = rng.nextBool();
  final battingTeamName = chooseBat ? tossWinner : (tossWinner == homeTeam ? awayTeam : homeTeam);
  final bowlingTeamName = battingTeamName == homeTeam ? awayTeam : homeTeam;

  final battingTeamData = allTeams.firstWhere((t) => t.name == battingTeamName);
  final bowlingTeamData = allTeams.firstWhere((t) => t.name == bowlingTeamName);

  final opener1 = battingTeamData.players[0].name;
  final opener2 = battingTeamData.players[1].name;
  final openingBowler = bowlingTeamData.players[0].name;

  print('  Toss: $tossWinner wins, chooses to ${chooseBat ? "Bat" : "Field"}');

  await completeTossWizard(
    tester,
    tossWinnerName: tossWinner,
    battingOpener1: opener1,
    battingOpener2: opener2,
    openingBowler: openingBowler,
    playersPerSide: playersPerSide,
    chooseBat: chooseBat,
  );

  final matchRecord = MatchRecord(matchId: 'fixture');
  final bowlingPlayerNames = bowlingTeamData.players.map((p) => p.name).toList();
  final battingPlayerNames = battingTeamData.players.map((p) => p.name).toList();

  print('  [Innings 1] $battingTeamName batting...');
  await playRandomInnings(
    tester: tester,
    matchRecord: matchRecord,
    inningsNumber: 1,
    totalOvers: totalOvers,
    playersPerSide: playersPerSide,
    bowlerNames: bowlingPlayerNames,
    batterNames: battingPlayerNames,
    random: rng,
  );
  print('  [Innings 1] ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');

  // Wait for innings transition modal (may take a moment after server sync)
  await waitForFinder(tester, find.byType(InningsTransitionModal),
      timeoutMs: 15000, intervalMs: 500);

  final transitionModal = find.byType(InningsTransitionModal);
  if (transitionModal.evaluate().isNotEmpty) {
    final inn2Opener1 = bowlingTeamData.players[0].name;
    final inn2Opener2 = bowlingTeamData.players[1].name;
    final inn2Bowler = battingTeamData.players[0].name;

    await completeInningsTransition(
      tester,
      striker: inn2Opener1,
      nonStriker: inn2Opener2,
      bowler: inn2Bowler,
    );

    final battingPlayerNames2 = bowlingTeamData.players.map((p) => p.name).toList();
    final bowlingPlayerNames2 = battingTeamData.players.map((p) => p.name).toList();

    print('  [Innings 2] $bowlingTeamName batting (target: ${matchRecord.firstInningsRuns + 1})...');
    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 2,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingPlayerNames2,
      batterNames: battingPlayerNames2,
      random: rng,
    );
    print('  [Innings 2] ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
  }

  // Capture result before dismissing modal
  await settle(tester);
  final matchResult = await captureMatchCompleteResult(tester);

  // Dismiss modal and navigate home. The toss→scoring flow uses GoRouter.go()
  // (replace), so there's nothing to pop back to. scoreAllFixtures handles
  // re-entering the tournament detail page before the next fixture.
  await dismissMatchCompleteModal(tester);
  await settle(tester);
  await visualPause(tester, 500);

  return MatchOutcome(
    homeTeam: homeTeam,
    awayTeam: awayTeam,
    firstInningsRuns: matchRecord.firstInningsRuns,
    firstInningsWickets: matchRecord.firstInningsWickets,
    secondInningsRuns: matchRecord.secondInningsRuns,
    secondInningsWickets: matchRecord.secondInningsWickets,
    resultText: matchResult,
  );
}
