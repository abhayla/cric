import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../notifiers/scoring_notifier.dart';

/// Bottom sheet for selecting the next bowler after an over completes.
///
/// Shows eligible bowlers (tappable) and ineligible bowlers (greyed out with reason).
/// Single tap selects immediately. Auto-selects if only 1 eligible bowler.
class SelectBowlerSheet extends StatefulWidget {
  const SelectBowlerSheet({
    super.key,
    required this.bowlerOptions,
    required this.overNumber,
    required this.onSelect,
  });

  final List<BowlerOption> bowlerOptions;
  final int overNumber;
  final ValueChanged<String> onSelect;

  @override
  State<SelectBowlerSheet> createState() => _SelectBowlerSheetState();
}

class _SelectBowlerSheetState extends State<SelectBowlerSheet> {
  bool _autoSelected = false;

  @override
  void initState() {
    super.initState();
    _checkAutoSelect();
  }

  void _checkAutoSelect() {
    final eligible =
        widget.bowlerOptions.where((o) => o.isEligible).toList();
    if (eligible.length == 1 && !_autoSelected) {
      _autoSelected = true;
      final bowler = eligible.first;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onSelect(bowler.playerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only 1 eligible bowler \u2014 ${bowler.displayName} selected',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final eligible =
        widget.bowlerOptions.where((o) => o.isEligible).toList();
    final ineligible =
        widget.bowlerOptions.where((o) => !o.isEligible).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Over ${widget.overNumber}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Over completed. Select the next bowler.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Bowler list
          Expanded(
            child: ListView(
              children: [
                // Eligible bowlers
                ...eligible.map((o) => _buildBowlerRow(theme, o)),

                // Ineligible section
                if (ineligible.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...ineligible.map((o) => _buildBowlerRow(theme, o)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(ThemeData theme, BowlerOption option) {
    final opacity = option.isEligible ? 1.0 : 0.4;
    final statsText = option.spell != null
        ? '${option.spell!.oversDisplay}-${option.spell!.maidens}-${option.spell!.runsConceded}-${option.spell!.wicketsTaken}'
        : '--';
    final economyText = option.spell != null && option.spell!.ballsBowled > 0
        ? 'Ec: ${option.spell!.economyRate.toStringAsFixed(1)}'
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: option.isEligible
              ? () => widget.onSelect(option.playerId)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Initials avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  child: Text(
                    option.initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + badge + reason
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${option.displayName}${option.badge != null ? ' ${option.badge}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!option.isEligible &&
                          option.ineligibleReason != null)
                        Text(
                          option.ineligibleReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),

                // Stats column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statsText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (economyText != null)
                      Text(
                        economyText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
