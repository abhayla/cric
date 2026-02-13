import 'package:drift/drift.dart';

import 'users_table.dart';

/// Local mirror of the PostgreSQL `teams` table.
class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get createdBy => text().references(Users, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of the PostgreSQL `team_rosters` table.
class TeamRosters extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text().references(Teams, #id)();
  TextColumn get playerId => text().references(Users, #id)();
  IntColumn get jerseyNumber => integer().nullable()();
  TextColumn get role => text().withDefault(const Constant('player'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {teamId, playerId},
      ];
}
