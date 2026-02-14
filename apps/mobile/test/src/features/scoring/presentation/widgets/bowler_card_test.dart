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

    testWidgets('renders economy rate', (tester) async {
      await tester.pumpWidget(buildCard(bowler: spell));
      // Economy = (25 / 18) * 6 = 8.3
      expect(find.text('Ec 8.3'), findsOneWidget);
    });

    testWidgets('economy rate 0.0 when 0 balls bowled', (tester) async {
      const freshSpell = BowlerSpell(
        playerId: 'b-2',
        displayName: 'New Bowler',
        ballsBowled: 0,
        maidens: 0,
        runsConceded: 0,
        wicketsTaken: 0,
      );
      await tester.pumpWidget(buildCard(bowler: freshSpell));
      expect(find.text('Ec 0.0'), findsOneWidget);
    });

    testWidgets('renders overs display for partial over', (tester) async {
      const partial = BowlerSpell(
        playerId: 'b-3',
        displayName: 'Partial Bowler',
        ballsBowled: 8, // 1.2 overs
        maidens: 0,
        runsConceded: 12,
        wicketsTaken: 0,
      );
      await tester.pumpWidget(buildCard(bowler: partial));
      expect(find.text('1.2'), findsOneWidget);
    });

    testWidgets('renders expensive bowler stats', (tester) async {
      const expensive = BowlerSpell(
        playerId: 'b-4',
        displayName: 'Expensive Bowler',
        ballsBowled: 6, // 1 over
        maidens: 0,
        runsConceded: 24,
        wicketsTaken: 0,
      );
      await tester.pumpWidget(buildCard(bowler: expensive));
      // Economy = (24 / 6) * 6 = 24.0
      expect(find.text('Ec 24.0'), findsOneWidget);
    });
  });
}
