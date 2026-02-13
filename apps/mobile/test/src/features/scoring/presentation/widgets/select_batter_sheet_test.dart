import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/select_batter_sheet.dart';

void main() {
  List<PlayingXIPlayer> makeYetToBat({int count = 5}) {
    return List.generate(count, (i) => PlayingXIPlayer(
      playerId: 'p-${i + 3}',
      displayName: 'Player ${i + 3}',
      playerRole: i.isEven ? 'batter' : 'all_rounder',
      battingStyle: i.isEven ? 'RHB' : 'LHB',
      isCaptain: i == 0,
      isKeeper: i == 1,
    ));
  }

  Widget buildSheet({
    List<PlayingXIPlayer>? yetToBat,
    List<BatterInnings>? retiredHurt,
    String? dismissedBatterName,
    String? dismissalDescription,
    ValueChanged<String>? onSelect,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SelectBatterSheet(
          yetToBatPlayers: yetToBat ?? makeYetToBat(),
          retiredHurtBatters: retiredHurt ?? [],
          dismissedBatterName: dismissedBatterName,
          dismissalDescription: dismissalDescription,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    );
  }

  group('SelectBatterSheet', () {
    testWidgets('renders title "Select New Batter"', (tester) async {
      await tester.pumpWidget(buildSheet());
      expect(find.text('Select New Batter'), findsOneWidget);
    });

    testWidgets('renders subtitle with dismissed batter and dismissal',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        dismissedBatterName: 'Virat Kohli',
        dismissalDescription: 'b Bumrah',
      ));
      expect(find.text('Replacing: Virat Kohli (b Bumrah)'), findsOneWidget);
    });

    testWidgets('subtitle not shown when no dismissed batter', (tester) async {
      await tester.pumpWidget(buildSheet());
      expect(find.textContaining('Replacing:'), findsNothing);
    });

    testWidgets('renders player rows with names', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(playerId: 'p-3', displayName: 'Player Three'),
          PlayingXIPlayer(playerId: 'p-4', displayName: 'Player Four'),
          PlayingXIPlayer(playerId: 'p-5', displayName: 'Player Five'),
        ],
      ));
      expect(find.text('Player Three'), findsOneWidget);
      expect(find.text('Player Four'), findsOneWidget);
      expect(find.text('Player Five'), findsOneWidget);
    });

    testWidgets('renders player initials in avatar', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'p-1',
            displayName: 'Virat Kohli',
            battingStyle: 'RHB',
          ),
        ],
      ));
      expect(find.text('VK'), findsOneWidget);
    });

    testWidgets('renders captain badge', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'p-1',
            displayName: 'Rohit Sharma',
            isCaptain: true,
          ),
        ],
      ));
      expect(find.textContaining('(C)'), findsOneWidget);
    });

    testWidgets('renders keeper badge', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'p-1',
            displayName: 'KL Rahul',
            isKeeper: true,
          ),
        ],
      ));
      expect(find.textContaining('(WK)'), findsOneWidget);
    });

    testWidgets('renders batting style chip', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'p-1',
            displayName: 'Player One',
            battingStyle: 'LHB',
          ),
        ],
      ));
      expect(find.text('LHB'), findsOneWidget);
    });

    testWidgets('tap on player calls onSelect with playerId', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'p-99',
            displayName: 'Test Player',
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.tap(find.text('Test Player'));
      await tester.pumpAndSettle();
      expect(selectedId, 'p-99');
    });

    testWidgets('renders retired hurt section when present', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(playerId: 'p-5', displayName: 'New Player'),
        ],
        retiredHurt: const [
          BatterInnings(
            playerId: 'p-1',
            displayName: 'Hurt Player',
            isRetiredHurt: true,
            isNotOut: true,
            runsScored: 25,
            ballsFaced: 20,
          ),
        ],
      ));
      expect(find.text('Retired Hurt'), findsOneWidget);
      expect(find.text('Hurt Player'), findsOneWidget);
    });

    testWidgets('retired hurt player shows runs and balls', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [],
        retiredHurt: const [
          BatterInnings(
            playerId: 'p-1',
            displayName: 'Hurt Player',
            isRetiredHurt: true,
            isNotOut: true,
            runsScored: 25,
            ballsFaced: 20,
          ),
        ],
      ));
      expect(find.text('25 (20)'), findsOneWidget);
    });

    testWidgets('tap on retired hurt calls onSelect', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        yetToBat: const [],
        retiredHurt: const [
          BatterInnings(
            playerId: 'rh-1',
            displayName: 'Hurt Player',
            isRetiredHurt: true,
            isNotOut: true,
            runsScored: 10,
          ),
        ],
        onSelect: (id) => selectedId = id,
      ));

      await tester.tap(find.text('Hurt Player'));
      await tester.pumpAndSettle();
      expect(selectedId, 'rh-1');
    });

    testWidgets('auto-selects when only 1 player available', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'last-one',
            displayName: 'Last Player',
          ),
        ],
        retiredHurt: const [],
        onSelect: (id) => selectedId = id,
      ));

      // Wait for addPostFrameCallback
      await tester.pumpAndSettle();
      expect(selectedId, 'last-one');
    });

    testWidgets('shows snackbar on auto-select', (tester) async {
      await tester.pumpWidget(buildSheet(
        yetToBat: const [
          PlayingXIPlayer(
            playerId: 'last-one',
            displayName: 'Last Player',
          ),
        ],
        retiredHurt: const [],
      ));

      await tester.pumpAndSettle();
      expect(
        find.textContaining('Last batter Last Player coming in'),
        findsOneWidget,
      );
    });
  });
}
