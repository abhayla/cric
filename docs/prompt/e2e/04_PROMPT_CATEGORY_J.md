# E2E Test Implementation Prompt: Category J (Tournament Advanced)

Please implement an integration test file in Flutter at `apps/mobile/integration_test/tournament_advanced_e2e_test.dart` and its corresponding documentation prompt `docs/prompt/e2e/TOURNAMENT_ADVANCED_E2E.md`.

## Context
We are implementing comprehensive E2E test scenarios as outlined in `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`. This task focuses on **Category J: Scenarios 41-43, 47, 50**.

## Scenarios to Implement
Create a single group "Category J: Tournament Advanced" with specific tests.
1. **Scenario 41:** Tournament Team Reuse Across Runs (detect existing exactly 16 teams and skip creation overhead).
2. **Scenario 42:** Knockout-Only Tournament (Create a 8-team knockout, verify QF -> SF -> Final bracket structure).
3. **Scenario 43:** Round Robin Tournament (Create a 4-team round-robin, verify 6 fixtures generated, check standings table).
4. **Scenarios 47 & 50:** Tournament Career Stats & Leaderboard (Simulate partial scores and check that global career stats and the leaderboard reflect correct standings based on DB queries `GET /api/v1/players/:id/stats` or similar).

## Instructions
1. This test should use `ServerManager` to setup different formats.
2. The UI interactions should follow `completeMatchSetup()` and `completeTossWizard()` but maybe bypass full manual UI scoring for all 27 matches. If possible, structure the test to just verify the UI representations of brackets (QF/SF/F) for Knockout, and Standings for Round-Robin without strictly scoring every ball.
3. Validate DB state via API against the expectations.
4. Also write `docs/prompt/e2e/TOURNAMENT_ADVANCED_E2E.md` which instructs testers how to run this test suite.
