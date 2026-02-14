import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';
import '../../domain/entities/player_profile.dart';

part 'player_profile_model.freezed.dart';
part 'player_profile_model.g.dart';

@freezed
abstract class TeamAffiliationModel with _$TeamAffiliationModel {
  const factory TeamAffiliationModel({
    required String teamId,
    required String teamName,
    @Default('player') String role,
    String? teamLogoUrl,
    String? joinedAt,
  }) = _TeamAffiliationModel;

  factory TeamAffiliationModel.fromJson(Map<String, dynamic> json) =>
      _$TeamAffiliationModelFromJson(json);
}

extension TeamAffiliationModelX on TeamAffiliationModel {
  TeamAffiliation toEntity() => TeamAffiliation(
        teamId: teamId,
        teamName: teamName,
        role: role,
        teamLogoUrl: teamLogoUrl,
        joinedAt: joinedAt != null ? DateTime.parse(joinedAt!) : null,
      );
}

@freezed
abstract class PlayerProfileModel with _$PlayerProfileModel {
  const factory PlayerProfileModel({
    required String id,
    required String displayName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
    String? location,
    String? createdAt,
    @Default([]) List<TeamAffiliationModel> teams,
  }) = _PlayerProfileModel;

  factory PlayerProfileModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerProfileModelFromJson(json);
}

extension PlayerProfileModelX on PlayerProfileModel {
  PlayerProfile toEntity() => PlayerProfile(
        id: id,
        displayName: displayName,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        playerRole: PlayerRole.fromApiValue(playerRole),
        battingStyle: BattingStyle.fromApiValue(battingStyle),
        bowlingStyle: BowlingStyle.fromApiValue(bowlingStyle),
        location: location,
        createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
        teams: teams.map((t) => t.toEntity()).toList(),
      );
}
