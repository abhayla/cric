import 'package:cricscores/src/features/player_profile/domain/entities/career_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BattingCareerStats', () {
    test('dismissals returns innings minus not-outs', () {
      const stats = BattingCareerStats(
        matchesPlayed: 10,
        inningsBatted: 8,
        totalRuns: 300,
        highestScore: 75,
        notOuts: 2,
        fifties: 3,
        hundreds: 0,
        fours: 30,
        sixes: 10,
        battingAverage: 50.0,
        battingStrikeRate: 130.0,
      );
      expect(stats.dismissals, 6);
    });

    test('averageDisplay formats to 2 decimal places', () {
      const stats = BattingCareerStats(
        matchesPlayed: 5,
        inningsBatted: 5,
        totalRuns: 250,
        highestScore: 100,
        notOuts: 0,
        fifties: 1,
        hundreds: 1,
        fours: 20,
        sixes: 8,
        battingAverage: 50.0,
        battingStrikeRate: 125.55,
      );
      expect(stats.averageDisplay, '50.00');
    });

    test('averageDisplay returns dash when null', () {
      const stats = BattingCareerStats(
        matchesPlayed: 1,
        inningsBatted: 1,
        totalRuns: 0,
        highestScore: 0,
        notOuts: 1,
        fifties: 0,
        hundreds: 0,
        fours: 0,
        sixes: 0,
      );
      expect(stats.averageDisplay, '-');
    });

    test('strikeRateDisplay formats to 2 decimal places', () {
      const stats = BattingCareerStats(
        matchesPlayed: 5,
        inningsBatted: 5,
        totalRuns: 250,
        highestScore: 100,
        notOuts: 0,
        fifties: 1,
        hundreds: 1,
        fours: 20,
        sixes: 8,
        battingStrikeRate: 155.55,
      );
      expect(stats.strikeRateDisplay, '155.55');
    });

    test('strikeRateDisplay returns dash when null', () {
      const stats = BattingCareerStats(
        matchesPlayed: 0,
        inningsBatted: 0,
        totalRuns: 0,
        highestScore: 0,
        notOuts: 0,
        fifties: 0,
        hundreds: 0,
        fours: 0,
        sixes: 0,
      );
      expect(stats.strikeRateDisplay, '-');
    });
  });

  group('BowlingCareerStats', () {
    test('bestBowlingDisplay formats correctly', () {
      const stats = BowlingCareerStats(
        inningsBowled: 10,
        oversBowled: '40.0',
        runsConceded: 300,
        wicketsTaken: 15,
        bestBowlingWickets: 5,
        bestBowlingRuns: 25,
        threeWicketHauls: 2,
        fiveWicketHauls: 1,
        bowlingAverage: 20.0,
        bowlingEconomy: 7.5,
        bowlingStrikeRate: 16.0,
      );
      expect(stats.bestBowlingDisplay, '5/25');
    });

    test('bestBowlingDisplay returns dash when no wickets', () {
      const stats = BowlingCareerStats(
        inningsBowled: 0,
        oversBowled: '0.0',
        runsConceded: 0,
        wicketsTaken: 0,
        bestBowlingWickets: 0,
        bestBowlingRuns: 0,
        threeWicketHauls: 0,
        fiveWicketHauls: 0,
      );
      expect(stats.bestBowlingDisplay, '-');
    });

    test('averageDisplay formats to 2 decimal places', () {
      const stats = BowlingCareerStats(
        inningsBowled: 5,
        oversBowled: '20.0',
        runsConceded: 150,
        wicketsTaken: 8,
        bestBowlingWickets: 3,
        bestBowlingRuns: 20,
        threeWicketHauls: 1,
        fiveWicketHauls: 0,
        bowlingAverage: 18.75,
        bowlingEconomy: 7.5,
        bowlingStrikeRate: 15.0,
      );
      expect(stats.averageDisplay, '18.75');
    });

    test('economyDisplay formats to 2 decimal places', () {
      const stats = BowlingCareerStats(
        inningsBowled: 5,
        oversBowled: '20.0',
        runsConceded: 150,
        wicketsTaken: 8,
        bestBowlingWickets: 3,
        bestBowlingRuns: 20,
        threeWicketHauls: 1,
        fiveWicketHauls: 0,
        bowlingEconomy: 7.5,
      );
      expect(stats.economyDisplay, '7.50');
    });

    test('strikeRateDisplay returns dash when null', () {
      const stats = BowlingCareerStats(
        inningsBowled: 0,
        oversBowled: '0.0',
        runsConceded: 0,
        wicketsTaken: 0,
        bestBowlingWickets: 0,
        bestBowlingRuns: 0,
        threeWicketHauls: 0,
        fiveWicketHauls: 0,
      );
      expect(stats.strikeRateDisplay, '-');
    });
  });

  group('FieldingCareerStats', () {
    test('totalDismissals sums catches, run-outs, stumpings', () {
      const stats = FieldingCareerStats(
        catches: 5,
        runOuts: 3,
        stumpings: 2,
      );
      expect(stats.totalDismissals, 10);
    });

    test('totalDismissals is zero when all fields are zero', () {
      const stats = FieldingCareerStats(
        catches: 0,
        runOuts: 0,
        stumpings: 0,
      );
      expect(stats.totalDismissals, 0);
    });

    test('totalDismissals works with only catches', () {
      const stats = FieldingCareerStats(
        catches: 7,
        runOuts: 0,
        stumpings: 0,
      );
      expect(stats.totalDismissals, 7);
    });

    test('totalDismissals works with only stumpings', () {
      const stats = FieldingCareerStats(
        catches: 0,
        runOuts: 0,
        stumpings: 4,
      );
      expect(stats.totalDismissals, 4);
    });

    test('totalDismissals works with only run-outs', () {
      const stats = FieldingCareerStats(
        catches: 0,
        runOuts: 5,
        stumpings: 0,
      );
      expect(stats.totalDismissals, 5);
    });

    test('individual fields are accessible', () {
      const stats = FieldingCareerStats(
        catches: 12,
        runOuts: 3,
        stumpings: 8,
      );
      expect(stats.catches, 12);
      expect(stats.runOuts, 3);
      expect(stats.stumpings, 8);
    });
  });

  group('CareerStats', () {
    test('holds format and all stat categories', () {
      const stats = CareerStats(
        format: 'T20',
        batting: BattingCareerStats(
          matchesPlayed: 10,
          inningsBatted: 10,
          totalRuns: 500,
          highestScore: 100,
          notOuts: 2,
          fifties: 3,
          hundreds: 1,
          fours: 40,
          sixes: 15,
        ),
        bowling: BowlingCareerStats(
          inningsBowled: 8,
          oversBowled: '32.0',
          runsConceded: 200,
          wicketsTaken: 12,
          bestBowlingWickets: 4,
          bestBowlingRuns: 20,
          threeWicketHauls: 2,
          fiveWicketHauls: 0,
        ),
        fielding: FieldingCareerStats(
          catches: 6,
          runOuts: 2,
          stumpings: 0,
        ),
      );
      expect(stats.format, 'T20');
      expect(stats.batting.totalRuns, 500);
      expect(stats.bowling.wicketsTaken, 12);
      expect(stats.fielding.catches, 6);
    });
  });
}
