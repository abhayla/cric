import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/presentation/pages/create_tournament_page.dart';

void main() {
  Widget buildTestWidget({
    void Function(String tournamentId)? onCreated,
  }) {
    return MaterialApp(
      home: CreateTournamentPage(
        onCreated: onCreated ?? (_) {},
      ),
    );
  }

  group('CreateTournamentPage', () {
    testWidgets('renders Create Tournament title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Create Tournament'), findsOneWidget);
    });

    testWidgets('has tournament name input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Tournament Name'), findsOneWidget);
    });

    testWidgets('has format chip group with 3 options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Round Robin'), findsOneWidget);
      expect(find.text('Knockout'), findsOneWidget);
      expect(find.text('Group + KO'), findsOneWidget);
    });

    testWidgets('has overs input with preset chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Overs per Side'), findsOneWidget);
      // Preset chips — "20" appears in both input and chip, so check at least one
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('20'), findsAtLeastNWidgets(1));
      expect(find.text('25'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('has ball type chip group', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Leather'), findsOneWidget);
      expect(find.text('Tennis'), findsOneWidget);
      expect(find.text('Tape'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('has match rules section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MATCH RULES'), findsOneWidget);
      expect(find.text('Players Per Side'), findsOneWidget);
      expect(find.text('Max Overs/Bowler'), findsOneWidget);
      expect(find.text('Wide Runs'), findsOneWidget);
      expect(find.text('No-Ball Runs'), findsOneWidget);
      expect(find.text('Powerplay Overs'), findsOneWidget);
    });

    testWidgets('shows points system section by default', (tester) async {
      // Default format is Group+KO which shows points
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('POINTS SYSTEM'), findsOneWidget);
    });

    testWidgets('shows group settings for Group + KO format', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GROUP STAGE SETTINGS'), findsOneWidget);
      expect(find.text('Number of Groups'), findsOneWidget);
      expect(find.text('Top N Qualify'), findsOneWidget);
    });

    testWidgets('hides points and groups when Knockout selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Knockout chip
      await tester.tap(find.text('Knockout'));
      await tester.pumpAndSettle();

      expect(find.text('POINTS SYSTEM'), findsNothing);
      expect(find.text('GROUP STAGE SETTINGS'), findsNothing);
    });

    testWidgets('shows points but hides groups for Round Robin',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Round Robin chip
      await tester.tap(find.text('Round Robin'));
      await tester.pumpAndSettle();

      expect(find.text('POINTS SYSTEM'), findsOneWidget);
      expect(find.text('GROUP STAGE SETTINGS'), findsNothing);
    });

    testWidgets('has dates section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dates (optional)'), findsOneWidget);
    });

    testWidgets('has create tournament button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the submit button (may need to scroll)
      final createButton = find.widgetWithText(FilledButton, 'Create Tournament');
      expect(createButton, findsOneWidget);
    });

    testWidgets('overs preset chip updates value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap '10' chip
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      // The overs input should show 10
      final input = tester.widget<TextFormField>(
        find.byKey(const Key('oversInput')),
      );
      expect(input.controller?.text, '10');
    });

    testWidgets('players per side stepper works', (tester) async {
      // Use a larger surface to avoid offscreen issues
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Default is 11, verify
      expect(find.text('11'), findsWidgets);

      // Find the minus button for Players Per Side row
      final minusButtons = find.byIcon(Icons.remove);
      expect(minusButtons, findsWidgets);

      // Tap first minus button (players per side)
      await tester.tap(minusButtons.first);
      await tester.pumpAndSettle();

      // Should now show 10
      expect(find.text('10'), findsWidgets);
    });
  });
}
