---
name: flutter-async-providers
description: >
  AsyncNotifier list notifiers must follow the loading-then-guard mutation
  pattern: Future<T> build(), AsyncValue.loading() before mutations, and
  AsyncValue.guard() wrapping every async result — never raw try/catch into state.
globs: ["apps/mobile/lib/src/features/*/providers.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# AsyncNotifier Provider Conventions

Each feature's `providers.dart` is the single source of truth for its
Riverpod providers (see `.claude/rules/flutter.md`). List-state notifiers in
this app are `AsyncNotifier` subclasses and all follow one mutation pattern.
The 3 existing list notifiers comply: `MatchesListNotifier`
(`features/scoring/providers.dart` ~lines 73–88), `TeamsListNotifier`
(`features/teams/providers.dart`), `TournamentsListNotifier`
(`features/tournaments/providers.dart`).

## The pattern (canonical example)

From `apps/mobile/lib/src/features/scoring/providers.dart`:

```dart
final matchesListProvider =
    AsyncNotifierProvider<MatchesListNotifier, MatchListResult>(
  MatchesListNotifier.new,
);

class MatchesListNotifier extends AsyncNotifier<MatchListResult> {
  @override
  Future<MatchListResult> build() async {
    return _fetchMatches();
  }

  Future<MatchListResult> _fetchMatches({int page = 1}) async {
    final repository = ref.read(matchRepositoryProvider);
    return repository.getMatches(page: page);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMatches());
  }
}
```

## The three mandatory elements

1. **`Future<T> build()`** — the initial load IS the build method. MUST NOT
   load in a constructor, an `init()` method, or a fire-and-forget call from
   the UI.
2. **`state = const AsyncValue.loading();` before mutations** — every
   user-triggered refetch/mutation first sets loading so the UI's
   `AsyncValue.when(loading: ...)` branch fires. Skipping this leaves stale
   data on screen with no progress indicator during the refetch.
3. **`state = await AsyncValue.guard(() => ...)`** — every async result is
   wrapped in `guard`, which converts thrown exceptions into
   `AsyncValue.error` with the stack trace preserved.

## What is forbidden, and what to do instead

| Forbidden | Instead |
|---|---|
| `try { state = AsyncValue.data(await fetch()); } catch (e) { state = AsyncValue.error(e, st); }` | `state = await AsyncValue.guard(() => fetch());` — same semantics, no hand-rolled catch, stack trace kept |
| `state = AsyncValue.data(await fetch());` unguarded | `AsyncValue.guard` — an unguarded await that throws leaves the notifier permanently in loading |
| Swallowing the error into a nullable field (`error = e.toString()`) | Let `guard` produce `AsyncValue.error`; the page handles it in `when(error: ...)` per `flutter.md` ("handle all AsyncValue states") |
| Fetching repository data inside the widget | Add a method on the notifier; widgets only `ref.watch(...)` and call notifier methods |

## Scope notes

- This pattern governs `AsyncNotifier` subclasses. One-shot reads
  (`matchDetailProvider`, `resumableMatchIdsProvider`) remain
  `FutureProvider`/`FutureProvider.family` — do not convert them to
  notifiers without a mutation need.
- Synchronous UI state (e.g., `MatchLiveNotifier extends Notifier`) is out of
  scope — it has no async build to guard.
- New list features MUST add their notifier to that feature's
  `providers.dart`, not a separate file.

## CRITICAL RULES

- AsyncNotifier subclasses MUST implement `Future<T> build()` as the initial
  load — no constructor/init loading.
- Every mutation/refetch MUST set `state = const AsyncValue.loading();`
  before the async call.
- Every async result MUST be assigned via
  `state = await AsyncValue.guard(() => ...)` — NEVER raw try/catch-into-state
  and NEVER an unguarded `AsyncValue.data(await ...)`.
- Widgets MUST NOT call repositories directly — they watch the provider and
  invoke notifier methods.
