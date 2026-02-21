import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricapp/src/features/auth/domain/entities/app_user.dart';
import 'package:cricapp/src/features/teams/domain/entities/team.dart';
import 'package:cricapp/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricapp/src/features/teams/presentation/pages/manage_roster_page.dart';
import 'package:cricapp/src/features/teams/providers.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  final testTeam = Team(
    id: 'team-1',
    name: 'Mumbai Warriors',
    createdBy: 'user-1',
    isActive: true,
    playerCount: 2,
    role: TeamMemberRole.owner,
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
      displayName: 'Rajesh Kumar',
      rosterRole: RosterRole.player,
      isActive: true,
      joinedAt: DateTime(2025, 3, 15),
      playerRole: PlayerRole.bowler,
      bowlingStyle: BowlingStyle.rightArmFast,
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
        home: ManageRosterPage(teamId: 'team-1'),
      ),
    );
  }

  group('ManageRosterPage', () {
    testWidgets('renders Manage Roster title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Manage Roster'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows player count', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      // RichText with TextSpan children — use byWidgetPredicate
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('2') &&
            widget.text.toPlainText().contains('25')),
        findsOneWidget,
      );
    });

    testWidgets('shows Add Player button', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('Add Player'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Search players...'),
        findsOneWidget,
      );
    });

    testWidgets('shows player names in roster', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
    });

    testWidgets('shows remove buttons for each player', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('shows captain badge', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('C'), findsWidgets);
    });

    testWidgets('filters players by search query', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialData: testDetail));
      await tester.pumpAndSettle();

      // Both players visible initially
      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);

      // Type search query
      await tester.enterText(
        find.widgetWithText(TextField, 'Search players...'),
        'Arjun',
      );
      await tester.pump();

      // Only matching player visible
      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsNothing);
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
          home: ManageRosterPage(teamId: 'team-1'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No players yet'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    group('remove player', () {
      late MockTeamRepository mockRepo;

      setUp(() {
        mockRepo = MockTeamRepository();
      });

      Widget buildWithMock({TeamDetail? detail}) {
        return ProviderScope(
          overrides: [
            teamDetailProvider('team-1').overrideWith(
              (ref) => Future.value(detail ?? testDetail),
            ),
            teamRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ManageRosterPage(teamId: 'team-1'),
          ),
        );
      }

      testWidgets('shows confirmation dialog on delete tap', (tester) async {
        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        expect(find.text('Remove Player'), findsOneWidget);
        expect(
          find.textContaining('Remove Arjun Mehta'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
      });

      testWidgets('Cancel dismisses dialog without calling API',
          (tester) async {
        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Remove Player'), findsNothing);
        verifyNever(() => mockRepo.removePlayer(any(), any()));
      });

      testWidgets('Remove calls removePlayer and shows success SnackBar',
          (tester) async {
        when(() => mockRepo.removePlayer('team-1', 'p-1'))
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        verify(() => mockRepo.removePlayer('team-1', 'p-1')).called(1);
        expect(find.text('Player removed'), findsOneWidget);
      });

      testWidgets('shows error SnackBar on failure', (tester) async {
        when(() => mockRepo.removePlayer('team-1', 'p-1'))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Failed to remove player'), findsOneWidget);
      });
    });
  });
}
