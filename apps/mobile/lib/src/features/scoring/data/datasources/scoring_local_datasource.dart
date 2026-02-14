import 'package:drift/drift.dart';

import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/data/database/daos/scoring_dao.dart';
import '../../presentation/notifiers/scoring_notifier.dart';
import '../models/scoring_state_converter.dart';

/// Local datasource for persisting and restoring scoring state.
///
/// Wraps [ScoringDao] with JSON serialization via [scoringStateToJsonString]
/// and [scoringStateFromJsonString].
class ScoringLocalDatasource {
  ScoringLocalDatasource({required ScoringDao scoringDao})
      : _dao = scoringDao;

  final ScoringDao _dao;

  /// Persist the current scoring state for a match.
  Future<void> saveState(ScoringState state) {
    return _dao.saveSnapshot(ScoringSnapshotsCompanion(
      matchId: Value(state.matchId),
      inningsNumber: Value(state.inningsNumber),
      stateJson: Value(scoringStateToJsonString(state)),
      isActive: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Load a previously saved scoring state for a match.
  ///
  /// Returns null if no snapshot exists.
  Future<ScoringState?> loadState(String matchId) async {
    final snapshot = await _dao.loadSnapshot(matchId);
    if (snapshot == null) return null;
    return scoringStateFromJsonString(snapshot.stateJson);
  }

  /// Whether an active scoring session exists for a match.
  Future<bool> hasActiveSession(String matchId) async {
    final snapshot = await _dao.loadSnapshot(matchId);
    return snapshot != null && snapshot.isActive;
  }

  /// Get match IDs that can be resumed.
  Future<List<String>> getResumableMatchIds() async {
    final active = await _dao.getActiveSnapshots();
    return active.map((s) => s.matchId).toList();
  }

  /// Mark a match as completed (deactivate the snapshot).
  Future<void> completeMatch(String matchId) {
    return _dao.deactivateSnapshot(matchId);
  }

  /// Delete the snapshot for a match entirely.
  Future<void> clearMatch(String matchId) {
    return _dao.deleteSnapshot(matchId);
  }
}
