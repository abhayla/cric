import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cricapp/src/app/router.dart';
import '../../domain/entities/activity_event.dart';
import '../../providers.dart';
import '../widgets/activity_event_card.dart';

/// Activity feed page showing grouped events.
class UpdatesPage extends ConsumerWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(activityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityFeedProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: feedAsync.when(
          data: (result) {
            if (result.events.isEmpty) {
              return _EmptyState(theme: theme);
            }

            final grouped = _groupByDate(result.events);

            return ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        group.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...group.events.map(
                      (event) => ActivityEventCard(
                        event: event,
                        onTap: () => _onEventTap(context, ref, event),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 8),
                Text('Failed to load updates',
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(activityFeedProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onEventTap(BuildContext context, WidgetRef ref, ActivityEvent event) {
    // Mark as read
    if (!event.isRead) {
      ref.read(updatesRepositoryProvider).markAsRead([event.id]);
      ref.invalidate(activityFeedProvider);
      ref.invalidate(unreadCountProvider);
    }

    // Navigate to referenced entity
    if (event.referenceId == null || event.referenceType == null) return;

    switch (event.referenceType) {
      case 'match':
        context.push(AppRoutes.scorecardPath(event.referenceId!));
      case 'team':
        context.push(AppRoutes.teamDetailPath(event.referenceId!));
      case 'tournament':
        context.push(AppRoutes.tournamentDetailPath(event.referenceId!));
      case 'player':
        context.push(AppRoutes.playerProfilePath(event.referenceId!));
    }
  }

  List<_DateGroup> _groupByDate(List<ActivityEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    final todayEvents = <ActivityEvent>[];
    final yesterdayEvents = <ActivityEvent>[];
    final thisWeekEvents = <ActivityEvent>[];
    final olderEvents = <ActivityEvent>[];

    for (final event in events) {
      final eventDate =
          DateTime(event.createdAt.year, event.createdAt.month, event.createdAt.day);
      if (eventDate == today) {
        todayEvents.add(event);
      } else if (eventDate == yesterday) {
        yesterdayEvents.add(event);
      } else if (eventDate.isAfter(thisWeekStart) ||
          eventDate == thisWeekStart) {
        thisWeekEvents.add(event);
      } else {
        olderEvents.add(event);
      }
    }

    return [
      if (todayEvents.isNotEmpty) _DateGroup('Today', todayEvents),
      if (yesterdayEvents.isNotEmpty) _DateGroup('Yesterday', yesterdayEvents),
      if (thisWeekEvents.isNotEmpty) _DateGroup('This Week', thisWeekEvents),
      if (olderEvents.isNotEmpty) _DateGroup('Earlier', olderEvents),
    ];
  }
}

class _DateGroup {
  const _DateGroup(this.label, this.events);
  final String label;
  final List<ActivityEvent> events;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.notifications_none,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'No Updates Yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Activity from your matches, teams, and\ntournaments will appear here',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
