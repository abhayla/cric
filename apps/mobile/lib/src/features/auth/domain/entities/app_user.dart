/// Cricket player profile entity.
class AppUser {
  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.displayName,
    this.phone,
    this.email,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.location,
  });

  final String id;
  final String firebaseUid;
  final String displayName;
  final String? phone;
  final String? email;
  final PlayerRole? playerRole;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final String? location;

  /// Returns the user's initials from display name.
  /// "Virat Kohli" → "VK", "Virat" → "V".
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

/// Player role in the team.
enum PlayerRole {
  batter('Batter', 'batter'),
  bowler('Bowler', 'bowler'),
  allRounder('All-Rounder', 'all_rounder'),
  wkBatter('WK-Batter', 'wk_batter');

  const PlayerRole(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static PlayerRole? fromApiValue(String? value) {
    if (value == null) return null;
    return PlayerRole.values.cast<PlayerRole?>().firstWhere(
          (r) => r!.apiValue == value,
          orElse: () => null,
        );
  }
}

/// Batting hand.
enum BattingStyle {
  rightHand('Right Hand', 'right_hand'),
  leftHand('Left Hand', 'left_hand');

  const BattingStyle(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static BattingStyle? fromApiValue(String? value) {
    if (value == null) return null;
    return BattingStyle.values.cast<BattingStyle?>().firstWhere(
          (r) => r!.apiValue == value,
          orElse: () => null,
        );
  }
}

/// Bowling style — 9 options matching DATABASE.md enums.
enum BowlingStyle {
  rightArmFast('Right Arm Fast', 'right_arm_fast'),
  rightArmMedium('Right Arm Medium', 'right_arm_medium'),
  rightArmOffSpin('Right Arm Off Spin', 'right_arm_off_spin'),
  rightArmLegSpin('Right Arm Leg Spin', 'right_arm_leg_spin'),
  leftArmFast('Left Arm Fast', 'left_arm_fast'),
  leftArmMedium('Left Arm Medium', 'left_arm_medium'),
  leftArmOrthodox('Left Arm Orthodox', 'left_arm_orthodox'),
  leftArmChinaman('Left Arm Chinaman', 'left_arm_chinaman'),
  none('None', 'none');

  const BowlingStyle(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static BowlingStyle? fromApiValue(String? value) {
    if (value == null) return null;
    return BowlingStyle.values.cast<BowlingStyle?>().firstWhere(
          (r) => r!.apiValue == value,
          orElse: () => null,
        );
  }
}
