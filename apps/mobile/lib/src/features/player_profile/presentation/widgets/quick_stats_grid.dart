import 'package:flutter/material.dart';

import '../../domain/entities/career_stats.dart';

/// Quick stats grid showing Matches, Runs, Wickets, Catches.
class QuickStatsGrid extends StatelessWidget {
  const QuickStatsGrid({super.key, required this.stats});

  final CareerStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              _StatItem(
                label: 'Matches',
                value: '${stats?.batting.matchesPlayed ?? 0}',
                theme: theme,
              ),
              _StatItem(
                label: 'Runs',
                value: '${stats?.batting.totalRuns ?? 0}',
                theme: theme,
              ),
              _StatItem(
                label: 'Wickets',
                value: '${stats?.bowling.wicketsTaken ?? 0}',
                theme: theme,
              ),
              _StatItem(
                label: 'Catches',
                value: '${stats?.fielding.catches ?? 0}',
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
