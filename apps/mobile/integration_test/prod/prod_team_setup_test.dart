/// Production E2E Test: Create 16 teams x 6 players via UI.
///
/// Follows the exact same process a real user would:
/// 1. Log in with phone OTP
/// 2. Navigate to Teams tab
/// 3. Create each team (fill name -> submit)
/// 4. Add 6 players per team (Create New -> fill name/phone/role -> Add to Team)
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
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
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== PROD TEAM SETUP: 16 teams x 6 players (UI-driven) ===\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();

    // Create all 16 teams + players through the app UI
    await createAllTeamsViaUI(tester, tracker);

    stopwatch.stop();
    print('\n=== TEAM SETUP COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Team setup had errors. See tracker summary above.');
    }

    expect(tracker.teamsCreated, equals(prodTeams.length));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
