import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/auth/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage', () {
    testWidgets('renders two-tone app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      );

      // Verify both parts of the two-tone title exist
      expect(find.textContaining('Cric'), findsOneWidget);
      expect(find.textContaining('App'), findsOneWidget);

      // Verify it's a Text.rich with two styled spans
      final textFinder = find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final span = widget.textSpan;
        if (span == null || span is! TextSpan) return false;
        return span.children != null && span.children!.length == 2;
      });
      expect(textFinder, findsOneWidget);
    });

    testWidgets('renders tagline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      );

      expect(
        find.text('Score every ball. Own every moment.'),
        findsOneWidget,
      );
    });

    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has centered layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      );

      expect(find.byType(Column), findsOneWidget);
    });
  });
}
