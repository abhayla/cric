import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'data/datasources/updates_remote_datasource.dart';
import 'data/repositories/updates_repository_impl.dart';
import 'domain/repositories/updates_repository.dart';

/// Dio instance for updates feature.
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  try {
    final authDatasource = ref.read(firebaseAuthDatasourceProvider);
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await authDatasource.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Silently continue without auth
        }
        handler.next(options);
      },
    ));
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
