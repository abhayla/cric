import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/team.dart';
import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';

part 'team_model.freezed.dart';
part 'team_model.g.dart';

@freezed
abstract class TeamModel with _$TeamModel {
  const factory TeamModel({
    required String id,
    required String name,
    @JsonKey(name: 'logoUrl') String? logoUrl,
    String? location,
    @JsonKey(name: 'createdBy') required String createdBy,
    @JsonKey(name: 'isActive') @Default(true) bool isActive,
    @JsonKey(name: 'playerCount') @Default(0) int playerCount,
    @Default('member') String role,
    @JsonKey(name: 'createdAt') String? createdAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
  }) = _TeamModel;

  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);
}

extension TeamModelX on TeamModel {
  Team toEntity() => Team(
        id: id,
        name: name,
        createdBy: createdBy,
        isActive: isActive,
        playerCount: playerCount,
        role: _parseTeamMemberRole(role),
        location: location,
        logoUrl: logoUrl,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      );
}

TeamMemberRole _parseTeamMemberRole(String role) {
  switch (role) {
    case 'owner':
      return TeamMemberRole.owner;
    case 'captain':
      return TeamMemberRole.captain;
    default:
      return TeamMemberRole.member;
  }
}

@freezed
abstract class RosterEntryModel with _$RosterEntryModel {
  const factory RosterEntryModel({
    required String id,
    @JsonKey(name: 'playerId') required String playerId,
    @JsonKey(name: 'displayName') required String displayName,
    @JsonKey(name: 'jerseyNumber') int? jerseyNumber,
    @Default('player') String role,
    @JsonKey(name: 'isActive') @Default(true) bool isActive,
    @JsonKey(name: 'joinedAt') String? joinedAt,
    @JsonKey(name: 'playerRole') String? playerRole,
    @JsonKey(name: 'battingStyle') String? battingStyle,
    @JsonKey(name: 'bowlingStyle') String? bowlingStyle,
    String? phone,
    @JsonKey(name: 'avatarUrl') String? avatarUrl,
    @JsonKey(name: 'isVerified') @Default(false) bool isVerified,
  }) = _RosterEntryModel;

  factory RosterEntryModel.fromJson(Map<String, dynamic> json) =>
      _$RosterEntryModelFromJson(json);
}

extension RosterEntryModelX on RosterEntryModel {
  RosterEntry toEntity() => RosterEntry(
        id: id,
        playerId: playerId,
        displayName: displayName,
        rosterRole: RosterRole.fromApiValue(role),
        isActive: isActive,
        joinedAt:
            joinedAt != null ? DateTime.parse(joinedAt!) : DateTime.now(),
        jerseyNumber: jerseyNumber,
        playerRole: PlayerRole.fromApiValue(playerRole),
        battingStyle: BattingStyle.fromApiValue(battingStyle),
        bowlingStyle: BowlingStyle.fromApiValue(bowlingStyle),
        phone: phone,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
      );
}

@freezed
abstract class PlayerSearchResultModel with _$PlayerSearchResultModel {
  const factory PlayerSearchResultModel({
    required String id,
    @JsonKey(name: 'displayName') required String displayName,
    String? phone,
    @JsonKey(name: 'battingStyle') String? battingStyle,
    @JsonKey(name: 'bowlingStyle') String? bowlingStyle,
    @JsonKey(name: 'playerRole') String? playerRole,
    String? location,
    @JsonKey(name: 'avatarUrl') String? avatarUrl,
  }) = _PlayerSearchResultModel;

  factory PlayerSearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerSearchResultModelFromJson(json);
}
