# E2E Test Implementation Prompt: Category H (Player Profile & Stat Accumulation)

Please implement or extend integration tests for **Category H: Scenarios 35-36** from `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`.

## Context

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

## Current Coverage

Test `03_verify_after_match_test.dart` verifies player profiles loosely after a standalone match. Test `07_verify_all_screens_test.dart` navigates to player profiles. Neither test verifies exact stat accumulation across multiple matches.

## Scenarios to Implement

1. **Scenario 35:** Same Player Stats Accumulate Across Matches.
   - Score specific deliveries for a player across two matches (e.g., exactly 50 in Match 1 (out) and 30 in Match 2 (out)).
   - Verify via player profile page: Career Batting Average = 40.0, Total Runs = 80.
2. **Scenario 36:** Bowler Stats Across Matches.
   - Score specific bowler figures across two matches (e.g., 3/25 in Match 1 and 2/30 in Match 2).
   - Verify via player profile page: Career Wickets = 5, Runs Conceded = 55.

## Current Architecture

- **Helpers:** `helpers/scoring.dart` (tap runs, extras, wickets), `helpers/match_setup.dart` (toss wizard)
- **Flows:** `flows/standalone_match_flow.dart` (full match lifecycle), `flows/random_innings.dart` (`playRandomInnings()`)
- **Verification:** `verification/player_profile_verifier.dart` (player profile assertions)
- **Core:** `core/app_bootstrap.dart` (app launch + Firebase auth), `core/test_utils.dart` (`waitForFinder()`)

## Instructions

1. Create a new test file (e.g., `integration_test/tests/09_player_stat_accumulation_test.dart`).
2. Replace random scoring with deterministic delivery sequences that produce exact known values for specific batters and bowlers.
3. Assert specific mathematical totals via the player profile page UI (career runs, average, wickets).
4. Use `player_profile_verifier.dart` for structured assertions.
