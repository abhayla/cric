import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricapp/src/features/home/presentation/widgets/my_stats_card.dart';

void main() {
  Widget buildTestWidget(CareerStats stats) {
    return MaterialApp(
      home: Scaffold(
        body: MyStatsCard(stats: stats),
      ),
    );
  }

  final sampleStats = CareerStats(
    format: 'all',
    batting: const BattingCareerStats(
      matchesPlayed: 28,
      inningsBatted: 25,
      totalRuns: 892,
      highestScore: 102,
      notOuts: 3,
      fifties: 5,
      hundreds: 1,
      fours: 95,
      sixes: 22,
      battingAverage: 31.86,
      battingStrikeRate: 125.0,
    ),
    bowling: const BowlingCareerStats(
      inningsBowled: 20,
      oversBowled: '48.0',
      runsConceded: 380,
      wicketsTaken: 12,
      bestBowlingWickets: 3,
      bestBowlingRuns: 20,
      threeWicketHauls: 1,
      fiveWicketHauls: 0,
      bowlingAverage: 31.67,
      bowlingEconomy: 7.92,
      bowlingStrikeRate: 24.0,
    ),
    fielding: const FieldingCareerStats(
      catches: 8,
      runOuts: 2,
      stumpings: 0,
    ),
  );

  group('MyStatsCard', () {
    testWidgets('renders 4 stat columns', (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleStats));

      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Runs'), findsOneWidget);
      expect(find.text('Wickets'), findsOneWidget);
      expect(find.text('Avg'), findsOneWidget);
    });

    testWidgets('displays correct stat values', (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleStats));

      expect(find.text('28'), findsOneWidget);
      expect(find.text('892'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('31.86'), findsOneWidget);
    });

    testWidgets('handles zero values', (tester) async {
      final zeroStats = CareerStats(
        format: 'all',
        batting: const BattingCareerStats(
          matchesPlayed: 0,
          inningsBatted: 0,
          totalRuns: 0,
          highestScore: 0,
          notOuts: 0,
          fifties: 0,
          hundreds: 0,
          fours: 0,
          sixes: 0,
        ),
        bowling: const BowlingCareerStats(
          inningsBowled: 0,
          oversBowled: '0.0',
          runsConceded: 0,
          wicketsTaken: 0,
          bestBowlingWickets: 0,
          bestBowlingRuns: 0,
          threeWicketHauls: 0,
          fiveWicketHauls: 0,
        ),
        fielding: const FieldingCareerStats(
          catches: 0,
          runOuts: 0,
          stumpings: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(zeroStats));

      // Should show "0" for matches, runs, wickets, and "-" for avg
      expect(find.text('0'), findsNWidgets(3)); // Matches, Runs, Wickets
      expect(find.text('-'), findsOneWidget); // Avg (null)
    });

    testWidgets('displays labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleStats));

      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Runs'), findsOneWidget);
      expect(find.text('Wickets'), findsOneWidget);
      expect(find.text('Avg'), findsOneWidget);
    });

    testWidgets('handles large values', (tester) async {
      final bigStats = CareerStats(
        format: 'all',
        batting: const BattingCareerStats(
          matchesPlayed: 999,
          inningsBatted: 900,
          totalRuns: 25000,
          highestScore: 264,
          notOuts: 50,
          fifties: 80,
          hundreds: 40,
          fours: 2500,
          sixes: 1000,
          battingAverage: 45.50,
          battingStrikeRate: 90.0,
        ),
        bowling: const BowlingCareerStats(
          inningsBowled: 500,
          oversBowled: '1500.0',
          runsConceded: 12000,
          wicketsTaken: 500,
          bestBowlingWickets: 8,
          bestBowlingRuns: 15,
          threeWicketHauls: 25,
          fiveWicketHauls: 10,
          bowlingAverage: 24.0,
          bowlingEconomy: 8.0,
          bowlingStrikeRate: 18.0,
        ),
        fielding: const FieldingCareerStats(
          catches: 200,
          runOuts: 50,
          stumpings: 30,
        ),
      );

      await tester.pumpWidget(buildTestWidget(bigStats));

      expect(find.text('999'), findsOneWidget);
      expect(find.text('25000'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });
  });
}
