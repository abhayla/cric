import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/domain/entities/tournament_request.dart';

void main() {
  group('RequestStatus', () {
    test('has exactly 3 values', () {
      expect(RequestStatus.values.length, 3);
    });

    test('contains expected values', () {
      expect(RequestStatus.values, contains(RequestStatus.pending));
      expect(RequestStatus.values, contains(RequestStatus.approved));
      expect(RequestStatus.values, contains(RequestStatus.rejected));
    });

    test('labels are correct', () {
      expect(RequestStatus.pending.label, 'Pending');
      expect(RequestStatus.approved.label, 'Approved');
      expect(RequestStatus.rejected.label, 'Rejected');
    });

    test('apiValue maps correctly', () {
      expect(RequestStatus.pending.apiValue, 'pending');
      expect(RequestStatus.approved.apiValue, 'approved');
      expect(RequestStatus.rejected.apiValue, 'rejected');
    });

    test('fromApiValue parses correctly', () {
      expect(RequestStatus.fromApiValue('pending'), RequestStatus.pending);
      expect(RequestStatus.fromApiValue('approved'), RequestStatus.approved);
      expect(RequestStatus.fromApiValue('rejected'), RequestStatus.rejected);
    });

    test('fromApiValue throws for unknown value', () {
      expect(
        () => RequestStatus.fromApiValue('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('TournamentRequest', () {
    final now = DateTime(2026, 3, 1);

    TournamentRequest createRequest({
      String id = 'request-1',
      String tournamentId = 'tournament-1',
      String teamId = 'team-1',
      String requestedBy = 'user-1',
      RequestStatus status = RequestStatus.pending,
      String? teamName,
      String? teamLocation,
      int? rosterCount,
      String? requestedByName,
      String? rejectionReason,
      DateTime? resolvedAt,
    }) {
      return TournamentRequest(
        id: id,
        tournamentId: tournamentId,
        teamId: teamId,
        requestedBy: requestedBy,
        status: status,
        requestedAt: now,
        updatedAt: now,
        teamName: teamName,
        teamLocation: teamLocation,
        rosterCount: rosterCount,
        requestedByName: requestedByName,
        rejectionReason: rejectionReason,
        resolvedAt: resolvedAt,
      );
    }

    test('creates with required fields', () {
      final request = createRequest();
      expect(request.id, 'request-1');
      expect(request.tournamentId, 'tournament-1');
      expect(request.teamId, 'team-1');
      expect(request.requestedBy, 'user-1');
      expect(request.status, RequestStatus.pending);
      expect(request.requestedAt, now);
    });

    test('optional fields default to null', () {
      final request = createRequest();
      expect(request.teamName, isNull);
      expect(request.teamLocation, isNull);
      expect(request.rosterCount, isNull);
      expect(request.requestedByName, isNull);
      expect(request.rejectionReason, isNull);
      expect(request.resolvedAt, isNull);
    });

    test('creates with all optional fields', () {
      final resolvedTime = DateTime(2026, 3, 2);
      final request = createRequest(
        teamName: 'Mumbai Warriors',
        teamLocation: 'Mumbai',
        rosterCount: 15,
        requestedByName: 'Rohit Sharma',
        rejectionReason: 'Roster too small',
        resolvedAt: resolvedTime,
      );

      expect(request.teamName, 'Mumbai Warriors');
      expect(request.teamLocation, 'Mumbai');
      expect(request.rosterCount, 15);
      expect(request.requestedByName, 'Rohit Sharma');
      expect(request.rejectionReason, 'Roster too small');
      expect(request.resolvedAt, resolvedTime);
    });

    test('isPending returns true only for pending status', () {
      expect(createRequest(status: RequestStatus.pending).isPending, true);
      expect(createRequest(status: RequestStatus.approved).isPending, false);
      expect(createRequest(status: RequestStatus.rejected).isPending, false);
    });

    test('isApproved returns true only for approved status', () {
      expect(createRequest(status: RequestStatus.approved).isApproved, true);
      expect(createRequest(status: RequestStatus.pending).isApproved, false);
      expect(createRequest(status: RequestStatus.rejected).isApproved, false);
    });

    test('isRejected returns true only for rejected status', () {
      expect(createRequest(status: RequestStatus.rejected).isRejected, true);
      expect(createRequest(status: RequestStatus.pending).isRejected, false);
      expect(createRequest(status: RequestStatus.approved).isRejected, false);
    });
  });
}
