import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/features/tournaments/domain/entities/standing.dart';

void main() {
  group('Standing', () {
    Standing createStanding({
      String tournamentId = 'tournament-1',
      String teamId = 'team-1',
      int played = 3,
      int won = 2,
      int lost = 1,
      int tied = 0,
      int noResult = 0,
      int points = 4,
      double nrr = 1.25,
      int totalRunsScored = 450,
      double totalOversFaced = 57.3,
      int totalRunsConceded = 380,
      double totalOversBowled = 60.0,
      String? groupName,
      int? position,
      String? teamName,
    }) {
      return Standing(
        tournamentId: tournamentId,
        teamId: teamId,
        played: played,
        won: won,
        lost: lost,
        tied: tied,
        noResult: noResult,
        points: points,
        nrr: nrr,
        totalRunsScored: totalRunsScored,
        totalOversFaced: totalOversFaced,
        totalRunsConceded: totalRunsConceded,
        totalOversBowled: totalOversBowled,
        groupName: groupName,
        position: position,
        teamName: teamName,
      );
    }

    test('creates with required fields', () {
      final standing = createStanding();
      expect(standing.tournamentId, 'tournament-1');
      expect(standing.teamId, 'team-1');
      expect(standing.played, 3);
      expect(standing.won, 2);
      expect(standing.lost, 1);
      expect(standing.tied, 0);
      expect(standing.noResult, 0);
      expect(standing.points, 4);
      expect(standing.nrr, 1.25);
      expect(standing.totalRunsScored, 450);
      expect(standing.totalOversFaced, 57.3);
      expect(standing.totalRunsConceded, 380);
      expect(standing.totalOversBowled, 60.0);
    });

    test('optional fields default to null', () {
      final standing = createStanding();
      expect(standing.groupName, isNull);
      expect(standing.position, isNull);
      expect(standing.teamName, isNull);
    });

    test('creates with optional fields', () {
      final standing = createStanding(
        groupName: 'A',
        position: 1,
        teamName: 'Mumbai Warriors',
      );
      expect(standing.groupName, 'A');
      expect(standing.position, 1);
      expect(standing.teamName, 'Mumbai Warriors');
    });

    test('hasPositiveNrr returns true for positive NRR', () {
      expect(createStanding(nrr: 1.25).hasPositiveNrr, true);
      expect(createStanding(nrr: 0.001).hasPositiveNrr, true);
    });

    test('hasPositiveNrr returns false for zero or negative NRR', () {
      expect(createStanding(nrr: 0.0).hasPositiveNrr, false);
      expect(createStanding(nrr: -0.5).hasPositiveNrr, false);
    });

    test('formattedNrr returns string with sign and 3 decimals', () {
      expect(createStanding(nrr: 1.25).formattedNrr, '+1.250');
      expect(createStanding(nrr: -0.5).formattedNrr, '-0.500');
      expect(createStanding(nrr: 0.0).formattedNrr, '+0.000');
      expect(createStanding(nrr: 2.123).formattedNrr, '+2.123');
    });
  });
}
