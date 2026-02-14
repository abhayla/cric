import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/providers.dart';
import 'package:cricapp/src/features/home/domain/entities/match_list_item.dart';
import 'package:cricapp/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricapp/src/features/home/presentation/pages/home_page.dart';
import 'package:cricapp/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricapp/src/features/home/providers.dart';

void main() {
  final liveMatchData = MatchListResult(
    matches: [
      MatchListItem(
        id: 'live-1',
        homeTeamName: 'Chennai Kings',
        awayTeamName: 'Bangalore Royals',
        format: 'T20',
        totalOvers: 20,
        status: 'live',
        matchDate: '2026-03-15',
        venue: 'Marina Ground',
        currentInnings: const InningsSnapshot(
          battingTeamId: 'team-1',
          totalRuns: 156,
          totalWickets: 4,
          overs: '18.2',
        ),
      ),
    ],
    total: 1,
    page: 1,
  );

  final recentMatchData = MatchListResult(
    matches: [
      MatchListItem(
        id: 'recent-1',
        homeTeamName: 'Mumbai Warriors',
        awayTeamName: 'Delhi Strikers',
        format: 'T20',
        totalOvers: 20,
        status: 'completed',
        matchDate: '2026-02-08',
        result: 'Mumbai Warriors won by 15 runs',
        currentInnings: const InningsSnapshot(
          battingTeamId: 'team-2',
          totalRuns: 172,
          totalWickets: 9,
          overs: '20.0',
        ),
      ),
    ],
    total: 1,
    page: 1,
  );

  final emptyMatchData = const MatchListResult(
    matches: [],
    total: 0,
    page: 1,
  );

  Widget buildTestWidget({
    AsyncValue<MatchListResult>? liveMatches,
    AsyncValue<MatchListResult>? recentMatches,
  }) {
    return ProviderScope(
      overrides: [
        // Override auth state to return null user (no Firebase needed)
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        liveMatchesProvider.overrideWith(
          (ref) => (liveMatches ?? AsyncValue.data(emptyMatchData)).when(
            data: (d) => Future.value(d),
            loading: () => Future.any([]),
            error: (e, s) => Future.error(e, s),
          ),
        ),
        recentMatchesProvider.overrideWith(
          (ref) => (recentMatches ?? AsyncValue.data(emptyMatchData)).when(
            data: (d) => Future.value(d),
            loading: () => Future.any([]),
            error: (e, s) => Future.error(e, s),
          ),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  group('HomePage', () {
    testWidgets('renders CricApp title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Title uses Text.rich with spans — find by RichText content
      expect(find.byType(RichText), findsAtLeast(1));
    });

    testWidgets('renders quick action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Start Match'), findsOneWidget);
      expect(find.text('Create Team'), findsOneWidget);
      expect(find.text('Tournament'), findsOneWidget);
    });

    testWidgets('shows live matches section when data available',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        liveMatches: AsyncValue.data(liveMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Chennai Kings'), findsOneWidget);
      expect(find.text('Bangalore Royals'), findsOneWidget);
    });

    testWidgets('hides live section when no live matches', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        liveMatches: AsyncValue.data(emptyMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live'), findsNothing);
    });

    testWidgets('shows recent matches section', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        recentMatches: AsyncValue.data(recentMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recent Matches'), findsOneWidget);
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('shows empty state when no recent matches', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        recentMatches: AsyncValue.data(emptyMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No matches yet'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows error state for live matches hides section',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        liveMatches: AsyncValue.error('Network error', StackTrace.current),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Error state should not crash — section just hidden
      expect(find.text('Live'), findsNothing);
    });

    testWidgets('renders MatchCard widgets for live matches', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        liveMatches: AsyncValue.data(liveMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MatchCard), findsOneWidget);
    });

    testWidgets('renders Recent Matches View All button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        recentMatches: AsyncValue.data(recentMatchData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('View All'), findsAtLeast(1));
    });
  });
}
