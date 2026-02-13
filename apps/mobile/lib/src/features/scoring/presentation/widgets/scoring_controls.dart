import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Scoring control panel with run buttons, extras, wicket, undo, and swap.
///
/// Run buttons: 0, 1, 2, 3, 4, 6, and "..." (overthrow picker).
/// Extras row: WD, NB, B, LB, W (wicket).
/// Action row: undo + swap strike.
class ScoringControls extends StatelessWidget {
  const ScoringControls({
    super.key,
    required this.onRunTap,
    required this.onWideTap,
    required this.onNoBallTap,
    required this.onByeTap,
    required this.onLegByeTap,
    required this.onWicketTap,
    required this.onUndoTap,
    required this.onSwapStrike,
    this.onOverthrowTap,
    this.canUndo = true,
    this.isInningsComplete = false,
  });

  final ValueChanged<int> onRunTap;
  final VoidCallback onWideTap;
  final VoidCallback onNoBallTap;
  final VoidCallback onByeTap;
  final VoidCallback onLegByeTap;
  final VoidCallback onWicketTap;
  final VoidCallback onUndoTap;
  final VoidCallback onSwapStrike;
  final VoidCallback? onOverthrowTap;
  final bool canUndo;
  final bool isInningsComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Run buttons row
            _buildRunButtons(theme),
            const SizedBox(height: 8),
            // Extras + wicket row
            _buildExtrasRow(theme),
            const SizedBox(height: 8),
            // Action bar: undo + swap
            _buildActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButtons(ThemeData theme) {
    const runs = [0, 1, 2, 3, 4, 6];

    return Row(
      children: [
        ...runs.map((r) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _RunButton(
                  label: '$r',
                  onTap: isInningsComplete ? null : () => onRunTap(r),
                  color: r == 4
                      ? AppColors.four
                      : r == 6
                          ? AppColors.six
                          : null,
                ),
              ),
            )),
        // Overthrow picker
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: _RunButton(
            label: '...',
            onTap: isInningsComplete ? null : onOverthrowTap,
          ),
        ),
      ],
    );
  }

  Widget _buildExtrasRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _ExtrasButton(
            label: 'WD',
            color: AppColors.wide,
            onTap: isInningsComplete ? null : onWideTap,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ExtrasButton(
            label: 'NB',
            color: AppColors.noBall,
            onTap: isInningsComplete ? null : onNoBallTap,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ExtrasButton(
            label: 'B',
            color: AppColors.bye,
            onTap: isInningsComplete ? null : onByeTap,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ExtrasButton(
            label: 'LB',
            color: AppColors.legBye,
            onTap: isInningsComplete ? null : onLegByeTap,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ExtrasButton(
            label: 'W',
            color: AppColors.wicket,
            onTap: isInningsComplete ? null : onWicketTap,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: canUndo && !isInningsComplete ? onUndoTap : null,
          tooltip: 'Undo',
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: isInningsComplete ? null : onSwapStrike,
          tooltip: 'Swap Strike',
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.label,
    this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color ?? theme.colorScheme.surfaceContainerHigh;
    final textColor = color != null ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtrasButton extends StatelessWidget {
  const _ExtrasButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
