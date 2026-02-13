import 'package:drift/drift.dart';

import 'master_data_table.dart';
import 'teams_table.dart';
import 'users_table.dart';

/// Local mirror of the PostgreSQL `matches` table.
class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get homeTeamId => text().references(Teams, #id)();
  TextColumn get awayTeamId => text().references(Teams, #id)();
  TextColumn get tournamentId => text().nullable()();
  TextColumn get format => text()();
  IntColumn get totalOvers => integer()();
  IntColumn get ballTypeId => integer().references(BallTypes, #id)();
  TextColumn get venue => text().nullable()();
  TextColumn get tossWinnerId => text().nullable()();
  TextColumn get tossDecision => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('setup'))();
  TextColumn get scorerId => text().nullable()();
  IntColumn get playersPerSide =>
      integer().withDefault(const Constant(11))();
  IntColumn get wideRuns => integer().withDefault(const Constant(1))();
  IntColumn get noBallRuns => integer().withDefault(const Constant(1))();
  IntColumn get maxOversPerBowler => integer().nullable()();
  IntColumn get powerplayOvers => integer().nullable()();
  TextColumn get createdBy => text().references(Users, #id)();
  DateTimeColumn get matchDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of the PostgreSQL `match_players` table.
class MatchPlayers extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text().references(Matches, #id)();
  TextColumn get teamId => text().references(Teams, #id)();
  TextColumn get playerId => text().references(Users, #id)();
  IntColumn get battingOrder => integer().nullable()();
  BoolColumn get isPlaying =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isCaptain =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isKeeper =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {matchId, teamId, playerId},
      ];
}
