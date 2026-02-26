import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/updates/presentation/notifiers/updates_preferences_notifier.dart';
import 'package:cricscores/src/features/updates/providers.dart';

void main() {
  ProviderContainer createContainer() {
    return ProviderContainer();
  }

  group('UpdatesPreferencesNotifier', () {
    test('default state has no hidden event types', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(updatesPreferencesProvider);

      expect(state.hiddenEventTypes, isEmpty);
    });

    test('toggleEventType hides an event type', () {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(updatesPreferencesProvider.notifier).toggleEventType('century');

      final state = container.read(updatesPreferencesProvider);
      expect(state.hiddenEventTypes, contains('century'));
      expect(state.hiddenEventTypes.length, 1);
    });

    test('toggleEventType again shows the event type', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(updatesPreferencesProvider.notifier);
      notifier.toggleEventType('century');
      notifier.toggleEventType('century');

      final state = container.read(updatesPreferencesProvider);
      expect(state.hiddenEventTypes, isEmpty);
    });

    test('showAll clears all hidden event types', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(updatesPreferencesProvider.notifier);
      notifier.toggleEventType('century');
      notifier.toggleEventType('half_century');
      notifier.toggleEventType('hat_trick');

      // Verify events are hidden first
      expect(container.read(updatesPreferencesProvider).hiddenEventTypes.length, 3);

      notifier.showAll();

      final state = container.read(updatesPreferencesProvider);
      expect(state.hiddenEventTypes, isEmpty);
    });

    test('hideAll hides all provided event types', () {
      final container = createContainer();
      addTearDown(container.dispose);

      const allTypes = ['century', 'half_century', 'hat_trick', 'match_completed'];
      container.read(updatesPreferencesProvider.notifier).hideAll(allTypes);

      final state = container.read(updatesPreferencesProvider);
      expect(state.hiddenEventTypes, allTypes.toSet());
      expect(state.hiddenEventTypes.length, 4);
    });

    test('multiple toggles accumulate correctly', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(updatesPreferencesProvider.notifier);

      notifier.toggleEventType('century');
      expect(
        container.read(updatesPreferencesProvider).hiddenEventTypes,
        {'century'},
      );

      notifier.toggleEventType('half_century');
      expect(
        container.read(updatesPreferencesProvider).hiddenEventTypes,
        {'century', 'half_century'},
      );

      notifier.toggleEventType('hat_trick');
      expect(
        container.read(updatesPreferencesProvider).hiddenEventTypes,
        {'century', 'half_century', 'hat_trick'},
      );

      // Remove one
      notifier.toggleEventType('century');
      expect(
        container.read(updatesPreferencesProvider).hiddenEventTypes,
        {'half_century', 'hat_trick'},
      );
    });
  });

  group('UpdatesPreferencesState', () {
    test('copyWith creates a new state with updated hiddenEventTypes', () {
      const state = UpdatesPreferencesState(hiddenEventTypes: {'century'});
      final updated = state.copyWith(hiddenEventTypes: {'half_century', 'hat_trick'});

      expect(updated.hiddenEventTypes, {'half_century', 'hat_trick'});
      // Original unchanged
      expect(state.hiddenEventTypes, {'century'});
    });

    test('copyWith with no arguments preserves state', () {
      const state = UpdatesPreferencesState(hiddenEventTypes: {'century'});
      final copy = state.copyWith();

      expect(copy.hiddenEventTypes, {'century'});
    });
  });
}
