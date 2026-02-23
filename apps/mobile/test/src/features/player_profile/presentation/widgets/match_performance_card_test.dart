import 'package:cricscores/src/features/player_profile/domain/entities/match_performance.dart';
import 'package:cricscores/src/features/player_profile/presentation/widgets/match_performance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(MatchPerformance match, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MatchPerformanceCard(match: match, onTap: onTap),
        ),
      ),
    );
  }

  const fullMatch = MatchPerformance(
    matchId: 'match-1',
    format: 'T20',
    matchDate: '2026-02-08',
    venue: 'Shivaji Park',
    homeTeam: MatchTeamInfo(id: 'h1', name: 'Mumbai Warriors'),
    awayTeam: MatchTeamInfo(id: 'a1', name: 'Delhi Strikers'),
    teamScores: [
      TeamScore(
        teamId: 'h1',
        teamName: 'Mumbai Warriors',
        runs: 187,
        wickets: 6,
        overs: '20.0',
      ),
      TeamScore(
        teamId: 'a1',
        teamName: 'Delhi Strikers',
        runs: 172,
        wickets: 9,
        overs: '20.0',
      ),
    ],
    result: MatchResultSummary(
      resultType: 'runs',
      summary: 'Mumbai Warriors won by 15 runs',
      winnerTeamId: 'h1',
      margin: 15,
    ),
    playerResult: 'won',
    playerTeamId: 'h1',
    batting: PersonalBatting(
      runsScored: 75,
      ballsFaced: 45,
      fours: 8,
      sixes: 3,
      isNotOut: true,
      strikeRate: 166.67,
    ),
    bowling: PersonalBowling(
      oversBowled: '4.0',
      runsConceded: 30,
      wicketsTaken: 2,
      maidens: 0,
      economyRate: 7.5,
    ),
  );

  group('MatchPerformanceCard', () {
    testWidgets('displays match format and date', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.textContaining('T20'), findsOneWidget);
      expect(find.textContaining('2026-02-08'), findsOneWidget);
    });

    testWidgets('displays venue in meta', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.textContaining('Shivaji Park'), findsOneWidget);
    });

    testWidgets('displays team names and scores', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Delhi Strikers'), findsOneWidget);
      expect(find.text('187/6'), findsOneWidget);
      expect(find.text('172/9'), findsOneWidget);
    });

    testWidgets('displays result summary', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(
        find.text('Mumbai Warriors won by 15 runs'),
        findsOneWidget,
      );
    });

    testWidgets('displays result badge', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.text('Won'), findsOneWidget);
    });

    testWidgets('displays personal batting stats', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.text('75* (45)'), findsOneWidget);
    });

    testWidgets('displays personal bowling stats', (tester) async {
      await tester.pumpWidget(buildWidget(fullMatch));
      expect(find.text('2/30 (4.0)'), findsOneWidget);
    });

    testWidgets('shows lost badge for lost matches', (tester) async {
      const lostMatch = MatchPerformance(
        matchId: 'match-2',
        format: 'T20',
        matchDate: '2026-02-01',
        homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
        awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
        teamScores: [],
        playerResult: 'lost',
        playerTeamId: 'h1',
      );
      await tester.pumpWidget(buildWidget(lostMatch));
      expect(find.text('Lost'), findsOneWidget);
    });

    testWidgets('shows tied badge for tied matches', (tester) async {
      const tiedMatch = MatchPerformance(
        matchId: 'match-3',
        format: 'T20',
        matchDate: '2026-02-01',
        homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
        awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
        teamScores: [],
        playerResult: 'tied',
        playerTeamId: 'h1',
      );
      await tester.pumpWidget(buildWidget(tiedMatch));
      expect(find.text('Tied'), findsOneWidget);
    });

    testWidgets('shows N/R badge for no result', (tester) async {
      const nrMatch = MatchPerformance(
        matchId: 'match-4',
        format: 'T20',
        matchDate: '2026-02-01',
        homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
        awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
        teamScores: [],
        playerResult: 'no_result',
        playerTeamId: 'h1',
      );
      await tester.pumpWidget(buildWidget(nrMatch));
      expect(find.text('N/R'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildWidget(fullMatch, onTap: () => tapped = true),
      );
      await tester.tap(find.byType(MatchPerformanceCard));
      expect(tapped, true);
    });

    testWidgets('shows team names when no scores', (tester) async {
      const noScoreMatch = MatchPerformance(
        matchId: 'match-5',
        format: 'T20',
        matchDate: '2026-02-01',
        homeTeam: MatchTeamInfo(id: 'h1', name: 'Team A'),
        awayTeam: MatchTeamInfo(id: 'a1', name: 'Team B'),
        teamScores: [],
        playerResult: 'no_result',
        playerTeamId: 'h1',
      );
      await tester.pumpWidget(buildWidget(noScoreMatch));
      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
    });

    testWidgets('hides personal stats when not available', (tester) async {
      const noBattingMatch = MatchPerformance(
        matchId: 'match-6',
        format: 'T20',
        matchDate: '2026-02-01',
        homeTeam: MatchTeamInfo(id: 'h1', name: 'Home'),
        awayTeam: MatchTeamInfo(id: 'a1', name: 'Away'),
        teamScores: [],
        playerResult: 'won',
        playerTeamId: 'h1',
      );
      await tester.pumpWidget(buildWidget(noBattingMatch));
      expect(find.byIcon(Icons.sports_cricket), findsNothing);
    });
  });
}
