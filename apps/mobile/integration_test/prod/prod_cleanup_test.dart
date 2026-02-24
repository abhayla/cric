/// Production cleanup: soft-delete all test teams and their rosters.
///
/// Uses DELETE /api/v1/teams/:id (soft-delete, sets isActive=false).
/// Teams and players remain in DB but won't appear in listings.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_cleanup_test.dart -d emulator-5556
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Clean up all prod test data', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== PROD CLEANUP: Deleting all test teams ===\n');

    final api = await ProdApiClient.create();

    // Get all teams
    final teams = await api.listTeams(limit: 50);
    print('Found ${teams.length} teams to delete\n');

    // Known test team names
    final testTeamNames = prodTeams.map((t) => t.name).toSet();

    var deleted = 0;
    var skipped = 0;
    for (final team in teams) {
      final name = team['name'] as String;
      final id = team['id'] as String;

      if (testTeamNames.contains(name)) {
        try {
          await api.deleteTeam(id);
          print('  [DELETED] $name ($id)');
          deleted++;
        } catch (e) {
          print('  [ERROR] Failed to delete $name: $e');
        }
      } else {
        print('  [SKIP] $name — not a test team');
        skipped++;
      }
    }

    // Verify
    final remaining = await api.listTeams(limit: 50);
    print('\n=== CLEANUP COMPLETE ===');
    print('Deleted: $deleted teams');
    print('Skipped: $skipped teams');
    print('Remaining: ${remaining.length} teams');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
