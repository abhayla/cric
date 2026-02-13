import 'package:drift/drift.dart';

/// Local mirror of the PostgreSQL `users` table.
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get firebaseUid => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get battingStyle => text().nullable()();
  TextColumn get bowlingStyle => text().nullable()();
  TextColumn get playerRole => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
