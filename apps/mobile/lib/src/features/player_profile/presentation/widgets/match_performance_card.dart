import 'package:flutter/material.dart';

import '../../domain/entities/match_performance.dart';

/// Match performance card showing teams, scores, result, and personal stats.
class MatchPerformanceCard extends StatelessWidget {
  const MatchPerformanceCard({
    super.key,
    required this.match,
    this.onTap,
  });

  final MatchPerformance match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match meta + badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildMeta(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _ResultBadge(result: match.playerResult),
                ],
              ),
              const SizedBox(height: 8),
              // Team rows
              for (final score in match.teamScores)
                _TeamRow(
                  teamName: score.teamName,
                  score: '${score.runs}/${score.wickets}',
                  overs: '(${score.overs})',
                  isPlayerTeam: score.teamId == match.playerTeamId,
                  theme: theme,
                ),
              if (match.teamScores.isEmpty) ...[
                _TeamRow(
                  teamName: match.homeTeam.name,
                  score: '-',
                  overs: '',
                  isPlayerTeam: match.playerTeamId == match.homeTeam.id,
                  theme: theme,
                ),
                _TeamRow(
                  teamName: match.awayTeam.name,
                  score: '-',
                  overs: '',
                  isPlayerTeam: match.playerTeamId == match.awayTeam.id,
                  theme: theme,
                ),
              ],
              // Result summary
              if (match.result != null) ...[
                const SizedBox(height: 6),
                Text(
                  match.result!.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _resultColor(colorScheme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              // Personal performance
              if (match.batting != null || match.bowling != null) ...[
                const Divider(height: 16),
                _PersonalPerformance(match: match, theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildMeta() {
    final parts = <String>[match.format, match.matchDate];
    if (match.venue != null) parts.add(match.venue!);
    return parts.join(' \u2022 ');
  }

  Color _resultColor(ColorScheme colorScheme) {
    return switch (match.playerResult) {
      'won' => Colors.green.shade700,
      'lost' => Colors.red.shade700,
      'tied' => Colors.orange.shade700,
      _ => colorScheme.onSurfaceVariant,
    };
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      'won' => ('Won', Colors.green),
      'lost' => ('Lost', Colors.red),
      'tied' => ('Tied', Colors.orange),
      'no_result' => ('N/R', Colors.grey),
      _ => ('', Colors.grey),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.teamName,
    required this.score,
    required this.overs,
    required this.isPlayerTeam,
    required this.theme,
  });

  final String teamName;
  final String score;
  final String overs;
  final bool isPlayerTeam;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    isPlayerTeam ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            score,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            child: Text(
              overs,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalPerformance extends StatelessWidget {
  const _PersonalPerformance({
    required this.match,
    required this.theme,
  });

  final MatchPerformance match;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (match.batting != null) ...[
          Icon(Icons.sports_cricket, size: 14,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            match.batting!.scoreDisplay,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (match.batting != null && match.bowling != null)
          const SizedBox(width: 16),
        if (match.bowling != null) ...[
          Icon(Icons.sports_baseball, size: 14,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            match.bowling!.figuresDisplay,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (match.fielding != null && match.fielding!.hasContributions) ...[
          const SizedBox(width: 16),
          Icon(Icons.sports_handball, size: 14,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            _fieldingDisplay(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _fieldingDisplay() {
    final f = match.fielding!;
    final parts = <String>[];
    if (f.catches > 0) parts.add('${f.catches} ct');
    if (f.runOuts > 0) parts.add('${f.runOuts} ro');
    if (f.stumpings > 0) parts.add('${f.stumpings} st');
    return parts.join(', ');
  }
}
