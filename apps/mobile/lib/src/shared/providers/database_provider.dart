import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/scoring_dao.dart';
import '../data/database/daos/teams_dao.dart';

/// Riverpod provider for the Drift database instance.
///
/// Must be overridden in the root ProviderScope with a real database
/// instance (file-backed in production, in-memory for tests).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with a real database instance. '
    'Use ProviderScope overrides in main.dart.',
  );
});

/// Riverpod provider for the TeamsDao.
final teamsDaoProvider = Provider<TeamsDao>((ref) {
  return TeamsDao(ref.watch(databaseProvider));
});

/// Riverpod provider for the ScoringDao.
final scoringDaoProvider = Provider<ScoringDao>((ref) {
  return ScoringDao(ref.watch(databaseProvider));
});
