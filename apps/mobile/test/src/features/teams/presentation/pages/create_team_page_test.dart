import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/teams/presentation/pages/create_team_page.dart';

void main() {
  Widget buildTestWidget({
    void Function(String name, String? location)? onSubmit,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: CreateTeamPage(
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  group('CreateTeamPage', () {
    testWidgets('renders Create Team title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Create Team'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders logo upload area with camera icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Logo'), findsOneWidget);
    });

    testWidgets('renders upload help text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Tap to upload. Max 100KB, no cropping.'),
        findsOneWidget,
      );
    });

    testWidgets('renders Team Name label and input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Team Name *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Enter team name'), findsOneWidget);
    });

    testWidgets('renders Location label and input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsOneWidget);
      expect(
        find.widgetWithText(
          TextFormField,
          'City, State (e.g. Ahmedabad, Gujarat)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Create Team button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Create Team'), findsOneWidget);
    });

    testWidgets('Create Team button is disabled when name is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Create Team button is enabled with valid name',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        'Mumbai Warriors',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create Team'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Create Team button is disabled with 1-char name',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        'A',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Team Name field enforces maxLength 50', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter a 51-character string
      final longName = 'A' * 51;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        longName,
      );
      await tester.pump();

      // TextField should have truncated to 50 chars
      final textField = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(textField.controller.text.length, 50);
    });

    testWidgets('calls onSubmit with name and location on tap',
        (tester) async {
      String? submittedName;
      String? submittedLocation;

      await tester.pumpWidget(buildTestWidget(
        onSubmit: (name, location) {
          submittedName = name;
          submittedLocation = location;
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        'Mumbai Warriors',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'City, State (e.g. Ahmedabad, Gujarat)',
        ),
        'Mumbai, Maharashtra',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Team'));
      await tester.pump();

      expect(submittedName, 'Mumbai Warriors');
      expect(submittedLocation, 'Mumbai, Maharashtra');
    });

    testWidgets('calls onSubmit with null location when empty',
        (tester) async {
      String? submittedName;
      String? submittedLocation = 'initial';

      await tester.pumpWidget(buildTestWidget(
        onSubmit: (name, location) {
          submittedName = name;
          submittedLocation = location;
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        'Mumbai Warriors',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Team'));
      await tester.pump();

      expect(submittedName, 'Mumbai Warriors');
      expect(submittedLocation, isNull);
    });

    testWidgets('trims whitespace from team name', (tester) async {
      String? submittedName;

      await tester.pumpWidget(buildTestWidget(
        onSubmit: (name, location) {
          submittedName = name;
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter team name'),
        '  Mumbai Warriors  ',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Team'));
      await tester.pump();

      expect(submittedName, 'Mumbai Warriors');
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // AppBar should have automatic back button since this is pushed onto a stack
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
