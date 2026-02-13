import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/domain/entities/tournament.dart';

void main() {
  group('TournamentFormat', () {
    test('has exactly 3 values', () {
      expect(TournamentFormat.values.length, 3);
    });

    test('contains expected values', () {
      expect(TournamentFormat.values, contains(TournamentFormat.roundRobin));
      expect(TournamentFormat.values, contains(TournamentFormat.knockout));
      expect(TournamentFormat.values, contains(TournamentFormat.groupKnockout));
    });

    test('labels are correct', () {
      expect(TournamentFormat.roundRobin.label, 'Round Robin');
      expect(TournamentFormat.knockout.label, 'Knockout');
      expect(TournamentFormat.groupKnockout.label, 'Group + KO');
    });

    test('apiValue maps correctly', () {
      expect(TournamentFormat.roundRobin.apiValue, 'round_robin');
      expect(TournamentFormat.knockout.apiValue, 'knockout');
      expect(TournamentFormat.groupKnockout.apiValue, 'group_knockout');
    });

    test('fromApiValue parses correctly', () {
      expect(
        TournamentFormat.fromApiValue('round_robin'),
        TournamentFormat.roundRobin,
      );
      expect(
        TournamentFormat.fromApiValue('knockout'),
        TournamentFormat.knockout,
      );
      expect(
        TournamentFormat.fromApiValue('group_knockout'),
        TournamentFormat.groupKnockout,
      );
    });

    test('fromApiValue throws for unknown value', () {
      expect(
        () => TournamentFormat.fromApiValue('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('TournamentStatus', () {
    test('has exactly 4 values', () {
      expect(TournamentStatus.values.length, 4);
    });

    test('contains expected values', () {
      expect(TournamentStatus.values, contains(TournamentStatus.draft));
      expect(TournamentStatus.values, contains(TournamentStatus.registration));
      expect(TournamentStatus.values, contains(TournamentStatus.live));
      expect(TournamentStatus.values, contains(TournamentStatus.completed));
    });

    test('labels are correct', () {
      expect(TournamentStatus.draft.label, 'Draft');
      expect(TournamentStatus.registration.label, 'Registration');
      expect(TournamentStatus.live.label, 'Live');
      expect(TournamentStatus.completed.label, 'Completed');
    });

    test('apiValue maps correctly', () {
      expect(TournamentStatus.draft.apiValue, 'draft');
      expect(TournamentStatus.registration.apiValue, 'registration');
      expect(TournamentStatus.live.apiValue, 'live');
      expect(TournamentStatus.completed.apiValue, 'completed');
    });

    test('fromApiValue parses correctly', () {
      expect(TournamentStatus.fromApiValue('draft'), TournamentStatus.draft);
      expect(
        TournamentStatus.fromApiValue('registration'),
        TournamentStatus.registration,
      );
      expect(TournamentStatus.fromApiValue('live'), TournamentStatus.live);
      expect(
        TournamentStatus.fromApiValue('completed'),
        TournamentStatus.completed,
      );
    });

    test('fromApiValue throws for unknown value', () {
      expect(
        () => TournamentStatus.fromApiValue('unknown'),
        throwsArgumentError,
      );
    });

    test('isEditable returns true for draft and registration', () {
      expect(TournamentStatus.draft.isEditable, true);
      expect(TournamentStatus.registration.isEditable, true);
      expect(TournamentStatus.live.isEditable, false);
      expect(TournamentStatus.completed.isEditable, false);
    });

    test('isFinished returns true only for completed', () {
      expect(TournamentStatus.draft.isFinished, false);
      expect(TournamentStatus.registration.isFinished, false);
      expect(TournamentStatus.live.isFinished, false);
      expect(TournamentStatus.completed.isFinished, true);
    });

    test('isActive returns true only for live', () {
      expect(TournamentStatus.draft.isActive, false);
      expect(TournamentStatus.registration.isActive, false);
      expect(TournamentStatus.live.isActive, true);
      expect(TournamentStatus.completed.isActive, false);
    });

    test('validTransitions follows state machine', () {
      expect(
        TournamentStatus.draft.validTransitions,
        [TournamentStatus.registration],
      );
      expect(
        TournamentStatus.registration.validTransitions,
        [TournamentStatus.live],
      );
      expect(
        TournamentStatus.live.validTransitions,
        [TournamentStatus.completed],
      );
      expect(TournamentStatus.completed.validTransitions, isEmpty);
    });

    test('canTransitionTo validates transitions correctly', () {
      // Valid transitions
      expect(
        TournamentStatus.draft.canTransitionTo(TournamentStatus.registration),
        true,
      );
      expect(
        TournamentStatus.registration.canTransitionTo(TournamentStatus.live),
        true,
      );
      expect(
        TournamentStatus.live.canTransitionTo(TournamentStatus.completed),
        true,
      );

      // Invalid transitions
      expect(
        TournamentStatus.draft.canTransitionTo(TournamentStatus.live),
        false,
      );
      expect(
        TournamentStatus.draft.canTransitionTo(TournamentStatus.completed),
        false,
      );
      expect(
        TournamentStatus.registration.canTransitionTo(TournamentStatus.draft),
        false,
      );
      expect(
        TournamentStatus.completed.canTransitionTo(TournamentStatus.draft),
        false,
      );
      expect(
        TournamentStatus.live.canTransitionTo(TournamentStatus.draft),
        false,
      );
    });
  });

  group('Tournament', () {
    final now = DateTime(2026, 3, 1);

    Tournament createTournament({
      String id = 'tournament-1',
      String name = 'Weekend Warriors Cup',
      TournamentFormat format = TournamentFormat.groupKnockout,
      int oversPerMatch = 20,
      int ballTypeId = 1,
      TournamentStatus status = TournamentStatus.draft,
      int pointsWin = 2,
      int pointsTie = 1,
      int pointsNoResult = 1,
      int pointsLoss = 0,
      int numGroups = 2,
      int qualifyPerGroup = 2,
      bool hasThirdPlaceMatch = false,
      int playersPerSide = 11,
      int wideRuns = 1,
      int noBallRuns = 1,
      String createdBy = 'user-1',
      int? maxOversPerBowler,
      int? powerplayOvers,
      String? startDate,
      String? endDate,
      int? teamCount,
    }) {
      return Tournament(
        id: id,
        name: name,
        format: format,
        oversPerMatch: oversPerMatch,
        ballTypeId: ballTypeId,
        status: status,
        pointsWin: pointsWin,
        pointsTie: pointsTie,
        pointsNoResult: pointsNoResult,
        pointsLoss: pointsLoss,
        numGroups: numGroups,
        qualifyPerGroup: qualifyPerGroup,
        hasThirdPlaceMatch: hasThirdPlaceMatch,
        playersPerSide: playersPerSide,
        wideRuns: wideRuns,
        noBallRuns: noBallRuns,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        maxOversPerBowler: maxOversPerBowler,
        powerplayOvers: powerplayOvers,
        startDate: startDate,
        endDate: endDate,
        teamCount: teamCount,
      );
    }

    test('creates with required fields', () {
      final tournament = createTournament();
      expect(tournament.id, 'tournament-1');
      expect(tournament.name, 'Weekend Warriors Cup');
      expect(tournament.format, TournamentFormat.groupKnockout);
      expect(tournament.oversPerMatch, 20);
      expect(tournament.ballTypeId, 1);
      expect(tournament.status, TournamentStatus.draft);
      expect(tournament.pointsWin, 2);
      expect(tournament.pointsTie, 1);
      expect(tournament.pointsNoResult, 1);
      expect(tournament.pointsLoss, 0);
      expect(tournament.numGroups, 2);
      expect(tournament.qualifyPerGroup, 2);
      expect(tournament.hasThirdPlaceMatch, false);
      expect(tournament.playersPerSide, 11);
      expect(tournament.wideRuns, 1);
      expect(tournament.noBallRuns, 1);
      expect(tournament.createdBy, 'user-1');
    });

    test('optional fields default to null', () {
      final tournament = createTournament();
      expect(tournament.maxOversPerBowler, isNull);
      expect(tournament.powerplayOvers, isNull);
      expect(tournament.startDate, isNull);
      expect(tournament.endDate, isNull);
      expect(tournament.teamCount, isNull);
      expect(tournament.teams, isNull);
      expect(tournament.groups, isNull);
    });

    test('creates with all optional fields', () {
      final tournament = createTournament(
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        startDate: '2026-03-01',
        endDate: '2026-03-15',
        teamCount: 8,
      );
      expect(tournament.maxOversPerBowler, 4);
      expect(tournament.powerplayOvers, 6);
      expect(tournament.startDate, '2026-03-01');
      expect(tournament.endDate, '2026-03-15');
      expect(tournament.teamCount, 8);
    });

    test('effectiveMaxOversPerBowler uses provided value', () {
      final tournament = createTournament(maxOversPerBowler: 4);
      expect(tournament.effectiveMaxOversPerBowler, 4);
    });

    test('effectiveMaxOversPerBowler falls back to ceil(overs/5)', () {
      expect(
        createTournament(oversPerMatch: 20).effectiveMaxOversPerBowler,
        4,
      );
      expect(
        createTournament(oversPerMatch: 50).effectiveMaxOversPerBowler,
        10,
      );
      expect(
        createTournament(oversPerMatch: 6).effectiveMaxOversPerBowler,
        2,
      );
      expect(
        createTournament(oversPerMatch: 5).effectiveMaxOversPerBowler,
        1,
      );
    });

    test('hasGroupStage returns true only for groupKnockout', () {
      expect(
        createTournament(format: TournamentFormat.groupKnockout).hasGroupStage,
        true,
      );
      expect(
        createTournament(format: TournamentFormat.roundRobin).hasGroupStage,
        false,
      );
      expect(
        createTournament(format: TournamentFormat.knockout).hasGroupStage,
        false,
      );
    });

    test('hasKnockoutStage returns true for knockout formats', () {
      expect(
        createTournament(format: TournamentFormat.knockout).hasKnockoutStage,
        true,
      );
      expect(
        createTournament(
          format: TournamentFormat.groupKnockout,
        ).hasKnockoutStage,
        true,
      );
      expect(
        createTournament(format: TournamentFormat.roundRobin).hasKnockoutStage,
        false,
      );
    });

    test('hasPointsSystem returns false only for pure knockout', () {
      expect(
        createTournament(format: TournamentFormat.roundRobin).hasPointsSystem,
        true,
      );
      expect(
        createTournament(
          format: TournamentFormat.groupKnockout,
        ).hasPointsSystem,
        true,
      );
      expect(
        createTournament(format: TournamentFormat.knockout).hasPointsSystem,
        false,
      );
    });

    test('isEditable delegates to status', () {
      expect(
        createTournament(status: TournamentStatus.draft).isEditable,
        true,
      );
      expect(
        createTournament(status: TournamentStatus.registration).isEditable,
        true,
      );
      expect(
        createTournament(status: TournamentStatus.live).isEditable,
        false,
      );
      expect(
        createTournament(status: TournamentStatus.completed).isEditable,
        false,
      );
    });

    test('formatLabel returns format and overs', () {
      expect(createTournament().formatLabel, 'Group + KO · 20 Overs');
      expect(
        createTournament(
          format: TournamentFormat.roundRobin,
          oversPerMatch: 10,
        ).formatLabel,
        'Round Robin · 10 Overs',
      );
    });

    test('dateRange returns null when no dates', () {
      expect(createTournament().dateRange, isNull);
    });

    test('dateRange returns range when both dates set', () {
      expect(
        createTournament(
          startDate: '2026-03-01',
          endDate: '2026-03-15',
        ).dateRange,
        '2026-03-01 - 2026-03-15',
      );
    });

    test('dateRange returns single date when only one set', () {
      expect(
        createTournament(startDate: '2026-03-01').dateRange,
        '2026-03-01',
      );
      expect(
        createTournament(endDate: '2026-03-15').dateRange,
        '2026-03-15',
      );
    });
  });

  group('Tournament validation', () {
    test('validateName accepts 2-100 characters', () {
      expect(Tournament.validateName('AB'), isNull);
      expect(Tournament.validateName('Weekend Warriors Cup'), isNull);
      expect(Tournament.validateName('A' * 100), isNull);
    });

    test('validateName rejects out of range', () {
      expect(Tournament.validateName('A'), isNotNull);
      expect(Tournament.validateName(''), isNotNull);
      expect(Tournament.validateName('A' * 101), isNotNull);
    });

    test('validateOvers accepts 1-50', () {
      expect(Tournament.validateOvers(1), isNull);
      expect(Tournament.validateOvers(20), isNull);
      expect(Tournament.validateOvers(50), isNull);
    });

    test('validateOvers rejects out of range', () {
      expect(Tournament.validateOvers(0), isNotNull);
      expect(Tournament.validateOvers(51), isNotNull);
    });

    test('validatePlayersPerSide accepts 2-11', () {
      expect(Tournament.validatePlayersPerSide(2), isNull);
      expect(Tournament.validatePlayersPerSide(11), isNull);
      expect(Tournament.validatePlayersPerSide(6), isNull);
    });

    test('validatePlayersPerSide rejects out of range', () {
      expect(Tournament.validatePlayersPerSide(1), isNotNull);
      expect(Tournament.validatePlayersPerSide(12), isNotNull);
    });

    test('validatePoints accepts 0-10', () {
      expect(Tournament.validatePoints(0), isNull);
      expect(Tournament.validatePoints(2), isNull);
      expect(Tournament.validatePoints(10), isNull);
    });

    test('validatePoints rejects out of range', () {
      expect(Tournament.validatePoints(-1), isNotNull);
      expect(Tournament.validatePoints(11), isNotNull);
    });

    test('validateNumGroups accepts 1-8', () {
      expect(Tournament.validateNumGroups(1), isNull);
      expect(Tournament.validateNumGroups(4), isNull);
      expect(Tournament.validateNumGroups(8), isNull);
    });

    test('validateNumGroups rejects out of range', () {
      expect(Tournament.validateNumGroups(0), isNotNull);
      expect(Tournament.validateNumGroups(9), isNotNull);
    });

    test('validateQualifyPerGroup accepts 1-4', () {
      expect(Tournament.validateQualifyPerGroup(1), isNull);
      expect(Tournament.validateQualifyPerGroup(2), isNull);
      expect(Tournament.validateQualifyPerGroup(4), isNull);
    });

    test('validateQualifyPerGroup rejects out of range', () {
      expect(Tournament.validateQualifyPerGroup(0), isNotNull);
      expect(Tournament.validateQualifyPerGroup(5), isNotNull);
    });

    test('validateWideRuns accepts 1-5', () {
      expect(Tournament.validateWideRuns(1), isNull);
      expect(Tournament.validateWideRuns(5), isNull);
    });

    test('validateWideRuns rejects out of range', () {
      expect(Tournament.validateWideRuns(0), isNotNull);
      expect(Tournament.validateWideRuns(6), isNotNull);
    });

    test('validateNoBallRuns accepts 1-5', () {
      expect(Tournament.validateNoBallRuns(1), isNull);
      expect(Tournament.validateNoBallRuns(5), isNull);
    });

    test('validateNoBallRuns rejects out of range', () {
      expect(Tournament.validateNoBallRuns(0), isNotNull);
      expect(Tournament.validateNoBallRuns(6), isNotNull);
    });

    test('validatePowerplayOvers accepts null', () {
      expect(Tournament.validatePowerplayOvers(null, 20), isNull);
    });

    test('validatePowerplayOvers accepts 1 to totalOvers', () {
      expect(Tournament.validatePowerplayOvers(1, 20), isNull);
      expect(Tournament.validatePowerplayOvers(6, 20), isNull);
      expect(Tournament.validatePowerplayOvers(20, 20), isNull);
    });

    test('validatePowerplayOvers rejects out of range', () {
      expect(Tournament.validatePowerplayOvers(0, 20), isNotNull);
      expect(Tournament.validatePowerplayOvers(21, 20), isNotNull);
    });

    test('validateMaxOversPerBowler accepts null', () {
      expect(Tournament.validateMaxOversPerBowler(null, 20), isNull);
    });

    test('validateMaxOversPerBowler accepts 1 to totalOvers', () {
      expect(Tournament.validateMaxOversPerBowler(1, 20), isNull);
      expect(Tournament.validateMaxOversPerBowler(4, 20), isNull);
      expect(Tournament.validateMaxOversPerBowler(20, 20), isNull);
    });

    test('validateMaxOversPerBowler rejects out of range', () {
      expect(Tournament.validateMaxOversPerBowler(0, 20), isNotNull);
      expect(Tournament.validateMaxOversPerBowler(21, 20), isNotNull);
    });
  });

  group('TournamentTeam', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 3, 1);
      final team = TournamentTeam(
        id: 'tt-1',
        tournamentId: 'tournament-1',
        teamId: 'team-1',
        joinedAt: now,
        updatedAt: now,
      );

      expect(team.id, 'tt-1');
      expect(team.tournamentId, 'tournament-1');
      expect(team.teamId, 'team-1');
      expect(team.groupName, isNull);
      expect(team.seedNumber, isNull);
      expect(team.teamName, isNull);
    });

    test('creates with optional fields', () {
      final now = DateTime(2026, 3, 1);
      final team = TournamentTeam(
        id: 'tt-1',
        tournamentId: 'tournament-1',
        teamId: 'team-1',
        joinedAt: now,
        updatedAt: now,
        groupName: 'A',
        seedNumber: 1,
        teamName: 'Mumbai Warriors',
      );

      expect(team.groupName, 'A');
      expect(team.seedNumber, 1);
      expect(team.teamName, 'Mumbai Warriors');
    });
  });

  group('TournamentGroup', () {
    test('creates with name only', () {
      const group = TournamentGroup(name: 'A');
      expect(group.name, 'A');
      expect(group.teamCount, isNull);
    });

    test('creates with teamCount', () {
      const group = TournamentGroup(name: 'B', teamCount: 4);
      expect(group.name, 'B');
      expect(group.teamCount, 4);
    });
  });
}
