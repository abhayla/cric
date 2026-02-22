import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';
import 'package:cricapp/src/features/teams/domain/entities/team.dart';
import 'package:cricapp/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricapp/src/features/teams/presentation/pages/team_detail_page.dart';
import 'package:cricapp/src/features/teams/providers.dart';

void main() {
  final testTeam = Team(
    id: 'team-1',
    name: 'Mumbai Warriors',
    createdBy: 'user-1',
    isActive: true,
    playerCount: 11,
    role: TeamMemberRole.owner,
    location: 'Mumbai',
    createdAt: DateTime(2025, 3, 15),
    updatedAt: DateTime(2025, 3, 15),
  );

  final testRoster = [
    RosterEntry(
      id: 'r-1',
      playerId: 'p-1',
      displayName: 'Arjun Mehta',
      rosterRole: RosterRole.captain,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      playerRole: PlayerRole.batter,
      battingStyle: BattingStyle.rightHand,
    ),
    RosterEntry(
      id: 'r-2',
      playerId: 'p-2',
      displayName: 'Karan Singh',
      rosterRole: RosterRole.player,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      playerRole: PlayerRole.allRounder,
      battingStyle: BattingStyle.rightHand,
      bowlingStyle: BowlingStyle.rightArmFast,
    ),
    RosterEntry(
      id: 'r-3',
      playerId: 'p-3',
      displayName: 'Rajesh Kumar',
      rosterRole: RosterRole.player,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      playerRole: PlayerRole.bowler,
      bowlingStyle: BowlingStyle.rightArmOffSpin,
    ),
    RosterEntry(
      id: 'r-4',
      playerId: 'p-4',
      displayName: 'Nikhil Verma',
      rosterRole: RosterRole.player,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      playerRole: PlayerRole.wkBatter,
      battingStyle: BattingStyle.leftHand,
    ),
  ];

  final testDetail = TeamDetail(team: testTeam, roster: testRoster);

  Widget buildTestWidget({TeamDetail? initialData}) {
    return ProviderScope(
      overrides: [
        teamDetailProvider('team-1').overrideWith(
          (ref) => initialData != null
              ? Future.value(initialData)
              : Completer<TeamDetail>().future,
        ),
      ],
      child: const MaterialApp(
        home: TeamDetailPage(teamId: 'team-1'),
      ),
    );
  }

  group('TeamDetailPage', () {
    testWidgets('renders team name in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Mumbai Warriors'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders team avatar with initial', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('M'), findsWidgets);
    });

    testWidgets('renders team subtitle with location and player count',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('11 players · Mumbai'), findsOneWidget);
    });

    testWidgets('renders stats row with zero values', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      // Stats labels (Matches appears in both stats and tab)
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('Losses'), findsOneWidget);
      expect(find.text('Tied'), findsOneWidget);
      // Zero values
      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('renders three tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsNWidgets(3));
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Players'), findsOneWidget);
    });

    testWidgets('shows player names in Players tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      // Tap Players tab (last tab)
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      // First players visible without scrolling
      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Karan Singh'), findsOneWidget);

      // Scroll to see remaining players
      await tester.scrollUntilVisible(
        find.text('Rajesh Kumar'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Rajesh Kumar'), findsOneWidget);
    });

    testWidgets('shows player styles in Players tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      // All-rounder shows both styles
      expect(find.text('Right Hand · Right Arm Fast'), findsOneWidget);
    });

    testWidgets('shows role group headers in Players tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      // First group header visible
      expect(find.text('BATTERS'), findsOneWidget);

      // Scroll to see more groups
      await tester.scrollUntilVisible(
        find.text('BOWLERS'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('BOWLERS'), findsOneWidget);
    });

    testWidgets('shows empty state when roster is empty', (tester) async {
      final emptyDetail = TeamDetail(team: testTeam, roster: []);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          teamDetailProvider('team-1').overrideWith(
            (ref) => Future.value(emptyDetail),
          ),
        ],
        child: const MaterialApp(
          home: TeamDetailPage(teamId: 'team-1'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.text('No players yet'), findsOneWidget);
      // Both the empty state icon and the FAB show person_add
      expect(find.byIcon(Icons.person_add), findsNWidgets(2));
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Don't settle - stay in loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows FAB on Players tab for owner', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      // FAB not visible on Overview tab
      expect(find.byType(FloatingActionButton), findsNothing);

      // Switch to Players tab
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows delete icons on Players tab for owner',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('hides FAB and delete icons for regular player',
        (tester) async {
      final playerTeam = Team(
        id: 'team-1',
        name: 'Mumbai Warriors',
        createdBy: 'user-1',
        isActive: true,
        playerCount: 11,
        role: TeamMemberRole.member,
        location: 'Mumbai',
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
      );
      final playerDetail = TeamDetail(team: playerTeam, roster: testRoster);

      await tester.pumpWidget(buildTestWidget(initialData: playerDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('shows player count in Players tab header', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.text('4 players'), findsOneWidget);
    });
  });
}
