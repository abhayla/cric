import 'package:flutter/material.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/team.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({super.key, required this.entry, this.onTap});

  final RosterEntry entry;
  final VoidCallback? onTap;

  Color _avatarBackground(ThemeData theme) => switch (entry.playerRole) {
        PlayerRole.batter => theme.colorScheme.primaryContainer,
        PlayerRole.allRounder => const Color(0xFFE8F5E9),
        PlayerRole.wkBatter => const Color(0xFFFFF3E0),
        PlayerRole.bowler => theme.colorScheme.errorContainer,
        null => theme.colorScheme.surfaceContainerHighest,
      };

  Color _avatarForeground(ThemeData theme) => switch (entry.playerRole) {
        PlayerRole.batter => theme.colorScheme.onPrimaryContainer,
        PlayerRole.allRounder => const Color(0xFF2E7D32),
        PlayerRole.wkBatter => const Color(0xFFE65100),
        PlayerRole.bowler => theme.colorScheme.onErrorContainer,
        null => theme.colorScheme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _avatarBackground(theme),
              child: Text(
                entry.initials,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _avatarForeground(theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.styleDescription.isNotEmpty)
                    Text(
                      entry.styleDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (entry.isCaptain)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'C',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
