import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/bowler_card.dart';

void main() {
  Widget buildCard({required BowlerSpell bowler}) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: BowlerCard(bowler: bowler),
      ),
    );
  }

  const spell = BowlerSpell(
    playerId: 'b-1',
    displayName: 'Jasprit Bumrah',
    ballsBowled: 18,
    maidens: 1,
    runsConceded: 25,
    wicketsTaken: 2,
  );

  group('BowlerCard', () {
    testWidgets('renders bowler name', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      expect(find.text('Jasprit Bumrah'), findsOneWidget);
    });

    testWidgets('renders overs display', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      // 18 balls = 3.0 overs
      expect(find.text('3.0'), findsOneWidget);
    });

    testWidgets('renders maidens', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      expect(find.text('1'), findsOneWidget); // maidens
    });

    testWidgets('renders runs conceded', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('renders wickets taken', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      expect(find.text('2'), findsOneWidget);
    });
  });
}
