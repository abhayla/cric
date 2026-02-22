import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/career_stats.dart';
import '../../providers.dart';
import '../notifiers/player_profile_notifier.dart';
import '../widgets/batting_stats_card.dart';
import '../widgets/bowling_stats_card.dart';
import '../widgets/fielding_stats_card.dart';
import '../widgets/player_profile_hero.dart';
import '../widgets/quick_stats_grid.dart';

/// Player profile page showing hero, quick stats, and tabbed career stats.
class PlayerProfilePage extends ConsumerStatefulWidget {
  const PlayerProfilePage({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends ConsumerState<PlayerProfilePage> {
  late final PlayerProfileNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = PlayerProfileNotifier(
      repository: ref.read(playerProfileRepositoryProvider),
      playerId: widget.playerId,
    );
    _notifier.addListener(_onNotifierChanged);
    _notifier.loadProfile();
  }

  void _onNotifierChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierChanged);
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;

    if (state.isLoading && state.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: ErrorDisplay(
          error: state.error!,
          onRetry: () => _notifier.loadProfile(),
        ),
      );
    }

    if (state.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: const Center(child: Text('Player not found')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Player Profile'),
        ),
        body: _ProfileBody(
          playerId: widget.playerId,
          state: state,
          onRefresh: () => _notifier.loadProfile(),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.playerId,
    required this.state,
    required this.onRefresh,
  });

  final String playerId;
  final PlayerProfileState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable header + quick stats
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  PlayerProfileHero(profile: state.profile!),
                  const SizedBox(height: 8),
                  QuickStatsGrid(stats: state.stats),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          AppRoutes.playerMatchHistoryPath(playerId),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Match History'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Batting'),
                      Tab(text: 'Bowling'),
                      Tab(text: 'Fielding'),
                    ],
                  ),
                  if (state.isStatsLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _StatsTabContent(stats: state.stats),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays stats for the currently selected tab.
/// Listens to DefaultTabController to show the correct tab content.
class _StatsTabContent extends StatefulWidget {
  const _StatsTabContent({required this.stats});

  final CareerStats? stats;

  @override
  State<_StatsTabContent> createState() => _StatsTabContentState();
}

class _StatsTabContentState extends State<_StatsTabContent> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    controller.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final controller = DefaultTabController.of(context);
    if (controller.index != _currentIndex) {
      setState(() => _currentIndex = controller.index);
    }
  }

  @override
  void dispose() {
    // TabController is managed by DefaultTabController, no need to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentIndex) {
      0 => BattingStatsCard(stats: widget.stats?.batting),
      1 => BowlingStatsCard(stats: widget.stats?.bowling),
      2 => FieldingStatsCard(stats: widget.stats?.fielding),
      _ => const SizedBox.shrink(),
    };
  }
}
