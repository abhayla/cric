/// 04: Group + Knockout Tournament — 8 teams, 2 groups, 3 overs.
///
/// ~15 matches (12 group + 2 semi + 1 final).
/// Uses Team1-Team8.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/04_tournament_gk_test.dart -d emulator-5554
/// ```
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../config/test_data.dart';
import '../config/tournament_presets.dart';
import '../core/app_bootstrap.dart';
import '../core/error_tracker.dart';
import '../flows/tournament_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Group+Knockout tournament: 8 teams, 2 groups, 3 overs',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TOURNAMENT GK TEST ===');
    print('8 teams, 2 groups, 3 overs, ~15 matches\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();
    final rng = Random();

    final name = gkPreset.generateName();

    // Setup tournament
    await setupTournament(
      tester: tester,
      preset: gkPreset,
      name: name,
      tracker: tracker,
      teams: allTeams,
      groupAssignments: gkGroupAssignments,
    );

    if (!tracker.hasError) {
      // Score all fixtures
      await scoreAllFixtures(
        tester: tester,
        teams: allTeams,
        totalOvers: gkPreset.overs,
        playersPerSide: gkPreset.playersPerSide,
        tracker: tracker,
        tournamentName: name,
        random: rng,
      );
    }

    stopwatch.stop();
    print('\n=== TOURNAMENT GK COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament GK test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 3)));
}
