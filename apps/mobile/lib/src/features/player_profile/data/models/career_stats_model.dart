import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/career_stats.dart';

part 'career_stats_model.freezed.dart';
part 'career_stats_model.g.dart';

@freezed
abstract class CareerStatsModel with _$CareerStatsModel {
  const factory CareerStatsModel({
    required String format,
    @Default(0) int matchesPlayed,
    @Default(0) int inningsBatted,
    @Default(0) int totalRuns,
    @Default(0) int highestScore,
    String? battingAverage,
    String? battingStrikeRate,
    @Default(0) int fifties,
    @Default(0) int hundreds,
    @Default(0) int fours,
    @Default(0) int sixes,
    @Default(0) int notOuts,
    @Default(0) int inningsBowled,
    String? oversBowled,
    @Default(0) int runsConceded,
    @Default(0) int wicketsTaken,
    String? bowlingAverage,
    String? bowlingEconomy,
    String? bowlingStrikeRate,
    @Default(0) int bestBowlingWickets,
    @Default(0) int bestBowlingRuns,
    @Default(0) int threeWicketHauls,
    @Default(0) int fiveWicketHauls,
    @Default(0) int catches,
    @Default(0) int runOuts,
    @Default(0) int stumpings,
    @Default(0) int ducks,
    @Default(0) int directHits,
  }) = _CareerStatsModel;

  factory CareerStatsModel.fromJson(Map<String, dynamic> json) =>
      _$CareerStatsModelFromJson(json);
}

extension CareerStatsModelX on CareerStatsModel {
  CareerStats toEntity() => CareerStats(
        format: format,
        batting: BattingCareerStats(
          matchesPlayed: matchesPlayed,
          inningsBatted: inningsBatted,
          totalRuns: totalRuns,
          highestScore: highestScore,
          notOuts: notOuts,
          fifties: fifties,
          hundreds: hundreds,
          fours: fours,
          sixes: sixes,
          ducks: ducks,
          battingAverage: _parseDouble(battingAverage),
          battingStrikeRate: _parseDouble(battingStrikeRate),
        ),
        bowling: BowlingCareerStats(
          inningsBowled: inningsBowled,
          oversBowled: oversBowled ?? '0.0',
          runsConceded: runsConceded,
          wicketsTaken: wicketsTaken,
          bestBowlingWickets: bestBowlingWickets,
          bestBowlingRuns: bestBowlingRuns,
          threeWicketHauls: threeWicketHauls,
          fiveWicketHauls: fiveWicketHauls,
          bowlingAverage: _parseDouble(bowlingAverage),
          bowlingEconomy: _parseDouble(bowlingEconomy),
          bowlingStrikeRate: _parseDouble(bowlingStrikeRate),
        ),
        fielding: FieldingCareerStats(
          catches: catches,
          runOuts: runOuts,
          stumpings: stumpings,
          directHits: directHits,
        ),
      );
}

double? _parseDouble(String? value) {
  if (value == null) return null;
  return double.tryParse(value);
}
