/// Production E2E: Tournament 2 — Group + Knockout, 10 overs
///
/// Format: Group + Knockout, 10 overs, 4 groups x 4 teams, top 1 qualifies
/// Ball: Leather (ID 1), ~27 matches, ~2.5 hours
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_tournament_2_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 2: Group+KO, 10ov, 4 groups, top 1 qualifies', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    final name = randomTournamentName();
    print('\n=== TOURNAMENT 2: $name ===');
    print('Format: Group+Knockout | 10 overs | 4 groups | Top 1 qualifies\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();
    final tracker = ErrorTracker();

    await setupTournamentViaUI(
      tester: tester,
      name: name,
      format: 'group_knockout',
      oversPerMatch: 10,
      tracker: tracker,
      ballTypeId: 1, // Leather
      playersPerSide: 6,
      numGroups: 4,
      qualifyPerGroup: 1,
      groupAssignments: fourGroupAssignments,
    );

    if (tracker.hasError) {
      tracker.printSummary();
      fail('Tournament setup failed. See error tracker summary above.');
    }

    await scoreAllFixturesViaUI(
      tester: tester,
      totalOvers: 10,
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
    print('\n=== TOURNAMENT 2 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 5)));
}
