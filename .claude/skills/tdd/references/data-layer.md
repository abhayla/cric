# Data Layer TDD Patterns

## What to Test
- Mock datasources using `mocktail` or hand-written mocks
- Test Freezed model serialization round-trips (toJson → fromJson)
- Test repository implementations call correct datasource methods
- Test error wrapping (datasource exceptions → domain exceptions)

## Example: Repository Test with Mocked Datasource

```dart
test('repository calls remote datasource and maps result', () async {
  when(() => mockRemote.getMatches()).thenAnswer(
    (_) async => [MatchModel(id: '1', name: 'Test')],
  );

  final result = await repository.getMatches();

  expect(result, hasLength(1));
  expect(result.first.name, 'Test');
  verify(() => mockRemote.getMatches()).called(1);
});
```

## Example: Freezed Model Serialization Test

```dart
test('MatchModel round-trip serialization', () {
  final model = MatchModel(id: '1', name: 'Test Match');
  final json = model.toJson();
  final restored = MatchModel.fromJson(json);
  expect(restored, model);
});
```
