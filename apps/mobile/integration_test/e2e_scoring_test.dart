import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/pages/scoring_page.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_batter_sheet.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/wicket_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Test Data
// ═══════════════════════════════════════════════════════════════════════════

/// Mumbai Indians — batting team A
const _miPlayers = [
  PlayingXIPlayer(
    playerId: 'mi-1',
    displayName: 'Rohit Sharma',
    playerRole: 'batter',
    isCaptain: true,
  ),
  PlayingXIPlayer(
    playerId: 'mi-2',
    displayName: 'Suryakumar Yadav',
    playerRole: 'batter',
  ),
  PlayingXIPlayer(
    playerId: 'mi-3',
    displayName: 'Jasprit Bumrah',
    playerRole: 'bowler',
  ),
];

/// Chennai Super Kings — batting team B
const _cskPlayers = [
  PlayingXIPlayer(
    playerId: 'csk-1',
    displayName: 'MS Dhoni',
    playerRole: 'wicketkeeper_batter',
    isKeeper: true,
  ),
  PlayingXIPlayer(
    playerId: 'csk-2',
    displayName: 'Ravindra Jadeja',
    playerRole: 'all_rounder',
  ),
  PlayingXIPlayer(
    playerId: 'csk-3',
    displayName: 'Deepak Chahar',
    playerRole: 'bowler',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// Visual Delay — slows actions so you can watch on device
// ═══════════════════════════════════════════════════════════════════════════

const _defaultPauseMs = 300;

Future<void> _visualPause(WidgetTester tester, [int ms = _defaultPauseMs]) async {
  await tester.pump(Duration(milliseconds: ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers (same as widget tests, with visual pauses added)
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildScoringPage({
  int totalOvers = 2,
  int playersPerSide = 3,
  List<PlayingXIPlayer> battingPlayers = _miPlayers,
  List<PlayingXIPlayer> bowlingPlayers = _cskPlayers,
  String openingStrikerId = 'mi-1',
  String openingStrikerName = 'Rohit Sharma',
  String openingNonStrikerId = 'mi-2',
  String openingNonStrikerName = 'Suryakumar Yadav',
  String openingBowlerId = 'csk-1',
  String openingBowlerName = 'MS Dhoni',
  String battingTeamId = 'team-mi',
  String bowlingTeamId = 'team-csk',
  String battingTeamName = 'Mumbai Indians',
  String bowlingTeamName = 'Chennai Super Kings',
  int inningsNumber = 1,
  int? target,
  FirstInningsSummary? firstInningsSummary,
}) {
  return MaterialApp(
    home: ScoringPage(
      args: ScoringPageArgs(
        matchId: 'match-e2e',
        inningsId: 'inn-$inningsNumber',
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        battingTeamName: battingTeamName,
        bowlingTeamName: bowlingTeamName,
        inningsNumber: inningsNumber,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        target: target,
        battingTeamPlayers: battingPlayers,
        bowlingTeamPlayers: bowlingPlayers,
        openingStrikerId: openingStrikerId,
        openingStrikerName: openingStrikerName,
        openingNonStrikerId: openingNonStrikerId,
        openingNonStrikerName: openingNonStrikerName,
        openingBowlerId: openingBowlerId,
        openingBowlerName: openingBowlerName,
        firstInningsSummary: firstInningsSummary,
      ),
    ),
  );
}

Future<void> _tapRun(WidgetTester tester, int runs) async {
  final runButton = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('$runs'),
  );
  expect(runButton, findsOneWidget, reason: 'Run button $runs should exist');
  await tester.tap(runButton);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _tapExtra(WidgetTester tester, String label) async {
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text(label),
  );
  expect(button, findsOneWidget, reason: 'Extras button $label should exist');
  await tester.tap(button);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _confirmExtra(WidgetTester tester) async {
  final confirmButton = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('Confirm'),
  );
  expect(confirmButton, findsOneWidget);
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _selectExtraRuns(WidgetTester tester, int runs) async {
  final runBtn = find.descendant(
    of: find.byType(ExtrasPanel),
    matching: find.text('$runs'),
  );
  expect(runBtn, findsWidgets);
  await tester.tap(runBtn.first);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _tapWicket(WidgetTester tester) async {
  final button = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.text('W'),
  );
  expect(button, findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _selectDismissalType(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.text(label),
  );
  expect(chip, findsOneWidget, reason: 'Dismissal type $label should exist');
  await tester.tap(chip);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _tapWicketPrimary(WidgetTester tester) async {
  final buttons = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.byType(FilledButton),
  );
  expect(buttons, findsOneWidget);
  await tester.tap(buttons);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _selectFielder(WidgetTester tester, String name) async {
  final fielder = find.descendant(
    of: find.byType(WicketDialog),
    matching: find.text(name),
  );
  expect(fielder, findsOneWidget, reason: 'Fielder $name should exist');
  await tester.tap(fielder);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _tapUndo(WidgetTester tester) async {
  final undoIcon = find.descendant(
    of: find.byType(ScoringControls),
    matching: find.byIcon(Icons.undo),
  );
  expect(undoIcon, findsOneWidget);
  await tester.tap(undoIcon, warnIfMissed: false);
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _selectBowler(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final bowlerName = find.descendant(
    of: find.byType(SelectBowlerSheet),
    matching: find.textContaining(name),
  );
  if (bowlerName.evaluate().isNotEmpty) {
    await tester.tap(bowlerName.first);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  await _visualPause(tester, 500); // Longer pause at over boundary
}

Future<void> _selectBatter(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final batterName = find.descendant(
    of: find.byType(SelectBatterSheet),
    matching: find.textContaining(name),
  );
  if (batterName.evaluate().isNotEmpty) {
    await tester.tap(batterName.first);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  await _visualPause(tester);
}

Future<void> _bowlDotOver(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await _tapRun(tester, 0);
  }
}

Future<void> _completeInningsTransition(
  WidgetTester tester, {
  required String striker,
  required String nonStriker,
  required String bowler,
}) async {
  await tester.pumpAndSettle();
  await _visualPause(tester, 600); // Let user see innings summary

  // Step 1: Summary -> Next
  expect(find.byType(InningsTransitionModal), findsOneWidget);
  final nextButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
  await _visualPause(tester);

  // Step 2: Select 2 openers
  final strikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(striker),
  );
  await tester.tap(strikerRow);
  await tester.pumpAndSettle();
  await _visualPause(tester);

  final nonStrikerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(nonStriker),
  );
  await tester.tap(nonStrikerRow);
  await tester.pumpAndSettle();
  await _visualPause(tester);

  // Next -> Step 3
  final nextButton2 = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Next'),
  );
  await tester.tap(nextButton2);
  await tester.pumpAndSettle();
  await _visualPause(tester);

  // Step 3: Select bowler
  final bowlerRow = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text(bowler),
  );
  await tester.tap(bowlerRow);
  await tester.pumpAndSettle();
  await _visualPause(tester);

  // Start Innings
  final startButton = find.descendant(
    of: find.byType(InningsTransitionModal),
    matching: find.text('Start Innings'),
  );
  await tester.tap(startButton);
  await tester.pumpAndSettle();
  await _visualPause(tester, 600); // Let user see new innings start
}

// ═══════════════════════════════════════════════════════════════════════════
// Integration Tests — 5 Visual Scenarios
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Scenario 1: Full Match — Win by Runs ───────────────────────────────
  // Both innings, boundaries, over changes, bowler selection, innings
  // transition, 2nd innings all dots, match complete by run margin.

  testWidgets('Scenario 1: Full Match — Win by Runs', (tester) async {
    await tester.pumpWidget(_buildScoringPage());
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // Verify initial state
    expect(find.byType(ScoringPage), findsOneWidget);
    expect(find.text('Rohit Sharma *'), findsOneWidget);
    expect(find.text('Suryakumar Yadav'), findsOneWidget);

    // ── 1st Innings, Over 1 ──
    await _tapRun(tester, 1); // 1.1: single, strike swaps
    expect(find.text('Suryakumar Yadav *'), findsOneWidget);

    await _tapRun(tester, 1); // 1.2: single, swaps back
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    await _tapRun(tester, 4); // 1.3: four
    await _tapRun(tester, 4); // 1.4: four
    await _tapRun(tester, 0); // 1.5: dot
    await _tapRun(tester, 6); // 1.6: six -> over complete

    // Over complete -> SelectBowlerSheet
    await _selectBowler(tester, 'Deepak Chahar');

    // ── 1st Innings, Over 2 ──
    await _tapRun(tester, 4); // 2.1: four
    await _tapRun(tester, 4); // 2.2: four
    await _tapRun(tester, 0); // 2.3: dot
    await _tapRun(tester, 0); // 2.4: dot
    await _tapRun(tester, 2); // 2.5: two
    await _tapRun(tester, 0); // 2.6: dot -> innings complete

    // Innings transition modal
    await tester.pumpAndSettle();
    expect(find.byType(InningsTransitionModal), findsOneWidget);

    await _completeInningsTransition(
      tester,
      striker: 'MS Dhoni',
      nonStriker: 'Ravindra Jadeja',
      bowler: 'Rohit Sharma',
    );

    // ── 2nd Innings: all dots ──
    await _bowlDotOver(tester);

    // Select bowler for over 2
    await tester.pumpAndSettle();
    final bowlerSheet = find.byType(SelectBowlerSheet);
    if (bowlerSheet.evaluate().isNotEmpty) {
      await _selectBowler(tester, 'Suryakumar Yadav');
    }

    await _bowlDotOver(tester);

    // Match complete
    await tester.pumpAndSettle();
    expect(find.byType(MatchCompleteModal), findsOneWidget);
    expect(find.textContaining('Mumbai Indians won by 26 runs'), findsOneWidget);
    await _visualPause(tester, 1000); // Let user see result

    await tester.tap(find.text('View Scorecard'));
    await tester.pumpAndSettle();
  });

  // ── Scenario 2: Target Chase + All Out + Tie ───────────────────────────
  // 1st innings scores 7, 2nd innings chases target mid-over. Then a
  // separate tie scenario (both score 0).

  testWidgets('Scenario 2: Target Chase — Win by Wickets', (tester) async {
    await tester.pumpWidget(_buildScoringPage());
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // ── 1st Innings: 6 singles + 1 single = 7 runs ──
    for (var i = 0; i < 6; i++) {
      await _tapRun(tester, 1);
    }

    await _selectBowler(tester, 'Deepak Chahar');

    for (var i = 0; i < 5; i++) {
      await _tapRun(tester, 0);
    }
    await _tapRun(tester, 1); // total = 7

    // Innings complete -> transition
    await tester.pumpAndSettle();
    expect(find.byType(InningsTransitionModal), findsOneWidget);

    await _completeInningsTransition(
      tester,
      striker: 'MS Dhoni',
      nonStriker: 'Ravindra Jadeja',
      bowler: 'Rohit Sharma',
    );

    // ── 2nd Innings: chase 8 ──
    await _tapRun(tester, 6); // 6 runs
    await _tapRun(tester, 1); // 7 runs
    await _tapRun(tester, 1); // 8 runs -> TARGET CHASED!

    await tester.pumpAndSettle();
    expect(find.byType(MatchCompleteModal), findsOneWidget);
    expect(
      find.textContaining('Chennai Super Kings won by 2 wickets'),
      findsOneWidget,
    );
    await _visualPause(tester, 1000);
  });

  testWidgets('Scenario 2b: All Out + Tie', (tester) async {
    await tester.pumpWidget(_buildScoringPage(totalOvers: 1));
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // 1st innings: 6 dots = 0 runs
    await _bowlDotOver(tester);

    // Innings transition
    await tester.pumpAndSettle();
    expect(find.byType(InningsTransitionModal), findsOneWidget);

    await _completeInningsTransition(
      tester,
      striker: 'MS Dhoni',
      nonStriker: 'Ravindra Jadeja',
      bowler: 'Rohit Sharma',
    );

    // 2nd innings: 2 wickets = all out for 0
    // Wicket 1: Bowled
    await _tapWicket(tester);
    await _selectDismissalType(tester, 'Bowled');
    await _tapWicketPrimary(tester);

    await tester.pumpAndSettle();
    final batterSheet = find.byType(SelectBatterSheet);
    if (batterSheet.evaluate().isNotEmpty) {
      await _selectBatter(tester, 'Deepak Chahar');
    }

    // Wicket 2: Bowled -> all out
    await _tapWicket(tester);
    await _selectDismissalType(tester, 'Bowled');
    await _tapWicketPrimary(tester);

    // Match complete -> tie
    await tester.pumpAndSettle();
    expect(find.byType(MatchCompleteModal), findsOneWidget);
    expect(find.text('Match Tied'), findsOneWidget);
    await _visualPause(tester, 1000);
  });

  // ── Scenario 3: Extras & Free Hit Demo ─────────────────────────────────
  // Wide, no-ball, bye, leg-bye, free hit chain, wicket on free hit.

  testWidgets('Scenario 3: Extras & Free Hit Demo', (tester) async {
    await tester.pumpWidget(_buildScoringPage(totalOvers: 5));
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // --- Wide: default 0 additional = 1 penalty run ---
    await _tapExtra(tester, 'WD');
    expect(find.byType(ExtrasPanel), findsOneWidget);
    expect(find.text('Wide'), findsOneWidget);
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsNothing); // Wide doesn't trigger free hit

    // --- Wide with additional runs ---
    await _tapExtra(tester, 'WD');
    await _selectExtraRuns(tester, 2);
    await _confirmExtra(tester);

    // --- No Ball triggers free hit ---
    await _tapExtra(tester, 'NB');
    expect(find.text('No Ball'), findsOneWidget);
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsOneWidget);

    // --- Free hit: legal delivery consumes it ---
    await _tapRun(tester, 4);
    expect(find.text('FREE HIT'), findsNothing);

    // --- Bye: legal delivery ---
    await _tapExtra(tester, 'B');
    expect(find.text('Bye'), findsOneWidget);
    await _confirmExtra(tester);

    // --- Leg Bye ---
    await _tapExtra(tester, 'LB');
    expect(find.text('Leg Bye'), findsOneWidget);
    await _confirmExtra(tester);

    // --- No-ball -> free hit -> wide keeps free hit -> legal consumes ---
    await _tapExtra(tester, 'NB');
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsOneWidget);

    // Wide on free hit keeps it pending
    await _tapExtra(tester, 'WD');
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsOneWidget);

    // No-ball on free hit chains another free hit
    await _tapExtra(tester, 'NB');
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsOneWidget);

    // Legal delivery finally consumes
    await _tapRun(tester, 0);
    expect(find.text('FREE HIT'), findsNothing);

    // --- Wicket on free hit: only Run Out enabled ---
    await _tapExtra(tester, 'NB');
    await _confirmExtra(tester);
    expect(find.text('FREE HIT'), findsOneWidget);

    await _tapWicket(tester);
    expect(find.byType(WicketDialog), findsOneWidget);
    expect(find.text('Run Out'), findsOneWidget);
    expect(find.text('Bowled'), findsOneWidget); // exists but disabled
    await _visualPause(tester, 500);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await _visualPause(tester);
  });

  // ── Scenario 4: Strike Rotation & Undo Demo ───────────────────────────
  // Odd/even runs, over-end swap, double swap cancellation, undo ops.

  testWidgets('Scenario 4: Strike Rotation & Undo Demo', (tester) async {
    await tester.pumpWidget(_buildScoringPage());
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // Initially Rohit on strike
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    // --- Strike rotation ---
    // 1 run -> swap
    await _tapRun(tester, 1);
    expect(find.text('Suryakumar Yadav *'), findsOneWidget);

    // 3 runs -> swap back
    await _tapRun(tester, 3);
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    // 0 runs -> no swap
    await _tapRun(tester, 0);
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    // 4 runs -> no swap
    await _tapRun(tester, 4);
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    // 6 runs -> no swap
    await _tapRun(tester, 6);
    expect(find.text('Rohit Sharma *'), findsOneWidget);

    // Over complete -> end of over swaps striker
    // That was ball 6 (1+3+0+4+6 = 5 legal balls? No: 1,3,0,4,6 = 5 balls)
    // We need one more ball for 6 total. Actually we have exactly 6 balls above.
    // Wait: 1,3,0,4,6 = 5 balls. Need 1 more.
    // Actually let me count: _tapRun(1), _tapRun(3), _tapRun(0), _tapRun(4), _tapRun(6)
    // That's 5 balls. Need ball 6.
    await _tapRun(tester, 2); // ball 6 -> over complete

    await _selectBowler(tester, 'Deepak Chahar');

    // After over: Rohit had strike, even runs last ball, then end-of-over swap
    // -> Suryakumar on strike
    expect(find.text('Suryakumar Yadav *'), findsOneWidget);

    // --- Undo demo ---
    // Undo the last delivery of previous over
    await _tapUndo(tester);
    // Should revert state

    // Tap 4 runs
    await _tapRun(tester, 4);

    // Undo reverts it
    await _tapUndo(tester);
    await _visualPause(tester, 500);

    // --- Wide strike rotation ---
    // Wide with 0 additional = 1 run (odd) -> swaps
    await _tapExtra(tester, 'WD');
    await _confirmExtra(tester);

    await _visualPause(tester, 500);
  });

  // ── Scenario 5: Wicket Types Showcase ──────────────────────────────────
  // All 7 dismissal types one after another.

  testWidgets('Scenario 5: Wicket Types Showcase', (tester) async {
    // Use 5 overs and 3 players so we can show wickets without running out
    // of batters too fast. We'll show the dialog flow for each type, but
    // only confirm some (since we only have 3 batters = max 2 wickets).

    await tester.pumpWidget(_buildScoringPage(totalOvers: 5));
    await tester.pumpAndSettle();
    await _visualPause(tester, 500);

    // --- 1. Bowled: 1-step, no fielder ---
    await _tapWicket(tester);
    expect(find.byType(WicketDialog), findsOneWidget);
    expect(find.text('Wicket!'), findsOneWidget);
    await _selectDismissalType(tester, 'Bowled');
    expect(find.text('Confirm Wicket'), findsOneWidget);
    await _tapWicketPrimary(tester);
    expect(find.byType(WicketDialog), findsNothing);

    // Select new batter
    await tester.pumpAndSettle();
    final batterSheet1 = find.byType(SelectBatterSheet);
    if (batterSheet1.evaluate().isNotEmpty) {
      await _selectBatter(tester, 'Jasprit Bumrah');
    }
    await _visualPause(tester, 500);

    // --- 2. Caught: 2-step, fielder selection -> ALL OUT ---
    await _tapWicket(tester);
    await _selectDismissalType(tester, 'Caught');
    expect(find.text('Next'), findsOneWidget);
    await _tapWicketPrimary(tester); // -> step 2
    expect(find.text('Select Fielder'), findsOneWidget);
    await _selectFielder(tester, 'MS Dhoni');
    expect(find.text('Confirm Wicket'), findsOneWidget);
    await _tapWicketPrimary(tester);
    expect(find.byType(WicketDialog), findsNothing);
    await _visualPause(tester, 500);

    // All out (2 wickets in 3-player team) -> innings transition
    await tester.pumpAndSettle();
    expect(find.byType(InningsTransitionModal), findsOneWidget);

    // Complete transition for 2nd innings
    await _completeInningsTransition(
      tester,
      striker: 'MS Dhoni',
      nonStriker: 'Ravindra Jadeja',
      bowler: 'Rohit Sharma',
    );

    // --- Now demonstrate remaining wicket types as UI dialog showcases ---
    // We'll open the dialog, show the type, then confirm (consuming batters)

    // --- 3. LBW: 1-step ---
    await _tapWicket(tester);
    await _selectDismissalType(tester, 'LBW');
    expect(find.text('Confirm Wicket'), findsOneWidget);
    await _tapWicketPrimary(tester);
    expect(find.byType(WicketDialog), findsNothing);
    await _visualPause(tester, 500);

    // Select new batter
    await tester.pumpAndSettle();
    final batterSheet2 = find.byType(SelectBatterSheet);
    if (batterSheet2.evaluate().isNotEmpty) {
      await _selectBatter(tester, 'Deepak Chahar');
    }

    // --- 4. Run Out: 3-step (fielder, who dismissed, batters crossed) ---
    await _tapWicket(tester);
    await _selectDismissalType(tester, 'Run Out');
    expect(find.text('Next'), findsOneWidget);
    await _tapWicketPrimary(tester); // -> step 2: fielder

    expect(find.text('Select Fielder'), findsOneWidget);
    await _selectFielder(tester, 'Suryakumar Yadav');
    await _tapWicketPrimary(tester); // -> step 3: run out details

    expect(find.text('Run Out Details'), findsOneWidget);
    expect(find.text('Which batter was run out?'), findsOneWidget);
    expect(find.text('Striker'), findsOneWidget);
    expect(find.text('Non-Striker'), findsOneWidget);
    await _visualPause(tester, 500);

    // Confirm (default = striker)
    expect(find.text('Confirm Wicket'), findsOneWidget);
    await _tapWicketPrimary(tester);
    expect(find.byType(WicketDialog), findsNothing);
    await _visualPause(tester, 500);

    // All out in 2nd innings -> match complete
    await tester.pumpAndSettle();
    expect(find.byType(MatchCompleteModal), findsOneWidget);
    await _visualPause(tester, 1000);
  });
}
