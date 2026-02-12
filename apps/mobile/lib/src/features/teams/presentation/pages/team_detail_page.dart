import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        body: Center(child: Text('Error: $error')),
      ),
      data: (detail) => _TeamDetailView(detail: detail),
    );
  }
}

class _TeamDetailView extends StatelessWidget {
  const _TeamDetailView({required this.detail});

  final TeamDetail detail;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail.team.name),
        ),
        body: Column(
          children: [
            _TeamHeader(team: detail.team),
            const TeamStatsRow(),
            const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Matches'),
                Tab(text: 'Players'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(team: detail.team),
                  const _MatchesTab(),
                  _PlayersTab(
                    roster: detail.roster,
                    team: detail.team,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            backgroundImage:
                team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
            child: team.logoUrl == null
                ? Text(
                    team.initial,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
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

class _PlayersTab extends StatelessWidget {
  const _PlayersTab({required this.roster, required this.team});

  final List<RosterEntry> roster;
  final Team team;

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return _EmptyPlayersState();
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${roster.length} ${roster.length == 1 ? 'player' : 'players'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (team.role == TeamMemberRole.owner ||
                  team.role == TeamMemberRole.captain)
                OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to manage roster
                  },
                  child: const Text('Manage'),
                ),
            ],
          ),
        ),
        for (final role in roleOrder)
          if (grouped.containsKey(role)) ...[
            _RoleGroupHeader(role: role),
            for (final entry in grouped[role]!)
              PlayerRow(entry: entry),
          ],
      ],
    );
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
              // TODO: Navigate to add player
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
}
