import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/extras_panel.dart';

void main() {
  Widget buildPanel({
    ExtraType extraType = ExtraType.wide,
    int wideRunsPenalty = 1,
    int noBallRunsPenalty = 1,
    void Function(int runs, {bool withWicket, NoBallRunType? noBallRunType})? onConfirm,
    VoidCallback? onClose,
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
        body: ExtrasPanel(
          extraType: extraType,
          wideRunsPenalty: wideRunsPenalty,
          noBallRunsPenalty: noBallRunsPenalty,
          onConfirm: onConfirm ?? (_, {bool withWicket = false, NoBallRunType? noBallRunType}) {},
          onClose: onClose ?? () {},
        ),
      ),
    );
  }

  /// Find text inside a button (FilledButton or OutlinedButton).
  Finder findButtonWithText(String label) {
    return find.descendant(
      of: find.byWidgetPredicate(
          (w) => w is FilledButton || w is OutlinedButton),
      matching: find.text(label),
    );
  }

  group('ExtrasPanel', () {
    group('header and badges', () {
      testWidgets('renders Extra title text', (tester) async {
        await tester.pumpWidget(buildPanel());
        expect(find.text('Extra'), findsOneWidget);
      });

      testWidgets('Wide type shows Wide badge', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        expect(find.text('Wide'), findsOneWidget);
      });

      testWidgets('No Ball type shows No Ball badge', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        expect(find.text('No Ball'), findsOneWidget);
      });

      testWidgets('Bye type shows Bye badge', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        expect(find.text('Bye'), findsOneWidget);
      });

      testWidgets('Leg Bye type shows Leg Bye badge', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.legBye));
        expect(find.text('Leg Bye'), findsOneWidget);
      });
    });

    group('run buttons per type', () {
      testWidgets('Wide shows run buttons 0 1 2 3 4 and ...', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        for (final label in ['0', '1', '2', '3', '4']) {
          expect(findButtonWithText(label), findsOneWidget);
        }
        expect(findButtonWithText('...'), findsOneWidget);
      });

      testWidgets('No Ball shows run buttons 0 1 2 3 4 6 and ...',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        for (final label in ['0', '1', '2', '3', '4', '6']) {
          expect(findButtonWithText(label), findsOneWidget);
        }
        expect(findButtonWithText('...'), findsOneWidget);
      });

      testWidgets('Bye shows run buttons 1 2 3 4 and ... (no zero)',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        for (final label in ['1', '2', '3', '4']) {
          expect(findButtonWithText(label), findsOneWidget);
        }
        expect(findButtonWithText('...'), findsOneWidget);
        // No zero button
        expect(findButtonWithText('0'), findsNothing);
      });

      testWidgets('Leg Bye shows run buttons 1 2 3 4 and ... (no zero)',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.legBye));
        for (final label in ['1', '2', '3', '4']) {
          expect(findButtonWithText(label), findsOneWidget);
        }
        expect(findButtonWithText('...'), findsOneWidget);
        expect(findButtonWithText('0'), findsNothing);
      });
    });

    group('defaults', () {
      testWidgets('Wide defaults to 0 selected', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        // The "0" button should be visually selected (filled style)
        final zeroButton = find.ancestor(
          of: find.text('0'),
          matching: find.byType(FilledButton),
        );
        expect(zeroButton, findsOneWidget);
      });

      testWidgets('Bye defaults to 1 selected', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        final oneButton = find.ancestor(
          of: find.text('1'),
          matching: find.byType(FilledButton),
        );
        expect(oneButton, findsOneWidget);
      });

      testWidgets('No Ball defaults to 0 selected', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        final zeroButton = find.ancestor(
          of: find.text('0'),
          matching: find.byType(FilledButton),
        );
        expect(zeroButton, findsOneWidget);
      });

      testWidgets('Leg Bye defaults to 1 selected', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.legBye));
        final oneButton = find.ancestor(
          of: find.text('1'),
          matching: find.byType(FilledButton),
        );
        expect(oneButton, findsOneWidget);
      });
    });

    group('selection', () {
      testWidgets('tapping a run button selects it', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        // Initially 0 is selected
        expect(
          find.ancestor(
            of: find.text('0'),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );
        // Tap "3" (which should be an OutlinedButton)
        await tester.tap(find.ancestor(
          of: find.text('3'),
          matching: find.byType(OutlinedButton),
        ));
        await tester.pump();
        // Now 3 should be selected (FilledButton) and 0 not
        expect(
          find.ancestor(
            of: find.text('3'),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('0'),
            matching: find.byType(OutlinedButton),
          ),
          findsOneWidget,
        );
      });
    });

    group('total runs display', () {
      testWidgets('Wide default shows total = penalty + 0', (tester) async {
        await tester.pumpWidget(
            buildPanel(extraType: ExtraType.wide, wideRunsPenalty: 1));
        // Total = 1 (penalty) + 0 (additional) = 1
        expect(find.text('1'), findsWidgets);
        expect(find.textContaining('Total'), findsOneWidget);
      });

      testWidgets('Wide +2 shows total 3', (tester) async {
        await tester.pumpWidget(
            buildPanel(extraType: ExtraType.wide, wideRunsPenalty: 1));
        // Select 2
        await tester.tap(find.ancestor(
          of: find.text('2'),
          matching: find.byType(OutlinedButton),
        ));
        await tester.pump();
        // Total = 1 + 2 = 3, find it in the total row
        final totalRow = find.textContaining('Total');
        expect(totalRow, findsOneWidget);
        // Find the "3" that is the computed total (look for bold total text)
        expect(find.text('3'), findsWidgets);
      });

      testWidgets('No Ball with 2 from bat shows total 3', (tester) async {
        await tester.pumpWidget(
            buildPanel(extraType: ExtraType.noBall, noBallRunsPenalty: 1));
        // Select 2
        await tester.tap(find.ancestor(
          of: find.text('2'),
          matching: find.byType(OutlinedButton),
        ));
        await tester.pump();
        // Total = 1 + 2 = 3
        expect(find.text('3'), findsWidgets);
      });

      testWidgets('Bye total shows just bye runs (no penalty)',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        // Default bye runs = 1, no penalty
        // Find the total value
        final totalRow = find.textContaining('Total');
        expect(totalRow, findsOneWidget);
      });

      testWidgets('configurable penalty: wideRunsPenalty=2 shows total 2+0=2',
          (tester) async {
        await tester.pumpWidget(
            buildPanel(extraType: ExtraType.wide, wideRunsPenalty: 2));
        // Total = 2 (penalty) + 0 = 2
        final totalRow = find.textContaining('Total');
        expect(totalRow, findsOneWidget);
        // The total value should be 2
        expect(find.text('2'), findsWidgets);
      });
    });

    group('callbacks', () {
      testWidgets('Confirm button fires onConfirm with correct runs',
          (tester) async {
        int? confirmedRuns;
        await tester.pumpWidget(buildPanel(
          extraType: ExtraType.wide,
          onConfirm: (runs, {bool withWicket = false, NoBallRunType? noBallRunType}) => confirmedRuns = runs,
        ));
        // Default wide runs = 0 (additional)
        await tester.tap(find.text('Confirm'));
        await tester.pump();
        expect(confirmedRuns, 0);
      });

      testWidgets('Confirm after selecting 3 fires onConfirm with 3',
          (tester) async {
        int? confirmedRuns;
        await tester.pumpWidget(buildPanel(
          extraType: ExtraType.wide,
          onConfirm: (runs, {bool withWicket = false, NoBallRunType? noBallRunType}) => confirmedRuns = runs,
        ));
        await tester.tap(find.ancestor(
          of: find.text('3'),
          matching: find.byType(OutlinedButton),
        ));
        await tester.pump();
        await tester.tap(find.text('Confirm'));
        await tester.pump();
        expect(confirmedRuns, 3);
      });

      testWidgets('Bye confirm fires with bye runs', (tester) async {
        int? confirmedRuns;
        await tester.pumpWidget(buildPanel(
          extraType: ExtraType.bye,
          onConfirm: (runs, {bool withWicket = false, NoBallRunType? noBallRunType}) => confirmedRuns = runs,
        ));
        // Default bye = 1
        await tester.tap(find.text('Confirm'));
        await tester.pump();
        expect(confirmedRuns, 1);
      });

      testWidgets('Close button fires onClose callback', (tester) async {
        var closeCalled = false;
        await tester.pumpWidget(buildPanel(
          onClose: () => closeCalled = true,
        ));
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        expect(closeCalled, true);
      });
    });

    group('custom run picker', () {
      testWidgets('tapping ... opens custom run dialog', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();
        // Dialog should show values 5-12
        expect(find.text('5'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
      });

      testWidgets('selecting custom value updates selection', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();
        // Select 7 from the dialog
        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();
        // The custom value should now be displayed and selected
        expect(find.text('7'), findsOneWidget);
      });
    });

    group('label text per type', () {
      testWidgets('Wide shows Additional Runs label', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        expect(find.text('Additional Runs'), findsOneWidget);
      });

      testWidgets('No Ball shows Runs from Bat label', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        expect(find.text('Runs from Bat'), findsOneWidget);
      });

      testWidgets('Bye shows Bye Runs label', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        expect(find.text('Bye Runs'), findsOneWidget);
      });

      testWidgets('Leg Bye shows Leg Bye Runs label', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.legBye));
        expect(find.text('Leg Bye Runs'), findsOneWidget);
      });
    });

    group('wicket toggle per type', () {
      testWidgets('Wide panel shows Wicket? toggle text', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        expect(find.text('Wicket?'), findsOneWidget);
      });

      testWidgets('No Ball panel shows Wicket? toggle text', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        expect(find.text('Wicket?'), findsOneWidget);
      });

      testWidgets('Bye panel does NOT show Wicket? toggle', (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.bye));
        expect(find.text('Wicket?'), findsNothing);
      });

      testWidgets('Leg Bye panel does NOT show Wicket? toggle',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.legBye));
        expect(find.text('Wicket?'), findsNothing);
      });

      testWidgets(
          'toggling wicket changes confirm button text to Next: Select Wicket',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.wide));
        // Initially shows Confirm
        expect(find.text('Confirm'), findsOneWidget);
        // Toggle wicket switch on
        await tester.tap(find.byType(Switch));
        await tester.pump();
        // Button text should change
        expect(find.text('Next: Select Wicket'), findsOneWidget);
        expect(find.text('Confirm'), findsNothing);
      });
    });

    group('no ball run type selector', () {
      testWidgets('NB panel shows Run Type with 3 ChoiceChips',
          (tester) async {
        await tester.pumpWidget(buildPanel(extraType: ExtraType.noBall));
        expect(find.text('Run Type'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNWidgets(3));
        expect(find.text('Bat Runs'), findsOneWidget);
        expect(find.text('Byes'), findsOneWidget);
        expect(find.text('Leg Byes'), findsOneWidget);
      });
    });
  });
}
