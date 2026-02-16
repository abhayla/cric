# Presentation Layer TDD Patterns

## What to Test
- Notifier state transition tests with mocked repository
- Test initial state, loading state, success state, error state
- Widget tests: pump with `ProviderScope` overrides, tap buttons, verify UI
- Test form validation, dialog interactions

## Async Provider Testing — Notifier State Transitions

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

## Async Widget Testing — Loading and Data States

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
