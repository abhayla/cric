import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricscores/src/app/router.dart';
import 'package:cricscores/src/features/live/providers.dart';
import 'package:cricscores/src/features/home/presentation/widgets/match_card.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/tournament_card.dart';
import 'package:cricscores/src/features/tournaments/domain/entities/tournament.dart';

/// Live hub page with Matches and Tournaments tabs.
class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Matches'),
            Tab(text: 'Tournaments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MatchesSubTab(),
          _TournamentsSubTab(),
        ],
      ),
    );
  }
}

class _MatchesSubTab extends ConsumerStatefulWidget {
  const _MatchesSubTab();

  @override
  ConsumerState<_MatchesSubTab> createState() => _MatchesSubTabState();
}

class _MatchesSubTabState extends ConsumerState<_MatchesSubTab>
    with AutomaticKeepAliveClientMixin {
  String _filter = 'live';

  @override
  bool get wantKeepAlive => true;

  /// Maps filter label to provider arg: 'live' -> 'live', 'completed' -> 'completed', 'all' -> null.
  String? get _statusArg => _filter == 'all' ? null : _filter;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final matchesAsync = ref.watch(publicMatchesByStatusProvider(_statusArg));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(publicMatchesByStatusProvider(_statusArg));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
            ),
          ),
          ...matchesAsync.when(
            data: (data) {
              if (data.matches.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySectionCard(
                      icon: Icons.sports_cricket_outlined,
                      message: _emptyMessageForFilter(_filter, 'matches'),
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
                        final path = match.status == 'completed'
                            ? AppRoutes.scorecardPath(match.id)
                            : AppRoutes.liveMatchPath(match.id);
                        context.push(path);
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
                  message: 'Failed to load matches',
                ),
              ),
            ],
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _TournamentsSubTab extends ConsumerStatefulWidget {
  const _TournamentsSubTab();

  @override
  ConsumerState<_TournamentsSubTab> createState() =>
      _TournamentsSubTabState();
}

class _TournamentsSubTabState extends ConsumerState<_TournamentsSubTab>
    with AutomaticKeepAliveClientMixin {
  String _filter = 'live';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tournamentsAsync = ref.watch(tournamentsListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(tournamentsListProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
            ),
          ),
          ...tournamentsAsync.when(
            data: (data) {
              final filtered = _filterTournaments(data.tournaments);
              if (filtered.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySectionCard(
                      icon: Icons.emoji_events_outlined,
                      message:
                          _emptyMessageForFilter(_filter, 'tournaments'),
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tournament = filtered[index];
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
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  List<Tournament> _filterTournaments(List<Tournament> tournaments) {
    switch (_filter) {
      case 'live':
        return tournaments
            .where((t) => t.status == TournamentStatus.live)
            .toList();
      case 'completed':
        return tournaments
            .where((t) => t.status == TournamentStatus.completed)
            .toList();
      default:
        return tournaments;
    }
  }
}

String _emptyMessageForFilter(String filter, String type) {
  switch (filter) {
    case 'live':
      return 'No live $type right now';
    case 'completed':
      return 'No completed $type';
    default:
      return 'No $type found';
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
        mainAxisSize: MainAxisSize.min,
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
