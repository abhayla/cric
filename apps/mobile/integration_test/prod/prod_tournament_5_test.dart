/// Production E2E: Tournament 5 — Masters Trophy
///
/// Format: Group + Knockout, 3 overs, 2 groups x 8 teams, top 4 qualify
/// Ball: Tape (ID 3), ~63 matches, ~3 hours
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
import '../helpers/tournament_flow_helpers.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 5: Masters Trophy (Group+KO, 3ov, 2 groups)', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== TOURNAMENT 5: Masters Trophy ===');
    print('Format: Group+Knockout | 3 overs | 2 groups of 8 | Top 4 qualify\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();

    final api = await ProdApiClient.create();

    final tournamentId = await setupTournamentViaApi(
      api: api,
      name: 'Masters Trophy',
      format: 'group_knockout',
      oversPerMatch: 3,
      ballTypeId: 3, // Tape
      playersPerSide: 6,
      numGroups: 2,
      qualifyPerGroup: 4,
      groupAssignments: twoGroupAssignments,
    );

    await navigateToTournaments(tester);
    await settle(tester);

    final tournamentCard = find.text('Masters Trophy');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (tournamentCard.evaluate().isNotEmpty) break;
    }
    if (tournamentCard.evaluate().isNotEmpty) {
      await tester.tap(tournamentCard.first);
      await settle(tester);
    }

    await scoreAllFixtures(
      tester: tester,
      api: api,
      tournamentId: tournamentId,
      totalOvers: 3,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 5 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inHours}h ${stopwatch.elapsed.inMinutes % 60}m');

    final standings = await api.getStandings(tournamentId);
    print('Standings entries: ${standings.length}');
    for (final s in standings) {
      print('  ${s['teamName']}: P=${s['played']} W=${s['won']} L=${s['lost']} '
          'Pts=${s['points']} NRR=${s['nrr']}');
    }
  }, timeout: const Timeout(Duration(hours: 5)));
}
