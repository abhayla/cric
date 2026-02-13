/// Registration request status — mirrors server-side enum.
enum RequestStatus {
  pending('Pending', 'pending'),
  approved('Approved', 'approved'),
  rejected('Rejected', 'rejected');

  const RequestStatus(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static RequestStatus fromApiValue(String value) {
    return RequestStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => throw ArgumentError('Unknown request status: $value'),
    );
  }
}

/// Tournament registration request entity.
class TournamentRequest {
  const TournamentRequest({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.requestedBy,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
    this.teamName,
    this.teamLocation,
    this.rosterCount,
    this.requestedByName,
    this.rejectionReason,
    this.resolvedAt,
  });

  final String id;
  final String tournamentId;
  final String teamId;
  final String requestedBy;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime updatedAt;

  // Optional fields (populated from joins)
  final String? teamName;
  final String? teamLocation;
  final int? rosterCount;
  final String? requestedByName;
  final String? rejectionReason;
  final DateTime? resolvedAt;

  /// Whether the request is still pending.
  bool get isPending => status == RequestStatus.pending;

  /// Whether the request was approved.
  bool get isApproved => status == RequestStatus.approved;

  /// Whether the request was rejected.
  bool get isRejected => status == RequestStatus.rejected;
}
