/// Production E2E: Tournament 1 — Group + Knockout, 5 overs
///
/// Format: Group + Knockout, 5 overs, 4 groups x 4 teams, top 2 qualify
/// Ball: Tennis (ID 2), ~31 matches, ~2 hours
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_tournament_1_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 1: Group+KO, 5ov, 4 groups, top 2 qualify', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    final name = randomTournamentName();
    print('\n=== TOURNAMENT 1: $name ===');
    print('Format: Group+Knockout | 5 overs | 4 groups | Top 2 qualify\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();
    final tracker = ErrorTracker();

    // Setup tournament entirely via UI
    await setupTournamentViaUI(
      tester: tester,
      name: name,
      format: 'group_knockout',
      oversPerMatch: 5,
      tracker: tracker,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
      numGroups: 4,
      qualifyPerGroup: 2,
      groupAssignments: fourGroupAssignments,
    );

    if (tracker.hasError) {
      tracker.printSummary();
      fail('Tournament setup failed. See error tracker summary above.');
    }

    // Score all fixtures via UI
    await scoreAllFixturesViaUI(
      tester: tester,
      totalOvers: 5,
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
    print('\n=== TOURNAMENT 1 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 4)));
}
