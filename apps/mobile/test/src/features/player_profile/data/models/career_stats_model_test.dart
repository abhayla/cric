import 'package:cricapp/src/features/player_profile/data/models/career_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareerStatsModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'format': 'T20',
        'matchesPlayed': 10,
        'inningsBatted': 8,
        'totalRuns': 300,
        'highestScore': 75,
        'battingAverage': '42.86',
        'battingStrikeRate': '150.00',
        'fifties': 3,
        'hundreds': 0,
        'fours': 30,
        'sixes': 10,
        'notOuts': 1,
        'inningsBowled': 6,
        'oversBowled': '24.0',
        'runsConceded': 180,
        'wicketsTaken': 8,
        'bowlingAverage': '22.50',
        'bowlingEconomy': '7.50',
        'bowlingStrikeRate': '18.00',
        'bestBowlingWickets': 3,
        'bestBowlingRuns': 20,
        'threeWicketHauls': 1,
        'fiveWicketHauls': 0,
        'catches': 5,
        'runOuts': 2,
        'stumpings': 0,
      };

      final model = CareerStatsModel.fromJson(json);
      expect(model.format, 'T20');
      expect(model.matchesPlayed, 10);
      expect(model.totalRuns, 300);
      expect(model.battingAverage, '42.86');
      expect(model.wicketsTaken, 8);
      expect(model.catches, 5);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {
        'format': 'ODI',
      };

      final model = CareerStatsModel.fromJson(json);
      expect(model.matchesPlayed, 0);
      expect(model.totalRuns, 0);
      expect(model.battingAverage, isNull);
      expect(model.catches, 0);
    });

    test('toEntity converts batting stats correctly', () {
      const model = CareerStatsModel(
        format: 'T20',
        matchesPlayed: 10,
        inningsBatted: 8,
        totalRuns: 300,
        highestScore: 75,
        battingAverage: '42.86',
        battingStrikeRate: '150.00',
        fifties: 3,
        hundreds: 0,
        fours: 30,
        sixes: 10,
        notOuts: 1,
      );

      final entity = model.toEntity();
      expect(entity.format, 'T20');
      expect(entity.batting.matchesPlayed, 10);
      expect(entity.batting.totalRuns, 300);
      expect(entity.batting.battingAverage, closeTo(42.86, 0.01));
      expect(entity.batting.battingStrikeRate, closeTo(150.0, 0.01));
      expect(entity.batting.fifties, 3);
    });

    test('toEntity converts bowling stats correctly', () {
      const model = CareerStatsModel(
        format: 'T20',
        inningsBowled: 6,
        oversBowled: '24.0',
        runsConceded: 180,
        wicketsTaken: 8,
        bowlingAverage: '22.50',
        bowlingEconomy: '7.50',
        bestBowlingWickets: 3,
        bestBowlingRuns: 20,
        threeWicketHauls: 1,
        fiveWicketHauls: 0,
      );

      final entity = model.toEntity();
      expect(entity.bowling.inningsBowled, 6);
      expect(entity.bowling.oversBowled, '24.0');
      expect(entity.bowling.bowlingAverage, closeTo(22.5, 0.01));
      expect(entity.bowling.bestBowlingWickets, 3);
    });

    test('toEntity converts fielding stats correctly', () {
      const model = CareerStatsModel(
        format: 'all',
        catches: 5,
        runOuts: 2,
        stumpings: 1,
      );

      final entity = model.toEntity();
      expect(entity.fielding.catches, 5);
      expect(entity.fielding.runOuts, 2);
      expect(entity.fielding.stumpings, 1);
    });

    test('toEntity handles null decimal strings', () {
      const model = CareerStatsModel(format: 'T20');

      final entity = model.toEntity();
      expect(entity.batting.battingAverage, isNull);
      expect(entity.batting.battingStrikeRate, isNull);
      expect(entity.bowling.bowlingAverage, isNull);
      expect(entity.bowling.bowlingEconomy, isNull);
      expect(entity.bowling.oversBowled, '0.0');
    });
  });
}
