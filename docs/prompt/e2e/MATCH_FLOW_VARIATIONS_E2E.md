# Match Flow Variations E2E Test — Run Prompt

Run this prompt when you want to test bowl-first toss choice, tied matches, and bowler eligibility enforcement.

---

## Status: NOT YET IMPLEMENTED AS STANDALONE TEST

These scenarios (29, 7, 27 from `E2E_TEST_SCENARIOS.md`) do not have a dedicated test file in the current test suite. Bowl-first and tied match paths are not exercised by current tests (all tests use bat-first with random scoring).

**To implement:** Create a new test file (e.g., `integration_test/tests/09_match_flow_variations_test.dart`) following the current architecture.

---

## Scenarios to Cover

### Scenario 29: Bowl-First Toss Choice
Team A wins toss, chooses to FIELD. Verifies Team B bats first and innings teams are correctly assigned.

### Scenario 7: Tied Match
Both innings score exactly 15 runs. Verifies match complete modal shows "Match Tied" and no winner.

### Scenario 27: Bowler Eligibility
Verifies consecutive-over rule (last bowler ineligible) and max overs enforcement via SelectBowlerSheet UI.

---

## Prerequisites

1. **Android emulator is running**
2. **Prod server is live** at `cricscores.in`
3. **Teams already created** — run test 01 first
4. **Flutter dependencies resolved**
5. **Code generation up to date**

---

## Run Command (when implemented)

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/09_match_flow_variations_test.dart -d emulator-5554
```

---

## Implementation Notes

### Current Architecture
- `helpers/scoring.dart` — Tap scoring controls
- `helpers/match_setup.dart` — Match setup + toss wizard (modify for bowl-first)
- `helpers/modals.dart` — Dismiss modals
- `core/app_bootstrap.dart` — App launch + Firebase auth
- `core/test_utils.dart` — `waitForFinder()`, `settle()`

### Bowl-First Flow
1. Modify toss wizard helper to tap "Field" instead of "Bat"
2. Verify Inn 1 batting team = toss loser
3. Verify Inn 2 batting team = toss winner (chasing)

### Tied Match Delivery Patterns (both innings identical)
| Over | Pattern | Runs |
|------|---------|------|
| 1 | 4, 0, 2, 1, 0, 0 | 7 |
| 2 | 2, 0, 0, 0, 1, 0 | 3 |
| 3 | 0, 1, 0, 2, 0, 0 | 3 |
| 4 | 0, 0, 0, 0, 0, 2 | 2 |
| 5 | 0, 0, 0, 0, 0, 0 | 0 |
| **Total** | | **15** |

### Bowler Eligibility
- After Over 1, verify last bowler shows "Bowled last over" or greyed out in SelectBowlerSheet
- After max overs, verify bowler shows "Max overs" indicator

---

## Debugging Tips

- **Bowl-first not working?** Toss wizard helper needs a "choose to field" option. Check `match_setup.dart`.
- **Tied match not triggering?** If 2nd innings chases target before all overs, it won't tie. Delivery pattern must be carefully matched.
- **Bowler eligibility not visible?** Check `select_bowler_sheet.dart` for how ineligible bowlers are displayed.
