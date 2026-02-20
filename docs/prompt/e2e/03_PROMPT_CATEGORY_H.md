# E2E Test Implementation Prompt: Category H (Player Profile & Stat Accumulation)

Please modify the existing test file `apps/mobile/integration_test/player_profile_e2e_test.dart` and its documentation `docs/prompt/e2e/PLAYER_PROFILE_E2E.md`.

## Context
We are implementing comprehensive E2E test scenarios as outlined in `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`. This task focuses on **Category H: Scenarios 35-36**. The existing test already checks cross-match accumulation loosely, but needs to be exact.

## Scenarios to Implement
Update `player_profile_e2e_test.dart` to strictly verify:
1. **Scenario 35:** Same Player Stats Accumulate Across Matches.
   - Force specific scores for a player across the two matches (e.g., instead of random scoring, score exactly 50 in Match 1 (out) and 30 in Match 2 (out)).
   - Verify: Career Batting Average = 40.0, Total Runs = 80.
2. **Scenario 36:** Bowler Stats Across Matches.
   - Force specific bowler figures across two matches (e.g., 3/25 in Match 1 and 2/30 in Match 2).
   - Verify: Career Wickets = 5, Runs Conceded = 55, Econ = 6.875.

## Instructions
1. Replace the `playRandomInnings` calls in `player_profile_e2e_test.dart` with deterministic scoring loops that produce exact run and wicket values for at least one specific batter and bowler.
2. Assert the specific mathematical totals in the DB verifications (and UI if feasible).
3. Update `docs/prompt/e2e/PLAYER_PROFILE_E2E.md` to reflect these deterministic scenario checks.
