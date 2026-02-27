import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/teams/domain/entities/team.dart';
import 'package:cricscores/src/features/teams/presentation/widgets/team_card.dart';
import 'package:cricscores/src/shared/widgets/pulsing_live_dot.dart';

void main() {
  Widget buildTestWidget(Team team) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 200,
          child: TeamCard(team: team),
        ),
      ),
    );
  }

  Team makeTeam({int liveMatchCount = 0}) {
    return Team(
      id: 'team-1',
      name: 'Mumbai Warriors',
      createdBy: 'user-1',
      isActive: true,
      playerCount: 11,
      role: TeamMemberRole.owner,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      liveMatchCount: liveMatchCount,
    );
  }

  group('TeamCard', () {
    testWidgets('shows LIVE badge when liveMatchCount > 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeTeam(liveMatchCount: 1)));

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.byType(PulsingLiveDot), findsOneWidget);
    });

    testWidgets('does not show LIVE badge when liveMatchCount is 0',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeTeam()));

      expect(find.text('LIVE'), findsNothing);
      expect(find.byType(PulsingLiveDot), findsNothing);
    });

    testWidgets('displays team name', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeTeam()));

      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('displays role badge', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeTeam()));

      expect(find.text('OWNER'), findsOneWidget);
    });
  });
}
