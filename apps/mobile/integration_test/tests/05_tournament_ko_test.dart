/// 05: Knockout Tournament — 8 teams, 3 overs, 7 matches.
///
/// Uses Team1-Team8.
///
/// Run:
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
import '../flows/tournament_flow.dart';

void main() {
  initIntegrationTest();

  testWidgets('Knockout tournament: 8 teams, 3 overs, 7 matches',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TOURNAMENT KO TEST ===');
    print('8 teams, 3 overs, 7 matches\n');

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
      teamIndices: [0, 1, 2, 3, 4, 5, 6, 7], // Team1-Team8
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
      fail('Tournament KO test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 2)));
}
