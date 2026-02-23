import 'package:cricscores/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricscores/src/features/player_profile/presentation/widgets/quick_stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(CareerStats? stats) {
    return MaterialApp(
      home: Scaffold(
        body: QuickStatsGrid(stats: stats),
      ),
    );
  }

  const testStats = CareerStats(
    format: 'all',
    batting: BattingCareerStats(
      matchesPlayed: 28,
      inningsBatted: 27,
      totalRuns: 892,
      highestScore: 98,
      notOuts: 3,
      fifties: 7,
      hundreds: 0,
      fours: 96,
      sixes: 32,
    ),
    bowling: BowlingCareerStats(
      inningsBowled: 5,
      oversBowled: '12.0',
      runsConceded: 84,
      wicketsTaken: 2,
      bestBowlingWickets: 1,
      bestBowlingRuns: 18,
      threeWicketHauls: 0,
      fiveWicketHauls: 0,
    ),
    fielding: FieldingCareerStats(catches: 14, runOuts: 3, stumpings: 0),
  );

  group('QuickStatsGrid', () {
    testWidgets('displays four stat items', (tester) async {
      await tester.pumpWidget(buildWidget(testStats));
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Runs'), findsOneWidget);
      expect(find.text('Wickets'), findsOneWidget);
      expect(find.text('Catches'), findsOneWidget);
    });

    testWidgets('displays correct stat values', (tester) async {
      await tester.pumpWidget(buildWidget(testStats));
      expect(find.text('28'), findsOneWidget);
      expect(find.text('892'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets('displays zeros when stats is null', (tester) async {
      await tester.pumpWidget(buildWidget(null));
      expect(find.text('0'), findsNWidgets(4));
    });
  });
}
