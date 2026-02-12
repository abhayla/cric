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
  batter('Batter'),
  bowler('Bowler'),
  allRounder('All-Rounder'),
  wkBatter('WK-Batter');

  const PlayerRole(this.label);
  final String label;
}

/// Batting hand.
enum BattingStyle {
  rightHand('Right Hand'),
  leftHand('Left Hand');

  const BattingStyle(this.label);
  final String label;
}

/// Bowling style — 9 options matching DATABASE.md enums.
enum BowlingStyle {
  rightArmFast('Right Arm Fast'),
  rightArmMedium('Right Arm Medium'),
  rightArmOffSpin('Right Arm Off Spin'),
  rightArmLegSpin('Right Arm Leg Spin'),
  leftArmFast('Left Arm Fast'),
  leftArmMedium('Left Arm Medium'),
  leftArmOrthodox('Left Arm Orthodox'),
  leftArmChinaman('Left Arm Chinaman'),
  none('None');

  const BowlingStyle(this.label);
  final String label;
}
