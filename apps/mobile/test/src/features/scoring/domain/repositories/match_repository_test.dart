import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/match.dart';
import 'package:cricapp/src/features/scoring/domain/repositories/match_repository.dart';

void main() {
  group('MatchRepository interface', () {
    test('MatchListResult holds matches, total, and page', () {
      const result = MatchListResult(
        matches: [],
        total: 0,
        page: 1,
      );

      expect(result.matches, isEmpty);
      expect(result.total, 0);
      expect(result.page, 1);
    });

    test('MatchListResult holds populated data', () {
      final match = Match(
        id: 'match-1',
        homeTeamId: 'team-1',
        awayTeamId: 'team-2',
        format: MatchFormat.t20,
        totalOvers: 20,
        ballTypeId: 1,
        status: MatchStatus.setup,
        playersPerSide: 11,
        wideRuns: 1,
        noBallRuns: 1,
        scorerId: 'user-1',
        createdBy: 'user-1',
        matchDate: '2026-01-15',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = MatchListResult(
        matches: [match],
        total: 1,
        page: 1,
      );

      expect(result.matches.length, 1);
      expect(result.matches.first.id, 'match-1');
      expect(result.total, 1);
    });

    test('CreateMatchInput holds all creation fields', () {
      const input = CreateMatchInput(
        homeTeamId: 'team-1',
        awayTeamId: 'team-2',
        format: MatchFormat.t20,
        totalOvers: 20,
        ballTypeId: 1,
        matchDate: '2026-01-15',
      );

      expect(input.homeTeamId, 'team-1');
      expect(input.awayTeamId, 'team-2');
      expect(input.format, MatchFormat.t20);
      expect(input.totalOvers, 20);
      expect(input.ballTypeId, 1);
      expect(input.matchDate, '2026-01-15');
      expect(input.venue, isNull);
      expect(input.playersPerSide, isNull);
    });

    test('CreateMatchInput holds optional fields', () {
      const input = CreateMatchInput(
        homeTeamId: 'team-1',
        awayTeamId: 'team-2',
        format: MatchFormat.odi,
        totalOvers: 50,
        ballTypeId: 2,
        matchDate: '2026-01-15',
        venue: 'Wankhede',
        playersPerSide: 11,
        maxOversPerBowler: 10,
        wideRuns: 1,
        noBallRuns: 1,
        powerplayOvers: 10,
      );

      expect(input.venue, 'Wankhede');
      expect(input.playersPerSide, 11);
      expect(input.maxOversPerBowler, 10);
      expect(input.wideRuns, 1);
      expect(input.noBallRuns, 1);
      expect(input.powerplayOvers, 10);
    });

    test('RecordTossInput holds all toss fields', () {
      const input = RecordTossInput(
        winnerId: 'team-1',
        decision: TossDecision.bat,
        openingStrikerId: 'player-1',
        openingNonStrikerId: 'player-2',
        openingBowlerId: 'player-3',
      );

      expect(input.winnerId, 'team-1');
      expect(input.decision, TossDecision.bat);
      expect(input.openingStrikerId, 'player-1');
      expect(input.openingNonStrikerId, 'player-2');
      expect(input.openingBowlerId, 'player-3');
    });

    test('SetPlayingXIInput holds all playing XI fields', () {
      const input = SetPlayingXIInput(
        teamId: 'team-1',
        playerIds: ['p1', 'p2', 'p3'],
        captainId: 'p1',
        keeperId: 'p2',
      );

      expect(input.teamId, 'team-1');
      expect(input.playerIds, ['p1', 'p2', 'p3']);
      expect(input.captainId, 'p1');
      expect(input.keeperId, 'p2');
    });
  });
}
