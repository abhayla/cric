/// Production E2E: Tournament 3 — Knockout, 5 overs
///
/// Format: Knockout, 5 overs, 16 teams seeded 1-16
/// Ball: Tennis (ID 2), 15 matches, ~1 hour
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_tournament_3_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 3: Knockout, 5ov, 16 teams', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    final name = randomTournamentName();
    print('\n=== TOURNAMENT 3: $name ===');
    print('Format: Knockout | 5 overs | 16 teams | 15 matches\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();
    final tracker = ErrorTracker();

    // All 16 teams, no groups
    final allTeamIndices = List.generate(16, (i) => i);

    await setupTournamentViaUI(
      tester: tester,
      name: name,
      format: 'knockout',
      oversPerMatch: 5,
      tracker: tracker,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
      teamIndices: allTeamIndices,
    );

    if (tracker.hasError) {
      tracker.printSummary();
      fail('Tournament setup failed. See error tracker summary above.');
    }

    await scoreAllFixturesViaUI(
      tester: tester,
      totalOvers: 5,
      tracker: tracker,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 3 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 3)));
}
