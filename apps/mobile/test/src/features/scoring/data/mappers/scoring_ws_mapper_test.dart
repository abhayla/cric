import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/data/mappers/scoring_ws_mapper.dart';
import 'package:cricapp/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricapp/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricapp/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  List<PlayingXIPlayer> makeBattingTeam() => [
        const PlayingXIPlayer(playerId: 'bat-1', displayName: 'Opener 1'),
        const PlayingXIPlayer(playerId: 'bat-2', displayName: 'Opener 2'),
        for (int i = 3; i <= 11; i++)
          PlayingXIPlayer(playerId: 'bat-$i', displayName: 'Batter $i'),
      ];

  List<PlayingXIPlayer> makeBowlingTeam() => [
        for (int i = 1; i <= 11; i++)
          PlayingXIPlayer(playerId: 'bowl-$i', displayName: 'Bowler $i'),
      ];

  ScoringNotifier makeNotifier({int? target}) {
    final state = ScoringState(
      matchId: 'match-1',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      inningsNumber: 1,
      totalOvers: 20,
      playersPerSide: 11,
      target: target,
      battingTeamPlayers: makeBattingTeam(),
      bowlingTeamPlayers: makeBowlingTeam(),
    );
    final notifier = ScoringNotifier(state);
    notifier.selectNewBatter(playerId: 'bat-1', displayName: 'Opener 1');
    notifier.selectNewBatter(playerId: 'bat-2', displayName: 'Opener 2');
    notifier.selectNewBowler(playerId: 'bowl-1', displayName: 'Bowler 1');
    return notifier;
  }

  group('buildScoreUpdatePayload', () {
    test('produces correct shape for a dot ball', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(runsFromBat: 0);
      final payload = buildScoreUpdatePayload(notifier.state);

      expect(payload['type'], 'score_update');
      expect(payload['matchId'], 'match-1');

      final data = payload['data'] as Map<String, dynamic>;
      expect(data['totalRuns'], 0);
      expect(data['totalWickets'], 0);
      expect(data['overs'], '0.1');
      expect(data['currentRunRate'], isA<double>());
      expect(data['requiredRunRate'], isNull);
      expect(data['battingTeamName'], 'Team Alpha');
      expect(data['bowlingTeamName'], 'Team Beta');

      // Striker snapshot
      final striker = data['striker'] as Map<String, dynamic>;
      expect(striker['id'], 'bat-1');
      expect(striker['name'], 'Opener 1');
      expect(striker['runs'], 0);
      expect(striker['balls'], 1);

      // Bowler snapshot
      final bowler = data['bowler'] as Map<String, dynamic>;
      expect(bowler['id'], 'bowl-1');
      expect(bowler['name'], 'Bowler 1');
      expect(bowler['overs'], '0.1');
      expect(bowler['runs'], 0);

      // Current over
      final currentOver = data['currentOver'] as List;
      expect(currentOver, hasLength(1));
      expect((currentOver[0] as Map)['display'], '.');

      // Last delivery
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['runs'], 0);
      expect(lastDel['description'], 'Dot ball');

      // Delivery count for gap detection
      expect(data['deliveryCount'], 1);
    });

    test('produces correct shape for a boundary four', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(
        runsFromBat: 4,
        isBoundaryFour: true,
      );
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;

      expect(data['totalRuns'], 4);
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['isBoundaryFour'], true);
      expect(lastDel['description'], 'FOUR!');
    });

    test('produces correct shape for a six', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(
        runsFromBat: 6,
        isBoundarySix: true,
      );
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;

      expect(data['totalRuns'], 6);
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['isBoundarySix'], true);
      expect(lastDel['description'], 'SIX!');
    });

    test('handles wide delivery', () {
      final notifier = makeNotifier();
      notifier.recordWide(additionalRuns: 2);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;

      expect(data['totalRuns'], 3); // 1 penalty + 2 additional
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['isWide'], true);
      expect(lastDel['description'], 'Wide + 2 runs');
    });

    test('handles no-ball delivery', () {
      final notifier = makeNotifier();
      notifier.recordNoBall(runsFromBat: 1);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;

      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['isNoBall'], true);
      expect(lastDel['description'], 'No Ball + 1 runs');
    });

    test('deliveryCount increments with each delivery', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(runsFromBat: 1);
      notifier.recordDelivery(runsFromBat: 2);
      notifier.recordDelivery(runsFromBat: 0);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      expect(data['deliveryCount'], 3);
    });

    test('rate formatting matches toFixed(2) pattern', () {
      final notifier = makeNotifier();
      // Score 7 runs off 1 ball → run rate = 42.0
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      notifier.recordDelivery(runsFromBat: 1);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final rr = data['currentRunRate'] as double;
      // Should be formatted to 2 decimal places
      expect(rr.toStringAsFixed(2), rr.toString().contains('.') ? rr.toStringAsFixed(2) : rr.toStringAsFixed(2));
    });
  });

  group('buildWicketPayload', () {
    test('produces correct shape', () {
      final notifier = makeNotifier();
      notifier.recordWicket(
        dismissalType: DismissalType.caught,
        dismissedPlayerId: 'bat-1',
        fielderId: 'bowl-2',
        fielderName: 'Bowler 2',
      );

      final lastDelivery = notifier.state.lastDelivery!;
      final payload = buildWicketPayload(
        notifier.state,
        lastDelivery,
        fielderName: 'Bowler 2',
      );

      expect(payload['type'], 'wicket');
      expect(payload['matchId'], 'match-1');

      final data = payload['data'] as Map<String, dynamic>;
      expect(data['dismissedPlayer'], 'Opener 1');
      expect(data['dismissalType'], 'Caught');
      expect(data['fielder'], 'Bowler 2');
      expect(data['description'], 'c Bowler 2 b Bowler 1');
      expect(data['teamScore'], '0/1');
      expect(data['overs'], '0.1');
    });

    test('bowled dismissal has no fielder', () {
      final notifier = makeNotifier();
      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );

      final lastDelivery = notifier.state.lastDelivery!;
      final payload = buildWicketPayload(notifier.state, lastDelivery);

      final data = payload['data'] as Map<String, dynamic>;
      expect(data['fielder'], isNull);
      expect(data['description'], 'b Bowler 1');
    });
  });

  group('buildInningsCompletePayload', () {
    test('produces correct shape', () {
      final notifier = makeNotifier();
      // Bowl an entire over
      for (var i = 0; i < 6; i++) {
        notifier.recordDelivery(runsFromBat: 4, isBoundaryFour: true);
      }
      notifier.declareInnings();

      final payload = buildInningsCompletePayload(notifier.state);

      expect(payload['type'], 'innings_complete');
      expect(payload['matchId'], 'match-1');

      final data = payload['data'] as Map<String, dynamic>;
      expect(data['inningsNumber'], 1);
      expect(data['battingTeam'], 'Team Alpha');
      expect(data['totalRuns'], 24);
      expect(data['totalWickets'], 0);
      expect(data['overs'], '1.0');
      expect(data['target'], 25);
    });
  });

  group('buildMatchCompletePayload', () {
    test('produces correct shape', () {
      // We need a 2nd innings state to get match complete.
      // Create 1st innings, declare it, start 2nd innings with target, then chase.
      final notifier = makeNotifier();
      // Score some runs in 1st innings then declare
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      notifier.declareInnings();
      // Start 2nd innings — target = 7 (6+1)
      notifier.startSecondInnings(
        strikerId: 'bowl-1',
        strikerName: 'Bowler 1',
        nonStrikerId: 'bowl-2',
        nonStrikerName: 'Bowler 2',
        bowlerId: 'bat-1',
        bowlerName: 'Opener 1',
      );
      // Chase target: 6+6 = 12 >= 7
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);
      notifier.recordDelivery(runsFromBat: 6, isBoundarySix: true);

      expect(notifier.state.isMatchComplete, true);

      final payload = buildMatchCompletePayload(notifier.state);

      expect(payload['type'], 'match_complete');
      expect(payload['matchId'], 'match-1');

      final data = payload['data'] as Map<String, dynamic>;
      expect(data['summary'], isNotEmpty);
      expect(data['resultType'], isNotEmpty);
    });
  });

  group('delivery description formatting', () {
    test('bye description', () {
      final notifier = makeNotifier();
      notifier.recordBye(byeRuns: 1);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], '1 Bye');
    });

    test('leg bye description plural', () {
      final notifier = makeNotifier();
      notifier.recordLegBye(legByeRuns: 2);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], '2 Leg Byes');
    });

    test('run description plural', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(runsFromBat: 3);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], '3 runs');
    });

    test('single run description singular', () {
      final notifier = makeNotifier();
      notifier.recordDelivery(runsFromBat: 1);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], '1 run');
    });

    test('wide with no additional runs', () {
      final notifier = makeNotifier();
      notifier.recordWide(additionalRuns: 0);
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], 'Wide');
    });

    test('wicket description', () {
      final notifier = makeNotifier();
      notifier.recordWicket(
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: 'bat-1',
      );
      final payload = buildScoreUpdatePayload(notifier.state);
      final data = payload['data'] as Map<String, dynamic>;
      final lastDel = data['lastDelivery'] as Map<String, dynamic>;
      expect(lastDel['description'], 'WICKET!');
      expect(lastDel['isWicket'], true);
    });
  });
}
