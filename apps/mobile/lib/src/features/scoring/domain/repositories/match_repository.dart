import '../entities/match.dart';

/// Paginated match list response.
class MatchListResult {
  const MatchListResult({
    required this.matches,
    required this.total,
    required this.page,
  });

  final List<Match> matches;
  final int total;
  final int page;
}

/// Input for creating a new match.
class CreateMatchInput {
  const CreateMatchInput({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.format,
    required this.totalOvers,
    required this.ballTypeId,
    required this.matchDate,
    this.venue,
    this.playersPerSide,
    this.maxOversPerBowler,
    this.wideRuns,
    this.noBallRuns,
    this.powerplayOvers,
  });

  final String homeTeamId;
  final String awayTeamId;
  final MatchFormat format;
  final int totalOvers;
  final int ballTypeId;
  final String matchDate;
  final String? venue;
  final int? playersPerSide;
  final int? maxOversPerBowler;
  final int? wideRuns;
  final int? noBallRuns;
  final int? powerplayOvers;
}

/// Input for recording toss result.
class RecordTossInput {
  const RecordTossInput({
    required this.winnerId,
    required this.decision,
    required this.openingStrikerId,
    required this.openingNonStrikerId,
    required this.openingBowlerId,
  });

  final String winnerId;
  final TossDecision decision;
  final String openingStrikerId;
  final String openingNonStrikerId;
  final String openingBowlerId;
}

/// Input for setting a team's Playing XI.
class SetPlayingXIInput {
  const SetPlayingXIInput({
    required this.teamId,
    required this.playerIds,
    required this.captainId,
    required this.keeperId,
  });

  final String teamId;
  final List<String> playerIds;
  final String captainId;
  final String keeperId;
}

/// Abstract repository interface for match operations.
abstract class MatchRepository {
  /// Create a new match.
  Future<Match> createMatch(CreateMatchInput input);

  /// Get paginated list of user's matches.
  Future<MatchListResult> getMatches({int page = 1, int limit = 20});

  /// Get match details with team names and innings.
  Future<Match> getMatch(String matchId);

  /// Submit a team's Playing XI for a match.
  Future<List<PlayingXIEntry>> setPlayingXI(
    String matchId,
    SetPlayingXIInput input,
  );

  /// Record toss result and start the match.
  Future<Match> recordToss(String matchId, RecordTossInput input);
}
