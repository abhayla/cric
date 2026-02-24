/// Production E2E Test: Create 16 teams x 6 players via UI.
///
/// This test creates all 16 teams through the regular app UI flow.
/// Idempotent: skips teams that already exist.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_team_setup_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create 16 prod teams with 6 players each', (tester) async {
    // Boot app and log in as scorer (9999999999)
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== PROD TEAM SETUP: 16 teams x 6 players ===\n');

    final stopwatch = Stopwatch()..start();

    // Create all 16 teams via UI
    await createAllTeamsViaUI(tester);

    stopwatch.stop();
    print('\n=== TEAM SETUP COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    print('Teams: ${prodTeams.length}');
    print('Players: ${prodTeams.length * 6}');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
