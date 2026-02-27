import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/fixture.dart';
import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';
import 'package:cricscores/src/shared/widgets/pulsing_live_dot.dart';

void main() {
  Widget buildTestWidget(Fixture fixture) {
    return MaterialApp(
      home: Scaffold(
        body: FixtureCard(fixture: fixture),
      ),
    );
  }

  Fixture makeFixture({String? matchStatus, FixtureResult? result}) {
    return Fixture(
      id: 'fix-1',
      tournamentId: 'tourn-1',
      roundNumber: 1,
      roundType: RoundType.group,
      fixtureOrder: 1,
      homeTeamId: 'team-1',
      awayTeamId: 'team-2',
      homeTeamName: 'Mumbai',
      awayTeamName: 'Chennai',
      matchStatus: matchStatus,
      result: result,
    );
  }

  group('FixtureCard', () {
    testWidgets('shows LIVE badge with PulsingLiveDot when matchStatus is live',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeFixture(matchStatus: 'live')));

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.byType(PulsingLiveDot), findsOneWidget);
    });

    testWidgets(
        'shows LIVE badge when matchStatus is innings_break',
        (tester) async {
      await tester
          .pumpWidget(buildTestWidget(makeFixture(matchStatus: 'innings_break')));

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.byType(PulsingLiveDot), findsOneWidget);
    });

    testWidgets('shows Upcoming when matchStatus is null and not completed',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeFixture()));

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
      expect(find.byType(PulsingLiveDot), findsNothing);
    });

    testWidgets('shows neither LIVE nor Upcoming when completed',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeFixture(
        matchStatus: 'completed',
        result: const FixtureResult(winner: 'team-1', summary: 'Mumbai won'),
      )));

      expect(find.text('LIVE'), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
      expect(find.text('Mumbai won'), findsOneWidget);
    });

    testWidgets('displays team names', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeFixture()));

      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Chennai'), findsOneWidget);
    });
  });
}
