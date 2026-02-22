import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/more/presentation/pages/more_page.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: MorePage(),
    );
  }

  group('MorePage', () {
    testWidgets('renders 4 list tiles', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('renders Tournaments item', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('renders Settings item', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('renders About item', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('About'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders Help item', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Help'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('More'), findsOneWidget);
    });
  });
}
