import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for updates feed preferences — tracks which event types are hidden.
class UpdatesPreferencesState {
  const UpdatesPreferencesState({this.hiddenEventTypes = const {}});

  final Set<String> hiddenEventTypes;

  UpdatesPreferencesState copyWith({Set<String>? hiddenEventTypes}) =>
      UpdatesPreferencesState(
        hiddenEventTypes: hiddenEventTypes ?? this.hiddenEventTypes,
      );
}

/// Notifier that manages updates feed event type filtering preferences.
///
/// Stores hidden event types in memory. Default: all events visible.
class UpdatesPreferencesNotifier extends Notifier<UpdatesPreferencesState> {
  @override
  UpdatesPreferencesState build() => const UpdatesPreferencesState();

  void toggleEventType(String eventType) {
    final current = Set<String>.from(state.hiddenEventTypes);
    if (current.contains(eventType)) {
      current.remove(eventType);
    } else {
      current.add(eventType);
    }
    state = state.copyWith(hiddenEventTypes: current);
  }

  void showAll() {
    state = state.copyWith(hiddenEventTypes: {});
  }

  void hideAll(List<String> allTypes) {
    state = state.copyWith(hiddenEventTypes: allTypes.toSet());
  }
}
