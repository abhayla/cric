import 'package:drift/drift.dart';

/// Offline sync queue — tracks pending operations to push to server.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Local app preferences — key-value store for settings and cached state.
class LocalPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
