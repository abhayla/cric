/// 03: Verify My Cricket tabs after standalone match.
///
/// Checks Teams, Matches, and Tournaments sub-tabs with all filter chips
/// after at least one standalone match has been played.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/03_verify_after_match_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../core/app_bootstrap.dart';
import '../verification/my_cricket_verifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Verify My Cricket tabs after standalone match', (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== VERIFY AFTER MATCH TEST ===\n');

    final stopwatch = Stopwatch()..start();

    // Verify Teams tab — scorer owns Team1 and Team2
    print('[1/3] Verifying Teams tab...');
    await verifyTeamsTab(
      tester,
      expectedMinAllTeams: 2,
      expectedOwnerTeams: ['Team1', 'Team2'],
    );

    // Verify Matches tab — at least 1 match played (standalone from test 02)
    print('\n[2/3] Verifying Matches tab...');
    await verifyMatchesTab(tester, minAllCount: 1, expectWon: true);

    // Verify Tournaments tab — no tournaments yet at this point
    print('\n[3/3] Verifying Tournaments tab...');
    await verifyTournamentsTab(tester);

    stopwatch.stop();
    print('\n=== VERIFY AFTER MATCH COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
