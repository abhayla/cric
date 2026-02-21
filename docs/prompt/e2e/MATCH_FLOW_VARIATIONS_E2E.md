# Match Flow Variations E2E Test — Run Prompt

Run this prompt when you want to execute the match flow variations E2E test. This test proves that bowl-first toss choice, tied matches, and bowler eligibility enforcement work correctly.

---

## What This Test Does

Three independent test cases in one file:

1. **Scenario 29: Bowl-First Toss Choice** — Team A wins toss, chooses to FIELD. Verifies Team B bats first and innings teams are correctly assigned.
2. **Scenario 7: Tied Match** — Both innings score exactly 15 runs. Verifies `resultType='tied'` and `winnerTeamId=null`.
3. **Scenario 27: Bowler Eligibility** — Verifies consecutive-over rule (last bowler ineligible) and max overs enforcement.

**Runtime: ~20-30 minutes on emulator.**

---

## Prerequisites Checklist

1. **Android emulator is running**
2. **Bun server running in test mode:**
   ```bash
   cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
   ```
3. **PostgreSQL running** with test database
4. **Flutter dependencies resolved**
5. **Code generation up to date**

---

## Run Command

```bash
cd apps/mobile && flutter test integration_test/match_flow_variations_e2e_test.dart -d emulator-5554
```

Timeout: 45 minutes.

---

## Test 1: Scenario 29 — Bowl-First Toss Choice

### Flow
1. Team A wins toss, chooses to **Field** (uses `chooseBat: false`)
2. Inn 1: Team B bats (openers: Shubman Gill, Yashasvi Jaiswal), Team A bowls (Jasprit Bumrah)
3. Over 1: Score 7 runs, Overs 2-5: dots
4. Inn 2: Team A bats (Rohit Sharma, Virat Kohli), Team B bowls (Deepak Chahar)
5. Chase target quickly

### Verifications
- `innings[0].battingTeamId` = Team B's ID
- `innings[0].bowlingTeamId` = Team A's ID
- `innings[1]` has them swapped
- Match result has a winner

---

## Test 2: Scenario 7 — Tied Match

### Delivery Patterns (both innings identical)
| Over | Pattern | Runs |
|------|---------|------|
| 1 | 4, 0, 2, 1, 0, 0 | 7 |
| 2 | 2, 0, 0, 0, 1, 0 | 3 |
| 3 | 0, 1, 0, 2, 0, 0 | 3 |
| 4 | 0, 0, 0, 0, 0, 2 | 2 |
| 5 | 0, 0, 0, 0, 0, 0 | 0 |
| **Total** | | **15** |

### Verifications
- `match_result.resultType = 'tied'`
- `match_result.winnerTeamId = null`

### Note
The 2nd innings may end early if a boundary causes the chase to succeed before matching. The test uses the exact same pattern, so it should reach 15 at ball 5.6 (same as 1st innings).

---

## Test 3: Scenario 27 — Bowler Eligibility

### Flow
- Over 1: Deepak Chahar bowls 6 dots
- Over 2 selection: Verify Deepak is ineligible ("Bowled last over" or greyed out). Select Bhuvneshwar.
- Over 3 selection: Verify Bhuvneshwar is now ineligible. Select Kuldeep.
- Over 5: Check max overs enforcement (ceil(5/5)=1 per bowler)

### Verifications
- "last over" text appears in bowler selection sheet
- "Max" text appears when a bowler has hit their over limit
- Correct bowler can be selected despite ineligible bowlers

---

## Debugging Tips

- **Bowl-first not working?** The `completeTossWizard` helper taps "Field" instead of "Bat" when `chooseBat: false`. Verify the toss_page.dart has a "Field" option.
- **Tied match not triggering?** If the 2nd innings chases the target before all overs are exhausted, the match won't be tied. The delivery pattern must be carefully matched. Check if a boundary was accidentally scored.
- **Bowler eligibility not visible?** The SelectBowlerSheet implementation may vary. Check `select_bowler_sheet.dart` for how ineligible bowlers are displayed (greyed opacity, subtitle text, or filtered out entirely).

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/match_flow_variations_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data |
| `integration_test/helpers/match_flow_helpers.dart` | `tapRun`, `selectBowler` |
| `integration_test/helpers/tournament_flow_helpers.dart` | `completeTossWizard` with `chooseBat` |
| `integration_test/helpers/server_manager.dart` | Server API calls |
