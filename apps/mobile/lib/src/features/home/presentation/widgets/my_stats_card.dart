import 'package:flutter/material.dart';

import 'package:cricapp/src/features/player_profile/domain/entities/career_stats.dart';

class MyStatsCard extends StatelessWidget {
  const MyStatsCard({super.key, required this.stats});

  final CareerStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              value: stats.batting.matchesPlayed.toString(),
              label: 'Matches',
            ),
            _StatColumn(
              value: stats.batting.totalRuns.toString(),
              label: 'Runs',
            ),
            _StatColumn(
              value: stats.bowling.wicketsTaken.toString(),
              label: 'Wickets',
            ),
            _StatColumn(value: stats.batting.averageDisplay, label: 'Avg'),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
    );
  }
}
