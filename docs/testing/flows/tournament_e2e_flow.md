# Tournament E2E Flow

Full UI navigation path for the 16-team Group+Knockout tournament E2E integration test.

## Overview

The `tournament_e2e_test.dart` executes a complete tournament through the Flutter UI:
- 16 teams (8 players each)
- Group+Knockout format (4 groups x 4 teams)
- 24 group matches + 2 semi-finals + 1 final = 27 matches
- 6 overs per innings, 6 players per side
- Magic Over on the 4th over (doubles all runs)
- Random seed 42 for deterministic reproducibility
- ~2-3 hours runtime on emulator with 300ms visual delays

## Prerequisites

1. Bun server running with `NODE_ENV=test` on port 3001
2. PostgreSQL database `cricapp_test_e2e` available
3. Android emulator connected
4. Run: `flutter test integration_test/tournament_e2e_test.dart -d emulator-5554`

## Phase-by-Phase Flow

### Phase 1: Launch App
- `AppTestWrapper.pumpApp(tester)` boots the full app with test overrides
- Debug mode skips auth, lands on Home page
- Verify: `find.text('Home')` visible

### Phase 2: Create 16 Teams
For each team (Team1-Team16):
1. Navigate: Home -> Teams tab (bottom nav)
2. Tap "Create Team" button (or FAB)
3. Enter team name in TextFormField
4. Tap "Create" to submit
5. For each of 8 players (T{n}P1 - T{n}P8):
   - Tap "Add Player"
   - Enter player name
   - Tap "Add"
6. Tap back arrow to return to teams list

### Phase 3: Create Tournament
1. Navigate: Home -> Tournaments tab (bottom nav)
2. Tap "Create Tournament" (or FAB)
3. Fill tournament name: "MockTour-1"
4. Select format: "Group + Knockout" chip
5. Select overs: "6" preset chip
6. Tap "Create Tournament" submit button
7. Wait 1000ms for creation

### Phase 4: Add Teams to Groups
From tournament detail page, for each group (A/B/C/D):
1. Tap "Add Team"
2. Select team name from list
3. Select group letter
4. Tap "Confirm"

Group assignments:
- Group A: Team1, Team2, Team3, Team4
- Group B: Team5, Team6, Team7, Team8
- Group C: Team9, Team10, Team11, Team12
- Group D: Team13, Team14, Team15, Team16

### Phase 5: Generate Fixtures
1. Tap "Generate Fixtures" on tournament detail
2. Wait 1000ms
3. Creates 24 group fixtures (C(4,2) = 6 per group x 4 groups)

### Phase 6: Play 24 Group Matches
For each fixture (round-robin within each group):
1. Score 1st innings via `playRandomInnings()` (see `match_scoring_flow.md`)
2. Complete innings transition (select openers + bowler)
3. Score 2nd innings
4. Dismiss match complete modal ("Back to Home")

### Phase 7: Verify Group Standings
1. Navigate to "Standings" tab
2. Verify data is displayed (UI check)
3. Optionally verify via DB test API

### Phase 8: Play 2 Semi-Finals
For each semi-final:
1. Navigate to knockout fixture
2. Score both innings (same flow as group matches)
3. Dismiss match complete modal

### Phase 9: Play Final
1. Navigate to final fixture
2. Score both innings
3. Dismiss match complete modal

### Phase 10: Verify Tournament Awards
1. Navigate to "Leaderboard" tab
2. Verify leaderboard page displays

### Phase 11: Log Results
- Print all match records with scores
- Print total matches played

## Configuring for Different Tournaments

### Fewer Teams
```dart
final teams = TournamentTestData.generateTeams(8, playersPerTeam: 8);
final config = TournamentConfig(
  name: 'SmallTour',
  format: 'group_knockout',
  overs: 6,
  playersPerSide: 6,
  numGroups: 2,
  qualifyPerGroup: 2,
);
final groupAssignments = {
  'A': [1, 2, 3, 4],
  'B': [5, 6, 7, 8],
};
```

### Knockout Only
```dart
final config = TournamentConfig(
  name: 'KnockoutTour',
  format: 'knockout',
  overs: 10,
  playersPerSide: 11,
  numGroups: 0,
  qualifyPerGroup: 0,
);
// Skip group assignments, go straight to knockout fixtures
```

### Round Robin Only
```dart
final config = TournamentConfig(
  name: 'LeagueTour',
  format: 'round_robin',
  overs: 20,
  playersPerSide: 11,
  numGroups: 1,
  qualifyPerGroup: 0,
);
```

## DB Verification (Optional)

When running with a real server, uncomment the DB verification block at the end of the test to verify:
- All deliveries match UI taps
- Match results are correctly stored
- Tournament standings are accurate
- Leaderboard aggregations are correct

See `test_infrastructure.md` for verification API details.
