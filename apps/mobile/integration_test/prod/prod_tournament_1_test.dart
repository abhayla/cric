/// Production E2E: Tournament 1 — Champions Trophy 2026
///
/// Format: Group + Knockout, 5 overs, 4 groups x 4 teams, top 2 qualify
/// Ball: Tennis (ID 2), ~31 matches, ~2 hours
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
import '../helpers/tournament_flow_helpers.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 1: Champions Trophy 2026 (Group+KO, 5ov)', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== TOURNAMENT 1: Champions Trophy 2026 ===');
    print('Format: Group+Knockout | 5 overs | 4 groups | Top 2 qualify\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();

    // Create API client
    final api = await ProdApiClient.create();

    // Setup tournament via API
    final tournamentId = await setupTournamentViaApi(
      api: api,
      name: 'Champions Trophy 2026',
      format: 'group_knockout',
      oversPerMatch: 5,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
      numGroups: 4,
      qualifyPerGroup: 2,
      groupAssignments: fourGroupAssignments,
    );

    // Navigate to tournament in UI
    await navigateToTournaments(tester);
    await settle(tester);

    // Find and tap the tournament
    final tournamentCard = find.text('Champions Trophy 2026');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (tournamentCard.evaluate().isNotEmpty) break;
    }
    if (tournamentCard.evaluate().isNotEmpty) {
      await tester.tap(tournamentCard.first);
      await settle(tester);
    }

    // Score all fixtures
    await scoreAllFixtures(
      tester: tester,
      api: api,
      tournamentId: tournamentId,
      totalOvers: 5,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 1 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');

    // Verify standings
    final standings = await api.getStandings(tournamentId);
    print('Standings entries: ${standings.length}');
    for (final s in standings) {
      print('  ${s['teamName']}: P=${s['played']} W=${s['won']} L=${s['lost']} '
          'Pts=${s['points']} NRR=${s['nrr']}');
    }
  }, timeout: const Timeout(Duration(hours: 4)));
}
