/// Production E2E: Tournament 3 — Knockout Cup
///
/// Format: Knockout, 5 overs, 16 teams seeded 1-16
/// Ball: Tennis (ID 2), 15 matches, ~1 hour
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
import '../helpers/tournament_flow_helpers.dart';
import 'prod_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tournament 3: Knockout Cup (KO, 5ov, 16 teams)', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== TOURNAMENT 3: Knockout Cup ===');
    print('Format: Knockout | 5 overs | 16 teams | 15 matches\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();

    final api = await ProdApiClient.create();

    // All 16 teams, no groups
    final allTeamIndices = List.generate(16, (i) => i);

    final tournamentId = await setupTournamentViaApi(
      api: api,
      name: 'Knockout Cup',
      format: 'knockout',
      oversPerMatch: 5,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
      numGroups: 1,
      qualifyPerGroup: 1,
      teamIndices: allTeamIndices,
    );

    await navigateToTournaments(tester);
    await settle(tester);

    final tournamentCard = find.text('Knockout Cup');
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
      totalOvers: 5,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 3 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inMinutes}m ${stopwatch.elapsed.inSeconds % 60}s');
  }, timeout: const Timeout(Duration(hours: 3)));
}
