import 'package:flutter/material.dart';

class TeamStatsRow extends StatelessWidget {
  const TeamStatsRow({
    super.key,
    this.matches = 0,
    this.wins = 0,
    this.losses = 0,
    this.tied = 0,
  });

  final int matches;
  final int wins;
  final int losses;
  final int tied;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            _StatItem(value: '$matches', label: 'Matches'),
            _StatItem(value: '$wins', label: 'Wins'),
            _StatItem(value: '$losses', label: 'Losses'),
            _StatItem(value: '$tied', label: 'Tied'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
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
