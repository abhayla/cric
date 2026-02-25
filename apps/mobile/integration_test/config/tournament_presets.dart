/// Tournament configuration presets for different test scenarios.
library;

import 'dart:math';

/// Tournament configuration for test setup.
class TournamentPreset {
  const TournamentPreset({
    required this.format,
    required this.overs,
    this.playersPerSide = 6,
    this.ballTypeId = 2,
    this.numGroups = 1,
    this.qualifyPerGroup = 2,
    this.magicOverNumber,
  });

  final String format; // 'group_knockout', 'knockout', 'round_robin'
  final int overs;
  final int playersPerSide;
  final int ballTypeId; // 1=Leather, 2=Tennis, 3=Tape, 4=Other
  final int numGroups;
  final int qualifyPerGroup;
  final int? magicOverNumber;

  /// Generate a unique tournament name with this preset's format.
  String generateName() {
    final suffix = Random().nextInt(99999);
    final label = switch (format) {
      'group_knockout' => 'GK',
      'knockout' => 'KO',
      'round_robin' => 'RR',
      _ => 'T',
    };
    return '$label-Tournament-$suffix';
  }
}

/// Group + Knockout: 8 teams, 2 groups of 4, top 2 qualify, 3 overs.
/// ~15 matches (12 group + 2 semi + 1 final).
const gkPreset = TournamentPreset(
  format: 'group_knockout',
  overs: 3,
  playersPerSide: 6,
  ballTypeId: 2,
  numGroups: 2,
  qualifyPerGroup: 2,
);

/// Group assignments for GK preset: 2 groups x 4 teams.
const Map<String, List<int>> gkGroupAssignments = {
  'A': [0, 1, 2, 3], // Team1-Team4
  'B': [4, 5, 6, 7], // Team5-Team8
};

/// Pure Knockout: 8 teams, 3 overs, 7 matches.
const koPreset = TournamentPreset(
  format: 'knockout',
  overs: 3,
  playersPerSide: 6,
  ballTypeId: 2,
);

/// Round Robin: 4 teams, 3 overs, 6 matches.
const rrPreset = TournamentPreset(
  format: 'round_robin',
  overs: 3,
  playersPerSide: 6,
  ballTypeId: 2,
);
