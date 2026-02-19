---
name: flutter-testing-patterns
description: Flutter testing templates and best practices. Quick reference for unit tests, widget tests, integration tests, BLoC testing, and mocking patterns.
---

# Flutter Testing Patterns - Quick Reference

Production-ready test templates for comprehensive test coverage.

## Unit Test Templates

### Basic Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassName', () {
    test('description of what is being tested', () {
      // Arrange
      final input = 'test input';
      final expected = 'expected output';

      // Act
      final result = functionToTest(input);

      // Assert
      expect(result, expected);
    });
  });
}
```

### Test with Setup and Teardown

```dart
void main() {
  late MyClass instance;

  setUp(() {
    // Runs before each test
    instance = MyClass();
  });

  tearDown(() {
    // Runs after each test
    instance.dispose();
  });

  test('test description', () {
    expect(instance.value, isNotNull);
  });
}
```

### Testing Future/Async

```dart
test('async function returns expected value', () async {
  // Arrange
  final repository = MyRepository();

  // Act
  final result = await repository.fetchData();

  // Assert
  expect(result, isA<List<Data>>());
  expect(result.length, greaterThan(0));
});
```

### Testing Streams

```dart
test('stream emits correct values', () {
  // Arrange
  final controller = StreamController<int>();

  // Act & Assert
  expect(
    controller.stream,
    emitsInOrder([1, 2, 3, emitsDone]),
  );

  controller.add(1);
  controller.add(2);
  controller.add(3);
  controller.close();
});
```

## Widget Test Templates

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget description', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(),
      ),
    );

    // Act (if needed)
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // Assert
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

### Test with Theme

```dart
testWidgets('widget with theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: MyWidget(),
    ),
  );

  expect(find.byType(MyWidget), findsOneWidget);
});
```

### Test with Riverpod Provider Override

```dart
testWidgets('widget with riverpod override', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProvider.overrideWithValue(AsyncValue.data(mockValue)),
      ],
      child: MaterialApp(
        home: MyWidget(),
      ),
    ),
  );

  expect(find.byType(MyWidget), findsOneWidget);
});
```

### Test User Interaction

```dart
testWidgets('button tap triggers callback', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => tapped = true,
          child: Text('Tap me'),
        ),
      ),
    ),
  );

  // Find and tap button
  await tester.tap(find.text('Tap me'));
  await tester.pump();

  expect(tapped, true);
});
```

### Test Text Input

```dart
testWidgets('text field accepts input', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextField(
          controller: controller,
          key: Key('email_field'),
        ),
      ),
    ),
  );

  // Enter text
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.pump();

  expect(controller.text, 'test@example.com');
  expect(find.text('test@example.com'), findsOneWidget);
});
```

### Test Navigation

```dart
testWidgets('navigation to detail page', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(),
      routes: {
        '/details': (context) => DetailsPage(),
      },
    ),
  );

  // Tap navigation element
  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle(); // Wait for navigation animation

  expect(find.byType(DetailsPage), findsOneWidget);
});
```

### Test Scrolling

```dart
testWidgets('list scrolls to item', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      ),
    ),
  );

  // Scroll to bottom
  await tester.scrollUntilVisible(
    find.text('Item 99'),
    500.0,
  );

  expect(find.text('Item 99'), findsOneWidget);
});
```

## Riverpod Notifier Testing Templates

### Basic Notifier Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MyNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is correct', () {
      final state = container.read(myNotifierProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('loads data successfully', () async {
      final notifier = container.read(myNotifierProvider.notifier);
      await notifier.loadData();

      final state = container.read(myNotifierProvider);
      expect(state, isA<AsyncData>());
    });
  });
}
```

### Notifier Test with Mock Dependencies

```dart
test('loads products successfully', () async {
  final mockRepository = MockProductsRepository();
  when(() => mockRepository.getProducts())
      .thenAnswer((_) async => testProducts);

  final container = ProviderContainer(
    overrides: [
      productsRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  addTearDown(container.dispose);

  // Wait for async initialization
  await container.read(productsNotifierProvider.future);

  final state = container.read(productsNotifierProvider);
  expect(state.value, testProducts);
  verify(() => mockRepository.getProducts()).called(1);
});
```

### Notifier Test with Error Handling

```dart
test('handles error when loading products fails', () async {
  final mockRepository = MockProductsRepository();
  when(() => mockRepository.getProducts())
      .thenThrow(Exception('Network error'));

  final container = ProviderContainer(
    overrides: [
      productsRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  addTearDown(container.dispose);

  // Let the notifier attempt to load
  await expectLater(
    container.read(productsNotifierProvider.future),
    throwsException,
  );

  final state = container.read(productsNotifierProvider);
  expect(state, isA<AsyncError>());
});
```

## Mock Patterns

### Mocktail Setup (Preferred)

```dart
import 'package:mocktail/mocktail.dart';

// No code generation needed — just extend Mock
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthService extends Mock implements AuthService {}
```

### Mock with Return Value

```dart
test('mock returns value', () async {
  final mockRepo = MockUserRepository();

  when(() => mockRepo.getUser('123'))
      .thenAnswer((_) async => User(id: '123', name: 'Test'));

  final user = await mockRepo.getUser('123');

  expect(user.name, 'Test');
  verify(() => mockRepo.getUser('123')).called(1);
});
```

### Mock with Exception

```dart
test('mock throws exception', () async {
  final mockRepo = MockUserRepository();

  when(() => mockRepo.getUser('123'))
      .thenThrow(Exception('User not found'));

  expect(
    () => mockRepo.getUser('123'),
    throwsException,
  );
});
```

### Mock with Any Matcher

```dart
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepo;

  setUp(() {
    mockRepo = MockUserRepository();
  });

  test('using mocktail any matcher', () async {
    when(() => mockRepo.getUser(any()))
        .thenAnswer((_) async => User(id: '1', name: 'Test'));

    final user = await mockRepo.getUser('1');

    expect(user.name, 'Test');
    verify(() => mockRepo.getUser(any())).called(1);
  });
}
```

## Integration Test Templates

### Basic Integration Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Phone OTP login flow (stub Firebase Auth in test setup)
    await tester.enterText(find.byKey(Key('phone_field')), '+919876543210');
    await tester.tap(find.byKey(Key('send_otp_button')));
    await tester.pumpAndSettle();

    // Enter OTP (stubbed to auto-verify in test)
    await tester.enterText(find.byKey(Key('otp_field')), '123456');
    await tester.tap(find.byKey(Key('verify_button')));
    await tester.pumpAndSettle();

    // Verify home page
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### Integration Test with Network

```dart
testWidgets('complete purchase flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Browse products
  await tester.tap(find.text('Products'));
  await tester.pumpAndSettle(Duration(seconds: 2)); // Wait for API

  // Add to cart
  await tester.tap(find.byKey(Key('add_to_cart_0')));
  await tester.pumpAndSettle();

  // Checkout
  await tester.tap(find.byIcon(Icons.shopping_cart));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Checkout'));
  await tester.pumpAndSettle(Duration(seconds: 3)); // Wait for payment

  expect(find.text('Order Complete'), findsOneWidget);
});
```

## Golden Test Templates

### Basic Golden Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('widget golden test', (tester) async {
    await tester.pumpWidgetBuilder(
      MyWidget(),
      wrapper: materialAppWrapper(theme: ThemeData.light()),
      surfaceSize: Size(400, 600),
    );

    await screenMatchesGolden(tester, 'my_widget');
  });
}
```

### Multi-Device Golden Test

```dart
testGoldens('responsive layout golden test', (tester) async {
  await tester.pumpWidgetBuilder(
    MyResponsiveWidget(),
    wrapper: materialAppWrapper(),
  );

  await multiScreenGolden(
    tester,
    'responsive_widget',
    devices: [
      Device.phone,
      const Device(name: 'android_pixel_5', size: Size(393, 851)),
    ],
  );
});
```

## Test Helper Patterns

### Pump Widget Helper

```dart
extension WidgetTesterX on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
  }

  Future<void> pumpWithProviderScope(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }
}
```

### Test Data Fixtures

```dart
// test/fixtures/test_data.dart
class TestData {
  static final user = User(
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
  );

  static final products = [
    Product(id: '1', name: 'Product 1', price: 9.99),
    Product(id: '2', name: 'Product 2', price: 19.99),
  ];

  static final order = Order(
    id: '1',
    userId: '1',
    items: [OrderItem(productId: '1', quantity: 2)],
    total: 19.98,
  );
}
```

## Common Test Matchers

```dart
// Equality
expect(value, equals(expected));
expect(value, isNot(equals(unexpected)));

// Types
expect(value, isA<MyClass>());
expect(value, isNull);
expect(value, isNotNull);

// Numbers
expect(value, greaterThan(5));
expect(value, lessThan(10));
expect(value, closeTo(5.0, 0.1));

// Strings
expect(value, contains('substring'));
expect(value, startsWith('prefix'));
expect(value, endsWith('suffix'));
expect(value, matches(RegExp(r'\d+')));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(3));
expect(list, contains(item));
expect(map, containsKey('key'));
expect(map, containsValue('value'));

// Widgets
expect(find.text('Hello'), findsOneWidget);
expect(find.byType(MyWidget), findsNWidgets(3));
expect(find.byKey(Key('my_key')), findsNothing);

// Exceptions
expect(() => throwingFunction(), throwsException);
expect(() => throwingFunction(), throwsA(isA<MyException>()));

// Async
await expectLater(future, completion(equals(expected)));
await expectLater(stream, emits(value));
await expectLater(stream, emitsInOrder([1, 2, 3]));
```

## Testing Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **One assertion per test**: Focus on single behavior
3. **Descriptive names**: Test names should describe what they test
4. **Mock external dependencies**: Isolate unit under test
5. **Don't test implementation details**: Test behavior, not internals
6. **Use factories for test data**: Reusable, consistent test objects
7. **Clean up resources**: Dispose controllers, close streams
8. **Test edge cases**: Empty lists, null values, errors
9. **Golden tests for UI**: Catch visual regressions
10. **Integration tests for flows**: Test complete user journeys

These patterns provide comprehensive test coverage for Flutter applications.
