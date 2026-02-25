# Tournament E2E Flow

Full UI navigation path for the tournament E2E integration tests.

## Overview

Three tournament tests (`04_tournament_gk_test.dart`, `05_tournament_ko_test.dart`, `06_tournament_rr_test.dart`) execute complete tournaments through the Flutter UI against the prod server (`cricscores.in`):

- **Test 04 (Group+Knockout):** 16 teams (4 groups × 4 teams), ~27 matches
- **Test 05 (Knockout):** 16 teams, single elimination, 15 matches
- **Test 06 (Round Robin):** Subset of teams, all-play-all format

All tests are prod-only, 100% UI-driven, with random scoring and `ErrorTracker` progress reporting.

## Prerequisites

1. Prod server running at `cricscores.in`
2. Android emulator connected
3. Teams already created via test 01 (`01_team_setup_test.dart`)
4. Run: `flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/04_tournament_gk_test.dart -d emulator-5554`

## Phase-by-Phase Flow

### Phase 1: Launch App
- `appBootstrap()` launches the app with prod flavor
- Firebase phone auth with test number `9999999999` (OTP: `123456`)
- Lands on Home page after successful auth

### Phase 2: Create Tournament
1. Navigate: Home -> Tournaments tab (bottom nav)
2. Tap "Create Tournament" (or FAB)
3. Fill tournament name (random name for idempotency)
4. Select format chip (Group+Knockout / Knockout / Round Robin)
5. Select overs preset chip
6. Configure group settings if applicable
7. Tap "Create Tournament" submit button

**Implementation:** `tournament_mgmt.dart:createTournament()`

### Phase 3: Open Registration + Add Teams
1. Tap ... menu -> "Open Registration"
2. For each team: Tap "Add Team" -> select group (if applicable) -> tap team name
3. All teams added via `tournament_mgmt.dart:addTeamToTournament()`

### Phase 4: Generate Fixtures + Start
1. Tap "Generate Fixtures" on Overview tab
2. Assert at least 1 `FixtureCard` exists on Fixtures tab
3. Tap ... menu -> "Start Tournament"

**Implementation:** `tournament_mgmt.dart:generateFixtures()`, `startTournament()`

### Phase 5: Score All Fixtures
`tournament_flow.dart:scoreAllFixtures()` orchestrates:
1. Switch to Fixtures tab, scan for unplayed FixtureCard via `fixture_scanning.dart`
2. Tap fixture -> match setup -> toss wizard (`match_setup.dart`)
3. Score 1st innings via `playRandomInnings()` (`random_innings.dart`)
4. Complete innings transition — select openers + bowler (`modals.dart`)
5. Score 2nd innings
6. Dismiss MatchCompleteModal
7. Navigate back to tournament fixtures tab
8. Repeat until no unplayed fixtures remain
9. **Assert:** zero unplayed fixtures at completion

### Phase 6: Verification (Test 07)
Test 07 (`07_verify_all_screens_test.dart`) navigates to tournament detail and verifies:
- Standings tab shows data (`tournament_verifier.dart`)
- Fixtures tab shows completed fixtures
- Team detail pages show roster and match data (`team_detail_verifier.dart`)

## Key Helper Files

| File | Purpose |
|------|---------|
| `flows/tournament_flow.dart` | `scoreAllFixtures()` — scan + score all unplayed fixtures |
| `flows/random_innings.dart` | `playRandomInnings()` — weighted random delivery generation |
| `helpers/tournament_mgmt.dart` | `createTournament()`, `addTeamToTournament()`, `generateFixtures()` |
| `helpers/fixture_scanning.dart` | Find and tap FixtureCard widgets |
| `helpers/match_setup.dart` | Match setup + 5-step toss wizard |
| `helpers/modals.dart` | Dismiss completion/transition modals |
| `helpers/navigation.dart` | Tab switching, `switchToTab()` |
| `helpers/scoring.dart` | Tap scoring controls |
| `core/error_tracker.dart` | Step-by-step progress tracking |
| `config/tournament_presets.dart` | Tournament format configurations |

## Configuring for Different Tournaments

Tournament presets are defined in `config/tournament_presets.dart`. Each test file selects a preset and passes it to the tournament flow helpers. To add a new tournament configuration, add a preset and create a new test file following the `04-06` pattern.
