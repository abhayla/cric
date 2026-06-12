---
name: flutter-scoring-state
description: >
  Scoring presentation conventions: hand-written sentinel-based state classes
  (never Freezed), StatefulWidget pages with an immutable args class for DI,
  and UI-only data classes defined inline in the notifier file.
globs: ["apps/mobile/lib/src/features/scoring/presentation/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Scoring Presentation State Conventions

Three deliberate departures from the generic Flutter rules apply inside
`apps/mobile/lib/src/features/scoring/presentation/`. They exist because the
scoring engine's state is large, hot, and nullable-heavy — do not "fix" them
back to the generic patterns.

## 1. Large state classes are HAND-WRITTEN with a sentinel copyWith

`ScoringState` (in `presentation/notifiers/scoring_notifier.dart`, class at
~lines 119–189, copyWith from ~line 485) is a plain hand-written class — NOT
`@freezed`. Freezed's generated `copyWith` cannot distinguish "not provided"
from "explicitly set to null", which the scoring engine needs constantly
(clearing `strikerId` after a wicket, clearing `error`, clearing `target`).

The pattern:

```dart
/// Sentinel for [ScoringState.copyWith] to distinguish "not provided" from "set to null".
const _unset = Object();

ScoringState copyWith({
  Object? strikerId = _unset,
  Object? bowlerId = _unset,
  Object? error = _unset,
  // ...
}) {
  return ScoringState(
    strikerId: identical(strikerId, _unset)
        ? this.strikerId
        : strikerId as String?,
    // ...
  );
}
```

- MUST use `identical(field, _unset)` for the check, exactly as the existing
  copyWith does — NOT `==`.
- MUST NOT convert `ScoringState` (or any future large scoring state class)
  to Freezed. Freezed stays in `data/models/` only (see
  `flutter-model-entity-mapping.md`).
- When adding a nullable field, add it to BOTH the constructor and the
  sentinel copyWith — a field reachable only through the constructor cannot
  be cleared.

## 2. Scoring pages are StatefulWidget with an immutable args class

`ScoringPage` (`presentation/pages/scoring_page.dart`) is a `StatefulWidget`
taking a `ScoringPageArgs` const class (~lines 27–81) plus optional
infrastructure for DI:

```dart
class ScoringPage extends StatefulWidget {
  const ScoringPage({
    super.key,
    required this.args,
    this.datasource,    // ScoringLocalDatasource? — persistence
    this.syncService,   // SyncService? — server push
    this.wsClient,      // WebSocketClient? — live broadcast
  });
  // ...
}
```

- All 4 scoring pages follow this shape. New scoring pages MUST be
  `StatefulWidget` + args class — NOT `ConsumerWidget`.
- Generic list pages elsewhere in the app (matches list, teams list) ARE
  `ConsumerWidget` — that remains correct outside scoring. The split exists
  because scoring pages need injectable datasource/sync/ws for widget tests
  and own a long-lived imperative notifier lifecycle.
- New constructor inputs go into `ScoringPageArgs` (immutable, const
  constructor), NOT as loose positional parameters. Optional infrastructure
  (anything with a real default at runtime) goes as a nullable constructor
  field like `datasource`/`syncService`/`wsClient`.

## 3. UI-only data classes live inline at the top of the notifier file

`FallOfWicket`, `BowlerOption`, `FirstInningsSummary`, `MatchResult` (and the
`MatchResultType` enum) are defined at the top of `scoring_notifier.dart`
(~lines 15–116) with `const` constructors. They are presentation artifacts —
they never cross the network and never persist.

- UI-only view classes MUST stay in the notifier file that produces them —
  MUST NOT be moved to `data/models/` (they are not API models and need no
  Freezed/JSON machinery) and MUST NOT get `fromJson`/`toJson`.
- They MUST have `const` constructors and `final` fields.
- Small computed getters on them are fine (`BowlerOption.initials`,
  `BowlerOption.badge`, `FirstInningsSummary.scoreDisplay`).

## CRITICAL RULES

- `ScoringState` and future large scoring state classes MUST be hand-written
  with the `const _unset = Object()` sentinel copyWith — NEVER Freezed.
- Sentinel checks MUST use `identical(field, _unset)`, matching the existing
  copyWith.
- Scoring pages MUST be `StatefulWidget` with an immutable `...Args` class
  and optional `datasource`/`syncService`/`wsClient` DI parameters — NOT
  `ConsumerWidget` (which stays correct for generic list pages elsewhere).
- UI-only data classes (`FallOfWicket`-style) MUST be defined inline in the
  notifier file with const constructors — NEVER in `data/models/`.
