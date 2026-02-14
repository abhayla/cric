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
    String? result,
  }) = _MatchListItemModel;

  factory MatchListItemModel.fromJson(Map<String, dynamic> json) =>
      _$MatchListItemModelFromJson(json);
}

extension MatchListItemModelX on MatchListItemModel {
  MatchListItem toEntity() => MatchListItem(
        id: id,
        homeTeamName: homeTeam.name,
        awayTeamName: awayTeam.name,
        format: format,
        totalOvers: totalOvers,
        status: status,
        matchDate: matchDate,
        venue: venue,
        currentInnings: currentInnings != null
            ? InningsSnapshot(
                battingTeamId: currentInnings!.battingTeamId,
                totalRuns: currentInnings!.totalRuns,
                totalWickets: currentInnings!.totalWickets,
                overs: currentInnings!.overs,
              )
            : null,
        result: result,
      );
}
