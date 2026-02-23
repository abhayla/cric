import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/tournament.dart';
import 'package:cricscores/src/features/tournaments/domain/repositories/tournament_repository.dart';

void main() {
  group('TournamentListResult', () {
    test('creates with required fields', () {
      const result = TournamentListResult(
        tournaments: [],
        total: 0,
        page: 1,
      );
      expect(result.tournaments, isEmpty);
      expect(result.total, 0);
      expect(result.page, 1);
    });

    test('holds tournament list', () {
      final now = DateTime(2026, 3, 1);
      final result = TournamentListResult(
        tournaments: [
          Tournament(
            id: 't-1',
            name: 'Test Cup',
            format: TournamentFormat.knockout,
            oversPerMatch: 20,
            ballTypeId: 1,
            status: TournamentStatus.draft,
            pointsWin: 2,
            pointsTie: 1,
            pointsNoResult: 1,
            pointsLoss: 0,
            numGroups: 1,
            qualifyPerGroup: 2,
            hasThirdPlaceMatch: false,
            playersPerSide: 11,
            wideRuns: 1,
            noBallRuns: 1,
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        total: 1,
        page: 1,
      );
      expect(result.tournaments.length, 1);
      expect(result.total, 1);
    });
  });

  group('CreateTournamentInput', () {
    test('creates with required fields and defaults', () {
      const input = CreateTournamentInput(
        name: 'Test Cup',
        format: TournamentFormat.roundRobin,
        oversPerMatch: 20,
        ballTypeId: 1,
      );
      expect(input.name, 'Test Cup');
      expect(input.format, TournamentFormat.roundRobin);
      expect(input.oversPerMatch, 20);
      expect(input.ballTypeId, 1);
      expect(input.pointsWin, 2);
      expect(input.pointsTie, 1);
      expect(input.pointsNoResult, 1);
      expect(input.pointsLoss, 0);
      expect(input.numGroups, 1);
      expect(input.qualifyPerGroup, 2);
      expect(input.hasThirdPlaceMatch, false);
      expect(input.playersPerSide, 11);
      expect(input.maxOversPerBowler, isNull);
      expect(input.wideRuns, 1);
      expect(input.noBallRuns, 1);
      expect(input.powerplayOvers, isNull);
      expect(input.startDate, isNull);
      expect(input.endDate, isNull);
    });

    test('creates with all custom values', () {
      const input = CreateTournamentInput(
        name: 'Champions League',
        format: TournamentFormat.groupKnockout,
        oversPerMatch: 50,
        ballTypeId: 2,
        pointsWin: 3,
        pointsTie: 1,
        pointsNoResult: 1,
        pointsLoss: 0,
        numGroups: 4,
        qualifyPerGroup: 2,
        hasThirdPlaceMatch: true,
        playersPerSide: 8,
        maxOversPerBowler: 10,
        wideRuns: 2,
        noBallRuns: 2,
        powerplayOvers: 10,
        startDate: '2026-04-01',
        endDate: '2026-04-30',
      );
      expect(input.pointsWin, 3);
      expect(input.numGroups, 4);
      expect(input.hasThirdPlaceMatch, true);
      expect(input.playersPerSide, 8);
      expect(input.maxOversPerBowler, 10);
      expect(input.wideRuns, 2);
      expect(input.powerplayOvers, 10);
      expect(input.startDate, '2026-04-01');
    });
  });

  group('UpdateTournamentInput', () {
    test('creates with all null fields', () {
      const input = UpdateTournamentInput();
      expect(input.name, isNull);
      expect(input.oversPerMatch, isNull);
      expect(input.ballTypeId, isNull);
      expect(input.pointsWin, isNull);
      expect(input.playersPerSide, isNull);
    });

    test('creates with selective fields', () {
      const input = UpdateTournamentInput(
        name: 'Updated Cup',
        oversPerMatch: 10,
      );
      expect(input.name, 'Updated Cup');
      expect(input.oversPerMatch, 10);
      expect(input.ballTypeId, isNull);
    });
  });

  group('GenerateFixturesResult', () {
    test('creates with fixtures list', () {
      const result = GenerateFixturesResult(
        fixtures: [],
        totalFixtures: 0,
      );
      expect(result.fixtures, isEmpty);
      expect(result.totalFixtures, 0);
    });
  });

  group('StandingsResult', () {
    test('creates with standings and groups', () {
      const result = StandingsResult(
        standings: [],
        groups: ['A', 'B'],
      );
      expect(result.standings, isEmpty);
      expect(result.groups, ['A', 'B']);
    });
  });

  group('LeaderboardCategory', () {
    test('has exactly 4 values', () {
      expect(LeaderboardCategory.values.length, 4);
    });

    test('contains expected values', () {
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.runs));
      expect(
        LeaderboardCategory.values,
        contains(LeaderboardCategory.wickets),
      );
      expect(
        LeaderboardCategory.values,
        contains(LeaderboardCategory.battingAvg),
      );
      expect(
        LeaderboardCategory.values,
        contains(LeaderboardCategory.economy),
      );
    });

    test('labels are correct', () {
      expect(LeaderboardCategory.runs.label, 'Runs');
      expect(LeaderboardCategory.wickets.label, 'Wickets');
      expect(LeaderboardCategory.battingAvg.label, 'Batting Avg');
      expect(LeaderboardCategory.economy.label, 'Economy');
    });

    test('apiValue maps correctly', () {
      expect(LeaderboardCategory.runs.apiValue, 'runs');
      expect(LeaderboardCategory.wickets.apiValue, 'wickets');
      expect(LeaderboardCategory.battingAvg.apiValue, 'batting_avg');
      expect(LeaderboardCategory.economy.apiValue, 'economy');
    });

    test('fromApiValue parses correctly', () {
      expect(
        LeaderboardCategory.fromApiValue('runs'),
        LeaderboardCategory.runs,
      );
      expect(
        LeaderboardCategory.fromApiValue('wickets'),
        LeaderboardCategory.wickets,
      );
      expect(
        LeaderboardCategory.fromApiValue('batting_avg'),
        LeaderboardCategory.battingAvg,
      );
      expect(
        LeaderboardCategory.fromApiValue('economy'),
        LeaderboardCategory.economy,
      );
    });

    test('fromApiValue throws for unknown value', () {
      expect(
        () => LeaderboardCategory.fromApiValue('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('LeaderboardEntry', () {
    test('creates with required fields', () {
      const entry = LeaderboardEntry(
        rank: 1,
        playerId: 'player-1',
        playerName: 'Arjun Mehta',
        teamName: 'Mumbai Warriors',
        value: 245,
        matches: 3,
      );
      expect(entry.rank, 1);
      expect(entry.playerId, 'player-1');
      expect(entry.playerName, 'Arjun Mehta');
      expect(entry.teamName, 'Mumbai Warriors');
      expect(entry.value, 245);
      expect(entry.matches, 3);
      expect(entry.details, isNull);
    });

    test('creates with details', () {
      const entry = LeaderboardEntry(
        rank: 1,
        playerId: 'player-1',
        playerName: 'Arjun Mehta',
        teamName: 'Mumbai Warriors',
        value: 245,
        matches: 3,
        details: {'innings': 3, 'highestScore': 98, 'strikeRate': 142.44},
      );
      expect(entry.details, isNotNull);
      expect(entry.details!['innings'], 3);
      expect(entry.details!['highestScore'], 98);
    });
  });

  group('LeaderboardResult', () {
    test('creates with category and leaderboard', () {
      const result = LeaderboardResult(
        category: LeaderboardCategory.runs,
        leaderboard: [],
      );
      expect(result.category, LeaderboardCategory.runs);
      expect(result.leaderboard, isEmpty);
    });
  });
}
