import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';

/// A team the player is affiliated with.
class TeamAffiliation {
  const TeamAffiliation({
    required this.teamId,
    required this.teamName,
    required this.role,
    this.teamLogoUrl,
    this.joinedAt,
  });

  final String teamId;
  final String teamName;
  final String role;
  final String? teamLogoUrl;
  final DateTime? joinedAt;

  /// First letter of team name for avatar fallback.
  String get initial => teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';
}

/// Player profile entity with team affiliations.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.location,
    this.createdAt,
    this.teams = const [],
  });

  final String id;
  final String displayName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final PlayerRole? playerRole;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final String? location;
  final DateTime? createdAt;
  final List<TeamAffiliation> teams;

  /// Initials from display name for avatar fallback.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Style description based on player role.
  String get styleDescription {
    if (battingStyle == null && bowlingStyle == null) return '';

    switch (playerRole) {
      case PlayerRole.batter:
        return battingStyle?.label ?? '';
      case PlayerRole.bowler:
        return bowlingStyle?.label ?? '';
      case PlayerRole.allRounder:
      case PlayerRole.wkBatter:
        final parts = <String>[];
        if (battingStyle != null) parts.add(battingStyle!.label);
        if (bowlingStyle != null && bowlingStyle != BowlingStyle.none) {
          parts.add(bowlingStyle!.label);
        }
        return parts.join(' · ');
      case null:
        return battingStyle?.label ?? bowlingStyle?.label ?? '';
    }
  }
}
