import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/this_over_display.dart';

void main() {
  Widget buildDisplay({
    required List<Delivery> deliveries,
    bool isFreeHitPending = false,
    int overNumber = 1,
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
        body: ThisOverDisplay(
          deliveries: deliveries,
          isFreeHitPending: isFreeHitPending,
          overNumber: overNumber,
        ),
      ),
    );
  }

  Delivery makeDelivery({
    int runsFromBat = 0,
    bool isWide = false,
    int wideRuns = 0,
    bool isNoBall = false,
    int noBallRuns = 0,
    bool isBye = false,
    int byeRuns = 0,
    bool isLegBye = false,
    int legByeRuns = 0,
    bool isWicket = false,
    bool isBoundaryFour = false,
    bool isBoundarySix = false,
    bool isFreeHit = false,
  }) {
    return Delivery(
      id: 'del-1',
      inningsId: 'inn-1',
      overNumber: 1,
      ballNumber: 1,
      sequenceNumber: 1,
      strikerId: 'p-1',
      nonStrikerId: 'p-2',
      bowlerId: 'b-1',
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      isNoBall: isNoBall,
      noBallRuns: noBallRuns,
      isBye: isBye,
      byeRuns: byeRuns,
      isLegBye: isLegBye,
      legByeRuns: legByeRuns,
      isWicket: isWicket,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
      isFreeHit: isFreeHit,
    );
  }

  group('ThisOverDisplay', () {
    testWidgets('renders "This Over" label', (tester) async {
      await tester.pumpWidget(buildDisplay(deliveries: []));
      expect(find.text('This Over'), findsOneWidget);
    });

    testWidgets('empty deliveries shows no ball indicators', (tester) async {
      await tester.pumpWidget(buildDisplay(deliveries: []));
      // No notation text should appear
      expect(find.text('.'), findsNothing);
      expect(find.text('W'), findsNothing);
    });

    testWidgets('dot ball shows "." notation', (tester) async {
      final dot = makeDelivery(runsFromBat: 0);
      await tester.pumpWidget(buildDisplay(deliveries: [dot]));
      expect(find.text('.'), findsOneWidget);
    });

    testWidgets('single run shows "1"', (tester) async {
      final single = makeDelivery(runsFromBat: 1);
      await tester.pumpWidget(buildDisplay(deliveries: [single]));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('boundary four shows "4"', (tester) async {
      final four = makeDelivery(runsFromBat: 4, isBoundaryFour: true);
      await tester.pumpWidget(buildDisplay(deliveries: [four]));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('boundary six shows "6"', (tester) async {
      final six = makeDelivery(runsFromBat: 6, isBoundarySix: true);
      await tester.pumpWidget(buildDisplay(deliveries: [six]));
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('wicket shows "W"', (tester) async {
      final wicket = makeDelivery(isWicket: true);
      await tester.pumpWidget(buildDisplay(deliveries: [wicket]));
      expect(find.text('W'), findsOneWidget);
    });

    testWidgets('wide shows "Wd" notation', (tester) async {
      final wide = makeDelivery(isWide: true, wideRuns: 1);
      await tester.pumpWidget(buildDisplay(deliveries: [wide]));
      expect(find.text('Wd'), findsOneWidget);
    });

    testWidgets('no-ball shows "Nb" notation', (tester) async {
      final nb = makeDelivery(isNoBall: true, noBallRuns: 1);
      await tester.pumpWidget(buildDisplay(deliveries: [nb]));
      expect(find.text('Nb'), findsOneWidget);
    });

    testWidgets('free hit badge shown when pending', (tester) async {
      await tester
          .pumpWidget(buildDisplay(deliveries: [], isFreeHitPending: true));
      expect(find.text('FREE HIT'), findsOneWidget);
    });

    testWidgets('free hit badge not shown when not pending', (tester) async {
      await tester
          .pumpWidget(buildDisplay(deliveries: [], isFreeHitPending: false));
      expect(find.text('FREE HIT'), findsNothing);
    });
  });
}
