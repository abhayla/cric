import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/home/domain/entities/match_list_item.dart';

void main() {
  group('MatchListItem', () {
    test('constructs with required fields', () {
      final item = MatchListItem(
        id: 'match-1',
        homeTeamName: 'Mumbai',
        awayTeamName: 'Chennai',
        format: 'T20',
        totalOvers: 20,
        status: 'live',
        matchDate: '2026-03-15',
      );

      expect(item.id, 'match-1');
      expect(item.homeTeamName, 'Mumbai');
      expect(item.awayTeamName, 'Chennai');
      expect(item.format, 'T20');
      expect(item.totalOvers, 20);
      expect(item.status, 'live');
      expect(item.matchDate, '2026-03-15');
      expect(item.venue, isNull);
      expect(item.currentInnings, isNull);
      expect(item.result, isNull);
    });

    test('constructs with all optional fields', () {
      final item = MatchListItem(
        id: 'match-2',
        homeTeamName: 'Mumbai',
        awayTeamName: 'Chennai',
        format: 'ODI',
        totalOvers: 50,
        status: 'completed',
        matchDate: '2026-03-15',
        venue: 'Wankhede Stadium',
        currentInnings: const InningsSnapshot(
          battingTeamId: 'team-1',
          totalRuns: 185,
          totalWickets: 7,
          overs: '20.0',
        ),
        result: 'Mumbai won by 15 runs',
      );

      expect(item.venue, 'Wankhede Stadium');
      expect(item.currentInnings, isNotNull);
      expect(item.currentInnings!.totalRuns, 185);
      expect(item.currentInnings!.totalWickets, 7);
      expect(item.currentInnings!.overs, '20.0');
      expect(item.result, 'Mumbai won by 15 runs');
    });

    test('title returns "HomeTeam vs AwayTeam"', () {
      final item = MatchListItem(
        id: 'match-1',
        homeTeamName: 'Mumbai',
        awayTeamName: 'Chennai',
        format: 'T20',
        totalOvers: 20,
        status: 'live',
        matchDate: '2026-03-15',
      );

      expect(item.title, 'Mumbai vs Chennai');
    });

    test('isLive returns true for live status', () {
      final item = MatchListItem(
        id: 'match-1',
        homeTeamName: 'Mumbai',
        awayTeamName: 'Chennai',
        format: 'T20',
        totalOvers: 20,
        status: 'live',
        matchDate: '2026-03-15',
      );

      expect(item.isLive, isTrue);
      expect(item.isCompleted, isFalse);
    });

    test('isCompleted returns true for completed status', () {
      final item = MatchListItem(
        id: 'match-1',
        homeTeamName: 'Mumbai',
        awayTeamName: 'Chennai',
        format: 'T20',
        totalOvers: 20,
        status: 'completed',
        matchDate: '2026-03-15',
      );

      expect(item.isCompleted, isTrue);
      expect(item.isLive, isFalse);
    });
  });

  group('InningsSnapshot', () {
    test('constructs with all fields', () {
      const snapshot = InningsSnapshot(
        battingTeamId: 'team-1',
        totalRuns: 150,
        totalWickets: 5,
        overs: '15.3',
      );

      expect(snapshot.battingTeamId, 'team-1');
      expect(snapshot.totalRuns, 150);
      expect(snapshot.totalWickets, 5);
      expect(snapshot.overs, '15.3');
    });

    test('scoreDisplay returns "runs/wickets"', () {
      const snapshot = InningsSnapshot(
        battingTeamId: 'team-1',
        totalRuns: 150,
        totalWickets: 5,
        overs: '15.3',
      );

      expect(snapshot.scoreDisplay, '150/5');
    });
  });
}
