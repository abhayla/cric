# Implementation Prompt: Scoring Extras E2E Test

## Context

This prompt implements three E2E test scenarios covering extras (bye/leg-bye), strike rotation correctness, and maiden over verification — areas not covered by existing tests.

## Scenarios

### Scenario 23: Bye and Leg-Bye Scoring
- **Category:** B (Extras)
- **What it tests:** Bye and leg-bye deliveries with various run values (1, 2, 4)
- **Key assertions:**
  - `totalByes` and `totalLegByes` in innings table
  - Byes/leg-byes don't break maiden over (bowler concedes 0)
  - Deliveries flagged correctly with `isBye`/`isLegBye` and correct run values
  - Batting stats: opener scores 0 runs from bat

### Scenario 28: Strike Rotation Correctness
- **Category:** C (Strike Rotation)
- **What it tests:** Strike swaps on odd runs, stays on even runs, end-of-over swap
- **Key assertions:**
  - After 1 run: striker changes
  - After 2 runs: striker stays
  - After 3 runs: striker changes
  - After 0 runs: no change
  - After 4 runs: striker stays
  - End of over + odd run on last ball = cancel out
  - Bye/leg-bye odd runs also swap strike

### Scenario 11: Maiden Over
- **Category:** A (Core Scoring)
- **What it tests:** Maiden over detection (6 dot balls with 0 runs from bat)
- **Key assertions:**
  - Over with runs: `isMaiden=false`
  - Over with 6 dots: `isMaiden=true`
  - Bowler stats: `maidens>=1` for the maiden over bowler

## Implementation Details

### File
`apps/mobile/integration_test/scoring_extras_e2e_test.dart`

### Dependencies
- `helpers/match_flow_helpers.dart` — `tapExtra`, `confirmExtraWithRuns`, `tapRun`
- `helpers/tournament_flow_helpers.dart` — `completeTossWizard`, `createTeam`, `addPlayersToRoster`
- `helpers/scenario_test_data.dart` — `ScenarioTeams`
- Server endpoints: `/api/v1/test/overs/:matchId`, `/api/v1/test/innings-detail/:matchId`, `/api/v1/test/match-stats/:matchId`

### Pattern
Follows `scoring_edge_cases_e2e_test.dart` pattern:
1. Boot app
2. Create teams (or reuse existing)
3. Match setup + toss wizard
4. Score specific delivery sequence
5. Innings transition + quick chase
6. DB verification via test API endpoints

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
6 dot balls → isMaiden=true

## Server Endpoints Used
- `GET /api/v1/test/overs/:matchId` — verify isMaiden flag
- `GET /api/v1/test/innings-detail/:matchId` — verify totalByes, totalLegByes
- `GET /api/v1/test/match-stats/:matchId` — verify bowler maidens
- `GET /api/v1/test/deliveries/:matchId` — verify bye/LB flags on deliveries
