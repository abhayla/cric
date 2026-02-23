import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/standing.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:cricscores/src/features/tournaments/presentation/pages/standings_page.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';

void main() {
  Widget buildTestWidget({StandingsResult? result}) {
    return ProviderScope(
      overrides: [
        tournamentStandingsProvider('tour-1').overrideWith(
          (ref) async =>
              result ?? const StandingsResult(standings: [], groups: []),
        ),
      ],
      child: const MaterialApp(
        home: StandingsPage(tournamentId: 'tour-1'),
      ),
    );
  }

  group('StandingsPage', () {
    testWidgets('renders Standings title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Standings'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentStandingsProvider('tour-1').overrideWith(
              (ref) => Completer<StandingsResult>().future,
            ),
          ],
          child: const MaterialApp(
            home: StandingsPage(tournamentId: 'tour-1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no standings', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Standings Yet'), findsOneWidget);
    });

    testWidgets('shows standings table with data', (tester) async {
      const result = StandingsResult(
        standings: [
          Standing(
            tournamentId: 'tour-1',
            teamId: 'team-1',
            played: 3,
            won: 2,
            lost: 1,
            tied: 0,
            noResult: 0,
            points: 4,
            nrr: 1.25,
            totalRunsScored: 450,
            totalOversFaced: 60.0,
            totalRunsConceded: 380,
            totalOversBowled: 60.0,
            teamName: 'Mumbai Warriors',
            position: 1,
          ),
        ],
        groups: [],
      );

      await tester.pumpWidget(buildTestWidget(result: result));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // points
      expect(find.text('+1.250'), findsOneWidget); // NRR
    });

    testWidgets('shows table headers', (tester) async {
      const result = StandingsResult(
        standings: [
          Standing(
            tournamentId: 'tour-1',
            teamId: 'team-1',
            played: 0,
            won: 0,
            lost: 0,
            tied: 0,
            noResult: 0,
            points: 0,
            nrr: 0.0,
            totalRunsScored: 0,
            totalOversFaced: 0,
            totalRunsConceded: 0,
            totalOversBowled: 0,
            teamName: 'Test Team',
          ),
        ],
        groups: [],
      );

      await tester.pumpWidget(buildTestWidget(result: result));
      await tester.pumpAndSettle();

      expect(find.text('#'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Pts'), findsOneWidget);
      expect(find.text('NRR'), findsOneWidget);
    });

    testWidgets('shows group tabs when multiple groups', (tester) async {
      const result = StandingsResult(
        standings: [
          Standing(
            tournamentId: 'tour-1',
            teamId: 'team-1',
            played: 3,
            won: 2,
            lost: 1,
            tied: 0,
            noResult: 0,
            points: 4,
            nrr: 1.25,
            totalRunsScored: 450,
            totalOversFaced: 60.0,
            totalRunsConceded: 380,
            totalOversBowled: 60.0,
            groupName: 'A',
            teamName: 'Mumbai Warriors',
          ),
          Standing(
            tournamentId: 'tour-1',
            teamId: 'team-2',
            played: 3,
            won: 1,
            lost: 2,
            tied: 0,
            noResult: 0,
            points: 2,
            nrr: -0.5,
            totalRunsScored: 350,
            totalOversFaced: 60.0,
            totalRunsConceded: 400,
            totalOversBowled: 60.0,
            groupName: 'B',
            teamName: 'Delhi Strikers',
          ),
        ],
        groups: ['A', 'B'],
      );

      await tester.pumpWidget(buildTestWidget(result: result));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'A'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'B'), findsOneWidget);
    });
  });
}
