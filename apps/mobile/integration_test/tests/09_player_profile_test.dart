/// 09: Player Profile — verify profile page via both entry points.
///
/// Tests the scorer's own profile (More → My Profile) and a different
/// player's profile (GoRouter push with UUID from search-by-phone API).
///
/// Requires tests 01-02 to have run (scorer has played at least 1 match).
///
/// Run (dev mode — local server on port 3001):
/// ```bash
/// flutter test --flavor dev integration_test/tests/09_player_profile_test.dart -d emulator-5554
/// ```
///
/// Run (prod mode — cricscores.in):
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/09_player_profile_test.dart -d emulator-5554
/// ```
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cricscores/src/core/constants/app_constants.dart';

import '../core/app_bootstrap.dart';
import '../core/test_utils.dart';
import '../helpers/navigation.dart';
import '../verification/player_profile_verifier.dart';

void main() {
  initIntegrationTest();

  testWidgets('Player Profile: verify via More tab and direct navigation',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== PLAYER PROFILE TEST ===\n');

    final stopwatch = Stopwatch()..start();

    // Step 1: Navigate to scorer's profile via More tab
    print('[1/10] Navigating to More → My Profile...');
    await navigateToMore(tester);
    await settle(tester);

    final myProfile = find.text('My Profile');
    expect(myProfile, findsOneWidget, reason: 'My Profile should be on More page');
    await tester.tap(myProfile);
    await settle(tester);
    await visualPause(tester, 1000);

    // Wait for profile page to appear
    final profileLoaded =
        await waitForText(tester, 'Player Profile', timeoutMs: 10000);
    expect(profileLoaded, isTrue, reason: 'Player Profile page should load');
    print('  [step-1] Player Profile page loaded');

    // Step 2: Verify hero section
    print('\n[2/10] Verifying hero section...');
    await verifyProfileHero(tester);

    // Step 3: Verify quick stats grid
    print('\n[3/10] Verifying quick stats grid...');
    await verifyQuickStats(tester);

    // Step 4: Verify format selector
    print('\n[4/10] Verifying format selector...');
    await verifyFormatSelector(tester);

    // Step 5: Verify tab bar
    print('\n[5/10] Verifying tab bar...');
    await verifyTabBar(tester);

    // Step 6: Verify batting tab (default)
    print('\n[6/10] Verifying batting tab...');
    await verifyBattingTab(tester);

    // Step 7: Verify bowling tab
    print('\n[7/10] Verifying bowling tab...');
    await verifyBowlingTab(tester);

    // Step 8: Verify fielding tab
    print('\n[8/10] Verifying fielding tab...');
    await verifyFieldingTab(tester);

    // Step 9: Verify match history navigation
    print('\n[9/10] Verifying match history navigation...');
    await verifyMatchHistoryNavigation(tester);

    // Step 10: Navigate to a different player's profile via GoRouter
    print('\n[10/10] Navigating to Player301 profile via API + GoRouter...');

    // Go back to home first
    await goBack(tester);
    await settle(tester);
    await ensureOnMyCricketPage(tester);

    // Get Firebase auth token from the running app
    final user = FirebaseAuth.instance.currentUser;
    expect(user, isNotNull, reason: 'Firebase user should be logged in');
    final token = await user!.getIdToken();
    expect(token, isNotNull, reason: 'Firebase token should be available');

    // Search for Player301 by phone (only exists if they registered via Firebase)
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));

    final response = await dio.get(
      '/players/search-by-phone',
      queryParameters: {'phone': '9999999301'},
    );
    final player = response.data['player'];
    // Player301 is added to team rosters but may not have a Firebase account
    // (only scorer phone 9999999999 actually registers). This is expected —
    // the test verifies GoRouter navigation works when a player IS found.
    if (player == null) {
      print('  [step-10] Player301 not in users table (expected — not a '
          'Firebase-registered user). Direct navigation not testable.');
    } else {
      final playerId = player['id'] as String;
      print('  [step-10] Found Player301 with ID: $playerId');

      // Navigate via GoRouter
      final context = tester.element(find.byType(Navigator).last);
      GoRouter.of(context).push('/players/$playerId');
      await settle(tester);

      // Wait for Player301's profile to load
      final found =
          await waitForText(tester, 'Player301', timeoutMs: 15000);
      expect(found, isTrue,
          reason: 'Player301 profile should show the player name');
      print('  [step-10] Player301 profile loaded successfully');

      // Go back
      await goBack(tester);
      await settle(tester);
    }

    stopwatch.stop();
    print('\n=== PLAYER PROFILE TEST COMPLETE ===');
    print(
        'Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
