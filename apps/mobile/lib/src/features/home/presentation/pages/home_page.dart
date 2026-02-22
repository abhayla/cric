import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricapp/src/app/router.dart';
import 'package:cricapp/src/app/providers.dart';
import 'package:cricapp/src/features/home/providers.dart';
import 'package:cricapp/src/features/player_profile/providers.dart';
import '../widgets/match_card.dart';
import '../widgets/my_stats_card.dart';

/// Home dashboard page.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveMatches = ref.watch(liveMatchesProvider);
    final recentMatches = ref.watch(recentMatchesProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid;
    final myStats =
        userId != null ? ref.watch(playerStatsProvider(userId)) : null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveMatchesProvider);
          ref.invalidate(recentMatchesProvider);
          if (userId != null) {
            ref.invalidate(playerStatsProvider(userId));
          }
        },
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Cric',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'App',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: false,
            ),

            // Quick actions — Start Match full-width, then row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.matchSetup);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Start Match'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.push(AppRoutes.createTeam);
                            },
                            child: const Text('Create Team'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.push(AppRoutes.tournaments);
                            },
                            child: const Text('Tournament'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Live Matches section
            ...liveMatches.when(
              data: (data) {
                if (data.matches.isEmpty) return <Widget>[];
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Live',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: data.matches.length,
                    itemBuilder: (context, index) {
                      final match = data.matches[index];
                      return MatchCard(
                        match: match,
                        onTap: () {
                          context.push(
                              AppRoutes.liveMatchPath(match.id));
                        },
                      );
                    },
                  ),
                ];
              },
              loading: () => <Widget>[],
              error: (_, __) => <Widget>[],
            ),

            // Recent Matches section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Matches',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go(AppRoutes.matches);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            ...recentMatches.when(
              data: (data) {
                if (data.matches.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: _EmptyMatchesState(theme: theme),
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
                          context.push(
                              AppRoutes.scorecardPath(match.id));
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
              error: (_, __) => [
                SliverToBoxAdapter(
                  child: _EmptyMatchesState(theme: theme),
                ),
              ],
            ),

            // My Stats section
            if (myStats != null)
              ...myStats.when(
                data: (stats) {
                  if (stats == null) return <Widget>[];
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Stats',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go(AppRoutes.profile);
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: MyStatsCard(stats: stats),
                    ),
                  ];
                },
                loading: () => <Widget>[],
                error: (_, __) => <Widget>[],
              ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  const _EmptyMatchesState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_cricket_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No matches yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a match to see it here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
