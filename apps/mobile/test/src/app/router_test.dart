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
      expect(AppRoutes.teams, '/teams');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.more, '/more');
    });

    test('more sub-routes have correct paths', () {
      expect(AppRoutes.settings, '/more/settings');
      expect(AppRoutes.about, '/more/about');
      expect(AppRoutes.help, '/more/help');
    });

    test('team detail route paths', () {
      expect(AppRoutes.createTeam, '/teams/create');
      expect(AppRoutes.teamDetail, '/teams/:teamId');
      expect(AppRoutes.teamDetailPath('abc-123'), '/teams/abc-123');
    });

    test('add player route path', () {
      expect(AppRoutes.addPlayer, '/teams/:teamId/add-player');
      expect(
        AppRoutes.addPlayerPath('abc-123'),
        '/teams/abc-123/add-player',
      );
    });

    test('match setup route path', () {
      expect(AppRoutes.matchSetup, '/match-setup');
    });

    test('toss route path', () {
      expect(AppRoutes.toss, '/toss/:matchId');
      expect(AppRoutes.tossPath('match-456'), '/toss/match-456');
    });

    test('tournaments route path', () {
      expect(AppRoutes.tournaments, '/tournaments');
    });

    test('all routes defined', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.otp,
        AppRoutes.profileSetup,
        AppRoutes.home,
        AppRoutes.matches,
        AppRoutes.teams,
        AppRoutes.profile,
        AppRoutes.more,
        AppRoutes.settings,
        AppRoutes.about,
        AppRoutes.help,
        AppRoutes.createTeam,
        AppRoutes.teamDetail,
        AppRoutes.addPlayer,
        AppRoutes.matchSetup,
        AppRoutes.toss,
        AppRoutes.tournaments,
      ];
      expect(routes.length, 18);
      expect(routes.toSet().length, 18); // All unique
    });
  });
}
