# E2E Test Implementation Prompt: Category A (Scoring Edge Cases)

Please implement an integration test file in Flutter at `apps/mobile/integration_test/scoring_category_a_e2e_test.dart` and its corresponding documentation prompt `docs/prompt/e2e/SCORING_CATEGORY_A_E2E.md`.

## Context
We are implementing comprehensive E2E test scenarios as outlined in `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`. This task focuses on **Category A (Scoring Edge Cases): Scenarios 1-11**.
You need to create a test that boots the app, uses `ServerManager` to manage test database state and simulate these 11 scenarios by tapping through the actual UI.

## Scenarios to Implement
Create a single group "Category A: Scoring Edge Cases" with individual tests or one large test executing these sequentially (whichever is more stable, likely separate testWidgets for independence, but remember team creation overhead). Please follow the pattern of existing tests like `scoring_edge_cases_e2e_test.dart`.

1. **Scenario 1:** Five Wickets in One Over (Rapid new-batter selection, 5W for bowler).
2. **Scenario 2:** Wide + No-Ball Chain (Over doesn't end until 6 legal deliveries).
3. **Scenario 3:** Target Chased Off a Wide (Match ends immediately).
4. **Scenario 4:** Target Chased Off a No-Ball (Match ends immediately).
5. **Scenario 5:** All Out for 0 (10 consecutive wickets).
6. **Scenario 6:** Last Ball Six to Win (Target chased exactly on 19.5 or 19.6).
7. **Scenario 7:** Tied Match (Equals scores).
8. **Scenario 8:** Undo After Over Transition (Restores previous over and bowler).
9. **Scenario 9:** Undo After Innings Transition (Should be blocked).
10. **Scenario 10:** Abandon Mid-Match (Abandon from menu).
11. **Scenario 11:** Maiden Over (6 dots).

## Instructions
1. Review `apps/mobile/integration_test/scoring_edge_cases_e2e_test.dart` to understand the setup, server manager usage, and helper functions available (like `tapRun`, `tapWicket`, `selectBowler`, etc).
2. Implement the `.dart` test. Ensure all interactions reflect the user tapping the UI. Use DB assertions at the end of matches to verify the `matchId` data `GET /api/v1/test/deliveries/:matchId` (like in `scoring_edge_cases_e2e_test.dart`).
3. Write `docs/prompt/e2e/SCORING_CATEGORY_A_E2E.md` which instructs testers how to run this specific test, listing out what it tests and the validations it performs.

Please start by reading `integration_test/scoring_edge_cases_e2e_test.dart` to familiarize yourself with the pattern, then write the new files.
