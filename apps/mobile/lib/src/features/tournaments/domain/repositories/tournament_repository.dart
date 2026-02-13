import '../entities/fixture.dart';
import '../entities/standing.dart';
import '../entities/tournament.dart';
import '../entities/tournament_request.dart';

/// Paginated tournament list response.
class TournamentListResult {
  const TournamentListResult({
    required this.tournaments,
    required this.total,
    required this.page,
  });

  final List<Tournament> tournaments;
  final int total;
  final int page;
}

/// Input for creating a tournament.
class CreateTournamentInput {
  const CreateTournamentInput({
    required this.name,
    required this.format,
    required this.oversPerMatch,
    required this.ballTypeId,
    this.pointsWin = 2,
    this.pointsTie = 1,
    this.pointsNoResult = 1,
    this.pointsLoss = 0,
    this.numGroups = 1,
    this.qualifyPerGroup = 2,
    this.hasThirdPlaceMatch = false,
    this.playersPerSide = 11,
    this.maxOversPerBowler,
    this.wideRuns = 1,
    this.noBallRuns = 1,
    this.powerplayOvers,
    this.startDate,
    this.endDate,
  });

  final String name;
  final TournamentFormat format;
  final int oversPerMatch;
  final int ballTypeId;
  final int pointsWin;
  final int pointsTie;
  final int pointsNoResult;
  final int pointsLoss;
  final int numGroups;
  final int qualifyPerGroup;
  final bool hasThirdPlaceMatch;
  final int playersPerSide;
  final int? maxOversPerBowler;
  final int wideRuns;
  final int noBallRuns;
  final int? powerplayOvers;
  final String? startDate;
  final String? endDate;
}

/// Input for updating a tournament.
class UpdateTournamentInput {
  const UpdateTournamentInput({
    this.name,
    this.oversPerMatch,
    this.ballTypeId,
    this.pointsWin,
    this.pointsTie,
    this.pointsNoResult,
    this.pointsLoss,
    this.numGroups,
    this.qualifyPerGroup,
    this.hasThirdPlaceMatch,
    this.playersPerSide,
    this.maxOversPerBowler,
    this.wideRuns,
    this.noBallRuns,
    this.powerplayOvers,
    this.startDate,
    this.endDate,
  });

  final String? name;
  final int? oversPerMatch;
  final int? ballTypeId;
  final int? pointsWin;
  final int? pointsTie;
  final int? pointsNoResult;
  final int? pointsLoss;
  final int? numGroups;
  final int? qualifyPerGroup;
  final bool? hasThirdPlaceMatch;
  final int? playersPerSide;
  final int? maxOversPerBowler;
  final int? wideRuns;
  final int? noBallRuns;
  final int? powerplayOvers;
  final String? startDate;
  final String? endDate;
}

/// Result from fixture generation.
class GenerateFixturesResult {
  const GenerateFixturesResult({
    required this.fixtures,
    required this.totalFixtures,
  });

  final List<Fixture> fixtures;
  final int totalFixtures;
}

/// Result from standings query.
class StandingsResult {
  const StandingsResult({
    required this.standings,
    required this.groups,
  });

  final List<Standing> standings;
  final List<String> groups;
}

/// Leaderboard entry for tournament player stats.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.value,
    required this.matches,
    this.details,
  });

  final int rank;
  final String playerId;
  final String playerName;
  final String teamName;
  final double value;
  final int matches;
  final Map<String, dynamic>? details;
}

/// Leaderboard categories.
enum LeaderboardCategory {
  runs('Runs', 'runs'),
  wickets('Wickets', 'wickets'),
  battingAvg('Batting Avg', 'batting_avg'),
  economy('Economy', 'economy');

  const LeaderboardCategory(this.label, this.apiValue);
  final String label;
  final String apiValue;

  static LeaderboardCategory fromApiValue(String value) {
    return LeaderboardCategory.values.firstWhere(
      (c) => c.apiValue == value,
      orElse: () => throw ArgumentError('Unknown leaderboard category: $value'),
    );
  }
}

/// Result from leaderboard query.
class LeaderboardResult {
  const LeaderboardResult({
    required this.category,
    required this.leaderboard,
  });

  final LeaderboardCategory category;
  final List<LeaderboardEntry> leaderboard;
}

/// Abstract repository interface for tournament operations.
abstract class TournamentRepository {
  /// Create a new tournament.
  Future<Tournament> createTournament(CreateTournamentInput input);

  /// Get paginated list of user's tournaments.
  Future<TournamentListResult> getTournaments({
    int page = 1,
    int limit = 20,
    TournamentStatus? status,
  });

  /// Get tournament details with teams and groups.
  Future<Tournament> getTournament(String tournamentId);

  /// Update tournament settings.
  Future<Tournament> updateTournament(
    String tournamentId,
    UpdateTournamentInput input,
  );

  /// Transition tournament status.
  Future<Tournament> transitionStatus(
    String tournamentId,
    TournamentStatus newStatus,
  );

  /// Add a team directly (organizer action).
  Future<TournamentTeam> addTeam(
    String tournamentId, {
    required String teamId,
    String? groupName,
    int? seedNumber,
  });

  /// Register a team (creates a pending request).
  Future<TournamentRequest> registerTeam(
    String tournamentId, {
    required String teamId,
  });

  /// Get registration requests.
  Future<List<TournamentRequest>> getRequests(
    String tournamentId, {
    RequestStatus? status,
  });

  /// Approve or reject a registration request.
  Future<TournamentRequest> resolveRequest(
    String tournamentId,
    String requestId, {
    required RequestStatus status,
    String? groupName,
    int? seedNumber,
    String? rejectionReason,
  });

  /// Remove a team from the tournament.
  Future<void> removeTeam(String tournamentId, String teamId);

  /// Auto-generate fixtures based on format and teams.
  Future<GenerateFixturesResult> generateFixtures(String tournamentId);

  /// Get fixtures with optional filters.
  Future<List<Fixture>> getFixtures(
    String tournamentId, {
    RoundType? roundType,
    String? groupName,
  });

  /// Edit a fixture's schedule/venue.
  Future<Fixture> editFixture(
    String tournamentId,
    String fixtureId, {
    String? scheduledDate,
    String? scheduledTime,
    int? estimatedDurationMinutes,
    String? venue,
    String? homeTeamId,
    String? awayTeamId,
  });

  /// Get standings/points table.
  Future<StandingsResult> getStandings(
    String tournamentId, {
    String? groupName,
  });

  /// Get tournament player leaderboard.
  Future<LeaderboardResult> getLeaderboard(
    String tournamentId, {
    required LeaderboardCategory category,
    int limit = 10,
  });
}
