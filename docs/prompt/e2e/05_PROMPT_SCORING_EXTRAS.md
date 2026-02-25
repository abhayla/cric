# Implementation Prompt: Scoring Extras E2E Test

## Context

This prompt implements three E2E test scenarios covering extras (bye/leg-bye), strike rotation correctness, and maiden over verification — areas not fully covered by existing tests.

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

## Scenarios

### Scenario 23: Bye and Leg-Bye Scoring
- **Category:** B (Extras)
- **What it tests:** Bye and leg-bye deliveries with various run values (1, 2, 4)
- **Key assertions:**
  - Byes/leg-byes don't break maiden over (bowler concedes 0)
  - Correct strike rotation on odd bye/LB runs
  - Batting stats: opener scores 0 runs from bat

### Scenario 28: Strike Rotation Correctness
- **Category:** C (Strike Rotation)
- **What it tests:** Strike swaps on odd runs, stays on even runs, end-of-over swap
- **Key assertions:**
  - After 1 run: striker changes
  - After 2 runs: striker stays
  - After 3 runs: striker changes
  - End of over + odd run on last ball = cancel out
  - Bye/leg-bye odd runs also swap strike

### Scenario 11: Maiden Over
- **Category:** A (Core Scoring)
- **What it tests:** Maiden over detection (6 dot balls with 0 runs from bat)
- **Key assertions:**
  - Over with runs: not maiden
  - Over with 6 dots: maiden
  - Bowler stats show maiden count >= 1

## Implementation Details

### File
Create new test: `integration_test/tests/09_scoring_extras_test.dart`

### Current Architecture
- `helpers/scoring.dart` — `tapRun()`, `tapExtra()`, tap scoring controls
- `helpers/match_setup.dart` — match setup + toss wizard
- `helpers/modals.dart` — dismiss modals
- `core/app_bootstrap.dart` — app launch + Firebase auth
- `core/test_utils.dart` — `waitForFinder()`, `settle()`

### Pattern
1. Boot app via `app_bootstrap.dart`
2. Reuse teams from test 01
3. Create match + toss wizard via `match_setup.dart`
4. Score specific delivery sequence via `helpers/scoring.dart`
5. Verify results via UI (scorer display, bowler stats)
6. Complete match (innings transition + quick chase)

### Delivery Sequences

**Scenario 23 Over 1:**
| Ball | Type | Runs | Total |
|------|------|------|-------|
| 1.1 | Bye | 1 | 1/0 |
| 1.2 | Leg-bye | 2 | 3/0 |
| 1.3 | Bye | 4 | 7/0 |
| 1.4 | Dot | 0 | 7/0 |
| 1.5 | Leg-bye | 1 | 8/0 |
| 1.6 | Dot | 0 | 8/0 |

**Scenario 11 Over 2 (Maiden):**
6 dot balls -> verify maiden via UI
