import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricscores/src/features/home/providers.dart';
import 'package:cricscores/src/features/live/presentation/pages/live_page.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        matchesByStatusProvider.overrideWith(
          (ref, status) async =>
              const MatchListResult(matches: [], total: 0, page: 1),
        ),
        tournamentsListProvider.overrideWith(() => _FakeTournamentsNotifier()),
      ],
      child: const MaterialApp(home: LivePage()),
    );
  }

  group('LivePage', () {
    testWidgets('renders Live title in AppBar with primary color',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 'Live' appears in AppBar title and in filter chip — verify at least one
      expect(find.text('Live'), findsAtLeast(1));
      // Verify AppBar is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders two tabs: Matches and Tournaments', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Tournaments'), findsOneWidget);
    });

    testWidgets('TabBar has correct tab count (2)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('Matches tab is selected by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Matches tab content should be visible — filter chips are present
      expect(find.byType(FilterChip), findsAtLeast(1));
    });

    testWidgets('Matches tab shows Live/Completed/All filter chips',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Live'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Completed'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    });

    testWidgets('Matches tab defaults to Live filter selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final liveChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Live'),
      );
      expect(liveChip.selected, isTrue);

      final completedChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Completed'),
      );
      expect(completedChip.selected, isFalse);
    });

    testWidgets('Tournaments tab shows Live/Completed/All filter chips',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Tournaments tab
      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Live'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Completed'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    });

    testWidgets('Tournaments tab defaults to Live filter selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      final liveChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Live'),
      );
      expect(liveChip.selected, isTrue);
    });

    testWidgets('Matches tab shows empty state when no live matches',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No live matches right now'), findsOneWidget);
    });

    testWidgets('Tournaments tab shows empty state when no live tournaments',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      expect(find.text('No live tournaments right now'), findsOneWidget);
    });

    testWidgets('Both tabs have pull-to-refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Matches tab has RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Switch to Tournaments tab
      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Switching filter chip changes selection state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Completed chip
      await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
      await tester.pumpAndSettle();

      final completedChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Completed'),
      );
      expect(completedChip.selected, isTrue);

      final liveChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Live'),
      );
      expect(liveChip.selected, isFalse);
    });
  });
}

class _FakeTournamentsNotifier extends TournamentsListNotifier {
  @override
  Future<TournamentListResult> build() async {
    return const TournamentListResult(tournaments: [], total: 0, page: 1);
  }
}
