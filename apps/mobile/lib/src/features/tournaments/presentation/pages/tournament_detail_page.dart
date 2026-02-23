import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../../providers.dart';
import '../widgets/fixture_card.dart';

class TournamentDetailPage extends ConsumerWidget {
  const TournamentDetailPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return tournamentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(tournamentDetailProvider(tournamentId)),
        ),
      ),
      data: (tournament) => _TournamentDetailView(
        tournament: tournament,
        tournamentId: tournamentId,
      ),
    );
  }
}

class _TournamentDetailView extends StatelessWidget {
  const _TournamentDetailView({
    required this.tournament,
    required this.tournamentId,
  });

  final Tournament tournament;
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) => [
            SliverAppBar(
              title: const Text('Tournament'),
              pinned: true,
              expandedHeight: 260,
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroSection(tournament: tournament),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (_) {},
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Tournament'),
                    ),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Fixtures'),
                    Tab(text: 'Teams'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _OverviewTab(tournament: tournament, tournamentId: tournamentId),
              _FixturesTab(tournamentId: tournamentId, tournament: tournament),
              _TeamsTab(tournament: tournament),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Hero Section --

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: MediaQuery.of(context).padding.top + 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            tournament.name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _HeroBadge(text: tournament.format.label),
              _HeroBadge(text: '${tournament.oversPerMatch} Overs'),
              _StatusBadge(status: tournament.status),
            ],
          ),
          if (tournament.dateRange != null) ...[
            const SizedBox(height: 8),
            Text(
              tournament.dateRange!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: 'Teams', value: '${tournament.teamCount ?? 0}'),
              const _StatItem(label: 'Matches', value: '0'),
              const _StatItem(label: 'Completed', value: '0'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final isLive = status == TournamentStatus.live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLive
            ? const Color(0xFFEF4444)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Tab Bar Delegate --

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// -- Overview Tab --

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.tournament, required this.tournamentId});

  final Tournament tournament;
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(tournamentStandingsProvider(tournamentId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Standings preview
        standingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (result) {
            if (result.standings.isEmpty) {
              return const _SectionEmptyState(
                icon: Icons.calendar_today,
                title: 'No Upcoming Matches',
                description:
                    'All matches have been completed or fixtures haven\'t been scheduled yet.',
              );
            }
            return _StandingsPreview(
              standings: result.standings,
              tournamentId: tournamentId,
            );
          },
        ),
        const SizedBox(height: 16),
        // Quick links
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.push(AppRoutes.tournamentBracketPath(tournamentId));
                },
                child: const Text('Bracket'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.push(
                    AppRoutes.tournamentLeaderboardPath(tournamentId),
                  );
                },
                child: const Text('Leaderboard'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StandingsPreview extends StatelessWidget {
  const _StandingsPreview({
    required this.standings,
    required this.tournamentId,
  });

  final List<Standing> standings;
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewStandings = standings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Standings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push(AppRoutes.tournamentStandingsPath(tournamentId));
              },
              child: const Text('View Full'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FixedColumnWidth(30),
            2: FixedColumnWidth(30),
            3: FixedColumnWidth(30),
            4: FixedColumnWidth(35),
            5: FixedColumnWidth(50),
          },
          children: [
            TableRow(
              children: ['Team', 'P', 'W', 'L', 'Pts', 'NRR']
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        h,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: h == 'Team'
                            ? TextAlign.left
                            : TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...previewStandings.map(
              (s) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      s.teamName ?? s.teamId,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _cellText('${s.played}', theme),
                  _cellText('${s.won}', theme),
                  _cellText('${s.lost}', theme),
                  _cellText('${s.points}', theme, bold: true),
                  _cellText(
                    s.formattedNrr,
                    theme,
                    color: s.hasPositiveNrr ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cellText(
    String text,
    ThemeData theme, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          color: color,
        ),
      ),
    );
  }
}

// -- Fixtures Tab --

class _FixturesTab extends ConsumerWidget {
  const _FixturesTab({required this.tournamentId, required this.tournament});

  final String tournamentId;
  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(tournamentFixturesProvider(tournamentId));

    return fixturesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorDisplay(
        error: error,
        onRetry: () => ref.invalidate(tournamentFixturesProvider(tournamentId)),
      ),
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return const _SectionEmptyState(
            icon: Icons.calendar_today,
            title: 'No Fixtures Yet',
            description:
                'Fixtures will appear here once the tournament schedule is generated.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fixtures.length,
          itemBuilder: (context, index) {
            final fixture = fixtures[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FixtureCard(
                fixture: fixture,
                onTap: () => _onFixtureTap(context, fixture),
              ),
            );
          },
        );
      },
    );
  }

  void _onFixtureTap(BuildContext context, Fixture fixture) {
    if (fixture.isCompleted && fixture.matchId != null) {
      // Completed match — navigate to scorecard
      context.push(AppRoutes.scorecardPath(fixture.matchId!));
    } else if (fixture.hasMatch) {
      // Live match — navigate to scoring
      context.push(AppRoutes.scoringPath(fixture.matchId!));
    } else {
      // No match yet — navigate to match setup with pre-selected teams
      context.push(
        AppRoutes.matchSetup,
        extra: <String, dynamic>{
          'homeTeamId': fixture.homeTeamId,
          'homeTeamName': fixture.homeTeamName,
          'awayTeamId': fixture.awayTeamId,
          'awayTeamName': fixture.awayTeamName,
          'tournamentId': fixture.tournamentId,
          'fixtureId': fixture.id,
          'totalOvers': tournament.oversPerMatch,
          'playersPerSide': tournament.playersPerSide,
        },
      );
    }
  }
}

// -- Teams Tab --

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final teams = tournament.teams;
    if (teams == null || teams.isEmpty) {
      return const _SectionEmptyState(
        icon: Icons.groups,
        title: 'No Teams Registered',
        description:
            'Teams will appear here once they register for the tournament.',
      );
    }

    // Group teams by groupName
    final grouped = <String, List<TournamentTeam>>{};
    for (final team in teams) {
      final group = team.groupName ?? 'Ungrouped';
      grouped.putIfAbsent(group, () => []).add(team);
    }

    // Flatten grouped entries into a list of widgets for builder
    final items = grouped.entries
        .expand(
          (entry) => [
            entry.key, // group header (String)
            ...entry.value, // team rows (TournamentTeam)
          ],
        )
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return _GroupHeader(groupName: item);
        }
        return _TeamRow(team: item as TournamentTeam);
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        groupName.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team});

  final TournamentTeam team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              (team.teamName ?? 'T')[0],
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName ?? team.teamId,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (team.seedNumber != null)
                  Text(
                    'Seed #${team.seedNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Shared Empty State --

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
