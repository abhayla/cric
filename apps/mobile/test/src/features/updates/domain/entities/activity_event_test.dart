import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/updates/domain/entities/activity_event.dart';

void main() {
  ActivityEvent makeEvent(String eventType) => ActivityEvent(
        id: '1',
        eventType: eventType,
        title: 'Test',
        createdAt: DateTime(2026, 1, 1),
      );

  group('ActivityEvent.iconType', () {
    group('returns IconType.match for match lifecycle events', () {
      for (final type in [
        'match_completed',
        'match_started',
        'match_abandoned',
        'innings_completed',
      ]) {
        test('$type -> IconType.match', () {
          expect(makeEvent(type).iconType, IconType.match);
        });
      }
    });

    group('returns IconType.team for team events', () {
      for (final type in ['player_added', 'player_removed', 'team_joined']) {
        test('$type -> IconType.team', () {
          expect(makeEvent(type).iconType, IconType.team);
        });
      }
    });

    group('returns IconType.tournament for tournament events', () {
      for (final type in [
        'tournament_update',
        'tournament_match_result',
        'team_added_tournament',
        'registration_resolved',
        'fixtures_generated',
      ]) {
        test('$type -> IconType.tournament', () {
          expect(makeEvent(type).iconType, IconType.tournament);
        });
      }
    });

    group('returns IconType.milestone for milestone events', () {
      for (final type in [
        'century',
        'half_century',
        'five_wicket_haul',
        'three_wicket_haul',
        'hat_trick',
        'personal_milestone',
      ]) {
        test('$type -> IconType.milestone', () {
          expect(makeEvent(type).iconType, IconType.milestone);
        });
      }
    });

    test('returns IconType.general for unknown event type', () {
      expect(makeEvent('unknown_type').iconType, IconType.general);
      expect(makeEvent('').iconType, IconType.general);
      expect(makeEvent('random_event').iconType, IconType.general);
    });
  });

  group('ActivityEvent.eventTypeLabel', () {
    test('returns correct label for each known event type', () {
      expect(ActivityEvent.eventTypeLabel('century'), 'Century');
      expect(ActivityEvent.eventTypeLabel('half_century'), 'Half Century');
      expect(ActivityEvent.eventTypeLabel('five_wicket_haul'), '5-Wicket Haul');
      expect(
          ActivityEvent.eventTypeLabel('three_wicket_haul'), '3-Wicket Haul');
      expect(ActivityEvent.eventTypeLabel('hat_trick'), 'Hat-Trick');
      expect(
          ActivityEvent.eventTypeLabel('match_completed'), 'Match Completed');
      expect(ActivityEvent.eventTypeLabel('match_started'), 'Match Started');
      expect(
          ActivityEvent.eventTypeLabel('match_abandoned'), 'Match Abandoned');
      expect(ActivityEvent.eventTypeLabel('innings_completed'),
          'Innings Completed');
      expect(ActivityEvent.eventTypeLabel('player_added'), 'Player Added');
      expect(ActivityEvent.eventTypeLabel('player_removed'), 'Player Removed');
      expect(ActivityEvent.eventTypeLabel('team_joined'), 'Team Joined');
      expect(ActivityEvent.eventTypeLabel('tournament_update'),
          'Tournament Update');
      expect(ActivityEvent.eventTypeLabel('tournament_match_result'),
          'Tournament Match Result');
      expect(ActivityEvent.eventTypeLabel('team_added_tournament'),
          'Team Added to Tournament');
      expect(ActivityEvent.eventTypeLabel('registration_resolved'),
          'Registration Resolved');
      expect(ActivityEvent.eventTypeLabel('fixtures_generated'),
          'Fixtures Generated');
    });

    test('returns raw event type string for unknown types', () {
      expect(ActivityEvent.eventTypeLabel('unknown'), 'unknown');
      expect(ActivityEvent.eventTypeLabel('custom_event'), 'custom_event');
    });
  });

  group('ActivityEvent.allEventTypes', () {
    test('contains exactly 17 event types', () {
      expect(ActivityEvent.allEventTypes.length, 17);
    });

    test('contains all known event types', () {
      const expectedTypes = [
        'century',
        'half_century',
        'five_wicket_haul',
        'three_wicket_haul',
        'hat_trick',
        'match_completed',
        'match_started',
        'match_abandoned',
        'innings_completed',
        'player_added',
        'player_removed',
        'team_joined',
        'tournament_update',
        'tournament_match_result',
        'team_added_tournament',
        'registration_resolved',
        'fixtures_generated',
      ];

      for (final type in expectedTypes) {
        expect(ActivityEvent.allEventTypes, contains(type));
      }
    });

    test('has no duplicates', () {
      final uniqueTypes = ActivityEvent.allEventTypes.toSet();
      expect(uniqueTypes.length, ActivityEvent.allEventTypes.length);
    });
  });

  group('ActivityEvent.eventTypeGroups', () {
    test('has four groups', () {
      expect(ActivityEvent.eventTypeGroups.keys.toList(),
          ['Player', 'Match', 'Team', 'Tournament']);
    });

    test('all group items are in allEventTypes', () {
      for (final types in ActivityEvent.eventTypeGroups.values) {
        for (final type in types) {
          expect(ActivityEvent.allEventTypes, contains(type));
        }
      }
    });
  });
}
