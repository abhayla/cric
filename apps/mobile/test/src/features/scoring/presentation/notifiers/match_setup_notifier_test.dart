import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cricscores/src/features/scoring/domain/entities/match.dart';
import 'package:cricscores/src/features/scoring/domain/repositories/match_repository.dart';
import 'package:cricscores/src/features/scoring/presentation/notifiers/match_setup_notifier.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  group('MatchSetupState', () {
    test('has correct defaults', () {
      final state = MatchSetupState();

      expect(state.homeTeamId, isNull);
      expect(state.homeTeamName, isNull);
      expect(state.awayTeamId, isNull);
      expect(state.awayTeamName, isNull);
      expect(state.totalOvers, 20);
      expect(state.playersPerSide, 11);
      expect(state.ballTypeId, 1);
      expect(state.matchDate, isNotEmpty);
      expect(state.venue, isNull);
      expect(state.wideRuns, 1);
      expect(state.noBallRuns, 1);
      expect(state.maxOversPerBowler, isNull);
      expect(state.powerplayOvers, isNull);
      expect(state.isAdvancedOpen, false);
      expect(state.isSubmitting, false);
      expect(state.error, isNull);
    });

    test('matchDate defaults to today in yyyy-MM-dd format', () {
      final state = MatchSetupState();
      final now = DateTime.now();
      final expected =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(state.matchDate, expected);
    });

    test('copyWith updates fields correctly', () {
      final state = MatchSetupState();
      final updated = state.copyWith(
        homeTeamId: 'team-1',
        homeTeamName: 'Mumbai Warriors',
        totalOvers: 10,
        ballTypeId: 2,
      );

      expect(updated.homeTeamId, 'team-1');
      expect(updated.homeTeamName, 'Mumbai Warriors');
      expect(updated.totalOvers, 10);
      expect(updated.ballTypeId, 2);
      // Unchanged fields
      expect(updated.playersPerSide, 11);
      expect(updated.awayTeamId, isNull);
    });

    group('validation', () {
      test('isValid returns false when no teams selected', () {
        final state = MatchSetupState();
        expect(state.isValid, false);
      });

      test('isValid returns false when only home team selected', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
        );
        expect(state.isValid, false);
      });

      test('isValid returns false when only away team selected', () {
        final state = MatchSetupState().copyWith(
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
        );
        expect(state.isValid, false);
      });

      test('isValid returns false when same team selected for both', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-1',
          awayTeamName: 'Team A',
        );
        expect(state.isValid, false);
      });

      test('isValid returns true when both different teams selected', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
        );
        expect(state.isValid, true);
      });

      test('isValid returns false when overs out of range', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
          totalOvers: 0,
        );
        expect(state.isValid, false);
      });

      test('isValid returns false when overs > 50', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
          totalOvers: 51,
        );
        expect(state.isValid, false);
      });

      test('isValid returns false when players out of range', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
          playersPerSide: 1,
        );
        expect(state.isValid, false);
      });

      test('teamsError returns error when same team', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-1',
          awayTeamName: 'Team A',
        );
        expect(state.teamsError, isNotNull);
      });

      test('teamsError returns null for different teams', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          homeTeamName: 'Team A',
          awayTeamId: 'team-2',
          awayTeamName: 'Team B',
        );
        expect(state.teamsError, isNull);
      });

      test('oversError returns error for invalid overs', () {
        final state = MatchSetupState().copyWith(totalOvers: 0);
        expect(state.oversError, isNotNull);
      });

      test('oversError returns null for valid overs', () {
        final state = MatchSetupState().copyWith(totalOvers: 20);
        expect(state.oversError, isNull);
      });

      test('playersError returns error for invalid players', () {
        final state = MatchSetupState().copyWith(playersPerSide: 12);
        expect(state.playersError, isNotNull);
      });

      test('playersError returns null for valid players', () {
        final state = MatchSetupState().copyWith(playersPerSide: 11);
        expect(state.playersError, isNull);
      });
    });

    group('format detection', () {
      test('detects T20 format', () {
        final state = MatchSetupState().copyWith(totalOvers: 20);
        expect(state.detectedFormat, MatchFormat.t20);
      });

      test('detects ODI format', () {
        final state = MatchSetupState().copyWith(totalOvers: 50);
        expect(state.detectedFormat, MatchFormat.odi);
      });

      test('returns custom for non-standard overs', () {
        final state = MatchSetupState().copyWith(totalOvers: 15);
        expect(state.detectedFormat, MatchFormat.custom);
      });
    });

    group('toCreateMatchInput', () {
      test('creates input with required fields', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          totalOvers: 20,
          ballTypeId: 1,
          matchDate: '2026-01-15',
        );

        final input = state.toCreateMatchInput();

        expect(input.homeTeamId, 'team-1');
        expect(input.awayTeamId, 'team-2');
        expect(input.format, MatchFormat.t20);
        expect(input.totalOvers, 20);
        expect(input.ballTypeId, 1);
        expect(input.matchDate, '2026-01-15');
      });

      test('includes optional fields when set', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          totalOvers: 10,
          venue: 'Shivaji Park',
          playersPerSide: 8,
          wideRuns: 2,
          noBallRuns: 2,
          maxOversPerBowler: 2,
          powerplayOvers: 3,
        );

        final input = state.toCreateMatchInput();

        expect(input.venue, 'Shivaji Park');
        expect(input.playersPerSide, 8);
        expect(input.wideRuns, 2);
        expect(input.noBallRuns, 2);
        expect(input.maxOversPerBowler, 2);
        expect(input.powerplayOvers, 3);
      });

      test('omits default optional values', () {
        final state = MatchSetupState().copyWith(
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
        );

        final input = state.toCreateMatchInput();

        expect(input.venue, isNull);
        expect(input.maxOversPerBowler, isNull);
        expect(input.powerplayOvers, isNull);
      });
    });
  });

  group('BallType', () {
    test('has 4 values', () {
      expect(BallType.values, hasLength(4));
    });

    test('has correct labels', () {
      expect(BallType.leather.label, 'Leather');
      expect(BallType.tennis.label, 'Tennis');
      expect(BallType.tape.label, 'Tape');
      expect(BallType.other.label, 'Other');
    });

    test('has correct IDs matching seed data', () {
      expect(BallType.leather.id, 1);
      expect(BallType.tennis.id, 2);
      expect(BallType.tape.id, 3);
      expect(BallType.other.id, 4);
    });
  });
}
