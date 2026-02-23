import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/fixture.dart';

void main() {
  group('RoundType', () {
    test('has exactly 5 values', () {
      expect(RoundType.values.length, 5);
    });

    test('contains expected values', () {
      expect(RoundType.values, contains(RoundType.group));
      expect(RoundType.values, contains(RoundType.quarterFinal));
      expect(RoundType.values, contains(RoundType.semiFinal));
      expect(RoundType.values, contains(RoundType.final_));
      expect(RoundType.values, contains(RoundType.thirdPlace));
    });

    test('labels are correct', () {
      expect(RoundType.group.label, 'Group');
      expect(RoundType.quarterFinal.label, 'Quarter Final');
      expect(RoundType.semiFinal.label, 'Semi Final');
      expect(RoundType.final_.label, 'Final');
      expect(RoundType.thirdPlace.label, '3rd Place');
    });

    test('apiValue maps correctly', () {
      expect(RoundType.group.apiValue, 'group');
      expect(RoundType.quarterFinal.apiValue, 'quarter_final');
      expect(RoundType.semiFinal.apiValue, 'semi_final');
      expect(RoundType.final_.apiValue, 'final');
      expect(RoundType.thirdPlace.apiValue, 'third_place');
    });

    test('fromApiValue parses correctly', () {
      expect(RoundType.fromApiValue('group'), RoundType.group);
      expect(RoundType.fromApiValue('quarter_final'), RoundType.quarterFinal);
      expect(RoundType.fromApiValue('semi_final'), RoundType.semiFinal);
      expect(RoundType.fromApiValue('final'), RoundType.final_);
      expect(RoundType.fromApiValue('third_place'), RoundType.thirdPlace);
    });

    test('fromApiValue throws for unknown value', () {
      expect(() => RoundType.fromApiValue('unknown'), throwsArgumentError);
    });

    test('isKnockout returns true for non-group rounds', () {
      expect(RoundType.group.isKnockout, false);
      expect(RoundType.quarterFinal.isKnockout, true);
      expect(RoundType.semiFinal.isKnockout, true);
      expect(RoundType.final_.isKnockout, true);
      expect(RoundType.thirdPlace.isKnockout, true);
    });
  });

  group('Fixture', () {
    Fixture createFixture({
      String id = 'fixture-1',
      String tournamentId = 'tournament-1',
      int roundNumber = 1,
      RoundType roundType = RoundType.group,
      int fixtureOrder = 1,
      String homeTeamId = 'team-home',
      String awayTeamId = 'team-away',
      String? matchId,
      String? groupName,
      String? homeTeamName,
      String? awayTeamName,
      String? scheduledDate,
      String? scheduledTime,
      int? estimatedDurationMinutes,
      String? venue,
      FixtureResult? result,
    }) {
      return Fixture(
        id: id,
        tournamentId: tournamentId,
        roundNumber: roundNumber,
        roundType: roundType,
        fixtureOrder: fixtureOrder,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        matchId: matchId,
        groupName: groupName,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
        venue: venue,
        result: result,
      );
    }

    test('creates with required fields', () {
      final fixture = createFixture();
      expect(fixture.id, 'fixture-1');
      expect(fixture.tournamentId, 'tournament-1');
      expect(fixture.roundNumber, 1);
      expect(fixture.roundType, RoundType.group);
      expect(fixture.fixtureOrder, 1);
      expect(fixture.homeTeamId, 'team-home');
      expect(fixture.awayTeamId, 'team-away');
    });

    test('optional fields default to null', () {
      final fixture = createFixture();
      expect(fixture.matchId, isNull);
      expect(fixture.groupName, isNull);
      expect(fixture.homeTeamName, isNull);
      expect(fixture.awayTeamName, isNull);
      expect(fixture.scheduledDate, isNull);
      expect(fixture.scheduledTime, isNull);
      expect(fixture.estimatedDurationMinutes, isNull);
      expect(fixture.venue, isNull);
      expect(fixture.result, isNull);
    });

    test('creates with all optional fields', () {
      final fixture = createFixture(
        matchId: 'match-1',
        groupName: 'A',
        homeTeamName: 'Mumbai Warriors',
        awayTeamName: 'Delhi Strikers',
        scheduledDate: '2026-03-01',
        scheduledTime: '14:30',
        estimatedDurationMinutes: 180,
        venue: 'Wankhede Stadium',
        result: const FixtureResult(
          winner: 'Mumbai Warriors',
          summary: 'Mumbai Warriors won by 5 wickets',
        ),
      );

      expect(fixture.matchId, 'match-1');
      expect(fixture.groupName, 'A');
      expect(fixture.homeTeamName, 'Mumbai Warriors');
      expect(fixture.awayTeamName, 'Delhi Strikers');
      expect(fixture.scheduledDate, '2026-03-01');
      expect(fixture.scheduledTime, '14:30');
      expect(fixture.estimatedDurationMinutes, 180);
      expect(fixture.venue, 'Wankhede Stadium');
      expect(fixture.result, isNotNull);
    });

    test('hasMatch returns true when matchId is set', () {
      expect(createFixture().hasMatch, false);
      expect(createFixture(matchId: 'match-1').hasMatch, true);
    });

    test('isCompleted returns true when result is set', () {
      expect(createFixture().isCompleted, false);
      expect(
        createFixture(
          result: const FixtureResult(winner: 'Team A', summary: 'Won'),
        ).isCompleted,
        true,
      );
    });

    test('title returns team names or TBD', () {
      expect(
        createFixture(
          homeTeamName: 'Mumbai',
          awayTeamName: 'Delhi',
        ).title,
        'Mumbai vs Delhi',
      );
      expect(createFixture().title, 'TBD vs TBD');
      expect(createFixture(homeTeamName: 'Mumbai').title, 'Mumbai vs TBD');
    });

    test('scheduleDescription returns null when no date', () {
      expect(createFixture().scheduleDescription, isNull);
    });

    test('scheduleDescription returns date only when no time', () {
      expect(
        createFixture(scheduledDate: '2026-03-01').scheduleDescription,
        '2026-03-01',
      );
    });

    test('scheduleDescription returns date and time when both set', () {
      expect(
        createFixture(
          scheduledDate: '2026-03-01',
          scheduledTime: '14:30',
        ).scheduleDescription,
        '2026-03-01 at 14:30',
      );
    });
  });

  group('FixtureResult', () {
    test('creates with required fields', () {
      const result = FixtureResult(
        winner: 'Mumbai Warriors',
        summary: 'Mumbai Warriors won by 15 runs',
      );
      expect(result.winner, 'Mumbai Warriors');
      expect(result.summary, 'Mumbai Warriors won by 15 runs');
    });
  });
}
