import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:cricscores/src/features/tournaments/presentation/pages/tournaments_list_page.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';

Tournament _makeTournament({
  String id = 'tour-1',
  String name = 'Summer League',
  TournamentFormat format = TournamentFormat.roundRobin,
  TournamentStatus status = TournamentStatus.draft,
  int oversPerMatch = 20,
  int? teamCount,
  String? startDate,
  String? endDate,
}) {
  return Tournament(
    id: id,
    name: name,
    format: format,
    oversPerMatch: oversPerMatch,
    ballTypeId: 1,
    status: status,
    pointsWin: 2,
    pointsTie: 1,
    pointsNoResult: 1,
    pointsLoss: 0,
    numGroups: 1,
    qualifyPerGroup: 2,
    hasThirdPlaceMatch: false,
    playersPerSide: 11,
    wideRuns: 1,
    noBallRuns: 1,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 1, 15),
    teamCount: teamCount,
    startDate: startDate,
    endDate: endDate,
  );
}

void main() {
  Widget buildTestWidget({TournamentListResult? initialData}) {
    return ProviderScope(
      overrides: [
        tournamentsListProvider.overrideWith(() {
          return _TestTournamentsListNotifier(initialData);
        }),
      ],
      child: const MaterialApp(
        home: TournamentsListPage(),
      ),
    );
  }

  group('TournamentsListPage', () {
    testWidgets('renders Tournaments title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData:
            const TournamentListResult(tournaments: [], total: 0, page: 1),
      ));
      await tester.pump();

      expect(find.text('Tournaments'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no tournaments', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData:
            const TournamentListResult(tournaments: [], total: 0, page: 1),
      ));
      await tester.pump();

      expect(find.text('No Tournaments'), findsOneWidget);
      expect(
        find.text('Create a tournament to organize matches between teams.'),
        findsOneWidget,
      );
      expect(find.text('Create Tournament'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows FAB', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData:
            const TournamentListResult(tournaments: [], total: 0, page: 1),
      ));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData:
            const TournamentListResult(tournaments: [], total: 0, page: 1),
      ));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows tournament cards when data exists', (tester) async {
      final tournaments = [
        _makeTournament(
          id: 'tour-1',
          name: 'Summer League',
          format: TournamentFormat.roundRobin,
          status: TournamentStatus.live,
          teamCount: 8,
          startDate: '2026-03-01',
          endDate: '2026-03-31',
        ),
        _makeTournament(
          id: 'tour-2',
          name: 'Winter Cup',
          format: TournamentFormat.knockout,
          status: TournamentStatus.draft,
          teamCount: 4,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 2, page: 1),
      ));
      await tester.pump();

      expect(find.text('Summer League'), findsOneWidget);
      expect(find.text('Winter Cup'), findsOneWidget);
    });

    testWidgets('shows status badges on cards', (tester) async {
      final tournaments = [
        _makeTournament(status: TournamentStatus.live, name: 'Live Tournament'),
        _makeTournament(
          id: 'tour-2',
          status: TournamentStatus.draft,
          name: 'Draft Tournament',
        ),
        _makeTournament(
          id: 'tour-3',
          status: TournamentStatus.registration,
          name: 'Reg Tournament',
        ),
        _makeTournament(
          id: 'tour-4',
          status: TournamentStatus.completed,
          name: 'Done Tournament',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 4, page: 1),
      ));
      await tester.pump();

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('REGISTRATION'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('shows format badge on cards', (tester) async {
      final tournaments = [
        _makeTournament(format: TournamentFormat.roundRobin),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 1, page: 1),
      ));
      await tester.pump();

      expect(find.text('ROUND ROBIN'), findsOneWidget);
    });

    testWidgets('shows overs info on cards', (tester) async {
      final tournaments = [
        _makeTournament(oversPerMatch: 20),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 1, page: 1),
      ));
      await tester.pump();

      expect(find.text('20 overs'), findsOneWidget);
    });

    testWidgets('shows team count on cards', (tester) async {
      final tournaments = [
        _makeTournament(teamCount: 8),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 1, page: 1),
      ));
      await tester.pump();

      expect(find.text('8 teams'), findsOneWidget);
    });

    testWidgets('shows date range on cards', (tester) async {
      final tournaments = [
        _makeTournament(startDate: '2026-03-01', endDate: '2026-03-31'),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData:
            TournamentListResult(tournaments: tournaments, total: 1, page: 1),
      ));
      await tester.pump();

      expect(find.text('2026-03-01 - 2026-03-31'), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsListProvider.overrideWith(() {
              return _ErrorTournamentsListNotifier();
            }),
          ],
          child: const MaterialApp(
            home: TournamentsListPage(),
          ),
        ),
      );
      // Error state has no PulsingLiveDot, so pumpAndSettle is safe here
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

class _TestTournamentsListNotifier extends TournamentsListNotifier {
  _TestTournamentsListNotifier(this._initialData);

  final TournamentListResult? _initialData;

  @override
  Future<TournamentListResult> build() async {
    if (_initialData != null) return _initialData;
    return Completer<TournamentListResult>().future;
  }
}

class _ErrorTournamentsListNotifier extends TournamentsListNotifier {
  @override
  Future<TournamentListResult> build() async {
    throw Exception('Network error');
  }
}
