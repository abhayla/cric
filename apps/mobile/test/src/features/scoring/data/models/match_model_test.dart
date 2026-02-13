import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/data/models/match_model.dart';
import 'package:cricapp/src/features/scoring/domain/entities/match.dart';

void main() {
  group('MatchModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'T20',
        'totalOvers': 20,
        'ballTypeId': 1,
        'status': 'setup',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
      };

      final model = MatchModel.fromJson(json);

      expect(model.id, 'match-1');
      expect(model.homeTeamId, 'team-home');
      expect(model.awayTeamId, 'team-away');
      expect(model.format, 'T20');
      expect(model.totalOvers, 20);
      expect(model.ballTypeId, 1);
      expect(model.status, 'setup');
      expect(model.playersPerSide, 11);
      expect(model.wideRuns, 1);
      expect(model.noBallRuns, 1);
      expect(model.scorerId, 'user-1');
      expect(model.createdBy, 'user-1');
      expect(model.matchDate, '2026-01-15');
    });

    test('fromJson parses optional fields', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'T20',
        'totalOvers': 20,
        'ballTypeId': 1,
        'status': 'live',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
        'homeTeamName': 'Mumbai Warriors',
        'awayTeamName': 'Delhi Capitals',
        'venue': 'Wankhede Stadium',
        'tossWinnerId': 'team-home',
        'tossDecision': 'bat',
        'maxOversPerBowler': 4,
        'powerplayOvers': 6,
        'tournamentId': 'tournament-1',
      };

      final model = MatchModel.fromJson(json);

      expect(model.homeTeamName, 'Mumbai Warriors');
      expect(model.awayTeamName, 'Delhi Capitals');
      expect(model.venue, 'Wankhede Stadium');
      expect(model.tossWinnerId, 'team-home');
      expect(model.tossDecision, 'bat');
      expect(model.maxOversPerBowler, 4);
      expect(model.powerplayOvers, 6);
      expect(model.tournamentId, 'tournament-1');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'T20',
        'totalOvers': 20,
        'ballTypeId': 1,
        'status': 'setup',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
      };

      final model = MatchModel.fromJson(json);

      expect(model.homeTeamName, isNull);
      expect(model.awayTeamName, isNull);
      expect(model.venue, isNull);
      expect(model.tossWinnerId, isNull);
      expect(model.tossDecision, isNull);
      expect(model.maxOversPerBowler, isNull);
      expect(model.powerplayOvers, isNull);
      expect(model.tournamentId, isNull);
    });

    test('toJson round-trips correctly', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'T20',
        'totalOvers': 20,
        'ballTypeId': 1,
        'status': 'setup',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
      };

      final model = MatchModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], 'match-1');
      expect(output['homeTeamId'], 'team-home');
      expect(output['format'], 'T20');
      expect(output['totalOvers'], 20);
      expect(output['status'], 'setup');
    });

    test('toEntity maps all fields correctly', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'T20',
        'totalOvers': 20,
        'ballTypeId': 1,
        'status': 'live',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
        'homeTeamName': 'Mumbai Warriors',
        'awayTeamName': 'Delhi Capitals',
        'venue': 'Wankhede Stadium',
        'tossWinnerId': 'team-home',
        'tossDecision': 'bat',
        'maxOversPerBowler': 4,
        'powerplayOvers': 6,
        'tournamentId': 'tour-1',
      };

      final model = MatchModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity, isA<Match>());
      expect(entity.id, 'match-1');
      expect(entity.format, MatchFormat.t20);
      expect(entity.status, MatchStatus.live);
      expect(entity.homeTeamName, 'Mumbai Warriors');
      expect(entity.tossDecision, TossDecision.bat);
      expect(entity.maxOversPerBowler, 4);
      expect(entity.tournamentId, 'tour-1');
    });

    test('toEntity handles "bowl" toss decision as field', () {
      final json = {
        'id': 'match-1',
        'homeTeamId': 'team-home',
        'awayTeamId': 'team-away',
        'format': 'ODI',
        'totalOvers': 50,
        'ballTypeId': 1,
        'status': 'live',
        'playersPerSide': 11,
        'wideRuns': 1,
        'noBallRuns': 1,
        'scorerId': 'user-1',
        'createdBy': 'user-1',
        'matchDate': '2026-01-15',
        'createdAt': '2026-01-15T10:00:00.000Z',
        'updatedAt': '2026-01-15T10:00:00.000Z',
        'tossDecision': 'bowl',
      };

      final entity = MatchModel.fromJson(json).toEntity();
      expect(entity.tossDecision, TossDecision.field);
    });
  });

  group('PlayingXIModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'mp-1',
        'matchId': 'match-1',
        'teamId': 'team-1',
        'playerId': 'player-1',
        'battingOrder': 1,
        'isPlaying': true,
        'isCaptain': true,
        'isKeeper': false,
        'displayName': 'Virat Kohli',
        'playerRole': 'batter',
        'battingStyle': 'right_hand',
        'bowlingStyle': 'right_arm_medium',
      };

      final model = PlayingXIModel.fromJson(json);

      expect(model.id, 'mp-1');
      expect(model.matchId, 'match-1');
      expect(model.teamId, 'team-1');
      expect(model.playerId, 'player-1');
      expect(model.battingOrder, 1);
      expect(model.isPlaying, true);
      expect(model.isCaptain, true);
      expect(model.isKeeper, false);
      expect(model.displayName, 'Virat Kohli');
      expect(model.playerRole, 'batter');
      expect(model.battingStyle, 'right_hand');
      expect(model.bowlingStyle, 'right_arm_medium');
    });

    test('toEntity maps to PlayingXIEntry', () {
      final json = {
        'id': 'mp-1',
        'matchId': 'match-1',
        'teamId': 'team-1',
        'playerId': 'player-1',
        'battingOrder': 3,
        'isPlaying': true,
        'isCaptain': false,
        'isKeeper': true,
        'displayName': 'MS Dhoni',
        'playerRole': 'wk_batter',
        'battingStyle': 'right_hand',
        'bowlingStyle': 'none',
      };

      final model = PlayingXIModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity, isA<PlayingXIEntry>());
      expect(entity.playerId, 'player-1');
      expect(entity.displayName, 'MS Dhoni');
      expect(entity.isCaptain, false);
      expect(entity.isKeeper, true);
      expect(entity.playerRole, 'wk_batter');
      expect(entity.battingOrder, 3);
      expect(entity.badge, '(WK)');
    });

    test('toJson round-trips correctly', () {
      final json = {
        'id': 'mp-1',
        'matchId': 'match-1',
        'teamId': 'team-1',
        'playerId': 'player-1',
        'battingOrder': 1,
        'isPlaying': true,
        'isCaptain': true,
        'isKeeper': false,
      };

      final model = PlayingXIModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], 'mp-1');
      expect(output['playerId'], 'player-1');
      expect(output['isCaptain'], true);
    });
  });
}
