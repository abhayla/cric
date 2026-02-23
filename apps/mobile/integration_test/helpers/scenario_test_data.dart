import 'data_generators.dart';

/// Two full 11-player teams for Must Have E2E scenarios.
///
/// Team A (Mumbai Warriors): 4 batters, 3 bowlers, 3 all-rounders, 1 WK-batter
/// Team B (Chennai Challengers): 4 batters, 3 bowlers, 3 all-rounders, 1 WK-batter
///
/// All tests reuse these teams via smart reset (Scenario 0):
///   - First run: full DB reset + create teams via API
///   - Subsequent runs: reset match data only, reuse existing teams
class ScenarioTeams {
  static const teamAName = 'Mumbai Warriors';
  static const teamBName = 'Chennai Challengers';

  static TeamData get teamA => const TeamData(
        name: teamAName,
        players: [
          // Batters (indexes 0-3)
          PlayerData(name: 'Rohit Sharma', role: 'batter'),
          PlayerData(name: 'Virat Kohli', role: 'batter'),
          PlayerData(name: 'Suryakumar Yadav', role: 'batter'),
          PlayerData(name: 'KL Rahul', role: 'batter'),
          // All-rounders (indexes 4-6)
          PlayerData(name: 'Hardik Pandya', role: 'all_rounder'),
          PlayerData(name: 'Ravindra Jadeja', role: 'all_rounder'),
          PlayerData(name: 'Axar Patel', role: 'all_rounder'),
          // Bowlers (indexes 7-9)
          PlayerData(name: 'Jasprit Bumrah', role: 'bowler'),
          PlayerData(name: 'Mohammed Shami', role: 'bowler'),
          PlayerData(name: 'Yuzvendra Chahal', role: 'bowler'),
          // WK-Batter (index 10)
          PlayerData(name: 'Rishabh Pant', role: 'wk_batter'),
        ],
      );

  static TeamData get teamB => const TeamData(
        name: teamBName,
        players: [
          // Batters (indexes 0-3)
          PlayerData(name: 'Shubman Gill', role: 'batter'),
          PlayerData(name: 'Yashasvi Jaiswal', role: 'batter'),
          PlayerData(name: 'Shreyas Iyer', role: 'batter'),
          PlayerData(name: 'Sanju Samson', role: 'batter'),
          // All-rounders (indexes 4-6)
          PlayerData(name: 'Ravichandran Ashwin', role: 'all_rounder'),
          PlayerData(name: 'Washington Sundar', role: 'all_rounder'),
          PlayerData(name: 'Shardul Thakur', role: 'all_rounder'),
          // Bowlers (indexes 7-9)
          PlayerData(name: 'Deepak Chahar', role: 'bowler'),
          PlayerData(name: 'Bhuvneshwar Kumar', role: 'bowler'),
          PlayerData(name: 'Kuldeep Yadav', role: 'bowler'),
          // WK-Batter (index 10)
          PlayerData(name: 'Ishan Kishan', role: 'wk_batter'),
        ],
      );

  /// Opening batters for Team A (batting first).
  static String get teamAOpener1 => teamA.players[0].name; // Rohit Sharma
  static String get teamAOpener2 => teamA.players[1].name; // Virat Kohli

  /// Opening bowler from Team B (bowling first).
  static String get teamBOpeningBowler =>
      teamB.players[7].name; // Deepak Chahar

  /// Opening batters for Team B (batting second).
  static String get teamBOpener1 => teamB.players[0].name; // Shubman Gill
  static String get teamBOpener2 => teamB.players[1].name; // Yashasvi Jaiswal

  /// Opening bowler from Team A (bowling second).
  static String get teamAOpeningBowler =>
      teamA.players[7].name; // Jasprit Bumrah

  /// Bowler pool for Team A (for rotation across overs).
  static List<String> get teamABowlers => [
        teamA.players[7].name, // Jasprit Bumrah
        teamA.players[8].name, // Mohammed Shami
        teamA.players[9].name, // Yuzvendra Chahal
        teamA.players[4].name, // Hardik Pandya
        teamA.players[5].name, // Ravindra Jadeja
        teamA.players[6].name, // Axar Patel
      ];

  /// Bowler pool for Team B (for rotation across overs).
  static List<String> get teamBBowlers => [
        teamB.players[7].name, // Deepak Chahar
        teamB.players[8].name, // Bhuvneshwar Kumar
        teamB.players[9].name, // Kuldeep Yadav
        teamB.players[4].name, // Ravichandran Ashwin
        teamB.players[5].name, // Washington Sundar
        teamB.players[6].name, // Shardul Thakur
      ];

  /// Batter names for Team A (all 11 in batting order).
  static List<String> get teamABatters =>
      teamA.players.map((p) => p.name).toList();

  /// Batter names for Team B (all 11 in batting order).
  static List<String> get teamBBatters =>
      teamB.players.map((p) => p.name).toList();

  /// Fielder candidates from a team (all 11 players).
  static List<String> get teamAFielders => teamABatters;
  static List<String> get teamBFielders => teamBBatters;
}
