import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/teams/presentation/pages/add_player_page.dart';

void main() {
  Widget buildTestWidget({
    void Function(String name, String? phone, String? playerRole,
            String? battingStyle, String? bowlingStyle)?
        onCreatePlayer,
    void Function(String playerId)? onAddExisting,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: AddPlayerPage(
          teamId: 'team-1',
          onCreatePlayer: onCreatePlayer,
          onAddExisting: onAddExisting,
        ),
      ),
    );
  }

  group('AddPlayerPage', () {
    testWidgets('renders Add Player title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Add Player'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders two tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Search by Phone'), findsOneWidget);
      expect(find.text('Create New'), findsOneWidget);
    });

    testWidgets('Search tab shows phone input with +91 prefix',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsWidgets);
      expect(find.text('Phone Number'), findsWidgets);
    });

    testWidgets('Search tab shows Search button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Search'), findsOneWidget);
    });

    testWidgets('Create tab shows player name input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Create tab
      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Player Name *'), findsOneWidget);
    });

    testWidgets('Create tab shows role chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Batter'), findsOneWidget);
      expect(find.text('Bowler'), findsOneWidget);
      expect(find.text('All-Rounder'), findsOneWidget);
      expect(find.text('WK-Batter'), findsOneWidget);
    });

    testWidgets('Create tab shows batting style chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Right Hand'), findsOneWidget);
      expect(find.text('Left Hand'), findsOneWidget);
    });

    testWidgets('Create tab shows Add to Team button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Add to Team'),
        findsOneWidget,
      );
    });

    testWidgets('Create tab button disabled when name is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Create tab calls onCreatePlayer with form data',
        (tester) async {
      String? createdName;
      String? createdRole;

      await tester.pumpWidget(buildTestWidget(
        onCreatePlayer: (name, phone, role, batting, bowling) {
          createdName = name;
          createdRole = role;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      // Enter player name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter full name'),
        'Test Player',
      );
      await tester.pump();

      // Tap Add to Team button
      await tester.tap(find.widgetWithText(FilledButton, 'Add to Team'));
      await tester.pump();

      expect(createdName, 'Test Player');
      expect(createdRole, 'batter'); // Default role
    });
  });
}
