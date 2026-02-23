import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/batter_innings.dart';
import '../../domain/entities/playing_xi_player.dart';

/// Bottom sheet for selecting a new batter after a wicket.
///
/// Shows yet-to-bat players and optionally retired hurt batters.
/// Single tap selects immediately (no confirm button).
/// Auto-selects if only 1 player is available.
class SelectBatterSheet extends StatefulWidget {
  const SelectBatterSheet({
    super.key,
    required this.yetToBatPlayers,
    required this.retiredHurtBatters,
    required this.onSelect,
    this.dismissedBatterName,
    this.dismissalDescription,
  });

  final List<PlayingXIPlayer> yetToBatPlayers;
  final List<BatterInnings> retiredHurtBatters;
  final ValueChanged<String> onSelect;
  final String? dismissedBatterName;
  final String? dismissalDescription;

  @override
  State<SelectBatterSheet> createState() => _SelectBatterSheetState();
}

class _SelectBatterSheetState extends State<SelectBatterSheet> {
  bool _autoSelected = false;

  @override
  void initState() {
    super.initState();
    _checkAutoSelect();
  }

  void _checkAutoSelect() {
    final totalAvailable =
        widget.yetToBatPlayers.length + widget.retiredHurtBatters.length;
    if (totalAvailable == 1 && !_autoSelected) {
      _autoSelected = true;
      final playerId = widget.yetToBatPlayers.isNotEmpty
          ? widget.yetToBatPlayers.first.playerId
          : widget.retiredHurtBatters.first.playerId;
      final name = widget.yetToBatPlayers.isNotEmpty
          ? widget.yetToBatPlayers.first.displayName
          : widget.retiredHurtBatters.first.displayName;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onSelect(playerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Last batter $name coming in'),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Select New Batter',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          // Subtitle with dismissed batter info
          if (widget.dismissedBatterName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Replacing: ${widget.dismissedBatterName} (${widget.dismissalDescription ?? ''})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.wicket,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Yet to bat players
          Expanded(
            child: ListView.builder(
              itemCount: widget.yetToBatPlayers.length +
                  (widget.retiredHurtBatters.isNotEmpty
                      ? widget.retiredHurtBatters.length + 2 // +2 for spacing + header
                      : 0),
              itemBuilder: (context, index) {
                // Yet-to-bat players
                if (index < widget.yetToBatPlayers.length) {
                  return _buildPlayerRow(theme, widget.yetToBatPlayers[index]);
                }

                // Retired hurt section
                final retiredIndex = index - widget.yetToBatPlayers.length;
                if (retiredIndex == 0) {
                  return const SizedBox(height: 12);
                }
                if (retiredIndex == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Retired Hurt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return _buildRetiredHurtRow(
                  theme,
                  widget.retiredHurtBatters[retiredIndex - 2],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(ThemeData theme, PlayingXIPlayer player) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onSelect(player.playerId),
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
                  player.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + badge + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.displayName}${player.badge != null ? ' ${player.badge}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.roleLabel != null)
                      Text(
                        '${player.roleLabel}${player.bowlingStyle != null ? ' • ${player.bowlingStyle}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Batting style chip
              if (player.battingStyleShort != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    player.battingStyleShort!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetiredHurtRow(ThemeData theme, BatterInnings batter) {
    final initials = batter.displayName.trim().split(RegExp(r'\s+')).length >= 2
        ? '${batter.displayName.trim().split(RegExp(r'\s+'))[0][0]}${batter.displayName.trim().split(RegExp(r'\s+'))[1][0]}'
            .toUpperCase()
        : batter.displayName.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onSelect(batter.playerId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  batter.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${batter.runsScored} (${batter.ballsFaced})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
