import 'package:drift/drift.dart';

import 'tables/local_tables.dart';
import 'tables/master_data_table.dart';
import 'tables/matches_table.dart';
import 'tables/teams_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Teams,
  TeamRosters,
  Matches,
  MatchPlayers,
  BallTypes,
  SyncQueue,
  LocalPreferences,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedBallTypes();
        },
      );

  /// Seed ball_types with the 4 master data values.
  Future<void> _seedBallTypes() async {
    final now = DateTime.now();
    const names = ['leather', 'tennis', 'tape', 'other'];
    for (final name in names) {
      await into(ballTypes).insert(
        BallTypesCompanion.insert(name: name, createdAt: now),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}
