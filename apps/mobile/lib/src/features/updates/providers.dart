import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/updates_remote_datasource.dart';
import 'data/repositories/updates_repository_impl.dart';
import 'domain/repositories/updates_repository.dart';

/// Dio instance for updates feature.
final _dioProvider = Provider<Dio>((ref) {
  return Dio();
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
