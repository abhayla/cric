import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_bowler_sheet.dart';

void main() {
  Widget buildSheet({
    required List<BowlerOption> options,
    int overNumber = 2,
    ValueChanged<String>? onSelect,
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
        body: SelectBowlerSheet(
          bowlerOptions: options,
          overNumber: overNumber,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    );
  }

  group('SelectBowlerSheet', () {
    testWidgets('renders title with over number', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Bowler One',
            isEligible: true,
          ),
        ],
        overNumber: 3,
      ));
      expect(find.text('Over 3'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Bowler One',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Bowler Two',
            isEligible: true,
          ),
        ],
      ));
      expect(
        find.text('Over completed. Select the next bowler.'),
        findsOneWidget,
      );
    });

    testWidgets('renders eligible bowler names', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Jasprit Bumrah',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Mohammed Siraj',
            isEligible: true,
          ),
        ],
      ));
      expect(find.text('Jasprit Bumrah'), findsOneWidget);
      expect(find.text('Mohammed Siraj'), findsOneWidget);
    });

    testWidgets('eligible bowler shows O-M-R-W stats when spell exists',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Bumrah',
            isEligible: true,
            spell: BowlerSpell(
              playerId: 'b-1',
              displayName: 'Bumrah',
              ballsBowled: 24,
              maidens: 2,
              runsConceded: 30,
              wicketsTaken: 3,
            ),
          ),
        ],
      ));
      // O-M-R-W format
      expect(find.text('4.0-2-30-3'), findsOneWidget);
    });

    testWidgets('eligible bowler shows "--" when no spell', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'New Bowler',
            isEligible: true,
          ),
        ],
      ));
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('eligible bowler shows economy rate', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Bumrah',
            isEligible: true,
            spell: BowlerSpell(
              playerId: 'b-1',
              displayName: 'Bumrah',
              ballsBowled: 12,
              runsConceded: 20,
            ),
          ),
        ],
      ));
      // Economy: (20/12)*6 = 10.0
      expect(find.text('Ec: 10.0'), findsOneWidget);
    });

    testWidgets('tap on eligible bowler calls onSelect', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-99',
            displayName: 'Selected Bowler',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-100',
            displayName: 'Other Bowler',
            isEligible: true,
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.tap(find.text('Selected Bowler'));
      await tester.pumpAndSettle();
      expect(selectedId, 'b-99');
    });

    testWidgets('renders ineligible bowler with reason', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Eligible Bowler',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Last Over Bowler',
            isEligible: false,
            ineligibleReason: 'Bowled last over',
          ),
        ],
      ));
      expect(find.text('Last Over Bowler'), findsOneWidget);
      expect(find.text('Bowled last over'), findsOneWidget);
    });

    testWidgets('ineligible bowler shows max overs reason', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Eligible Bowler',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Maxed Bowler',
            isEligible: false,
            ineligibleReason: 'Max overs reached',
          ),
        ],
      ));
      expect(find.text('Max overs reached'), findsOneWidget);
    });

    testWidgets('tap on ineligible bowler does not call onSelect',
        (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Eligible One',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Eligible Two',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-3',
            displayName: 'Cannot Bowl',
            isEligible: false,
            ineligibleReason: 'Bowled last over',
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.tap(find.text('Cannot Bowl'));
      await tester.pumpAndSettle();
      expect(selectedId, isNull);
    });

    testWidgets('auto-selects when only 1 eligible bowler', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-solo',
            displayName: 'Solo Bowler',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Ineligible',
            isEligible: false,
            ineligibleReason: 'Bowled last over',
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.pumpAndSettle();
      expect(selectedId, 'b-solo');
    });

    testWidgets('shows snackbar on auto-select', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-solo',
            displayName: 'Solo Bowler',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Ineligible',
            isEligible: false,
            ineligibleReason: 'Max overs reached',
          ),
        ],
      ));

      await tester.pumpAndSettle();
      expect(
        find.textContaining('Only 1 eligible bowler'),
        findsOneWidget,
      );
    });

    testWidgets('renders bowler initials', (tester) async {
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Jasprit Bumrah',
            isEligible: true,
          ),
        ],
      ));
      expect(find.text('JB'), findsOneWidget);
    });

    testWidgets('does not auto-select with multiple eligible bowlers',
        (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        options: const [
          BowlerOption(
            playerId: 'b-1',
            displayName: 'Bowler One',
            isEligible: true,
          ),
          BowlerOption(
            playerId: 'b-2',
            displayName: 'Bowler Two',
            isEligible: true,
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.pumpAndSettle();
      expect(selectedId, isNull);
    });
  });
}
