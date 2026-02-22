import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_display.dart';
import '../../providers.dart';
import '../notifiers/player_match_history_notifier.dart';
import '../widgets/match_performance_card.dart';

/// Match history page with result filter chips and paginated list.
class PlayerMatchHistoryPage extends ConsumerStatefulWidget {
  const PlayerMatchHistoryPage({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerMatchHistoryPage> createState() =>
      _PlayerMatchHistoryPageState();
}

class _PlayerMatchHistoryPageState
    extends ConsumerState<PlayerMatchHistoryPage> {
  late final PlayerMatchHistoryNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = PlayerMatchHistoryNotifier(
      repository: ref.read(playerProfileRepositoryProvider),
      playerId: widget.playerId,
    );
    _notifier.addListener(_onChanged);
    _notifier.loadMatches();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: RefreshIndicator(
        onRefresh: () => _notifier.loadMatches(),
        child: Column(
          children: [
            _FilterChips(
              selectedResult: state.selectedResult,
              onSelected: _notifier.filterByResult,
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PlayerMatchHistoryState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.matches.isEmpty) {
      return ErrorDisplay(
        error: state.error!,
        onRetry: () => _notifier.loadMatches(),
      );
    }

    if (state.matches.isEmpty) {
      return const _EmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          _notifier.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: state.matches.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.matches.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return MatchPerformanceCard(match: state.matches[index]);
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedResult,
    required this.onSelected,
  });

  final String? selectedResult;
  final void Function(String?) onSelected;

  static const _filters = [
    (null, 'All'),
    ('won', 'Won'),
    ('lost', 'Lost'),
    ('tied', 'Tied'),
    ('no_result', 'No Result'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final (value, label) = filter;
            final isSelected = value == selectedResult;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onSelected(value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'No Match History',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your past matches will appear here once you play.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
