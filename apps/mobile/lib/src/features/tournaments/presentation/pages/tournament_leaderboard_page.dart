import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/tournament_repository.dart';
import '../../providers.dart';

class TournamentLeaderboardPage extends StatelessWidget {
  const TournamentLeaderboardPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Runs'),
              Tab(text: 'Wickets'),
              Tab(text: 'Batting Avg'),
              Tab(text: 'Economy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderboardTab(
              tournamentId: tournamentId,
              category: LeaderboardCategory.runs,
            ),
            _LeaderboardTab(
              tournamentId: tournamentId,
              category: LeaderboardCategory.wickets,
            ),
            _LeaderboardTab(
              tournamentId: tournamentId,
              category: LeaderboardCategory.battingAvg,
            ),
            _LeaderboardTab(
              tournamentId: tournamentId,
              category: LeaderboardCategory.economy,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab({
    required this.tournamentId,
    required this.category,
  });

  final String tournamentId;
  final LeaderboardCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(
      tournamentLeaderboardProvider(
        (tournamentId: tournamentId, category: category),
      ),
    );

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (result) {
        if (result.leaderboard.isEmpty) {
          return const _EmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: result.leaderboard.length,
          itemBuilder: (context, index) {
            return _LeaderboardCard(entry: result.leaderboard[index]);
          },
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _RankBadge(rank: entry.rank),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                entry.playerName[0],
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    entry.teamName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatValue(entry.value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${entry.matches} matches',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (rank) {
      1 => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      2 => (const Color(0xFFF5F5F5), const Color(0xFF616161)),
      3 => (const Color(0xFFFBE9E7), const Color(0xFFBF360C)),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No Data Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leaderboard data will appear once matches have been played.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
