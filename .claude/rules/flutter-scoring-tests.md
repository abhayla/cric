---
name: flutter-scoring-tests
description: >
  Test files must mirror lib/src/ structure exactly, and test helpers are
  top-level builder factories defined inside each test file — never shared
  external test-util modules.
globs: ["apps/mobile/test/**/*_test.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Test Structure and Helper Conventions

Two conventions govern `apps/mobile/test/`: a strict mirror of the source
tree, and self-contained builder-factory helpers per test file. All 8
scoring test files comply.

## 1. Test files mirror `lib/src/` exactly

| Source file | Test file |
|---|---|
| `lib/src/features/scoring/presentation/notifiers/scoring_notifier.dart` | `test/src/features/scoring/presentation/notifiers/scoring_notifier_test.dart` |
| `lib/src/shared/data/sync/sync_service.dart` | `test/src/shared/data/sync/sync_service_test.dart` |

- A new test for `lib/src/<path>/<name>.dart` MUST live at
  `test/src/<path>/<name>_test.dart` — same directory chain, `_test` suffix.
- Cross-cutting integration tests get their own `integration/` directory
  inside the feature's mirrored path (e.g.,
  `test/src/features/scoring/integration/full_match_test.dart`) — NOT a
  top-level `test/integration/` dump.
- MUST NOT park tests at `test/` root or group them by test type
  (`test/unit/`, `test/widgets/`) — discoverability depends on the mirror.

## 2. Helpers are top-level builder factories IN the test file

Each test file defines its own `make...` factories with defaulted named
parameters, declared at the top of `main()` (or top-level), e.g.
`test/src/features/scoring/presentation/notifiers/scoring_notifier_test.dart`
(~lines 11–51):

```dart
void main() {
  /// Helper: create a default ScoringState for testing.
  ScoringState makeState({
    String matchId = 'match-1',
    String battingTeamId = 'team-a',
    int totalOvers = 20,
    int playersPerSide = 11,
    int totalRuns = 0,
    // ... every field defaulted, overridable per test
  }) {
    return ScoringState(/* ... */);
  }

  /// Helper: create a notifier with batters and bowler pre-selected.
  ScoringNotifier makeNotifier({ /* ... */ }) { /* ... */ }
  // tests follow ...
}
```

The established factory vocabulary: `makeState`, `makeNotifier`,
`makeMatchNotifier`, `makePlayers`, `transitionInnings` (see also
`test/src/features/scoring/integration/full_match_test.dart` ~lines 10–52).
Reuse these names when writing new scoring tests so the suite reads
uniformly.

## Why no shared test-util module

- MUST NOT create `test/helpers/`, `test/test_utils.dart`, or any shared
  builder module — shared test utils accrete project-wide coupling: one
  test's default change silently rewrites every other file's fixtures, and
  they violate the no-catch-all-files rule (`claude-behavior.md` rule 8).
- The cost is small duplication per file; the benefit is each test file is
  fully readable and editable in isolation. If two test files need "the same"
  helper, copy the factory and let the copies diverge with their files.
- Helpers MUST be builder factories with defaulted named parameters — every
  field overridable, sensible cricket defaults (20 overs, 11 players a side)
  baked in. MUST NOT hand-construct `ScoringState` inline in dozens of tests;
  add/extend a factory instead.

## CRITICAL RULES

- Test files MUST mirror `lib/src/` exactly:
  `lib/src/<path>/<name>.dart` → `test/src/<path>/<name>_test.dart`.
- Feature integration tests live in the feature's mirrored
  `integration/` directory — never a top-level type-based grouping.
- Test helpers MUST be top-level builder factories (`makeState`,
  `makeNotifier`, `makePlayers`, ...) defined IN the test file that uses
  them.
- MUST NOT create shared external test-util modules (`test/helpers/`,
  `test_utils.dart`) — copy the factory into the new file instead.
