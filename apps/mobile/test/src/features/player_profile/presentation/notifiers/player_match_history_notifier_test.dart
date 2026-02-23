import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/features/player_profile/domain/entities/match_performance.dart';
import 'package:cricscores/src/features/player_profile/domain/repositories/player_profile_repository.dart';
import 'package:cricscores/src/features/player_profile/presentation/notifiers/player_match_history_notifier.dart';

class MockPlayerProfileRepository extends Mock
    implements PlayerProfileRepository {}

const _match1 = MatchPerformance(
  matchId: 'match-1',
  format: 'T20',
  matchDate: '2026-02-01',
  homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
  awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
  teamScores: [],
  playerResult: 'won',
  playerTeamId: 'h1',
);

const _match2 = MatchPerformance(
  matchId: 'match-2',
  format: 'T20',
  matchDate: '2026-01-15',
  homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
  awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
  teamScores: [],
  playerResult: 'lost',
  playerTeamId: 'h1',
);

void main() {
  late MockPlayerProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerProfileRepository();
  });

  group('PlayerMatchHistoryNotifier', () {
    test('initial state is correct', () {
      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );
      expect(notifier.state.matches, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.selectedResult, isNull);
      expect(notifier.state.page, 1);
      notifier.dispose();
    });

    test('loadMatches populates matches on success', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1, _match2],
            total: 2,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();

      expect(notifier.state.matches.length, 2);
      expect(notifier.state.total, 2);
      expect(notifier.state.page, 1);
      expect(notifier.state.isLoading, false);
      notifier.dispose();
    });

    test('loadMatches sets error on failure', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenThrow(Exception('Server error'));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();

      expect(notifier.state.matches, isEmpty);
      expect(notifier.state.error, contains('Server error'));
      expect(notifier.state.isLoading, false);
      notifier.dispose();
    });

    test('loadMore appends matches to existing list', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: 1,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 25,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();
      expect(notifier.state.matches.length, 1);
      expect(notifier.state.hasMore, true);

      when(() => mockRepo.getMatchHistory(
            any(),
            page: 2,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match2],
            total: 25,
            page: 2,
            limit: 20,
          ));

      await notifier.loadMore();

      expect(notifier.state.matches.length, 2);
      expect(notifier.state.page, 2);
      notifier.dispose();
    });

    test('loadMore does nothing when no more pages', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();
      expect(notifier.state.hasMore, false);

      clearInteractions(mockRepo);
      await notifier.loadMore();

      verifyNever(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          ));
      notifier.dispose();
    });

    test('filterByResult reloads with filter', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();
      await notifier.filterByResult('won');

      expect(notifier.state.selectedResult, 'won');
      verify(() => mockRepo.getMatchHistory(
            'player-1',
            page: 1,
            limit: 20,
            result: 'won',
          )).called(1);
      notifier.dispose();
    });

    test('filterByResult with null clears filter', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();
      await notifier.filterByResult('won');
      await notifier.filterByResult(null);

      expect(notifier.state.selectedResult, isNull);
      notifier.dispose();
    });

    test('filterByResult skips if same filter', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();
      await notifier.filterByResult('won');

      clearInteractions(mockRepo);
      await notifier.filterByResult('won'); // same filter

      verifyNever(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          ));
      notifier.dispose();
    });

    test('loadMore sets error on failure', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: 1,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 25,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();

      when(() => mockRepo.getMatchHistory(
            any(),
            page: 2,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenThrow(Exception('Load more error'));

      await notifier.loadMore();

      expect(notifier.state.error, contains('Load more error'));
      expect(notifier.state.isLoadingMore, false);
      // Original matches still present
      expect(notifier.state.matches.length, 1);
      notifier.dispose();
    });

    test('notifies listeners on state changes', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 1,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      var callCount = 0;
      notifier.addListener(() => callCount++);

      await notifier.loadMatches();

      expect(callCount, greaterThanOrEqualTo(2)); // loading + loaded
      notifier.dispose();
    });

    test('filterByResult resets page to 1', () async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: 1,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 25,
            page: 1,
            limit: 20,
          ));

      final notifier = PlayerMatchHistoryNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadMatches();

      when(() => mockRepo.getMatchHistory(
            any(),
            page: 2,
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match2],
            total: 25,
            page: 2,
            limit: 20,
          ));

      await notifier.loadMore();
      expect(notifier.state.page, 2);

      when(() => mockRepo.getMatchHistory(
            any(),
            page: 1,
            limit: any(named: 'limit'),
            result: 'won',
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_match1],
            total: 10,
            page: 1,
            limit: 20,
          ));

      await notifier.filterByResult('won');
      expect(notifier.state.page, 1); // reset
      notifier.dispose();
    });
  });
}
