import 'package:flutter/material.dart';

import '../../domain/entities/mvp_data.dart';

/// MVP rankings widget showing players sorted by MVP points.
///
/// Top 3 players get gold/silver/bronze medal badges.
class MvpRankingWidget extends StatelessWidget {
  const MvpRankingWidget({super.key, required this.data});

  final MatchMvpData data;

  @override
  Widget build(BuildContext context) {
    if (data.rankings.isEmpty) {
      return const Center(child: Text('No MVP data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: data.rankings.length,
      itemBuilder: (context, index) {
        final player = data.rankings[index];
        final rank = index + 1;
        return _MvpPlayerCard(player: player, rank: rank);
      },
    );
  }
}

class _MvpPlayerCard extends StatelessWidget {
  const _MvpPlayerCard({required this.player, required this.rank});

  final MvpPlayerScore player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank badge
            _buildRankBadge(theme),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                _initials(player.displayName),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + team + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (player.teamName.isNotEmpty)
                    Text(
                      player.teamName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    player.performanceSummary,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  player.totalPoints.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'pts',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(ThemeData theme) {
    final badgeColor = switch (rank) {
      1 => const Color(0xFFE65100), // Gold
      2 => const Color(0xFF616161), // Silver
      3 => const Color(0xFFBF360C), // Bronze
      _ => null,
    };

    if (badgeColor != null) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: Text(
          '$rank',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }
}
