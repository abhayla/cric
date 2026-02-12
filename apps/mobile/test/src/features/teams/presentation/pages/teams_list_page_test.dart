import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/teams/domain/entities/team.dart';
import 'package:cricapp/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricapp/src/features/teams/presentation/pages/teams_list_page.dart';
import 'package:cricapp/src/features/teams/providers.dart';

void main() {
  Widget buildTestWidget({TeamListResult? initialData}) {
    return ProviderScope(
      overrides: [
        teamsListProvider.overrideWith(() {
          return _TestTeamsListNotifier(initialData);
        }),
      ],
      child: const MaterialApp(
        home: TeamsListPage(),
      ),
    );
  }

  group('TeamsListPage', () {
    testWidgets('renders Teams title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData: const TeamListResult(teams: [], total: 0, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Teams'), findsOneWidget);
    });

    testWidgets('shows empty state when no teams', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData: const TeamListResult(teams: [], total: 0, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No teams yet'), findsOneWidget);
      expect(find.text('Create a team to get started'), findsOneWidget);
      expect(find.text('Create a Team'), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
    });

    testWidgets('shows team cards in grid when teams exist', (tester) async {
      final teams = [
        Team(
          id: 'team-1',
          name: 'Mumbai Warriors',
          createdBy: 'user-1',
          isActive: true,
          playerCount: 11,
          role: TeamMemberRole.owner,
          location: 'Mumbai',
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 3, 15),
        ),
        Team(
          id: 'team-2',
          name: 'Delhi Strikers',
          createdBy: 'user-2',
          isActive: true,
          playerCount: 8,
          role: TeamMemberRole.member,
          location: 'Delhi',
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 3, 15),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData: TeamListResult(teams: teams, total: 2, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mumbai Warriors'), findsOneWidget);
      expect(find.text('Delhi Strikers'), findsOneWidget);
      expect(find.text('11 players · Mumbai'), findsOneWidget);
      expect(find.text('8 players · Delhi'), findsOneWidget);
    });

    testWidgets('shows role badges on team cards', (tester) async {
      final teams = [
        Team(
          id: 'team-1',
          name: 'Mumbai Warriors',
          createdBy: 'user-1',
          isActive: true,
          playerCount: 11,
          role: TeamMemberRole.owner,
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 3, 15),
        ),
        Team(
          id: 'team-2',
          name: 'Delhi Strikers',
          createdBy: 'user-2',
          isActive: true,
          playerCount: 8,
          role: TeamMemberRole.member,
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 3, 15),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData: TeamListResult(teams: teams, total: 2, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
    });

    testWidgets('shows team initial in avatar', (tester) async {
      final teams = [
        Team(
          id: 'team-1',
          name: 'Mumbai Warriors',
          createdBy: 'user-1',
          isActive: true,
          playerCount: 11,
          role: TeamMemberRole.owner,
          createdAt: DateTime(2025, 3, 15),
          updatedAt: DateTime(2025, 3, 15),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        initialData: TeamListResult(teams: teams, total: 1, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('shows FAB for creating team', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData: const TeamListResult(teams: [], total: 0, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('has pull-to-refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialData: const TeamListResult(teams: [], total: 0, page: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Don't settle - stay in loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _TestTeamsListNotifier extends TeamsListNotifier {
  _TestTeamsListNotifier(this._initialData);

  final TeamListResult? _initialData;

  @override
  Future<TeamListResult> build() async {
    if (_initialData != null) return _initialData;
    // Return a never-completing future for loading state test
    return Completer<TeamListResult>().future;
  }
}
