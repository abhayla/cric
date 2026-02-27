import 'package:flutter/material.dart';

import '../../domain/entities/career_stats.dart';

/// Batting career stats card with 11 stat rows.
class BattingStatsCard extends StatelessWidget {
  const BattingStatsCard({super.key, required this.stats});

  final BattingCareerStats? stats;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const _EmptyStats(message: 'No batting stats available');
    }
    final s = stats!;
    return _StatsCard(
      rows: [
        _StatRow('Matches', '${s.matchesPlayed}'),
        _StatRow('Innings', '${s.inningsBatted}'),
        _StatRow('Runs', '${s.totalRuns}', highlight: true),
        _StatRow('Highest Score', s.highestScoreDisplay, highlight: true),
        _StatRow('Average', s.averageDisplay),
        _StatRow('Strike Rate', s.strikeRateDisplay),
        _StatRow('50s / 100s', '${s.fifties} / ${s.hundreds}'),
        _StatRow('Fours', '${s.fours}'),
        _StatRow('Sixes', '${s.sixes}'),
        _StatRow('Not Outs', '${s.notOuts}'),
        _StatRow('Ducks', '${s.ducks}'),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.rows});

  final List<_StatRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                _StatRowWidget(
                  row: rows[i],
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
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

class _StatRowWidget extends StatelessWidget {
  const _StatRowWidget({required this.row, this.showDivider = true});

  final _StatRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
