import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/utils/commentary_generator.dart';
import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/domain/entities/scorecard_data.dart';
import 'package:cricapp/src/features/scoring/domain/entities/wicket_info.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/pages/scorecard_page.dart';

void main() {
  late ScorecardData scorecardData;

  setUp(() {
    scorecardData = _createScorecardData();
  });

  Widget buildWidget({ScorecardData? data}) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ScorecardPage(data: data ?? scorecardData),
    );
  }

  group('ScorecardPage', () {
    group('AppBar', () {
      testWidgets('shows Match Details title', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Match Details'), findsOneWidget);
      });

      testWidgets('has back button', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('score comparison header', () {
      testWidgets('shows first innings team name', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Team A'), findsWidgets);
      });

      testWidgets('shows second innings team name', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Team B'), findsWidgets);
      });

      testWidgets('shows first innings score', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('150/5'), findsOneWidget);
      });

      testWidgets('shows second innings score', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('120/8'), findsOneWidget);
      });

      testWidgets('shows overs display', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('(20.0 ov)'), findsAtLeast(1));
      });

      testWidgets('shows VS separator', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('VS'), findsOneWidget);
      });
    });

    group('result banner', () {
      testWidgets('shows result description', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Team A won by 30 runs'), findsOneWidget);
      });
    });

    group('tabs', () {
      testWidgets('shows three tabs', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Scorecard'), findsOneWidget);
        expect(find.text('Commentary'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);
      });

      testWidgets('scorecard tab is active by default', (tester) async {
        await tester.pumpWidget(buildWidget());
        // The Batting header should be visible (scorecard tab active)
        expect(find.text('Batting'), findsOneWidget);
      });
    });

    group('scorecard tab', () {
      testWidgets('shows innings toggle chips', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Team A — 1st Inn'), findsOneWidget);
        expect(find.text('Team B — 2nd Inn'), findsOneWidget);
      });

      testWidgets('shows batting header', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Batting'), findsOneWidget);
      });

      testWidgets('shows batting table headers', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Batter'), findsOneWidget);
        expect(find.text('R'), findsAtLeast(1));
        expect(find.text('B'), findsAtLeast(1));
        expect(find.text('4s'), findsAtLeast(1));
        expect(find.text('6s'), findsAtLeast(1));
        expect(find.text('SR'), findsAtLeast(1));
      });

      testWidgets('shows batter names', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      });

      testWidgets('shows dismissal descriptions', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('b Bowler 1'), findsOneWidget);
        expect(find.text('not out'), findsOneWidget);
      });

      testWidgets('shows extras row', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Extras'), findsOneWidget);
      });

      testWidgets('shows total row', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.textContaining('Total'), findsOneWidget);
      });

      testWidgets('shows yet to bat section', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Yet to Bat'), findsOneWidget);
      });

      testWidgets('shows fall of wickets', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Fall of Wickets'), findsOneWidget);
      });

      testWidgets('shows bowling header', (tester) async {
        await tester.pumpWidget(buildWidget());
        // Scroll down using drag
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bowling'), findsOneWidget);
      });

      testWidgets('shows bowler names', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bowler 1'), findsOneWidget);
      });

      testWidgets('innings toggle switches to 2nd innings', (tester) async {
        await tester.pumpWidget(buildWidget());

        // Tap 2nd innings chip
        await tester.tap(find.text('Team B — 2nd Inn'));
        await tester.pumpAndSettle();

        // Should show 2nd innings batters
        expect(find.text('Player 3'), findsOneWidget);
        expect(find.text('Player 4'), findsOneWidget);
      });
    });

    group('commentary tab', () {
      testWidgets('shows commentary items in reverse chronological order',
          (tester) async {
        await tester.pumpWidget(buildWidget());

        // Tap commentary tab
        await tester.tap(find.text('Commentary'));
        await tester.pumpAndSettle();

        // Should show commentary for the selected innings
        // Last delivery appears first (reverse chrono)
        expect(find.textContaining('OUT! Bowled!'), findsOneWidget);
      });
    });

    group('analytics tab', () {
      testWidgets('shows analytics sub-tabs', (tester) async {
        await tester.pumpWidget(buildWidget());

        // Tap analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        expect(find.text('Manhattan'), findsOneWidget);
        expect(find.text('Worm'), findsOneWidget);
        expect(find.text('Run Rate'), findsOneWidget);
        expect(find.text('MVP'), findsOneWidget);
      });
    });
  });
}

// Helper to create test data
ScorecardData _createScorecardData() {
  // 1st innings deliveries
  final firstDeliveries = [
    Delivery(
      id: 'del-1',
      inningsId: 'inn-1',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsFromBat: 4,
      isBoundaryFour: true,
    ),
    Delivery(
      id: 'del-2',
      inningsId: 'inn-1',
      overNumber: 0,
      ballNumber: 2,
      sequenceNumber: 2,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      isWicket: true,
      wicketInfo: const WicketInfo(
        dismissedPlayerId: 'p1',
        dismissalType: DismissalType.bowled,
        bowlerCredited: true,
      ),
    ),
  ];

  // 2nd innings deliveries
  final secondDeliveries = [
    Delivery(
      id: 'del-3',
      inningsId: 'inn-2',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p3',
      nonStrikerId: 'p4',
      bowlerId: 'b3',
      runsFromBat: 6,
      isBoundarySix: true,
    ),
  ];

  final firstInnings = InningsData(
    teamName: 'Team A',
    teamId: 'team-a',
    totalRuns: 150,
    totalWickets: 5,
    totalBalls: 120,
    totalWides: 3,
    totalNoBalls: 2,
    totalByes: 1,
    totalLegByes: 1,
    totalExtras: 7,
    batterStats: {
      'p1': const BatterInnings(
        playerId: 'p1',
        displayName: 'Player 1',
        runsScored: 50,
        ballsFaced: 40,
        fours: 6,
        sixes: 2,
        isNotOut: false,
        dismissalType: DismissalType.bowled,
        dismissedByName: 'Bowler 1',
      ),
      'p2': const BatterInnings(
        playerId: 'p2',
        displayName: 'Player 2',
        runsScored: 80,
        ballsFaced: 60,
        fours: 8,
        sixes: 3,
      ),
    },
    bowlerStats: {
      'b1': const BowlerSpell(
        playerId: 'b1',
        displayName: 'Bowler 1',
        ballsBowled: 24,
        maidens: 1,
        runsConceded: 30,
        wicketsTaken: 2,
      ),
    },
    fallOfWickets: [
      const FallOfWicket(
        wicketNumber: 1,
        scoreAtFall: 45,
        oversAtFall: '5.2',
        dismissedPlayerName: 'Player 1',
      ),
    ],
    deliveryHistory: firstDeliveries,
    battingTeamPlayers: const [
      PlayingXIPlayer(playerId: 'p1', displayName: 'Player 1'),
      PlayingXIPlayer(playerId: 'p2', displayName: 'Player 2'),
      PlayingXIPlayer(playerId: 'p5', displayName: 'Player 5'),
      PlayingXIPlayer(playerId: 'p6', displayName: 'Player 6'),
    ],
    bowlingTeamPlayers: const [
      PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
    ],
  );

  final secondInnings = InningsData(
    teamName: 'Team B',
    teamId: 'team-b',
    totalRuns: 120,
    totalWickets: 8,
    totalBalls: 120,
    totalWides: 2,
    totalNoBalls: 1,
    totalByes: 0,
    totalLegByes: 1,
    totalExtras: 4,
    batterStats: {
      'p3': const BatterInnings(
        playerId: 'p3',
        displayName: 'Player 3',
        runsScored: 60,
        ballsFaced: 50,
        fours: 5,
        sixes: 2,
      ),
      'p4': const BatterInnings(
        playerId: 'p4',
        displayName: 'Player 4',
        runsScored: 35,
        ballsFaced: 30,
        fours: 3,
        sixes: 1,
      ),
    },
    bowlerStats: {
      'b3': const BowlerSpell(
        playerId: 'b3',
        displayName: 'Bowler 3',
        ballsBowled: 24,
        runsConceded: 28,
        wicketsTaken: 3,
      ),
    },
    fallOfWickets: const [],
    deliveryHistory: secondDeliveries,
    battingTeamPlayers: const [
      PlayingXIPlayer(playerId: 'p3', displayName: 'Player 3'),
      PlayingXIPlayer(playerId: 'p4', displayName: 'Player 4'),
    ],
    bowlingTeamPlayers: const [
      PlayingXIPlayer(playerId: 'b3', displayName: 'Bowler 3'),
    ],
  );

  return ScorecardData(
    matchId: 'match-1',
    totalOvers: 20,
    playersPerSide: 11,
    firstInnings: firstInnings,
    secondInnings: secondInnings,
    matchResult: const MatchResult(
      winnerTeamId: 'team-a',
      winnerTeamName: 'Team A',
      resultType: MatchResultType.runs,
      margin: 30,
      resultDescription: 'Team A won by 30 runs',
    ),
  );
}
