import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/domain/entities/match_list_item.dart';
import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';

void main() {
  Widget buildTestWidget(MatchListItem match, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: MatchCard(match: match, onTap: onTap),
      ),
    );
  }

  final liveMatch = MatchListItem(
    id: 'match-1',
    homeTeamId: 'team-1',
    awayTeamId: 'team-2',
    homeTeamName: 'Mumbai Warriors',
    awayTeamName: 'Chennai Kings',
    format: 'T20',
    totalOvers: 20,
    status: 'live',
    matchDate: '2026-03-15',
    venue: 'Wankhede Stadium',
    currentInnings: const InningsSnapshot(
      battingTeamId: 'team-1',
      totalRuns: 156,
      totalWickets: 4,
      overs: '18.2',
    ),
  );

  final completedMatch = MatchListItem(
    id: 'match-2',
    homeTeamId: 'team-3',
    awayTeamId: 'team-4',
    homeTeamName: 'Delhi Strikers',
    awayTeamName: 'Kolkata Thunder',
    format: 'ODI',
    totalOvers: 50,
    status: 'completed',
    matchDate: '2026-02-08',
    result: 'Delhi Strikers won by 15 runs',
    firstInnings: const InningsSnapshot(
      battingTeamId: 'team-3',
      totalRuns: 187,
      totalWickets: 6,
      overs: '50.0',
    ),
    secondInnings: const InningsSnapshot(
      battingTeamId: 'team-4',
      totalRuns: 172,
      totalWickets: 9,
      overs: '50.0',
    ),
  );

  final setupMatch = MatchListItem(
    id: 'match-3',
    homeTeamId: 'team-5',
    awayTeamId: 'team-6',
    homeTeamName: 'Team A',
    awayTeamName: 'Team B',
    format: 'T20',
    totalOvers: 20,
    status: 'setup',
    matchDate: '2026-03-20',
  );

  group('MatchCard', () {
    testWidgets('displays team names', (tester) async {
      await tester.pumpWidget(buildTestWidget(liveMatch));

      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Chennai Kings'), findsOneWidget);
    });

    testWidgets('displays score for current innings (live match)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(liveMatch));

      expect(find.text('156/4'), findsOneWidget);
      expect(find.text('(18.2)'), findsOneWidget);
    });

    testWidgets('displays both teams scores for completed match',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(completedMatch));

      expect(find.text('187/6'), findsOneWidget);
      expect(find.text('172/9'), findsOneWidget);
    });

    testWidgets('displays LIVE badge for live match', (tester) async {
      await tester.pumpWidget(buildTestWidget(liveMatch));

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('displays Completed badge for completed match', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedMatch));

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('displays result text for completed match', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedMatch));

      expect(find.text('Delhi Strikers won by 15 runs'), findsOneWidget);
    });

    testWidgets('displays meta line with format', (tester) async {
      await tester.pumpWidget(buildTestWidget(liveMatch));

      // Should show "T20" in meta
      expect(find.textContaining('T20'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(liveMatch, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(MatchCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows dash for team without score (setup match)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(setupMatch));

      // No score data should be shown, dash instead
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('shows Setup badge for setup match', (tester) async {
      await tester.pumpWidget(buildTestWidget(setupMatch));

      expect(find.text('Setup'), findsOneWidget);
    });

    testWidgets('shows venue in meta line when available', (tester) async {
      await tester.pumpWidget(buildTestWidget(liveMatch));

      expect(find.textContaining('Wankhede'), findsOneWidget);
    });
  });
}
