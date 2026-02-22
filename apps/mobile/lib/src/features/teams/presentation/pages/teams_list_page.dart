import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../domain/entities/team.dart';
import '../../providers.dart';
import '../widgets/team_card.dart';

class TeamsListPage extends ConsumerWidget {
  const TeamsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamsListProvider.notifier).refresh(),
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorDisplay(
            error: error,
            onRetry: () => ref.read(teamsListProvider.notifier).refresh(),
          ),
          data: (result) {
            if (result.teams.isEmpty) {
              return const _EmptyState();
            }
            return _TeamsGrid(teams: result.teams);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createTeam),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TeamsGrid extends StatelessWidget {
  const _TeamsGrid({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) => TeamCard(
        team: teams[index],
        onTap: () => context.push(
          AppRoutes.teamDetailPath(teams[index].id),
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
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No teams yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a team to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.createTeam),
                icon: const Icon(Icons.add),
                label: const Text('Create a Team'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

