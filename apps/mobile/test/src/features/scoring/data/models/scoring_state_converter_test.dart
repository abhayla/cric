import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/data/models/scoring_state_converter.dart';
import 'package:cricscores/src/features/scoring/domain/entities/batter_innings.dart';
import 'package:cricscores/src/features/scoring/domain/entities/bowler_spell.dart';
import 'package:cricscores/src/features/scoring/domain/entities/delivery.dart';
import 'package:cricscores/src/features/scoring/domain/entities/innings_data.dart';
import 'package:cricscores/src/features/scoring/domain/entities/over.dart';
import 'package:cricscores/src/features/scoring/domain/entities/playing_xi_player.dart';
import 'package:cricscores/src/features/scoring/domain/entities/wicket_info.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/scoring_notifier.dart';

void main() {
  // ── Helper factories ──

  PlayingXIPlayer makePlayer({
    String playerId = 'p1',
    String displayName = 'Player One',
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
    bool isCaptain = false,
    bool isKeeper = false,
  }) {
    return PlayingXIPlayer(
      playerId: playerId,
      displayName: displayName,
      playerRole: playerRole,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      isCaptain: isCaptain,
      isKeeper: isKeeper,
    );
  }

  WicketInfo makeWicketInfo({
    String dismissedPlayerId = 'p1',
    DismissalType dismissalType = DismissalType.bowled,
    bool bowlerCredited = true,
    String? fielderId,
    bool? battersCrossed,
  }) {
    return WicketInfo(
      dismissedPlayerId: dismissedPlayerId,
      dismissalType: dismissalType,
      bowlerCredited: bowlerCredited,
      fielderId: fielderId,
      battersCrossed: battersCrossed,
    );
  }

  Delivery makeDelivery({
    String id = 'del-1',
    String inningsId = 'inn-1',
    int overNumber = 1,
    int ballNumber = 1,
    int sequenceNumber = 1,
    String strikerId = 'bat-1',
    String nonStrikerId = 'bat-2',
    String bowlerId = 'bowl-1',
    int runsFromBat = 0,
    bool isWide = false,
    int wideRuns = 0,
    bool isNoBall = false,
    int noBallRuns = 0,
    bool isBye = false,
    int byeRuns = 0,
    bool isLegBye = false,
    int legByeRuns = 0,
    bool isWicket = false,
    bool isBoundaryFour = false,
    bool isBoundarySix = false,
    bool isFreeHit = false,
    bool isPenalty = false,
    WicketInfo? wicketInfo,
  }) {
    return Delivery(
      id: id,
      inningsId: inningsId,
      overNumber: overNumber,
      ballNumber: ballNumber,
      sequenceNumber: sequenceNumber,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      runsFromBat: runsFromBat,
      isWide: isWide,
      wideRuns: wideRuns,
      isNoBall: isNoBall,
      noBallRuns: noBallRuns,
      isBye: isBye,
      byeRuns: byeRuns,
      isLegBye: isLegBye,
      legByeRuns: legByeRuns,
      isWicket: isWicket,
      isBoundaryFour: isBoundaryFour,
      isBoundarySix: isBoundarySix,
      isFreeHit: isFreeHit,
      isPenalty: isPenalty,
      wicketInfo: wicketInfo,
      timestamp: DateTime(2024, 6, 15, 14, 30),
    );
  }

  BatterInnings makeBatter({
    String playerId = 'bat-1',
    String displayName = 'Batter One',
    int runsScored = 45,
    int ballsFaced = 30,
    int fours = 5,
    int sixes = 2,
    bool isNotOut = true,
    bool isOnStrike = true,
    bool isRetiredHurt = false,
    DismissalType? dismissalType,
    String? dismissedByName,
    String? fielderName,
  }) {
    return BatterInnings(
      playerId: playerId,
      displayName: displayName,
      runsScored: runsScored,
      ballsFaced: ballsFaced,
      fours: fours,
      sixes: sixes,
      isNotOut: isNotOut,
      isOnStrike: isOnStrike,
      isRetiredHurt: isRetiredHurt,
      dismissalType: dismissalType,
      dismissedByName: dismissedByName,
      fielderName: fielderName,
    );
  }

  BowlerSpell makeBowler({
    String playerId = 'bowl-1',
    String displayName = 'Bowler One',
    int ballsBowled = 24,
    int maidens = 1,
    int runsConceded = 32,
    int wicketsTaken = 2,
    int wides = 1,
    int noBalls = 0,
    int dotBalls = 8,
  }) {
    return BowlerSpell(
      playerId: playerId,
      displayName: displayName,
      ballsBowled: ballsBowled,
      maidens: maidens,
      runsConceded: runsConceded,
      wicketsTaken: wicketsTaken,
      wides: wides,
      noBalls: noBalls,
      dotBalls: dotBalls,
    );
  }

  Over makeOver({
    int overNumber = 1,
    String bowlerId = 'bowl-1',
    String bowlerName = 'Bowler One',
    int runsConceded = 8,
    int wicketsTaken = 0,
    bool isMaiden = false,
    List<Delivery>? deliveries,
  }) {
    return Over(
      overNumber: overNumber,
      bowlerId: bowlerId,
      bowlerName: bowlerName,
      runsConceded: runsConceded,
      wicketsTaken: wicketsTaken,
      isMaiden: isMaiden,
      deliveries: deliveries ?? [makeDelivery()],
    );
  }

  ScoringState makeMinimalState() {
    return ScoringState(
      matchId: 'match-1',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      inningsNumber: 1,
      totalOvers: 20,
      playersPerSide: 11,
    );
  }

  ScoringState makeFullState() {
    final battingPlayers = [
      makePlayer(playerId: 'bat-1', displayName: 'Opener 1', isCaptain: true),
      makePlayer(playerId: 'bat-2', displayName: 'Opener 2', isKeeper: true),
    ];
    final bowlingPlayers = [
      makePlayer(
        playerId: 'bowl-1',
        displayName: 'Fast Bowler',
        bowlingStyle: 'Right Arm Fast',
      ),
      makePlayer(
        playerId: 'bowl-2',
        displayName: 'Spinner',
        bowlingStyle: 'Left Arm Orthodox',
      ),
    ];
    final del1 = makeDelivery(id: 'del-1', runsFromBat: 4, isBoundaryFour: true);
    final del2 = makeDelivery(
      id: 'del-2',
      ballNumber: 2,
      sequenceNumber: 2,
      runsFromBat: 1,
    );

    return ScoringState(
      matchId: 'match-42',
      inningsId: 'inn-1',
      battingTeamId: 'team-a',
      bowlingTeamId: 'team-b',
      inningsNumber: 1,
      totalOvers: 20,
      playersPerSide: 11,
      wideRunsPenalty: 1,
      noBallRunsPenalty: 1,
      battingTeamName: 'Team Alpha',
      bowlingTeamName: 'Team Beta',
      battingTeamPlayers: battingPlayers,
      bowlingTeamPlayers: bowlingPlayers,
      maxOversPerBowler: 4,
      strikerId: 'bat-1',
      nonStrikerId: 'bat-2',
      bowlerId: 'bowl-1',
      totalRuns: 5,
      totalWickets: 0,
      totalBalls: 2,
      totalExtras: 0,
      totalWides: 0,
      totalNoBalls: 0,
      totalByes: 0,
      totalLegByes: 0,
      isFreeHitPending: false,
      currentOverBalls: 2,
      currentOverDeliveries: [del1, del2],
      completedOvers: [],
      batterStats: {
        'bat-1': makeBatter(playerId: 'bat-1', runsScored: 5, ballsFaced: 2),
        'bat-2': makeBatter(
          playerId: 'bat-2',
          displayName: 'Opener 2',
          runsScored: 0,
          ballsFaced: 0,
          fours: 0,
          sixes: 0,
          isOnStrike: false,
        ),
      },
      bowlerStats: {
        'bowl-1': makeBowler(
          playerId: 'bowl-1',
          ballsBowled: 2,
          runsConceded: 5,
          wicketsTaken: 0,
          wides: 0,
          maidens: 0,
          dotBalls: 0,
        ),
      },
      deliveryHistory: [del1, del2],
    );
  }

  // ── Tests ──

  group('PlayingXIPlayer round-trip', () {
    test('basic player', () {
      final state = makeMinimalState();
      // Embed a player in battingTeamPlayers
      final withPlayers = ScoringState(
        matchId: state.matchId,
        inningsId: state.inningsId,
        battingTeamId: state.battingTeamId,
        bowlingTeamId: state.bowlingTeamId,
        inningsNumber: state.inningsNumber,
        totalOvers: state.totalOvers,
        playersPerSide: state.playersPerSide,
        battingTeamPlayers: [makePlayer()],
      );
      final json = scoringStateToJsonString(withPlayers);
      final restored = scoringStateFromJsonString(json);
      final p = restored.battingTeamPlayers.first;
      expect(p.playerId, 'p1');
      expect(p.displayName, 'Player One');
      expect(p.isCaptain, false);
      expect(p.isKeeper, false);
    });

    test('player with all optional fields', () {
      final player = makePlayer(
        playerRole: 'all_rounder',
        battingStyle: 'RHB',
        bowlingStyle: 'Right Arm Fast',
        isCaptain: true,
        isKeeper: true,
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        battingTeamPlayers: [player],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      final p = restored.battingTeamPlayers.first;
      expect(p.playerRole, 'all_rounder');
      expect(p.battingStyle, 'RHB');
      expect(p.bowlingStyle, 'Right Arm Fast');
      expect(p.isCaptain, true);
      expect(p.isKeeper, true);
    });
  });

  group('DismissalType round-trip', () {
    test('all dismissal types serialize via id', () {
      for (final dt in DismissalType.values) {
        final batter = makeBatter(
          isNotOut: false,
          dismissalType: dt,
          dismissedByName: 'Bowler',
        );
        final state = ScoringState(
          matchId: 'x',
          inningsId: 'x',
          battingTeamId: 'x',
          bowlingTeamId: 'x',
          inningsNumber: 1,
          totalOvers: 20,
          playersPerSide: 11,
          batterStats: {'bat-1': batter},
        );
        final json = scoringStateToJsonString(state);
        final restored = scoringStateFromJsonString(json);
        expect(
          restored.batterStats['bat-1']!.dismissalType,
          dt,
          reason: 'DismissalType.${dt.name} should round-trip',
        );
      }
    });
  });

  group('InningsCompletionReason round-trip', () {
    test('all completion reasons serialize via apiValue', () {
      for (final reason in InningsCompletionReason.values) {
        final state = ScoringState(
          matchId: 'x',
          inningsId: 'x',
          battingTeamId: 'x',
          bowlingTeamId: 'x',
          inningsNumber: 1,
          totalOvers: 20,
          playersPerSide: 11,
          isInningsComplete: true,
          completionReason: reason,
        );
        final json = scoringStateToJsonString(state);
        final restored = scoringStateFromJsonString(json);
        expect(
          restored.completionReason,
          reason,
          reason:
              'InningsCompletionReason.${reason.name} should round-trip',
        );
      }
    });

    test('null completion reason', () {
      final state = makeMinimalState();
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      expect(restored.completionReason, isNull);
    });
  });

  group('WicketInfo round-trip', () {
    test('basic wicket (bowled)', () {
      final delivery = makeDelivery(
        isWicket: true,
        wicketInfo: makeWicketInfo(),
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [delivery],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      final w = restored.deliveryHistory.first.wicketInfo!;
      expect(w.dismissedPlayerId, 'p1');
      expect(w.dismissalType, DismissalType.bowled);
      expect(w.bowlerCredited, true);
      expect(w.fielderId, isNull);
      expect(w.battersCrossed, isNull);
    });

    test('caught with fielder and batters crossed', () {
      final wicket = makeWicketInfo(
        dismissalType: DismissalType.caught,
        fielderId: 'fielder-1',
        battersCrossed: true,
      );
      final delivery = makeDelivery(isWicket: true, wicketInfo: wicket);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [delivery],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      final w = restored.deliveryHistory.first.wicketInfo!;
      expect(w.dismissalType, DismissalType.caught);
      expect(w.fielderId, 'fielder-1');
      expect(w.battersCrossed, true);
    });

    test('null wicket info', () {
      final delivery = makeDelivery();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [delivery],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      expect(restored.deliveryHistory.first.wicketInfo, isNull);
    });
  });

  group('Delivery round-trip', () {
    test('dot ball', () {
      final del = makeDelivery();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      final d = restored.deliveryHistory.first;
      expect(d.id, 'del-1');
      expect(d.runsFromBat, 0);
      expect(d.isLegal, true);
    });

    test('boundary four', () {
      final del = makeDelivery(runsFromBat: 4, isBoundaryFour: true);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.deliveryHistory.first.isBoundaryFour, true);
      expect(restored.deliveryHistory.first.runsFromBat, 4);
    });

    test('wide delivery', () {
      final del = makeDelivery(isWide: true, wideRuns: 2);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final d = restored.deliveryHistory.first;
      expect(d.isWide, true);
      expect(d.wideRuns, 2);
      expect(d.isLegal, false);
    });

    test('no-ball delivery', () {
      final del = makeDelivery(isNoBall: true, noBallRuns: 1, runsFromBat: 2);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final d = restored.deliveryHistory.first;
      expect(d.isNoBall, true);
      expect(d.noBallRuns, 1);
      expect(d.runsFromBat, 2);
    });

    test('bye delivery', () {
      final del = makeDelivery(isBye: true, byeRuns: 3);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.deliveryHistory.first.isBye, true);
      expect(restored.deliveryHistory.first.byeRuns, 3);
    });

    test('leg-bye delivery', () {
      final del = makeDelivery(isLegBye: true, legByeRuns: 2);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.deliveryHistory.first.isLegBye, true);
      expect(restored.deliveryHistory.first.legByeRuns, 2);
    });

    test('free hit delivery', () {
      final del = makeDelivery(isFreeHit: true, runsFromBat: 6, isBoundarySix: true);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final d = restored.deliveryHistory.first;
      expect(d.isFreeHit, true);
      expect(d.isBoundarySix, true);
    });

    test('delivery timestamp preserves', () {
      final del = makeDelivery();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [del],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(
        restored.deliveryHistory.first.timestamp,
        del.timestamp,
      );
    });
  });

  group('BatterInnings round-trip', () {
    test('active not-out batter', () {
      final batter = makeBatter();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        batterStats: {'bat-1': batter},
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final b = restored.batterStats['bat-1']!;
      expect(b.playerId, 'bat-1');
      expect(b.runsScored, 45);
      expect(b.ballsFaced, 30);
      expect(b.fours, 5);
      expect(b.sixes, 2);
      expect(b.isNotOut, true);
      expect(b.isOnStrike, true);
    });

    test('dismissed batter with fielder', () {
      final batter = makeBatter(
        isNotOut: false,
        dismissalType: DismissalType.caught,
        dismissedByName: 'Bumrah',
        fielderName: 'Kohli',
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        batterStats: {'bat-1': batter},
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final b = restored.batterStats['bat-1']!;
      expect(b.isNotOut, false);
      expect(b.dismissalType, DismissalType.caught);
      expect(b.dismissedByName, 'Bumrah');
      expect(b.fielderName, 'Kohli');
    });

    test('retired hurt batter', () {
      final batter = makeBatter(isRetiredHurt: true);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        batterStats: {'bat-1': batter},
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.batterStats['bat-1']!.isRetiredHurt, true);
    });
  });

  group('BowlerSpell round-trip', () {
    test('full bowler stats', () {
      final bowler = makeBowler();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        bowlerStats: {'bowl-1': bowler},
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final b = restored.bowlerStats['bowl-1']!;
      expect(b.playerId, 'bowl-1');
      expect(b.ballsBowled, 24);
      expect(b.maidens, 1);
      expect(b.runsConceded, 32);
      expect(b.wicketsTaken, 2);
      expect(b.wides, 1);
      expect(b.noBalls, 0);
      expect(b.dotBalls, 8);
    });

    test('fresh bowler with zero stats', () {
      final bowler = makeBowler(
        ballsBowled: 0,
        maidens: 0,
        runsConceded: 0,
        wicketsTaken: 0,
        wides: 0,
        noBalls: 0,
        dotBalls: 0,
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        bowlerStats: {'bowl-1': bowler},
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final b = restored.bowlerStats['bowl-1']!;
      expect(b.ballsBowled, 0);
      expect(b.displayName, 'Bowler One');
    });
  });

  group('Over round-trip', () {
    test('normal over with deliveries', () {
      final over = makeOver();
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        completedOvers: [over],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final o = restored.completedOvers.first;
      expect(o.overNumber, 1);
      expect(o.bowlerId, 'bowl-1');
      expect(o.bowlerName, 'Bowler One');
      expect(o.runsConceded, 8);
      expect(o.isMaiden, false);
      expect(o.deliveries.length, 1);
    });

    test('maiden over', () {
      final over = makeOver(isMaiden: true, runsConceded: 0);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        completedOvers: [over],
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.completedOvers.first.isMaiden, true);
    });
  });

  group('FirstInningsSummary round-trip', () {
    test('populated summary', () {
      const summary = FirstInningsSummary(
        teamName: 'Team Alpha',
        teamId: 'team-a',
        totalRuns: 187,
        totalWickets: 6,
        totalBalls: 120,
        oversDisplay: '20.0',
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        firstInningsSummary: summary,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final s = restored.firstInningsSummary!;
      expect(s.teamName, 'Team Alpha');
      expect(s.teamId, 'team-a');
      expect(s.totalRuns, 187);
      expect(s.totalWickets, 6);
      expect(s.totalBalls, 120);
      expect(s.oversDisplay, '20.0');
    });

    test('null summary', () {
      final state = makeMinimalState();
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.firstInningsSummary, isNull);
    });
  });

  group('InningsData round-trip', () {
    test('full innings data', () {
      final inningsData = InningsData(
        teamName: 'Team A',
        teamId: 'team-a',
        totalRuns: 150,
        totalWickets: 7,
        totalBalls: 120,
        totalWides: 5,
        totalNoBalls: 3,
        totalByes: 2,
        totalLegByes: 1,
        totalExtras: 11,
        batterStats: {'bat-1': makeBatter()},
        bowlerStats: {'bowl-1': makeBowler()},
        fallOfWickets: [
          const FallOfWicket(
            wicketNumber: 1,
            scoreAtFall: 25,
            oversAtFall: '4.3',
            dismissedPlayerName: 'Opener 1',
          ),
        ],
        deliveryHistory: [makeDelivery()],
        battingTeamPlayers: [makePlayer(playerId: 'bat-1')],
        bowlingTeamPlayers: [makePlayer(playerId: 'bowl-1')],
      );
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        firstInnings: inningsData,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      final d = restored.firstInnings!;
      expect(d.teamName, 'Team A');
      expect(d.totalRuns, 150);
      expect(d.totalWickets, 7);
      expect(d.totalExtras, 11);
      expect(d.batterStats.length, 1);
      expect(d.bowlerStats.length, 1);
      expect(d.fallOfWickets.length, 1);
      expect(d.fallOfWickets.first.wicketNumber, 1);
      expect(d.fallOfWickets.first.scoreAtFall, 25);
      expect(d.deliveryHistory.length, 1);
      expect(d.battingTeamPlayers.length, 1);
      expect(d.bowlingTeamPlayers.length, 1);
    });
  });

  group('ScoringState round-trip', () {
    test('minimal state', () {
      final state = makeMinimalState();
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      expect(restored.matchId, 'match-1');
      expect(restored.inningsId, 'inn-1');
      expect(restored.battingTeamId, 'team-a');
      expect(restored.bowlingTeamId, 'team-b');
      expect(restored.inningsNumber, 1);
      expect(restored.totalOvers, 20);
      expect(restored.playersPerSide, 11);
      expect(restored.totalRuns, 0);
      expect(restored.strikerId, isNull);
      expect(restored.bowlerId, isNull);
      expect(restored.deliveryHistory, isEmpty);
      expect(restored.firstInningsSummary, isNull);
      expect(restored.firstInnings, isNull);
    });

    test('full 1st innings state', () {
      final state = makeFullState();
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      expect(restored.matchId, 'match-42');
      expect(restored.battingTeamName, 'Team Alpha');
      expect(restored.bowlingTeamName, 'Team Beta');
      expect(restored.maxOversPerBowler, 4);
      expect(restored.strikerId, 'bat-1');
      expect(restored.nonStrikerId, 'bat-2');
      expect(restored.bowlerId, 'bowl-1');
      expect(restored.totalRuns, 5);
      expect(restored.totalBalls, 2);
      expect(restored.currentOverBalls, 2);
      expect(restored.currentOverDeliveries.length, 2);
      expect(restored.battingTeamPlayers.length, 2);
      expect(restored.bowlingTeamPlayers.length, 2);
      expect(restored.batterStats.length, 2);
      expect(restored.bowlerStats.length, 1);
      expect(restored.deliveryHistory.length, 2);
    });

    test('2nd innings with first innings summary and data', () {
      const summary = FirstInningsSummary(
        teamName: 'Team A',
        teamId: 'team-a',
        totalRuns: 180,
        totalWickets: 5,
        totalBalls: 120,
        oversDisplay: '20.0',
      );
      const firstInningsData = InningsData(
        teamName: 'Team A',
        teamId: 'team-a',
        totalRuns: 180,
        totalWickets: 5,
        totalBalls: 120,
        totalWides: 3,
        totalNoBalls: 2,
        totalByes: 1,
        totalLegByes: 0,
        totalExtras: 6,
        batterStats: {},
        bowlerStats: {},
        fallOfWickets: [],
        deliveryHistory: [],
        battingTeamPlayers: [],
        bowlingTeamPlayers: [],
      );
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-2',
        battingTeamId: 'team-b',
        bowlingTeamId: 'team-a',
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        target: 181,
        firstInningsSummary: summary,
        firstInnings: firstInningsData,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.inningsNumber, 2);
      expect(restored.target, 181);
      expect(restored.firstInningsSummary, isNotNull);
      expect(restored.firstInningsSummary!.totalRuns, 180);
      expect(restored.firstInnings, isNotNull);
      expect(restored.firstInnings!.totalExtras, 6);
    });

    test('completed innings state', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        isInningsComplete: true,
        completionReason: InningsCompletionReason.oversExhausted,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.isInningsComplete, true);
      expect(restored.completionReason, InningsCompletionReason.oversExhausted);
    });

    test('match complete state', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-2',
        battingTeamId: 'team-b',
        bowlingTeamId: 'team-a',
        inningsNumber: 2,
        totalOvers: 20,
        playersPerSide: 11,
        isInningsComplete: true,
        isMatchComplete: true,
        completionReason: InningsCompletionReason.targetChased,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.isMatchComplete, true);
      expect(restored.completionReason, InningsCompletionReason.targetChased);
    });

    test('state with free hit pending', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        isFreeHitPending: true,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.isFreeHitPending, true);
    });

    test('state with undo blocked by transition', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        undoBlockedByTransition: true,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.undoBlockedByTransition, true);
    });

    test('state with error', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        error: 'Something went wrong',
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.error, 'Something went wrong');
    });

    test('state with lastBowlerId', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        lastBowlerId: 'bowl-prev',
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.lastBowlerId, 'bowl-prev');
    });

    test('state with custom penalty values', () {
      final state = ScoringState(
        matchId: 'match-1',
        inningsId: 'inn-1',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        wideRunsPenalty: 2,
        noBallRunsPenalty: 2,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.wideRunsPenalty, 2);
      expect(restored.noBallRunsPenalty, 2);
    });

    test('JSON is valid JSON string', () {
      final state = makeFullState();
      final json = scoringStateToJsonString(state);
      // Should not throw
      final parsed = jsonDecode(json);
      expect(parsed, isA<Map<String, dynamic>>());
    });

    test('empty maps and lists serialize correctly', () {
      final state = makeMinimalState();
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.batterStats, isEmpty);
      expect(restored.bowlerStats, isEmpty);
      expect(restored.battingTeamPlayers, isEmpty);
      expect(restored.bowlingTeamPlayers, isEmpty);
      expect(restored.currentOverDeliveries, isEmpty);
      expect(restored.completedOvers, isEmpty);
      expect(restored.deliveryHistory, isEmpty);
    });

    test('multiple completed overs round-trip', () {
      final overs = [
        makeOver(overNumber: 1),
        makeOver(overNumber: 2, bowlerId: 'bowl-2', bowlerName: 'Bowler Two'),
      ];
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        completedOvers: overs,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.completedOvers.length, 2);
      expect(restored.completedOvers[0].overNumber, 1);
      expect(restored.completedOvers[1].overNumber, 2);
      expect(restored.completedOvers[1].bowlerId, 'bowl-2');
    });

    test('multiple batters in stats map', () {
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        batterStats: {
          'bat-1': makeBatter(playerId: 'bat-1', runsScored: 50),
          'bat-2': makeBatter(playerId: 'bat-2', displayName: 'Batter Two', runsScored: 30),
          'bat-3': makeBatter(playerId: 'bat-3', displayName: 'Batter Three', runsScored: 0),
        },
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.batterStats.length, 3);
      expect(restored.batterStats['bat-1']!.runsScored, 50);
      expect(restored.batterStats['bat-2']!.runsScored, 30);
      expect(restored.batterStats['bat-3']!.runsScored, 0);
    });

    test('all extras totals round-trip', () {
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        totalExtras: 15,
        totalWides: 5,
        totalNoBalls: 4,
        totalByes: 3,
        totalLegByes: 3,
      );
      final restored = scoringStateFromJsonString(scoringStateToJsonString(state));
      expect(restored.totalExtras, 15);
      expect(restored.totalWides, 5);
      expect(restored.totalNoBalls, 4);
      expect(restored.totalByes, 3);
      expect(restored.totalLegByes, 3);
    });
  });

  group('isDirectHit round-trip', () {
    test('preserves isDirectHit=true in WicketInfo', () {
      const wicket = WicketInfo(
        dismissedPlayerId: 'p1',
        dismissalType: DismissalType.runOut,
        bowlerCredited: false,
        fielderId: 'fielder-1',
        battersCrossed: false,
        isDirectHit: true,
      );
      final delivery = makeDelivery(isWicket: true, wicketInfo: wicket);
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [delivery],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      final w = restored.deliveryHistory.first.wicketInfo!;
      expect(w.isDirectHit, true);
    });

    test('backward compatibility: missing isDirectHit defaults to false', () {
      // Build JSON manually without isDirectHit field in wicketInfo
      final state = ScoringState(
        matchId: 'x',
        inningsId: 'x',
        battingTeamId: 'x',
        bowlingTeamId: 'x',
        inningsNumber: 1,
        totalOvers: 20,
        playersPerSide: 11,
        deliveryHistory: [
          makeDelivery(
            isWicket: true,
            wicketInfo: makeWicketInfo(),
          ),
        ],
      );
      final jsonStr = scoringStateToJsonString(state);
      // Remove isDirectHit from the JSON to simulate old data
      final modified = jsonStr.replaceAll('"isDirectHit":false,', '');
      final restored = scoringStateFromJsonString(modified);
      final w = restored.deliveryHistory.first.wicketInfo!;
      expect(w.isDirectHit, false);
    });
  });

  group('Super over fields round-trip', () {
    test('preserves all super over fields', () {
      final state = ScoringState(
        matchId: 'match-so',
        inningsId: 'inn-so',
        battingTeamId: 'team-a',
        bowlingTeamId: 'team-b',
        inningsNumber: 1,
        totalOvers: 1,
        playersPerSide: 3,
        isKnockoutMatch: true,
        isSuperOver: true,
        superOverNumber: 2,
        needsSuperOver: true,
        previousSuperOverBowlerIds: ['bowl-1', 'bowl-2'],
      );
      final json = scoringStateToJsonString(state);
      final restored = scoringStateFromJsonString(json);
      expect(restored.isKnockoutMatch, true);
      expect(restored.isSuperOver, true);
      expect(restored.superOverNumber, 2);
      expect(restored.needsSuperOver, true);
      expect(restored.previousSuperOverBowlerIds, ['bowl-1', 'bowl-2']);
    });

    test('backward compatibility: missing super over fields default correctly',
        () {
      // Use minimal state which has defaults, serialize, strip the SO fields
      final state = makeMinimalState();
      final jsonStr = scoringStateToJsonString(state);
      // Remove super over keys to simulate old data
      final modified = jsonStr
          .replaceAll('"isKnockoutMatch":false,', '')
          .replaceAll('"isSuperOver":false,', '')
          .replaceAll('"superOverNumber":0,', '')
          .replaceAll('"needsSuperOver":false,', '')
          .replaceAll('"previousSuperOverBowlerIds":[],', '');
      final restored = scoringStateFromJsonString(modified);
      expect(restored.isKnockoutMatch, false);
      expect(restored.isSuperOver, false);
      expect(restored.superOverNumber, 0);
      expect(restored.needsSuperOver, false);
      expect(restored.previousSuperOverBowlerIds, isEmpty);
    });
  });
}
