# Remaining Phase 7 E2E Tests — Run Prompt

Run this prompt to execute **all remaining E2E tests** (excluding the Full T20 test which has its own prompt). Tests run sequentially on emulator-5554, with the multi-device test also using emulator-5556 for the viewer.

---

## HOW THIS TEST WORKS — READ THIS FIRST

This prompt runs **5 E2E test suites** in sequence. Each is an **AUTOMATED integration test** — `WidgetTester` drives the UI programmatically.

| # | Test Suite | Test File | Scenarios | Emulators | Est. Runtime |
|---|-----------|-----------|-----------|-----------|-------------|
| 1 | Single Match | `single_match_e2e_test.dart` | Basic match flow | 5554 only | ~15-20 min |
| 2 | Scoring Edge Cases | `scoring_edge_cases_e2e_test.dart` | 21, 22, 26 | 5554 only | ~20-30 min |
| 3 | Persistence Recovery | `persistence_e2e_test.dart` | 16 | 5554 only | ~10-15 min |
| 4 | Multi-Device Live | `multi_device_scorer_e2e_test.dart` + `multi_device_viewer_e2e_test.dart` | 18, 19 | 5554 + 5556 | ~15-25 min |
| 5 | Player Profile | `player_profile_e2e_test.dart` | 20 | 5554 only | ~20-30 min |
| 6 | Scoring Extras | `scoring_extras_e2e_test.dart` | 23, 28, 11 | 5554 only | ~25-35 min |
| 7 | Match Flow Variations | `match_flow_variations_e2e_test.dart` | 29, 7, 27 | 5554 only | ~20-30 min |

**Tournament E2E** (`tournament_e2e_test.dart`, scenarios 41/47/50, ~2-3 hours) is excluded by default due to its long runtime. Add it as Test #8 if the user explicitly requests it.

**Total estimated runtime: ~120-180 minutes** (excluding tournament).

---

## EXECUTION INSTRUCTIONS FOR CLAUDE

**DO NOT ask any questions. DO NOT ask for confirmations. Execute immediately.**

**Skip any prerequisite the user has already confirmed.**

### Step 1: Quick Prerequisites (only check unknowns)

Only run checks for things the user has NOT already confirmed. Skip silently if already stated.

| Check | Command | Skip if user said |
|-------|---------|-------------------|
| Emulators | `flutter devices 2>/dev/null \| grep emulator` | "emulators are running" |
| Server | `curl -s http://localhost:3001/api/v1/test/health` | "server is running" |
| Stale processes | `wmic.exe process where "name='dart.exe'" get processid,commandline` | Only check if a previous test run failed |

If a check fails, report the specific failure and stop.

### Step 2: Disable ANR on Both Emulators

```bash
adb -s emulator-5554 shell settings put global anr_show_background 0
adb -s emulator-5556 shell settings put global anr_show_background 0
```

### Step 3: Run Tests Sequentially

Run each test one at a time. **Wait for each test to fully complete before starting the next.** Between tests, reset match data to avoid stale state (except between multi-device scorer and viewer which run in parallel).

**IMPORTANT:** Before each test, clear coordination signals and reset match data:
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

---

## TEST 1: Single Match E2E

**What it does:** Creates teams, sets up a match, completes toss, scores a short match through the UI, verifies match result.

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/single_match_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Monitoring:**
- Check progress every ~60s with `TaskOutput` (non-blocking)
- Dismiss ANR dialogs: `adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"`
- Wait for test to print final result (PASS/FAIL)
- Take a screenshot when the test completes: `adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/single_match_final.png`

**Expected output:** Test completes with all assertions passing. Match result verified in DB.

**After completion:** Report result, then proceed to Test 2.

---

## TEST 2: Scoring Edge Cases E2E

**What it does:** Three independent test cases:
1. **Scenario 21 — No-Ball Free Hit Chain:** NB -> free hit -> NB on free hit -> another free hit -> normal delivery
2. **Scenario 22 — All Dismissal Types:** Bowled, Caught, LBW, Run Out, Stumped through WicketDialog
3. **Scenario 26 — Overs Exhausted:** Scores 30 legal deliveries (5 overs) without wickets, verifies innings ends

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/scoring_edge_cases_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Monitoring:**
- Check progress every ~60s with `TaskOutput` (non-blocking)
- Dismiss ANR dialogs every ~30s
- Look for per-scenario completion lines in output
- Take a screenshot when each scenario completes (if visible in output)

**Expected output:** All 3 scenarios pass. DB verification for each scenario confirms correct delivery records.

**After completion:** Report result, then proceed to Test 3.

---

## TEST 3: Persistence Recovery E2E

**What it does:**
- Scores 3 overs (18 legal deliveries) through the UI
- Simulates app restart by re-pumping the widget tree
- Verifies the app detects a resumable match from Drift/SQLite
- Resumes scoring and records one more delivery
- Verifies no duplicate deliveries in PostgreSQL

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/persistence_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Monitoring:**
- Check progress every ~60s with `TaskOutput` (non-blocking)
- Dismiss ANR dialogs every ~30s
- Look for "app restart" / "resume" markers in output
- Take a screenshot after restart phase: `adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/persistence_restart.png`

**Expected output:** Match resumes after simulated restart. No duplicate deliveries. DB delivery count matches expected.

**After completion:** Report result, then proceed to Test 4.

---

## TEST 4: Multi-Device Live E2E (Dual Emulators)

**What it does:**
- **Scorer (emulator-5554):** Scores a predetermined match with 2s pauses between deliveries
- **Viewer (emulator-5556):** Connects via WebSocket, receives live updates, verifies every field
- Uses the same signal handshake as Full T20 (scorer-ready / viewer-ready)

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Launch scorer (background):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/multi_device_scorer_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Wait 60 seconds** (Gradle lock contention), then **launch viewer (background):**
```
Bash tool: sleep 60
```
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/multi_device_viewer_e2e_test.dart -d emulator-5556
  - run_in_background: true
  - timeout: 600000
```

**Why 60s delay:** Both tests share `apps/mobile/build/`. Simultaneous launches cause Gradle lock contention. The viewer polls for `scorer-ready` signal for up to 5 minutes.

**Monitoring loop (run until both tests end):**

0. **Dismiss ANR dialogs** every cycle on BOTH emulators:
   ```bash
   adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   adb -s emulator-5556 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   ```

1. **Check scorer progress** with `TaskOutput` (non-blocking, `block: false`, `timeout: 5000`)

2. **Check viewer progress** with `TaskOutput` (non-blocking)

3. **Take periodic screenshots** of both emulators for sync comparison:
   ```bash
   adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/multi_scorer_progress.png
   adb -s emulator-5556 exec-out screencap -p > .playwright-mcp/screenshots/multi_viewer_progress.png
   ```

4. **Compare scores** visually from screenshots. Report sync status:
   ```
   Multi-Device Check — Scorer: 45/2 (7.3)  |  Viewer: 45/2 (7.3)  OK
   ```

5. **Check every ~30s.** Wait for both tests to complete.

6. **On completion** — Read both task outputs for final summaries. Report:
   - Scorer: deliveries scored, match result
   - Viewer: updates received, invariant violations (should be 0)
   - Sync status: any mismatches between scorer and viewer

**Expected output:** Both tests pass. Viewer receives all updates with 0 invariant violations.

**After completion:** Report result, then proceed to Test 5.

---

## TEST 5: Player Profile E2E

**What it does:**
- Scores 2 complete quick matches (5 overs each, 6 players per side) using the same teams
- Navigates to a player's profile: Teams -> Team Detail -> Players -> Player Detail
- Verifies career stats (matches played, runs, average, wickets) accumulated across both matches
- Cross-checks profile data against server API

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/player_profile_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Monitoring:**
- Check progress every ~60s with `TaskOutput` (non-blocking)
- Dismiss ANR dialogs every ~30s
- Look for "Match 1 complete" / "Match 2 complete" / "Profile verification" markers
- Take a screenshot of the player profile page: `adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/player_profile_final.png`

**Expected output:** Career stats correctly accumulate across 2 matches. Profile page data matches server API.

**After completion:** Report result.

---

## TEST 6: Scoring Extras E2E

**What it does:** Three test cases:
1. **Scenario 23 — Bye/Leg-Bye Scoring:** Tests byes and leg-byes with various run values, verifies innings totals and maiden detection
2. **Scenario 28 — Strike Rotation:** Tests striker swap on odd/even runs, end-of-over swap, bye/LB rotation
3. **Scenario 11 — Maiden Over:** Scores a maiden over (6 dots), verifies isMaiden flag and bowler stats

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/scoring_extras_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Expected output:** All 3 scenarios pass. Byes/LBs correctly tracked. Maiden over detected. Strike rotation correct.

**After completion:** Report result, then proceed to Test 7.

---

## TEST 7: Match Flow Variations E2E

**What it does:** Three test cases:
1. **Scenario 29 — Bowl-First:** Toss winner chooses to field, verifies innings team assignments are swapped
2. **Scenario 7 — Tied Match:** Both innings score exactly 15 runs, verifies resultType='tied'
3. **Scenario 27 — Bowler Eligibility:** Verifies consecutive-over rule and max overs enforcement in UI

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-match-data
```

**Run command (background, 10 min timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/match_flow_variations_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000
```

**Expected output:** All 3 scenarios pass. Bowl-first innings correct. Tied match detected. Bowler eligibility enforced.

**After completion:** Report result.

---

## TEST 8 (OPTIONAL): Tournament E2E

**Only run if the user explicitly requests it.** This test takes ~2-3 hours.
(Previously Test #6, renumbered to #8 after adding Scoring Extras and Match Flow Variations.)

**What it does:**
- Creates 16 teams (6 players each) via server API
- Creates Group+Knockout tournament (4 groups x 4 teams, 6 overs, magic over on 4th)
- Plays 24 group stage matches + 2 semi-finals + 1 final through the UI
- Verifies standings, leaderboards, and all match data in PostgreSQL

**Pre-test reset:**
```bash
curl -s -X DELETE http://localhost:3001/api/v1/test/signals
curl -s -X POST http://localhost:3001/api/v1/test/reset-db
```

**Run command (background, 3 hour timeout):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/tournament_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 10800000
```

**Monitoring:**
- Check progress every ~5 minutes with `TaskOutput`
- Dismiss ANR dialogs every ~60s
- Look for "Match N/27 complete" progress markers
- Take screenshots at group stage end and after the final

**Expected output:** All 27 matches complete. Group standings verified. Tournament winner determined. All match data verified in PostgreSQL.

---

## Step 4: Final Summary Report

After all tests complete (or if any test fails), present a consolidated report:

```
=== REMAINING E2E TEST RESULTS ===

| # | Test Suite            | Status  | Runtime | Notes |
|---|-----------------------|---------|---------|-------|
| 1 | Single Match          | PASS/FAIL | Xm Ys  |       |
| 2 | Scoring Edge Cases    | PASS/FAIL | Xm Ys  |       |
| 3 | Persistence Recovery  | PASS/FAIL | Xm Ys  |       |
| 4 | Multi-Device Live     | PASS/FAIL | Xm Ys  |       |
| 5 | Player Profile        | PASS/FAIL | Xm Ys  |       |
| 6 | Scoring Extras        | PASS/FAIL | Xm Ys  |       |
| 7 | Match Flow Variations | PASS/FAIL | Xm Ys  |       |
| 8 | Tournament (optional) | PASS/FAIL/SKIPPED | Xm Ys |  |

Total: X/7 PASSED (or X/8 if tournament included)
Total runtime: ~XX minutes
```

**If any test fails:**
- Report the specific failure message from the test output
- Take a screenshot of the emulator at the point of failure
- Do NOT proceed to the next test — report the failure and stop

---

## Debugging Tips

### Common Across All Tests
- **Gradle lock contention:** Never launch two tests on different emulators simultaneously. Always wait ~60s between launches.
- **Kill stale dart.exe:** `wmic.exe process where "name='dart.exe'" get processid,commandline` then `taskkill.exe /PID <pid> /F`
- **ANR blocking tests:** Run `adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"` every ~30s
- **Server restart clears signals:** `testSignals` Map is in-memory. If server restarts, restart the current test.
- **ADB path:** If `adb` is not in PATH, use: `C:/Users/itsab/AppData/Local/Android/Sdk/platform-tools/adb.exe`

### Single Match Issues
- **Match setup stalls?** Check if teams already exist via `curl http://localhost:3001/api/v1/test/teams`. Test should reuse existing teams.

### Scoring Edge Cases Issues
- **Free hit not triggering?** Verify the no-ball was recorded correctly. Check if free hit badge appears on the scoring page.
- **Dismissal dialog not appearing?** The wicket button may not be tappable in certain states (e.g., free hit — only run out is valid).

### Persistence Recovery Issues
- **App not detecting resumable match?** Drift DB might be empty after a full DB reset. Ensure only `reset-match-data` is used (not `reset-db`), so teams persist.
- **Duplicate deliveries?** Check if the sync service flushed before the simulated restart.

### Multi-Device Issues
- **Viewer never receives scorer-ready?** Same as Full T20 — check server is running, check scorer terminal for errors.
- **WebSocket connection fails?** Verify server's `/ws` endpoint. Check emulator network: `adb -s emulator-5556 shell ping 10.0.2.2`.

### Player Profile Issues
- **Career stats not accumulating?** Check if `player_career_stats` upserts are running after each match completion.
- **Profile page navigation fails?** Ensure the Teams tab and team detail page are accessible.

### Tournament Issues
- **Match N hangs?** Tournament test creates many matches. ANR is more likely — increase ANR dismiss frequency to every ~15s.
- **Group standings wrong?** Check server's `calculateGroupStandings` logic. NRR calculation is complex.

---

## Key Files

| File | Purpose |
|------|---------|
| **Test files** | |
| `integration_test/single_match_e2e_test.dart` | Basic match flow E2E |
| `integration_test/scoring_edge_cases_e2e_test.dart` | Free hit, dismissals, overs exhausted |
| `integration_test/persistence_e2e_test.dart` | App restart + resume |
| `integration_test/multi_device_scorer_e2e_test.dart` | Multi-device scorer (emulator-5554) |
| `integration_test/multi_device_viewer_e2e_test.dart` | Multi-device viewer (emulator-5556) |
| `integration_test/player_profile_e2e_test.dart` | Career stats across matches |
| `integration_test/scoring_extras_e2e_test.dart` | Byes, leg-byes, strike rotation, maiden |
| `integration_test/match_flow_variations_e2e_test.dart` | Bowl-first, tied match, bowler eligibility |
| `integration_test/tournament_e2e_test.dart` | Full tournament lifecycle |
| **Helpers** | |
| `integration_test/helpers/match_flow_helpers.dart` | `tapRun`, `tapExtra`, `tapWicket`, `selectBowler`, `selectBatter` |
| `integration_test/helpers/server_manager.dart` | Health check, DB reset, API helpers |
| `integration_test/helpers/scenario_test_data.dart` | Team rosters, openers, bowler pools |
| `integration_test/helpers/tournament_flow_helpers.dart` | Tournament-specific UI helpers |
| `integration_test/helpers/app_test_wrapper.dart` | In-memory Drift DB + ProviderScope |

---

## Server Test Endpoints Reference

All under `GET/POST /api/v1/test/...` — only available when `NODE_ENV=test`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/teams` | GET | List teams with player counts |
| `/latest-match` | GET | Most recently created match ID |
| `/deliveries/:matchId` | GET | All deliveries for a match |
| `/match-stats/:matchId` | GET | Batting + bowling stats |
| `/match-result/:matchId` | GET | Result type, winner, margin, MOTM |
| `/overs/:matchId` | GET | All overs with maiden flag |
| `/innings-detail/:matchId` | GET | Innings totals (byes, LBs, extras) |
| `/fielding-stats/:matchId` | GET | Catches, run outs, stumpings |
| `/fall-of-wickets/:matchId` | GET | Fall of wickets records |
| `/signal/:name` | GET/POST | Coordination signals |
| `/signals` | DELETE | Clear all signals |
| `/reset-db` | POST | Truncate ALL tables + re-seed |
| `/reset-match-data` | POST | Truncate match tables only (preserve teams) |
