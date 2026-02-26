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
        'match_completed' ||
        'match_started' ||
        'match_abandoned' ||
        'innings_completed' =>
          IconType.match,
        'player_added' || 'player_removed' || 'team_joined' => IconType.team,
        'tournament_update' ||
        'tournament_match_result' ||
        'team_added_tournament' ||
        'registration_resolved' ||
        'fixtures_generated' =>
          IconType.tournament,
        'century' ||
        'half_century' ||
        'five_wicket_haul' ||
        'three_wicket_haul' ||
        'hat_trick' ||
        'personal_milestone' =>
          IconType.milestone,
        _ => IconType.general,
      };

  /// All known event types for settings UI.
  static const allEventTypes = [
    // Player milestones
    'century',
    'half_century',
    'five_wicket_haul',
    'three_wicket_haul',
    'hat_trick',
    // Match lifecycle
    'match_completed',
    'match_started',
    'match_abandoned',
    'innings_completed',
    // Team
    'player_added',
    'player_removed',
    'team_joined',
    // Tournament
    'tournament_update',
    'tournament_match_result',
    'team_added_tournament',
    'registration_resolved',
    'fixtures_generated',
  ];

  /// Human-readable label for an event type.
  static String eventTypeLabel(String eventType) => switch (eventType) {
        'century' => 'Century',
        'half_century' => 'Half Century',
        'five_wicket_haul' => '5-Wicket Haul',
        'three_wicket_haul' => '3-Wicket Haul',
        'hat_trick' => 'Hat-Trick',
        'match_completed' => 'Match Completed',
        'match_started' => 'Match Started',
        'match_abandoned' => 'Match Abandoned',
        'innings_completed' => 'Innings Completed',
        'player_added' => 'Player Added',
        'player_removed' => 'Player Removed',
        'team_joined' => 'Team Joined',
        'tournament_update' => 'Tournament Update',
        'tournament_match_result' => 'Tournament Match Result',
        'team_added_tournament' => 'Team Added to Tournament',
        'registration_resolved' => 'Registration Resolved',
        'fixtures_generated' => 'Fixtures Generated',
        _ => eventType,
      };

  /// Grouped event types for settings UI.
  static const eventTypeGroups = {
    'Player': [
      'century',
      'half_century',
      'five_wicket_haul',
      'three_wicket_haul',
      'hat_trick',
    ],
    'Match': [
      'match_completed',
      'match_started',
      'match_abandoned',
      'innings_completed',
    ],
    'Team': [
      'player_added',
      'player_removed',
      'team_joined',
    ],
    'Tournament': [
      'tournament_update',
      'tournament_match_result',
      'team_added_tournament',
      'registration_resolved',
      'fixtures_generated',
    ],
  };
}

enum IconType { match, team, tournament, milestone, general }
