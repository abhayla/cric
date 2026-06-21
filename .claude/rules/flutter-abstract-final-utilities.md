---
name: flutter-abstract-final-utilities
description: >
  Stateless utility, constant, and theme holders in the CricScores Flutter app MUST be
  declared `abstract final class` — never `class`, `final class` alone, or a top-level
  collection of loose functions — so they can never be instantiated or subclassed and read
  as pure namespaces of static members.
globs: ["apps/mobile/lib/src/core/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# `abstract final class` for Static-Only Holders

Every class in `lib/src/core/` that holds only static members — pure functions, constants,
or theme values — is declared `abstract final class`. This is a deliberate, consistent choice
across the core layer (7+ files) and new core utilities MUST match it.

## The pattern

```dart
abstract final class ScoringUtils {
  static bool isLegalDelivery(BallType type) => ...;
  static int calculateTotalRuns(Delivery d) => ...;
}

abstract final class CricketConstants {
  static const maxOvers = 50;
}
```

Reference files: `core/utils/scoring_utils.dart`, `core/utils/cricket_utils.dart`,
`core/utils/validators.dart`, `core/constants/app_constants.dart`,
`core/constants/cricket_constants.dart`, `core/theme/app_colors.dart`,
`core/theme/app_theme.dart`.

## Rules

- A core class that exposes only static members MUST be `abstract final class`.
  - `abstract` makes instantiation a compile error (there is no reason to `new` a namespace).
  - `final` forbids subclassing/`implements`/`mixin`, so the namespace can't be extended or
    faked. Together they pin the type to "a bag of statics" and nothing else.
- MUST NOT declare these as plain `class`, `final class` alone, or `abstract class` alone —
  each leaves one of the two escape hatches (instantiation or subtyping) open.
- MUST NOT add instance fields, a constructor, or instance methods to such a class. If state
  or injected dependencies appear, it is no longer a static holder — promote it to a Riverpod
  provider / notifier instead (see `flutter-scoring-state`, `flutter-async-providers`).
- Cricket/scoring constants (dismissal types, ball types, fielding positions) belong in one
  of these constant holders or in seed data — never hardcoded at call sites (see the DRY rule
  in CLAUDE.md).

## Why not top-level functions?

Dart allows top-level functions, but this project groups related pure helpers under a named
`abstract final class` so call sites read `ScoringUtils.isLegalDelivery(...)` — the namespace
documents which subsystem a helper belongs to and keeps `core/` import surfaces tidy. Match
the surrounding file: helpers that already live in a holder MUST be added to that holder, not
split out as loose top-level functions.
