/// Cumulative batting/bowling stat tracking for player profile verification.
///
/// Stub for now — Player Profile page is "Coming Soon".
/// Infrastructure ready for when it ships.
library;

/// Tracks cumulative batting stats across matches.
class BattingStats {
  int matches = 0;
  int innings = 0;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int notOuts = 0;
  int highScore = 0;

  double get average => innings - notOuts > 0 ? runs / (innings - notOuts) : 0;
  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0;
}

/// Tracks cumulative bowling stats across matches.
class BowlingStats {
  int matches = 0;
  int innings = 0;
  int wickets = 0;
  int runsConceded = 0;
  int ballsBowled = 0;
  int maidens = 0;
  int bestWickets = 0;
  int bestRuns = 0;

  double get average => wickets > 0 ? runsConceded / wickets : 0;
  double get economy => ballsBowled > 0 ? (runsConceded / ballsBowled) * 6 : 0;
}
