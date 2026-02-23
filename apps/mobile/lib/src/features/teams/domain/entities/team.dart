import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';

/// Role of the current user within a team (for display purposes).
enum TeamMemberRole {
  owner('Owner'),
  captain('Captain'),
  member('Member');

  const TeamMemberRole(this.label);
  final String label;
}

/// Role of a player within a team roster.
enum RosterRole {
  captain('Captain', 'captain'),
  viceCaptain('Vice Captain', 'vice_captain'),
  player('Player', 'player');

  const RosterRole(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static RosterRole fromApiValue(String value) {
    return RosterRole.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => RosterRole.player,
    );
  }
}

/// Team entity.
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.isActive,
    required this.playerCount,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String createdBy;
  final bool isActive;
  final int playerCount;
  final TeamMemberRole role;
  final String? location;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// First letter of team name for avatar fallback.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Formatted subtitle: "11 players · Mumbai" or "5 players".
  String get subtitle {
    final playerText = playerCount == 1 ? '1 player' : '$playerCount players';
    if (location != null && location!.isNotEmpty) {
      return '$playerText · $location';
    }
    return playerText;
  }
}

/// A player entry in a team roster with joined profile data.
class RosterEntry {
  const RosterEntry({
    required this.id,
    required this.playerId,
    required this.displayName,
    required this.rosterRole,
    required this.isActive,
    required this.joinedAt,
    this.jerseyNumber,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.phone,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String playerId;
  final String displayName;
  final RosterRole rosterRole;
  final bool isActive;
  final DateTime joinedAt;
  final int? jerseyNumber;
  final PlayerRole? playerRole;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;

  /// Whether this player has an unverified (placeholder) account.
  bool get isUnverified => !isVerified;

  /// Initials from display name.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Style description based on player role.
  /// All-rounders and WK-batters show both batting + bowling style.
  /// Batters show batting style only. Bowlers show bowling style only.
  String get styleDescription {
    if (battingStyle == null && bowlingStyle == null) return '';

    switch (playerRole) {
      case PlayerRole.allRounder:
        final parts = <String>[];
        if (battingStyle != null) parts.add(battingStyle!.label);
        if (bowlingStyle != null && bowlingStyle != BowlingStyle.none) {
          parts.add(bowlingStyle!.label);
        }
        return parts.join(' · ');
      case PlayerRole.bowler:
        return bowlingStyle?.label ?? '';
      case PlayerRole.batter:
        return battingStyle?.label ?? '';
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

  /// Whether this player is captain.
  bool get isCaptain => rosterRole == RosterRole.captain;

  /// Whether this player is a wicketkeeper.
  bool get isKeeper => playerRole == PlayerRole.wkBatter;
}
