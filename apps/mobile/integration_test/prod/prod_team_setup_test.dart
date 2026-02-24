/// Production E2E Test: Create 16 teams x 6+1 players via UI.
///
/// Follows the exact same process a real user would:
/// 1. Log in with phone OTP
/// 2. Navigate to Teams tab
/// 3. Create each team (fill name → submit)
/// 4. Add 6 players per team (Create New → fill name/phone/role → Add to Team)
/// 5. Add Abhay Kumar (viewer, 9999999998) to Bangalore Titans
///
/// **IMPORTANT: All actions must go through the app UI. No API shortcuts.
/// No exceptions.**
///
/// Idempotent: checks existing teams via API read and skips complete ones.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_team_setup_test.dart -d emulator-5556
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create 16 prod teams with 6 players each via UI', (tester) async {
    // Boot app and log in as scorer (9999999999)
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== PROD TEAM SETUP: 16 teams x 6 players (UI-driven) ===\n');

    final stopwatch = Stopwatch()..start();

    // API client for read-only checks (existing teams/rosters)
    final api = await ProdApiClient.create();

    // Create all 16 teams + players through the app UI
    await createAllTeamsViaUI(tester, api);

    // Verify by listing teams via API (read-only)
    final teams = await api.listTeams(limit: 50);
    print('\n=== VERIFICATION ===');
    print('Total teams found: ${teams.length}');
    for (final t in teams) {
      print('  ${t['name']}: ${t['playerCount'] ?? '?'} players');
    }

    stopwatch.stop();
    print('\n=== TEAM SETUP COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    print('Expected: ${prodTeams.length} teams, ${prodTeams.length * 6 + 1} players');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
