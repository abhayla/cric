import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricapp/src/features/player_profile/presentation/widgets/fielding_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(FieldingCareerStats? stats) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FieldingStatsCard(stats: stats),
        ),
      ),
    );
  }

  const testFielding = FieldingCareerStats(
    catches: 14,
    stumpings: 0,
    runOuts: 3,
  );

  group('FieldingStatsCard', () {
    testWidgets('displays all fielding stat rows', (tester) async {
      await tester.pumpWidget(buildWidget(testFielding));
      expect(find.text('Catches'), findsOneWidget);
      expect(find.text('Stumpings'), findsOneWidget);
      expect(find.text('Run Outs'), findsOneWidget);
    });

    testWidgets('displays correct values', (tester) async {
      await tester.pumpWidget(buildWidget(testFielding));
      expect(find.text('14'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows empty message when stats is null', (tester) async {
      await tester.pumpWidget(buildWidget(null));
      expect(find.text('No fielding stats available'), findsOneWidget);
    });
  });
}
