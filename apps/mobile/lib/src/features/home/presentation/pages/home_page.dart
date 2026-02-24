import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricscores/src/app/router.dart';
import 'package:cricscores/src/app/providers.dart' show currentUserIdProvider;
import 'package:cricscores/src/features/home/providers.dart';
import 'package:cricscores/src/features/teams/providers.dart' as teams_prov;
import 'package:cricscores/src/features/teams/domain/entities/team.dart';
import 'package:cricscores/src/features/teams/presentation/widgets/team_card.dart';
import 'package:cricscores/src/features/tournaments/providers.dart' as tourn_prov;
import 'package:cricscores/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/tournament_card.dart';
import '../../../../shared/widgets/error_display.dart';
import '../widgets/match_card.dart';
import '../widgets/expandable_fab.dart';

/// My Cricket page — the main tab with Teams / Matches / Tournaments sub-tabs.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'My ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: 'Cricket',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              onPressed: () {
                if (userId != null) {
                  context.push(AppRoutes.playerProfilePath(userId));
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Teams'),
            Tab(text: 'Matches'),
            Tab(text: 'Tournaments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TeamsSubTab(),
          _MatchesSubTab(),
          _TournamentsSubTab(),
        ],
      ),
      floatingActionButton: ExpandableFab(
        children: [
          FabAction(
            icon: Icons.sports_cricket,
            label: 'Start Match',
            onPressed: () => context.push(AppRoutes.matchSetup),
          ),
          FabAction(
            icon: Icons.groups,
            label: 'Create Team',
            onPressed: () => context.push(AppRoutes.createTeam),
          ),
          FabAction(
            icon: Icons.emoji_events,
            label: 'Create Tournament',
            onPressed: () => context.push(AppRoutes.createTournament),
          ),
        ],
      ),
    );
  }
}

/// Teams sub-tab: filter chips (Member / Owner / All) + team grid.
class _TeamsSubTab extends ConsumerStatefulWidget {
  const _TeamsSubTab();

  @override
  ConsumerState<_TeamsSubTab> createState() => _TeamsSubTabState();
}

class _TeamsSubTabState extends ConsumerState<_TeamsSubTab> {
  String _filter = 'member';

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teams_prov.teamsListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(teams_prov.teamsListProvider.notifier).refresh();
      },
      child: teamsAsync.when(
        data: (result) {
          final filtered = _filter == 'all'
              ? result.teams
              : result.teams.where((t) {
                  return switch (_filter) {
                    'member' => t.role != TeamMemberRole.owner,
                    'owner' => t.role == TeamMemberRole.owner,
                    _ => true,
                  };
                }).toList();

          final itemCount =
              1 + // filter chips
              (filtered.isEmpty ? 1 : 1); // empty state or grid

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Filter chips row
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Member',
                        selected: _filter == 'member',
                        onSelected: () => setState(() => _filter = 'member'),
                      ),
                      _FilterChip(
                        label: 'Owner',
                        selected: _filter == 'owner',
                        onSelected: () => setState(() => _filter = 'owner'),
                      ),
                      _FilterChip(
                        label: 'All',
                        selected: _filter == 'all',
                        onSelected: () => setState(() => _filter = 'all'),
                      ),
                    ],
                  ),
                );
              }

              // Empty state
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No Teams Found',
                    subtitle: _filter == 'all'
                        ? 'Create a team to get started'
                        : 'No teams match this filter',
                    actionLabel: _filter == 'all' ? 'Create a Team' : null,
                    onAction: _filter == 'all'
                        ? () => context.push(AppRoutes.createTeam)
                        : null,
                  ),
                );
              }

              // Team grid
              return _TeamGrid(teams: filtered);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(teams_prov.teamsListProvider),
        ),
      ),
    );
  }
}

/// Matches sub-tab: filter chips + match list.
class _MatchesSubTab extends ConsumerStatefulWidget {
  const _MatchesSubTab();

  @override
  ConsumerState<_MatchesSubTab> createState() => _MatchesSubTabState();
}

class _MatchesSubTabState extends ConsumerState<_MatchesSubTab> {
  String _filter = 'live';

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(allMatchesProvider(1));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allMatchesProvider(1));
      },
      child: matchesAsync.when(
        data: (result) {
          final filteredMatches = _filter == 'all'
              ? result.matches
              : result.matches.where((m) {
                  return switch (_filter) {
                    'live' => m.status == 'live',
                    'won' => m.result?.contains('Won') ?? false,
                    'lost' => m.isCompleted &&
                        m.result != null &&
                        !m.result!.contains('Won') &&
                        !m.result!.contains('Tied') &&
                        !m.result!.contains('No Result'),
                    _ => true,
                  };
                }).toList();

          // Build items list: filter chips + matches (or empty state) + optional view all
          final hasViewAll =
              filteredMatches.isNotEmpty &&
              result.total > result.matches.length;
          final itemCount =
              1 + // filter chips
              (filteredMatches.isEmpty ? 1 : filteredMatches.length) +
              (hasViewAll ? 1 : 0);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Filter chips row
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Live',
                        selected: _filter == 'live',
                        onSelected: () => setState(() => _filter = 'live'),
                      ),
                      _FilterChip(
                        label: 'Won',
                        selected: _filter == 'won',
                        onSelected: () => setState(() => _filter = 'won'),
                      ),
                      _FilterChip(
                        label: 'Lost',
                        selected: _filter == 'lost',
                        onSelected: () => setState(() => _filter = 'lost'),
                      ),
                      _FilterChip(
                        label: 'All',
                        selected: _filter == 'all',
                        onSelected: () => setState(() => _filter = 'all'),
                      ),
                    ],
                  ),
                );
              }

              // Empty state
              if (filteredMatches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _EmptyState(
                    icon: Icons.sports_cricket_outlined,
                    title: 'No Matches Found',
                    subtitle: _filter == 'all'
                        ? 'Start a match to see it here'
                        : 'No matches match this filter',
                    actionLabel: _filter == 'all' ? 'Start a Match' : null,
                    onAction: _filter == 'all'
                        ? () => context.push(AppRoutes.matchSetup)
                        : null,
                  ),
                );
              }

              // Match cards
              final matchIndex = index - 1;
              if (matchIndex < filteredMatches.length) {
                final match = filteredMatches[matchIndex];
                return MatchCard(
                  match: match,
                  onTap: () {
                    if (match.isLive) {
                      context.push(AppRoutes.liveMatchPath(match.id));
                    } else {
                      context.push(AppRoutes.scorecardPath(match.id));
                    }
                  },
                );
              }

              // View All link
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.matches),
                    child: const Text('View All Matches'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(allMatchesProvider(1)),
        ),
      ),
    );
  }
}

/// Tournaments sub-tab: filter chips + tournament list.
class _TournamentsSubTab extends ConsumerStatefulWidget {
  const _TournamentsSubTab();

  @override
  ConsumerState<_TournamentsSubTab> createState() => _TournamentsSubTabState();
}

class _TournamentsSubTabState extends ConsumerState<_TournamentsSubTab> {
  String _filter = 'live';

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tourn_prov.tournamentsListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(tourn_prov.tournamentsListProvider.notifier).refresh();
      },
      child: tournamentsAsync.when(
        data: (result) {
          final filtered = _filter == 'all'
              ? result.tournaments
              : result.tournaments.where((t) {
                  return switch (_filter) {
                    'live' => t.status == TournamentStatus.live,
                    'registered' => t.status == TournamentStatus.registration,
                    'completed' => t.status == TournamentStatus.completed,
                    _ => true,
                  };
                }).toList();

          // Build items list: filter chips + tournaments (or empty state) + optional view all
          final hasViewAll =
              filtered.isNotEmpty && result.tournaments.length < result.total;
          final itemCount =
              1 + // filter chips
              (filtered.isEmpty ? 1 : filtered.length) +
              (hasViewAll ? 1 : 0);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Filter chips row
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Live',
                        selected: _filter == 'live',
                        onSelected: () => setState(() => _filter = 'live'),
                      ),
                      _FilterChip(
                        label: 'Registered',
                        selected: _filter == 'registered',
                        onSelected: () => setState(() => _filter = 'registered'),
                      ),
                      _FilterChip(
                        label: 'Completed',
                        selected: _filter == 'completed',
                        onSelected: () => setState(() => _filter = 'completed'),
                      ),
                      _FilterChip(
                        label: 'All',
                        selected: _filter == 'all',
                        onSelected: () => setState(() => _filter = 'all'),
                      ),
                    ],
                  ),
                );
              }

              // Empty state
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No Tournaments Found',
                    subtitle: _filter == 'all'
                        ? 'Create a tournament to get started'
                        : 'No tournaments match this filter',
                    actionLabel: _filter == 'all' ? 'Create Tournament' : null,
                    onAction: _filter == 'all'
                        ? () => context.push(AppRoutes.createTournament)
                        : null,
                  ),
                );
              }

              // Tournament cards
              final tournamentIndex = index - 1;
              if (tournamentIndex < filtered.length) {
                final tournament = filtered[tournamentIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TournamentCard(
                    tournament: tournament,
                    onTap: () {
                      context.push(
                        AppRoutes.tournamentDetailPath(tournament.id),
                      );
                    },
                  ),
                );
              }

              // View All link
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.tournaments),
                    child: const Text('View All Tournaments'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(tourn_prov.tournamentsListProvider),
        ),
      ),
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: teams.length,
        itemBuilder: (context, index) => TeamCard(
          team: teams[index],
          onTap: () => context.push(AppRoutes.teamDetailPath(teams[index].id)),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
