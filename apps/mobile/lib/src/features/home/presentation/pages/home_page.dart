import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cricapp/src/app/router.dart';

/// Home dashboard page.
///
/// Displays quick action buttons (Start Match, Create Team, Tournament),
/// and sections for Live, Tournaments, and Recent Matches (all empty state
/// for Phase 1).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull-to-refresh placeholder — wired in later phases
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
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
              ],
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.matchSetup);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Start Match'),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          context.go(AppRoutes.tournaments);
                        },
                        child: const Text('Tournament'),
                      ),
                    ),
                  ],
                ),
              ),
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
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // Empty state for recent matches
            SliverToBoxAdapter(
              child: Container(
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
              ),
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}
