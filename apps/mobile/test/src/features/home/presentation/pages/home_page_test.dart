import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/home/presentation/pages/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders CricApp title in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );

      expect(find.textContaining('CricApp'), findsOneWidget);
    });

    testWidgets('renders quick action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );

      expect(find.text('Start Match'), findsOneWidget);
      expect(find.text('Create Team'), findsOneWidget);
      expect(find.text('Tournament'), findsOneWidget);
    });

    testWidgets('renders Recent Matches section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );

      expect(find.text('Recent Matches'), findsOneWidget);
    });

    testWidgets('shows empty state for recent matches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );

      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
