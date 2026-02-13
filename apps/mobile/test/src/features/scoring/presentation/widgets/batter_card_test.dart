import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/batter_card.dart';

void main() {
  Widget buildCard({
    required BatterInnings batter,
    bool isStriker = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: BatterCard(
          batter: batter,
          isStriker: isStriker,
        ),
      ),
    );
  }

  const striker = BatterInnings(
    playerId: 'p-1',
    displayName: 'Virat Kohli',
    runsScored: 45,
    ballsFaced: 32,
    fours: 5,
    sixes: 2,
    isOnStrike: true,
  );

  const nonStriker = BatterInnings(
    playerId: 'p-2',
    displayName: 'Rohit Sharma',
    runsScored: 28,
    ballsFaced: 20,
    fours: 3,
    sixes: 1,
    isOnStrike: false,
  );

  group('BatterCard', () {
    testWidgets('renders batter name', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.textContaining('Virat Kohli'), findsOneWidget);
    });

    testWidgets('renders runs scored', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('renders balls faced', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.text('(32)'), findsOneWidget);
    });

    testWidgets('renders fours count', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.text('5'), findsOneWidget); // fours
    });

    testWidgets('renders sixes count', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.text('2'), findsOneWidget); // sixes
    });

    testWidgets('striker shows asterisk in name', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      expect(find.text('Virat Kohli *'), findsOneWidget);
    });

    testWidgets('non-striker does not show asterisk', (tester) async {
      await tester.pumpWidget(buildCard(batter: nonStriker, isStriker: false));
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('Rohit Sharma *'), findsNothing);
    });

    testWidgets('renders strike rate', (tester) async {
      await tester.pumpWidget(buildCard(batter: striker, isStriker: true));
      // SR = (45/32) * 100 = 140.63
      expect(find.text('SR 140.63'), findsOneWidget);
    });
  });
}
