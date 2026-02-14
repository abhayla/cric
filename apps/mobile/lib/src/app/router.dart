import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/profile_setup_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/match_history_page.dart';
import '../features/teams/presentation/pages/add_player_page.dart';
import '../features/teams/presentation/pages/create_team_page.dart';
import '../features/teams/presentation/pages/manage_roster_page.dart';
import '../features/teams/presentation/pages/team_detail_page.dart';
import '../features/scoring/presentation/notifiers/toss_notifier.dart';
import '../features/scoring/presentation/pages/match_setup_page.dart';
import '../features/scoring/presentation/pages/scoring_page.dart';
import '../features/scoring/presentation/pages/scorecard_page.dart';
import '../features/scoring/domain/entities/scorecard_data.dart';
import '../features/scoring/presentation/pages/toss_page.dart';
import '../features/teams/presentation/pages/teams_list_page.dart';
import '../features/tournaments/presentation/pages/create_tournament_page.dart';
import '../features/tournaments/presentation/pages/knockout_bracket_page.dart';
import '../features/tournaments/presentation/pages/standings_page.dart';
import '../features/tournaments/presentation/pages/tournament_detail_page.dart';
import '../features/tournaments/presentation/pages/tournament_leaderboard_page.dart';
import '../features/tournaments/presentation/pages/tournaments_list_page.dart';
import 'providers.dart';

/// Route paths.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String matches = '/matches';
  static const String tournaments = '/tournaments';
  static const String teams = '/teams';
  static const String profile = '/profile';
  static const String createTeam = '/teams/create';
  static const String teamDetail = '/teams/:teamId';
  static const String manageRoster = '/teams/:teamId/roster';
  static const String addPlayer = '/teams/:teamId/roster/add';
  static const String matchSetup = '/match-setup';
  static const String toss = '/toss/:matchId';
  static const String scoring = '/scoring/:matchId';
  static const String scorecard = '/scorecard/:matchId';
  static const String createTournament = '/tournaments/create';
  static const String tournamentDetail = '/tournaments/:tournamentId';
  static const String tournamentStandings =
      '/tournaments/:tournamentId/standings';
  static const String tournamentBracket =
      '/tournaments/:tournamentId/bracket';
  static const String tournamentLeaderboard =
      '/tournaments/:tournamentId/leaderboard';

  /// Build team detail path with actual ID.
  static String teamDetailPath(String teamId) => '/teams/$teamId';

  /// Build manage roster path with actual ID.
  static String manageRosterPath(String teamId) => '/teams/$teamId/roster';

  /// Build add player path with actual ID.
  static String addPlayerPath(String teamId) => '/teams/$teamId/roster/add';

  /// Build toss path with actual match ID.
  static String tossPath(String matchId) => '/toss/$matchId';

  /// Build scoring path with actual match ID.
  static String scoringPath(String matchId) => '/scoring/$matchId';

  /// Build scorecard path with actual match ID.
  static String scorecardPath(String matchId) => '/scorecard/$matchId';

  /// Build tournament detail path.
  static String tournamentDetailPath(String id) => '/tournaments/$id';

  /// Build tournament standings path.
  static String tournamentStandingsPath(String id) =>
      '/tournaments/$id/standings';

  /// Build tournament bracket path.
  static String tournamentBracketPath(String id) =>
      '/tournaments/$id/bracket';

  /// Build tournament leaderboard path.
  static String tournamentLeaderboardPath(String id) =>
      '/tournaments/$id/leaderboard';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// go_router provider with auth-based redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      // While auth state is loading, stay on splash
      if (isLoading) {
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthRoute = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.otp ||
          currentPath == AppRoutes.splash;

      // Not logged in → go to login (unless already on auth route)
      if (!isLoggedIn) {
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
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          onSendOtp: (fullPhone) {
            GoRouter.of(context).go(
              AppRoutes.otp,
              extra: fullPhone,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return OtpPage(
            phoneNumber: phoneNumber,
            onVerify: (otp) {
              // After OTP verification, navigate to profile setup or home
              // This will be handled by auth state change via redirect
              GoRouter.of(context).go(AppRoutes.profileSetup);
            },
            onResend: () {
              // Re-trigger OTP send via datasource (wired in later phases)
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => ProfileSetupPage(
          onSave: (data) {
            // Profile saved → navigate to home (auth redirect handles this)
            GoRouter.of(context).go(AppRoutes.home);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.createTeam,
        builder: (context, state) => CreateTeamPage(
          onSubmit: (name, location) {
            // TODO: Call API to create team, then navigate to team detail
            GoRouter.of(context).pop();
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.teamDetail,
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return TeamDetailPage(teamId: teamId);
        },
      ),
      GoRoute(
        path: AppRoutes.manageRoster,
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return ManageRosterPage(teamId: teamId);
        },
      ),
      GoRoute(
        path: AppRoutes.addPlayer,
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return AddPlayerPage(
            teamId: teamId,
            onCreatePlayer: (name, phone, role, batting, bowling) {
              // TODO: Call API to create player and add to team
              GoRouter.of(context).pop();
            },
            onAddExisting: (playerId) {
              // TODO: Call API to add existing player to team
              GoRouter.of(context).pop();
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.matchSetup,
        builder: (context, state) => MatchSetupPage(
          onMatchCreated: (matchId) {
            // After match created, navigate to toss page
            // Toss page data will be passed via extra
            final tossData = state.extra as Map<String, dynamic>?;
            GoRouter.of(context).go(
              AppRoutes.tossPath(matchId),
              extra: tossData,
            );
          },
          onNavigateToCreateTeam: () {
            GoRouter.of(context).push(AppRoutes.createTeam);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.toss,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final data = state.extra as Map<String, dynamic>? ?? {};
          return TossPage(
            matchId: matchId,
            homeTeamId: data['homeTeamId'] as String? ?? '',
            homeTeamName: data['homeTeamName'] as String? ?? '',
            awayTeamId: data['awayTeamId'] as String? ?? '',
            awayTeamName: data['awayTeamName'] as String? ?? '',
            playersPerSide: data['playersPerSide'] as int? ?? 11,
            homeRoster: data['homeRoster'] as List<RosterPlayer>? ?? [],
            awayRoster: data['awayRoster'] as List<RosterPlayer>? ?? [],
            onStartMatch: () {
              // Navigate to scoring page with args passed via extra
              final args = state.extra as Map<String, dynamic>? ?? {};
              GoRouter.of(context).go(
                AppRoutes.scoringPath(matchId),
                extra: args,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scoring,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final args = state.extra as ScoringPageArgs?;
          if (args != null) {
            return ScoringPage(args: args);
          }
          // Fallback: navigate home if no args (shouldn't happen in normal flow)
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: AppRoutes.scorecard,
        builder: (context, state) {
          final data = state.extra as ScorecardData?;
          if (data != null) {
            return ScorecardPage(data: data);
          }
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: AppRoutes.createTournament,
        builder: (context, state) => CreateTournamentPage(
          onCreated: (tournamentId) {
            GoRouter.of(context).go(
              AppRoutes.tournamentDetailPath(tournamentId),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.tournamentDetail,
        builder: (context, state) {
          final id = state.pathParameters['tournamentId']!;
          return TournamentDetailPage(tournamentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tournamentStandings,
        builder: (context, state) {
          final id = state.pathParameters['tournamentId']!;
          return StandingsPage(tournamentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tournamentBracket,
        builder: (context, state) {
          final id = state.pathParameters['tournamentId']!;
          return KnockoutBracketPage(tournamentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tournamentLeaderboard,
        builder: (context, state) {
          final id = state.pathParameters['tournamentId']!;
          return TournamentLeaderboardPage(tournamentId: id);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.matches,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MatchHistoryPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.tournaments,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TournamentsListPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.teams,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeamsListPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage('Profile'),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Bottom navigation shell with 5 tabs.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.matches,
    AppRoutes.tournaments,
    AppRoutes.teams,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexOf(location).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          GoRouter.of(context).go(_tabs[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket_outlined),
            selectedIcon: Icon(Icons.sports_cricket),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Tourneys',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Temporary placeholder pages until real screens are built.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
