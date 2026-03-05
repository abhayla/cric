/// 05: Knockout Tournament — 4 teams, 2 overs, 3 matches.
///
/// Uses Team1-Team4.
///
/// Run (dev mode — local server on port 3001):
/// ```bash
/// flutter test --flavor dev integration_test/tests/05_tournament_ko_test.dart -d emulator-5554
/// ```
///
/// Run (prod mode — cricscores.in):
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/05_tournament_ko_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../config/test_data.dart';
import '../config/tournament_presets.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../core/test_utils.dart';
import '../flows/tournament_flow.dart';

void main() {
  initIntegrationTest();

  testWidgets('Knockout tournament: 4 teams, 2 overs, 3 matches',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TOURNAMENT KO TEST ===');
    print('4 teams, 2 overs, 3 matches\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();
    final rng = Random();

    final name = koPreset.generateName();

    await setupTournament(
      tester: tester,
      preset: koPreset,
      name: name,
      tracker: tracker,
      teams: allTeams,
      teamIndices: [0, 1, 2, 3], // Team1-Team4
    );

    if (!tracker.hasError) {
      await scoreAllFixtures(
        tester: tester,
        teams: allTeams,
        totalOvers: koPreset.overs,
        playersPerSide: koPreset.playersPerSide,
        tracker: tracker,
        tournamentName: name,
        random: rng,
      );
    }

    stopwatch.stop();
    print('\n=== TOURNAMENT KO COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      await takeFailureScreenshot('05_tournament_ko');
      fail('Tournament KO test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 1)));
}
