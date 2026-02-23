import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricapp/src/features/scoring/domain/entities/scorecard_data.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  group('ScorecardData', () {
    ScorecardData createScorecardData({
      String matchId = 'match-1',
      int totalOvers = 20,
      int playersPerSide = 11,
      InningsData? firstInnings,
      InningsData? secondInnings,
      MatchResult? matchResult,
    }) {
      return ScorecardData(
        matchId: matchId,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        firstInnings: firstInnings ?? _defaultInningsData('Team A', 'team-a'),
        secondInnings: secondInnings ?? _defaultInningsData('Team B', 'team-b'),
        matchResult: matchResult ??
            const MatchResult(
              winnerTeamId: 'team-a',
              winnerTeamName: 'Team A',
              resultType: MatchResultType.runs,
              margin: 25,
              resultDescription: 'Team A won by 25 runs',
            ),
      );
    }

    test('stores match metadata', () {
      final data = createScorecardData(
        matchId: 'match-99',
        totalOvers: 50,
        playersPerSide: 11,
      );
      expect(data.matchId, 'match-99');
      expect(data.totalOvers, 50);
      expect(data.playersPerSide, 11);
    });

    test('holds both innings data', () {
      final first = _defaultInningsData('Team A', 'team-a', runs: 180);
      final second = _defaultInningsData('Team B', 'team-b', runs: 155);
      final data = createScorecardData(
        firstInnings: first,
        secondInnings: second,
      );
      expect(data.firstInnings.totalRuns, 180);
      expect(data.secondInnings.totalRuns, 155);
    });

    test('holds match result', () {
      const result = MatchResult(
        winnerTeamId: 'team-b',
        winnerTeamName: 'Team B',
        resultType: MatchResultType.wickets,
        margin: 4,
        resultDescription: 'Team B won by 4 wickets',
      );
      final data = createScorecardData(matchResult: result);
      expect(data.matchResult.resultDescription, 'Team B won by 4 wickets');
      expect(data.matchResult.resultType, MatchResultType.wickets);
    });

    test('holds tie result', () {
      const result = MatchResult(
        winnerTeamId: null,
        winnerTeamName: null,
        resultType: MatchResultType.tie,
        margin: null,
        resultDescription: 'Match Tied',
      );
      final data = createScorecardData(matchResult: result);
      expect(data.matchResult.resultType, MatchResultType.tie);
      expect(data.matchResult.winnerTeamId, isNull);
    });

    test('fromScoringState creates correct data for completed match', () {
      final firstInnings = _defaultInningsData('Team A', 'team-a', runs: 150);
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'innings-2',
        battingTeamId: 'team-b',
        bowlingTeamId: 'team-a',
        battingTeamName: 'Team B',
        bowlingTeamName: 'Team A',
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        totalRuns: 120,
        totalWickets: 10,
        totalBalls: 114,
        isInningsComplete: true,
        isMatchComplete: true,
        firstInnings: firstInnings,
        firstInningsSummary: const FirstInningsSummary(
          teamName: 'Team A',
          teamId: 'team-a',
          totalRuns: 150,
          totalWickets: 6,
          totalBalls: 120,
          oversDisplay: '20.0',
        ),
      );

      final data = ScorecardData.fromScoringState(state);
      expect(data.matchId, 'match-1');
      expect(data.firstInnings.teamName, 'Team A');
      expect(data.firstInnings.totalRuns, 150);
      expect(data.secondInnings.teamName, 'Team B');
      expect(data.secondInnings.totalRuns, 120);
      expect(data.matchResult.resultType, MatchResultType.runs);
    });
  });
}

InningsData _defaultInningsData(String teamName, String teamId, {int runs = 150}) {
  return InningsData(
    teamName: teamName,
    teamId: teamId,
    totalRuns: runs,
    totalWickets: 5,
    totalBalls: 120,
    totalWides: 3,
    totalNoBalls: 2,
    totalByes: 1,
    totalLegByes: 0,
    totalExtras: 6,
    batterStats: const {},
    bowlerStats: const {},
    fallOfWickets: const [],
    deliveryHistory: const [],
    battingTeamPlayers: const [],
    bowlingTeamPlayers: const [],
  );
}
