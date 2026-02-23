import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/auth/presentation/pages/profile_setup_page.dart';

void main() {
  group('ProfileSetupPage', () {
    testWidgets('renders Set Up Profile app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Set Up Profile'), findsOneWidget);
    });

    testWidgets('renders initials avatar placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      // Should show a circle avatar area
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders Display Name input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Display Name *'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Playing Role dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Playing Role *'), findsOneWidget);
    });

    testWidgets('renders Batting Style toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Batting Style *'), findsOneWidget);
      expect(find.text('Right Hand'), findsOneWidget);
      expect(find.text('Left Hand'), findsOneWidget);
    });

    testWidgets('renders Bowling Style dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Bowling Style'), findsOneWidget);
    });

    testWidgets('renders Location input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('renders Save & Continue button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      expect(find.text('Save & Continue'), findsOneWidget);
    });

    testWidgets('Save button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Right Hand is selected by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileSetupPage()),
      );

      // Right Hand should be the selected/filled chip
      final rightHandFinder = find.ancestor(
        of: find.text('Right Hand'),
        matching: find.byType(ChoiceChip),
      );
      final chip = tester.widget<ChoiceChip>(rightHandFinder);
      expect(chip.selected, isTrue);
    });
  });
}
