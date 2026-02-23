import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/data/datasources/scoring_local_datasource.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';
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

  ScoringState makeState({
    String matchId = 'match-1',
    int inningsNumber = 1,
    int totalRuns = 0,
  }) {
    return ScoringState(
      matchId: matchId,
      inningsId: 'inn-$inningsNumber',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      inningsNumber: inningsNumber,
      totalOvers: 20,
      playersPerSide: 11,
      totalRuns: totalRuns,
    );
  }

  test('saveState and loadState round-trip', () async {
    final state = makeState(totalRuns: 42);
    await datasource.saveState(state);
    final loaded = await datasource.loadState('match-1');
    expect(loaded, isNotNull);
    expect(loaded!.matchId, 'match-1');
    expect(loaded.totalRuns, 42);
  });

  test('loadState returns null for non-existent match', () async {
    final loaded = await datasource.loadState('non-existent');
    expect(loaded, isNull);
  });

  test('saveState overwrites previous state', () async {
    await datasource.saveState(makeState(totalRuns: 10));
    await datasource.saveState(makeState(totalRuns: 50));
    final loaded = await datasource.loadState('match-1');
    expect(loaded!.totalRuns, 50);
  });

  test('hasActiveSession returns true for saved match', () async {
    await datasource.saveState(makeState());
    expect(await datasource.hasActiveSession('match-1'), true);
  });

  test('hasActiveSession returns false after completeMatch', () async {
    await datasource.saveState(makeState());
    await datasource.completeMatch('match-1');
    expect(await datasource.hasActiveSession('match-1'), false);
  });

  test('hasActiveSession returns false for non-existent match', () async {
    expect(await datasource.hasActiveSession('nope'), false);
  });

  test('getResumableMatchIds returns active match IDs', () async {
    await datasource.saveState(makeState(matchId: 'match-1'));
    await datasource.saveState(makeState(matchId: 'match-2'));
    await datasource.completeMatch('match-2');

    final ids = await datasource.getResumableMatchIds();
    expect(ids, ['match-1']);
  });

  test('completeMatch deactivates snapshot', () async {
    await datasource.saveState(makeState());
    await datasource.completeMatch('match-1');
    // loadState still returns the snapshot
    final loaded = await datasource.loadState('match-1');
    expect(loaded, isNotNull);
    // But it's not active
    expect(await datasource.hasActiveSession('match-1'), false);
  });

  test('clearMatch removes snapshot entirely', () async {
    await datasource.saveState(makeState());
    await datasource.clearMatch('match-1');
    final loaded = await datasource.loadState('match-1');
    expect(loaded, isNull);
  });

  test('saveState updates innings number on 2nd innings', () async {
    await datasource.saveState(makeState(inningsNumber: 1));
    await datasource.saveState(makeState(inningsNumber: 2, totalRuns: 75));
    final loaded = await datasource.loadState('match-1');
    expect(loaded!.inningsNumber, 2);
    expect(loaded.totalRuns, 75);
  });
}
