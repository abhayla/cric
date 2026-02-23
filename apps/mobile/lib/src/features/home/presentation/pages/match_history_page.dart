import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cricscores/src/features/home/providers.dart';
import '../widgets/match_card.dart';

/// Match history page showing list of all matches.
class MatchHistoryPage extends ConsumerWidget {
  const MatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allMatches = ref.watch(allMatchesProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allMatchesProvider(1));
        },
        child: allMatches.when(
          data: (data) {
            if (data.matches.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_cricket_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matches yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a match to see your history here',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Start a Match'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: data.matches.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final match = data.matches[index];
                return MatchCard(
                  match: match,
                  onTap: () {
                    // Navigate to match detail/scorecard
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Something went wrong. Pull to refresh.\n\nerror: $error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
