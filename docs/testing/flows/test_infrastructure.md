# Test Infrastructure

Layered architecture for the integration/E2E test suite. All tests are **prod-only** (run against `cricscores.in`), **100% UI-driven** (zero API calls), **idempotent** (each run creates fresh data), and **ordered** (tests 01-08 run sequentially).

## Directory Structure

```
integration_test/
├── config/                          # Test configuration
│   ├── constants.dart               # Timeouts, retry counts, device IDs
│   ├── test_data.dart               # Team/player names, phone numbers
│   └── tournament_presets.dart      # Tournament format configurations
├── core/                            # Shared infrastructure
│   ├── app_bootstrap.dart           # App launch + Firebase auth + flavor setup
│   ├── error_tracker.dart           # Step-by-step error tracking + resume support
│   ├── stat_tracker.dart            # Per-match stat accumulation
│   └── test_utils.dart              # waitForFinder(), waitForFinderGone(), testLog(), settle()
├── flows/                           # High-level test flows (orchestrators)
│   ├── random_innings.dart          # playRandomInnings() — weighted random delivery generation
│   ├── standalone_match_flow.dart   # Full standalone match lifecycle (setup → toss → score → complete)
│   ├── team_setup_flow.dart         # Create N teams with M players each via UI
│   └── tournament_flow.dart         # scoreAllFixtures() — scan + score all unplayed fixtures
├── helpers/                         # Low-level UI interaction helpers
│   ├── fixture_scanning.dart        # Find and tap FixtureCard widgets
│   ├── forms.dart                   # Fill text fields, create teams/players via forms
│   ├── match_setup.dart             # Match setup page + 5-step toss wizard
│   ├── modals.dart                  # Dismiss MatchCompleteModal, InningsTransitionModal
│   ├── navigation.dart              # Tab switching, bottom nav, back navigation, switchToTab()
│   ├── scoring.dart                 # Tap run buttons, extras, wickets in ScoringControls
│   └── tournament_mgmt.dart         # Create tournament, open registration, add teams, generate fixtures
├── models/                          # Data classes for test tracking
│   ├── delivery_record.dart         # DeliveryRecord — tracks each UI tap
│   ├── match_outcome.dart           # MatchOutcome — result text + teams
│   └── player_stats.dart            # PlayerStats — accumulated batting/bowling
├── tests/                           # Test files (ordered 01-08)
│   ├── 01_team_setup_test.dart      # Create 16 teams × 6 players
│   ├── 02_standalone_match_test.dart # Standalone match: undo, target chase, persistence
│   ├── 03_verify_after_match_test.dart # Verify match data on My Cricket, scorecard, player profile
│   ├── 04_tournament_gk_test.dart   # Group+Knockout tournament (4 groups × 4 teams)
│   ├── 05_tournament_ko_test.dart   # Knockout tournament (16 teams, single elimination)
│   ├── 06_tournament_rr_test.dart   # Round Robin tournament (subset of teams)
│   ├── 07_verify_all_screens_test.dart # Navigate all screens, verify data populated
│   └── 08_viewer_live_test.dart     # Multi-device WebSocket live scoring test
└── verification/                    # Screen-specific assertion helpers
    ├── live_verifier.dart           # Verify live match WebSocket data on viewer
    ├── my_cricket_verifier.dart     # Verify My Cricket tab (matches, teams, stats)
    ├── player_profile_verifier.dart # Verify player profile page stats
    ├── team_detail_verifier.dart    # Verify team detail page (roster, matches)
    ├── tournament_verifier.dart     # Verify tournament detail (standings, fixtures, leaderboard)
    └── updates_verifier.dart        # Verify Updates/activity feed
```

**34 files across 7 directories.**

## Design Principles

1. **Prod-only:** All tests run with `--flavor prod --dart-define=FLAVOR=prod` against the production server at `cricscores.in`. No local test server, no `NODE_ENV=test`, no test-only API endpoints.

2. **100% UI-driven:** Every action goes through the real Flutter UI — team creation, player addition, tournament setup, scoring, navigation. Zero API shortcuts.

3. **Idempotent:** Each test run creates fresh data (teams with timestamp suffixes, tournaments with random names). No cleanup or reset required.

4. **Ordered execution:** Tests are numbered 01-08 and must run sequentially. Later tests depend on data created by earlier tests (e.g., test 02 uses teams from test 01).

5. **Error tracking with resume:** `ErrorTracker` logs every step. On failure, prints exactly where it stopped. Tests can be re-run — they create new data rather than conflicting with previous runs.

## Core Utilities

### `app_bootstrap.dart`
Launches the Flutter app in prod mode with Firebase phone OTP auth (test phone `9999999999`, OTP `123456`). Handles the full login flow through the real Firebase Auth UI.

### `test_utils.dart`
- `waitForFinder(finder, {timeout})` — Polls until a widget appears (replaces hand-rolled retry loops)
- `waitForFinderGone(finder, {timeout})` — Polls until a widget disappears
- `testLog(message)` — Conditional logging controlled by `verboseTestOutput` flag
- `settle(tester)` — `pumpAndSettle` with timeout handling

### `error_tracker.dart`
Tracks test progress step-by-step. Each step is logged with description. On first error: stops execution, prints summary showing all completed steps and the failure point. Supports `startFromTeam`/`startFromMatch` for partial resume.

## Test Ordering

| # | Test | What It Does | Depends On |
|---|------|-------------|------------|
| 01 | `01_team_setup_test.dart` | Create 16 teams × 6 players via UI | Nothing |
| 02 | `02_standalone_match_test.dart` | Standalone match with undo + target chase | Teams from 01 |
| 03 | `03_verify_after_match_test.dart` | Verify My Cricket, scorecard, player profile | Match from 02 |
| 04 | `04_tournament_gk_test.dart` | Group+Knockout tournament (all 16 teams) | Teams from 01 |
| 05 | `05_tournament_ko_test.dart` | Knockout tournament (16 teams) | Teams from 01 |
| 06 | `06_tournament_rr_test.dart` | Round Robin tournament | Teams from 01 |
| 07 | `07_verify_all_screens_test.dart` | Navigate + verify all app screens | Data from 01-06 |
| 08 | `08_viewer_live_test.dart` | Multi-device WebSocket live test | Teams from 01 |

## Run Commands

```bash
# Single test
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554

# All tests in order (run manually one by one — no test runner for ordered execution)
cd apps/mobile
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/01_team_setup_test.dart -d emulator-5554
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554
# ... and so on through 08
```

## Key Flows

### Team Setup (`team_setup_flow.dart`)
Creates N teams with M players each through the UI. For each team: navigates to Teams tab → taps Create Team → fills name → for each player: taps Add Player → fills name + phone → confirms. Asserts player count text after each team.

### Standalone Match (`standalone_match_flow.dart`)
Full match lifecycle: navigate to match creation → fill setup form → complete 5-step toss wizard → score both innings via `playRandomInnings()` → dismiss match complete modal.

### Tournament (`tournament_flow.dart` + `tournament_mgmt.dart`)
- `tournament_mgmt.dart`: Low-level helpers — `createTournament()`, `openRegistration()`, `addTeamToTournament()`, `generateFixtures()`, `startTournament()`
- `tournament_flow.dart`: High-level orchestrator — `scoreAllFixtures()` scans FixtureCard widgets, taps unplayed fixtures, scores each match, repeats until no unplayed fixtures remain. Asserts zero unplayed fixtures at completion.

### Random Innings (`random_innings.dart`)
`playRandomInnings()` generates weighted random deliveries (30% dot, 25% single, 15% double, 10% four, 5% six, 5% wicket, 3% wide, 2% no-ball). Handles bowler rotation, new batter selection, over completion, and innings/match completion detection.
