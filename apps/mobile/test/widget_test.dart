import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/app/app.dart';
import 'package:cricscores/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricscores/src/features/home/providers.dart';
import 'package:cricscores/src/features/teams/providers.dart';
import 'package:cricscores/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricscores/src/features/tournaments/providers.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';

void main() {
  testWidgets('CricScores renders with router', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override network providers to prevent real HTTP calls
          liveMatchesProvider.overrideWith(
            (ref) async =>
                const MatchListResult(matches: [], total: 0, page: 1),
          ),
          recentMatchesProvider.overrideWith(
            (ref) async =>
                const MatchListResult(matches: [], total: 0, page: 1),
          ),
          allMatchesProvider.overrideWith(
            (ref, page) async =>
                const MatchListResult(matches: [], total: 0, page: 1),
          ),
          teamsListProvider.overrideWith(
            () => _FakeTeamsNotifier(),
          ),
          tournamentsListProvider.overrideWith(
            () => _FakeTournamentsNotifier(),
          ),
        ],
        child: const CricScores(),
      ),
    );

    // Without SKIP_AUTH, app starts at splash page. Verify app renders.
    await tester.pump();
    expect(find.textContaining('Cric'), findsWidgets);
  });
}

class _FakeTeamsNotifier extends TeamsListNotifier {
  @override
  Future<TeamListResult> build() async {
    return const TeamListResult(teams: [], total: 0, page: 1);
  }
}

class _FakeTournamentsNotifier extends TournamentsListNotifier {
  @override
  Future<TournamentListResult> build() async {
    return const TournamentListResult(tournaments: [], total: 0, page: 1);
  }
}
