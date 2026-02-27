import 'package:flutter/material.dart';

import '../../../../shared/widgets/pulsing_live_dot.dart';
import '../../domain/entities/match_list_item.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap});

  final MatchListItem match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: meta + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _metaLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _StatusBadge(status: match.status),
                ],
              ),
              const SizedBox(height: 8),

              // Home team row
              _TeamRow(
                teamName: match.homeTeamName,
                score: _homeScore,
                overs: _homeOvers,
              ),
              const SizedBox(height: 4),

              // Away team row
              _TeamRow(
                teamName: match.awayTeamName,
                score: _awayScore,
                overs: _awayOvers,
              ),

              // Result text for completed matches
              if (match.result != null) ...[
                const SizedBox(height: 8),
                Text(
                  match.result!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _metaLine {
    final parts = <String>[match.format];
    if (match.venue != null) parts.add(match.venue!);
    return parts.join(' \u2022 ');
  }

  InningsSnapshot? _inningsForTeam(String teamId) {
    if (match.firstInnings?.battingTeamId == teamId) return match.firstInnings;
    if (match.secondInnings?.battingTeamId == teamId) {
      return match.secondInnings;
    }
    // Fallback for live matches: use currentInnings if batting team matches
    if (match.currentInnings?.battingTeamId == teamId) {
      return match.currentInnings;
    }
    return null;
  }

  String get _homeScore {
    final innings = _inningsForTeam(match.homeTeamId);
    return innings?.scoreDisplay ?? '—';
  }

  String get _homeOvers {
    final innings = _inningsForTeam(match.homeTeamId);
    if (innings == null) return '';
    return '(${innings.overs})';
  }

  String get _awayScore {
    final innings = _inningsForTeam(match.awayTeamId);
    return innings?.scoreDisplay ?? '—';
  }

  String get _awayOvers {
    final innings = _inningsForTeam(match.awayTeamId);
    if (innings == null) return '';
    return '(${innings.overs})';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = status == 'live' || status == 'innings_break';
    final (label, color) = switch (status) {
      'live' || 'innings_break' => ('LIVE', Colors.green),
      'completed' => ('Completed', theme.colorScheme.outline),
      'setup' => ('Setup', theme.colorScheme.primary),
      'toss' => ('Toss', Colors.orange),
      'abandoned' => ('Abandoned', Colors.red),
      _ => (status, theme.colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            PulsingLiveDot(size: 6, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.teamName,
    required this.score,
    required this.overs,
  });

  final String teamName;
  final String score;
  final String overs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          score,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (overs.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            overs,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
