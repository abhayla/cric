/// Activity feed event entity.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.eventType,
    required this.title,
    required this.createdAt,
    this.description,
    this.referenceType,
    this.referenceId,
    this.isRead = false,
  });

  final String id;
  final String eventType;
  final String title;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  IconType get iconType => switch (eventType) {
        'match_completed' => IconType.match,
        'player_added' => IconType.team,
        'team_joined' => IconType.team,
        'tournament_update' => IconType.tournament,
        'personal_milestone' => IconType.milestone,
        _ => IconType.general,
      };
}

enum IconType { match, team, tournament, milestone, general }
