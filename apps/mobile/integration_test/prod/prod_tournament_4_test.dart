/// Production E2E: Tournament 4 — Round Robin, 5 overs
///
/// Format: Round Robin, 5 overs, 16 teams, all play each other
/// Ball: Tennis (ID 2), 120 matches, ~7 hours
///
/// This is the longest tournament — 120 matches. Each team plays 15 matches.
///
/// 100% UI-driven — zero API calls. Error tracking with stop-on-first-error.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/prod/prod_tournament_4_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/app_test_wrapper.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 4: Round Robin, 5ov, 120 matches', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);

    final name = randomTournamentName();
    print('\n=== TOURNAMENT 4: $name ===');
    print('Format: Round Robin | 5 overs | 16 teams | 120 matches\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();
    final tracker = ErrorTracker();

    await setupTournamentViaUI(
      tester: tester,
      name: name,
      format: 'round_robin',
      oversPerMatch: 5,
      tracker: tracker,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
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
    print('\n=== TOURNAMENT 4 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inHours}h ${stopwatch.elapsed.inMinutes % 60}m');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 10)));
}
