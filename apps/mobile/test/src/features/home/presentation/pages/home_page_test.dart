import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/app/providers.dart';
import 'package:cricscores/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricscores/src/features/home/presentation/pages/home_page.dart';
import 'package:cricscores/src/features/home/presentation/widgets/expandable_fab.dart';
import 'package:cricscores/src/features/home/providers.dart';
import 'package:cricscores/src/features/teams/providers.dart';
import 'package:cricscores/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';

void main() {
  Widget buildTestWidget({
    AsyncValue<MatchListResult>? allMatches,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        teamsListProvider.overrideWith(() => _FakeTeamsNotifier()),
        tournamentsListProvider.overrideWith(() => _FakeTournamentsNotifier()),
        allMatchesProvider.overrideWith(
          (ref, page) async =>
              (allMatches ?? const AsyncValue.data(MatchListResult(
                matches: [],
                total: 0,
                page: 1,
              )))
                  .when(
            data: (d) => d,
            loading: () => throw StateError('loading'),
            error: (e, s) => throw e,
          ),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  group('HomePage', () {
    testWidgets('renders My Cricket title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('My'), findsWidgets);
      expect(find.textContaining('Cricket'), findsWidgets);
    });

    testWidgets('renders three sub-tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Tournaments'), findsOneWidget);
    });

    testWidgets('renders expandable FAB', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ExpandableFab), findsOneWidget);
    });

    testWidgets('renders profile avatar in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows teams empty state when no teams', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Teams tab is the default tab
      expect(find.text('No Teams Yet'), findsOneWidget);
    });

    testWidgets('shows matches empty state on Matches tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(find.text('No Matches Found'), findsOneWidget);
    });

    testWidgets('shows tournaments empty state on Tournaments tab',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the Tournaments tab
      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      expect(find.text('No Tournaments Found'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh on Teams tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows filter chips on Matches tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsAtLeast(1));
    });

    testWidgets('has TabBar with correct tab count', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });
  });
}

class _FakeTeamsNotifier extends TeamsListNotifier {
  @override
  Future<TeamListResult> build() async {
    return const TeamListResult(teams: [], total: 0, page: 1);
  }
}

class _FakeTournamentsNotifier extends TournamentsListNotifier {
  @override
  Future<TournamentListResult> build() async {
    return const TournamentListResult(tournaments: [], total: 0, page: 1);
  }
}
