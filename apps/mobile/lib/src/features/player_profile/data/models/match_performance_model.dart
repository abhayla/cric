import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_performance.dart';

part 'match_performance_model.freezed.dart';
part 'match_performance_model.g.dart';

@freezed
abstract class MatchTeamInfoModel with _$MatchTeamInfoModel {
  const factory MatchTeamInfoModel({
    required String id,
    required String name,
    String? logoUrl,
  }) = _MatchTeamInfoModel;

  factory MatchTeamInfoModel.fromJson(Map<String, dynamic> json) =>
      _$MatchTeamInfoModelFromJson(json);
}

extension MatchTeamInfoModelX on MatchTeamInfoModel {
  MatchTeamInfo toEntity() => MatchTeamInfo(
        id: id,
        name: name,
        logoUrl: logoUrl,
      );
}

@freezed
abstract class TeamScoreModel with _$TeamScoreModel {
  const factory TeamScoreModel({
    required String teamId,
    required String teamName,
    @Default(0) int runs,
    @Default(0) int wickets,
    @Default('0.0') String overs,
  }) = _TeamScoreModel;

  factory TeamScoreModel.fromJson(Map<String, dynamic> json) =>
      _$TeamScoreModelFromJson(json);
}

extension TeamScoreModelX on TeamScoreModel {
  TeamScore toEntity() => TeamScore(
        teamId: teamId,
        teamName: teamName,
        runs: runs,
        wickets: wickets,
        overs: overs,
      );
}

@freezed
abstract class MatchResultModel with _$MatchResultModel {
  const factory MatchResultModel({
    String? winnerTeamId,
    required String resultType,
    int? margin,
    required String summary,
  }) = _MatchResultModel;

  factory MatchResultModel.fromJson(Map<String, dynamic> json) =>
      _$MatchResultModelFromJson(json);
}

extension MatchResultModelX on MatchResultModel {
  MatchResultSummary toEntity() => MatchResultSummary(
        winnerTeamId: winnerTeamId,
        resultType: resultType,
        margin: margin,
        summary: summary,
      );
}

@freezed
abstract class PersonalBattingModel with _$PersonalBattingModel {
  const factory PersonalBattingModel({
    @Default(0) int runsScored,
    @Default(0) int ballsFaced,
    @Default(0) int fours,
    @Default(0) int sixes,
    @Default(false) bool isNotOut,
    String? strikeRate,
  }) = _PersonalBattingModel;

  factory PersonalBattingModel.fromJson(Map<String, dynamic> json) =>
      _$PersonalBattingModelFromJson(json);
}

extension PersonalBattingModelX on PersonalBattingModel {
  PersonalBatting toEntity() => PersonalBatting(
        runsScored: runsScored,
        ballsFaced: ballsFaced,
        fours: fours,
        sixes: sixes,
        isNotOut: isNotOut,
        strikeRate: strikeRate != null ? double.tryParse(strikeRate!) : null,
      );
}

@freezed
abstract class PersonalBowlingModel with _$PersonalBowlingModel {
  const factory PersonalBowlingModel({
    @Default('0.0') String oversBowled,
    @Default(0) int runsConceded,
    @Default(0) int wicketsTaken,
    @Default(0) int maidens,
    String? economyRate,
  }) = _PersonalBowlingModel;

  factory PersonalBowlingModel.fromJson(Map<String, dynamic> json) =>
      _$PersonalBowlingModelFromJson(json);
}

extension PersonalBowlingModelX on PersonalBowlingModel {
  PersonalBowling toEntity() => PersonalBowling(
        oversBowled: oversBowled,
        runsConceded: runsConceded,
        wicketsTaken: wicketsTaken,
        maidens: maidens,
        economyRate:
            economyRate != null ? double.tryParse(economyRate!) : null,
      );
}

@freezed
abstract class PersonalFieldingModel with _$PersonalFieldingModel {
  const factory PersonalFieldingModel({
    @Default(0) int catches,
    @Default(0) int runOuts,
    @Default(0) int stumpings,
  }) = _PersonalFieldingModel;

  factory PersonalFieldingModel.fromJson(Map<String, dynamic> json) =>
      _$PersonalFieldingModelFromJson(json);
}

extension PersonalFieldingModelX on PersonalFieldingModel {
  PersonalFielding toEntity() => PersonalFielding(
        catches: catches,
        runOuts: runOuts,
        stumpings: stumpings,
      );
}

@freezed
abstract class MatchPerformanceModel with _$MatchPerformanceModel {
  const factory MatchPerformanceModel({
    required String matchId,
    required String format,
    required String matchDate,
    String? venue,
    required MatchTeamInfoModel homeTeam,
    required MatchTeamInfoModel awayTeam,
    @Default([]) List<TeamScoreModel> teamScores,
    MatchResultModel? result,
    @Default('no_result') String playerResult,
    required String playerTeamId,
    PersonalBattingModel? batting,
    PersonalBowlingModel? bowling,
    PersonalFieldingModel? fielding,
  }) = _MatchPerformanceModel;

  factory MatchPerformanceModel.fromJson(Map<String, dynamic> json) =>
      _$MatchPerformanceModelFromJson(json);
}

extension MatchPerformanceModelX on MatchPerformanceModel {
  MatchPerformance toEntity() => MatchPerformance(
        matchId: matchId,
        format: format,
        matchDate: matchDate,
        venue: venue,
        homeTeam: homeTeam.toEntity(),
        awayTeam: awayTeam.toEntity(),
        teamScores: teamScores.map((s) => s.toEntity()).toList(),
        result: result?.toEntity(),
        playerResult: playerResult,
        playerTeamId: playerTeamId,
        batting: batting?.toEntity(),
        bowling: bowling?.toEntity(),
        fielding: fielding?.toEntity(),
      );
}
