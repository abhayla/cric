import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/domain/entities/fixture.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/standing.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricapp/src/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:cricapp/src/features/tournaments/presentation/pages/tournament_detail_page.dart';
import 'package:cricapp/src/features/tournaments/providers.dart';

Tournament _makeTournament({
  TournamentStatus status = TournamentStatus.live,
  TournamentFormat format = TournamentFormat.groupKnockout,
  int teamCount = 8,
  List<TournamentTeam>? teams,
}) {
  return Tournament(
    id: 'tour-1',
    name: 'Weekend Warriors Cup',
    format: format,
    oversPerMatch: 20,
    ballTypeId: 1,
    status: status,
    pointsWin: 2,
    pointsTie: 1,
    pointsNoResult: 1,
    pointsLoss: 0,
    numGroups: 2,
    qualifyPerGroup: 2,
    hasThirdPlaceMatch: false,
    playersPerSide: 11,
    wideRuns: 1,
    noBallRuns: 1,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
    startDate: '2026-03-01',
    endDate: '2026-03-15',
    teamCount: teamCount,
    teams: teams,
  );
}

void main() {
  Widget buildTestWidget({
    Tournament? tournament,
    List<Fixture>? fixtures,
    StandingsResult? standings,
  }) {
    return ProviderScope(
      overrides: [
        tournamentDetailProvider('tour-1').overrideWith(
          (ref) async => tournament ?? _makeTournament(),
        ),
        tournamentFixturesProvider('tour-1').overrideWith(
          (ref) async => fixtures ?? [],
        ),
        tournamentStandingsProvider('tour-1').overrideWith(
          (ref) async =>
              standings ??
              const StandingsResult(standings: [], groups: []),
        ),
      ],
      child: const MaterialApp(
        home: TournamentDetailPage(tournamentId: 'tour-1'),
      ),
    );
  }

  group('TournamentDetailPage', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tour-1').overrideWith(
              (ref) => Completer<Tournament>().future,
            ),
            tournamentFixturesProvider('tour-1').overrideWith(
              (ref) async => <Fixture>[],
            ),
            tournamentStandingsProvider('tour-1').overrideWith(
              (ref) async =>
                  const StandingsResult(standings: [], groups: []),
            ),
          ],
          child: const MaterialApp(
            home: TournamentDetailPage(tournamentId: 'tour-1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows tournament name in hero section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Weekend Warriors Cup'), findsOneWidget);
    });

    testWidgets('shows format and overs badges', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Group + KO'), findsOneWidget);
      expect(find.text('20 Overs'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('shows date range', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('2026-03-01 - 2026-03-15'), findsOneWidget);
    });

    testWidgets('shows stat grid with team count', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // "Teams" appears in both stat grid and tab — check at least 1
      expect(find.text('Teams'), findsAtLeastNWidgets(1));
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('has 3 tabs: Overview, Fixtures, Teams', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Overview'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Fixtures'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Teams'), findsOneWidget);
    });

    testWidgets('shows standings section on Overview tab', (tester) async {
      final standings = StandingsResult(
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
          ),
        ],
        groups: ['A'],
      );

      await tester.pumpWidget(buildTestWidget(standings: standings));
      await tester.pumpAndSettle();

      expect(find.text('Standings'), findsOneWidget);
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('shows empty state on Fixtures tab when no fixtures',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Fixtures tab
      await tester.tap(find.widgetWithText(Tab, 'Fixtures'));
      await tester.pumpAndSettle();

      expect(find.text('No Fixtures Yet'), findsOneWidget);
    });

    testWidgets('shows fixtures on Fixtures tab', (tester) async {
      final fixtures = [
        Fixture(
          id: 'fix-1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundType: RoundType.group,
          fixtureOrder: 1,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeTeamName: 'Mumbai Warriors',
          awayTeamName: 'Chennai Kings',
          groupName: 'A',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(fixtures: fixtures));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Fixtures'));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Chennai Kings'), findsOneWidget);
    });

    testWidgets('shows empty state on Teams tab when no teams',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: _makeTournament(teams: []),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Teams'));
      await tester.pumpAndSettle();

      expect(find.text('No Teams Registered'), findsOneWidget);
    });

    testWidgets('shows teams on Teams tab', (tester) async {
      final teams = [
        TournamentTeam(
          id: 'tt-1',
          tournamentId: 'tour-1',
          teamId: 'team-1',
          joinedAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 15),
          groupName: 'A',
          seedNumber: 1,
          teamName: 'Mumbai Warriors',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        tournament: _makeTournament(teams: teams),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Teams'));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors'), findsWidgets);
    });
  });
}
