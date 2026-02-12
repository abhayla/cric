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

    test('team detail route paths', () {
      expect(AppRoutes.createTeam, '/teams/create');
      expect(AppRoutes.teamDetail, '/teams/:teamId');
      expect(AppRoutes.teamDetailPath('abc-123'), '/teams/abc-123');
    });

    test('manage roster and add player route paths', () {
      expect(AppRoutes.manageRoster, '/teams/:teamId/roster');
      expect(AppRoutes.addPlayer, '/teams/:teamId/roster/add');
      expect(
        AppRoutes.manageRosterPath('abc-123'),
        '/teams/abc-123/roster',
      );
      expect(
        AppRoutes.addPlayerPath('abc-123'),
        '/teams/abc-123/roster/add',
      );
    });

    test('all 13 routes defined', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.otp,
        AppRoutes.profileSetup,
        AppRoutes.home,
        AppRoutes.matches,
        AppRoutes.tournaments,
        AppRoutes.teams,
        AppRoutes.createTeam,
        AppRoutes.teamDetail,
        AppRoutes.manageRoster,
        AppRoutes.addPlayer,
        AppRoutes.profile,
      ];
      expect(routes.length, 13);
      expect(routes.toSet().length, 13); // All unique
    });
  });
}
