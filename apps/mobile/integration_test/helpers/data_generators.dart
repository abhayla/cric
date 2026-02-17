/// Team data for tournament generation.
class TeamData {
  const TeamData({
    required this.name,
    required this.players,
  });

  final String name;
  final List<PlayerData> players;
}

/// Player data for team generation.
class PlayerData {
  const PlayerData({
    required this.name,
    this.role = 'all_rounder',
  });

  final String name;
  final String role;
}

/// Tournament configuration.
class TournamentConfig {
  const TournamentConfig({
    required this.name,
    required this.format,
    required this.overs,
    required this.playersPerSide,
    required this.numGroups,
    required this.qualifyPerGroup,
    this.magicOverNumber,
    this.wideRuns = 1,
    this.noBallRuns = 1,
  });

  final String name;
  final String format; // 'group_knockout', 'knockout', 'round_robin'
  final int overs;
  final int playersPerSide;
  final int numGroups;
  final int qualifyPerGroup;
  final int? magicOverNumber;
  final int wideRuns;
  final int noBallRuns;
}

/// Generates test data for tournament E2E tests.
class TournamentTestData {
  /// Generate 16 teams with 8 players each (6 playing + 2 extras).
  /// Team names: Team1-Team16, Player names: T{n}P{m}.
  static List<TeamData> generate16Teams() {
    return List.generate(16, (i) {
      final teamNum = i + 1;
      final players = List.generate(8, (j) {
        final playerNum = j + 1;
        return PlayerData(
          name: 'T${teamNum}P$playerNum',
          role: 'all_rounder', // Everyone can bat & bowl in 6-player format
        );
      });
      return TeamData(
        name: 'Team$teamNum',
        players: players,
      );
    });
  }

  /// Generate N teams with configurable player count.
  static List<TeamData> generateTeams(int count, {int playersPerTeam = 8}) {
    return List.generate(count, (i) {
      final teamNum = i + 1;
      final players = List.generate(playersPerTeam, (j) {
        final playerNum = j + 1;
        return PlayerData(
          name: 'T${teamNum}P$playerNum',
          role: 'all_rounder',
        );
      });
      return TeamData(
        name: 'Team$teamNum',
        players: players,
      );
    });
  }

  /// Tournament config for MockTour-1: 16-team Group+Knockout.
  static TournamentConfig mockTour1Config() {
    return const TournamentConfig(
      name: 'MockTour-1',
      format: 'group_knockout',
      overs: 6,
      playersPerSide: 6,
      numGroups: 4,
      qualifyPerGroup: 1,
      magicOverNumber: 4,
    );
  }

  /// Group assignments for 16 teams in 4 groups.
  /// Returns: { 'A': [Team1-4], 'B': [Team5-8], 'C': [Team9-12], 'D': [Team13-16] }
  static Map<String, List<int>> defaultGroupAssignments() {
    return {
      'A': [1, 2, 3, 4],
      'B': [5, 6, 7, 8],
      'C': [9, 10, 11, 12],
      'D': [13, 14, 15, 16],
    };
  }
}
