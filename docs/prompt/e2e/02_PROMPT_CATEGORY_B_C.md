# E2E Test Implementation Prompt: Category B & C (Scoring Flow & Extras)

Please implement an integration test file in Flutter at `apps/mobile/integration_test/scoring_category_b_c_e2e_test.dart` and its corresponding documentation prompt `docs/prompt/e2e/SCORING_CATEGORY_B_C_E2E.md`.

## Context
We are implementing comprehensive E2E test scenarios as outlined in `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`. This task focuses on **Categories B and C: Scenarios 23-25, 27-29**.

## Scenarios to Implement
Create a single group "Category B & C: Flow and Extras" with sequential tests or individual sub-tests.

1. **Scenario 23:** Bye and Leg-Bye Scoring (Runs to team, not batter; Odd runs swap strike).
2. **Scenario 24:** Wicket on a No-Ball (Run Out) (Verify free hit still triggers).
3. **Scenario 25:** Wicket on a Free Hit (Run Out) (Verify only run out is available/recorded).
4. **Scenario 27:** Bowler Eligibility Enforcement (Attempt selecting same bowler or max-overs bowler gets blocked).
5. **Scenario 28:** Strike Rotation Correctness (Track strike swaps on 1/2/3 runs and over boundaries).
6. **Scenario 29:** Bowl-First Toss Choice (Team A wins toss, chooses to field → verify Team B bats first).

## Instructions
1. Review existing tests to ensure you properly use `ServerManager` to manage `resetMatchData()` between tests (or `resetDatabase()` if teams must be created).
2. The UI interactions (like `tapRun`, `selectBowler`, `completeTossWizard(chooseBat: false)`) should directly exercise the app.
3. Validate DB state via the API `GET /api/v1/test/deliveries/:matchId` against the expectations in the E2E docs.
4. Also write `docs/prompt/e2e/SCORING_CATEGORY_B_C_E2E.md` which instructs testers how to run this test suite.
