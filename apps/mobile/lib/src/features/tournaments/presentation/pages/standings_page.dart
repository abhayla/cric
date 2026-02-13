import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/standing.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../providers.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(tournamentStandingsProvider(tournamentId));

    return standingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Standings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Standings')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (result) => _StandingsView(result: result),
    );
  }
}

class _StandingsView extends StatelessWidget {
  const _StandingsView({required this.result});

  final StandingsResult result;

  @override
  Widget build(BuildContext context) {
    if (result.standings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Standings')),
        body: const _EmptyState(),
      );
    }

    // If multiple groups, use tabs
    if (result.groups.length > 1) {
      return DefaultTabController(
        length: result.groups.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Standings'),
            bottom: TabBar(
              isScrollable: true,
              tabs: result.groups.map((g) => Tab(text: g)).toList(),
            ),
          ),
          body: TabBarView(
            children: result.groups.map((group) {
              final groupStandings = result.standings
                  .where((s) => s.groupName == group)
                  .toList();
              return _StandingsTable(standings: groupStandings);
            }).toList(),
          ),
        ),
      );
    }

    // Single group or no groups
    return Scaffold(
      appBar: AppBar(title: const Text('Standings')),
      body: _StandingsTable(standings: result.standings),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.standings});

  final List<Standing> standings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(28),
          1: FlexColumnWidth(3),
          2: FixedColumnWidth(28),
          3: FixedColumnWidth(28),
          4: FixedColumnWidth(28),
          5: FixedColumnWidth(28),
          6: FixedColumnWidth(28),
          7: FixedColumnWidth(35),
          8: FixedColumnWidth(50),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            children: ['#', 'Team', 'P', 'W', 'L', 'T', 'NR', 'Pts', 'NRR']
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        h,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign:
                            h == 'Team' ? TextAlign.left : TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
          ...standings.asMap().entries.map((entry) {
            final index = entry.key;
            final s = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              children: [
                _cell('${s.position ?? index + 1}', theme),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    s.teamName ?? s.teamId,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _cell('${s.played}', theme),
                _cell('${s.won}', theme),
                _cell('${s.lost}', theme),
                _cell('${s.tied}', theme),
                _cell('${s.noResult}', theme),
                _cell('${s.points}', theme, bold: true),
                _cell(
                  s.formattedNrr,
                  theme,
                  color: s.hasPositiveNrr ? Colors.green : Colors.red,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _cell(String text, ThemeData theme,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No Standings Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Standings will appear once matches have been played.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
