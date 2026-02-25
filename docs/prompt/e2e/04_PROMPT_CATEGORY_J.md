# E2E Test Implementation Prompt: Category J (Tournament Advanced)

Please implement integration tests for **Category J: Scenarios 41-43, 47, 50** from `docs/prompt/e2e/E2E_TEST_SCENARIOS.md`.

## Context

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

## Current Tournament Tests

Three tournament tests already exist:
- `04_tournament_gk_test.dart` — Group+Knockout (covers Scenario 41 team reuse, partial 44/49)
- `05_tournament_ko_test.dart` — Knockout (covers Scenario 42)
- `06_tournament_rr_test.dart` — Round Robin (covers Scenario 43)

## Scenarios to Implement (gaps in current coverage)

1. **Scenario 41:** Tournament Team Reuse Across Runs — Verify existing tests properly skip team creation on subsequent runs.
2. **Scenario 42:** Knockout-Only Tournament — Already covered by test 05. Extend to verify bracket structure (QF → SF → Final) via UI.
3. **Scenario 43:** Round Robin Tournament — Already covered by test 06. Extend to verify C(N,2) fixture count and standings table completeness.
4. **Scenario 47:** Tournament Career Stats — After completing a tournament, verify player career stats accumulated correctly via player profile pages.
5. **Scenario 50:** Tournament Leaderboard Accuracy — Verify leaderboard categories (Most Runs, Most Wickets) via tournament detail page.

## Current Architecture

- **Tournament helpers:** `helpers/tournament_mgmt.dart` (`createTournament()`, `addTeamToTournament()`, `generateFixtures()`, `startTournament()`)
- **Tournament flow:** `flows/tournament_flow.dart` (`scoreAllFixtures()`)
- **Verification:** `verification/tournament_verifier.dart` (standings, fixtures), `verification/player_profile_verifier.dart` (career stats)
- **Config:** `config/tournament_presets.dart` (format configurations)

## Instructions

1. Review existing tournament tests (04-06) and `tournament_mgmt.dart` helpers.
2. For Scenarios 47/50: add verification steps after tournament completion — navigate to player profiles and leaderboard tab.
3. All verification through UI navigation + `expect()` assertions — no direct API calls.
4. Use `tournament_verifier.dart` and `player_profile_verifier.dart` for structured assertions.
