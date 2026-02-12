---
name: tdd
description: Guided TDD workflow. Enforces Red-Green-Refactor cycle per layer. Write failing tests first, then implement.
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# TDD — Test-Driven Development

Guided Red-Green-Refactor workflow for a specific feature and layer.

## Arguments

`$ARGUMENTS` should be `<feature> <layer>` where:
- `<feature>` = feature name (e.g., `auth`, `scoring`, `teams`, `tournaments`)
- `<layer>` = `domain`, `data`, `presentation`, or `all` (runs all 3 in sequence)

Examples: `/tdd auth domain`, `/tdd scoring all`, `/tdd teams data`

## Pre-Steps

1. **Read planning docs** relevant to the feature:
   - `docs/planning/SCORING_RULES.md` — if scoring feature
   - `docs/planning/DATABASE.md` — if data layer or schema-related
   - `docs/planning/API.md` — if data layer with remote datasource
   - `docs/planning/IMPLEMENTATION_PLAN.md` — current phase scope
   - `.claude/rules.md` — file placement rules

2. **Identify test file locations:**
   - Domain: `apps/mobile/test/src/features/<feature>/domain/`
   - Data: `apps/mobile/test/src/features/<feature>/data/`
   - Presentation: `apps/mobile/test/src/features/<feature>/presentation/`

3. **Identify source file locations:**
   - Domain: `apps/mobile/lib/src/features/<feature>/domain/`
   - Data: `apps/mobile/lib/src/features/<feature>/data/`
   - Presentation: `apps/mobile/lib/src/features/<feature>/presentation/`

## Phase 1: RED — Write Failing Tests

**Context isolation rule:** Do NOT read existing implementation files. Write tests against INTERFACES, SPECS, and PLANNING DOCS only.

### Domain Layer Tests
- Pure unit tests for entity behavior and validation
- Test domain logic functions (strike rotation, delivery validation, etc.)
- Test repository interface contracts (abstract method signatures)

### Data Layer Tests
- Mock datasources using `mocktail` or hand-written mocks
- Test Freezed model serialization round-trips (toJson → fromJson)
- Test repository implementations call correct datasource methods
- Test error wrapping (datasource exceptions → domain exceptions)

### Presentation Layer Tests
- Notifier state transition tests with mocked repository
- Test initial state, loading state, success state, error state
- Widget tests: pump with `ProviderScope` overrides, tap buttons, verify UI
- Test form validation, dialog interactions

### Run Tests — Confirm FAIL
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

All tests MUST FAIL. If any pass, the test is not testing new behavior — rewrite it.

Output:
```
RED PHASE COMPLETE
Tests written: X
Tests failing: X (expected — all should fail)
Test files: [list]
```

## Phase 2: GREEN — Implement to Pass

Write the minimum code to make ALL red tests pass. Do not add untested functionality.

### Implementation Order (if `all`)
1. Domain entities + repository interfaces → run domain tests
2. Freezed models + datasources + repository implementations → run data tests
3. Notifiers + pages + widgets + providers.dart → run presentation tests

### Run build_runner if needed
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

### Run Tests — Confirm PASS
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

All tests MUST PASS. If any fail, fix implementation — NOT the tests (unless the test has a genuine bug).

Output:
```
GREEN PHASE COMPLETE
Tests passing: X/X
Source files created: [list]
```

## Phase 3: REFACTOR — Clean Up

With all tests green, refactor for clarity without changing behavior:
- Extract repeated code into helper functions
- Improve naming
- Simplify complex conditionals
- Apply KISS/DRY principles

### Run Tests — Confirm Still PASS
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

If any test fails during refactor → revert the refactoring change and try a different approach.

Output:
```
REFACTOR PHASE COMPLETE
Tests still passing: X/X
Refactoring changes: [brief summary]
```

## Final Report

```
## TDD Summary: <feature> / <layer>

| Phase | Status | Details |
|-------|--------|---------|
| RED | DONE | X tests written, all failing |
| GREEN | DONE | X tests passing, Y source files |
| REFACTOR | DONE | Tests still green after cleanup |

### Files Created
- Test files: [list]
- Source files: [list]

### Coverage
- Run: `cd apps/mobile && flutter test --coverage test/src/features/<feature>/`
```

## Async Provider Testing Patterns

For Riverpod notifiers that use async operations (Dio, Drift):

### Notifier test — async state transitions

```dart
test('transitions loading → data on fetch', () async {
  when(() => mockRepo.getMatches()).thenAnswer(
    (_) async => [Match(id: '1', name: 'Test')],
  );

  final container = ProviderContainer(overrides: [
    matchRepoProvider.overrideWithValue(mockRepo),
  ]);

  // Trigger fetch
  final notifier = container.read(matchListProvider.notifier);

  // Verify loading → data transition
  await container.read(matchListProvider.future);
  expect(container.read(matchListProvider).value, hasLength(1));
});
```

### Widget test — loading and data states

```dart
testWidgets('shows loading then data', (tester) async {
  when(() => mockRepo.getMatches()).thenAnswer(
    (_) async => [Match(id: '1', name: 'Test')],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [matchRepoProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: MatchListPage()),
    ),
  );

  // Loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for async
  await tester.pumpAndSettle();

  // Data state
  expect(find.text('Test'), findsOneWidget);
});
```

**Always test both success and error paths for async operations.**

## TDD Exceptions

Skip TDD for:
- **Generated code** (*.g.dart, *.freezed.dart) — test the source, not generated output
- **Static UI with no logic** (splash screen, about page) — use screenshot verify instead
- **Configuration files** (router setup, theme constants) — test via integration tests
- **Third-party wrappers** (Firebase init, Drift database constructor) — test the layer above
