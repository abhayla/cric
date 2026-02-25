# Scoring Extras E2E Test — Run Prompt

Run this prompt when you want to test byes, leg-byes, strike rotation, and maiden overs through the real Flutter UI.

---

## Status: NOT YET IMPLEMENTED AS STANDALONE TEST

These scenarios (23, 28, 11 from `E2E_TEST_SCENARIOS.md`) do not have a dedicated test file in the current test suite. Strike rotation and extras are exercised implicitly by the random scoring in tournament tests (04-06) but not verified deterministically.

**To implement:** Create a new test file (e.g., `integration_test/tests/09_scoring_extras_test.dart`) following the current architecture.

---

## Scenarios to Cover

### Scenario 23: Bye and Leg-Bye Scoring
Tests bye (B) and leg-bye (LB) with various run values. Verifies that byes/LBs don't break maiden overs and don't count against the bowler.

### Scenario 28: Strike Rotation Correctness
Tests striker swap on odd runs, stay on even, end-of-over swap, and bye/LB strike rotation.

### Scenario 11: Maiden Over
Scores a maiden over (6 dots) preceded by a non-maiden over. Verifies maiden detection via UI.

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
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/09_scoring_extras_test.dart -d emulator-5554
```

---

## Implementation Notes

### Current Architecture
- `helpers/scoring.dart` — Tap scoring controls (runs, extras, wickets)
- `helpers/match_setup.dart` — Match setup + toss wizard
- `helpers/modals.dart` — Dismiss completion/transition modals
- `core/app_bootstrap.dart` — App launch + Firebase auth
- `core/test_utils.dart` — `waitForFinder()`, `settle()`

### Delivery Sequences

**Scenario 23 Over 1:**
| Ball | Type | Runs | Total | Strike? |
|------|------|------|-------|---------|
| 1.1 | Bye | 1 | 1/0 | Swaps (odd) |
| 1.2 | Leg-bye | 2 | 3/0 | Stays (even) |
| 1.3 | Bye | 4 | 7/0 | Stays (even) |
| 1.4 | Dot | 0 | 7/0 | No change |
| 1.5 | Leg-bye | 1 | 8/0 | Swaps (odd) |
| 1.6 | Dot | 0 | 8/0 | No change |

**Scenario 11 Maiden Over:** 6 dot balls

---

## Debugging Tips

- **Bye/LB button not working?** The extras panel may need run chip selection before confirming.
- **Maiden not detected?** Byes and leg-byes should NOT break a maiden. Check scoring pipeline — maiden only counts `runsFromBat + wideRuns + noBallRuns`.
- **Strike rotation wrong?** Check the scoring notifier's `_rotateStrike()` method. Odd runs (including byes/LBs) should swap.
