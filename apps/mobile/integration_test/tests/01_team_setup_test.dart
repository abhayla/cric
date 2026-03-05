/// 01: Team Setup — Create 12 teams with 11 players each (check-then-skip).
///
/// Idempotent: safe to re-run. Teams that already exist are skipped.
/// Team1 includes Abhay (9999999998) as an extra roster member.
///
/// ## Test Ordering Dependencies
///
/// Tests are numbered and must run in order on a shared server/DB state:
///
/// - **01** Team Setup — Creates teams + rosters. Required by all subsequent tests.
/// - **02** Standalone Match — Creates & scores a match. Independent of 03+.
/// - **03** Verify After Match — Verifies My Cricket state after 02. Requires 02.
/// - **04** Tournament GK — Group+Knockout tournament. Requires 01 (teams).
/// - **05** Tournament KO — Knockout tournament. Requires 01 (teams).
/// - **06** Tournament RR — Round Robin tournament. Requires 01 (teams).
/// - **07** Verify All Screens — Full screen sweep. Requires 01-06 for data.
/// - **08** Viewer Live — Multi-device WebSocket test. Requires 01 (teams).
///
/// Run (dev mode — local server on port 3001):
/// ```bash
/// flutter test --flavor dev integration_test/tests/01_team_setup_test.dart -d emulator-5554
/// ```
///
/// Run (prod mode — cricscores.in):
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/01_team_setup_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';

import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../flows/team_setup_flow.dart';

void main() {
  initIntegrationTest();

  testWidgets('Create 12 teams with 11 players each (check-then-skip)',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TEAM SETUP TEST ===');
    print('Creating ${allTeams.length} teams with 11 players each\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();

    await ensureTeamsExist(tester, allTeams, tracker);

    // Test removing a player from Team12
    if (!tracker.hasError) {
      await testRemovePlayer(tester, tracker);
    }

    stopwatch.stop();
    print('\n=== TEAM SETUP COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Team setup had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
