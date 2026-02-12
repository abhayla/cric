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
        playerRole: _parsePlayerRole(playerRole),
        battingStyle: _parseBattingStyle(battingStyle),
        bowlingStyle: _parseBowlingStyle(bowlingStyle),
        phone: phone,
        avatarUrl: avatarUrl,
      );
}

PlayerRole? _parsePlayerRole(String? value) {
  if (value == null) return null;
  return switch (value) {
    'batter' => PlayerRole.batter,
    'bowler' => PlayerRole.bowler,
    'all_rounder' => PlayerRole.allRounder,
    'wk_batter' => PlayerRole.wkBatter,
    _ => null,
  };
}

BattingStyle? _parseBattingStyle(String? value) {
  if (value == null) return null;
  return switch (value) {
    'right_hand' => BattingStyle.rightHand,
    'left_hand' => BattingStyle.leftHand,
    _ => null,
  };
}

BowlingStyle? _parseBowlingStyle(String? value) {
  if (value == null) return null;
  return switch (value) {
    'right_arm_fast' => BowlingStyle.rightArmFast,
    'right_arm_medium' => BowlingStyle.rightArmMedium,
    'right_arm_off_spin' => BowlingStyle.rightArmOffSpin,
    'right_arm_leg_spin' => BowlingStyle.rightArmLegSpin,
    'left_arm_fast' => BowlingStyle.leftArmFast,
    'left_arm_medium' => BowlingStyle.leftArmMedium,
    'left_arm_orthodox' => BowlingStyle.leftArmOrthodox,
    'left_arm_chinaman' => BowlingStyle.leftArmChinaman,
    'none' => BowlingStyle.none,
    _ => null,
  };
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
