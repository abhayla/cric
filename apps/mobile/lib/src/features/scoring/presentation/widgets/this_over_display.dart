import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/delivery.dart';

/// Displays ball-by-ball indicators for the current over.
///
/// Each delivery is shown as a colored circle with notation text.
/// Includes a free hit badge when a free hit is pending.
class ThisOverDisplay extends StatelessWidget {
  const ThisOverDisplay({
    super.key,
    required this.deliveries,
    this.isFreeHitPending = false,
    this.overNumber = 1,
    this.isMagicOver = false,
    this.magicOverMultiplier = 2,
  });

  final List<Delivery> deliveries;
  final bool isFreeHitPending;
  final int overNumber;
  final bool isMagicOver;
  final int magicOverMultiplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'This Over',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isMagicOver) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'MAGIC ${magicOverMultiplier}x',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              if (isFreeHitPending) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.noBall,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'FREE HIT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: deliveries.map(_buildBallIndicator).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBallIndicator(Delivery delivery) {
    final color = _deliveryColor(delivery);
    final textColor = _deliveryTextColor(delivery);
    final isOutline = _isOutlineStyle(delivery);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOutline ? Colors.transparent : color,
        border: isOutline ? Border.all(color: color, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        delivery.notation,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _deliveryColor(Delivery delivery) {
    if (delivery.isWicket) return AppColors.wicket;
    if (delivery.isBoundaryFour) return AppColors.four;
    if (delivery.isBoundarySix) return AppColors.six;
    if (delivery.isWide) return AppColors.wide;
    if (delivery.isNoBall) return AppColors.noBall;
    if (delivery.isDotBall) return AppColors.dot;
    return Colors.grey.shade700;
  }

  Color _deliveryTextColor(Delivery delivery) {
    if (delivery.isWicket || delivery.isBoundaryFour || delivery.isBoundarySix) {
      return Colors.white;
    }
    if (delivery.isDotBall) return AppColors.dot;
    return Colors.grey.shade700;
  }

  bool _isOutlineStyle(Delivery delivery) {
    // Filled: wicket, boundary 4, boundary 6
    // Outline: everything else
    return !delivery.isWicket &&
        !delivery.isBoundaryFour &&
        !delivery.isBoundarySix;
  }
}
