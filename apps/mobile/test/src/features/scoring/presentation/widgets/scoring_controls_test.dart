import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/scoring_controls.dart';

void main() {
  Widget buildControls({
    ValueChanged<int>? onRunTap,
    VoidCallback? onWideTap,
    VoidCallback? onNoBallTap,
    VoidCallback? onByeTap,
    VoidCallback? onLegByeTap,
    VoidCallback? onWicketTap,
    VoidCallback? onUndoTap,
    VoidCallback? onSwapStrike,
    bool canUndo = true,
    bool isInningsComplete = false,
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
        body: ScoringControls(
          onRunTap: onRunTap ?? (_) {},
          onWideTap: onWideTap ?? () {},
          onNoBallTap: onNoBallTap ?? () {},
          onByeTap: onByeTap ?? () {},
          onLegByeTap: onLegByeTap ?? () {},
          onWicketTap: onWicketTap ?? () {},
          onUndoTap: onUndoTap ?? () {},
          onSwapStrike: onSwapStrike ?? () {},
          canUndo: canUndo,
          isInningsComplete: isInningsComplete,
        ),
      ),
    );
  }

  group('ScoringControls', () {
    testWidgets('renders run buttons 0-4 and 6', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('tapping run button 0 calls onRunTap with 0', (tester) async {
      int? tappedRuns;
      await tester
          .pumpWidget(buildControls(onRunTap: (runs) => tappedRuns = runs));
      await tester.tap(find.text('0'));
      expect(tappedRuns, 0);
    });

    testWidgets('tapping run button 1 calls onRunTap with 1', (tester) async {
      int? tappedRuns;
      await tester
          .pumpWidget(buildControls(onRunTap: (runs) => tappedRuns = runs));
      await tester.tap(find.text('1'));
      expect(tappedRuns, 1);
    });

    testWidgets('tapping run button 4 calls onRunTap with 4', (tester) async {
      int? tappedRuns;
      await tester
          .pumpWidget(buildControls(onRunTap: (runs) => tappedRuns = runs));
      await tester.tap(find.text('4'));
      expect(tappedRuns, 4);
    });

    testWidgets('tapping run button 6 calls onRunTap with 6', (tester) async {
      int? tappedRuns;
      await tester
          .pumpWidget(buildControls(onRunTap: (runs) => tappedRuns = runs));
      await tester.tap(find.text('6'));
      expect(tappedRuns, 6);
    });

    testWidgets('renders extras buttons', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.text('WD'), findsOneWidget);
      expect(find.text('NB'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('LB'), findsOneWidget);
    });

    testWidgets('renders wicket button', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.text('W'), findsOneWidget);
    });

    testWidgets('tapping Wide calls onWideTap', (tester) async {
      var called = false;
      await tester.pumpWidget(buildControls(onWideTap: () => called = true));
      await tester.tap(find.text('WD'));
      expect(called, isTrue);
    });

    testWidgets('tapping No Ball calls onNoBallTap', (tester) async {
      var called = false;
      await tester.pumpWidget(buildControls(onNoBallTap: () => called = true));
      await tester.tap(find.text('NB'));
      expect(called, isTrue);
    });

    testWidgets('tapping Wicket calls onWicketTap', (tester) async {
      var called = false;
      await tester.pumpWidget(buildControls(onWicketTap: () => called = true));
      await tester.tap(find.text('W'));
      expect(called, isTrue);
    });

    testWidgets('renders undo button', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('undo button calls onUndoTap when canUndo is true',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
          buildControls(onUndoTap: () => called = true, canUndo: true));
      await tester.tap(find.byIcon(Icons.undo));
      expect(called, isTrue);
    });

    testWidgets('undo button disabled when canUndo is false', (tester) async {
      var called = false;
      await tester.pumpWidget(
          buildControls(onUndoTap: () => called = true, canUndo: false));
      await tester.tap(find.byIcon(Icons.undo));
      expect(called, isFalse);
    });

    testWidgets('renders swap strike button', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('swap strike calls onSwapStrike', (tester) async {
      var called = false;
      await tester
          .pumpWidget(buildControls(onSwapStrike: () => called = true));
      await tester.tap(find.byIcon(Icons.swap_horiz));
      expect(called, isTrue);
    });

    testWidgets('overthrow button "..." is rendered', (tester) async {
      await tester.pumpWidget(buildControls());
      expect(find.text('...'), findsOneWidget);
    });
  });
}
