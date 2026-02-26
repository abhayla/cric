import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_event.dart';
import '../../providers.dart';

/// Settings sub-tab for the Updates screen.
///
/// Shows grouped event type toggles so users can filter their feed.
class UpdatesSettingsTab extends ConsumerWidget {
  const UpdatesSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(updatesPreferencesProvider);
    final notifier = ref.read(updatesPreferencesProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // All / None buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: notifier.showAll,
                child: const Text('All'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    notifier.hideAll(ActivityEvent.allEventTypes),
                child: const Text('None'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Grouped event type toggles
        ...ActivityEvent.eventTypeGroups.entries.map(
          (group) => _EventTypeGroup(
            title: group.key,
            eventTypes: group.value,
            hiddenTypes: prefs.hiddenEventTypes,
            onToggle: notifier.toggleEventType,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _EventTypeGroup extends StatelessWidget {
  const _EventTypeGroup({
    required this.title,
    required this.eventTypes,
    required this.hiddenTypes,
    required this.onToggle,
    required this.theme,
  });

  final String title;
  final List<String> eventTypes;
  final Set<String> hiddenTypes;
  final void Function(String) onToggle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...eventTypes.map(
          (type) => SwitchListTile(
            title: Text(ActivityEvent.eventTypeLabel(type)),
            value: !hiddenTypes.contains(type),
            onChanged: (_) => onToggle(type),
            dense: true,
          ),
        ),
      ],
    );
  }
}
