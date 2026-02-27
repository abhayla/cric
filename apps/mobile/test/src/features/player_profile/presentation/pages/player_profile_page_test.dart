import 'dart:async';

import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricscores/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:cricscores/src/features/player_profile/domain/repositories/player_profile_repository.dart';
import 'package:cricscores/src/features/player_profile/presentation/pages/player_profile_page.dart';
import 'package:cricscores/src/features/player_profile/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerProfileRepository extends Mock
    implements PlayerProfileRepository {}

const _playerId = 'player-1';

const _testProfile = PlayerProfile(
  id: _playerId,
  displayName: 'Test Player',
  playerRole: PlayerRole.batter,
  battingStyle: BattingStyle.rightHand,
);

const _testStats = CareerStats(
  format: 'all',
  batting: BattingCareerStats(
    matchesPlayed: 10,
    inningsBatted: 9,
    totalRuns: 350,
    highestScore: 75,
    notOuts: 2,
    fifties: 3,
    hundreds: 0,
    fours: 30,
    sixes: 10,
    ducks: 1,
  ),
  bowling: BowlingCareerStats(
    inningsBowled: 5,
    oversBowled: '20.0',
    runsConceded: 150,
    wicketsTaken: 6,
    bestBowlingWickets: 3,
    bestBowlingRuns: 20,
    threeWicketHauls: 1,
    fiveWicketHauls: 0,
  ),
  fielding: FieldingCareerStats(
    catches: 8,
    runOuts: 3,
    stumpings: 0,
    directHits: 1,
  ),
);

void main() {
  late MockPlayerProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerProfileRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [playerProfileRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(
        home: PlayerProfilePage(playerId: _playerId),
      ),
    );
  }

  group('PlayerProfilePage', () {
    testWidgets('shows AppBar with Player Profile title', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) => Completer<PlayerProfile>().future);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Player Profile'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('loading state shows spinner', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) => Completer<PlayerProfile>().future);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state shows Something went wrong', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('profile loaded shows hero, quick stats, tabs', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => _testStats);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Hero
      expect(find.text('Test Player'), findsOneWidget);

      // Quick stats
      expect(find.text('Matches'), findsAtLeastNWidgets(1));
      expect(find.text('Runs'), findsAtLeastNWidgets(1));

      // Tabs
      expect(find.text('Batting'), findsOneWidget);
      expect(find.text('Bowling'), findsOneWidget);
      expect(find.text('Fielding'), findsOneWidget);

      // Batting stats (default tab)
      expect(find.text('Highest Score'), findsOneWidget);

      // Match history button
      expect(find.text('View Match History'), findsOneWidget);
    });

    testWidgets('null stats shows empty message in batting tab', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('No batting stats available'), findsOneWidget);
    });

    testWidgets('format selector shows All, T20, ODI', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => _testStats);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('T20'), findsOneWidget);
      expect(find.text('ODI'), findsOneWidget);
    });

    testWidgets('error state shows retry button', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
