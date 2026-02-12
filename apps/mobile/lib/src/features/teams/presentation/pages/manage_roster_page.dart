import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/team.dart';
import '../../providers.dart';
import '../widgets/player_row.dart';

class ManageRosterPage extends ConsumerStatefulWidget {
  const ManageRosterPage({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<ManageRosterPage> createState() => _ManageRosterPageState();
}

class _ManageRosterPageState extends ConsumerState<ManageRosterPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RosterEntry> _filterRoster(List<RosterEntry> roster) {
    if (_searchQuery.isEmpty) return roster;
    return roster
        .where((e) =>
            e.displayName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(teamDetailProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roster'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (detail) => _RosterContent(
          roster: detail.roster,
          filteredRoster: _filterRoster(detail.roster),
          searchController: _searchController,
          onSearchChanged: (query) => setState(() => _searchQuery = query),
          onAddPlayer: () {
            context.push(AppRoutes.addPlayerPath(widget.teamId));
          },
          onRemovePlayer: (playerId) {
            // TODO: Call API to remove player
          },
        ),
      ),
    );
  }
}

class _RosterContent extends StatelessWidget {
  const _RosterContent({
    required this.roster,
    required this.filteredRoster,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddPlayer,
    required this.onRemovePlayer,
  });

  final List<RosterEntry> roster;
  final List<RosterEntry> filteredRoster;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPlayer;
  final ValueChanged<String> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (roster.isEmpty) {
      return _EmptyState(onAddPlayer: onAddPlayer);
    }

    return Column(
      children: [
        // Count and Add button row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${roster.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' / 25 players',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAddPlayer,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Player'),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Player list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredRoster.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = filteredRoster[index];
              return _RosterRow(
                entry: entry,
                onRemove: () => onRemovePlayer(entry.playerId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.entry, required this.onRemove});

  final RosterEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: PlayerRow(entry: entry)),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Remove',
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPlayer});

  final VoidCallback onAddPlayer;

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
            onPressed: onAddPlayer,
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
}
