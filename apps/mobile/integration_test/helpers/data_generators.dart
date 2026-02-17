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

/// Indian cricket-style player names for realistic test data.
const _playerNames = [
  // Team 1 — Mumbai Lions
  ['Rohit Sharma', 'Suryakumar Yadav', 'Ishan Kishan', 'Hardik Pandya', 'Jasprit Bumrah', 'Rahul Chahar', 'Tilak Varma', 'Arjun Tendulkar'],
  // Team 2 — Delhi Capitals
  ['Virat Kohli', 'Rishabh Pant', 'Prithvi Shaw', 'Axar Patel', 'Anrich Nortje', 'Kuldeep Yadav', 'David Warner', 'Lalit Yadav'],
  // Team 3 — Chennai Kings
  ['MS Dhoni', 'Ruturaj Gaikwad', 'Devon Conway', 'Ravindra Jadeja', 'Deepak Chahar', 'Tushar Deshpande', 'Shivam Dube', 'Moeen Ali'],
  // Team 4 — Kolkata Riders
  ['Shreyas Iyer', 'Andre Russell', 'Sunil Narine', 'Venkatesh Iyer', 'Varun Chakravarthy', 'Rinku Singh', 'Nitish Rana', 'Tim Southee'],
  // Team 5 — Bangalore Stars
  ['Faf du Plessis', 'Glenn Maxwell', 'Dinesh Karthik', 'Wanindu Hasaranga', 'Mohammed Siraj', 'Harshal Patel', 'Shahbaz Ahmed', 'Josh Hazlewood'],
  // Team 6 — Hyderabad Sunrisers
  ['Aiden Markram', 'Heinrich Klaasen', 'Abhishek Sharma', 'Bhuvneshwar Kumar', 'Umran Malik', 'Washington Sundar', 'Rahul Tripathi', 'Marco Jansen'],
  // Team 7 — Rajasthan Royals
  ['Sanju Samson', 'Jos Buttler', 'Yashasvi Jaiswal', 'Ravichandran Ashwin', 'Trent Boult', 'Yuzvendra Chahal', 'Shimron Hetmyer', 'Prasidh Krishna'],
  // Team 8 — Punjab Kings
  ['Shikhar Dhawan', 'Liam Livingstone', 'Jonny Bairstow', 'Kagiso Rabada', 'Arshdeep Singh', 'Rahul Chahar', 'Shahrukh Khan', 'Sam Curran'],
  // Team 9 — Gujarat Titans
  ['Shubman Gill', 'David Miller', 'Wriddhiman Saha', 'Rashid Khan', 'Mohammed Shami', 'Alzarri Joseph', 'Rahul Tewatia', 'Vijay Shankar'],
  // Team 10 — Lucknow Giants
  ['KL Rahul', 'Quinton de Kock', 'Nicholas Pooran', 'Krunal Pandya', 'Avesh Khan', 'Ravi Bishnoi', 'Deepak Hooda', 'Mark Wood'],
  // Team 11 — Ahmedabad Warriors
  ['Ajinkya Rahane', 'Cheteshwar Pujara', 'Ravindra Jadeja B', 'Jaydev Unadkat', 'Prasidh Krishna B', 'Sai Kishore', 'Darshan Nalkande', 'Chetan Sakariya'],
  // Team 12 — Pune Strikers
  ['Mayank Agarwal', 'Devdutt Padikkal', 'Sarfaraz Khan', 'Shardul Thakur', 'Umesh Yadav', 'Kuldeep Sen', 'Rajat Patidar', 'Mukesh Kumar'],
  // Team 13 — Indore Rangers
  ['Ishan Porel', 'Priyam Garg', 'Riyan Parag', 'Kartik Tyagi', 'Akash Deep', 'Anmolpreet Singh', 'Tilak Varma B', 'Ravi Kumar'],
  // Team 14 — Jaipur Panthers
  ['Dhruv Jurel', 'Yash Dhull', 'Raj Bawa', 'Nishant Sindhu', 'Vicky Ostwal', 'Rajvardhan Hangargekar', 'Kaushal Tambe', 'Aneeshwar Gautam'],
  // Team 15 — Chandigarh Lions
  ['Abhishek Nayar', 'Mandeep Singh', 'Gurkeerat Mann', 'Sandeep Sharma', 'Siddharth Kaul', 'Manan Vohra', 'Anmol Malhotra', 'Prabhsimran Singh'],
  // Team 16 — Goa Challengers
  ['Amit Mishra', 'Snehal Kauthankar', 'Daryl Ferreira', 'Lakshay Garg', 'Arjun Azad', 'Vaibhav Suryavanshi', 'Swapnil Asnodkar', 'Shadab Jakati'],
];

const _teamNames = [
  'Mumbai Lions', 'Delhi Capitals', 'Chennai Kings', 'Kolkata Riders',
  'Bangalore Stars', 'Hyderabad Sunrisers', 'Rajasthan Royals', 'Punjab Kings',
  'Gujarat Titans', 'Lucknow Giants', 'Ahmedabad Warriors', 'Pune Strikers',
  'Indore Rangers', 'Jaipur Panthers', 'Chandigarh Lions', 'Goa Challengers',
];

/// Generates test data for tournament E2E tests.
class TournamentTestData {
  /// Generate 16 teams with 6 players each (matching playersPerSide=6).
  /// Uses realistic Indian cricket player names and IPL-style team names.
  static List<TeamData> generate16Teams() {
    return List.generate(16, (i) {
      final players = List.generate(6, (j) {
        return PlayerData(
          name: _playerNames[i][j],
          role: 'all_rounder', // Everyone can bat & bowl in 6-player format
        );
      });
      return TeamData(
        name: _teamNames[i],
        players: players,
      );
    });
  }

  /// Generate N teams with configurable player count.
  static List<TeamData> generateTeams(int count, {int playersPerTeam = 8}) {
    return List.generate(count, (i) {
      final players = List.generate(playersPerTeam, (j) {
        final name = i < _playerNames.length && j < _playerNames[i].length
            ? _playerNames[i][j]
            : 'Player ${i + 1}-${j + 1}';
        return PlayerData(
          name: name,
          role: 'all_rounder',
        );
      });
      return TeamData(
        name: i < _teamNames.length ? _teamNames[i] : 'Team${i + 1}',
        players: players,
      );
    });
  }

  /// Tournament config for MockTour: 16-team Group+Knockout.
  /// Uses timestamp suffix for unique name per test run.
  static TournamentConfig mockTour1Config() {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    return TournamentConfig(
      name: 'MockTour-$suffix',
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
