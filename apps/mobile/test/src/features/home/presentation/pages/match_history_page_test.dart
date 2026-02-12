import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/home/presentation/pages/match_history_page.dart';

void main() {
  group('MatchHistoryPage', () {
    testWidgets('renders Matches title in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MatchHistoryPage()),
      );

      expect(find.text('Matches'), findsOneWidget);
    });

    testWidgets('renders empty state icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MatchHistoryPage()),
      );

      expect(find.byIcon(Icons.sports_cricket_outlined), findsOneWidget);
    });

    testWidgets('renders empty state message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MatchHistoryPage()),
      );

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.textContaining('Start a match'), findsOneWidget);
    });

    testWidgets('renders Start a Match CTA button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MatchHistoryPage()),
      );

      expect(find.text('Start a Match'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MatchHistoryPage()),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
