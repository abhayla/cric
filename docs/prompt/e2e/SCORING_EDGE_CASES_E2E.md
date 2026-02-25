# Scoring Edge Cases E2E Test — Run Prompt

Run this prompt when you want to execute specific scoring edge case scenarios. These test complex cricket scoring rules through the real Flutter UI.

---

## Status: NOT YET IMPLEMENTED AS STANDALONE TEST

These scenarios (21, 22, 26 from `E2E_TEST_SCENARIOS.md`) do not have a dedicated test file in the current test suite. Some aspects are partially covered by `02_standalone_match_test.dart` (undo, target chase) and the random scoring in tournament tests (04-06).

**To implement:** Create a new test file (e.g., `integration_test/tests/09_scoring_edge_cases_test.dart`) following the current architecture.

---

## Scenarios to Cover

### Scenario 21: No-Ball Free Hit Chain
Verifies free hit mechanics: NB -> free hit -> NB on free hit -> another free hit -> normal delivery.

### Scenario 22: All Dismissal Types
Tests Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket, C&B, Ret. Hurt, Ret. Out through the WicketDialog wizard.

### Scenario 26: Overs Exhausted
Scores all legal deliveries without wickets, verifying innings ends on over exhaustion.

---

## Prerequisites

1. **Android emulator is running**
2. **Prod server is live** at `cricscores.in`
3. **Teams already created** — run test 01 first
4. **Flutter dependencies resolved** — `flutter pub get`
5. **Code generation up to date**

---

## Run Command (when implemented)

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/09_scoring_edge_cases_test.dart -d emulator-5554
```

---

## Implementation Notes

### Current Architecture
- `helpers/scoring.dart` — Tap scoring controls (runs, extras, wickets)
- `helpers/match_setup.dart` — Match setup + toss wizard
- `helpers/modals.dart` — Dismiss completion/transition modals
- `core/app_bootstrap.dart` — App launch + Firebase auth
- `core/test_utils.dart` — `waitForFinder()`, `settle()`

### Pattern
1. Boot app via `app_bootstrap.dart`
2. Reuse teams from test 01
3. Create match + toss wizard
4. Score predetermined delivery sequences
5. Verify results via UI (scorer display, match complete modal)

### Test 1: No-Ball Free Hit Chain
| # | Type | Details |
|---|------|---------|
| 1 | NB | No-ball, +1 penalty run |
| 2 | 4 (FH) | Boundary on free hit, 4 runs |
| 3 | NB | No-ball on free hit -> chains another FH |
| 4 | 1 (FH) | Single on free hit, strike swaps |
| 5 | 0 | Normal dot ball (free hit chain broken) |

### Test 2: All Dismissal Types (9 types)
Take wickets with all dismissal types across multiple overs:
- Bowled, Caught (with fielder), LBW, Run Out (with fielder), Stumped (with fielder)
- Hit Wicket, C&B, Ret. Hurt (not a wicket), Ret. Out

### Test 3: Overs Exhausted
Score all dots for N overs to reach overs exhaustion without wickets.

---

## Debugging Tips

- **Free hit not showing?** Verify the no-ball was recorded correctly. Free hit indicator appears after NB.
- **Caught fielder selection stuck?** WicketDialog has multi-step wizard. After selecting "Caught", tap "Next" for fielder step.
- **Overs not ending?** Make sure no extras (wides/NB) were accidentally tapped — they don't count as legal deliveries.
