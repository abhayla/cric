import 'package:flutter/material.dart';

import '../notifiers/scoring_notifier.dart';

/// Actions available from the match complete modal.
enum MatchCompleteAction { viewScorecard, backToHome, startSuperOver }

/// Modal displayed when a match is complete, showing side-by-side score
/// comparison and result text.
class MatchCompleteModal extends StatelessWidget {
  const MatchCompleteModal({
    super.key,
    required this.firstInnings,
    required this.secondTeamName,
    required this.secondTotalRuns,
    required this.secondTotalWickets,
    required this.secondOversDisplay,
    required this.matchResult,
    required this.onAction,
    this.showSuperOverButton = false,
  });

  final FirstInningsSummary firstInnings;
  final String secondTeamName;
  final int secondTotalRuns;
  final int secondTotalWickets;
  final String secondOversDisplay;
  final MatchResult matchResult;
  final ValueChanged<MatchCompleteAction> onAction;

  /// Whether to show the "Start Super Over" button (tied knockout match).
  final bool showSuperOverButton;

  /// Extract initials from team name (first letter of each word).
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
              ),
              child: Text(
                'Match Complete!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Score comparison
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: colorScheme.primary,
              child: Row(
                children: [
                  // 1st innings team
                  Expanded(
                    child: _buildTeamBlock(
                      context,
                      teamName: firstInnings.teamName,
                      score: firstInnings.scoreDisplay,
                      overs: firstInnings.oversDisplay,
                      avatarBackground: const Color(0xFFE3F2FD),
                      avatarForeground: const Color(0xFF1565C0),
                    ),
                  ),
                  // VS separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 2nd innings team
                  Expanded(
                    child: _buildTeamBlock(
                      context,
                      teamName: secondTeamName,
                      score: '$secondTotalRuns/$secondTotalWickets',
                      overs: secondOversDisplay,
                      avatarBackground: const Color(0xFFFCE4EC),
                      avatarForeground: const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),

            // Result text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                matchResult.resultDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSuperOverButton) ...[
                    FilledButton(
                      onPressed: () =>
                          onAction(MatchCompleteAction.startSuperOver),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.tertiary,
                      ),
                      child: const Text('Start Super Over'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    onPressed: () =>
                        onAction(MatchCompleteAction.viewScorecard),
                    child: const Text('View Scorecard'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => onAction(MatchCompleteAction.backToHome),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBlock(
    BuildContext context, {
    required String teamName,
    required String score,
    required String overs,
    required Color avatarBackground,
    required Color avatarForeground,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: avatarBackground,
          child: Text(
            _initials(teamName),
            style: TextStyle(
              color: avatarForeground,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '($overs ov)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
