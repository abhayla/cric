import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricscores/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:cricscores/src/features/player_profile/domain/repositories/player_profile_repository.dart';
import 'package:cricscores/src/features/player_profile/presentation/notifiers/player_profile_notifier.dart';

class MockPlayerProfileRepository extends Mock
    implements PlayerProfileRepository {}

void main() {
  late MockPlayerProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerProfileRepository();
  });

  const testProfile = PlayerProfile(
    id: 'player-1',
    displayName: 'Test Player',
  );

  const testStats = CareerStats(
    format: 'all',
    batting: BattingCareerStats(
      matchesPlayed: 10,
      inningsBatted: 9,
      totalRuns: 300,
      highestScore: 75,
      notOuts: 1,
      fifties: 3,
      hundreds: 0,
      fours: 30,
      sixes: 10,
      battingAverage: 37.5,
      battingStrikeRate: 125.0,
    ),
    bowling: BowlingCareerStats(
      inningsBowled: 5,
      oversBowled: '20.0',
      runsConceded: 150,
      wicketsTaken: 8,
      bestBowlingWickets: 3,
      bestBowlingRuns: 20,
      threeWicketHauls: 1,
      fiveWicketHauls: 0,
      bowlingAverage: 18.75,
      bowlingEconomy: 7.5,
    ),
    fielding: FieldingCareerStats(catches: 5, runOuts: 2, stumpings: 0),
  );

  group('PlayerProfileNotifier', () {
    test('initial state is loading false', () {
      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );
      // Before loadProfile is called
      expect(notifier.state.isLoading, false);
      expect(notifier.state.profile, isNull);
      expect(notifier.state.selectedFormat, 'all');
      notifier.dispose();
    });

    test('loadProfile sets profile on success', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();

      expect(notifier.state.profile, testProfile);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.stats, testStats);
      verify(() => mockRepo.getProfile('player-1')).called(1);
      notifier.dispose();
    });

    test('loadProfile sets error on failure', () async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('Network error'));

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();

      expect(notifier.state.profile, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Network error'));
      notifier.dispose();
    });

    test('loadStats updates stats and format', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();
      await notifier.loadStats('T20');

      expect(notifier.state.selectedFormat, 'T20');
      expect(notifier.state.stats, testStats);
      expect(notifier.state.isStatsLoading, false);
      notifier.dispose();
    });

    test('loadStats sets error on failure', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: 'all'))
          .thenAnswer((_) async => testStats);
      when(() => mockRepo.getStats(any(), format: 'T20'))
          .thenThrow(Exception('Stats error'));

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();
      await notifier.loadStats('T20');

      expect(notifier.state.error, contains('Stats error'));
      expect(notifier.state.isStatsLoading, false);
      notifier.dispose();
    });

    test('switchFormat skips reload if same format', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();

      // Reset call count after initial load
      clearInteractions(mockRepo);

      await notifier.switchFormat('all'); // same as initial

      verifyNever(() => mockRepo.getStats(any(), format: any(named: 'format')));
      notifier.dispose();
    });

    test('switchFormat reloads stats with new format', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();
      await notifier.switchFormat('T20');

      expect(notifier.state.selectedFormat, 'T20');
      verify(() => mockRepo.getStats('player-1', format: 'T20')).called(1);
      notifier.dispose();
    });

    test('loadProfile clears previous error', () async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('First error'));

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();
      expect(notifier.state.error, contains('First error'));

      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await notifier.loadProfile();
      expect(notifier.state.error, isNull);
      expect(notifier.state.profile, testProfile);
      notifier.dispose();
    });

    test('notifies listeners on state changes', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      var callCount = 0;
      notifier.addListener(() => callCount++);

      await notifier.loadProfile();

      // Should have been called multiple times (loading, profile loaded, stats loading, stats loaded)
      expect(callCount, greaterThanOrEqualTo(3));
      notifier.dispose();
    });

    test('loadStats handles null stats', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => null);

      final notifier = PlayerProfileNotifier(
        repository: mockRepo,
        playerId: 'player-1',
      );

      await notifier.loadProfile();

      expect(notifier.state.stats, isNull);
      expect(notifier.state.isStatsLoading, false);
      notifier.dispose();
    });
  });
}
