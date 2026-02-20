# Scoring Edge Cases E2E Test — Run Prompt

Run this prompt when you want to execute the scoring edge cases E2E test. This test proves that complex cricket scoring scenarios work correctly through the real Flutter UI, with DB verification.

---

## What This Test Does

Three independent test cases in one file:

1. **Scenario 21: No-Ball Free Hit Chain** — Verifies free hit mechanics: NB → free hit → NB on free hit → another free hit → normal delivery
2. **Scenario 22: All Dismissal Types** — Tests Bowled, Caught, LBW, Run Out, and Stumped through the WicketDialog wizard
3. **Scenario 26: Overs Exhausted** — Scores all 30 legal deliveries (5 overs) without wickets, verifying innings ends on over exhaustion

**Runtime: ~20-30 minutes on emulator.**

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
cd apps/mobile && flutter test integration_test/scoring_edge_cases_e2e_test.dart -d emulator-5554
```

Timeout: 45 minutes.

---

## Test 1: Scenario 21 — No-Ball Free Hit Chain

### Delivery Sequence
| # | Type | Details |
|---|------|---------|
| 1 | NB | No-ball, +1 penalty run |
| 2 | 4 (FH) | Boundary on free hit, 4 runs |
| 3 | NB | No-ball on free hit → chains another FH |
| 4 | 1 (FH) | Single on free hit, strike swaps |
| 5 | 0 | Normal dot ball (free hit chain broken) |
| 6+ | dots | Complete the over normally |

### Verifications
- Two no-ball records in DB with `isNoBall: true`
- Free hit deliveries flagged correctly (`isFreeHit: true` on post-NB delivery)
- Runs accumulated: NB(1) + 4 + NB(1) + 1 + 0 = 7 runs in first over
- Free hit chain: NB on a free hit = another free hit (not a double free hit)

### UI Tap Sequence
```
tapExtra('NB') → confirmExtra → tapRun(4) → tapExtra('NB') → confirmExtra → tapRun(1) → tapRun(0)
```

---

## Test 2: Scenario 22 — All Dismissal Types

### Delivery Sequence
Score runs between wickets to keep the match going, then take wickets with different dismissal types:

| Wicket | Type | UI Flow |
|--------|------|---------|
| 1 | Bowled | tapWicket → selectDismissalType('Bowled') → tapWicketConfirm |
| 2 | Caught | tapWicket → selectDismissalType('Caught') → [select fielder] → tapWicketConfirm |
| 3 | LBW | tapWicket → selectDismissalType('LBW') → tapWicketConfirm |
| 4 | Run Out | tapWicket → selectDismissalType('Run Out') → [select fielder] → tapWicketConfirm |
| 5 | Stumped | tapWicket → selectDismissalType('Stumped') → [select fielder] → tapWicketConfirm |

### Fielders Used (from Team B)
- Caught fielder: Shubman Gill
- Run Out fielder: Yashasvi Jaiswal
- Stumped fielder: Ishan Kishan (WK)

### Next Batters (in order)
After Rohit Sharma and Virat Kohli (openers):
1. Suryakumar Yadav → 2. KL Rahul → 3. Hardik Pandya → 4. Ravindra Jadeja → 5. Axar Patel → etc.

### Verifications
- Each wicket delivery has correct dismissal type in DB
- Bowler gets wicket credit for Bowled, Caught, LBW, Stumped
- Fielder recorded for Caught, Run Out, Stumped
- Run Out doesn't credit the bowler with a wicket

---

## Test 3: Scenario 26 — Overs Exhausted

### Approach
Score 30 legal deliveries (5 overs × 6 balls) of all dot balls to reach overs exhausted without any wickets.

### Bowler Rotation
- Over 1: Deepak Chahar (set by toss)
- Over 2: Bhuvneshwar Kumar
- Over 3: Kuldeep Yadav
- Over 4: Ravichandran Ashwin
- Over 5: Washington Sundar

### Verifications
- InningsTransitionModal appears (not MatchCompleteModal) after 30 legal deliveries
- Innings completion reason = `overs_exhausted`
- Exactly 0 wickets taken
- Total score = 0 (all dots)
- 5 completed overs, all maidens

---

## Debugging Tips

- **Free hit not showing?** Verify the no-ball was recorded correctly. Free hit indicator appears after NB in the delivery processing pipeline step 9.
- **Caught fielder selection stuck?** The WicketDialog has a multi-step wizard. After selecting "Caught", tap "Next" to get to the fielder selection step.
- **Overs not ending?** Make sure no extras (wides/NB) were accidentally tapped. These don't count as legal deliveries.
- **Bowler selection after over?** The SelectBowlerSheet appears automatically. Consecutive-over rule blocks the last bowler.

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/scoring_edge_cases_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data |
| `integration_test/helpers/match_flow_helpers.dart` | Tap helpers |
| `integration_test/helpers/server_manager.dart` | Server API calls |
| `integration_test/helpers/tournament_flow_helpers.dart` | Team creation, toss |
