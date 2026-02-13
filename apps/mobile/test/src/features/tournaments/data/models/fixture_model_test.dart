import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/data/models/fixture_model.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/fixture.dart';

void main() {
  group('FixtureModel', () {
    final json = {
      'id': 'fix-1',
      'tournamentId': 'tour-1',
      'roundNumber': 1,
      'roundType': 'group',
      'fixtureOrder': 1,
      'homeTeamId': 'team-1',
      'awayTeamId': 'team-2',
    };

    test('fromJson parses required fields', () {
      final model = FixtureModel.fromJson(json);

      expect(model.id, 'fix-1');
      expect(model.tournamentId, 'tour-1');
      expect(model.roundNumber, 1);
      expect(model.roundType, 'group');
      expect(model.fixtureOrder, 1);
      expect(model.homeTeamId, 'team-1');
      expect(model.awayTeamId, 'team-2');
    });

    test('fromJson parses optional fields', () {
      final fullJson = {
        ...json,
        'matchId': 'match-1',
        'groupName': 'A',
        'homeTeamName': 'Warriors',
        'awayTeamName': 'Kings',
        'scheduledDate': '2026-03-15',
        'scheduledTime': '14:00',
        'estimatedDurationMinutes': 180,
        'venue': 'Stadium',
        'result': {
          'winner': 'team-1',
          'summary': 'Warriors won by 5 wickets',
        },
      };

      final model = FixtureModel.fromJson(fullJson);

      expect(model.matchId, 'match-1');
      expect(model.groupName, 'A');
      expect(model.homeTeamName, 'Warriors');
      expect(model.awayTeamName, 'Kings');
      expect(model.scheduledDate, '2026-03-15');
      expect(model.scheduledTime, '14:00');
      expect(model.estimatedDurationMinutes, 180);
      expect(model.venue, 'Stadium');
      expect(model.result, isNotNull);
      expect(model.result!.winner, 'team-1');
      expect(model.result!.summary, 'Warriors won by 5 wickets');
    });

    test('fromJson handles null optional fields', () {
      final model = FixtureModel.fromJson(json);

      expect(model.matchId, isNull);
      expect(model.groupName, isNull);
      expect(model.homeTeamName, isNull);
      expect(model.awayTeamName, isNull);
      expect(model.scheduledDate, isNull);
      expect(model.scheduledTime, isNull);
      expect(model.estimatedDurationMinutes, isNull);
      expect(model.venue, isNull);
      expect(model.result, isNull);
    });

    test('toJson round-trips correctly', () {
      final model = FixtureModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], 'fix-1');
      expect(output['tournamentId'], 'tour-1');
      expect(output['roundType'], 'group');
      expect(output['homeTeamId'], 'team-1');
    });

    test('toEntity maps all fields correctly', () {
      final fullJson = {
        ...json,
        'roundType': 'semi_final',
        'matchId': 'match-1',
        'groupName': 'A',
        'homeTeamName': 'Warriors',
        'awayTeamName': 'Kings',
        'scheduledDate': '2026-03-15',
        'scheduledTime': '14:00',
        'estimatedDurationMinutes': 180,
        'venue': 'Stadium',
        'result': {
          'winner': 'team-1',
          'summary': 'Warriors won by 5 wickets',
        },
      };

      final entity = FixtureModel.fromJson(fullJson).toEntity();

      expect(entity, isA<Fixture>());
      expect(entity.id, 'fix-1');
      expect(entity.roundType, RoundType.semiFinal);
      expect(entity.matchId, 'match-1');
      expect(entity.homeTeamName, 'Warriors');
      expect(entity.result, isNotNull);
      expect(entity.result!.winner, 'team-1');
    });

    test('toEntity maps knockout round types', () {
      for (final entry in {
        'group': RoundType.group,
        'quarter_final': RoundType.quarterFinal,
        'semi_final': RoundType.semiFinal,
        'final': RoundType.final_,
        'third_place': RoundType.thirdPlace,
      }.entries) {
        final model = FixtureModel.fromJson({...json, 'roundType': entry.key});
        expect(model.toEntity().roundType, entry.value);
      }
    });
  });

  group('FixtureResultModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'winner': 'team-1',
        'summary': 'Warriors won by 5 wickets',
      };

      final model = FixtureResultModel.fromJson(json);

      expect(model.winner, 'team-1');
      expect(model.summary, 'Warriors won by 5 wickets');
    });

    test('toEntity maps correctly', () {
      final json = {
        'winner': 'team-2',
        'summary': 'Kings won by 20 runs',
      };

      final entity = FixtureResultModel.fromJson(json).toEntity();

      expect(entity, isA<FixtureResult>());
      expect(entity.winner, 'team-2');
      expect(entity.summary, 'Kings won by 20 runs');
    });
  });
}
