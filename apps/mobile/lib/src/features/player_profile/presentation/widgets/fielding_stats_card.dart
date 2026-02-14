import 'package:flutter/material.dart';

import '../../domain/entities/career_stats.dart';

/// Fielding career stats card with 4 stat rows.
class FieldingStatsCard extends StatelessWidget {
  const FieldingStatsCard({super.key, required this.stats});

  final FieldingCareerStats? stats;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return _emptyStats(context);
    }
    final s = stats!;
    final theme = Theme.of(context);

    final rows = [
      _StatRow('Catches', '${s.catches}', highlight: true),
      _StatRow('Stumpings', '${s.stumpings}'),
      _StatRow('Run Outs', '${s.runOuts}'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++)
                _buildRow(theme, rows[i], showDivider: i < rows.length - 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStats(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          'No fielding stats available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, _StatRow row,
      {bool showDivider = true}) {
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            row.value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: row.highlight ? FontWeight.bold : FontWeight.w600,
              color: row.highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow {
  const _StatRow(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
}
