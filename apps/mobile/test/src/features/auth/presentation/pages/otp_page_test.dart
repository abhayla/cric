import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/auth/presentation/pages/otp_page.dart';

void main() {
  group('OtpPage', () {
    testWidgets('renders Verify OTP app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      expect(find.text('Verify OTP'), findsOneWidget);
    });

    testWidgets('renders Enter Verification Code heading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      expect(find.text('Enter Verification Code'), findsOneWidget);
    });

    testWidgets('displays masked phone number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      expect(find.textContaining('+91'), findsOneWidget);
      expect(find.textContaining('3210'), findsOneWidget);
    });

    testWidgets('renders 6 OTP input fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      // Should find exactly 6 TextField widgets for OTP digits
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('renders countdown timer text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    testWidgets('renders Verify button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      expect(find.text('Verify'), findsOneWidget);
    });

    testWidgets('Verify button disabled when OTP incomplete', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('resend button appears after countdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OtpPage(phoneNumber: '+919876543210')),
      );

      // Initially shows countdown, not resend button
      expect(find.textContaining('Resend code in'), findsOneWidget);
      expect(find.text('Resend Code'), findsNothing);

      // Fast-forward 30 seconds
      await tester.pump(const Duration(seconds: 30));

      expect(find.text('Resend Code'), findsOneWidget);
    });
  });
}
