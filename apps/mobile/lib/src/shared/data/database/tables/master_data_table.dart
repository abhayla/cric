import 'package:drift/drift.dart';

/// Local mirror of the PostgreSQL `ball_types` master data table.
class BallTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}
