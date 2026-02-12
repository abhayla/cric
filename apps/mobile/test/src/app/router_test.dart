import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/router.dart';

void main() {
  group('AppRoutes', () {
    test('splash is root path', () {
      expect(AppRoutes.splash, '/');
    });

    test('auth routes have correct paths', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.otp, '/otp');
      expect(AppRoutes.profileSetup, '/profile-setup');
    });

    test('main tab routes have correct paths', () {
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.matches, '/matches');
      expect(AppRoutes.tournaments, '/tournaments');
      expect(AppRoutes.teams, '/teams');
      expect(AppRoutes.profile, '/profile');
    });

    test('all 9 routes defined', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.otp,
        AppRoutes.profileSetup,
        AppRoutes.home,
        AppRoutes.matches,
        AppRoutes.tournaments,
        AppRoutes.teams,
        AppRoutes.profile,
      ];
      expect(routes.length, 9);
      expect(routes.toSet().length, 9); // All unique
    });
  });
}
