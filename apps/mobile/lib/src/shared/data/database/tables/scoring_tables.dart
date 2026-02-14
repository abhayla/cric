import 'package:drift/drift.dart';

/// Scoring state snapshots — persists full ScoringState as JSON for match resume.
class ScoringSnapshots extends Table {
  /// Match UUID — one snapshot per match.
  TextColumn get matchId => text()();

  /// Current innings number (1 or 2).
  IntColumn get inningsNumber => integer()();

  /// Full ScoringState serialized as JSON.
  TextColumn get stateJson => text()();

  /// Whether this match is still in progress.
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  /// Last time the snapshot was updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId};
}
