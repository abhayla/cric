import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/errors/exceptions.dart';
import 'package:cricscores/src/shared/widgets/error_display.dart';

void main() {
  Widget buildWidget(Object error, {VoidCallback? onRetry}) {
    return MaterialApp(
      home: Scaffold(
        body: ErrorDisplay(
          error: error,
          onRetry: onRetry ?? () {},
        ),
      ),
    );
  }

  group('ErrorDisplay', () {
    testWidgets('shows network error message for NetworkException',
        (tester) async {
      await tester.pumpWidget(buildWidget(const NetworkException()));
      expect(
        find.text('No internet connection. Please check your network and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows session expired message for AuthException',
        (tester) async {
      await tester.pumpWidget(buildWidget(const AuthException()));
      expect(
        find.text('Session expired. Please log in again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows session expired message for ServerException with 401',
        (tester) async {
      await tester
          .pumpWidget(buildWidget(const ServerException('err', null, 401)));
      expect(
        find.text('Session expired. Please log in again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows permission error for ServerException with 403',
        (tester) async {
      await tester
          .pumpWidget(buildWidget(const ServerException('err', null, 403)));
      expect(
        find.text("You don't have permission for this action."),
        findsOneWidget,
      );
    });

    testWidgets('shows not found error for ServerException with 404',
        (tester) async {
      await tester
          .pumpWidget(buildWidget(const ServerException('err', null, 404)));
      expect(
        find.text('The requested data was not found.'),
        findsOneWidget,
      );
    });

    testWidgets('shows server error for ServerException with 500+',
        (tester) async {
      await tester
          .pumpWidget(buildWidget(const ServerException('err', null, 500)));
      expect(
        find.text('Something went wrong on our end. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows generic error for unknown exception', (tester) async {
      await tester.pumpWidget(buildWidget(Exception('random')));
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Retry button and calls onRetry when tapped',
        (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        buildWidget(
          const NetworkException(),
          onRetry: () => retryCalled = true,
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(buildWidget(const NetworkException()));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
