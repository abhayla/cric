# E2E Test Implementation Prompt: Category B & C (Scoring Flow & Extras)

Please implement integration tests for **Categories B and C: Scenarios 23-25, 27-29** from `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`.

## Context

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

## Current Architecture

- **Helpers:** `helpers/scoring.dart` (tap runs, extras, wickets), `helpers/modals.dart` (dismiss modals), `helpers/match_setup.dart` (toss wizard)
- **Flows:** `flows/standalone_match_flow.dart` (full match lifecycle)
- **Core:** `core/app_bootstrap.dart` (app launch + Firebase auth), `core/test_utils.dart` (`waitForFinder()`, `settle()`)

## Scenarios to Implement

Create a new test file in `integration_test/tests/` (e.g., `09_scoring_extras_flow_test.dart`).

1. **Scenario 23:** Bye and Leg-Bye Scoring (Runs to team, not batter; Odd runs swap strike).
2. **Scenario 24:** Wicket on a No-Ball (Run Out) (Verify free hit still triggers).
3. **Scenario 25:** Wicket on a Free Hit (Run Out) (Verify only run out is available/recorded).
4. **Scenario 27:** Bowler Eligibility Enforcement (Attempt selecting same bowler or max-overs bowler gets blocked).
5. **Scenario 28:** Strike Rotation Correctness (Track strike swaps on 1/2/3 runs and over boundaries).
6. **Scenario 29:** Bowl-First Toss Choice (Team A wins toss, chooses to field → verify Team B bats first).

## Instructions

1. Review existing helpers in `helpers/scoring.dart` and `helpers/match_setup.dart` for UI interaction patterns.
2. Use `app_bootstrap.dart` to launch the app with Firebase auth. Reuse teams from test 01.
3. All interactions must go through the real UI — use the scoring helpers for taps.
4. For bowl-first scenario (29), modify toss wizard helper to choose "Field" instead of "Bat".
5. Verify results via the UI (striker name changes, bowler eligibility indicators, innings team assignment).
