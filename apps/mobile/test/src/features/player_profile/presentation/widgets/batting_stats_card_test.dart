import 'package:cricscores/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricscores/src/features/player_profile/presentation/widgets/batting_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(BattingCareerStats? stats) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BattingStatsCard(stats: stats),
        ),
      ),
    );
  }

  const testBatting = BattingCareerStats(
    matchesPlayed: 28,
    inningsBatted: 27,
    totalRuns: 892,
    highestScore: 98,
    notOuts: 3,
    fifties: 7,
    hundreds: 0,
    fours: 96,
    sixes: 32,
    ducks: 2,
    battingAverage: 36.16,
    battingStrikeRate: 134.53,
  );

  group('BattingStatsCard', () {
    testWidgets('displays all batting stat rows', (tester) async {
      await tester.pumpWidget(buildWidget(testBatting));
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Innings'), findsOneWidget);
      expect(find.text('Runs'), findsOneWidget);
      expect(find.text('Highest Score'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('Strike Rate'), findsOneWidget);
      expect(find.text('50s / 100s'), findsOneWidget);
      expect(find.text('Fours'), findsOneWidget);
      expect(find.text('Sixes'), findsOneWidget);
      expect(find.text('Not Outs'), findsOneWidget);
      expect(find.text('Ducks'), findsOneWidget);
    });

    testWidgets('displays correct values', (tester) async {
      await tester.pumpWidget(buildWidget(testBatting));
      expect(find.text('28'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(find.text('892'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
      expect(find.text('36.16'), findsOneWidget);
      expect(find.text('134.53'), findsOneWidget);
      expect(find.text('7 / 0'), findsOneWidget);
      expect(find.text('96'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows empty message when stats is null', (tester) async {
      await tester.pumpWidget(buildWidget(null));
      expect(find.text('No batting stats available'), findsOneWidget);
    });
  });
}
