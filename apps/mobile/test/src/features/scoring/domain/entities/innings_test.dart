import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/innings.dart';

void main() {
  group('Innings', () {
    Innings createInnings({
      String id = 'inn-1',
      String matchId = 'match-1',
      int inningsNumber = 1,
      String battingTeamId = 'team-a',
      String bowlingTeamId = 'team-b',
      int totalRuns = 0,
      int totalWickets = 0,
      int totalBalls = 0,
      int totalExtras = 0,
      int totalWides = 0,
      int totalNoBalls = 0,
      int totalByes = 0,
      int totalLegByes = 0,
      int penaltyRuns = 0,
      bool isCompleted = false,
      InningsCompletionReason? completionReason,
      int? target,
      bool isSuperOver = false,
      int? superOverNumber,
      String? battingTeamName,
      String? bowlingTeamName,
    }) {
      return Innings(
        id: id,
        matchId: matchId,
        inningsNumber: inningsNumber,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        totalBalls: totalBalls,
        totalExtras: totalExtras,
        totalWides: totalWides,
        totalNoBalls: totalNoBalls,
        totalByes: totalByes,
        totalLegByes: totalLegByes,
        penaltyRuns: penaltyRuns,
        isCompleted: isCompleted,
        completionReason: completionReason,
        target: target,
        isSuperOver: isSuperOver,
        superOverNumber: superOverNumber,
        battingTeamName: battingTeamName,
        bowlingTeamName: bowlingTeamName,
      );
    }

    test('constructs with defaults', () {
      final inn = createInnings();
      expect(inn.id, 'inn-1');
      expect(inn.matchId, 'match-1');
      expect(inn.inningsNumber, 1);
      expect(inn.battingTeamId, 'team-a');
      expect(inn.bowlingTeamId, 'team-b');
      expect(inn.totalRuns, 0);
      expect(inn.totalWickets, 0);
      expect(inn.totalBalls, 0);
      expect(inn.totalExtras, 0);
      expect(inn.totalWides, 0);
      expect(inn.totalNoBalls, 0);
      expect(inn.totalByes, 0);
      expect(inn.totalLegByes, 0);
      expect(inn.penaltyRuns, 0);
      expect(inn.isCompleted, false);
      expect(inn.completionReason, isNull);
      expect(inn.target, isNull);
      expect(inn.isSuperOver, false);
      expect(inn.superOverNumber, isNull);
      expect(inn.battingTeamName, isNull);
      expect(inn.bowlingTeamName, isNull);
    });

    test('constructs with all fields', () {
      final inn = createInnings(
        totalRuns: 185,
        totalWickets: 6,
        totalBalls: 120,
        totalExtras: 15,
        totalWides: 5,
        totalNoBalls: 3,
        totalByes: 4,
        totalLegByes: 3,
        penaltyRuns: 5,
        isCompleted: true,
        completionReason: InningsCompletionReason.oversExhausted,
        target: null,
        battingTeamName: 'Mumbai',
        bowlingTeamName: 'Delhi',
      );
      expect(inn.totalRuns, 185);
      expect(inn.totalWickets, 6);
      expect(inn.totalBalls, 120);
      expect(inn.totalExtras, 15);
      expect(inn.isCompleted, true);
      expect(inn.completionReason, InningsCompletionReason.oversExhausted);
      expect(inn.battingTeamName, 'Mumbai');
      expect(inn.bowlingTeamName, 'Delhi');
    });

    // ── oversDisplay ──

    test('oversDisplay is "0.0" at start', () {
      expect(createInnings().oversDisplay, '0.0');
    });

    test('oversDisplay shows partial overs', () {
      expect(createInnings(totalBalls: 1).oversDisplay, '0.1');
      expect(createInnings(totalBalls: 3).oversDisplay, '0.3');
      expect(createInnings(totalBalls: 5).oversDisplay, '0.5');
    });

    test('oversDisplay shows completed overs', () {
      expect(createInnings(totalBalls: 6).oversDisplay, '1.0');
      expect(createInnings(totalBalls: 12).oversDisplay, '2.0');
      expect(createInnings(totalBalls: 120).oversDisplay, '20.0');
    });

    test('oversDisplay shows mixed overs.balls', () {
      expect(createInnings(totalBalls: 7).oversDisplay, '1.1');
      expect(createInnings(totalBalls: 13).oversDisplay, '2.1');
      expect(createInnings(totalBalls: 99).oversDisplay, '16.3');
    });

    // ── runRate ──

    test('runRate is 0 when no balls bowled', () {
      expect(createInnings().runRate, 0);
    });

    test('runRate is calculated correctly', () {
      // 60 runs from 30 balls = 12.0 runs per over
      final inn = createInnings(totalRuns: 60, totalBalls: 30);
      expect(inn.runRate, 12.0);
    });

    test('runRate for standard T20 score', () {
      // 180 from 120 balls = 9.0 RPO
      final inn = createInnings(totalRuns: 180, totalBalls: 120);
      expect(inn.runRate, 9.0);
    });

    test('runRate for partial over', () {
      // 10 runs from 3 balls = 20.0 RPO
      final inn = createInnings(totalRuns: 10, totalBalls: 3);
      expect(inn.runRate, 20.0);
    });

    // ── runsNeeded ──

    test('runsNeeded is null when no target', () {
      expect(createInnings().runsNeeded, isNull);
    });

    test('runsNeeded calculates correctly', () {
      final inn = createInnings(
        inningsNumber: 2,
        totalRuns: 50,
        target: 180,
      );
      expect(inn.runsNeeded, 130);
    });

    test('runsNeeded is 0 when target reached', () {
      final inn = createInnings(
        inningsNumber: 2,
        totalRuns: 180,
        target: 180,
      );
      expect(inn.runsNeeded, 0);
    });

    test('runsNeeded is 0 when target exceeded', () {
      final inn = createInnings(
        inningsNumber: 2,
        totalRuns: 185,
        target: 180,
      );
      expect(inn.runsNeeded, 0);
    });

    test('runsNeeded is 1 when 1 run short of target', () {
      final inn = createInnings(
        inningsNumber: 2,
        totalRuns: 179,
        target: 180,
      );
      expect(inn.runsNeeded, 1);
    });

    // ── isFirstInnings / isSecondInnings ──

    test('isFirstInnings is true for innings number 1', () {
      expect(createInnings(inningsNumber: 1).isFirstInnings, true);
      expect(createInnings(inningsNumber: 1).isSecondInnings, false);
    });

    test('isSecondInnings is true for innings number 2', () {
      expect(createInnings(inningsNumber: 2).isSecondInnings, true);
      expect(createInnings(inningsNumber: 2).isFirstInnings, false);
    });

    test('super over innings are neither first nor second', () {
      final soInnings = createInnings(
        inningsNumber: 3,
        isSuperOver: true,
        superOverNumber: 1,
      );
      expect(soInnings.isFirstInnings, false);
      expect(soInnings.isSecondInnings, false);
      expect(soInnings.isSuperOver, true);
      expect(soInnings.superOverNumber, 1);
    });

    // ── completion states ──

    test('allOut completion', () {
      final inn = createInnings(
        totalWickets: 10,
        isCompleted: true,
        completionReason: InningsCompletionReason.allOut,
      );
      expect(inn.isCompleted, true);
      expect(inn.completionReason, InningsCompletionReason.allOut);
    });

    test('target chased completion', () {
      final inn = createInnings(
        inningsNumber: 2,
        totalRuns: 181,
        target: 180,
        isCompleted: true,
        completionReason: InningsCompletionReason.targetChased,
      );
      expect(inn.isCompleted, true);
      expect(inn.completionReason, InningsCompletionReason.targetChased);
    });

    test('declared completion', () {
      final inn = createInnings(
        isCompleted: true,
        completionReason: InningsCompletionReason.declared,
      );
      expect(inn.isCompleted, true);
      expect(inn.completionReason, InningsCompletionReason.declared);
    });

    // ── extras breakdown ──

    test('extras breakdown tracks all categories', () {
      final inn = createInnings(
        totalExtras: 20,
        totalWides: 8,
        totalNoBalls: 5,
        totalByes: 4,
        totalLegByes: 3,
      );
      expect(inn.totalExtras, 20);
      expect(inn.totalWides, 8);
      expect(inn.totalNoBalls, 5);
      expect(inn.totalByes, 4);
      expect(inn.totalLegByes, 3);
    });

    test('penalty runs tracked separately', () {
      final inn = createInnings(penaltyRuns: 5);
      expect(inn.penaltyRuns, 5);
    });
  });
}
