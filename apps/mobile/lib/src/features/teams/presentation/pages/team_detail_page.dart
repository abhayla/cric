import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../../providers.dart';
import '../widgets/player_row.dart';
import '../widgets/team_stats_row.dart';

class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teamDetailProvider(teamId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        ),
      ),
      data: (detail) => _TeamDetailView(detail: detail),
    );
  }
}

class _TeamDetailView extends ConsumerStatefulWidget {
  const _TeamDetailView({required this.detail});

  final TeamDetail detail;

  @override
  ConsumerState<_TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends ConsumerState<_TeamDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOwnerOrCaptain =>
      widget.detail.team.role == TeamMemberRole.owner ||
      widget.detail.team.role == TeamMemberRole.captain;

  bool get _showFab => _tabController.index == 2 && _isOwnerOrCaptain;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.detail.team.name),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                context.push(AppRoutes.addPlayerPath(widget.detail.team.id));
              },
              child: const Icon(Icons.person_add),
            )
          : null,
      body: Column(
        children: [
          _TeamHeader(team: widget.detail.team),
          const TeamStatsRow(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Matches'),
              Tab(text: 'Players'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(team: widget.detail.team),
                const _MatchesTab(),
                _PlayersTab(
                  roster: widget.detail.roster,
                  team: widget.detail.team,
                  teamId: widget.detail.team.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundImage:
                team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
            onForegroundImageError:
                team.logoUrl != null ? (_, _) {} : null,
            child: Text(
              team.initial,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            team.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            team.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Form',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No matches played yet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Top Performers',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Play matches to see top performers',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scoreboard_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No matches played yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Matches involving this team will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayersTab extends ConsumerWidget {
  const _PlayersTab({
    required this.roster,
    required this.team,
    required this.teamId,
  });

  final List<RosterEntry> roster;
  final Team team;
  final String teamId;

  bool get _isOwnerOrCaptain =>
      team.role == TeamMemberRole.owner ||
      team.role == TeamMemberRole.captain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roster.isEmpty) {
      return _EmptyPlayersState(teamId: teamId);
    }

    final theme = Theme.of(context);

    // Group roster by player role
    final grouped = <PlayerRole, List<RosterEntry>>{};
    for (final entry in roster) {
      final role = entry.playerRole ?? PlayerRole.batter;
      (grouped[role] ??= []).add(entry);
    }

    // Order: batter, allRounder, wkBatter, bowler
    final roleOrder = [
      PlayerRole.batter,
      PlayerRole.allRounder,
      PlayerRole.wkBatter,
      PlayerRole.bowler,
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamDetailProvider(teamId));
        await ref.read(teamDetailProvider(teamId).future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${roster.length} ${roster.length == 1 ? 'player' : 'players'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final role in roleOrder)
            if (grouped.containsKey(role)) ...[
              _RoleGroupHeader(role: role),
              for (final entry in grouped[role]!)
                Row(
                  children: [
                    Expanded(child: PlayerRow(entry: entry)),
                    if (_isOwnerOrCaptain)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Remove',
                        onPressed: () => _confirmRemovePlayer(
                          context, ref, entry.playerId,
                        ),
                      ),
                  ],
                ),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmRemovePlayer(
    BuildContext context, WidgetRef ref, String playerId,
  ) async {
    final player = roster.where((e) => e.playerId == playerId).firstOrNull;
    final playerName = player?.displayName ?? 'this player';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Remove $playerName from the roster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(teamRepositoryProvider).removePlayer(teamId, playerId);
      ref.invalidate(teamDetailProvider(teamId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player removed')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove player')),
      );
    }
  }
}

class _RoleGroupHeader extends StatelessWidget {
  const _RoleGroupHeader({required this.role});

  final PlayerRole role;

  String get _label => switch (role) {
        PlayerRole.batter => 'BATTERS',
        PlayerRole.bowler => 'BOWLERS',
        PlayerRole.allRounder => 'ALL-ROUNDERS',
        PlayerRole.wkBatter => 'WK-BATTERS',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        _label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyPlayersState extends StatelessWidget {
  const _EmptyPlayersState({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No players yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add players to build your team roster.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.push(AppRoutes.addPlayerPath(teamId));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
}
