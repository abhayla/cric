import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/features/teams/domain/repositories/team_repository.dart';
import 'package:cricscores/src/features/teams/presentation/pages/add_player_page.dart';
import 'package:cricscores/src/features/teams/providers.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  Widget buildTestWidget({
    void Function(String name, String? phone, String? playerRole,
            String? battingStyle, String? bowlingStyle)?
        onCreatePlayer,
    void Function(String playerId)? onAddExisting,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: AddPlayerPage(
          teamId: 'team-1',
          onCreatePlayer: onCreatePlayer,
          onAddExisting: onAddExisting,
        ),
      ),
    );
  }

  group('AddPlayerPage', () {
    testWidgets('renders Add Player title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Add Player'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders two tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Search by Phone'), findsOneWidget);
      expect(find.text('Create New'), findsOneWidget);
    });

    testWidgets('Search tab shows phone input with +91 prefix',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsWidgets);
      expect(find.text('Phone Number'), findsWidgets);
    });

    testWidgets('Search tab shows Search button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Search'), findsOneWidget);
    });

    testWidgets('Create tab shows player name input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Create tab
      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Player Name *'), findsOneWidget);
    });

    testWidgets('Create tab shows role chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Batter'), findsOneWidget);
      expect(find.text('Bowler'), findsOneWidget);
      expect(find.text('All-Rounder'), findsOneWidget);
      expect(find.text('WK-Batter'), findsOneWidget);
    });

    testWidgets('Create tab shows batting style chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Right Hand'), findsOneWidget);
      expect(find.text('Left Hand'), findsOneWidget);
    });

    testWidgets('Create tab shows Add to Team button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Add to Team'),
        findsOneWidget,
      );
    });

    testWidgets('Create tab button disabled when name is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Create tab button disabled without phone',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      // Enter only name
      await tester.enterText(
        find.byKey(const Key('playerNameField')),
        'Test Player',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Create tab button disabled with invalid phone',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('playerNameField')),
        'Test Player',
      );
      await tester.enterText(
        find.byKey(const Key('playerPhoneField')),
        '12345',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Team'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Create tab shows validation error for invalid phone',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('playerPhoneField')),
        '12345',
      );
      await tester.pump();

      expect(
        find.text('Enter a valid 10-digit Indian mobile number'),
        findsOneWidget,
      );
    });

    testWidgets('Create tab button enabled with valid name and phone',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('playerNameField')),
        'Test Player',
      );
      await tester.enterText(
        find.byKey(const Key('playerPhoneField')),
        '9876543210',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Team'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Create tab shows Phone Number as required field',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('Phone Number *'), findsOneWidget);
    });

    group('Search tab — phone search', () {
      late MockTeamRepository mockRepo;

      setUp(() {
        mockRepo = MockTeamRepository();
      });

      Widget buildWithMock({
        void Function(String playerId)? onAddExisting,
      }) {
        return ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: AddPlayerPage(
              teamId: 'team-1',
              onAddExisting: onAddExisting,
            ),
          ),
        );
      }

      testWidgets('search shows result card on success', (tester) async {
        when(() => mockRepo.searchPlayerByPhone('+919876543210'))
            .thenAnswer((_) async => const PlayerSearchResult(
                  id: 'p-found',
                  displayName: 'Found Player',
                  playerRole: 'batter',
                ));

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '98765 43210'),
          '9876543210',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pumpAndSettle();

        expect(find.text('Found Player'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Add to Team'), findsOneWidget);
      });

      testWidgets('search shows "No player found" when null', (tester) async {
        when(() => mockRepo.searchPlayerByPhone('+919876543210'))
            .thenAnswer((_) async => null);

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '98765 43210'),
          '9876543210',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pumpAndSettle();

        expect(find.text('No player found'), findsOneWidget);
      });

      testWidgets('search shows error message on failure', (tester) async {
        when(() => mockRepo.searchPlayerByPhone('+919876543210'))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '98765 43210'),
          '9876543210',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Search failed'), findsOneWidget);
      });

      testWidgets('Add to Team calls onAddExisting with player ID',
          (tester) async {
        String? addedPlayerId;

        when(() => mockRepo.searchPlayerByPhone('+919876543210'))
            .thenAnswer((_) async => const PlayerSearchResult(
                  id: 'p-found',
                  displayName: 'Found Player',
                  playerRole: 'batter',
                ));

        await tester.pumpWidget(buildWithMock(
          onAddExisting: (id) => addedPlayerId = id,
        ));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '98765 43210'),
          '9876543210',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Add to Team'));
        await tester.pump();

        expect(addedPlayerId, 'p-found');
      });

      testWidgets('shows loading indicator during search', (tester) async {
        final completer = Completer<PlayerSearchResult?>();
        when(() => mockRepo.searchPlayerByPhone('+919876543210'))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildWithMock());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '98765 43210'),
          '9876543210',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the future to clean up
        completer.complete(null);
        await tester.pumpAndSettle();
      });
    });

    testWidgets('Create tab calls onCreatePlayer with form data',
        (tester) async {
      String? createdName;
      String? createdPhone;
      String? createdRole;

      await tester.pumpWidget(buildTestWidget(
        onCreatePlayer: (name, phone, role, batting, bowling) {
          createdName = name;
          createdPhone = phone;
          createdRole = role;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      // Enter player name
      await tester.enterText(
        find.byKey(const Key('playerNameField')),
        'Test Player',
      );
      // Enter valid phone
      await tester.enterText(
        find.byKey(const Key('playerPhoneField')),
        '9876543210',
      );
      await tester.pump();

      // Tap Add to Team button (scroll into view since it's inside ScrollView)
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add to Team'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add to Team'));
      await tester.pump();

      expect(createdName, 'Test Player');
      expect(createdPhone, '+919876543210');
      expect(createdRole, 'batter'); // Default role
    });
  });
}
