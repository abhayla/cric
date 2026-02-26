import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/network/auth_interceptors.dart';
import 'data/datasources/updates_remote_datasource.dart';
import 'data/repositories/updates_repository_impl.dart';
import 'domain/repositories/updates_repository.dart';
import 'presentation/notifiers/updates_preferences_notifier.dart';

/// Dio instance for updates feature.
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  try {
    addAuthInterceptors(dio, ref.read(firebaseAuthDatasourceProvider));
  } catch (_) {
    // Provider not available (e.g., in test environment)
  }

  return dio;
});

/// Updates remote datasource.
final updatesRemoteDatasourceProvider =
    Provider<UpdatesRemoteDatasource>((ref) {
  return UpdatesRemoteDatasource(dio: ref.watch(_dioProvider));
});

/// Updates repository.
final updatesRepositoryProvider = Provider<UpdatesRepository>((ref) {
  return UpdatesRepositoryImpl(
    remoteDatasource: ref.watch(updatesRemoteDatasourceProvider),
  );
});

/// Activity feed provider.
final activityFeedProvider = FutureProvider<ActivityFeedResult>((ref) {
  final repository = ref.read(updatesRepositoryProvider);
  return repository.getActivityFeed();
});

/// Unread count provider.
final unreadCountProvider = FutureProvider<int>((ref) {
  final repository = ref.read(updatesRepositoryProvider);
  return repository.getUnreadCount();
});

/// Updates preferences notifier — controls which event types are visible.
final updatesPreferencesProvider =
    NotifierProvider<UpdatesPreferencesNotifier, UpdatesPreferencesState>(
  UpdatesPreferencesNotifier.new,
);
