/// Single source of truth for all test teams, players, and phone numbers.
///
/// Naming convention:
/// - Teams: Team1, Team2, ..., Team12
/// - Players: Player301, Player302, ... (global index, phone suffix = name suffix)
/// - Phone: 9999999301, 9999999302, ...
/// - Abhay: 9999999998 (viewer account, always on Team1)
library;

/// A test player with deterministic name and phone number.
class TestPlayer {
  const TestPlayer({
    required this.name,
    required this.phone,
    this.role = 'all_rounder',
  });

  final String name;
  final String phone;
  final String role;
}

/// A test team with its roster.
class TestTeam {
  const TestTeam({required this.name, required this.players});

  final String name;
  final List<TestPlayer> players;
}

/// Abhay — viewer account, must be in Team1 of every match.
const abhay = TestPlayer(name: 'Abhay', phone: '9999999998');

/// Generate [count] teams with [playersPerTeam] players each.
///
/// Deterministic naming: Team1..TeamN, Player301..Player(301+N*M-1).
/// Team1 always includes [abhay] as an extra roster member.
List<TestTeam> generateTeams(int count, {int playersPerTeam = 11}) {
  return List.generate(count, (i) {
    final teamNum = i + 1;
    final players = List.generate(playersPerTeam, (j) {
      final globalIdx = i * playersPerTeam + j;
      final suffix = (301 + globalIdx).toString();
      return TestPlayer(name: 'Player$suffix', phone: '9999999$suffix');
    });
    if (i == 0) players.add(abhay); // Abhay always on Team1
    return TestTeam(name: 'Team$teamNum', players: players);
  });
}

/// Pre-generated 12 teams with 11 players each (the standard test set).
final List<TestTeam> allTeams = generateTeams(12, playersPerTeam: 11);

/// Convenience: just team names.
final List<String> allTeamNames = allTeams.map((t) => t.name).toList();
