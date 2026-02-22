import '../entities/activity_event.dart';

/// Result container for paginated activity feed.
class ActivityFeedResult {
  const ActivityFeedResult({
    required this.events,
    required this.total,
    required this.page,
  });

  final List<ActivityEvent> events;
  final int total;
  final int page;
}

/// Abstract repository interface for updates feature.
abstract class UpdatesRepository {
  /// Get paginated activity feed.
  Future<ActivityFeedResult> getActivityFeed({int page, int limit});

  /// Mark events as read.
  Future<void> markAsRead(List<String> eventIds);

  /// Get unread event count.
  Future<int> getUnreadCount();
}
