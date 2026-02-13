import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bowler_spell.dart';

/// Displays the current bowler's live spell stats in a compact card.
class BowlerCard extends StatelessWidget {
  const BowlerCard({
    super.key,
    required this.bowler,
  });

  final BowlerSpell bowler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.wicket,
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
              bowler.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Overs
          SizedBox(
            width: 36,
            child: Text(
              bowler.oversDisplay,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Maidens
          SizedBox(
            width: 28,
            child: Text(
              '${bowler.maidens}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Runs
          SizedBox(
            width: 36,
            child: Text(
              '${bowler.runsConceded}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Wickets
          SizedBox(
            width: 28,
            child: Text(
              '${bowler.wicketsTaken}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Economy
          SizedBox(
            width: 48,
            child: Text(
              'Ec ${bowler.economyRate.toStringAsFixed(1)}',
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
