import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/analytics/presentation/widgets/manhattan_chart.dart';
import 'package:cricapp/src/features/analytics/presentation/widgets/mvp_ranking_widget.dart';
import 'package:cricapp/src/features/analytics/presentation/widgets/run_rate_chart.dart';
import 'package:cricapp/src/features/analytics/presentation/widgets/worm_chart.dart';
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

  Future<void> navigateToAnalyticsTab(WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
  }

  group('ScorecardPage Analytics Tab', () {
    testWidgets('analytics tab shows 4 sub-tabs', (tester) async {
      await navigateToAnalyticsTab(tester);

      expect(find.text('Manhattan'), findsOneWidget);
      expect(find.text('Worm'), findsOneWidget);
      expect(find.text('Run Rate'), findsOneWidget);
      expect(find.text('MVP'), findsOneWidget);
    });

    testWidgets('manhattan tab is shown by default', (tester) async {
      await navigateToAnalyticsTab(tester);

      // Manhattan chart should be visible
      expect(find.byType(ManhattanChart), findsOneWidget);
      expect(find.text('Runs Per Over — Team A Innings'), findsOneWidget);
    });

    testWidgets('manhattan tab has innings toggle chips', (tester) async {
      await navigateToAnalyticsTab(tester);

      expect(find.text('1st Innings'), findsOneWidget);
      expect(find.text('2nd Innings'), findsOneWidget);
    });

    testWidgets('manhattan innings toggle switches data', (tester) async {
      await navigateToAnalyticsTab(tester);

      // Initially shows 1st innings
      expect(find.text('Runs Per Over — Team A Innings'), findsOneWidget);

      // Tap 2nd innings toggle
      await tester.tap(find.text('2nd Innings'));
      await tester.pumpAndSettle();

      // Should now show 2nd innings
      expect(find.text('Runs Per Over — Team B Innings'), findsOneWidget);
    });

    testWidgets('worm tab shows line chart', (tester) async {
      await navigateToAnalyticsTab(tester);

      // Navigate to Worm sub-tab
      await tester.tap(find.text('Worm'));
      await tester.pumpAndSettle();

      expect(find.byType(WormChart), findsOneWidget);
      expect(find.text('Cumulative Runs Comparison'), findsOneWidget);
    });

    testWidgets('run rate tab shows line chart', (tester) async {
      await navigateToAnalyticsTab(tester);

      // Navigate to Run Rate sub-tab
      await tester.tap(find.text('Run Rate'));
      await tester.pumpAndSettle();

      expect(find.byType(RunRateChart), findsOneWidget);
      expect(find.text('Run Rate Per Over'), findsOneWidget);
    });

    testWidgets('mvp tab shows ranking widget', (tester) async {
      await navigateToAnalyticsTab(tester);

      // Navigate to MVP sub-tab
      await tester.tap(find.text('MVP'));
      await tester.pumpAndSettle();

      expect(find.byType(MvpRankingWidget), findsOneWidget);
    });

    testWidgets('mvp tab shows player names', (tester) async {
      await navigateToAnalyticsTab(tester);

      await tester.tap(find.text('MVP'));
      await tester.pumpAndSettle();

      // Players from the scorecard data should appear
      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('manhattan renders BarChart', (tester) async {
      await navigateToAnalyticsTab(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('no analytics coming soon placeholder', (tester) async {
      await navigateToAnalyticsTab(tester);

      expect(find.text('Analytics coming soon'), findsNothing);
    });

    testWidgets('worm shows both team legends', (tester) async {
      await navigateToAnalyticsTab(tester);

      await tester.tap(find.text('Worm'));
      await tester.pumpAndSettle();

      expect(find.text('Team A — 150/5'), findsOneWidget);
      expect(find.text('Team B — 120/8'), findsOneWidget);
    });
  });
}

// ── Test data ──────────────────────────────────────────────────────────

ScorecardData _createScorecardData() {
  // Create deliveries across multiple overs for chart data
  final firstDeliveries = [
    // Over 0: 4, W = 4 runs, wicket
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
    // Over 1: 6 = 6 runs
    Delivery(
      id: 'del-3',
      inningsId: 'inn-1',
      overNumber: 1,
      ballNumber: 1,
      sequenceNumber: 3,
      strikerId: 'p2',
      nonStrikerId: 'p3',
      bowlerId: 'b2',
      runsFromBat: 6,
      isBoundarySix: true,
    ),
  ];

  final secondDeliveries = [
    Delivery(
      id: 'del-4',
      inningsId: 'inn-2',
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p3',
      nonStrikerId: 'p4',
      bowlerId: 'p1',
      runsFromBat: 3,
    ),
    Delivery(
      id: 'del-5',
      inningsId: 'inn-2',
      overNumber: 0,
      ballNumber: 2,
      sequenceNumber: 2,
      strikerId: 'p4',
      nonStrikerId: 'p3',
      bowlerId: 'p1',
      runsFromBat: 2,
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
      'b2': const BowlerSpell(
        playerId: 'b2',
        displayName: 'Bowler 2',
        ballsBowled: 24,
        runsConceded: 35,
        wicketsTaken: 1,
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
    ],
    bowlingTeamPlayers: const [
      PlayingXIPlayer(playerId: 'b1', displayName: 'Bowler 1'),
      PlayingXIPlayer(playerId: 'b2', displayName: 'Bowler 2'),
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
      'p1': const BowlerSpell(
        playerId: 'p1',
        displayName: 'Player 1',
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
      PlayingXIPlayer(playerId: 'p1', displayName: 'Player 1'),
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
