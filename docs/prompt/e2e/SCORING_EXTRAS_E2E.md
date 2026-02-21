# Scoring Extras E2E Test — Run Prompt

Run this prompt when you want to execute the scoring extras E2E test. This test proves that byes, leg-byes, strike rotation, and maiden overs work correctly through the real Flutter UI, with DB verification.

---

## What This Test Does

Three independent test cases in one file:

1. **Scenario 23: Bye and Leg-Bye Scoring** — Tests bye (B) and leg-bye (LB) with various run values. Verifies innings totals, maiden over (byes/LBs don't break maidens), and delivery flags.
2. **Scenario 28: Strike Rotation Correctness** — Tests striker swap on odd runs, stay on even, end-of-over swap, and bye/LB strike rotation.
3. **Scenario 11: Maiden Over** — Scores a maiden over (6 dots) preceded by a non-maiden over. Verifies `isMaiden` flag and bowler stats.

**Runtime: ~25-35 minutes on emulator.**

---

## Prerequisites Checklist

1. **Android emulator is running**
2. **Bun server running in test mode:**
   ```bash
   cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
   ```
3. **PostgreSQL running** with test database
4. **Flutter dependencies resolved** — `flutter pub get`
5. **Code generation up to date** — `dart run build_runner build --delete-conflicting-outputs`

---

## Run Command

```bash
cd apps/mobile && flutter test integration_test/scoring_extras_e2e_test.dart -d emulator-5554
```

Timeout: 45 minutes.

---

## Test 1: Scenario 23 — Bye and Leg-Bye Scoring

### Delivery Sequence (Over 1)
| Ball | Type | Runs | Total | Strike? |
|------|------|------|-------|---------|
| 1.1 | Bye | 1 | 1/0 | Swaps (odd) |
| 1.2 | Leg-bye | 2 | 3/0 | Stays (even) |
| 1.3 | Bye | 4 | 7/0 | Stays (even) |
| 1.4 | Dot | 0 | 7/0 | No change |
| 1.5 | Leg-bye | 1 | 8/0 | Swaps (odd) |
| 1.6 | Dot | 0 | 8/0 | No change |

Over 2-5: All dots. Then quick chase.

### Verifications
- Innings: `totalByes=5, totalLegByes=3`
- Overs: Over 1 `isMaiden=true` (byes/LBs don't break maiden)
- Bowling stats: Over 1 bowler `runsConceded=0, maidens>=1`
- Deliveries: 2 byes, 2 leg-byes flagged correctly

### UI Tap Sequence
```
tapExtra('B') → confirmExtraWithRuns(1) → tapExtra('LB') → confirmExtraWithRuns(2) → ...
```

---

## Test 2: Scenario 28 — Strike Rotation

### Delivery Sequence (Over 1)
| Ball | Runs | Assert Striker |
|------|------|----------------|
| 1.1 | 1 | Virat* (odd swap) |
| 1.2 | 2 | Virat* (even stays) |
| 1.3 | 3 | Rohit* (odd swap) |
| 1.4 | 0 | Rohit* (no change) |
| 1.5 | 4 | Rohit* (even stays) |
| 1.6 | 1 | Rohit* (odd + over-end cancel) |

### Over 2 (Bye/LB rotation)
| Ball | Type | Assert |
|------|------|--------|
| 2.1 | Bye 1 | Swap |
| 2.2 | LB 1 | Swap back |

### Verifications
- Delivery count matches between UI and DB
- Strike rotation logged (visual assertion)

---

## Test 3: Scenario 11 — Maiden Over

### Delivery Sequence
- **Over 1:** 4, 0, 2, 0, 1, 0 = 7 runs (NOT maiden)
- **Over 2:** 0, 0, 0, 0, 0, 0 = 0 runs (MAIDEN)

### Verifications
- Overs table: Over 1 `isMaiden=false`, Over 2 `isMaiden=true`
- Bowling stats: Bhuvneshwar Kumar `maidens>=1`

---

## Debugging Tips

- **Bye/LB button not working?** The `confirmExtraWithRuns` helper taps the run chip inside ExtrasPanel before confirming. If the ExtrasPanel doesn't show run chips, the default 1-run bye is used.
- **Maiden not detected?** Byes and leg-byes should NOT break a maiden. If the test fails, check the scoring pipeline's maiden calculation logic — it should only count `runsFromBat + wideRuns + noBallRuns`, not `byeRuns` or `legByeRuns`.
- **Strike rotation wrong?** Check the scoring notifier's `_rotateStrike()` method. Odd runs (including byes/LBs) should swap, even should not.

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/scoring_extras_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data |
| `integration_test/helpers/match_flow_helpers.dart` | `tapExtra`, `confirmExtraWithRuns`, `tapRun` |
| `integration_test/helpers/server_manager.dart` | Server API calls |
| `integration_test/helpers/tournament_flow_helpers.dart` | Team creation, toss |
