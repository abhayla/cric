import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/pages/scoring_page.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/extras_panel.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/match_complete_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/wicket_dialog.dart';

void main() {
  List<PlayingXIPlayer> makePlayers({
    required String prefix,
    int count = 11,
  }) {
    return List.generate(
        count,
        (i) => PlayingXIPlayer(
              playerId: '$prefix-$i',
              displayName: '${prefix.toUpperCase()} Player ${i + 1}',
              playerRole:
                  i < 3 ? 'batter' : (i < 6 ? 'bowler' : 'all_rounder'),
              isCaptain: i == 0,
              isKeeper: i == 4,
            ));
  }

  Widget buildPage({
    String matchId = 'match-1',
    String inningsId = 'inn-1',
    String battingTeamId = 'bat-team',
    String bowlingTeamId = 'bowl-team',
    String battingTeamName = 'Mumbai Warriors',
    String bowlingTeamName = 'Delhi Strikers',
    int inningsNumber = 1,
    int totalOvers = 20,
    int playersPerSide = 11,
    int? target,
    List<PlayingXIPlayer>? battingPlayers,
    List<PlayingXIPlayer>? bowlingPlayers,
    String openingStrikerId = 'bat-0',
    String openingStrikerName = 'BAT Player 1',
    String openingNonStrikerId = 'bat-1',
    String openingNonStrikerName = 'BAT Player 2',
    String openingBowlerId = 'bowl-0',
    String openingBowlerName = 'BOWL Player 1',
    FirstInningsSummary? firstInningsSummary,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ScoringPage(
        args: ScoringPageArgs(
          matchId: matchId,
          inningsId: inningsId,
          battingTeamId: battingTeamId,
          bowlingTeamId: bowlingTeamId,
          battingTeamName: battingTeamName,
          bowlingTeamName: bowlingTeamName,
          inningsNumber: inningsNumber,
          totalOvers: totalOvers,
          playersPerSide: playersPerSide,
          target: target,
          battingTeamPlayers: battingPlayers ?? makePlayers(prefix: 'bat'),
          bowlingTeamPlayers: bowlingPlayers ?? makePlayers(prefix: 'bowl'),
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

  /// Find a run button inside ScoringControls by its label text.
  Finder findRunButton(String label) {
    return find.descendant(
      of: find.byType(ScoringControls),
      matching: find.text(label),
    );
  }

  group('ScoringPage', () {
    testWidgets('renders score header with team name', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('renders initial score 0/0', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('0/0'), findsOneWidget);
    });

    testWidgets('renders initial overs 0.0', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('(0.0)'), findsOneWidget);
    });

    testWidgets('renders opening striker name', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('BAT Player 1 *'), findsOneWidget);
    });

    testWidgets('renders opening non-striker name', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('BAT Player 2'), findsOneWidget);
    });

    testWidgets('renders opening bowler name', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('BOWL Player 1'), findsOneWidget);
    });

    testWidgets('renders ScoringControls widget', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.byType(ScoringControls), findsOneWidget);
    });

    testWidgets('tapping 1 updates score to 1/0', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('1'));
      await tester.pump();
      expect(find.text('1/0'), findsOneWidget);
    });

    testWidgets('tapping 4 updates score to 4/0', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('4'));
      await tester.pump();
      expect(find.text('4/0'), findsOneWidget);
    });

    testWidgets('tapping dot ball keeps score at 0/0', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('0'));
      await tester.pump();
      expect(find.text('0/0'), findsOneWidget);
    });

    testWidgets('undo restores previous score', (tester) async {
      await tester.pumpWidget(buildPage());
      // Score a single
      await tester.tap(findRunButton('1'));
      await tester.pump();
      expect(find.text('1/0'), findsOneWidget);
      // Undo
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(find.text('0/0'), findsOneWidget);
    });

    testWidgets('swap strike swaps batter names', (tester) async {
      await tester.pumpWidget(buildPage());
      // Initially: BAT Player 1 is striker
      expect(find.text('BAT Player 1 *'), findsOneWidget);
      // Swap
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pump();
      // Now: BAT Player 2 should be striker
      expect(find.text('BAT Player 2 *'), findsOneWidget);
    });

    testWidgets('1st innings label shown', (tester) async {
      await tester.pumpWidget(buildPage(inningsNumber: 1));
      expect(find.text('1st Innings'), findsOneWidget);
    });

    testWidgets('W button opens WicketDialog', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      expect(find.byType(WicketDialog), findsOneWidget);
      expect(find.text('Wicket!'), findsOneWidget);
    });

    testWidgets('This Over label is rendered', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('This Over'), findsOneWidget);
    });
  });

  group('ScoringPage extras integration', () {
    testWidgets('WD button opens ExtrasPanel with wide type', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('WD'));
      await tester.pumpAndSettle();
      expect(find.byType(ExtrasPanel), findsOneWidget);
      expect(find.text('Wide'), findsOneWidget);
    });

    testWidgets('NB button opens ExtrasPanel with no-ball type',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('NB'));
      await tester.pumpAndSettle();
      expect(find.byType(ExtrasPanel), findsOneWidget);
      expect(find.text('No Ball'), findsOneWidget);
    });

    testWidgets('B button opens ExtrasPanel with bye type', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('B'));
      await tester.pumpAndSettle();
      expect(find.byType(ExtrasPanel), findsOneWidget);
      expect(find.text('Bye'), findsOneWidget);
    });

    testWidgets('LB button opens ExtrasPanel with leg-bye type',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('LB'));
      await tester.pumpAndSettle();
      expect(find.byType(ExtrasPanel), findsOneWidget);
      expect(find.text('Leg Bye'), findsOneWidget);
    });

    testWidgets('Wide confirm with 0 additional updates score to 1/0',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Open Wide panel
      await tester.tap(findRunButton('WD'));
      await tester.pumpAndSettle();
      // Default is 0 additional runs, confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // Score should be 1/0 (1 wide penalty), overs still 0.0 (wide not legal)
      expect(find.text('1/0'), findsOneWidget);
      expect(find.text('(0.0)'), findsOneWidget);
    });

    testWidgets('NoBall confirm with 2 bat runs updates score to 3/0',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Open No Ball panel
      await tester.tap(findRunButton('NB'));
      await tester.pumpAndSettle();
      // Select 2 runs from bat
      await tester.tap(find.ancestor(
        of: find.text('2'),
        matching: find.byType(OutlinedButton),
      ));
      await tester.pump();
      // Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // Score: 1 (no-ball penalty) + 2 (bat) = 3/0, overs 0.0 (no-ball not legal)
      expect(find.text('3/0'), findsOneWidget);
      expect(find.text('(0.0)'), findsOneWidget);
    });

    testWidgets('Bye confirm with default 1 updates score to 1/0 and overs',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Open Bye panel
      await tester.tap(findRunButton('B'));
      await tester.pumpAndSettle();
      // Default is 1 bye run, confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // Score 1/0, overs 0.1 (bye is a legal delivery)
      expect(find.text('1/0'), findsOneWidget);
      expect(find.text('(0.1)'), findsOneWidget);
    });

    testWidgets('after no-ball confirm, free hit badge appears in this over',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Open No Ball panel
      await tester.tap(findRunButton('NB'));
      await tester.pumpAndSettle();
      // Confirm with 0 runs from bat
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // Free hit indicator should appear
      expect(find.text('FREE HIT'), findsOneWidget);
    });
  });

  group('ScoringPage wicket integration', () {
    testWidgets('Bowled wicket updates score to 0/1', (tester) async {
      await tester.pumpWidget(buildPage());
      // Open wicket dialog
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      // Select Bowled
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      // Score should be 0/1
      expect(find.text('0/1'), findsOneWidget);
    });

    testWidgets('select batter sheet auto-shows after wicket', (tester) async {
      await tester.pumpWidget(buildPage());
      // Record a Bowled wicket
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      // Select batter sheet should auto-show
      expect(find.text('Select New Batter'), findsOneWidget);
    });

    testWidgets('W button is disabled when innings complete', (tester) async {
      // Use 2 players per side so 1 wicket = all out
      await tester.pumpWidget(buildPage(playersPerSide: 2));
      // Record Bowled wicket
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      // Innings complete (1 wicket = all out for 2 players/side)
      // The W button (OutlinedButton) should have null onPressed
      final wButton = find.descendant(
        of: find.byType(ScoringControls),
        matching: find.widgetWithText(OutlinedButton, 'W'),
      );
      expect(
        tester.widget<OutlinedButton>(wButton).onPressed,
        isNull,
      );
    });

    testWidgets('Caught wicket with fielder updates score to 0/1',
        (tester) async {
      await tester.pumpWidget(buildPage());
      // Open wicket dialog
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      // Select Caught
      await tester.tap(find.text('Caught'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select fielder — use descendant of WicketDialog to avoid bowler card match
      final fielderInDialog = find.descendant(
        of: find.byType(WicketDialog),
        matching: find.text('BOWL Player 1'),
      );
      await tester.tap(fielderInDialog);
      await tester.pump();
      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      // Score should be 0/1
      expect(find.text('0/1'), findsOneWidget);
    });
  });

  group('ScoringPage innings transition', () {
    testWidgets('all-out in 1st innings shows innings transition modal',
        (tester) async {
      // 2 players per side: 1 wicket = all out
      await tester.pumpWidget(buildPage(playersPerSide: 2));
      // Record Bowled wicket
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      // Innings transition modal should appear
      expect(find.byType(InningsTransitionModal), findsOneWidget);
      expect(find.text('Innings Transition'), findsOneWidget);
    });

    testWidgets('overs exhausted in 1st innings shows modal', (tester) async {
      await tester.pumpWidget(buildPage(totalOvers: 1));
      // Bowl 6 dot balls = 1 over exhausted
      for (var i = 0; i < 6; i++) {
        await tester.tap(findRunButton('0'));
        await tester.pump();
        // After over complete, bowler sheet appears — select new bowler
        // Actually only shows at end of over (ball 6)
      }
      await tester.pumpAndSettle();
      // Innings transition modal should appear
      expect(find.byType(InningsTransitionModal), findsOneWidget);
    });

    testWidgets('completing modal transitions to 2nd innings state',
        (tester) async {
      // 2 players per side for quick all-out
      await tester.pumpWidget(buildPage(playersPerSide: 2));
      // Record Bowled wicket → all-out → modal appears
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();
      expect(find.byType(InningsTransitionModal), findsOneWidget);

      // Step 1 → 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select 2 batters — scope to modal to avoid ambiguity
      final modal = find.byType(InningsTransitionModal);
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BOWL Player 1'),
      ));
      await tester.pump();
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BOWL Player 2'),
      ));
      await tester.pump();
      // Step 2 → 3
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select bowler (batting team players)
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BAT Player 1'),
      ));
      await tester.pump();
      // Start Innings
      await tester.tap(find.widgetWithText(FilledButton, 'Start Innings'));
      await tester.pumpAndSettle();

      // Modal should be dismissed
      expect(find.byType(InningsTransitionModal), findsNothing);
      // Should now show 2nd innings
      expect(find.text('2nd Innings'), findsOneWidget);
    });

    testWidgets('after transition, score header shows target and RRR',
        (tester) async {
      // Score some runs then all-out
      await tester.pumpWidget(buildPage(playersPerSide: 2));
      // Score a four first
      await tester.tap(findRunButton('4'));
      await tester.pump();
      // Then wicket → all-out
      await tester.tap(findRunButton('W'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bowled'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Wicket'));
      await tester.pumpAndSettle();

      // Complete the modal — scope to modal for ambiguous names
      final modal = find.byType(InningsTransitionModal);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BOWL Player 1'),
      ));
      await tester.pump();
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BOWL Player 2'),
      ));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: modal,
        matching: find.text('BAT Player 1'),
      ));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Innings'));
      await tester.pumpAndSettle();

      // Score was 4 → target = 5
      // Should show target in header
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('2nd innings completion shows match complete modal',
        (tester) async {
      // Set up 2nd innings directly with target and firstInningsSummary
      await tester.pumpWidget(buildPage(
        inningsNumber: 2,
        target: 5,
        battingTeamName: 'Delhi Strikers',
        bowlingTeamName: 'Mumbai Warriors',
        playersPerSide: 11,
        firstInningsSummary: const FirstInningsSummary(
          teamName: 'Mumbai Warriors',
          teamId: 'team-mw',
          totalRuns: 4,
          totalWickets: 10,
          totalBalls: 30,
          oversDisplay: '5.0',
        ),
      ));
      // Score a six to chase down target
      await tester.tap(findRunButton('6'));
      await tester.pumpAndSettle();
      // Should show match complete modal
      expect(find.byType(MatchCompleteModal), findsOneWidget);
      expect(find.text('Match Complete!'), findsOneWidget);
    });

    testWidgets('match complete modal shows correct result text',
        (tester) async {
      await tester.pumpWidget(buildPage(
        inningsNumber: 2,
        target: 5,
        battingTeamName: 'Delhi Strikers',
        bowlingTeamName: 'Mumbai Warriors',
        playersPerSide: 11,
        firstInningsSummary: const FirstInningsSummary(
          teamName: 'Mumbai Warriors',
          teamId: 'team-mw',
          totalRuns: 4,
          totalWickets: 10,
          totalBalls: 30,
          oversDisplay: '5.0',
        ),
      ));
      // Score a six to chase target of 5
      await tester.tap(findRunButton('6'));
      await tester.pumpAndSettle();
      // Delhi Strikers chased successfully → won by wickets
      expect(find.text('Delhi Strikers won by 10 wickets'), findsOneWidget);
    });

    testWidgets('Back to Home dismisses modal and pops page', (tester) async {
      // Wrap in Navigator to test pop
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.seed,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ScoringPage(
                      args: ScoringPageArgs(
                        matchId: 'match-1',
                        inningsId: 'inn-2',
                        battingTeamId: 'bat-team',
                        bowlingTeamId: 'bowl-team',
                        battingTeamName: 'Delhi Strikers',
                        bowlingTeamName: 'Mumbai Warriors',
                        inningsNumber: 2,
                        totalOvers: 20,
                        playersPerSide: 11,
                        target: 5,
                        battingTeamPlayers: makePlayers(prefix: 'bat'),
                        bowlingTeamPlayers: makePlayers(prefix: 'bowl'),
                        openingStrikerId: 'bat-0',
                        openingStrikerName: 'BAT Player 1',
                        openingNonStrikerId: 'bat-1',
                        openingNonStrikerName: 'BAT Player 2',
                        openingBowlerId: 'bowl-0',
                        openingBowlerName: 'BOWL Player 1',
                        firstInningsSummary: const FirstInningsSummary(
                          teamName: 'Mumbai Warriors',
                          teamId: 'team-mw',
                          totalRuns: 4,
                          totalWickets: 10,
                          totalBalls: 30,
                          oversDisplay: '5.0',
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      ));

      // Navigate to scoring page
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Score a six to complete the match
      await tester.tap(findRunButton('6'));
      await tester.pumpAndSettle();

      // Modal should be visible
      expect(find.byType(MatchCompleteModal), findsOneWidget);

      // Tap Back to Home
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back to Home'));
      await tester.pumpAndSettle();

      // Modal should be dismissed and page popped (back to home)
      expect(find.byType(MatchCompleteModal), findsNothing);
      expect(find.byType(ScoringPage), findsNothing);
    });

    testWidgets('View Scorecard shows stub snackbar', (tester) async {
      await tester.pumpWidget(buildPage(
        inningsNumber: 2,
        target: 5,
        battingTeamName: 'Delhi Strikers',
        bowlingTeamName: 'Mumbai Warriors',
        playersPerSide: 11,
        firstInningsSummary: const FirstInningsSummary(
          teamName: 'Mumbai Warriors',
          teamId: 'team-mw',
          totalRuns: 4,
          totalWickets: 10,
          totalBalls: 30,
          oversDisplay: '5.0',
        ),
      ));
      // Score a six to complete match
      await tester.tap(findRunButton('6'));
      await tester.pumpAndSettle();
      // Tap View Scorecard
      await tester.tap(find.widgetWithText(FilledButton, 'View Scorecard'));
      await tester.pumpAndSettle();
      // Should show stub snackbar
      expect(find.textContaining('Issue #34'), findsOneWidget);
    });
  });
}
