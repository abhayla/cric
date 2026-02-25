# Implementation Prompt: Match Flow Variations E2E Test

## Context

This prompt implements three E2E test scenarios covering match flow variations not tested by existing suites: bowl-first toss choice, tied match, and bowler eligibility enforcement.

The integration test suite uses a **layered architecture** in `apps/mobile/integration_test/`. Tests are prod-only (`--flavor prod --dart-define=FLAVOR=prod`), 100% UI-driven (zero API calls), and run against the prod server at `cricscores.in`.

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
  - Match complete modal shows "Match Tied"
  - No winner declared

### Scenario 27: Bowler Eligibility Enforcement
- **What it tests:** Consecutive-over rule and max overs limit
- **Key assertions:**
  - After Over 1, the Over 1 bowler shows ineligibility indicator
  - After max overs, bowler shows "Max overs" indicator
  - Correct bowler can be selected despite ineligible bowlers

## Implementation Details

### File
Create new test: `integration_test/tests/09_match_flow_variations_test.dart`

### Current Architecture
- `helpers/scoring.dart` — tap scoring controls
- `helpers/match_setup.dart` — match setup + toss wizard (modify for bowl-first)
- `helpers/modals.dart` — dismiss modals
- `core/app_bootstrap.dart` — app launch + Firebase auth
- `core/test_utils.dart` — `waitForFinder()`, `settle()`

### Pattern
Follows current test architecture: boot app -> reuse teams -> create match -> toss -> score predetermined deliveries -> verify UI state.

### Bowl-First Flow
When toss winner chooses to field:
1. Modify toss wizard helper to tap "Field" instead of "Bat"
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
