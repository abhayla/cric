import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/home/data/models/match_list_item_model.dart';

void main() {
  group('MatchListItemModel', () {
    final fullJson = {
      'id': 'match-1',
      'homeTeam': {'id': 'team-1', 'name': 'Mumbai'},
      'awayTeam': {'id': 'team-2', 'name': 'Chennai'},
      'format': 'T20',
      'totalOvers': 20,
      'status': 'live',
      'matchDate': '2026-03-15',
      'venue': 'Wankhede Stadium',
      'currentInnings': {
        'battingTeamId': 'team-1',
        'totalRuns': 150,
        'totalWickets': 5,
        'overs': '15.3',
      },
      'result': 'Mumbai won by 15 runs',
    };

    test('fromJson parses all fields', () {
      final model = MatchListItemModel.fromJson(fullJson);

      expect(model.id, 'match-1');
      expect(model.homeTeam.id, 'team-1');
      expect(model.homeTeam.name, 'Mumbai');
      expect(model.awayTeam.id, 'team-2');
      expect(model.awayTeam.name, 'Chennai');
      expect(model.format, 'T20');
      expect(model.totalOvers, 20);
      expect(model.status, 'live');
      expect(model.matchDate, '2026-03-15');
      expect(model.venue, 'Wankhede Stadium');
      expect(model.currentInnings, isNotNull);
      expect(model.currentInnings!.totalRuns, 150);
      expect(model.result, 'Mumbai won by 15 runs');
    });

    test('fromJson handles nullable fields', () {
      final minJson = {
        'id': 'match-2',
        'homeTeam': {'id': 'team-1', 'name': 'Mumbai'},
        'awayTeam': {'id': 'team-2', 'name': 'Chennai'},
        'format': 'ODI',
        'totalOvers': 50,
        'status': 'setup',
        'matchDate': '2026-03-15',
      };

      final model = MatchListItemModel.fromJson(minJson);

      expect(model.venue, isNull);
      expect(model.currentInnings, isNull);
      expect(model.result, isNull);
    });

    test('toEntity maps all fields correctly', () {
      final model = MatchListItemModel.fromJson(fullJson);
      final entity = model.toEntity();

      expect(entity.id, 'match-1');
      expect(entity.homeTeamName, 'Mumbai');
      expect(entity.awayTeamName, 'Chennai');
      expect(entity.format, 'T20');
      expect(entity.totalOvers, 20);
      expect(entity.status, 'live');
      expect(entity.matchDate, '2026-03-15');
      expect(entity.venue, 'Wankhede Stadium');
      expect(entity.currentInnings, isNotNull);
      expect(entity.currentInnings!.totalRuns, 150);
      expect(entity.currentInnings!.totalWickets, 5);
      expect(entity.currentInnings!.overs, '15.3');
      expect(entity.result, 'Mumbai won by 15 runs');
    });

    test('toEntity maps nullable fields as null', () {
      final model = MatchListItemModel.fromJson({
        'id': 'match-3',
        'homeTeam': {'id': 'team-1', 'name': 'Delhi'},
        'awayTeam': {'id': 'team-2', 'name': 'Kolkata'},
        'format': 'T20',
        'totalOvers': 20,
        'status': 'setup',
        'matchDate': '2026-04-01',
      });

      final entity = model.toEntity();

      expect(entity.venue, isNull);
      expect(entity.currentInnings, isNull);
      expect(entity.result, isNull);
    });

    test('fromJson parses all status values', () {
      for (final status in ['setup', 'toss', 'live', 'completed', 'abandoned']) {
        final json = {
          'id': 'match-$status',
          'homeTeam': {'id': 't1', 'name': 'A'},
          'awayTeam': {'id': 't2', 'name': 'B'},
          'format': 'T20',
          'totalOvers': 20,
          'status': status,
          'matchDate': '2026-03-15',
        };
        final model = MatchListItemModel.fromJson(json);
        expect(model.status, status);
      }
    });
  });

  group('InningsSnapshotModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'battingTeamId': 'team-1',
        'totalRuns': 200,
        'totalWickets': 8,
        'overs': '20.0',
      };

      final model = InningsSnapshotModel.fromJson(json);
      expect(model.battingTeamId, 'team-1');
      expect(model.totalRuns, 200);
      expect(model.totalWickets, 8);
      expect(model.overs, '20.0');
    });
  });

  group('TeamRefModel', () {
    test('fromJson parses correctly', () {
      final json = {'id': 'team-1', 'name': 'Mumbai'};
      final model = TeamRefModel.fromJson(json);
      expect(model.id, 'team-1');
      expect(model.name, 'Mumbai');
    });
  });
}
