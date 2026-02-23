import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/fixture.dart';
import 'package:cricscores/src/features/tournaments/presentation/pages/knockout_bracket_page.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';

void main() {
  Widget buildTestWidget({List<Fixture>? fixtures}) {
    return ProviderScope(
      overrides: [
        tournamentFixturesProvider('tour-1').overrideWith(
          (ref) async => fixtures ?? [],
        ),
      ],
      child: const MaterialApp(
        home: KnockoutBracketPage(tournamentId: 'tour-1'),
      ),
    );
  }

  group('KnockoutBracketPage', () {
    testWidgets('renders Bracket title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bracket'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentFixturesProvider('tour-1').overrideWith(
              (ref) => Completer<List<Fixture>>().future,
            ),
          ],
          child: const MaterialApp(
            home: KnockoutBracketPage(tournamentId: 'tour-1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no knockout fixtures', (tester) async {
      // Only group fixtures — no knockout
      final fixtures = [
        const Fixture(
          id: 'fix-1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.group,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(fixtures: fixtures));
      await tester.pumpAndSettle();

      expect(find.text('Bracket Not Ready'), findsOneWidget);
    });

    testWidgets('shows bracket with knockout fixtures', (tester) async {
      final fixtures = [
        const Fixture(
          id: 'fix-1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.semiFinal,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeTeamName: 'Mumbai Warriors',
          awayTeamName: 'Chennai Kings',
        ),
        const Fixture(
          id: 'fix-2',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.final_,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-3',
          homeTeamName: 'Mumbai Warriors',
          awayTeamName: 'Delhi Strikers',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(fixtures: fixtures));
      await tester.pumpAndSettle();

      expect(find.text('Semi Final'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('Mumbai Warriors'), findsAtLeastNWidgets(1));
      expect(find.text('Chennai Kings'), findsOneWidget);
    });

    testWidgets('shows TBD for teams without names', (tester) async {
      final fixtures = [
        const Fixture(
          id: 'fix-1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.final_,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(fixtures: fixtures));
      await tester.pumpAndSettle();

      expect(find.text('TBD'), findsAtLeastNWidgets(2));
    });

    testWidgets('shows result summary for completed fixtures', (tester) async {
      final fixtures = [
        const Fixture(
          id: 'fix-1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.final_,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeTeamName: 'Mumbai Warriors',
          awayTeamName: 'Chennai Kings',
          result: FixtureResult(
            winner: 'team-1',
            summary: 'Mumbai Warriors won by 20 runs',
          ),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(fixtures: fixtures));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors won by 20 runs'), findsOneWidget);
    });
  });
}
