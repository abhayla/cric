import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/theme/app_colors.dart';
import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';

void main() {
  List<PlayingXIPlayer> makeChasingPlayers({int count = 11}) {
    return List.generate(
      count,
      (i) => PlayingXIPlayer(
        playerId: 'chase-${i + 1}',
        displayName: 'Chase Player ${i + 1}',
        playerRole: i < 3 ? 'batter' : (i < 6 ? 'bowler' : 'all_rounder'),
        battingStyle: i.isEven ? 'RHB' : 'LHB',
      ),
    );
  }

  List<PlayingXIPlayer> makeBowlingPlayers({int count = 11}) {
    return List.generate(
      count,
      (i) => PlayingXIPlayer(
        playerId: 'bowl-${i + 1}',
        displayName: 'Bowl Player ${i + 1}',
        playerRole: i < 5 ? 'bowler' : 'all_rounder',
        bowlingStyle: i < 5 ? 'RF' : 'SLA',
      ),
    );
  }

  List<FallOfWicket> makeFallOfWickets() {
    return const [
      FallOfWicket(
        wicketNumber: 1,
        scoreAtFall: 23,
        oversAtFall: '3.4',
        dismissedPlayerName: 'V. Sharma',
      ),
      FallOfWicket(
        wicketNumber: 2,
        scoreAtFall: 45,
        oversAtFall: '6.2',
        dismissedPlayerName: 'R. Patel',
      ),
    ];
  }

  List<BatterInnings> makeTopBatters() {
    return const [
      BatterInnings(
        playerId: 'bat-1',
        displayName: 'Star Batter',
        runsScored: 54,
        ballsFaced: 38,
      ),
      BatterInnings(
        playerId: 'bat-2',
        displayName: 'Good Batter',
        runsScored: 48,
        ballsFaced: 30,
        isNotOut: true,
      ),
    ];
  }

  BowlerSpell makeTopBowler() {
    return const BowlerSpell(
      playerId: 'bowl-top',
      displayName: 'Top Bowler',
      ballsBowled: 24,
      maidens: 0,
      runsConceded: 28,
      wicketsTaken: 3,
    );
  }

  Widget buildModal({
    String battingTeamName = 'Mumbai Warriors',
    String chasingTeamName = 'Delhi Strikers',
    int totalRuns = 187,
    int totalWickets = 6,
    String oversDisplay = '20.0',
    int totalExtras = 12,
    int totalWides = 5,
    int totalNoBalls = 3,
    int totalByes = 2,
    int totalLegByes = 2,
    double runRate = 9.35,
    int target = 188,
    int totalOvers = 20,
    List<FallOfWicket>? fallOfWickets,
    List<BatterInnings>? topBatters,
    BowlerSpell? topBowler,
    List<PlayingXIPlayer>? chasingTeamPlayers,
    List<PlayingXIPlayer>? bowlingTeamPlayers,
    ValueChanged<InningsTransitionResult>? onConfirm,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: InningsTransitionModal(
          battingTeamName: battingTeamName,
          chasingTeamName: chasingTeamName,
          totalRuns: totalRuns,
          totalWickets: totalWickets,
          oversDisplay: oversDisplay,
          totalExtras: totalExtras,
          totalWides: totalWides,
          totalNoBalls: totalNoBalls,
          totalByes: totalByes,
          totalLegByes: totalLegByes,
          runRate: runRate,
          target: target,
          totalOvers: totalOvers,
          fallOfWickets: fallOfWickets ?? makeFallOfWickets(),
          topBatters: topBatters ?? makeTopBatters(),
          topBowler: topBowler ?? makeTopBowler(),
          chasingTeamPlayers: chasingTeamPlayers ?? makeChasingPlayers(),
          bowlingTeamPlayers: bowlingTeamPlayers ?? makeBowlingPlayers(),
          onConfirm: onConfirm ?? (_) {},
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  group('InningsTransitionModal header', () {
    testWidgets('renders Innings Transition title', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Innings Transition'), findsOneWidget);
    });

    testWidgets('shows 3 stepper labels', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Openers'), findsOneWidget);
      expect(find.text('Bowler'), findsOneWidget);
    });
  });

  // ── Step 1: Innings Summary ─────────────────────────────────────────

  group('InningsTransitionModal step 1 - innings summary', () {
    testWidgets('displays score in "187/6" format', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('187/6'), findsOneWidget);
    });

    testWidgets('shows team name and overs', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('Mumbai Warriors'), findsWidgets);
      expect(find.textContaining('20.0'), findsOneWidget);
    });

    testWidgets('shows extras breakdown', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('Wd 5'), findsOneWidget);
      expect(find.textContaining('NB 3'), findsOneWidget);
      expect(find.textContaining('B 2'), findsOneWidget);
      expect(find.textContaining('LB 2'), findsOneWidget);
    });

    testWidgets('shows run rate', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('9.35'), findsOneWidget);
    });

    testWidgets('shows fall of wickets entries', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('1-23'), findsOneWidget);
      expect(find.textContaining('V. Sharma'), findsOneWidget);
      expect(find.textContaining('2-45'), findsOneWidget);
      expect(find.textContaining('R. Patel'), findsOneWidget);
    });

    testWidgets('shows top batters', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('Star Batter'), findsOneWidget);
      expect(find.textContaining('54'), findsOneWidget);
      expect(find.textContaining('Good Batter'), findsOneWidget);
      expect(find.textContaining('48'), findsOneWidget);
    });

    testWidgets('shows top bowler', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('Top Bowler'), findsOneWidget);
      expect(find.textContaining('3-28'), findsOneWidget);
    });

    testWidgets('shows target for chasing team', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.textContaining('188'), findsOneWidget);
      expect(find.textContaining('Delhi Strikers'), findsOneWidget);
    });

    testWidgets('shows required run rate', (tester) async {
      await tester.pumpWidget(buildModal());
      // RRR = 188 / 20 = 9.40
      expect(find.textContaining('9.40'), findsOneWidget);
    });
  });

  // ── Step Navigation ─────────────────────────────────────────────────

  group('InningsTransitionModal step navigation', () {
    testWidgets('Back button disabled on step 1', (tester) async {
      await tester.pumpWidget(buildModal());
      final backButton = find.widgetWithText(TextButton, 'Back');
      expect(tester.widget<TextButton>(backButton).onPressed, isNull);
    });

    testWidgets('Next advances from step 1 to step 2', (tester) async {
      await tester.pumpWidget(buildModal());
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Select Opening Batters'), findsOneWidget);
    });

    testWidgets('Back goes from step 2 to step 1', (tester) async {
      await tester.pumpWidget(buildModal());
      // Go to step 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Go back to step 1
      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('187/6'), findsOneWidget);
    });

    testWidgets('step 3 shows Start Innings button text', (tester) async {
      await tester.pumpWidget(buildModal());
      // Step 1 → 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select 2 batters
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      await tester.tap(find.text('Chase Player 2'));
      await tester.pump();
      // Step 2 → 3
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Start Innings'), findsOneWidget);
    });
  });

  // ── Step 2: Opening Batters ─────────────────────────────────────────

  group('InningsTransitionModal step 2 - opening batters', () {
    Future<void> goToStep2(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows chasing team players', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      expect(find.text('Chase Player 1'), findsOneWidget);
      expect(find.text('Chase Player 2'), findsOneWidget);
    });

    testWidgets('tapping player toggles selection', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      // Tap first player
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      // Should show a check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('can select exactly 2 players', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      await tester.tap(find.text('Chase Player 2'));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('selecting 3rd deselects first selected', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      await tester.tap(find.text('Chase Player 2'));
      await tester.pump();
      // Select a 3rd
      await tester.tap(find.text('Chase Player 3'));
      await tester.pump();
      // Should still have exactly 2 checks
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('striker designation appears when 2 selected', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      // Before selecting 2 — no striker section
      expect(find.text('Who will face the first ball?'), findsNothing);
      // Select 2
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      await tester.tap(find.text('Chase Player 2'));
      await tester.pump();
      expect(find.text('Who will face the first ball?'), findsOneWidget);
    });

    testWidgets('Next disabled when fewer than 2 selected', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep2(tester);
      // Only 1 selected
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    });
  });

  // ── Step 3: Opening Bowler ──────────────────────────────────────────

  group('InningsTransitionModal step 3 - opening bowler', () {
    Future<void> goToStep3(WidgetTester tester) async {
      // Step 1 → 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      // Select 2 batters
      await tester.tap(find.text('Chase Player 1'));
      await tester.pump();
      await tester.tap(find.text('Chase Player 2'));
      await tester.pump();
      // Step 2 → 3
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows bowling team players', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep3(tester);
      expect(find.text('Bowl Player 1'), findsOneWidget);
      expect(find.text('Bowl Player 2'), findsOneWidget);
    });

    testWidgets('tapping player selects it (radio)', (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep3(tester);
      await tester.tap(find.text('Bowl Player 1'));
      await tester.pump();
      // Radio selection — one filled indicator
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('Start Innings disabled when no bowler selected',
        (tester) async {
      await tester.pumpWidget(buildModal());
      await goToStep3(tester);
      final startButton = find.widgetWithText(FilledButton, 'Start Innings');
      expect(tester.widget<FilledButton>(startButton).onPressed, isNull);
    });

    testWidgets('Start Innings returns correct InningsTransitionResult',
        (tester) async {
      InningsTransitionResult? result;
      await tester.pumpWidget(buildModal(
        onConfirm: (r) => result = r,
      ));
      await goToStep3(tester);
      // Select bowler
      await tester.tap(find.text('Bowl Player 1'));
      await tester.pump();
      // Tap Start Innings
      await tester.tap(find.widgetWithText(FilledButton, 'Start Innings'));
      await tester.pumpAndSettle();
      // Verify result
      expect(result, isNotNull);
      expect(result!.strikerId, 'chase-1');
      expect(result!.nonStrikerId, 'chase-2');
      expect(result!.bowlerId, 'bowl-1');
      expect(result!.strikerName, 'Chase Player 1');
      expect(result!.nonStrikerName, 'Chase Player 2');
      expect(result!.bowlerName, 'Bowl Player 1');
    });
  });
}
