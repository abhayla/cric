import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricapp/src/features/player_profile/presentation/widgets/bowling_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(BowlingCareerStats? stats) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BowlingStatsCard(stats: stats),
        ),
      ),
    );
  }

  const testBowling = BowlingCareerStats(
    inningsBowled: 5,
    oversBowled: '12.0',
    runsConceded: 84,
    wicketsTaken: 2,
    bestBowlingWickets: 1,
    bestBowlingRuns: 18,
    threeWicketHauls: 0,
    fiveWicketHauls: 0,
    bowlingAverage: 42.0,
    bowlingEconomy: 7.0,
  );

  group('BowlingStatsCard', () {
    testWidgets('displays all bowling stat rows', (tester) async {
      await tester.pumpWidget(buildWidget(testBowling));
      expect(find.text('Innings'), findsOneWidget);
      expect(find.text('Overs'), findsOneWidget);
      expect(find.text('Wickets'), findsOneWidget);
      expect(find.text('Best Bowling'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('Economy'), findsOneWidget);
      expect(find.text('3 Wickets'), findsOneWidget);
      expect(find.text('5 Wickets'), findsOneWidget);
    });

    testWidgets('displays correct values', (tester) async {
      await tester.pumpWidget(buildWidget(testBowling));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('12.0'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1/18'), findsOneWidget);
      expect(find.text('42.00'), findsOneWidget);
      expect(find.text('7.00'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2)); // 3w and 5w
    });

    testWidgets('shows empty message when stats is null', (tester) async {
      await tester.pumpWidget(buildWidget(null));
      expect(find.text('No bowling stats available'), findsOneWidget);
    });
  });
}
