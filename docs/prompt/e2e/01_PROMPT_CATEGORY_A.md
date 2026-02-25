# E2E Test Implementation Prompt: Category A (Scoring Edge Cases)

Please implement integration tests for **Category A (Scoring Edge Cases): Scenarios 1-11** from `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`.

## Context

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

## Current Architecture

- **Helpers:** `helpers/scoring.dart` (tap runs, extras, wickets), `helpers/modals.dart` (dismiss modals), `helpers/match_setup.dart` (toss wizard)
- **Flows:** `flows/random_innings.dart` (`playRandomInnings()`), `flows/standalone_match_flow.dart` (full match lifecycle)
- **Core:** `core/app_bootstrap.dart` (app launch + Firebase auth), `core/test_utils.dart` (`waitForFinder()`, `settle()`), `core/error_tracker.dart`
- **Models:** `models/delivery_record.dart` (delivery tracking)

## Scenarios to Implement

Create new test files in `integration_test/tests/` following the existing naming pattern (e.g., `09_scoring_edge_cases_a_test.dart`). Each scenario should score specific delivery sequences through the UI to exercise edge cases.

1. **Scenario 1:** Five Wickets in One Over (Rapid new-batter selection, 5W for bowler).
2. **Scenario 2:** Wide + No-Ball Chain (Over doesn't end until 6 legal deliveries).
3. **Scenario 3:** Target Chased Off a Wide (Match ends immediately).
4. **Scenario 4:** Target Chased Off a No-Ball (Match ends immediately).
5. **Scenario 5:** All Out for 0 (10 consecutive wickets).
6. **Scenario 6:** Last Ball Six to Win (Target chased exactly on last ball).
7. **Scenario 7:** Tied Match (Equal scores).
8. **Scenario 8:** Undo After Over Transition (Restores previous over and bowler).
9. **Scenario 9:** Undo After Innings Transition (Should be blocked).
10. **Scenario 10:** Abandon Mid-Match (Abandon from menu).
11. **Scenario 11:** Maiden Over (6 dots).

## Instructions

1. Review existing test files (`02_standalone_match_test.dart`) and helpers (`helpers/scoring.dart`, `helpers/match_setup.dart`) to understand the current UI interaction patterns.
2. Use `app_bootstrap.dart` to launch the app with Firebase auth. Use existing teams from test 01.
3. All scoring must go through the real UI — use `tapRun()`, `tapWicket()`, `tapExtra()` helpers from `helpers/scoring.dart`.
4. Verify results via the UI (scorecard page, match complete modal text) — no direct API/DB verification calls.
5. Follow the pattern: create match → toss → score predetermined deliveries → verify UI state.
