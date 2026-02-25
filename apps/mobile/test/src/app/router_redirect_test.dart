import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/app/providers.dart';
import 'package:cricscores/src/app/router.dart';

class MockUser extends Mock implements User {}

void main() {
  group('Router redirect logic', () {
    late GoRouter router;

    GoRouter buildRouter(AsyncValue<User?> authState) {
      return GoRouter(
        initialLocation: '/',
        redirect: (context, state) {
          final isLoggedIn = authState.value != null;
          final isLoading = authState.isLoading;
          final hasError = authState.hasError;
          final currentPath = state.matchedLocation;

          // While auth state is loading, stay on splash
          if (isLoading && !hasError) {
            return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
          }

          final isOnSplash = currentPath == AppRoutes.splash;
          final isAuthRoute = currentPath == AppRoutes.login ||
              currentPath == AppRoutes.otp ||
              isOnSplash;

          // Not logged in → go to login (unless already on login/otp)
          if (!isLoggedIn) {
            if (isOnSplash) return AppRoutes.login;
            return isAuthRoute ? null : AppRoutes.login;
          }

          // Logged in but on auth route → go to home
          if (isAuthRoute) {
            return AppRoutes.home;
          }

          return null;
        },
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (_, __) =>
                const Scaffold(body: Text('Splash')),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (_, __) =>
                const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: AppRoutes.otp,
            builder: (_, __) =>
                const Scaffold(body: Text('OTP')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/teams/:teamId',
            builder: (_, __) =>
                const Scaffold(body: Text('Team Detail')),
          ),
        ],
      );
    }

    testWidgets('redirects to login when not authenticated and on splash',
        (tester) async {
      router = buildRouter(const AsyncValue.data(null));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets(
        'redirects to login when not authenticated and on protected route',
        (tester) async {
      router = buildRouter(const AsyncValue.data(null));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Try to navigate to a protected route
      router.go('/teams/abc');
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets(
        'stays on login when not authenticated and already on login',
        (tester) async {
      router = buildRouter(const AsyncValue.data(null));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Should already be on login (redirected from splash)
      expect(find.text('Login'), findsOneWidget);

      // Navigate explicitly to login
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('redirects to home when authenticated and on splash',
        (tester) async {
      final mockUser = MockUser();
      router = buildRouter(AsyncValue.data(mockUser));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('redirects to home when authenticated and on login',
        (tester) async {
      final mockUser = MockUser();
      router = buildRouter(AsyncValue.data(mockUser));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Try navigating to login
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('stays on protected route when authenticated',
        (tester) async {
      final mockUser = MockUser();
      router = buildRouter(AsyncValue.data(mockUser));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.go('/teams/abc');
      await tester.pumpAndSettle();

      expect(find.text('Team Detail'), findsOneWidget);
    });

    testWidgets('stays on splash when auth is loading', (tester) async {
      router = buildRouter(const AsyncValue.loading());

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Splash'), findsOneWidget);
    });
  });
}
