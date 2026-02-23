import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/teams/domain/entities/team.dart';
import 'package:cricscores/src/features/teams/presentation/widgets/player_row.dart';

void main() {
  Widget buildTestWidget(RosterEntry entry) {
    return MaterialApp(
      home: Scaffold(
        body: PlayerRow(entry: entry),
      ),
    );
  }

  RosterEntry makeEntry({bool isVerified = false}) {
    return RosterEntry(
      id: 'r1',
      playerId: 'p1',
      displayName: 'Virat Kohli',
      rosterRole: RosterRole.player,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      isVerified: isVerified,
    );
  }

  group('PlayerRow', () {
    testWidgets('displays player name', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeEntry()));

      expect(find.text('Virat Kohli'), findsOneWidget);
    });

    testWidgets('shows Unverified badge for isVerified: false',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeEntry(isVerified: false)));

      expect(find.text('Unverified'), findsOneWidget);
    });

    testWidgets('does not show Unverified badge for isVerified: true',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeEntry(isVerified: true)));

      expect(find.text('Unverified'), findsNothing);
    });
  });
}
