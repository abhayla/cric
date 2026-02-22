import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricapp/src/app/router.dart';
import 'package:cricapp/src/app/providers.dart';
import 'package:cricapp/src/features/home/providers.dart';
import 'package:cricapp/src/features/teams/providers.dart' as teams_prov;
import 'package:cricapp/src/features/teams/domain/entities/team.dart';
import 'package:cricapp/src/features/teams/presentation/widgets/team_card.dart';
import 'package:cricapp/src/features/tournaments/providers.dart' as tourn_prov;
import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricapp/src/features/tournaments/presentation/widgets/tournament_card.dart';
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
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid;

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

/// Teams sub-tab: "Teams I Own" + "Teams I'm In".
class _TeamsSubTab extends ConsumerWidget {
  const _TeamsSubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamsAsync = ref.watch(teams_prov.teamsListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(teams_prov.teamsListProvider.notifier).refresh();
      },
      child: teamsAsync.when(
        data: (result) {
          final owned = result.teams
              .where((t) => t.role == TeamMemberRole.owner)
              .toList();
          final member = result.teams
              .where((t) => t.role != TeamMemberRole.owner)
              .toList();

          if (owned.isEmpty && member.isEmpty) {
            return _EmptyState(
              icon: Icons.groups_outlined,
              title: 'No Teams Yet',
              subtitle: 'Create a team to get started',
              actionLabel: 'Create a Team',
              onAction: () => context.push(AppRoutes.createTeam),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (owned.isNotEmpty) ...[
                _SectionHeader(title: 'Teams I Own', theme: theme),
                _TeamGrid(teams: owned),
              ],
              if (member.isNotEmpty) ...[
                _SectionHeader(title: "Teams I'm In", theme: theme),
                _TeamGrid(teams: member),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load teams',
          subtitle: 'Pull to refresh',
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
  String _filter = 'all';

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
                    'lost' =>
                      m.isCompleted &&
                      !(m.result?.contains('Won') ?? true),
                    _ => true,
                  };
                }).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onSelected: () => setState(() => _filter = 'all'),
                    ),
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
                  ],
                ),
              ),
              if (filteredMatches.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _EmptyState(
                    icon: Icons.sports_cricket_outlined,
                    title: 'No Matches Found',
                    subtitle: _filter == 'all'
                        ? 'Start a match to see it here'
                        : 'No matches match this filter',
                    actionLabel:
                        _filter == 'all' ? 'Start a Match' : null,
                    onAction: _filter == 'all'
                        ? () => context.push(AppRoutes.matchSetup)
                        : null,
                  ),
                )
              else ...[
                ...filteredMatches.map(
                  (match) => MatchCard(
                    match: match,
                    onTap: () {
                      if (match.isLive) {
                        context.push(AppRoutes.liveMatchPath(match.id));
                      } else {
                        context.push(AppRoutes.scorecardPath(match.id));
                      }
                    },
                  ),
                ),
                // View All link
                if (result.total > result.matches.length)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.matches),
                        child: const Text('View All Matches'),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load matches',
          subtitle: 'Pull to refresh',
        ),
      ),
    );
  }
}

/// Tournaments sub-tab: filter chips + tournament list.
class _TournamentsSubTab extends ConsumerStatefulWidget {
  const _TournamentsSubTab();

  @override
  ConsumerState<_TournamentsSubTab> createState() =>
      _TournamentsSubTabState();
}

class _TournamentsSubTabState extends ConsumerState<_TournamentsSubTab> {
  String _filter = 'all';

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
                    'completed' => t.status == TournamentStatus.completed,
                    _ => true,
                  };
                }).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onSelected: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Live',
                      selected: _filter == 'live',
                      onSelected: () => setState(() => _filter = 'live'),
                    ),
                    _FilterChip(
                      label: 'Completed',
                      selected: _filter == 'completed',
                      onSelected: () =>
                          setState(() => _filter = 'completed'),
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No Tournaments Found',
                    subtitle: _filter == 'all'
                        ? 'Create a tournament to get started'
                        : 'No tournaments match this filter',
                    actionLabel:
                        _filter == 'all' ? 'Create Tournament' : null,
                    onAction: _filter == 'all'
                        ? () => context.push(AppRoutes.createTournament)
                        : null,
                  ),
                )
              else ...[
                ...filtered.map(
                  (tournament) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: TournamentCard(
                      tournament: tournament,
                      onTap: () {
                        context.push(AppRoutes.tournamentDetailPath(
                            tournament.id));
                      },
                    ),
                  ),
                ),
                // View All link
                if (result.tournaments.length < result.total)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.tournaments),
                        child: const Text('View All Tournaments'),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load tournaments',
          subtitle: 'Pull to refresh',
        ),
      ),
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

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
          onTap: () => context.push(
            AppRoutes.teamDetailPath(teams[index].id),
          ),
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
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
