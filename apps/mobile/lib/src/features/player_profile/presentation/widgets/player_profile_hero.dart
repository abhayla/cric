import 'package:flutter/material.dart';

import '../../domain/entities/player_profile.dart';

/// Profile hero section with avatar, name, role, and primary team.
class PlayerProfileHero extends StatelessWidget {
  const PlayerProfileHero({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary, colorScheme.surface],
          stops: const [0.6, 0.6],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            foregroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            onForegroundImageError:
                profile.avatarUrl != null ? (_, e) {} : null,
            child: Text(
              profile.initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            profile.displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Role & style
          if (profile.playerRole != null) ...[
            const SizedBox(height: 4),
            Text(
              _buildSubtitle(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (profile.playerRole != null) {
      parts.add(profile.playerRole!.label);
    }
    final style = profile.styleDescription;
    if (style.isNotEmpty) {
      parts.add(style);
    }
    return parts.join(' \u2022 ');
  }
}
