import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fixture.dart';
import '../../providers.dart';

class KnockoutBracketPage extends ConsumerWidget {
  const KnockoutBracketPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(tournamentFixturesProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bracket')),
      body: fixturesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (fixtures) {
          final knockoutFixtures =
              fixtures.where((f) => f.roundType.isKnockout).toList();
          if (knockoutFixtures.isEmpty) {
            return const _EmptyState();
          }
          return _BracketView(fixtures: knockoutFixtures);
        },
      ),
    );
  }
}

class _BracketView extends StatelessWidget {
  const _BracketView({required this.fixtures});

  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    // Group fixtures by round type
    final rounds = <RoundType, List<Fixture>>{};
    for (final fixture in fixtures) {
      rounds.putIfAbsent(fixture.roundType, () => []).add(fixture);
    }

    final roundOrder = [
      RoundType.quarterFinal,
      RoundType.semiFinal,
      RoundType.thirdPlace,
      RoundType.final_,
    ];

    final orderedRounds = roundOrder
        .where((r) => rounds.containsKey(r))
        .map((r) => MapEntry(r, rounds[r]!))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: orderedRounds.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _RoundColumn(
              roundType: entry.key,
              fixtures: entry.value,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({required this.roundType, required this.fixtures});

  final RoundType roundType;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roundType.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...fixtures.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BracketMatchCard(fixture: f),
              )),
        ],
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  const _BracketMatchCard({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = fixture.isCompleted;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeamSlot(
              name: fixture.homeTeamName ?? 'TBD',
              isWinner: isCompleted &&
                  fixture.result!.winner == fixture.homeTeamId,
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            _TeamSlot(
              name: fixture.awayTeamName ?? 'TBD',
              isWinner: isCompleted &&
                  fixture.result!.winner == fixture.awayTeamId,
            ),
            if (fixture.result != null) ...[
              const SizedBox(height: 4),
              Text(
                fixture.result!.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamSlot extends StatelessWidget {
  const _TeamSlot({required this.name, this.isWinner = false});

  final String name;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: isWinner
          ? BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              name[0],
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
          Icon(Icons.account_tree, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Bracket Not Ready',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The bracket will be available once knockout fixtures are generated.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
