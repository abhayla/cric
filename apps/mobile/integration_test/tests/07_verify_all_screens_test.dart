/// 07: Verify All Screens — My Cricket, Live, Updates + tournament details.
///
/// Full verification of all screens after matches and tournaments have been played.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/07_verify_all_screens_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../core/app_bootstrap.dart';
import '../verification/live_verifier.dart';
import '../verification/my_cricket_verifier.dart';
import '../verification/updates_verifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Verify all screens: My Cricket, Live, Updates', (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== VERIFY ALL SCREENS TEST ===\n');

    final stopwatch = Stopwatch()..start();

    // 1. My Cricket — Teams tab
    print('[1/5] Verifying Teams tab...');
    await verifyTeamsTab(
      tester,
      expectedOwnerTeams: ['Team1', 'Team2', 'Team3', 'Team4'],
    );

    // 2. My Cricket — Matches tab
    print('\n[2/5] Verifying Matches tab...');
    await verifyMatchesTab(tester);

    // 3. My Cricket — Tournaments tab
    print('\n[3/5] Verifying Tournaments tab...');
    await verifyTournamentsTab(tester, expectCompleted: true);

    // 4. Live page
    print('\n[4/5] Verifying Live page...');
    await verifyLivePage(tester);

    // 5. Updates page
    print('\n[5/5] Verifying Updates page...');
    await verifyUpdatesPage(tester);

    stopwatch.stop();
    print('\n=== VERIFY ALL SCREENS COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
