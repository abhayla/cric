import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/pages/scoring_page.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';

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

    testWidgets('extras button shows snackbar stub', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('WD'));
      await tester.pump();
      expect(find.textContaining('Extras panel'), findsOneWidget);
    });

    testWidgets('wicket button shows snackbar stub', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.tap(findRunButton('W'));
      await tester.pump();
      expect(find.textContaining('Wicket dialog'), findsOneWidget);
    });

    testWidgets('This Over label is rendered', (tester) async {
      await tester.pumpWidget(buildPage());
      expect(find.text('This Over'), findsOneWidget);
    });
  });
}
