import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/data/models/tournament_model.dart';
import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';

void main() {
  group('TournamentModel', () {
    final json = {
      'id': 'tour-1',
      'name': 'Summer League',
      'format': 'round_robin',
      'oversPerMatch': 20,
      'ballTypeId': 1,
      'status': 'draft',
      'pointsWin': 2,
      'pointsTie': 1,
      'pointsNoResult': 1,
      'pointsLoss': 0,
      'numGroups': 1,
      'qualifyPerGroup': 2,
      'hasThirdPlaceMatch': false,
      'playersPerSide': 11,
      'wideRuns': 1,
      'noBallRuns': 1,
      'createdBy': 'user-1',
      'createdAt': '2026-01-15T10:00:00.000Z',
      'updatedAt': '2026-01-15T10:00:00.000Z',
    };

    test('fromJson parses all required fields', () {
      final model = TournamentModel.fromJson(json);

      expect(model.id, 'tour-1');
      expect(model.name, 'Summer League');
      expect(model.format, 'round_robin');
      expect(model.oversPerMatch, 20);
      expect(model.ballTypeId, 1);
      expect(model.status, 'draft');
      expect(model.pointsWin, 2);
      expect(model.pointsTie, 1);
      expect(model.pointsNoResult, 1);
      expect(model.pointsLoss, 0);
      expect(model.numGroups, 1);
      expect(model.qualifyPerGroup, 2);
      expect(model.hasThirdPlaceMatch, false);
      expect(model.playersPerSide, 11);
      expect(model.wideRuns, 1);
      expect(model.noBallRuns, 1);
      expect(model.createdBy, 'user-1');
    });

    test('fromJson parses optional fields', () {
      final fullJson = {
        ...json,
        'maxOversPerBowler': 4,
        'powerplayOvers': 6,
        'startDate': '2026-03-01',
        'endDate': '2026-03-31',
        'teamCount': 8,
      };

      final model = TournamentModel.fromJson(fullJson);

      expect(model.maxOversPerBowler, 4);
      expect(model.powerplayOvers, 6);
      expect(model.startDate, '2026-03-01');
      expect(model.endDate, '2026-03-31');
      expect(model.teamCount, 8);
    });

    test('fromJson handles null optional fields', () {
      final model = TournamentModel.fromJson(json);

      expect(model.maxOversPerBowler, isNull);
      expect(model.powerplayOvers, isNull);
      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.teamCount, isNull);
      expect(model.teams, isNull);
      expect(model.groups, isNull);
    });

    test('fromJson applies default values', () {
      final minJson = {
        'id': 'tour-1',
        'name': 'Test',
        'format': 'knockout',
        'oversPerMatch': 10,
        'ballTypeId': 2,
        'status': 'draft',
        'createdBy': 'user-1',
      };

      final model = TournamentModel.fromJson(minJson);

      expect(model.pointsWin, 2);
      expect(model.pointsTie, 1);
      expect(model.pointsNoResult, 1);
      expect(model.pointsLoss, 0);
      expect(model.numGroups, 1);
      expect(model.qualifyPerGroup, 2);
      expect(model.hasThirdPlaceMatch, false);
      expect(model.playersPerSide, 11);
      expect(model.wideRuns, 1);
      expect(model.noBallRuns, 1);
    });

    test('toJson round-trips correctly', () {
      final model = TournamentModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], 'tour-1');
      expect(output['name'], 'Summer League');
      expect(output['format'], 'round_robin');
      expect(output['oversPerMatch'], 20);
      expect(output['status'], 'draft');
    });

    test('toEntity maps all fields correctly', () {
      final fullJson = {
        ...json,
        'status': 'live',
        'maxOversPerBowler': 4,
        'powerplayOvers': 6,
        'startDate': '2026-03-01',
        'endDate': '2026-03-31',
        'teamCount': 8,
      };

      final entity = TournamentModel.fromJson(fullJson).toEntity();

      expect(entity, isA<Tournament>());
      expect(entity.id, 'tour-1');
      expect(entity.name, 'Summer League');
      expect(entity.format, TournamentFormat.roundRobin);
      expect(entity.status, TournamentStatus.live);
      expect(entity.oversPerMatch, 20);
      expect(entity.maxOversPerBowler, 4);
      expect(entity.powerplayOvers, 6);
      expect(entity.startDate, '2026-03-01');
      expect(entity.endDate, '2026-03-31');
      expect(entity.teamCount, 8);
    });

    test('toEntity parses dates correctly', () {
      final entity = TournamentModel.fromJson(json).toEntity();

      expect(entity.createdAt, DateTime.parse('2026-01-15T10:00:00.000Z'));
      expect(entity.updatedAt, DateTime.parse('2026-01-15T10:00:00.000Z'));
    });

    test('toEntity defaults dates to now when null', () {
      final noDateJson = {
        ...json,
      };
      noDateJson.remove('createdAt');
      noDateJson.remove('updatedAt');

      final entity = TournamentModel.fromJson(noDateJson).toEntity();

      expect(entity.createdAt, isA<DateTime>());
      expect(entity.updatedAt, isA<DateTime>());
    });

    test('fromJson parses nested teams', () {
      final withTeams = {
        ...json,
        'teams': [
          {
            'id': 'tt-1',
            'tournamentId': 'tour-1',
            'teamId': 'team-1',
            'joinedAt': '2026-01-16T10:00:00.000Z',
            'updatedAt': '2026-01-16T10:00:00.000Z',
            'groupName': 'A',
            'seedNumber': 1,
            'teamName': 'Warriors',
          },
        ],
      };

      final model = TournamentModel.fromJson(withTeams);

      expect(model.teams, isNotNull);
      expect(model.teams!.length, 1);
      expect(model.teams!.first.teamId, 'team-1');
      expect(model.teams!.first.groupName, 'A');
      expect(model.teams!.first.seedNumber, 1);
    });

    test('fromJson parses nested groups', () {
      final withGroups = {
        ...json,
        'groups': [
          {'name': 'A', 'teamCount': 4},
          {'name': 'B', 'teamCount': 4},
        ],
      };

      final model = TournamentModel.fromJson(withGroups);

      expect(model.groups, isNotNull);
      expect(model.groups!.length, 2);
      expect(model.groups!.first.name, 'A');
      expect(model.groups!.first.teamCount, 4);
    });
  });

  group('TournamentTeamModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'tt-1',
        'tournamentId': 'tour-1',
        'teamId': 'team-1',
        'joinedAt': '2026-01-16T10:00:00.000Z',
        'updatedAt': '2026-01-16T10:00:00.000Z',
        'groupName': 'B',
        'seedNumber': 3,
        'teamName': 'Delhi Capitals',
      };

      final model = TournamentTeamModel.fromJson(json);

      expect(model.id, 'tt-1');
      expect(model.tournamentId, 'tour-1');
      expect(model.teamId, 'team-1');
      expect(model.groupName, 'B');
      expect(model.seedNumber, 3);
      expect(model.teamName, 'Delhi Capitals');
    });

    test('toEntity maps correctly', () {
      final json = {
        'id': 'tt-1',
        'tournamentId': 'tour-1',
        'teamId': 'team-1',
        'joinedAt': '2026-01-16T10:00:00.000Z',
        'updatedAt': '2026-01-16T10:00:00.000Z',
        'groupName': 'A',
        'seedNumber': 1,
        'teamName': 'Warriors',
      };

      final entity = TournamentTeamModel.fromJson(json).toEntity();

      expect(entity, isA<TournamentTeam>());
      expect(entity.id, 'tt-1');
      expect(entity.teamId, 'team-1');
      expect(entity.groupName, 'A');
      expect(entity.seedNumber, 1);
      expect(entity.teamName, 'Warriors');
    });
  });

  group('TournamentGroupModel', () {
    test('fromJson parses all fields', () {
      final json = {'name': 'A', 'teamCount': 4};
      final model = TournamentGroupModel.fromJson(json);

      expect(model.name, 'A');
      expect(model.teamCount, 4);
    });

    test('toEntity maps correctly', () {
      final json = {'name': 'B', 'teamCount': 3};
      final entity = TournamentGroupModel.fromJson(json).toEntity();

      expect(entity, isA<TournamentGroup>());
      expect(entity.name, 'B');
      expect(entity.teamCount, 3);
    });
  });
}
