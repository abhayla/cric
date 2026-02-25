/// Production E2E: Tournament 5 — Group + Knockout, 3 overs
///
/// Format: Group + Knockout, 3 overs, 2 groups x 8 teams, top 4 qualify
/// Ball: Tape (ID 3), ~63 matches, ~3 hours
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_tournament_5_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 5: Group+KO, 3ov, 2 groups, top 4 qualify', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    final name = randomTournamentName();
    print('\n=== TOURNAMENT 5: $name ===');
    print('Format: Group+Knockout | 3 overs | 2 groups of 8 | Top 4 qualify\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();
    final tracker = ErrorTracker();

    await setupTournamentViaUI(
      tester: tester,
      name: name,
      format: 'group_knockout',
      oversPerMatch: 3,
      tracker: tracker,
      ballTypeId: 3, // Tape
      playersPerSide: 6,
      numGroups: 2,
      qualifyPerGroup: 4,
      groupAssignments: twoGroupAssignments,
    );

    if (tracker.hasError) {
      tracker.printSummary();
      fail('Tournament setup failed. See error tracker summary above.');
    }

    await scoreAllFixturesViaUI(
      tester: tester,
      totalOvers: 3,
      tracker: tracker,
      playersPerSide: 6,
      random: rng,
    );

    // Verify standings on Overview tab (G2)
    if (!tracker.hasError) {
      await verifyTournamentStandings(tester);
      tracker.recordSuccess('Standings verified on Overview tab');
    }

    stopwatch.stop();
    print('\n=== TOURNAMENT 5 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inHours}h ${stopwatch.elapsed.inMinutes % 60}m');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 5)));
}
