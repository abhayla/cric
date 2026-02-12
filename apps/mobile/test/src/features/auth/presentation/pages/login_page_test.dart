import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/auth/presentation/pages/login_page.dart';
import 'package:cricapp/src/shared/widgets/cricket_ball_icon.dart';

void main() {
  group('LoginPage', () {
    testWidgets('renders cricket ball icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.byType(CricketBallIcon), findsOneWidget);
    });

    testWidgets('renders two-tone app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.textContaining('Cric'), findsOneWidget);
      expect(find.textContaining('App'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(
        find.text('Enter your phone number to continue'),
        findsOneWidget,
      );
    });

    testWidgets('renders phone number label and input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders country code selector with India default',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('+91'), findsOneWidget);
    });

    testWidgets('renders Send OTP button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('Send OTP button is disabled with empty phone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Send OTP button is enabled with valid phone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows error for invalid phone number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Enter invalid number (starts with 5, not 6-9)
      await tester.enterText(find.byType(TextField), '5876543210');
      await tester.pump();

      // Button should still be disabled for invalid Indian number
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders terms and privacy text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.textContaining('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);
    });
  });
}
