import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/data/models/standing_model.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/standing.dart';

void main() {
  group('StandingModel', () {
    final json = {
      'tournamentId': 'tour-1',
      'teamId': 'team-1',
      'played': 5,
      'won': 3,
      'lost': 1,
      'tied': 1,
      'noResult': 0,
      'points': 7,
      'nrr': '0.625',
      'totalRunsScored': 850,
      'totalOversFaced': '100.0',
      'totalRunsConceded': 780,
      'totalOversBowled': '96.3',
      'groupName': 'A',
      'position': 1,
      'teamName': 'Warriors',
    };

    test('fromJson parses all fields', () {
      final model = StandingModel.fromJson(json);

      expect(model.tournamentId, 'tour-1');
      expect(model.teamId, 'team-1');
      expect(model.played, 5);
      expect(model.won, 3);
      expect(model.lost, 1);
      expect(model.tied, 1);
      expect(model.noResult, 0);
      expect(model.points, 7);
      expect(model.nrr, '0.625');
      expect(model.totalRunsScored, 850);
      expect(model.totalOversFaced, '100.0');
      expect(model.totalRunsConceded, 780);
      expect(model.totalOversBowled, '96.3');
      expect(model.groupName, 'A');
      expect(model.position, 1);
      expect(model.teamName, 'Warriors');
    });

    test('fromJson handles null optional fields', () {
      final minJson = {
        'tournamentId': 'tour-1',
        'teamId': 'team-1',
        'played': 0,
        'won': 0,
        'lost': 0,
        'tied': 0,
        'noResult': 0,
        'points': 0,
        'nrr': '0.000',
        'totalRunsScored': 0,
        'totalOversFaced': '0.0',
        'totalRunsConceded': 0,
        'totalOversBowled': '0.0',
      };

      final model = StandingModel.fromJson(minJson);

      expect(model.groupName, isNull);
      expect(model.position, isNull);
      expect(model.teamName, isNull);
    });

    test('toJson round-trips correctly', () {
      final model = StandingModel.fromJson(json);
      final output = model.toJson();

      expect(output['tournamentId'], 'tour-1');
      expect(output['teamId'], 'team-1');
      expect(output['played'], 5);
      expect(output['nrr'], '0.625');
    });

    test('toEntity maps all fields correctly', () {
      final entity = StandingModel.fromJson(json).toEntity();

      expect(entity, isA<Standing>());
      expect(entity.tournamentId, 'tour-1');
      expect(entity.teamId, 'team-1');
      expect(entity.played, 5);
      expect(entity.won, 3);
      expect(entity.lost, 1);
      expect(entity.tied, 1);
      expect(entity.noResult, 0);
      expect(entity.points, 7);
      expect(entity.groupName, 'A');
      expect(entity.position, 1);
      expect(entity.teamName, 'Warriors');
    });

    test('toEntity parses nrr from string to double', () {
      final entity = StandingModel.fromJson(json).toEntity();
      expect(entity.nrr, 0.625);
    });

    test('toEntity parses negative nrr', () {
      final negJson = {...json, 'nrr': '-1.234'};
      final entity = StandingModel.fromJson(negJson).toEntity();
      expect(entity.nrr, -1.234);
    });

    test('toEntity defaults nrr to 0 for invalid string', () {
      final badJson = {...json, 'nrr': 'invalid'};
      final entity = StandingModel.fromJson(badJson).toEntity();
      expect(entity.nrr, 0.0);
    });

    test('toEntity parses overs from string to double', () {
      final entity = StandingModel.fromJson(json).toEntity();
      expect(entity.totalOversFaced, 100.0);
      expect(entity.totalOversBowled, 96.3);
    });

    test('toEntity defaults overs to 0 for invalid string', () {
      final badJson = {
        ...json,
        'totalOversFaced': 'bad',
        'totalOversBowled': 'bad',
      };
      final entity = StandingModel.fromJson(badJson).toEntity();
      expect(entity.totalOversFaced, 0.0);
      expect(entity.totalOversBowled, 0.0);
    });
  });
}
