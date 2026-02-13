import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/fixture.dart';

part 'fixture_model.freezed.dart';
part 'fixture_model.g.dart';

@freezed
abstract class FixtureModel with _$FixtureModel {
  const factory FixtureModel({
    required String id,
    @JsonKey(name: 'tournamentId') required String tournamentId,
    @JsonKey(name: 'roundNumber') required int roundNumber,
    @JsonKey(name: 'roundType') required String roundType,
    @JsonKey(name: 'fixtureOrder') required int fixtureOrder,
    @JsonKey(name: 'homeTeamId') required String homeTeamId,
    @JsonKey(name: 'awayTeamId') required String awayTeamId,
    @JsonKey(name: 'matchId') String? matchId,
    @JsonKey(name: 'groupName') String? groupName,
    @JsonKey(name: 'homeTeamName') String? homeTeamName,
    @JsonKey(name: 'awayTeamName') String? awayTeamName,
    @JsonKey(name: 'scheduledDate') String? scheduledDate,
    @JsonKey(name: 'scheduledTime') String? scheduledTime,
    @JsonKey(name: 'estimatedDurationMinutes') int? estimatedDurationMinutes,
    String? venue,
    FixtureResultModel? result,
  }) = _FixtureModel;

  factory FixtureModel.fromJson(Map<String, dynamic> json) =>
      _$FixtureModelFromJson(json);
}

extension FixtureModelX on FixtureModel {
  Fixture toEntity() => Fixture(
        id: id,
        tournamentId: tournamentId,
        roundNumber: roundNumber,
        roundType: RoundType.fromApiValue(roundType),
        fixtureOrder: fixtureOrder,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        matchId: matchId,
        groupName: groupName,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
        venue: venue,
        result: result?.toEntity(),
      );
}

@freezed
abstract class FixtureResultModel with _$FixtureResultModel {
  const factory FixtureResultModel({
    required String winner,
    required String summary,
  }) = _FixtureResultModel;

  factory FixtureResultModel.fromJson(Map<String, dynamic> json) =>
      _$FixtureResultModelFromJson(json);
}

extension FixtureResultModelX on FixtureResultModel {
  FixtureResult toEntity() => FixtureResult(
        winner: winner,
        summary: summary,
      );
}
