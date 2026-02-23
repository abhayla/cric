import 'dart:async';

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
        home: PlayerProfilePage(playerId: playerId),
      ),
    );
  }

  const testProfile = PlayerProfile(
    id: 'player-1',
    displayName: 'Test Player',
    teams: [
      TeamAffiliation(teamId: 't1', teamName: 'Test Team', role: 'player'),
    ],
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
    ),
    fielding: FieldingCareerStats(catches: 5, runOuts: 2, stumpings: 0),
  );

  group('PlayerProfilePage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) => Completer<PlayerProfile>().future);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error when loading fails', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows profile content on success', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('Player Profile'), findsOneWidget);
    });

    testWidgets('shows quick stats grid', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsAtLeastNWidgets(1));
      expect(find.text('Runs'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows tab bar with batting/bowling/fielding', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Batting'), findsOneWidget);
      expect(find.text('Bowling'), findsOneWidget);
      expect(find.text('Fielding'), findsOneWidget);
    });

    testWidgets('shows view match history button', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('View Match History'), findsOneWidget);
    });

    testWidgets('shows batting stats by default', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      // Batting-specific stats visible
      expect(find.text('Highest Score'), findsOneWidget);
      expect(find.text('Strike Rate'), findsOneWidget);
    });

    testWidgets('handles null stats gracefully', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      // Should show empty stats message
      expect(find.text('No batting stats available'), findsOneWidget);
    });

    testWidgets('shows team in hero section', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => testStats);

      await tester.pumpWidget(buildWidget('player-1'));
      await tester.pumpAndSettle();

      expect(find.text('Test Team'), findsOneWidget);
    });
  });
}
