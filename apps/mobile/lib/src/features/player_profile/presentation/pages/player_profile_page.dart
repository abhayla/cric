import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../notifiers/player_profile_notifier.dart';
import '../widgets/batting_stats_card.dart';
import '../widgets/bowling_stats_card.dart';
import '../widgets/fielding_stats_card.dart';
import '../widgets/player_profile_hero.dart';
import '../widgets/quick_stats_grid.dart';
import 'player_match_history_page.dart';

class PlayerProfilePage extends ConsumerStatefulWidget {
  const PlayerProfilePage({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends ConsumerState<PlayerProfilePage>
    with SingleTickerProviderStateMixin {
  late final PlayerProfileNotifier _notifier;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notifier = PlayerProfileNotifier(
      repository: ref.read(playerProfileRepositoryProvider),
      playerId: widget.playerId,
    );
    _notifier.addListener(_onStateChange);
    _notifier.loadProfile();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_onStateChange);
    _notifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PlayerProfileState state) {
    if (state.isLoading && state.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _notifier.loadProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: PlayerProfileHero(profile: profile)),
              SliverToBoxAdapter(child: QuickStatsGrid(stats: state.stats)),
              SliverToBoxAdapter(child: _buildFormatSelector(state)),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Batting'),
                    Tab(text: 'Bowling'),
                    Tab(text: 'Fielding'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: BattingStatsCard(stats: state.stats?.batting),
                ),
                SingleChildScrollView(
                  child: BowlingStatsCard(stats: state.stats?.bowling),
                ),
                SingleChildScrollView(
                  child: FieldingStatsCard(stats: state.stats?.fielding),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PlayerMatchHistoryPage(playerId: widget.playerId),
                ),
              ),
              child: const Text('View Match History'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelector(PlayerProfileState state) {
    const formats = ['all', 'T20', 'ODI', 'custom'];
    const labels = ['All', 'T20', 'ODI', 'Custom'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < formats.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              ChoiceChip(
                label: Text(labels[i]),
                selected: state.selectedFormat == formats[i],
                onSelected: (_) => _notifier.switchFormat(formats[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
