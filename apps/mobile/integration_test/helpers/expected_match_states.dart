// ignore_for_file: avoid_print

library;

/// Pre-computed expected LiveMatchState snapshots for the predetermined
/// scoring sequence used in single_match_e2e_test.dart.
///
/// Each [ExpectedLiveState] represents the state the viewer should see
/// after a WebSocket update from the server for a given delivery.
///
/// Match: Mumbai Lions vs Chennai Kings, 5 overs, 6 players per side.
/// 1st Innings: Mumbai Lions bat — ALL OUT 20/5 in 2.0 overs.
/// 2nd Innings: Chennai Kings chase 21 — 22/0 in 0.4 overs.
/// Result: Chennai Kings won by 5 wickets.

class ExpectedLiveState {
  const ExpectedLiveState({
    required this.deliveryIndex,
    required this.description,
    required this.inningsNumber,
    required this.totalRuns,
    required this.totalWickets,
    required this.oversDisplay,
    this.strikerName,
    this.strikerRuns,
    this.strikerBalls,
    this.strikerFours,
    this.strikerSixes,
    this.nonStrikerName,
    this.nonStrikerRuns,
    this.nonStrikerBalls,
    this.bowlerName,
    this.bowlerOvers,
    this.bowlerMaidens,
    this.bowlerRuns,
    this.bowlerWickets,
    this.target,
    this.requiredRunRate,
    this.isInningsComplete = false,
    this.isMatchComplete = false,
    this.matchResultSummary,
  });

  final int deliveryIndex;
  final String description;
  final int inningsNumber;
  final int totalRuns;
  final int totalWickets;
  final String oversDisplay;

  // Striker
  final String? strikerName;
  final int? strikerRuns;
  final int? strikerBalls;
  final int? strikerFours;
  final int? strikerSixes;

  // Non-striker
  final String? nonStrikerName;
  final int? nonStrikerRuns;
  final int? nonStrikerBalls;

  // Bowler
  final String? bowlerName;
  final String? bowlerOvers;
  final int? bowlerMaidens;
  final int? bowlerRuns;
  final int? bowlerWickets;

  // 2nd innings chase info
  final int? target;
  final double? requiredRunRate;

  // Terminal events
  final bool isInningsComplete;
  final bool isMatchComplete;
  final String? matchResultSummary;

  @override
  String toString() =>
      '#$deliveryIndex Inn$inningsNumber $totalRuns/$totalWickets ($oversDisplay) $description';
}

/// All expected states for the predetermined match.
///
/// Note: The viewer receives score_update messages for each delivery,
/// plus innings_complete and match_complete messages at transitions.
/// Not every field is guaranteed to match exactly (e.g., run rates are
/// approximate), so the verification focuses on core fields:
/// totalRuns, totalWickets, oversDisplay, inningsNumber, and player names.
const List<ExpectedLiveState> expectedMatchStates = [
  // ═══════════════════════════════════════════════════════════════
  // 1ST INNINGS — Mumbai Lions batting
  // Over 1: Bowler = Deepak Chahar
  // ═══════════════════════════════════════════════════════════════

  // #1: Over 1, Ball 1 — Rohit Sharma hits 4 (boundary)
  ExpectedLiveState(
    deliveryIndex: 1,
    description: '1.1 Rohit Sharma — 4 (boundary)',
    inningsNumber: 1,
    totalRuns: 4,
    totalWickets: 0,
    oversDisplay: '0.1',
    strikerName: 'Rohit Sharma',
    strikerRuns: 4,
    strikerBalls: 1,
    strikerFours: 1,
    strikerSixes: 0,
    nonStrikerName: 'Suryakumar Yadav',
    nonStrikerRuns: 0,
    nonStrikerBalls: 0,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.1',
    bowlerRuns: 4,
    bowlerWickets: 0,
  ),

  // #2: Over 1, Ball 2 — Rohit Sharma hits 6
  ExpectedLiveState(
    deliveryIndex: 2,
    description: '1.2 Rohit Sharma — 6 (six)',
    inningsNumber: 1,
    totalRuns: 10,
    totalWickets: 0,
    oversDisplay: '0.2',
    strikerName: 'Rohit Sharma',
    strikerRuns: 10,
    strikerBalls: 2,
    strikerFours: 1,
    strikerSixes: 1,
    nonStrikerName: 'Suryakumar Yadav',
    nonStrikerRuns: 0,
    nonStrikerBalls: 0,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.2',
    bowlerRuns: 10,
    bowlerWickets: 0,
  ),

  // #3: Over 1, Ball 3 — Rohit Sharma OUT (Bowled)
  // New batter: Ishan Kishan takes striker end
  ExpectedLiveState(
    deliveryIndex: 3,
    description: '1.3 Rohit Sharma — W (Bowled)',
    inningsNumber: 1,
    totalRuns: 10,
    totalWickets: 1,
    oversDisplay: '0.3',
    strikerName: 'Ishan Kishan',
    strikerRuns: 0,
    strikerBalls: 0,
    strikerFours: 0,
    strikerSixes: 0,
    nonStrikerName: 'Suryakumar Yadav',
    nonStrikerRuns: 0,
    nonStrikerBalls: 0,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.3',
    bowlerRuns: 10,
    bowlerWickets: 1,
  ),

  // #4: Over 1, Wide — +1 run, not legal
  ExpectedLiveState(
    deliveryIndex: 4,
    description: '1.WD Wide +1',
    inningsNumber: 1,
    totalRuns: 11,
    totalWickets: 1,
    oversDisplay: '0.3',
    strikerName: 'Ishan Kishan',
    strikerRuns: 0,
    strikerBalls: 0,
    nonStrikerName: 'Suryakumar Yadav',
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.3',
    bowlerRuns: 11,
    bowlerWickets: 1,
  ),

  // #5: Over 1, No-ball — +1 run, not legal, free hit next
  ExpectedLiveState(
    deliveryIndex: 5,
    description: '1.NB No-ball +1',
    inningsNumber: 1,
    totalRuns: 12,
    totalWickets: 1,
    oversDisplay: '0.3',
    strikerName: 'Ishan Kishan',
    strikerRuns: 0,
    strikerBalls: 0,
    nonStrikerName: 'Suryakumar Yadav',
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.3',
    bowlerRuns: 12,
    bowlerWickets: 1,
  ),

  // #6: Over 1, Ball 4 — Ishan Kishan 1 run (free hit), swap strike
  ExpectedLiveState(
    deliveryIndex: 6,
    description: '1.4 Ishan Kishan — 1 (free hit)',
    inningsNumber: 1,
    totalRuns: 13,
    totalWickets: 1,
    oversDisplay: '0.4',
    strikerName: 'Suryakumar Yadav',
    strikerRuns: 0,
    strikerBalls: 0,
    nonStrikerName: 'Ishan Kishan',
    nonStrikerRuns: 1,
    nonStrikerBalls: 1,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.4',
    bowlerRuns: 13,
    bowlerWickets: 1,
  ),

  // #7: Over 1, Ball 5 — Suryakumar Yadav OUT (Bowled)
  // New batter: Hardik Pandya
  ExpectedLiveState(
    deliveryIndex: 7,
    description: '1.5 Suryakumar Yadav — W (Bowled)',
    inningsNumber: 1,
    totalRuns: 13,
    totalWickets: 2,
    oversDisplay: '0.5',
    strikerName: 'Hardik Pandya',
    strikerRuns: 0,
    strikerBalls: 0,
    strikerFours: 0,
    strikerSixes: 0,
    nonStrikerName: 'Ishan Kishan',
    nonStrikerRuns: 1,
    nonStrikerBalls: 1,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '0.5',
    bowlerRuns: 13,
    bowlerWickets: 2,
  ),

  // #8: Over 1, Ball 6 — Hardik Pandya hits 4 (boundary)
  // End of over → strike swaps → Ishan Kishan striker next over
  ExpectedLiveState(
    deliveryIndex: 8,
    description: '1.6 Hardik Pandya — 4 (boundary)',
    inningsNumber: 1,
    totalRuns: 17,
    totalWickets: 2,
    oversDisplay: '1.0',
    // After end-of-over swap: Ishan = striker, Hardik = non-striker
    strikerName: 'Ishan Kishan',
    strikerRuns: 1,
    strikerBalls: 1,
    nonStrikerName: 'Hardik Pandya',
    nonStrikerRuns: 4,
    nonStrikerBalls: 1,
    bowlerName: 'Deepak Chahar',
    bowlerOvers: '1.0',
    bowlerRuns: 17,
    bowlerWickets: 2,
  ),

  // ═══════════════════════════════════════════════════════════════
  // Over 2: Bowler = Ravindra Jadeja
  // ═══════════════════════════════════════════════════════════════

  // #9: Over 2, Ball 1 — Ishan Kishan 2 runs
  ExpectedLiveState(
    deliveryIndex: 9,
    description: '2.1 Ishan Kishan — 2',
    inningsNumber: 1,
    totalRuns: 19,
    totalWickets: 2,
    oversDisplay: '1.1',
    strikerName: 'Ishan Kishan',
    strikerRuns: 3,
    strikerBalls: 2,
    nonStrikerName: 'Hardik Pandya',
    nonStrikerRuns: 4,
    nonStrikerBalls: 1,
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '0.1',
    bowlerRuns: 2,
    bowlerWickets: 0,
  ),

  // #10: Over 2, Ball 2 — Ishan Kishan OUT (Bowled)
  // New batter: Jasprit Bumrah
  ExpectedLiveState(
    deliveryIndex: 10,
    description: '2.2 Ishan Kishan — W (Bowled)',
    inningsNumber: 1,
    totalRuns: 19,
    totalWickets: 3,
    oversDisplay: '1.2',
    strikerName: 'Jasprit Bumrah',
    strikerRuns: 0,
    strikerBalls: 0,
    nonStrikerName: 'Hardik Pandya',
    nonStrikerRuns: 4,
    nonStrikerBalls: 1,
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '0.2',
    bowlerRuns: 2,
    bowlerWickets: 1,
  ),

  // #11: Over 2, Ball 3 — Jasprit Bumrah dot ball
  ExpectedLiveState(
    deliveryIndex: 11,
    description: '2.3 Jasprit Bumrah — 0 (dot)',
    inningsNumber: 1,
    totalRuns: 19,
    totalWickets: 3,
    oversDisplay: '1.3',
    strikerName: 'Jasprit Bumrah',
    strikerRuns: 0,
    strikerBalls: 1,
    nonStrikerName: 'Hardik Pandya',
    nonStrikerRuns: 4,
    nonStrikerBalls: 1,
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '0.3',
    bowlerRuns: 2,
    bowlerWickets: 1,
  ),

  // #12: Over 2, Ball 4 — Jasprit Bumrah OUT (Bowled)
  // New batter: Rahul Chahar
  ExpectedLiveState(
    deliveryIndex: 12,
    description: '2.4 Jasprit Bumrah — W (Bowled)',
    inningsNumber: 1,
    totalRuns: 19,
    totalWickets: 4,
    oversDisplay: '1.4',
    strikerName: 'Rahul Chahar',
    strikerRuns: 0,
    strikerBalls: 0,
    nonStrikerName: 'Hardik Pandya',
    nonStrikerRuns: 4,
    nonStrikerBalls: 1,
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '0.4',
    bowlerRuns: 2,
    bowlerWickets: 2,
  ),

  // #13: Over 2, Ball 5 — Rahul Chahar 1 run, swap strike
  ExpectedLiveState(
    deliveryIndex: 13,
    description: '2.5 Rahul Chahar — 1 (swap)',
    inningsNumber: 1,
    totalRuns: 20,
    totalWickets: 4,
    oversDisplay: '1.5',
    strikerName: 'Hardik Pandya',
    strikerRuns: 4,
    strikerBalls: 1,
    nonStrikerName: 'Rahul Chahar',
    nonStrikerRuns: 1,
    nonStrikerBalls: 1,
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '0.5',
    bowlerRuns: 3,
    bowlerWickets: 2,
  ),

  // #14: Over 2, Ball 6 — Hardik Pandya OUT (Bowled) → ALL OUT
  // This is the 5th wicket = all out (6 players per side)
  ExpectedLiveState(
    deliveryIndex: 14,
    description: '2.6 Hardik Pandya — W (Bowled) ALL OUT',
    inningsNumber: 1,
    totalRuns: 20,
    totalWickets: 5,
    oversDisplay: '2.0',
    // After all-out, striker/non-striker may be null
    bowlerName: 'Ravindra Jadeja',
    bowlerOvers: '1.0',
    bowlerRuns: 3,
    bowlerWickets: 3,
    isInningsComplete: true,
  ),

  // ═══════════════════════════════════════════════════════════════
  // 2ND INNINGS — Chennai Kings batting, chasing 21
  // Over 1: Bowler = Rohit Sharma
  // ═══════════════════════════════════════════════════════════════

  // #15: Over 1, Ball 1 — MS Dhoni hits 6
  ExpectedLiveState(
    deliveryIndex: 15,
    description: '1.1 MS Dhoni — 6 (six)',
    inningsNumber: 2,
    totalRuns: 6,
    totalWickets: 0,
    oversDisplay: '0.1',
    strikerName: 'MS Dhoni',
    strikerRuns: 6,
    strikerBalls: 1,
    strikerFours: 0,
    strikerSixes: 1,
    nonStrikerName: 'Ruturaj Gaikwad',
    nonStrikerRuns: 0,
    nonStrikerBalls: 0,
    bowlerName: 'Rohit Sharma',
    bowlerOvers: '0.1',
    bowlerRuns: 6,
    bowlerWickets: 0,
    target: 21,
  ),

  // #16: Over 1, Ball 2 — MS Dhoni hits 6
  ExpectedLiveState(
    deliveryIndex: 16,
    description: '1.2 MS Dhoni — 6 (six)',
    inningsNumber: 2,
    totalRuns: 12,
    totalWickets: 0,
    oversDisplay: '0.2',
    strikerName: 'MS Dhoni',
    strikerRuns: 12,
    strikerBalls: 2,
    strikerFours: 0,
    strikerSixes: 2,
    nonStrikerName: 'Ruturaj Gaikwad',
    bowlerName: 'Rohit Sharma',
    bowlerOvers: '0.2',
    bowlerRuns: 12,
    bowlerWickets: 0,
    target: 21,
  ),

  // #17: Over 1, Ball 3 — MS Dhoni hits 4 (boundary)
  ExpectedLiveState(
    deliveryIndex: 17,
    description: '1.3 MS Dhoni — 4 (boundary)',
    inningsNumber: 2,
    totalRuns: 16,
    totalWickets: 0,
    oversDisplay: '0.3',
    strikerName: 'MS Dhoni',
    strikerRuns: 16,
    strikerBalls: 3,
    strikerFours: 1,
    strikerSixes: 2,
    nonStrikerName: 'Ruturaj Gaikwad',
    bowlerName: 'Rohit Sharma',
    bowlerOvers: '0.3',
    bowlerRuns: 16,
    bowlerWickets: 0,
    target: 21,
  ),

  // #18: Over 1, Ball 4 — MS Dhoni hits 6 → 22/0 ≥ 21 → MATCH COMPLETE
  ExpectedLiveState(
    deliveryIndex: 18,
    description: '1.4 MS Dhoni — 6 (six) TARGET CHASED',
    inningsNumber: 2,
    totalRuns: 22,
    totalWickets: 0,
    oversDisplay: '0.4',
    strikerName: 'MS Dhoni',
    strikerRuns: 22,
    strikerBalls: 4,
    strikerFours: 1,
    strikerSixes: 3,
    nonStrikerName: 'Ruturaj Gaikwad',
    bowlerName: 'Rohit Sharma',
    bowlerOvers: '0.4',
    bowlerRuns: 22,
    bowlerWickets: 0,
    target: 21,
    isMatchComplete: true,
    matchResultSummary: 'Chennai Kings won by 5 wickets',
  ),
];

/// Key checkpoint indices for detailed verification.
/// These are the delivery indices where extra-thorough checking is warranted.
const List<int> keyCheckpoints = [
  1, // First delivery
  3, // First wicket
  5, // No-ball (free hit)
  8, // End of over 1
  14, // All out (innings complete)
  15, // First delivery of 2nd innings
  18, // Match complete
];
