import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/tournament.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
abstract class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    required String id,
    required String name,
    required String format,
    @JsonKey(name: 'oversPerMatch') required int oversPerMatch,
    @JsonKey(name: 'ballTypeId') @Default(1) int ballTypeId,
    required String status,
    @JsonKey(name: 'pointsWin') @Default(2) int pointsWin,
    @JsonKey(name: 'pointsTie') @Default(1) int pointsTie,
    @JsonKey(name: 'pointsNoResult') @Default(1) int pointsNoResult,
    @JsonKey(name: 'pointsLoss') @Default(0) int pointsLoss,
    @JsonKey(name: 'numGroups') @Default(1) int numGroups,
    @JsonKey(name: 'qualifyPerGroup') @Default(2) int qualifyPerGroup,
    @JsonKey(name: 'hasThirdPlaceMatch') @Default(false) bool hasThirdPlaceMatch,
    @JsonKey(name: 'playersPerSide') @Default(11) int playersPerSide,
    @JsonKey(name: 'wideRuns') @Default(1) int wideRuns,
    @JsonKey(name: 'noBallRuns') @Default(1) int noBallRuns,
    @JsonKey(name: 'createdBy') required String createdBy,
    @JsonKey(name: 'createdAt') String? createdAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
    @JsonKey(name: 'maxOversPerBowler') int? maxOversPerBowler,
    @JsonKey(name: 'powerplayOvers') int? powerplayOvers,
    @JsonKey(name: 'startDate') String? startDate,
    @JsonKey(name: 'endDate') String? endDate,
    @JsonKey(name: 'teamCount') int? teamCount,
    List<TournamentTeamModel>? teams,
    List<TournamentGroupModel>? groups,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}

extension TournamentModelX on TournamentModel {
  Tournament toEntity() => Tournament(
        id: id,
        name: name,
        format: TournamentFormat.fromApiValue(format),
        oversPerMatch: oversPerMatch,
        ballTypeId: ballTypeId,
        status: TournamentStatus.fromApiValue(status),
        pointsWin: pointsWin,
        pointsTie: pointsTie,
        pointsNoResult: pointsNoResult,
        pointsLoss: pointsLoss,
        numGroups: numGroups,
        qualifyPerGroup: qualifyPerGroup,
        hasThirdPlaceMatch: hasThirdPlaceMatch,
        playersPerSide: playersPerSide,
        wideRuns: wideRuns,
        noBallRuns: noBallRuns,
        createdBy: createdBy,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
        maxOversPerBowler: maxOversPerBowler,
        powerplayOvers: powerplayOvers,
        startDate: startDate,
        endDate: endDate,
        teamCount: teamCount,
        teams: teams?.map((t) => t.toEntity()).toList(),
        groups: groups?.map((g) => g.toEntity()).toList(),
      );
}

@freezed
abstract class TournamentTeamModel with _$TournamentTeamModel {
  const factory TournamentTeamModel({
    required String id,
    @JsonKey(name: 'tournamentId') required String tournamentId,
    @JsonKey(name: 'teamId') required String teamId,
    @JsonKey(name: 'joinedAt') String? joinedAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
    @JsonKey(name: 'groupName') String? groupName,
    @JsonKey(name: 'seedNumber') int? seedNumber,
    @JsonKey(name: 'teamName') String? teamName,
  }) = _TournamentTeamModel;

  factory TournamentTeamModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentTeamModelFromJson(json);
}

extension TournamentTeamModelX on TournamentTeamModel {
  TournamentTeam toEntity() => TournamentTeam(
        id: id,
        tournamentId: tournamentId,
        teamId: teamId,
        joinedAt:
            joinedAt != null ? DateTime.parse(joinedAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
        groupName: groupName,
        seedNumber: seedNumber,
        teamName: teamName,
      );
}

@freezed
abstract class TournamentGroupModel with _$TournamentGroupModel {
  const factory TournamentGroupModel({
    required String name,
    @JsonKey(name: 'teamCount') int? teamCount,
  }) = _TournamentGroupModel;

  factory TournamentGroupModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentGroupModelFromJson(json);
}

extension TournamentGroupModelX on TournamentGroupModel {
  TournamentGroup toEntity() => TournamentGroup(
        name: name,
        teamCount: teamCount,
      );
}
