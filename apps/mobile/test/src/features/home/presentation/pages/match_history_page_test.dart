import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/home/domain/entities/match_list_item.dart';
import 'package:cricapp/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricapp/src/features/home/presentation/pages/match_history_page.dart';
import 'package:cricapp/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricapp/src/features/home/providers.dart';

void main() {
  final matchData = MatchListResult(
    matches: [
      MatchListItem(
        id: 'match-1',
        homeTeamName: 'Mumbai Warriors',
        awayTeamName: 'Delhi Strikers',
        format: 'T20',
        totalOvers: 20,
        status: 'completed',
        matchDate: '2026-02-08',
        result: 'Mumbai Warriors won by 15 runs',
      ),
      MatchListItem(
        id: 'match-2',
        homeTeamName: 'Chennai Kings',
        awayTeamName: 'Kolkata Thunder',
        format: 'T20',
        totalOvers: 20,
        status: 'completed',
        matchDate: '2026-02-05',
        result: 'Chennai Kings won by 7 wickets',
      ),
    ],
    total: 2,
    page: 1,
  );

  final emptyData = const MatchListResult(
    matches: [],
    total: 0,
    page: 1,
  );

  Widget buildTestWidget({
    AsyncValue<MatchListResult>? allMatches,
  }) {
    return ProviderScope(
      overrides: [
        allMatchesProvider.overrideWith(
          (ref, page) => (allMatches ?? AsyncValue.data(emptyData)).when(
            data: (d) => Future.value(d),
            loading: () => Future.any([]),
            error: (e, s) => Future.error(e, s),
          ),
        ),
      ],
      child: const MaterialApp(home: MatchHistoryPage()),
    );
  }

  group('MatchHistoryPage', () {
    testWidgets('renders Matches title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
    });

    testWidgets('shows match list when data available', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        allMatches: AsyncValue.data(matchData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MatchCard), findsNWidgets(2));
      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Chennai Kings'), findsOneWidget);
    });

    testWidgets('shows empty state when no matches', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        allMatches: AsyncValue.data(emptyData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No matches yet'), findsOneWidget);
      expect(
          find.text('Start a match to see your history here'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        allMatches: AsyncValue.error('Network error', StackTrace.current),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        allMatches: const AsyncValue.loading(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Start a Match button in empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        allMatches: AsyncValue.data(emptyData),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Start a Match'), findsOneWidget);
    });
  });
}
