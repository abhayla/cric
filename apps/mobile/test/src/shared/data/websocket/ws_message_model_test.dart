import 'dart:convert';

import 'package:cricscores/src/shared/data/websocket/ws_message_model.dart';
import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WsPlayerBattingSnapshot', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'p1',
        'name': 'Virat Kohli',
        'runs': 56,
        'balls': 38,
        'fours': 6,
        'sixes': 2,
        'strikeRate': 147.37,
      };

      final snapshot = WsPlayerBattingSnapshot.fromJson(json);

      expect(snapshot.id, 'p1');
      expect(snapshot.name, 'Virat Kohli');
      expect(snapshot.runs, 56);
      expect(snapshot.balls, 38);
      expect(snapshot.fours, 6);
      expect(snapshot.sixes, 2);
      expect(snapshot.strikeRate, 147.37);
    });

    test('toBatterInnings converts to domain entity', () {
      const snapshot = WsPlayerBattingSnapshot(
        id: 'p1',
        name: 'Rohit Sharma',
        runs: 45,
        balls: 30,
        fours: 5,
        sixes: 1,
        strikeRate: 150.0,
      );

      final entity = snapshot.toBatterInnings();

      expect(entity, isA<BatterInnings>());
      expect(entity.playerId, 'p1');
      expect(entity.displayName, 'Rohit Sharma');
      expect(entity.runsScored, 45);
      expect(entity.ballsFaced, 30);
      expect(entity.fours, 5);
      expect(entity.sixes, 1);
    });
  });

  group('WsPlayerBowlingSnapshot', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'b1',
        'name': 'Jasprit Bumrah',
        'overs': '4.0',
        'maidens': 1,
        'runs': 28,
        'wickets': 3,
        'economy': 7.0,
      };

      final snapshot = WsPlayerBowlingSnapshot.fromJson(json);

      expect(snapshot.id, 'b1');
      expect(snapshot.name, 'Jasprit Bumrah');
      expect(snapshot.overs, '4.0');
      expect(snapshot.maidens, 1);
      expect(snapshot.runs, 28);
      expect(snapshot.wickets, 3);
      expect(snapshot.economy, 7.0);
    });

    test('toBowlerSpell converts to domain entity with complete overs', () {
      const snapshot = WsPlayerBowlingSnapshot(
        id: 'b1',
        name: 'Bumrah',
        overs: '4.0',
        maidens: 1,
        runs: 28,
        wickets: 3,
        economy: 7.0,
      );

      final entity = snapshot.toBowlerSpell();

      expect(entity, isA<BowlerSpell>());
      expect(entity.playerId, 'b1');
      expect(entity.displayName, 'Bumrah');
      expect(entity.ballsBowled, 24); // 4.0 overs = 24 balls
      expect(entity.maidens, 1);
      expect(entity.runsConceded, 28);
      expect(entity.wicketsTaken, 3);
    });

    test('toBowlerSpell converts partial overs correctly', () {
      const snapshot = WsPlayerBowlingSnapshot(
        id: 'b2',
        name: 'Ashwin',
        overs: '3.4',
        maidens: 0,
        runs: 22,
        wickets: 1,
        economy: 5.74,
      );

      final entity = snapshot.toBowlerSpell();

      expect(entity.ballsBowled, 22); // 3 * 6 + 4 = 22
    });

    test('toBowlerSpell handles zero overs', () {
      const snapshot = WsPlayerBowlingSnapshot(
        id: 'b3',
        name: 'Test',
        overs: '0.0',
        maidens: 0,
        runs: 0,
        wickets: 0,
        economy: 0,
      );

      final entity = snapshot.toBowlerSpell();

      expect(entity.ballsBowled, 0);
    });
  });

  group('WsOverBallDisplay', () {
    test('fromJson parses with isWicket', () {
      final json = {
        'runs': 0,
        'display': 'W',
        'isWicket': true,
      };

      final ball = WsOverBallDisplay.fromJson(json);

      expect(ball.runs, 0);
      expect(ball.display, 'W');
      expect(ball.isWicket, true);
    });

    test('fromJson defaults isWicket to false', () {
      final json = {
        'runs': 4,
        'display': '4',
      };

      final ball = WsOverBallDisplay.fromJson(json);

      expect(ball.runs, 4);
      expect(ball.display, '4');
      expect(ball.isWicket, false);
    });
  });

  group('WsLastDeliveryInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'runs': 4,
        'isWide': false,
        'isNoBall': false,
        'isBye': false,
        'isLegBye': false,
        'isWicket': false,
        'isBoundaryFour': true,
        'isBoundarySix': false,
        'description': 'FOUR! Through covers',
      };

      final delivery = WsLastDeliveryInfo.fromJson(json);

      expect(delivery.runs, 4);
      expect(delivery.isWide, false);
      expect(delivery.isBoundaryFour, true);
      expect(delivery.description, 'FOUR! Through covers');
    });
  });

  group('WsMatchStateMessage', () {
    test('fromJson parses full match state', () {
      final json = {
        'type': 'match_state',
        'matchId': 'm1',
        'data': {
          'status': 'LIVE',
          'inningsNumber': 1,
          'totalRuns': 120,
          'totalWickets': 3,
          'overs': '15.2',
          'currentRunRate': 7.83,
          'requiredRunRate': null,
          'target': null,
          'striker': {
            'id': 'p1',
            'name': 'Kohli',
            'runs': 56,
            'balls': 38,
            'fours': 6,
            'sixes': 2,
            'strikeRate': 147.37,
          },
          'nonStriker': {
            'id': 'p2',
            'name': 'Rohit',
            'runs': 30,
            'balls': 22,
            'fours': 4,
            'sixes': 0,
            'strikeRate': 136.36,
          },
          'bowler': {
            'id': 'b1',
            'name': 'Bumrah',
            'overs': '3.2',
            'maidens': 0,
            'runs': 24,
            'wickets': 1,
            'economy': 7.2,
          },
          'currentOver': [
            {'runs': 1, 'display': '1'},
            {'runs': 0, 'display': '.'},
          ],
          'recentDeliveries': [
            {'runs': 4, 'display': '4'},
          ],
        },
      };

      final msg = WsMatchStateMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.status, 'LIVE');
      expect(msg.data.inningsNumber, 1);
      expect(msg.data.totalRuns, 120);
      expect(msg.data.totalWickets, 3);
      expect(msg.data.overs, '15.2');
      expect(msg.data.currentRunRate, 7.83);
      expect(msg.data.requiredRunRate, isNull);
      expect(msg.data.target, isNull);
      expect(msg.data.striker, isNotNull);
      expect(msg.data.striker!.name, 'Kohli');
      expect(msg.data.nonStriker, isNotNull);
      expect(msg.data.bowler, isNotNull);
      expect(msg.data.currentOver, hasLength(2));
      expect(msg.data.recentDeliveries, hasLength(1));
    });

    test('fromJson handles null players', () {
      final json = {
        'type': 'match_state',
        'matchId': 'm1',
        'data': {
          'status': 'SETUP',
          'inningsNumber': 1,
          'totalRuns': 0,
          'totalWickets': 0,
          'overs': '0.0',
          'currentRunRate': null,
          'requiredRunRate': null,
          'target': null,
          'striker': null,
          'nonStriker': null,
          'bowler': null,
          'currentOver': <Map<String, dynamic>>[],
          'recentDeliveries': <Map<String, dynamic>>[],
        },
      };

      final msg = WsMatchStateMessage.fromJson(json);

      expect(msg.data.striker, isNull);
      expect(msg.data.nonStriker, isNull);
      expect(msg.data.bowler, isNull);
    });
  });

  group('WsScoreUpdateMessage', () {
    test('fromJson parses score update', () {
      final json = {
        'type': 'score_update',
        'matchId': 'm1',
        'data': {
          'totalRuns': 121,
          'totalWickets': 3,
          'overs': '15.3',
          'currentRunRate': 7.87,
          'requiredRunRate': null,
          'lastDelivery': {
            'runs': 1,
            'isWide': false,
            'isNoBall': false,
            'isBye': false,
            'isLegBye': false,
            'isWicket': false,
            'isBoundaryFour': false,
            'isBoundarySix': false,
            'description': 'Single to mid-on',
          },
          'striker': {
            'id': 'p1',
            'name': 'Kohli',
            'runs': 57,
            'balls': 39,
            'fours': 6,
            'sixes': 2,
            'strikeRate': 146.15,
          },
          'nonStriker': null,
          'bowler': {
            'id': 'b1',
            'name': 'Bumrah',
            'overs': '3.3',
            'maidens': 0,
            'runs': 25,
            'wickets': 1,
            'economy': 7.14,
          },
          'currentOver': [
            {'runs': 1, 'display': '1'},
            {'runs': 0, 'display': '.'},
            {'runs': 1, 'display': '1'},
          ],
        },
      };

      final msg = WsScoreUpdateMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.totalRuns, 121);
      expect(msg.data.lastDelivery.runs, 1);
      expect(msg.data.lastDelivery.description, 'Single to mid-on');
      expect(msg.data.currentOver, hasLength(3));
    });
  });

  group('WsWicketMessage', () {
    test('fromJson parses wicket data', () {
      final json = {
        'type': 'wicket',
        'matchId': 'm1',
        'data': {
          'dismissedPlayer': 'Rohit Sharma',
          'dismissalType': 'caught',
          'fielder': 'Smith',
          'bowler': 'Starc',
          'description': 'c Smith b Starc',
          'teamScore': '120/4',
          'overs': '15.3',
        },
      };

      final msg = WsWicketMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.dismissedPlayer, 'Rohit Sharma');
      expect(msg.data.dismissalType, 'caught');
      expect(msg.data.fielder, 'Smith');
      expect(msg.data.bowler, 'Starc');
      expect(msg.data.description, 'c Smith b Starc');
      expect(msg.data.teamScore, '120/4');
    });

    test('fromJson handles null fielder and bowler', () {
      final json = {
        'type': 'wicket',
        'matchId': 'm1',
        'data': {
          'dismissedPlayer': 'Player',
          'dismissalType': 'run_out',
          'fielder': null,
          'bowler': null,
          'description': 'run out',
          'teamScore': '50/2',
          'overs': '8.1',
        },
      };

      final msg = WsWicketMessage.fromJson(json);

      expect(msg.data.fielder, isNull);
      expect(msg.data.bowler, isNull);
    });
  });

  group('WsInningsCompleteMessage', () {
    test('fromJson parses innings complete', () {
      final json = {
        'type': 'innings_complete',
        'matchId': 'm1',
        'data': {
          'inningsNumber': 1,
          'battingTeam': 'India',
          'totalRuns': 185,
          'totalWickets': 7,
          'overs': '20.0',
          'target': 186,
        },
      };

      final msg = WsInningsCompleteMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.inningsNumber, 1);
      expect(msg.data.battingTeam, 'India');
      expect(msg.data.totalRuns, 185);
      expect(msg.data.totalWickets, 7);
      expect(msg.data.overs, '20.0');
      expect(msg.data.target, 186);
    });
  });

  group('WsMatchCompleteMessage', () {
    test('fromJson parses match complete with winner', () {
      final json = {
        'type': 'match_complete',
        'matchId': 'm1',
        'data': {
          'winner': 'India',
          'resultType': 'runs',
          'margin': 25,
          'summary': 'India won by 25 runs',
        },
      };

      final msg = WsMatchCompleteMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.winner, 'India');
      expect(msg.data.resultType, 'runs');
      expect(msg.data.margin, 25);
      expect(msg.data.summary, 'India won by 25 runs');
    });

    test('fromJson handles tied match (null winner/margin)', () {
      final json = {
        'type': 'match_complete',
        'matchId': 'm1',
        'data': {
          'winner': null,
          'resultType': 'tied',
          'margin': null,
          'summary': 'Match tied',
        },
      };

      final msg = WsMatchCompleteMessage.fromJson(json);

      expect(msg.data.winner, isNull);
      expect(msg.data.margin, isNull);
      expect(msg.data.resultType, 'tied');
    });
  });

  group('WsDeliveryUndoneMessage', () {
    test('fromJson parses delivery undone', () {
      final json = {
        'type': 'delivery_undone',
        'matchId': 'm1',
        'data': {
          'inningsId': 'inn1',
          'removedDeliveryId': 'del1',
          'updatedScore': {
            'runs': 119,
            'wickets': 3,
            'overs': '15.1',
          },
          'updatedBatterStats': {
            'strikerId': 'p1',
            'strikerRuns': 55,
            'strikerBalls': 37,
            'strikerFours': 6,
            'strikerSixes': 2,
          },
          'updatedBowlerStats': {
            'bowlerId': 'b1',
            'bowlerOvers': '3.1',
            'bowlerRuns': 23,
            'bowlerWickets': 1,
            'bowlerMaidens': 0,
          },
          'currentOver': [
            {'runs': 1, 'display': '1'},
          ],
        },
      };

      final msg = WsDeliveryUndoneMessage.fromJson(json);

      expect(msg.matchId, 'm1');
      expect(msg.data.inningsId, 'inn1');
      expect(msg.data.removedDeliveryId, 'del1');
      expect(msg.data.updatedScore.runs, 119);
      expect(msg.data.updatedScore.wickets, 3);
      expect(msg.data.updatedScore.overs, '15.1');
      expect(msg.data.updatedBatterStats, isNotNull);
      expect(msg.data.updatedBatterStats!.strikerId, 'p1');
      expect(msg.data.updatedBowlerStats, isNotNull);
      expect(msg.data.updatedBowlerStats!.bowlerId, 'b1');
      expect(msg.data.currentOver, hasLength(1));
    });

    test('fromJson handles null batter/bowler stats', () {
      final json = {
        'type': 'delivery_undone',
        'matchId': 'm1',
        'data': {
          'inningsId': 'inn1',
          'removedDeliveryId': 'del1',
          'updatedScore': {
            'runs': 0,
            'wickets': 0,
            'overs': '0.0',
          },
          'updatedBatterStats': null,
          'updatedBowlerStats': null,
          'currentOver': <Map<String, dynamic>>[],
        },
      };

      final msg = WsDeliveryUndoneMessage.fromJson(json);

      expect(msg.data.updatedBatterStats, isNull);
      expect(msg.data.updatedBowlerStats, isNull);
    });
  });

  group('WsErrorMessage', () {
    test('fromJson parses error', () {
      final json = {
        'type': 'error',
        'message': 'Match not found',
      };

      final msg = WsErrorMessage.fromJson(json);

      expect(msg.message, 'Match not found');
    });
  });

  group('parseServerMessage', () {
    test('dispatches match_state', () {
      final raw = jsonEncode({
        'type': 'match_state',
        'matchId': 'm1',
        'data': {
          'status': 'LIVE',
          'inningsNumber': 1,
          'totalRuns': 0,
          'totalWickets': 0,
          'overs': '0.0',
          'currentRunRate': null,
          'requiredRunRate': null,
          'target': null,
          'striker': null,
          'nonStriker': null,
          'bowler': null,
          'currentOver': <Map<String, dynamic>>[],
          'recentDeliveries': <Map<String, dynamic>>[],
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsMatchStateMessage>());
    });

    test('dispatches score_update', () {
      final raw = jsonEncode({
        'type': 'score_update',
        'matchId': 'm1',
        'data': {
          'totalRuns': 1,
          'totalWickets': 0,
          'overs': '0.1',
          'currentRunRate': 6.0,
          'requiredRunRate': null,
          'lastDelivery': {
            'runs': 1,
            'isWide': false,
            'isNoBall': false,
            'isBye': false,
            'isLegBye': false,
            'isWicket': false,
            'isBoundaryFour': false,
            'isBoundarySix': false,
            'description': '1 run',
          },
          'striker': null,
          'nonStriker': null,
          'bowler': null,
          'currentOver': <Map<String, dynamic>>[],
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsScoreUpdateMessage>());
    });

    test('dispatches wicket', () {
      final raw = jsonEncode({
        'type': 'wicket',
        'matchId': 'm1',
        'data': {
          'dismissedPlayer': 'Player',
          'dismissalType': 'bowled',
          'fielder': null,
          'bowler': 'Bowler',
          'description': 'b Bowler',
          'teamScore': '10/1',
          'overs': '2.1',
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsWicketMessage>());
    });

    test('dispatches innings_complete', () {
      final raw = jsonEncode({
        'type': 'innings_complete',
        'matchId': 'm1',
        'data': {
          'inningsNumber': 1,
          'battingTeam': 'Team A',
          'totalRuns': 150,
          'totalWickets': 10,
          'overs': '20.0',
          'target': 151,
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsInningsCompleteMessage>());
    });

    test('dispatches match_complete', () {
      final raw = jsonEncode({
        'type': 'match_complete',
        'matchId': 'm1',
        'data': {
          'winner': 'Team A',
          'resultType': 'runs',
          'margin': 20,
          'summary': 'Team A won by 20 runs',
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsMatchCompleteMessage>());
    });

    test('dispatches delivery_undone', () {
      final raw = jsonEncode({
        'type': 'delivery_undone',
        'matchId': 'm1',
        'data': {
          'inningsId': 'inn1',
          'removedDeliveryId': 'del1',
          'updatedScore': {'runs': 0, 'wickets': 0, 'overs': '0.0'},
          'updatedBatterStats': null,
          'updatedBowlerStats': null,
          'currentOver': <Map<String, dynamic>>[],
        },
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsDeliveryUndoneMessage>());
    });

    test('dispatches error', () {
      final raw = jsonEncode({
        'type': 'error',
        'message': 'Something went wrong',
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsErrorMessage>());
    });

    test('returns error for unknown type', () {
      final raw = jsonEncode({
        'type': 'unknown_type',
        'matchId': 'm1',
      });

      final msg = parseServerMessage(raw);
      expect(msg, isA<WsErrorMessage>());
      expect((msg as WsErrorMessage).message, contains('Unknown'));
    });

    test('returns error for malformed JSON', () {
      final msg = parseServerMessage('not valid json{');
      expect(msg, isA<WsErrorMessage>());
      expect((msg as WsErrorMessage).message, contains('Failed'));
    });
  });

  group('CricketUtils.parseOvers', () {
    test('parses complete overs', () {
      expect(parseOversString('4.0'), 24);
      expect(parseOversString('20.0'), 120);
      expect(parseOversString('0.0'), 0);
    });

    test('parses partial overs', () {
      expect(parseOversString('3.4'), 22);
      expect(parseOversString('0.3'), 3);
      expect(parseOversString('10.5'), 65);
    });
  });
}
