/// 06: Round Robin Tournament — 4 teams, 3 overs, 6 matches.
///
/// Uses Team1-Team4.
///
/// Run:
/// ```bash
/// flutter test --flavor prod --dart-define=FLAVOR=prod \
///   integration_test/tests/06_tournament_rr_test.dart -d emulator-5554
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

  testWidgets('Round Robin tournament: 4 teams, 3 overs, 6 matches',
      (tester) async {
    await pumpAppAndWaitForHome(tester);

    print('\n=== TOURNAMENT RR TEST ===');
    print('4 teams, 3 overs, 6 matches\n');

    final stopwatch = Stopwatch()..start();
    final tracker = ErrorTracker();
    final rng = Random();

    final name = rrPreset.generateName();

    await setupTournament(
      tester: tester,
      preset: rrPreset,
      name: name,
      tracker: tracker,
      teams: allTeams,
      teamIndices: [0, 1, 2, 3], // Team1-Team4
    );

    if (!tracker.hasError) {
      await scoreAllFixtures(
        tester: tester,
        teams: allTeams,
        totalOvers: rrPreset.overs,
        playersPerSide: rrPreset.playersPerSide,
        tracker: tracker,
        tournamentName: name,
        random: rng,
      );
    }

    stopwatch.stop();
    print('\n=== TOURNAMENT RR COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
    tracker.printSummary();

    if (tracker.hasError) {
      fail('Tournament RR test had errors. See tracker summary above.');
    }
  }, timeout: const Timeout(Duration(hours: 2)));
}
