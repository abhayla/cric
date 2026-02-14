import 'package:flutter/material.dart';

import '../../../../shared/data/sync/sync_service.dart';
import 'sync_status_indicator.dart';

/// Score header showing team name, innings, score, overs, and run rates.
///
/// Uses primary color background. Shows RRR/target/need only for 2nd innings.
/// Optionally displays a sync status indicator next to the team name.
class ScoreHeader extends StatelessWidget {
  const ScoreHeader({
    super.key,
    required this.battingTeamName,
    required this.inningsNumber,
    required this.totalRuns,
    required this.totalWickets,
    required this.oversDisplay,
    required this.runRate,
    this.requiredRunRate,
    this.target,
    this.runsNeeded,
    required this.onBack,
    this.syncStatus,
    this.pendingCount = 0,
  });

  final String battingTeamName;
  final int inningsNumber;
  final int totalRuns;
  final int totalWickets;
  final String oversDisplay;
  final double runRate;
  final double? requiredRunRate;
  final int? target;
  final int? runsNeeded;
  final VoidCallback onBack;
  final SyncStatus? syncStatus;
  final int pendingCount;

  String get _inningsLabel =>
      inningsNumber == 1 ? '1st Innings' : '2nd Innings';

  bool get _isSecondInnings => inningsNumber >= 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      color: primaryColor,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row 1: Back + Team/Innings + Score/Overs
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: onPrimary),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              battingTeamName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (syncStatus != null) ...[
                            const SizedBox(width: 8),
                            SyncStatusIndicator(
                              syncStatus: syncStatus!,
                              pendingCount: pendingCount,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _inningsLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalRuns/$totalWickets',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '($oversDisplay)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: CRR + (RRR + Target + Need for 2nd innings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'CRR: ${runRate.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  if (_isSecondInnings) ...[
                    const Spacer(),
                    if (requiredRunRate != null)
                      Text(
                        'RRR: ${requiredRunRate!.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    if (target != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Target: $target',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    if (runsNeeded != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Need: $runsNeeded',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
