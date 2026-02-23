import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/scoring/domain/entities/match.dart';

void main() {
  group('MatchStatus', () {
    test('has exactly 6 values', () {
      expect(MatchStatus.values.length, 6);
    });

    test('contains expected values', () {
      expect(MatchStatus.values, contains(MatchStatus.setup));
      expect(MatchStatus.values, contains(MatchStatus.toss));
      expect(MatchStatus.values, contains(MatchStatus.live));
      expect(MatchStatus.values, contains(MatchStatus.inningsBreak));
      expect(MatchStatus.values, contains(MatchStatus.completed));
      expect(MatchStatus.values, contains(MatchStatus.abandoned));
    });

    test('labels are correct', () {
      expect(MatchStatus.setup.label, 'Setup');
      expect(MatchStatus.toss.label, 'Toss');
      expect(MatchStatus.live.label, 'Live');
      expect(MatchStatus.inningsBreak.label, 'Innings Break');
      expect(MatchStatus.completed.label, 'Completed');
      expect(MatchStatus.abandoned.label, 'Abandoned');
    });

    test('apiValue maps to snake_case', () {
      expect(MatchStatus.setup.apiValue, 'setup');
      expect(MatchStatus.toss.apiValue, 'toss');
      expect(MatchStatus.live.apiValue, 'live');
      expect(MatchStatus.inningsBreak.apiValue, 'innings_break');
      expect(MatchStatus.completed.apiValue, 'completed');
      expect(MatchStatus.abandoned.apiValue, 'abandoned');
    });

    test('fromApiValue parses correctly', () {
      expect(MatchStatus.fromApiValue('setup'), MatchStatus.setup);
      expect(MatchStatus.fromApiValue('toss'), MatchStatus.toss);
      expect(MatchStatus.fromApiValue('live'), MatchStatus.live);
      expect(MatchStatus.fromApiValue('innings_break'), MatchStatus.inningsBreak);
      expect(MatchStatus.fromApiValue('completed'), MatchStatus.completed);
      expect(MatchStatus.fromApiValue('abandoned'), MatchStatus.abandoned);
    });

    test('fromApiValue throws for unknown value', () {
      expect(() => MatchStatus.fromApiValue('unknown'), throwsArgumentError);
    });

    test('isActive returns true for live and innings break', () {
      expect(MatchStatus.setup.isActive, false);
      expect(MatchStatus.toss.isActive, false);
      expect(MatchStatus.live.isActive, true);
      expect(MatchStatus.inningsBreak.isActive, true);
      expect(MatchStatus.completed.isActive, false);
      expect(MatchStatus.abandoned.isActive, false);
    });

    test('isFinished returns true for completed and abandoned', () {
      expect(MatchStatus.setup.isFinished, false);
      expect(MatchStatus.toss.isFinished, false);
      expect(MatchStatus.live.isFinished, false);
      expect(MatchStatus.inningsBreak.isFinished, false);
      expect(MatchStatus.completed.isFinished, true);
      expect(MatchStatus.abandoned.isFinished, true);
    });
  });

  group('TossDecision', () {
    test('has exactly 2 values', () {
      expect(TossDecision.values.length, 2);
    });

    test('labels are correct', () {
      expect(TossDecision.bat.label, 'Bat');
      expect(TossDecision.field.label, 'Field');
    });

    test('apiValue maps correctly', () {
      expect(TossDecision.bat.apiValue, 'bat');
      expect(TossDecision.field.apiValue, 'bowl');
    });

    test('fromApiValue parses correctly', () {
      expect(TossDecision.fromApiValue('bat'), TossDecision.bat);
      expect(TossDecision.fromApiValue('bowl'), TossDecision.field);
    });

    test('fromApiValue throws for unknown value', () {
      expect(() => TossDecision.fromApiValue('unknown'), throwsArgumentError);
    });
  });

  group('MatchFormat', () {
    test('has expected values', () {
      expect(MatchFormat.values.length, 4);
      expect(MatchFormat.values, contains(MatchFormat.t20));
      expect(MatchFormat.values, contains(MatchFormat.odi));
      expect(MatchFormat.values, contains(MatchFormat.test));
      expect(MatchFormat.values, contains(MatchFormat.custom));
    });

    test('labels are correct', () {
      expect(MatchFormat.t20.label, 'T20');
      expect(MatchFormat.odi.label, 'ODI');
      expect(MatchFormat.test.label, 'Test');
      expect(MatchFormat.custom.label, 'Custom');
    });

    test('apiValue maps correctly', () {
      expect(MatchFormat.t20.apiValue, 'T20');
      expect(MatchFormat.odi.apiValue, 'ODI');
      expect(MatchFormat.test.apiValue, 'test');
      expect(MatchFormat.custom.apiValue, 'custom');
    });

    test('defaultOvers returns correct values', () {
      expect(MatchFormat.t20.defaultOvers, 20);
      expect(MatchFormat.odi.defaultOvers, 50);
      expect(MatchFormat.test.defaultOvers, isNull);
      expect(MatchFormat.custom.defaultOvers, isNull);
    });

    test('fromApiValue parses correctly', () {
      expect(MatchFormat.fromApiValue('T20'), MatchFormat.t20);
      expect(MatchFormat.fromApiValue('ODI'), MatchFormat.odi);
      expect(MatchFormat.fromApiValue('test'), MatchFormat.test);
      expect(MatchFormat.fromApiValue('custom'), MatchFormat.custom);
    });

    test('fromApiValue returns custom for unknown format', () {
      expect(MatchFormat.fromApiValue('unknown'), MatchFormat.custom);
      expect(MatchFormat.fromApiValue('TWENTY20'), MatchFormat.custom);
    });
  });

  group('Match', () {
    final now = DateTime(2026, 1, 15);

    Match createMatch({
      String id = 'match-1',
      String homeTeamId = 'team-home',
      String awayTeamId = 'team-away',
      MatchFormat format = MatchFormat.t20,
      int totalOvers = 20,
      int ballTypeId = 1,
      MatchStatus status = MatchStatus.setup,
      int playersPerSide = 11,
      int wideRuns = 1,
      int noBallRuns = 1,
      String scorerId = 'scorer-1',
      String createdBy = 'user-1',
      String matchDate = '2026-01-15',
      String? homeTeamName,
      String? awayTeamName,
      String? venue,
      String? tossWinnerId,
      TossDecision? tossDecision,
      int? maxOversPerBowler,
      int? powerplayOvers,
      String? tournamentId,
    }) {
      return Match(
        id: id,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        format: format,
        totalOvers: totalOvers,
        ballTypeId: ballTypeId,
        status: status,
        playersPerSide: playersPerSide,
        wideRuns: wideRuns,
        noBallRuns: noBallRuns,
        scorerId: scorerId,
        createdBy: createdBy,
        matchDate: matchDate,
        createdAt: now,
        updatedAt: now,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        venue: venue,
        tossWinnerId: tossWinnerId,
        tossDecision: tossDecision,
        maxOversPerBowler: maxOversPerBowler,
        powerplayOvers: powerplayOvers,
        tournamentId: tournamentId,
      );
    }

    test('creates with required fields', () {
      final match = createMatch();
      expect(match.id, 'match-1');
      expect(match.homeTeamId, 'team-home');
      expect(match.awayTeamId, 'team-away');
      expect(match.format, MatchFormat.t20);
      expect(match.totalOvers, 20);
      expect(match.ballTypeId, 1);
      expect(match.status, MatchStatus.setup);
      expect(match.playersPerSide, 11);
      expect(match.wideRuns, 1);
      expect(match.noBallRuns, 1);
      expect(match.scorerId, 'scorer-1');
      expect(match.createdBy, 'user-1');
      expect(match.matchDate, '2026-01-15');
    });

    test('creates with all optional fields', () {
      final match = createMatch(
        homeTeamName: 'Mumbai Warriors',
        awayTeamName: 'Delhi Capitals',
        venue: 'Wankhede Stadium',
        tossWinnerId: 'team-home',
        tossDecision: TossDecision.bat,
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        tournamentId: 'tournament-1',
      );

      expect(match.homeTeamName, 'Mumbai Warriors');
      expect(match.awayTeamName, 'Delhi Capitals');
      expect(match.venue, 'Wankhede Stadium');
      expect(match.tossWinnerId, 'team-home');
      expect(match.tossDecision, TossDecision.bat);
      expect(match.maxOversPerBowler, 4);
      expect(match.powerplayOvers, 6);
      expect(match.tournamentId, 'tournament-1');
    });

    test('optional fields default to null', () {
      final match = createMatch();
      expect(match.homeTeamName, isNull);
      expect(match.awayTeamName, isNull);
      expect(match.venue, isNull);
      expect(match.tossWinnerId, isNull);
      expect(match.tossDecision, isNull);
      expect(match.maxOversPerBowler, isNull);
      expect(match.powerplayOvers, isNull);
      expect(match.tournamentId, isNull);
    });

    test('title returns "Home vs Away" when team names available', () {
      final match = createMatch(
        homeTeamName: 'Mumbai Warriors',
        awayTeamName: 'Delhi Capitals',
      );
      expect(match.title, 'Mumbai Warriors vs Delhi Capitals');
    });

    test('title returns fallback when team names not available', () {
      final match = createMatch();
      expect(match.title, 'Match');
    });

    test('effectiveMaxOversPerBowler uses provided value', () {
      final match = createMatch(maxOversPerBowler: 4);
      expect(match.effectiveMaxOversPerBowler, 4);
    });

    test('effectiveMaxOversPerBowler falls back to ceil(overs/5)', () {
      final match20 = createMatch(totalOvers: 20);
      expect(match20.effectiveMaxOversPerBowler, 4);

      final match50 = createMatch(totalOvers: 50);
      expect(match50.effectiveMaxOversPerBowler, 10);

      final match6 = createMatch(totalOvers: 6);
      expect(match6.effectiveMaxOversPerBowler, 2);

      final match5 = createMatch(totalOvers: 5);
      expect(match5.effectiveMaxOversPerBowler, 1);
    });

    test('isTournamentMatch returns correct value', () {
      expect(createMatch().isTournamentMatch, false);
      expect(createMatch(tournamentId: 'tour-1').isTournamentMatch, true);
    });

    test('isLive returns true only when status is live', () {
      expect(createMatch(status: MatchStatus.live).isLive, true);
      expect(createMatch(status: MatchStatus.setup).isLive, false);
      expect(createMatch(status: MatchStatus.completed).isLive, false);
    });

    test('isCompleted returns true only when status is completed', () {
      expect(createMatch(status: MatchStatus.completed).isCompleted, true);
      expect(createMatch(status: MatchStatus.live).isCompleted, false);
    });

    test('formatLabel returns human-readable format', () {
      expect(
        createMatch(format: MatchFormat.t20, totalOvers: 20).formatLabel,
        'T20',
      );
      expect(
        createMatch(format: MatchFormat.odi, totalOvers: 50).formatLabel,
        'ODI',
      );
      expect(
        createMatch(format: MatchFormat.custom, totalOvers: 15).formatLabel,
        '15 Overs',
      );
    });
  });

  group('Match validation', () {
    test('validateOvers accepts 1-50', () {
      expect(Match.validateOvers(1), isNull);
      expect(Match.validateOvers(20), isNull);
      expect(Match.validateOvers(50), isNull);
    });

    test('validateOvers rejects out of range', () {
      expect(Match.validateOvers(0), isNotNull);
      expect(Match.validateOvers(51), isNotNull);
      expect(Match.validateOvers(-1), isNotNull);
    });

    test('validatePlayersPerSide accepts 2-11', () {
      expect(Match.validatePlayersPerSide(2), isNull);
      expect(Match.validatePlayersPerSide(11), isNull);
      expect(Match.validatePlayersPerSide(6), isNull);
    });

    test('validatePlayersPerSide rejects out of range', () {
      expect(Match.validatePlayersPerSide(1), isNotNull);
      expect(Match.validatePlayersPerSide(12), isNotNull);
      expect(Match.validatePlayersPerSide(0), isNotNull);
    });

    test('validateTeams rejects same team', () {
      expect(Match.validateTeams('team-1', 'team-1'), isNotNull);
    });

    test('validateTeams accepts different teams', () {
      expect(Match.validateTeams('team-1', 'team-2'), isNull);
    });
  });

  group('PlayingXIEntry', () {
    test('creates with required fields', () {
      const entry = PlayingXIEntry(
        playerId: 'player-1',
        displayName: 'Virat Kohli',
        isCaptain: true,
        isKeeper: false,
      );

      expect(entry.playerId, 'player-1');
      expect(entry.displayName, 'Virat Kohli');
      expect(entry.isCaptain, true);
      expect(entry.isKeeper, false);
    });

    test('creates with all optional fields', () {
      const entry = PlayingXIEntry(
        playerId: 'player-1',
        displayName: 'Virat Kohli',
        isCaptain: true,
        isKeeper: false,
        playerRole: 'batter',
        battingStyle: 'right_hand',
        bowlingStyle: 'right_arm_medium',
        battingOrder: 1,
      );

      expect(entry.playerRole, 'batter');
      expect(entry.battingStyle, 'right_hand');
      expect(entry.bowlingStyle, 'right_arm_medium');
      expect(entry.battingOrder, 1);
    });

    test('badge returns (C) for captain', () {
      const entry = PlayingXIEntry(
        playerId: 'p1',
        displayName: 'Test',
        isCaptain: true,
        isKeeper: false,
      );
      expect(entry.badge, '(C)');
    });

    test('badge returns (WK) for keeper', () {
      const entry = PlayingXIEntry(
        playerId: 'p1',
        displayName: 'Test',
        isCaptain: false,
        isKeeper: true,
      );
      expect(entry.badge, '(WK)');
    });

    test('badge returns (C & WK) for captain+keeper', () {
      const entry = PlayingXIEntry(
        playerId: 'p1',
        displayName: 'Test',
        isCaptain: true,
        isKeeper: true,
      );
      expect(entry.badge, '(C & WK)');
    });

    test('badge returns null for regular player', () {
      const entry = PlayingXIEntry(
        playerId: 'p1',
        displayName: 'Test',
        isCaptain: false,
        isKeeper: false,
      );
      expect(entry.badge, isNull);
    });
  });
}
