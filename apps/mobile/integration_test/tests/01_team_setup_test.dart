/// 01: Team Setup — Create 12 teams with 11 players each (check-then-skip).
///
/// Idempotent: safe to re-run. Teams that already exist are skipped.
/// Team1 includes Abhay (9999999998) as an extra roster member.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/01_team_setup_test.dart -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../config/test_data.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../flows/team_setup_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create 12 teams with 11 players each (check-then-skip)',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TEAM SETUP TEST ===');
    print('Creating ${allTeams.length} teams with 11 players each\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();

    await ensureTeamsExist(tester, allTeams, tracker);

    stopwatch.stop();
    print('\n=== TEAM SETUP COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Team setup had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
