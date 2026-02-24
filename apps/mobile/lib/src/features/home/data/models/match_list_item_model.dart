import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_list_item.dart';

part 'match_list_item_model.freezed.dart';
part 'match_list_item_model.g.dart';

@freezed
abstract class TeamRefModel with _$TeamRefModel {
  const factory TeamRefModel({
    required String id,
    required String name,
  }) = _TeamRefModel;

  factory TeamRefModel.fromJson(Map<String, dynamic> json) =>
      _$TeamRefModelFromJson(json);
}

@freezed
abstract class InningsSnapshotModel with _$InningsSnapshotModel {
  const factory InningsSnapshotModel({
    required String battingTeamId,
    required int totalRuns,
    required int totalWickets,
    required String overs,
  }) = _InningsSnapshotModel;

  factory InningsSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$InningsSnapshotModelFromJson(json);
}

@freezed
abstract class MatchListItemModel with _$MatchListItemModel {
  const factory MatchListItemModel({
    required String id,
    required TeamRefModel homeTeam,
    required TeamRefModel awayTeam,
    required String format,
    required int totalOvers,
    required String status,
    required String matchDate,
    String? venue,
    InningsSnapshotModel? currentInnings,
    InningsSnapshotModel? firstInnings,
    InningsSnapshotModel? secondInnings,
    String? result,
  }) = _MatchListItemModel;

  factory MatchListItemModel.fromJson(Map<String, dynamic> json) =>
      _$MatchListItemModelFromJson(json);
}

InningsSnapshot? _toInningsSnapshot(InningsSnapshotModel? model) {
  if (model == null) return null;
  return InningsSnapshot(
    battingTeamId: model.battingTeamId,
    totalRuns: model.totalRuns,
    totalWickets: model.totalWickets,
    overs: model.overs,
  );
}

extension MatchListItemModelX on MatchListItemModel {
  MatchListItem toEntity() => MatchListItem(
        id: id,
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        homeTeamName: homeTeam.name,
        awayTeamName: awayTeam.name,
        format: format,
        totalOvers: totalOvers,
        status: status,
        matchDate: matchDate,
        venue: venue,
        currentInnings: _toInningsSnapshot(currentInnings),
        firstInnings: _toInningsSnapshot(firstInnings),
        secondInnings: _toInningsSnapshot(secondInnings),
        result: result,
      );
}
