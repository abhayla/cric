import 'package:flutter/material.dart';

import '../../domain/entities/batter_innings.dart';

/// Displays a batter's live innings stats in a compact card.
///
/// Striker has an asterisk and primary-colored left border;
/// non-striker has a grey left border.
class BatterCard extends StatelessWidget {
  const BatterCard({
    super.key,
    required this.batter,
    required this.isStriker,
  });

  final BatterInnings batter;
  final bool isStriker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isStriker
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Text(
              '${batter.displayName}${isStriker ? ' *' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isStriker ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Runs
          SizedBox(
            width: 36,
            child: Text(
              '${batter.runsScored}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Balls
          SizedBox(
            width: 36,
            child: Text(
              '(${batter.ballsFaced})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Fours
          SizedBox(
            width: 28,
            child: Text(
              '${batter.fours}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Sixes
          SizedBox(
            width: 28,
            child: Text(
              '${batter.sixes}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Strike rate
          SizedBox(
            width: 64,
            child: Text(
              'SR ${batter.strikeRate.toStringAsFixed(2)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
