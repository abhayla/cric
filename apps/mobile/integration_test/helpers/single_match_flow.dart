// ignore_for_file: avoid_print

import 'dart:math';

import 'package:cricapp/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data_generators.dart';
import 'delivery_record.dart';
import 'match_flow_helpers.dart';
import 'tournament_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SingleMatchFlow — Reusable flow for a complete 1-vs-1 match via the UI.
//
// Extracted from the patterns in docs/testing/flows/:
//   - E2E_FULL_MATCH.md     — Full match scenarios (win, chase, all-out, tie)
//   - match_scoring_flow.md — Delivery recording, bowler rotation, wickets
//   - test_infrastructure.md — Server connectivity, DB verification API
//
// Usage:
//   final flow = SingleMatchFlow(tester: tester, dio: testDio);
//   await flow.createTeamsViaUI(teamA, teamB);
//   await flow.setupMatch(config: matchConfig);
//   await flow.completeToss(config: tossConfig);
//   await flow.scoreFirstInnings(deliveries: over1 + over2);
//   await flow.transitionToSecondInnings(config: inningsTransitionConfig);
//   await flow.scoreSecondInnings(deliveries: ...);
//   final report = await flow.verifyAndReport();
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────
// Config DTOs
// ─────────────────────────────────────────────────────────────────────────

/// A delivery event to execute via UI tap.
/// Use factory constructors for concise test data.
class UiDelivery {
  const UiDelivery._({
    this.runs,
    this.isWide = false,
    this.isNoBall = false, // true if this is a Leg-Bye delivery
    this.isWicket = false,
    this.dismissalType = 'Bowled',
    this.fielderName,
    this.newBatterName,
    this.extraRuns = 0,
  });

  final int? runs;
  final bool isWide;
  final bool isNoBall;
  final bool isBypass = false;
  final bool isLegBypass = false;
  final bool isWicket;
  final String dismissalType;
  final String? fielderName;
  final String?
  newBatterName; // Required after a wicket (null = last wicket / auto-select)
  final int extraRuns; // Additional runs on wide/no-ball (default 0)

  // ── Factory constructors for common deliveries ──

  factory UiDelivery.dot() => const UiDelivery._(runs: 0);
  factory UiDelivery.single() => const UiDelivery._(runs: 1);
  factory UiDelivery.two() => const UiDelivery._(runs: 2);
  factory UiDelivery.three() => const UiDelivery._(runs: 3);
  factory UiDelivery.four() => const UiDelivery._(runs: 4);
  factory UiDelivery.six() => const UiDelivery._(runs: 6);

  factory UiDelivery.wide({int extraRuns = 0}) =>
      UiDelivery._(isWide: true, extraRuns: extraRuns);

  factory UiDelivery.noBall({int batRuns = 0}) =>
      UiDelivery._(isNoBall: true, runs: batRuns);

  factory UiDelivery.wicketBowled(String newBatter) => UiDelivery._(
    isWicket: true,
    dismissalType: 'Bowled',
    newBatterName: newBatter,
  );

  factory UiDelivery.wicketBowledLastWicket() =>
      const UiDelivery._(isWicket: true, dismissalType: 'Bowled');

  factory UiDelivery.wicketCaught(String fielder, String newBatter) =>
      UiDelivery._(
        isWicket: true,
        dismissalType: 'Caught',
        fielderName: fielder,
        newBatterName: newBatter,
      );

  factory UiDelivery.wicketCaughtLastWicket(String fielder) => UiDelivery._(
    isWicket: true,
    dismissalType: 'Caught',
    fielderName: fielder,
  );

  factory UiDelivery.wicketLbw(String newBatter) => UiDelivery._(
    isWicket: true,
    dismissalType: 'LBW',
    newBatterName: newBatter,
  );

  factory UiDelivery.wicketRunOut(String fielder, String newBatter) =>
      UiDelivery._(
        isWicket: true,
        dismissalType: 'Run Out',
        fielderName: fielder,
        newBatterName: newBatter,
      );

  /// Create a delivery record from this UiDelivery for tracking.
  DeliveryRecord toRecord({required int overNumber, required int ballNumber}) {
    if (isWide) {
      return DeliveryRecord(
        isWide: true,
        wideRuns: 1 + extraRuns,
        overNumber: overNumber,
        ballNumber: 0, // Wide = not legal, ball number 0
      );
    }
    if (isNoBall) {
      return DeliveryRecord(
        isNoBall: true,
        noBallRuns: 1,
        runsFromBat: runs ?? 0,
        overNumber: overNumber,
        ballNumber: 0, // NB = not legal
      );
    }
    if (isWicket) {
      return DeliveryRecord(
        isWicket: true,
        overNumber: overNumber,
        ballNumber: ballNumber,
      );
    }
    final r = runs ?? 0;
    return DeliveryRecord(
      runsFromBat: r,
      isBoundaryFour: r == 4,
      isBoundarySix: r == 6,
      overNumber: overNumber,
      ballNumber: ballNumber,
    );
  }

  @override
  String toString() {
    if (isWide) return 'WD';
    if (isNoBall) return 'NB${runs != null && runs! > 0 ? "+$runs" : ""}';
    if (isWicket) return 'W($dismissalType)';
    return '${runs ?? 0}';
  }
}

/// An over's worth of deliveries.
class UiOver {
  const UiOver({required this.bowlerName, required this.deliveries});

  final String bowlerName;
  final List<UiDelivery> deliveries;
}

/// Configuration for the toss wizard.
class TossConfig {
  const TossConfig({
    required this.tossWinnerName,
    required this.battingOpener1,
    required this.battingOpener2,
    required this.openingBowler,
  });

  final String tossWinnerName;
  final String battingOpener1;
  final String battingOpener2;
  final String openingBowler;
}

/// Configuration for innings transition.
class InningsTransitionConfig {
  const InningsTransitionConfig({
    required this.striker,
    required this.nonStriker,
    required this.bowler,
  });

  final String striker;
  final String nonStriker;
  final String bowler;
}

/// Result of the DB verification step.
class MatchVerificationReport {
  const MatchVerificationReport({
    required this.matchId,
    required this.deliveriesTracked,
    required this.deliveriesInDB,
    required this.deliveryMatches,
    required this.deliveryMismatches,
    this.resultType,
    this.winnerTeamId,
    this.winningMargin,
    this.winningMarginType,
    this.manOfMatchId,
    this.webSocketInfo,
  });

  final String matchId;
  final int deliveriesTracked;
  final int deliveriesInDB;
  final int deliveryMatches;
  final int deliveryMismatches;
  final String? resultType;
  final String? winnerTeamId;
  final int? winningMargin;
  final String? winningMarginType;
  final String? manOfMatchId;
  final String? webSocketInfo;

  bool get deliveriesMatch =>
      deliveryMismatches == 0 && deliveriesTracked == deliveriesInDB;

  @override
  String toString() {
    final lines = <String>[
      '╔══════════════════════════════════════════════════════════╗',
      '║             MATCH VERIFICATION REPORT                   ║',
      '╠══════════════════════════════════════════════════════════╣',
      '║  Match ID   : $matchId',
      '╠══════════════════════════════════════════════════════════╣',
      '║  Deliveries : tracked=$deliveriesTracked, DB=$deliveriesInDB',
      '║  Comparison : $deliveryMatches match / $deliveryMismatches mismatch',
      '║  Status     : ${deliveriesMatch ? "✓ PASS" : "✗ FAIL"}',
      '╠══════════════════════════════════════════════════════════╣',
      '║  Result     : $resultType',
      '║  Winner     : $winnerTeamId',
      '║  Margin     : $winningMargin $winningMarginType',
      '║  MOTM       : $manOfMatchId',
      '╠══════════════════════════════════════════════════════════╣',
      '║  WebSocket  : $webSocketInfo',
      '╚══════════════════════════════════════════════════════════╝',
    ];
    return lines.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SingleMatchFlow
// ─────────────────────────────────────────────────────────────────────────

/// Orchestrates a complete single match flow through the Flutter UI.
///
/// Covers the full lifecycle:
///   1. Create teams (via UI)
///   2. Navigate to match setup + fill form
///   3. Complete toss wizard (5 steps)
///   4. Score 1st innings (predetermined deliveries by over)
///   5. Innings transition (select openers + bowler)
///   6. Score 2nd innings (stops on target chase or all-out)
///   7. Verify database: deliveries, match result, awards
///
/// Based on the patterns in docs/testing/flows/E2E_FULL_MATCH.md and
/// match_scoring_flow.md.
class SingleMatchFlow {
  SingleMatchFlow({required this.tester, required this.dio});

  final WidgetTester tester;
  final Dio dio;

  // Accumulated delivery records for DB comparison
  final List<DeliveryRecord> _inn1Records = [];
  final List<DeliveryRecord> _inn2Records = [];

  // Track ball numbers
  int _currentBallNumber = 0;

  List<DeliveryRecord> get inn1Records => List.unmodifiable(_inn1Records);
  List<DeliveryRecord> get inn2Records => List.unmodifiable(_inn2Records);
  List<DeliveryRecord> get allRecords => [..._inn1Records, ..._inn2Records];

  // ─────────────────────────────────────────────────────────────────────
  // Phase 1: Create Teams via UI
  // ─────────────────────────────────────────────────────────────────────

  /// Create both teams through the Teams UI flow.
  /// After completion, returns to Home.
  Future<void> createTeamsViaUI(TeamData home, TeamData away) async {
    print('\n[SingleMatchFlow] Creating teams via UI');

    await navigateToTeams(tester);
    await createTeam(tester, home);
    await addPlayersToRoster(tester, home.players);
    await goBack(tester);
    await settle(tester);
    print('  ✓ ${home.name} created (${home.players.length} players)');

    await navigateToTeams(tester);
    await createTeam(tester, away);
    await addPlayersToRoster(tester, away.players);
    await goBack(tester);
    await settle(tester);
    print('  ✓ ${away.name} created (${away.players.length} players)');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 2: Match Setup (Home → Start Match → Select Teams → Overs)
  // ─────────────────────────────────────────────────────────────────────

  /// Navigate to and complete the Match Setup form.
  ///
  /// [homeTeamName] and [awayTeamName] must exist in the DB (created via
  /// createTeamsViaUI or API). [overs] must be one of [5,10,15,20,25,50].
  /// [playersPerSide] must be one of [6,8,11].
  Future<void> setupMatch({
    required String homeTeamName,
    required String awayTeamName,
    int overs = 5,
    int playersPerSide = 6,
  }) async {
    print(
      '\n[SingleMatchFlow] Setting up match: $homeTeamName vs $awayTeamName',
    );

    // Navigate to My Cricket tab
    final myCricketTab = find.text('My Cricket');
    if (myCricketTab.evaluate().isNotEmpty) {
      await tester.tap(myCricketTab.first);
      await settle(tester);
    }
    await visualPause(tester, 500);

    // Navigate to Match Setup
    await navigateToMatchSetup(tester);
    await visualPause(tester, 1000);

    // Select Home team
    final selectA = find.text('Select Team A');
    if (selectA.evaluate().isNotEmpty) {
      await tester.tap(selectA.first);
      await settle(tester);
      final teamAOpt = find.text(homeTeamName);
      if (teamAOpt.evaluate().isNotEmpty) {
        await tester.tap(teamAOpt.first);
        await settle(tester);
        print('  ✓ Home: $homeTeamName');
      } else {
        print('  ⚠ "$homeTeamName" not found in team picker');
      }
    }

    // Select Away team
    final selectB = find.text('Select Team B');
    if (selectB.evaluate().isNotEmpty) {
      await tester.tap(selectB.first);
      await settle(tester);
      final teamBOpt = find.text(awayTeamName);
      if (teamBOpt.evaluate().isNotEmpty) {
        await tester.tap(teamBOpt.first);
        await settle(tester);
        print('  ✓ Away: $awayTeamName');
      }
    }

    // Select overs chip
    final oversChip = find.text('$overs');
    if (oversChip.evaluate().isNotEmpty) {
      await tester.tap(oversChip.first);
      await settle(tester);
      print('  ✓ Overs: $overs');
    }

    // Select players per side chip
    final playersChip = find.text('$playersPerSide');
    if (playersChip.evaluate().isNotEmpty) {
      await tester.tap(playersChip.first);
      await settle(tester);
      print('  ✓ Players per side: $playersPerSide');
    }

    await completeMatchSetup(tester);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 3: Toss Wizard
  // ─────────────────────────────────────────────────────────────────────

  /// Complete the 5-step toss wizard.
  Future<void> completeToss(TossConfig config) async {
    print('\n[SingleMatchFlow] Completing toss wizard');
    await completeTossWizard(
      tester,
      tossWinnerName: config.tossWinnerName,
      battingOpener1: config.battingOpener1,
      battingOpener2: config.battingOpener2,
      openingBowler: config.openingBowler,
    );
    await visualPause(tester, 1000);
    print('  ✓ ${config.tossWinnerName} bats first');
    print(
      '  ✓ Openers: ${config.battingOpener1} (str) + ${config.battingOpener2}',
    );
    print('  ✓ Bowler: ${config.openingBowler}');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 4 & 6: Score an innings from a list of UiOver objects
  // ─────────────────────────────────────────────────────────────────────

  /// Score an innings ball by ball from [overs] list.
  ///
  /// Each [UiOver] specifies the bowler and delivery list for that over.
  /// Stops early if MatchCompleteModal or InningsTransitionModal appears.
  ///
  /// [inningsNumber] is 1 or 2. Used for delivery record tracking.
  Future<void> scoreInnings({
    required List<UiOver> overs,
    required int inningsNumber,
  }) async {
    final records = inningsNumber == 1 ? _inn1Records : _inn2Records;
    print(
      '\n[SingleMatchFlow] Scoring innings $inningsNumber (${overs.length} over(s))',
    );

    for (var overIdx = 0; overIdx < overs.length; overIdx++) {
      final over = overs[overIdx];
      final overNumber = overIdx + 1;
      _currentBallNumber = 0;

      // Select bowler (first over is set by toss/transition; subsequent need selection)
      if (overIdx > 0) {
        print('  Selecting bowler: ${over.bowlerName}');
        await selectBowler(tester, over.bowlerName);
      }

      print('  Over $overNumber — ${over.bowlerName}');

      for (final delivery in over.deliveries) {
        // Check for completion modals before each delivery
        if (_isMatchComplete() || _isInningsTransition()) break;

        final record = await _executeDelivery(delivery, overNumber);
        if (record != null) records.add(record);

        final deliveryStr = delivery.toString();
        final runningTotal = records.fold(0, (s, d) => s + d.totalRuns);
        final wickets = records.where((d) => d.isWicket).length;
        print(
          '    $overNumber.${delivery.isWide || delivery.isNoBall ? "ex" : _currentBallNumber}: $deliveryStr → $runningTotal/$wickets',
        );

        // Check again after delivery
        if (_isMatchComplete() || _isInningsTransition()) break;
      }

      if (_isMatchComplete() || _isInningsTransition()) break;
    }

    final total = records.fold(0, (s, d) => s + d.totalRuns);
    final wkts = records.where((d) => d.isWicket).length;
    print('  ── Innings $inningsNumber done: $total/$wkts ──');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 5: Innings Transition
  // ─────────────────────────────────────────────────────────────────────

  /// Complete the 3-step innings transition modal.
  Future<void> transitionToSecondInnings(InningsTransitionConfig config) async {
    print('\n[SingleMatchFlow] Innings transition');
    await completeInningsTransition(
      tester,
      striker: config.striker,
      nonStriker: config.nonStriker,
      bowler: config.bowler,
    );
    print('  ✓ 2nd innings: ${config.striker} (str) + ${config.nonStriker}');
    print('  ✓ Bowler: ${config.bowler}');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 7: Random innings scoring (alternative to predetermined)
  // ─────────────────────────────────────────────────────────────────────

  /// Score an innings with random deliveries (wraps playRandomInnings).
  Future<void> scoreRandomInnings({
    required int inningsNumber,
    required int totalOvers,
    required int playersPerSide,
    required List<String> bowlerNames,
    required List<String> batterNames,
    int? magicOverNumber,
    Random? random,
  }) async {
    final record = MatchRecord(matchId: 'random-innings-$inningsNumber');
    await playRandomInnings(
      tester: tester,
      matchRecord: record,
      inningsNumber: inningsNumber,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlerNames,
      batterNames: batterNames,
      magicOverNumber: magicOverNumber,
      random: random,
    );

    // Copy records to our tracking
    final source = inningsNumber == 1
        ? record.firstInningsDeliveries
        : record.secondInningsDeliveries;
    if (inningsNumber == 1) {
      _inn1Records.addAll(source);
    } else {
      _inn2Records.addAll(source);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 8: DB Verification + Report
  // ─────────────────────────────────────────────────────────────────────

  /// Fetch the latest match from the test API and verify DB records.
  ///
  /// Returns a [MatchVerificationReport] with all results.
  Future<MatchVerificationReport> verifyAndReport({
    Duration waitBeforeVerify = const Duration(seconds: 2),
  }) async {
    print('\n[SingleMatchFlow] DB Verification');
    await Future<void>.delayed(waitBeforeVerify);

    // Get match ID
    String matchId = '';
    try {
      final r = await dio.get('/api/v1/test/latest-match');
      matchId = r.data['matchId'] as String? ?? '';
      print('  Match ID: $matchId');
    } catch (e) {
      print('  ✗ Could not get match ID: $e');
    }

    if (matchId.isEmpty) {
      return const MatchVerificationReport(
        matchId: '',
        deliveriesTracked: 0,
        deliveriesInDB: 0,
        deliveryMatches: 0,
        deliveryMismatches: 0,
      );
    }

    // Fetch deliveries
    final allTracked = allRecords;
    List<Map<String, dynamic>> dbDeliveries = [];
    try {
      final r = await dio.get('/api/v1/test/deliveries/$matchId');
      dbDeliveries = (r.data['deliveries'] as List)
          .map((d) => d as Map<String, dynamic>)
          .toList();
      print(
        '  Deliveries — UI:${allTracked.length}, DB:${dbDeliveries.length}',
      );
    } catch (e) {
      print('  ✗ Delivery fetch failed: $e');
    }

    // Compare deliveries
    var matches = 0;
    var mismatches = 0;
    final checkCount = allTracked.length < dbDeliveries.length
        ? allTracked.length
        : dbDeliveries.length;

    for (var i = 0; i < checkCount; i++) {
      final db = dbDeliveries[i];
      final ui = allTracked[i];
      final ok =
          (db['total_runs'] as int? ?? 0) == ui.totalRuns &&
          (db['is_wide'] as bool? ?? false) == ui.isWide &&
          (db['is_no_ball'] as bool? ?? false) == ui.isNoBall &&
          (db['is_wicket'] as bool? ?? false) == ui.isWicket;
      if (ok) {
        matches++;
      } else {
        mismatches++;
      }
    }
    mismatches +=
        (allTracked.length - checkCount).abs() +
        (dbDeliveries.length - checkCount).abs();

    // Fetch match result
    String? resultType, winnerTeamId, winningMarginType;
    int? winningMargin;
    String? manOfMatchId;
    try {
      final r = await dio.get('/api/v1/test/match-result/$matchId');
      final result = r.data['result'] as Map<String, dynamic>?;
      if (result != null) {
        resultType = result['result_type'] as String?;
        winnerTeamId = result['winner_team_id'] as String?;
        winningMargin = result['winning_margin'] as int?;
        winningMarginType = result['winning_margin_type'] as String?;
        manOfMatchId = result['man_of_match_id'] as String?;
      }
    } catch (e) {
      print('  ✗ Result fetch failed: $e');
    }

    // WebSocket info
    final wsInfo =
        'ws://<server>:3001/ws → {"type":"join_match","matchId":"$matchId"}';

    final report = MatchVerificationReport(
      matchId: matchId,
      deliveriesTracked: allTracked.length,
      deliveriesInDB: dbDeliveries.length,
      deliveryMatches: matches,
      deliveryMismatches: mismatches,
      resultType: resultType,
      winnerTeamId: winnerTeamId,
      winningMargin: winningMargin,
      winningMarginType: winningMarginType,
      manOfMatchId: manOfMatchId,
      webSocketInfo: wsInfo,
    );

    print(report.toString());
    return report;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────

  bool _isMatchComplete() =>
      find.byType(MatchCompleteModal).evaluate().isNotEmpty;

  bool _isInningsTransition() =>
      find.byType(InningsTransitionModal).evaluate().isNotEmpty;

  /// Execute one UI delivery and return its tracking record.
  Future<DeliveryRecord?> _executeDelivery(UiDelivery d, int overNumber) async {
    if (d.isWide) {
      await tapExtra(tester, 'WD');
      await confirmExtra(tester);
      return d.toRecord(overNumber: overNumber, ballNumber: 0);
    }

    if (d.isNoBall) {
      await tapExtra(tester, 'NB');
      await confirmExtra(tester);
      // If bat runs on NB, tap those too
      if (d.runs != null && d.runs! > 0) {
        await tapRun(tester, d.runs!);
      }
      return d.toRecord(overNumber: overNumber, ballNumber: 0);
    }

    if (d.isWicket) {
      await tapWicket(tester);
      await selectDismissalType(tester, d.dismissalType);

      // Multi-step dismissals (Caught, Stumped, Run Out)
      final needsFielder =
          d.dismissalType == 'Caught' ||
          d.dismissalType == 'Stumped' ||
          d.dismissalType == 'Run Out';

      if (needsFielder && d.fielderName != null) {
        await _tapWicketNext();
        await _selectFielder(d.fielderName!);
        if (d.dismissalType == 'Run Out') {
          await _tapWicketNext(); // Run Out has 3 steps
        }
      }

      await tapWicketConfirm(tester);
      _currentBallNumber++;

      if (d.newBatterName != null) {
        await selectBatter(tester, d.newBatterName!);
      }

      return d.toRecord(overNumber: overNumber, ballNumber: _currentBallNumber);
    }

    // Regular run
    await tapRun(tester, d.runs ?? 0);
    _currentBallNumber++;
    return d.toRecord(overNumber: overNumber, ballNumber: _currentBallNumber);
  }

  Future<void> _tapWicketNext() async {
    // Find "Next" text inside the WicketDialog area
    final nextInDialog = find.text('Next');
    if (nextInDialog.evaluate().isNotEmpty) {
      await tester.tap(nextInDialog.first);
      await tester.pumpAndSettle();
      await visualPause(tester);
    }
  }

  Future<void> _selectFielder(String fielderName) async {
    final fielder = find.textContaining(fielderName);
    if (fielder.evaluate().isNotEmpty) {
      await tester.tap(fielder.first);
      await tester.pumpAndSettle();
      await visualPause(tester);
    }
  }
}
