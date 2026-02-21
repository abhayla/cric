# Implementation Prompt: Match Flow Variations E2E Test

## Context

This prompt implements three E2E test scenarios covering match flow variations not tested by existing suites: bowl-first toss choice, tied match, and bowler eligibility enforcement.

## Scenarios

### Scenario 29: Bowl-First Toss Choice
- **What it tests:** Toss winner choosing to field (bowl first)
- **Key assertions:**
  - Inn 1: batting team is the OTHER team (not toss winner)
  - Inn 2: teams swap correctly
  - Match result correct after chase

### Scenario 7: Tied Match
- **What it tests:** Both innings score identical totals, overs exhausted
- **Key assertions:**
  - `resultType = 'tied'`
  - `winnerTeamId = null`

### Scenario 27: Bowler Eligibility Enforcement
- **What it tests:** Consecutive-over rule and max overs limit
- **Key assertions:**
  - After Over 1, the Over 1 bowler shows ineligibility indicator
  - After max overs (ceil(5/5)=1 per bowler), bowler shows "Max overs" indicator
  - Correct bowler rotation throughout the match

## Implementation Details

### File
`apps/mobile/integration_test/match_flow_variations_e2e_test.dart`

### Dependencies
- `helpers/tournament_flow_helpers.dart` — `completeTossWizard` with `chooseBat: false` param
- `helpers/match_flow_helpers.dart` — `selectBowler`
- `helpers/scenario_test_data.dart` — `ScenarioTeams`
- Server endpoints: `/api/v1/test/innings-detail/:matchId`, `/api/v1/test/match-result/:matchId`

### Pattern
Follows `scoring_edge_cases_e2e_test.dart` pattern.

### Bowl-First Flow
When toss winner chooses to field:
1. `completeTossWizard(..., chooseBat: false)` selects "Field" instead of "Bat"
2. The batting openers and opening bowler params must be swapped:
   - `battingOpener1/2` = openers from the OTHER team (batting first)
   - `openingBowler` = bowler from the toss winner's team (bowling first)

### Tied Match Flow
Score exactly 15 runs in both innings using identical delivery patterns:
- Over 1: 4, 0, 2, 1, 0, 0 = 7
- Over 2: 2, 0, 0, 0, 1, 0 = 3
- Over 3: 0, 1, 0, 2, 0, 0 = 3
- Over 4: 0, 0, 0, 0, 0, 2 = 2
- Over 5: 0, 0, 0, 0, 0, 0 = 0
- Total: 15

### Bowler Eligibility UI
The SelectBowlerSheet shows bowler eligibility status:
- "Bowled last over" — consecutive-over rule
- "Max overs" — max overs per bowler limit
- Ineligible bowlers may be greyed out or have a subtitle indicator
