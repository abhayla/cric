import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/analytics/domain/entities/mvp_data.dart';
import 'package:cricapp/src/features/analytics/presentation/widgets/mvp_ranking_widget.dart';

void main() {
  Widget buildWidget(MatchMvpData data) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: MvpRankingWidget(data: data),
      ),
    );
  }

  group('MvpRankingWidget', () {
    testWidgets('shows correct number of cards', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(5)));

      expect(find.byType(Card), findsNWidgets(5));
    });

    testWidgets('shows player names', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(3)));

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
      expect(find.text('Player 3'), findsOneWidget);
    });

    testWidgets('shows team names', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(2)));

      expect(find.text('Team A'), findsAtLeast(1));
    });

    testWidgets('shows points for each player', (tester) async {
      const data = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Player 1',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 10.0,
            bowlingPoints: 5.0,
            fieldingPoints: 1.5,
            totalPoints: 16.5,
            performanceSummary: '80(50)',
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('16.5'), findsOneWidget);
      expect(find.text('pts'), findsOneWidget);
    });

    testWidgets('shows performance summary', (tester) async {
      const data = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Player 1',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 8.0,
            bowlingPoints: 3.0,
            fieldingPoints: 0.0,
            totalPoints: 11.0,
            performanceSummary: '54(38), 1/20',
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('54(38), 1/20'), findsOneWidget);
    });

    testWidgets('top 3 have medal badge colors', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(5)));

      // Look for colored circle containers (medal badges)
      final containers = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle &&
            (w.decoration as BoxDecoration).color != null),
      );

      // Should have at least 3 medal badges (gold, silver, bronze)
      // Plus avatar circles
      expect(containers.length, greaterThanOrEqualTo(3));
    });

    testWidgets('rank 4+ does not have medal badge', (tester) async {
      final data = MatchMvpData(
        rankings: List.generate(
          5,
          (i) => MvpPlayerScore(
            playerId: 'p${i + 1}',
            displayName: 'Player ${i + 1}',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: (5 - i).toDouble(),
            bowlingPoints: 0,
            fieldingPoints: 0,
            totalPoints: (5 - i).toDouble(),
            performanceSummary: '${(5 - i) * 10}(${(5 - i) * 8})',
          ),
        ),
      );

      await tester.pumpWidget(buildWidget(data));

      // Ranks 4 and 5 should show as plain text numbers
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('empty rankings shows no MVP data message', (tester) async {
      await tester.pumpWidget(buildWidget(const MatchMvpData(rankings: [])));

      expect(find.text('No MVP data available'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('single player shows one card', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(1)));

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('player initials shown in avatar', (tester) async {
      const data = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Virat Kohli',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 15.0,
            bowlingPoints: 0.0,
            fieldingPoints: 3.0,
            totalPoints: 18.0,
            performanceSummary: '100(60)',
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('VK'), findsOneWidget);
    });

    testWidgets('scrollable list with many players', (tester) async {
      await tester.pumpWidget(buildWidget(_createMvpData(15)));

      // Should render as a ListView
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('points displayed with one decimal place', (tester) async {
      const data = MatchMvpData(
        rankings: [
          MvpPlayerScore(
            playerId: 'p1',
            displayName: 'Player 1',
            teamName: 'Team A',
            teamId: 'team-a',
            battingPoints: 10.2,
            bowlingPoints: 5.3,
            fieldingPoints: 1.5,
            totalPoints: 17.0,
            performanceSummary: '65(40), 2/28, 1 ct',
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(data));
      expect(find.text('17.0'), findsOneWidget);
    });
  });
}

MatchMvpData _createMvpData(int playerCount) {
  return MatchMvpData(
    rankings: List.generate(
      playerCount,
      (i) => MvpPlayerScore(
        playerId: 'p${i + 1}',
        displayName: 'Player ${i + 1}',
        teamName: i.isEven ? 'Team A' : 'Team B',
        teamId: i.isEven ? 'team-a' : 'team-b',
        battingPoints: (playerCount - i) * 2.0,
        bowlingPoints: (playerCount - i) * 1.0,
        fieldingPoints: (playerCount - i) * 0.5,
        totalPoints: (playerCount - i) * 3.5,
        performanceSummary: '${(playerCount - i) * 10}(${(playerCount - i) * 8})',
      ),
    ),
  );
}
