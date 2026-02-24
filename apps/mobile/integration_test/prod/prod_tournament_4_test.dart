/// Production E2E: Tournament 4 — Super League
///
/// Format: Round Robin, 5 overs, 16 teams, all play each other
/// Ball: Tennis (ID 2), 120 matches, ~7 hours
///
/// This is the longest tournament — 120 matches. Each team plays 15 matches.
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

  testWidgets('Tournament 4: Super League (Round Robin, 5ov, 120 matches)', (tester) async {
    await AppTestWrapper.pumpAppAndWaitForHome(tester);
    print('\n=== TOURNAMENT 4: Super League ===');
    print('Format: Round Robin | 5 overs | 16 teams | 120 matches\n');

    final stopwatch = Stopwatch()..start();
    final rng = Random();

    final api = await ProdApiClient.create();

    // Setup tournament entirely via UI
    await setupTournamentViaUI(
      tester: tester,
      name: 'Super League',
      format: 'round_robin',
      oversPerMatch: 5,
      ballTypeId: 2, // Tennis
      playersPerSide: 6,
    );

    // Get tournament ID from API
    final tournaments = await api.listTournaments();
    final tournament = tournaments.firstWhere(
      (t) => t['name'] == 'Super League',
    );
    final tournamentId = tournament['id'] as String;

    await scoreAllFixtures(
      tester: tester,
      api: api,
      tournamentId: tournamentId,
      totalOvers: 5,
      playersPerSide: 6,
      random: rng,
    );

    stopwatch.stop();
    print('\n=== TOURNAMENT 4 COMPLETE ===');
    print('Duration: ${stopwatch.elapsed.inHours}h ${stopwatch.elapsed.inMinutes % 60}m');

    final standings = await api.getStandings(tournamentId);
    print('Final standings (${standings.length} teams):');
    for (final s in standings) {
      print('  ${s['teamName']}: P=${s['played']} W=${s['won']} L=${s['lost']} '
          'Pts=${s['points']} NRR=${s['nrr']}');
    }
  }, timeout: const Timeout(Duration(hours: 10)));
}
