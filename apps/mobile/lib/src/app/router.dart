import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/profile_setup_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/match_history_page.dart';
import '../features/updates/presentation/pages/updates_page.dart';
import '../features/live/presentation/pages/live_page.dart';
import '../features/more/presentation/pages/more_page.dart';
import '../features/more/presentation/pages/settings_page.dart';
import '../features/more/presentation/pages/about_page.dart';
import '../features/more/presentation/pages/help_page.dart';
import '../features/teams/presentation/pages/add_player_page.dart';
import '../features/teams/presentation/pages/create_team_page.dart';
import '../features/teams/presentation/pages/team_detail_page.dart';
import '../features/scoring/presentation/notifiers/toss_notifier.dart';
import '../features/scoring/presentation/pages/match_setup_page.dart';
import '../features/scoring/domain/entities/playing_xi_player.dart';
import '../features/scoring/presentation/pages/scoring_page.dart';
import '../features/scoring/presentation/pages/live_match_page.dart';
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
import '../features/player_profile/presentation/pages/player_profile_page.dart';
import '../features/player_profile/presentation/pages/player_match_history_page.dart';
import '../features/auth/providers.dart' as auth;
import '../features/auth/presentation/notifiers/auth_notifier.dart';
import '../features/teams/providers.dart' as teams;
import '../features/scoring/providers.dart' as scoring;
import '../shared/providers/websocket_provider.dart';
import 'providers.dart';

/// Opt-in auth bypass: only active when built with `--dart-define=SKIP_AUTH=true`.
/// Never use in externally-distributed builds.
const bool _kSkipAuth = bool.fromEnvironment('SKIP_AUTH');

/// Route paths.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String updates = '/updates';
  static const String liveHub = '/live-hub';
  static const String matches = '/matches';
  static const String tournaments = '/tournaments';
  static const String teams = '/teams';
  static const String profile = '/profile';
  static const String more = '/more';
  static const String settings = '/more/settings';
  static const String about = '/more/about';
  static const String help = '/more/help';
  static const String createTeam = '/teams/create';
  static const String teamDetail = '/teams/:teamId';
  static const String addPlayer = '/teams/:teamId/add-player';
  static const String matchSetup = '/match-setup';
  static const String toss = '/toss/:matchId';
  static const String scoring = '/scoring/:matchId';
  static const String scorecard = '/scorecard/:matchId';
  static const String liveMatch = '/live/:matchId';
  static const String createTournament = '/tournaments/create';
  static const String tournamentDetail = '/tournaments/:tournamentId';
  static const String tournamentStandings =
      '/tournaments/:tournamentId/standings';
  static const String tournamentBracket =
      '/tournaments/:tournamentId/bracket';
  static const String tournamentLeaderboard =
      '/tournaments/:tournamentId/leaderboard';
  static const String playerProfile = '/players/:playerId';
  static const String playerMatchHistory = '/players/:playerId/matches';

  /// Build team detail path with actual ID.
  static String teamDetailPath(String teamId) => '/teams/$teamId';

  /// Build add player path with actual ID.
  static String addPlayerPath(String teamId) => '/teams/$teamId/add-player';

  /// Build toss path with actual match ID.
  static String tossPath(String matchId) => '/toss/$matchId';

  /// Build scoring path with actual match ID.
  static String scoringPath(String matchId) => '/scoring/$matchId';

  /// Build scorecard path with actual match ID.
  static String scorecardPath(String matchId) => '/scorecard/$matchId';

  /// Build live match path with actual match ID.
  static String liveMatchPath(String matchId) => '/live/$matchId';

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

  /// Build player profile path with actual ID.
  static String playerProfilePath(String playerId) => '/players/$playerId';

  /// Build player match history path with actual ID.
  static String playerMatchHistoryPath(String playerId) =>
      '/players/$playerId/matches';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Cache for route extra data that GoRouter loses on rebuild/refresh.
/// When GoRouter's refreshListenable fires (e.g., auth state changes), all
/// route builders re-execute. GoRouter can only reconstruct routes from URLs,
/// so `state.extra` becomes null on rebuild. This cache preserves the extra
/// data across rebuilds, keyed by matched route path.
/// Capped at 10 entries to prevent unbounded memory growth.
const _kMaxCacheSize = 10;
final _routeExtraCache = <String, Object>{};
final _routeExtraCacheOrder = <String>[];

/// Get or cache typed route extra data. On first navigation (non-null extra),
/// stores it. On GoRouter rebuild (null extra), returns the cached value.
/// Evicts oldest entries when cache exceeds [_kMaxCacheSize].
T? _cachedRouteExtra<T extends Object>(String path, Object? extra) {
  if (extra is T) {
    // Remove existing entry if present (will be re-added at end)
    _routeExtraCacheOrder.remove(path);
    _routeExtraCache[path] = extra;
    _routeExtraCacheOrder.add(path);
    // Evict oldest entries if over limit
    while (_routeExtraCacheOrder.length > _kMaxCacheSize) {
      final oldest = _routeExtraCacheOrder.removeAt(0);
      _routeExtraCache.remove(oldest);
    }
    return extra;
  }
  final cached = _routeExtraCache[path];
  return cached is T ? cached : null;
}

/// Notifier that triggers GoRouter.refresh() when auth state changes.
/// This avoids recreating the GoRouter (and its GlobalKeys) on every auth event.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    _sub = ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }

  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// go_router provider with auth-based redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authNotifier,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Opt-in auth bypass: only when built with --dart-define=SKIP_AUTH=true
      if (_kSkipAuth) {
        final currentPath = state.matchedLocation;
        if (currentPath == AppRoutes.splash ||
            currentPath == AppRoutes.login ||
            currentPath == AppRoutes.otp) {
          return AppRoutes.home;
        }
        return null;
      }

      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);
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
        // Always leave splash once auth is resolved
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
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(auth.authNotifierProvider);
            final isLoading = authState.status == AuthStatus.sendingOtp;

            // Show error via snackbar
            ref.listen(auth.authNotifierProvider, (prev, next) {
              if (next.status == AuthStatus.error &&
                  next.errorMessage != null &&
                  prev?.status != AuthStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(next.errorMessage!)),
                );
              }
            });

            return Stack(
              children: [
                LoginPage(
                  onSendOtp: (fullPhone) {
                    ref.read(auth.authNotifierProvider.notifier).sendOtp(fullPhone).then((success) {
                      if (success && context.mounted) {
                        GoRouter.of(context).go(AppRoutes.otp, extra: fullPhone);
                      }
                    });
                  },
                ),
                if (isLoading)
                  const ColoredBox(
                    color: Color(0x40000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(auth.authNotifierProvider);
              final isVerifying = authState.status == AuthStatus.verifyingOtp;

              // Show error via snackbar
              ref.listen(auth.authNotifierProvider, (prev, next) {
                if (next.status == AuthStatus.error &&
                    next.errorMessage != null &&
                    prev?.status != AuthStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(next.errorMessage!)),
                  );
                }
              });

              return Stack(
                children: [
                  OtpPage(
                    phoneNumber: phoneNumber,
                    onVerify: (otp) {
                      // Call verifyOtp — on success, Firebase auth state
                      // changes and GoRouter redirect navigates to /home.
                      ref.read(auth.authNotifierProvider.notifier).verifyOtp(otp);
                    },
                    onResend: () {
                      ref.read(auth.authNotifierProvider.notifier).resendOtp();
                    },
                  ),
                  if (isVerifying)
                    const ColoredBox(
                      color: Color(0x40000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
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
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => CreateTeamPage(
            onSubmit: (name, location, logoFile) async {
              try {
                String? logoUrl;
                if (logoFile != null) {
                  try {
                    logoUrl = await ref.read(teams.teamRepositoryProvider)
                        .uploadImage(logoFile);
                  } catch (_) {
                    // Non-fatal: proceed without logo
                  }
                }
                final team = await ref.read(teams.teamRepositoryProvider)
                    .createTeam(name: name, location: location, logoUrl: logoUrl);
                // Invalidate the teams list so the picker shows this new team.
                ref.invalidate(teams.teamsListProvider);
                if (context.mounted) {
                  GoRouter.of(context).go(AppRoutes.teamDetailPath(team.id));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create team: $e')),
                  );
                }
              }
            },
          ),
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
        path: AppRoutes.addPlayer,
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return Consumer(
            builder: (context, ref, _) => AddPlayerPage(
              teamId: teamId,
              onCreatePlayer: (name, phone, role, batting, bowling) async {
                try {
                  final repo = ref.read(teams.teamRepositoryProvider);
                  final player = await repo.createPlayer(
                    displayName: name,
                    phone: phone,
                    playerRole: role,
                    battingStyle: batting,
                    bowlingStyle: bowling,
                  );
                  await repo.addPlayer(teamId, playerId: player.id);
                  ref.invalidate(teams.teamDetailProvider(teamId));
                  if (context.mounted) {
                    GoRouter.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add player: $e')),
                    );
                  }
                }
              },
              onAddExisting: (playerId) async {
                try {
                  await ref.read(teams.teamRepositoryProvider)
                      .addPlayer(teamId, playerId: playerId);
                  ref.invalidate(teams.teamDetailProvider(teamId));
                  if (context.mounted) {
                    GoRouter.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add player: $e')),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.matchSetup,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return Consumer(
            builder: (context, ref, _) => MatchSetupPage(
              initialHomeTeamId: extra['homeTeamId'] as String?,
              initialHomeTeamName: extra['homeTeamName'] as String?,
              initialAwayTeamId: extra['awayTeamId'] as String?,
              initialAwayTeamName: extra['awayTeamName'] as String?,
              initialOvers: extra['totalOvers'] as int?,
              initialPlayersPerSide: extra['playersPerSide'] as int?,
              onMatchCreated: (
                matchId, {
                required String homeTeamId,
                required String homeTeamName,
                required String awayTeamId,
                required String awayTeamName,
                required int playersPerSide,
                required int totalOvers,
                required int wideRuns,
                required int noBallRuns,
                required List<int>? magicOverNumbers,
                required int magicOverRunMultiplier,
                required int magicOverWicketPenalty,
              }) async {
                // Fetch team rosters for the toss page
                final teamRepo = ref.read(teams.teamRepositoryProvider);
                // Use team data passed from MatchSetupPage._state (preferred over stale
                // extra, which may be empty when navigating from Home → Match Setup).
                final homeId = homeTeamId.isNotEmpty ? homeTeamId : extra['homeTeamId'] as String?;
                final awayId = awayTeamId.isNotEmpty ? awayTeamId : extra['awayTeamId'] as String?;
                String resolvedHomeName = homeTeamName.isNotEmpty ? homeTeamName : extra['homeTeamName'] as String? ?? '';
                String resolvedAwayName = awayTeamName.isNotEmpty ? awayTeamName : extra['awayTeamName'] as String? ?? '';

                List<RosterPlayer> homeRoster = [];
                List<RosterPlayer> awayRoster = [];

                // Try to fetch rosters from the teams already in state
                try {
                  if (homeId != null) {
                    final homeDetail = await teamRepo.getTeam(homeId);
                    resolvedHomeName = homeDetail.team.name;
                    homeRoster = homeDetail.roster
                        .map((r) => RosterPlayer(
                              playerId: r.playerId,
                              displayName: r.displayName,
                              playerRole: r.playerRole?.label,
                              isCaptain: r.isCaptain,
                              isKeeper: r.isKeeper,
                            ))
                        .toList();
                  }
                  if (awayId != null) {
                    final awayDetail = await teamRepo.getTeam(awayId);
                    resolvedAwayName = awayDetail.team.name;
                    awayRoster = awayDetail.roster
                        .map((r) => RosterPlayer(
                              playerId: r.playerId,
                              displayName: r.displayName,
                              playerRole: r.playerRole?.label,
                              isCaptain: r.isCaptain,
                              isKeeper: r.isKeeper,
                            ))
                        .toList();
                  }
                } catch (_) {
                  // Proceed with empty rosters — toss page can still work
                }

                if (context.mounted) {
                  GoRouter.of(context).go(
                    AppRoutes.tossPath(matchId),
                    extra: <String, dynamic>{
                      'homeTeamId': homeId ?? '',
                      'homeTeamName': resolvedHomeName,
                      'awayTeamId': awayId ?? '',
                      'awayTeamName': resolvedAwayName,
                      'playersPerSide': playersPerSide,
                      'homeRoster': homeRoster,
                      'awayRoster': awayRoster,
                      'totalOvers': totalOvers,
                      'wideRuns': wideRuns,
                      'noBallRuns': noBallRuns,
                      'magicOverNumbers': magicOverNumbers,
                      'magicOverRunMultiplier': magicOverRunMultiplier,
                      'magicOverWicketPenalty': magicOverWicketPenalty,
                    },
                  );
                }
              },
              onNavigateToCreateTeam: () {
                GoRouter.of(context).push(AppRoutes.createTeam);
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.toss,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final data = _cachedRouteExtra<Map<String, dynamic>>(
            state.matchedLocation, state.extra,
          ) ?? {};
          return Consumer(
            builder: (context, ref, _) => TossPage(
              matchId: matchId,
              homeTeamId: data['homeTeamId'] as String? ?? '',
              homeTeamName: data['homeTeamName'] as String? ?? '',
              awayTeamId: data['awayTeamId'] as String? ?? '',
              awayTeamName: data['awayTeamName'] as String? ?? '',
              playersPerSide: data['playersPerSide'] as int? ?? 11,
              homeRoster: data['homeRoster'] as List<RosterPlayer>? ?? [],
              awayRoster: data['awayRoster'] as List<RosterPlayer>? ?? [],
              onStartMatch: (tossState) async {
                // Capture references before async gap to avoid deactivated widget errors
                final matchRepo = ref.read(scoring.matchRepositoryProvider);
                final router = GoRouter.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  if (kDebugMode) {
                    debugPrint('[onStartMatch] Starting match $matchId...');
                  }

                  // 1. Set Playing XI for both teams
                  await matchRepo.setPlayingXI(
                    matchId,
                    tossState.toHomePlayingXIInput(),
                  );
                  if (kDebugMode) {
                    debugPrint('[onStartMatch] Home XI set, calling setPlayingXI for away...');
                  }
                  await matchRepo.setPlayingXI(
                    matchId,
                    tossState.toAwayPlayingXIInput(),
                  );
                  if (kDebugMode) {
                    debugPrint('[onStartMatch] Away XI set, recording toss...');
                  }

                  // 2. Record toss (returns updated match with innings)
                  await matchRepo.recordToss(
                    matchId,
                    tossState.toRecordTossInput(),
                  );
                  if (kDebugMode) {
                    debugPrint('[onStartMatch] Toss recorded, building args...');
                  }

                  // 3. Build ScoringPageArgs from toss state
                  final battingXI = tossState.battingXI;
                  final fieldingXI = tossState.fieldingXI;
                  final nonStrikerId = tossState.openingBatterIds
                      .firstWhere((id) => id != tossState.strikerId);

                  final striker = battingXI.firstWhere(
                    (p) => p.playerId == tossState.strikerId,
                  );
                  final nonStriker = battingXI.firstWhere(
                    (p) => p.playerId == nonStrikerId,
                  );
                  final bowler = fieldingXI.firstWhere(
                    (p) => p.playerId == tossState.openingBowlerId,
                  );

                  final args = ScoringPageArgs(
                    matchId: matchId,
                    inningsId: '$matchId-inn-1',
                    battingTeamId: tossState.battingTeamId!,
                    bowlingTeamId: tossState.fieldingTeamId!,
                    battingTeamName: tossState.battingTeamName!,
                    bowlingTeamName: tossState.fieldingTeamName!,
                    inningsNumber: 1,
                    totalOvers: data['totalOvers'] as int? ?? 20,
                    playersPerSide: tossState.playersPerSide,
                    wideRunsPenalty: data['wideRuns'] as int? ?? 1,
                    noBallRunsPenalty: data['noBallRuns'] as int? ?? 1,
                    magicOverNumbers: data['magicOverNumbers'] as List<int>?,
                    magicOverRunMultiplier: data['magicOverRunMultiplier'] as int? ?? 2,
                    magicOverWicketPenalty: data['magicOverWicketPenalty'] as int? ?? -5,
                    battingTeamPlayers: battingXI
                        .map((p) => PlayingXIPlayer(
                              playerId: p.playerId,
                              displayName: p.displayName,
                              playerRole: p.playerRole,
                            ))
                        .toList(),
                    bowlingTeamPlayers: fieldingXI
                        .map((p) => PlayingXIPlayer(
                              playerId: p.playerId,
                              displayName: p.displayName,
                              playerRole: p.playerRole,
                            ))
                        .toList(),
                    openingStrikerId: tossState.strikerId!,
                    openingStrikerName: striker.displayName,
                    openingNonStrikerId: nonStrikerId,
                    openingNonStrikerName: nonStriker.displayName,
                    openingBowlerId: tossState.openingBowlerId!,
                    openingBowlerName: bowler.displayName,
                  );

                  if (kDebugMode) {
                    debugPrint('[onStartMatch] Args built, navigating to scoring page...');
                  }
                  router.go(
                    AppRoutes.scoringPath(matchId),
                    extra: args,
                  );
                } catch (e, stack) {
                  if (kDebugMode) {
                    debugPrint('[onStartMatch] ERROR: $e');
                    debugPrint('[onStartMatch] Stack: $stack');
                  }
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to start match: $e')),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scoring,
        builder: (context, state) {
          final args = _cachedRouteExtra<ScoringPageArgs>(
            state.matchedLocation, state.extra,
          );
          if (args != null) {
            return ScoringPage(
              args: args,
              datasource: ref.read(scoring.scoringLocalDatasourceProvider),
              syncService: ref.read(scoring.syncServiceProvider),
              wsClient: ref.read(websocketClientProvider),
            );
          }
          // Fallback: navigate home if no args (shouldn't happen in normal flow)
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: AppRoutes.scorecard,
        builder: (context, state) {
          final data = _cachedRouteExtra<ScorecardData>(
            state.matchedLocation, state.extra,
          );
          if (data != null) {
            return ScorecardPage(data: data);
          }
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: AppRoutes.liveMatch,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return LiveMatchPage(matchId: matchId);
        },
      ),
      GoRoute(
        path: AppRoutes.matches,
        builder: (context, state) => const MatchHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.teams,
        builder: (context, state) => const TeamsListPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _CurrentUserProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.tournaments,
        builder: (context, state) => const TournamentsListPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpPage(),
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
      GoRoute(
        path: AppRoutes.playerProfile,
        builder: (context, state) {
          final playerId = state.pathParameters['playerId']!;
          return PlayerProfilePage(playerId: playerId);
        },
      ),
      GoRoute(
        path: AppRoutes.playerMatchHistory,
        builder: (context, state) {
          final playerId = state.pathParameters['playerId']!;
          return PlayerMatchHistoryPage(playerId: playerId);
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
            path: AppRoutes.updates,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UpdatesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.liveHub,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LivePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.more,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MorePage(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Bottom navigation shell with 4 tabs.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.updates,
    AppRoutes.liveHub,
    AppRoutes.more,
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
            icon: Icon(Icons.sports_cricket_outlined),
            selectedIcon: Icon(Icons.sports_cricket),
            label: 'My Cricket',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.cell_tower_outlined),
            selectedIcon: Icon(Icons.cell_tower),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// Wraps PlayerProfilePage with current user's server-assigned UUID.
class _CurrentUserProfilePage extends ConsumerWidget {
  const _CurrentUserProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    return userIdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (userId) {
        if (userId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('Not logged in')),
          );
        }
        return PlayerProfilePage(playerId: userId);
      },
    );
  }
}
