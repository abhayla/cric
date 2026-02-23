import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricapp/src/app/router.dart';
import 'package:cricapp/src/features/home/providers.dart';
import 'package:cricapp/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricapp/src/features/tournaments/providers.dart';
import 'package:cricapp/src/features/tournaments/presentation/widgets/tournament_card.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';

/// Live hub page showing live matches and ongoing tournaments.
class LivePage extends ConsumerWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveMatches = ref.watch(liveMatchesProvider);
    final tournamentsAsync = ref.watch(tournamentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveMatchesProvider);
          ref.read(tournamentsListProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Live Matches section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Live Matches',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...liveMatches.when(
                      data: (data) => data.matches.isNotEmpty
                          ? [_CountBadge(count: data.matches.length)]
                          : <Widget>[],
                      loading: () => <Widget>[],
                      error: (_, _) => <Widget>[],
                    ),
                  ],
                ),
              ),
            ),

            ...liveMatches.when(
              data: (data) {
                if (data.matches.isEmpty) {
                  return [
                    const SliverToBoxAdapter(
                      child: _EmptySectionCard(
                        icon: Icons.sports_cricket_outlined,
                        message: 'No live matches right now',
                      ),
                    ),
                  ];
                }
                return [
                  SliverList.builder(
                    itemCount: data.matches.length,
                    itemBuilder: (context, index) {
                      final match = data.matches[index];
                      return MatchCard(
                        match: match,
                        onTap: () {
                          context.push(AppRoutes.liveMatchPath(match.id));
                        },
                      );
                    },
                  ),
                ];
              },
              loading: () => [
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
              error: (_, _) => [
                const SliverToBoxAdapter(
                  child: _EmptySectionCard(
                    icon: Icons.error_outline,
                    message: 'Failed to load live matches',
                  ),
                ),
              ],
            ),

            // Ongoing Tournaments section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Ongoing Tournaments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...tournamentsAsync.when(
                      data: (data) {
                        final ongoing = data.tournaments
                            .where((t) => t.status == TournamentStatus.live)
                            .toList();
                        return ongoing.isNotEmpty
                            ? [_CountBadge(count: ongoing.length)]
                            : <Widget>[];
                      },
                      loading: () => <Widget>[],
                      error: (_, _) => <Widget>[],
                    ),
                  ],
                ),
              ),
            ),

            ...tournamentsAsync.when(
              data: (data) {
                final ongoing = data.tournaments
                    .where((t) => t.status == TournamentStatus.live)
                    .toList();
                if (ongoing.isEmpty) {
                  return [
                    const SliverToBoxAdapter(
                      child: _EmptySectionCard(
                        icon: Icons.emoji_events_outlined,
                        message: 'No ongoing tournaments',
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.separated(
                      itemCount: ongoing.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tournament = ongoing[index];
                        return TournamentCard(
                          tournament: tournament,
                          onTap: () {
                            context.push(
                              AppRoutes.tournamentDetailPath(tournament.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ];
              },
              loading: () => [
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
              error: (_, _) => [
                const SliverToBoxAdapter(
                  child: _EmptySectionCard(
                    icon: Icons.error_outline,
                    message: 'Failed to load tournaments',
                  ),
                ),
              ],
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
