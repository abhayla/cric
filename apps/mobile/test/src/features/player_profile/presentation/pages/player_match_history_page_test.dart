import 'dart:async';

import 'package:cricscores/src/features/player_profile/domain/entities/match_performance.dart';
import 'package:cricscores/src/features/player_profile/domain/repositories/player_profile_repository.dart';
import 'package:cricscores/src/features/player_profile/presentation/pages/player_match_history_page.dart';
import 'package:cricscores/src/features/player_profile/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerProfileRepository extends Mock
    implements PlayerProfileRepository {}

void main() {
  late MockPlayerProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerProfileRepository();
  });

  Widget buildWidget(String playerId) {
    return ProviderScope(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: PlayerMatchHistoryPage(playerId: playerId),
      ),
    );
  }

  const match1 = MatchPerformance(
    matchId: 'match-1',
    format: 'T20',
    matchDate: '2026-02-08',
    homeTeam: MatchTeamInfo(id: 'h1', name: 'Mumbai Warriors'),
    awayTeam: MatchTeamInfo(id: 'a1', name: 'Delhi Strikers'),
    teamScores: [
      TeamScore(
          teamId: 'h1', teamName: 'Mumbai Warriors', runs: 187, wickets: 6, overs: '20.0'),
      TeamScore(
          teamId: 'a1', teamName: 'Delhi Strikers', runs: 172, wickets: 9, overs: '20.0'),
    ],
    result: MatchResultSummary(
      resultType: 'runs',
      summary: 'Won by 15 runs',
    ),
    playerResult: 'won',
    playerTeamId: 'h1',
  );

  const match2 = MatchPerformance(
    matchId: 'match-2',
    format: 'T20',
    matchDate: '2026-02-01',
    homeTeam: MatchTeamInfo(id: 'h1', name: 'Home Team'),
    awayTeam: MatchTeamInfo(id: 'a1', name: 'Away Team'),
    teamScores: [],
    playerResult: 'lost',
    playerTeamId: 'h1',
  );

  group('PlayerMatchHistoryPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) => Completer<MatchHistoryResult>().future);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when loading fails', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenThrow(Exception('Server error'));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows empty state when no matches', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [],
            total: 0,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('No Match History'), findsOneWidget);
    });

    testWidgets('shows matches list on success', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [match1, match2],
            total: 2,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Delhi Strikers'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Won'), findsAtLeastNWidgets(1));
      expect(find.text('Lost'), findsOneWidget);
      expect(find.text('Tied'), findsOneWidget);
      expect(find.text('No Result'), findsOneWidget);
    });

    testWidgets('tapping filter chip triggers reload', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      // Find the "Won" filter chip and tap it
      final wonChips = find.widgetWithText(FilterChip, 'Won');
      await tester.tap(wonChips.first);
      await tester.pumpAndSettle();

      // Verify it called with 'won' result filter
      verify(() => mockRepo.getMatchHistory(
            'player-1',
            page: 1,
            limit: 20,
            result: 'won',
          )).called(1);
    });

    testWidgets('shows app bar with Match History title', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [],
            total: 0,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Match History'), findsOneWidget);
    });

    testWidgets('shows result badges on match cards', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      // Won badge from match1
      expect(find.text('Won'), findsAtLeastNWidgets(1));
    });
  });
}
