/// Cricket domain constants.
///
/// Single source of truth for cricket values used across the app.
/// Master data (dismissal types, fielding positions, wagon wheel zones)
/// is fetched from the server and cached locally.
abstract final class CricketConstants {
  /// Default players per side.
  static const int defaultPlayersPerSide = 11;

  /// Maximum players per side.
  static const int maxPlayersPerSide = 11;

  /// Minimum players per side.
  static const int minPlayersPerSide = 2;

  /// Legal deliveries per over.
  static const int ballsPerOver = 6;

  /// Maximum overs for any match.
  static const int maxOvers = 50;

  /// Minimum overs for any match.
  static const int minOvers = 1;

  /// Default wide penalty runs.
  static const int defaultWideRuns = 1;

  /// Default no-ball penalty runs.
  static const int defaultNoBallRuns = 1;

  /// Maximum roster size per team.
  static const int maxRosterSize = 25;
}
