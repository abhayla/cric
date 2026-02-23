import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/data/datasources/scoring_local_datasource.dart';
import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
import 'package:cricscores/src/features/scoring/presentation/pages/scoring_page.dart';
import 'package:cricscores/src/shared/data/database/app_database.dart';
import 'package:cricscores/src/shared/data/database/daos/scoring_dao.dart';

void main() {
  late AppDatabase db;
  late ScoringDao dao;
  late ScoringLocalDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoringDao(db);
    datasource = ScoringLocalDatasource(scoringDao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  List<PlayingXIPlayer> makeBattingTeam() => List.generate(
        11,
        (i) => PlayingXIPlayer(
          playerId: 'bat-${i + 1}',
          displayName: 'Batter ${i + 1}',
        ),
      );

  List<PlayingXIPlayer> makeBowlingTeam() => List.generate(
        11,
        (i) => PlayingXIPlayer(
          playerId: 'bowl-${i + 1}',
          displayName: 'Bowler ${i + 1}',
        ),
      );

  ScoringPageArgs makeArgs() {
    return ScoringPageArgs(
      matchId: 'match-persist-1',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: 20,
      playersPerSide: 11,
      battingTeamPlayers: makeBattingTeam(),
      bowlingTeamPlayers: makeBowlingTeam(),
      openingStrikerId: 'bat-1',
      openingStrikerName: 'Batter 1',
      openingNonStrikerId: 'bat-2',
      openingNonStrikerName: 'Batter 2',
      openingBowlerId: 'bowl-1',
      openingBowlerName: 'Bowler 1',
    );
  }

  Widget buildPage({ScoringLocalDatasource? ds}) {
    return MaterialApp(
      home: ScoringPage(
        args: makeArgs(),
        datasource: ds,
      ),
    );
  }

  group('ScoringPage with persistence', () {
    testWidgets('shows loading then renders normally', (tester) async {
      await tester.pumpWidget(buildPage(ds: datasource));
      // On first frame, loading indicator should show
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // After async init completes
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Team Alpha'), findsOneWidget);
      expect(find.text('0/0'), findsOneWidget);
    });

    testWidgets('persists state after delivery', (tester) async {
      await tester.pumpWidget(buildPage(ds: datasource));
      await tester.pumpAndSettle();

      // Tap 4 runs
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(find.text('4/0'), findsOneWidget);

      // Give fire-and-forget persist time to complete
      await tester.pump(const Duration(milliseconds: 100));

      final loaded = await datasource.loadState('match-persist-1');
      expect(loaded, isNotNull);
      expect(loaded!.totalRuns, 4);
    });

    testWidgets('saves initial state on createNew', (tester) async {
      await tester.pumpWidget(buildPage(ds: datasource));
      await tester.pumpAndSettle();

      final loaded = await datasource.loadState('match-persist-1');
      expect(loaded, isNotNull);
      expect(loaded!.matchId, 'match-persist-1');
      expect(loaded.strikerId, 'bat-1');
    });

    testWidgets('resumes from saved state', (tester) async {
      // First: manually save a state with 10 runs
      final state = ScoringState(
        matchId: 'match-persist-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        battingTeamName: 'Team Alpha',
        bowlingTeamName: 'Team Beta',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        totalRuns: 10,
        totalBalls: 2,
        strikerId: 'bat-1',
        nonStrikerId: 'bat-2',
        bowlerId: 'bowl-1',
        battingTeamPlayers: makeBattingTeam(),
        bowlingTeamPlayers: makeBowlingTeam(),
        batterStats: {
          'bat-1': const BatterInnings(
            playerId: 'bat-1',
            displayName: 'Batter 1',
            runsScored: 10,
            ballsFaced: 2,
            isOnStrike: true,
          ),
          'bat-2': const BatterInnings(
            playerId: 'bat-2',
            displayName: 'Batter 2',
          ),
        },
        bowlerStats: {
          'bowl-1': const BowlerSpell(
            playerId: 'bowl-1',
            displayName: 'Bowler 1',
            ballsBowled: 2,
            runsConceded: 10,
          ),
        },
      );
      await datasource.saveState(state);

      // Build page with same matchId — should resume
      await tester.pumpWidget(buildPage(ds: datasource));
      await tester.pumpAndSettle();

      // Score should be restored
      expect(find.text('10/0'), findsOneWidget);
    });

    testWidgets('exit dialog mentions local save with persistence',
        (tester) async {
      await tester.pumpWidget(buildPage(ds: datasource));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(find.text('Exit Scoring?'), findsOneWidget);
      expect(find.textContaining('saved locally'), findsOneWidget);
    });

    testWidgets('exit dialog warns about lost progress without persistence',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(
          find.textContaining('Unsaved progress will be lost'), findsOneWidget);
    });
  });
}
