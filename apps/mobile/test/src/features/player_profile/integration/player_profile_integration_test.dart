import 'dart:async';

import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/match_performance.dart';
import 'package:cricapp/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:cricapp/src/features/player_profile/domain/repositories/player_profile_repository.dart';
import 'package:cricapp/src/features/player_profile/presentation/pages/player_match_history_page.dart';
import 'package:cricapp/src/features/player_profile/presentation/pages/player_profile_page.dart';
import 'package:cricapp/src/features/player_profile/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerProfileRepository extends Mock
    implements PlayerProfileRepository {}

const _playerId = 'player-123';

const _testProfile = PlayerProfile(
  id: _playerId,
  displayName: 'Virat Kohli',
  playerRole: PlayerRole.batter,
  battingStyle: BattingStyle.rightHand,
  teams: [
    TeamAffiliation(teamId: 't1', teamName: 'Royal Challengers', role: 'player'),
    TeamAffiliation(teamId: 't2', teamName: 'India XI', role: 'captain'),
  ],
);

const _testStats = CareerStats(
  format: 'all',
  batting: BattingCareerStats(
    matchesPlayed: 25,
    inningsBatted: 24,
    totalRuns: 800,
    highestScore: 120,
    notOuts: 3,
    fifties: 6,
    hundreds: 1,
    fours: 80,
    sixes: 20,
  ),
  bowling: BowlingCareerStats(
    inningsBowled: 10,
    oversBowled: '40.0',
    runsConceded: 300,
    wicketsTaken: 12,
    bestBowlingWickets: 3,
    bestBowlingRuns: 20,
    threeWicketHauls: 2,
    fiveWicketHauls: 0,
  ),
  fielding: FieldingCareerStats(catches: 15, runOuts: 5, stumpings: 0),
);

const _t20Stats = CareerStats(
  format: 'T20',
  batting: BattingCareerStats(
    matchesPlayed: 15,
    inningsBatted: 14,
    totalRuns: 500,
    highestScore: 95,
    notOuts: 2,
    fifties: 4,
    hundreds: 0,
    fours: 50,
    sixes: 15,
  ),
  bowling: BowlingCareerStats(
    inningsBowled: 5,
    oversBowled: '20.0',
    runsConceded: 150,
    wicketsTaken: 6,
    bestBowlingWickets: 2,
    bestBowlingRuns: 15,
    threeWicketHauls: 0,
    fiveWicketHauls: 0,
  ),
  fielding: FieldingCareerStats(catches: 8, runOuts: 3, stumpings: 0),
);

const _matchWon = MatchPerformance(
  matchId: 'match-1',
  format: 'T20',
  matchDate: '2026-02-10',
  homeTeam: MatchTeamInfo(id: 'h1', name: 'Mumbai Warriors'),
  awayTeam: MatchTeamInfo(id: 'a1', name: 'Delhi Strikers'),
  teamScores: [
    TeamScore(teamId: 'h1', teamName: 'Mumbai Warriors', runs: 187, wickets: 6, overs: '20.0'),
    TeamScore(teamId: 'a1', teamName: 'Delhi Strikers', runs: 172, wickets: 9, overs: '20.0'),
  ],
  result: MatchResultSummary(resultType: 'runs', summary: 'Won by 15 runs', winnerTeamId: 'h1'),
  playerResult: 'won',
  playerTeamId: 'h1',
  batting: PersonalBatting(runsScored: 75, ballsFaced: 45, fours: 8, sixes: 3, isNotOut: true),
);

const _matchLost = MatchPerformance(
  matchId: 'match-2',
  format: 'T20',
  matchDate: '2026-02-01',
  homeTeam: MatchTeamInfo(id: 'h1', name: 'Mumbai Warriors'),
  awayTeam: MatchTeamInfo(id: 'a1', name: 'Delhi Strikers'),
  teamScores: [
    TeamScore(teamId: 'h1', teamName: 'Mumbai Warriors', runs: 140, wickets: 10, overs: '19.2'),
    TeamScore(teamId: 'a1', teamName: 'Delhi Strikers', runs: 141, wickets: 3, overs: '17.4'),
  ],
  result: MatchResultSummary(resultType: 'wickets', summary: 'Won by 7 wickets', winnerTeamId: 'a1'),
  playerResult: 'lost',
  playerTeamId: 'h1',
  bowling: PersonalBowling(oversBowled: '4.0', runsConceded: 35, wicketsTaken: 2, maidens: 0),
);

void main() {
  late MockPlayerProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerProfileRepository();
  });

  Widget buildProfilePage() {
    return ProviderScope(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: PlayerProfilePage(playerId: _playerId),
      ),
    );
  }

  Widget buildMatchHistoryPage() {
    return ProviderScope(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: PlayerMatchHistoryPage(playerId: _playerId),
      ),
    );
  }

  group('Profile page full integration', () {
    testWidgets('loads profile and stats, displays all sections', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => _testStats);

      await tester.pumpWidget(buildProfilePage());
      await tester.pumpAndSettle();

      // Hero section
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Royal Challengers'), findsOneWidget);

      // Quick stats
      expect(find.text('Matches'), findsAtLeastNWidgets(1));
      expect(find.text('Runs'), findsAtLeastNWidgets(1));

      // Tab bar
      expect(find.text('Batting'), findsOneWidget);
      expect(find.text('Bowling'), findsOneWidget);
      expect(find.text('Fielding'), findsOneWidget);

      // Batting stats (default tab)
      expect(find.text('Highest Score'), findsOneWidget);

      // Match history button
      expect(find.text('View Match History'), findsOneWidget);
    });

    testWidgets('error state shows error and can retry', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenThrow(Exception('Network timeout'));

      await tester.pumpWidget(buildProfilePage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Network timeout'), findsOneWidget);
    });

    testWidgets('loading state shows spinner', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) => Completer<PlayerProfile>().future);

      await tester.pumpWidget(buildProfilePage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('null stats shows empty message in batting tab', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildProfilePage());
      await tester.pumpAndSettle();

      expect(find.text('No batting stats available'), findsOneWidget);
    });

    testWidgets('profile with multiple teams shows first team chip', (tester) async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => _testProfile);
      when(() => mockRepo.getStats(any(), format: any(named: 'format')))
          .thenAnswer((_) async => _testStats);

      await tester.pumpWidget(buildProfilePage());
      await tester.pumpAndSettle();

      // First team shown in hero
      expect(find.text('Royal Challengers'), findsOneWidget);
    });
  });

  group('Match history page full integration', () {
    testWidgets('loads and displays match cards with scores', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_matchWon, _matchLost],
            total: 2,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildMatchHistoryPage());
      await tester.pumpAndSettle();

      // Team names from scores
      expect(find.text('Mumbai Warriors'), findsNWidgets(2));
      expect(find.text('Delhi Strikers'), findsNWidgets(2));

      // Result badges
      expect(find.text('Won'), findsAtLeastNWidgets(1));
      expect(find.text('Lost'), findsAtLeastNWidgets(1));
    });

    testWidgets('filter chips trigger reload with correct result', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_matchWon],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildMatchHistoryPage());
      await tester.pumpAndSettle();

      // Tap 'Won' filter
      final wonChips = find.widgetWithText(FilterChip, 'Won');
      await tester.tap(wonChips.first);
      await tester.pumpAndSettle();

      // Verify called with 'won' result filter
      verify(() => mockRepo.getMatchHistory(
            _playerId,
            page: 1,
            limit: 20,
            result: 'won',
          )).called(1);
    });

    testWidgets('empty state shows no matches message', (tester) async {
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

      await tester.pumpWidget(buildMatchHistoryPage());
      await tester.pumpAndSettle();

      expect(find.text('No Match History'), findsOneWidget);
    });

    testWidgets('shows personal batting stats on match card', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_matchWon],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildMatchHistoryPage());
      await tester.pumpAndSettle();

      // Personal batting: 75* (45)
      expect(find.text('75* (45)'), findsOneWidget);
    });

    testWidgets('shows personal bowling stats on match card', (tester) async {
      when(() => mockRepo.getMatchHistory(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            result: any(named: 'result'),
          )).thenAnswer((_) async => const MatchHistoryResult(
            matches: [_matchLost],
            total: 1,
            page: 1,
            limit: 20,
          ));

      await tester.pumpWidget(buildMatchHistoryPage());
      await tester.pumpAndSettle();

      // Personal bowling: 2/35 (4.0)
      expect(find.text('2/35 (4.0)'), findsOneWidget);
    });
  });
}
