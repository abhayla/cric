import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/updates_repository.dart';
import '../datasources/updates_remote_datasource.dart';

class UpdatesRepositoryImpl implements UpdatesRepository {
  UpdatesRepositoryImpl({required this.remoteDatasource});

  final UpdatesRemoteDatasource remoteDatasource;

  @override
  Future<ActivityFeedResult> getActivityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await remoteDatasource.getActivityFeed(
      page: page,
      limit: limit,
    );

    final events = (data['events'] as List)
        .map((e) => _eventFromJson(e as Map<String, dynamic>))
        .toList();

    return ActivityFeedResult(
      events: events,
      total: data['total'] as int,
      page: data['page'] as int,
    );
  }

  @override
  Future<void> markAsRead(List<String> eventIds) async {
    await remoteDatasource.markAsRead(eventIds);
  }

  @override
  Future<int> getUnreadCount() async {
    return remoteDatasource.getUnreadCount();
  }

  ActivityEvent _eventFromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String,
      eventType: json['eventType'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
