/// Production E2E: Tournament 2 — Premier League S1
///
/// Format: Group + Knockout, 10 overs, 4 groups x 4 teams, top 1 qualifies
/// Ball: Leather (ID 1), ~27 matches, ~2.5 hours
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

  testWidgets('Tournament 2: Premier League S1 (Group+KO, 10ov)', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== TOURNAMENT 2: Premier League S1 ===');
    print('Format: Group+Knockout | 10 overs | 4 groups | Top 1 qualifies\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();

    final api = await ProdApiClient.create();

    // Setup tournament entirely via UI
    await setupTournamentViaUI(
      tester: tester,
      name: 'Premier League S1',
      format: 'group_knockout',
      oversPerMatch: 10,
      ballTypeId: 1, // Leather
      playersPerSide: 6,
      numGroups: 4,
      qualifyPerGroup: 1,
      groupAssignments: fourGroupAssignments,
    );

    // Get tournament ID from API
    final tournaments = await api.listTournaments();
    final tournament = tournaments.firstWhere(
      (t) => t['name'] == 'Premier League S1',
    );
    final tournamentId = tournament['id'] as String;

    await scoreAllFixtures(
      tester: tester,
      api: api,
      tournamentId: tournamentId,
      totalOvers: 10,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 2 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');

    final standings = await api.getStandings(tournamentId);
    print('Standings entries: ${standings.length}');
    for (final s in standings) {
      print('  ${s['teamName']}: P=${s['played']} W=${s['won']} L=${s['lost']} '
          'Pts=${s['points']} NRR=${s['nrr']}');
    }
  }, timeout: const Timeout(Duration(hours: 5)));
}
