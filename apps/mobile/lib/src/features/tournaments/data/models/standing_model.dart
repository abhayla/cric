import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/standing.dart';

part 'standing_model.freezed.dart';
part 'standing_model.g.dart';

@freezed
abstract class StandingModel with _$StandingModel {
  const factory StandingModel({
    @JsonKey(name: 'tournamentId') required String tournamentId,
    @JsonKey(name: 'teamId') required String teamId,
    required int played,
    required int won,
    required int lost,
    required int tied,
    @JsonKey(name: 'noResult') required int noResult,
    required int points,
    required String nrr,
    @JsonKey(name: 'totalRunsScored') required int totalRunsScored,
    @JsonKey(name: 'totalOversFaced') required String totalOversFaced,
    @JsonKey(name: 'totalRunsConceded') required int totalRunsConceded,
    @JsonKey(name: 'totalOversBowled') required String totalOversBowled,
    @JsonKey(name: 'groupName') String? groupName,
    int? position,
    @JsonKey(name: 'teamName') String? teamName,
  }) = _StandingModel;

  factory StandingModel.fromJson(Map<String, dynamic> json) =>
      _$StandingModelFromJson(json);
}

extension StandingModelX on StandingModel {
  Standing toEntity() => Standing(
        tournamentId: tournamentId,
        teamId: teamId,
        played: played,
        won: won,
        lost: lost,
        tied: tied,
        noResult: noResult,
        points: points,
        nrr: double.tryParse(nrr) ?? 0.0,
        totalRunsScored: totalRunsScored,
        totalOversFaced: double.tryParse(totalOversFaced) ?? 0.0,
        totalRunsConceded: totalRunsConceded,
        totalOversBowled: double.tryParse(totalOversBowled) ?? 0.0,
        groupName: groupName,
        position: position,
        teamName: teamName,
      );
}
