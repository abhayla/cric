# Domain Layer TDD Patterns

## What to Test
- Pure unit tests for entity behavior and validation
- Test domain logic functions (strike rotation, delivery validation, etc.)
- Test repository interface contracts (abstract method signatures)

## Context Isolation
Do NOT read existing implementation files. Write tests against INTERFACES, SPECS, and PLANNING DOCS only.

## Example: Entity Validation Test

```dart
test('Match entity requires at least 2 players per side', () {
  expect(
    () => Match(id: '1', playersPerSide: 1),
    throwsA(isA<ArgumentError>()),
  );
});
```

## Example: Domain Logic Function Test

```dart
test('rotateStrike swaps on odd runs', () {
  final state = ScoringState(strikerId: 'a', nonStrikerId: 'b');
  final result = rotateStrike(state, runsScored: 3);
  expect(result.strikerId, 'b');
  expect(result.nonStrikerId, 'a');
});
```
