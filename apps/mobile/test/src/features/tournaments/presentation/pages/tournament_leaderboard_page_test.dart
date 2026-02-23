import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:cricscores/src/features/tournaments/presentation/pages/tournament_leaderboard_page.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';

void main() {
  Widget buildTestWidget({
    LeaderboardResult? runsResult,
    LeaderboardResult? wicketsResult,
    LeaderboardResult? avgResult,
    LeaderboardResult? ecoResult,
  }) {
    const defaultResult = LeaderboardResult(
      category: LeaderboardCategory.runs,
      leaderboard: [],
    );

    return ProviderScope(
      overrides: [
        tournamentLeaderboardProvider(
          (
            tournamentId: 'tour-1',
            category: LeaderboardCategory.runs,
          ),
        ).overrideWith((ref) async => runsResult ?? defaultResult),
        tournamentLeaderboardProvider(
          (
            tournamentId: 'tour-1',
            category: LeaderboardCategory.wickets,
          ),
        ).overrideWith((ref) async =>
            wicketsResult ??
            const LeaderboardResult(
              category: LeaderboardCategory.wickets,
              leaderboard: [],
            )),
        tournamentLeaderboardProvider(
          (
            tournamentId: 'tour-1',
            category: LeaderboardCategory.battingAvg,
          ),
        ).overrideWith((ref) async =>
            avgResult ??
            const LeaderboardResult(
              category: LeaderboardCategory.battingAvg,
              leaderboard: [],
            )),
        tournamentLeaderboardProvider(
          (
            tournamentId: 'tour-1',
            category: LeaderboardCategory.economy,
          ),
        ).overrideWith((ref) async =>
            ecoResult ??
            const LeaderboardResult(
              category: LeaderboardCategory.economy,
              leaderboard: [],
            )),
      ],
      child: const MaterialApp(
        home: TournamentLeaderboardPage(tournamentId: 'tour-1'),
      ),
    );
  }

  group('TournamentLeaderboardPage', () {
    testWidgets('renders Leaderboard title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('has 4 tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Runs'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Wickets'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Batting Avg'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Economy'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Data Yet'), findsOneWidget);
    });

    testWidgets('shows leaderboard entries', (tester) async {
      const result = LeaderboardResult(
        category: LeaderboardCategory.runs,
        leaderboard: [
          LeaderboardEntry(
            rank: 1,
            playerId: 'p1',
            playerName: 'Virat Kohli',
            teamName: 'Warriors',
            value: 320,
            matches: 5,
          ),
          LeaderboardEntry(
            rank: 2,
            playerId: 'p2',
            playerName: 'Rohit Sharma',
            teamName: 'Kings',
            value: 280,
            matches: 5,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(runsResult: result));
      await tester.pumpAndSettle();

      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('Warriors'), findsOneWidget);
      expect(find.text('Kings'), findsOneWidget);
      expect(find.text('320'), findsOneWidget);
      expect(find.text('280'), findsOneWidget);
    });

    testWidgets('shows rank badges with correct numbering', (tester) async {
      const result = LeaderboardResult(
        category: LeaderboardCategory.runs,
        leaderboard: [
          LeaderboardEntry(
            rank: 1,
            playerId: 'p1',
            playerName: 'Player One',
            teamName: 'Team A',
            value: 100,
            matches: 3,
          ),
          LeaderboardEntry(
            rank: 2,
            playerId: 'p2',
            playerName: 'Player Two',
            teamName: 'Team B',
            value: 80,
            matches: 3,
          ),
          LeaderboardEntry(
            rank: 3,
            playerId: 'p3',
            playerName: 'Player Three',
            teamName: 'Team C',
            value: 60,
            matches: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(runsResult: result));
      await tester.pumpAndSettle();

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('shows matches count per entry', (tester) async {
      const result = LeaderboardResult(
        category: LeaderboardCategory.runs,
        leaderboard: [
          LeaderboardEntry(
            rank: 1,
            playerId: 'p1',
            playerName: 'Player One',
            teamName: 'Team A',
            value: 100,
            matches: 5,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(runsResult: result));
      await tester.pumpAndSettle();

      expect(find.text('5 matches'), findsOneWidget);
    });
  });
}
