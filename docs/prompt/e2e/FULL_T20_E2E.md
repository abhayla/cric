# Full T20 E2E Test — Run Prompt

Run this prompt to execute the full T20 E2E test (Scenarios 12, 13, 15) with **scorer + viewer on two emulators**.

---

## HOW THIS TEST WORKS — READ THIS FIRST

This is an **AUTOMATED integration test**, not a manual scoring session.

- **You do NOT manually tap scores.** The test code (`WidgetTester`) drives the UI programmatically — it taps run buttons, selects bowlers, confirms wickets, etc. automatically.
- **You WATCH it happen on the emulators.** The app launches visually on the device, and you see screens change, buttons get tapped, and scores update in real-time — all driven by code.
- **Scorer emulator (5554):** You'll see the app boot, teams get created, match setup, toss wizard, then rapid-fire scoring — buttons light up, score ticks up, bowler dialogs open and close automatically.
- **Viewer emulator (5556):** You'll see the app boot, navigate to the live match page, and the score/stats update in real-time as the scorer pushes deliveries through the server via WebSocket.
- **Terminal output:** Both terminals print detailed logs — per-over summaries, delivery tracking, DB verification results. The real action is on the emulator screens + terminal logs.

**First-run timing:** Gradle build takes **2-5 minutes** before anything appears on the emulator. The terminal will show Gradle output during this time. Be patient — once the app icon appears on the emulator, scoring starts within ~30 seconds.

---

## EXECUTION INSTRUCTIONS FOR CLAUDE

**DO NOT ask any questions. DO NOT ask for confirmations. DO NOT repeat information the user already provided. Execute immediately.**

**Skip any prerequisite the user has already confirmed** (e.g., "server is already running" = skip server health check). Only check what is unknown.

### Step 1: Quick Prerequisites (only check unknowns)

Only run checks for things the user has NOT already confirmed. Skip silently if already stated.

| Check | Command | Skip if user said |
|-------|---------|-------------------|
| Emulators | `flutter devices 2>/dev/null \| grep emulator` | "emulators are running" |
| Server | `curl -s http://localhost:3001/api/v1/test/health` | "server is running" / "server is already running" |
| Stale processes | `wmic.exe process where "name='dart.exe'" get processid,commandline` | Only check if a previous test run failed |

If a check fails, report the specific failure and stop. Do NOT ask the user what to do — just tell them what's wrong.

### Step 2: Launch Tests from Claude's CLI

Run both tests directly. Do NOT ask the user to run them. Do NOT output commands for copy-paste.

**Scorer (launch first, background):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/full_t20_e2e_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000 (10 min — Gradle build alone can take 5 min)
```

**Viewer (launch ~60s after scorer, background):**
```
Wait 60 seconds (use: Bash tool with `sleep 60` or equivalent), then:
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test integration_test/full_t20_viewer_e2e_test.dart -d emulator-5556
  - run_in_background: true
  - timeout: 600000
```

**Why 60s delay:** Both tests share `apps/mobile/build/`. Simultaneous launches cause Gradle lock contention. The viewer polls for the `scorer-ready` signal for up to 5 minutes, so a 60s delay is safe.

### Step 3: Monitor & Compare Scores After Each Over

After launching both tests, actively monitor the scorer output and take screenshots to compare both emulators after every over.

**Monitoring loop (run until match completes or tests end):**

0. **Dismiss ANR dialogs** — Every check cycle, run on BOTH emulators to prevent ANR from blocking:
   ```bash
   adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   adb -s emulator-5556 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   ```

1. **Check scorer progress** — Use `TaskOutput` (non-blocking, `block: false`) on the scorer task ID to read output. Look for over completion lines matching: `[innings N] Over X complete`

2. **When a new over completes** — Take screenshots of BOTH emulators side-by-side:
   ```bash
   # Screenshot scorer (emulator-5554)
   adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/scorer_innN_overX.png

   # Screenshot viewer (emulator-5556)
   adb -s emulator-5556 exec-out screencap -p > .playwright-mcp/screenshots/viewer_innN_overX.png
   ```

3. **Read both screenshots** using the Read tool (it can display images) and compare:
   - Score (runs/wickets) matches between scorer and viewer
   - Overs display matches
   - Current batsman/bowler info visible on both

4. **Report to user** after each over comparison:
   ```
   Over X.0 (Inn N) — Scorer: 85/3  |  Viewer: 85/3  ✓ SYNC OK
   ```
   Or if mismatch:
   ```
   Over X.0 (Inn N) — Scorer: 85/3  |  Viewer: 72/2  ✗ SYNC MISMATCH (viewer behind by 13 runs, 1 wicket)
   ```

5. **Timing:** Check every ~30 seconds. An over takes ~30-60s to complete (6 legal deliveries + extras + bowler selection). Don't flood with checks.

6. **Also check viewer output** — Use `TaskOutput` on the viewer task ID. The viewer prints per-over sync reports in the terminal. Cross-reference these with scorer screenshots.

7. **On match completion** — Both tests print final summaries. Read both outputs and present a combined report:
   - Total deliveries scored vs synced
   - DB verification pass/fail
   - Viewer invariant violations (should be 0)
   - Final match result

**Screenshot directory:** Save all screenshots to `.playwright-mcp/screenshots/` (per CLAUDE.md rules).

**ADB path:** If `adb` is not in PATH, use the full path: `C:/Users/itsab/AppData/Local/Android/Sdk/platform-tools/adb.exe`

**Important:** The monitoring loop should NOT block on TaskOutput. Use `block: false` and `timeout: 5000` to check progress without hanging. If no new over detected, wait 30s and check again.

---

## What This Test Does

### Scorer (emulator-5554)
- The automated test launches the CricScores, creates/reuses teams (Mumbai Warriors + Chennai Challengers), sets up a match, completes the toss, then **programmatically taps scoring buttons** for ~240 deliveries across 2 innings
- You see all of this happening live on the emulator screen — buttons being pressed, dialogs opening/closing, score ticking up
- After the match completes, the test verifies every delivery, stat, and result against PostgreSQL

### Viewer (emulator-5556)
- The automated test launches CricScores on the second emulator, navigates to the live match page, and **watches the score update in real-time via WebSocket**
- You see the live match page on this emulator showing the current score, batting/bowling stats, run rates — all updating as the scorer pushes deliveries
- The terminal prints per-over sync reports showing what the viewer received

**End-to-end pipeline verified (dual-path):**
- **Fast path** (~ms): Scorer UI tap -> ScoringNotifier -> ScoringPersistenceService -> `publish_score` WS -> Server relay (zero DB) -> Viewer LiveMatchPage
- **Durable path** (~2s): Scorer UI tap -> ScoringNotifier -> Drift/SQLite -> SyncService (timer: 2s, threshold: 1) -> HTTP POST -> Bun Server -> PostgreSQL -> `match_state` WS broadcast -> Viewer LiveMatchPage

**Scenarios covered:** 12 (Full T20), 13 (Stat Verification + WebSocket Sync), 15 (Scorecard vs DB)

**Total: ~240 deliveries. Runtime: ~30-60 minutes on emulator (+ 2-5 min Gradle build on first run).**

### Sync Architecture (Batch HTTP)

Deliveries are written to local Drift/SQLite first (offline-first), then synced to the server via the `SyncService`:

- **Fast-path WS relay:** After each delivery, `ScoringPersistenceService` sends `publish_score` WS message to server → server relays payload to all room subscribers (zero DB, sub-10ms latency). Independent of the REST sync cycle.
- **Live scoring (< 6 queued):** Individual `POST /deliveries` per ball (SyncService timer: 2s, threshold: 1) → server persists → broadcasts `match_state` reconciliation snapshot (~2s total latency)
- **Backlog sync (>= 6 queued):** `POST /deliveries/batch` sends up to 30 deliveries per chunk in a single DB transaction — server auto-creates missing innings, precomputes sequence numbers, uses `INSERT...ON CONFLICT DO UPDATE` for stats upserts
- **Performance:** Full T20 backlog (254 deliveries) syncs in ~3-8 seconds (was ~5 minutes with per-delivery sync). ~1,440 fewer DB queries per match via `UPDATE...RETURNING`, precomputed free-hit state, and batched stats upserts
- **Silent data loss fix:** Failed sync entries are marked `'failed'` (not `'synced'`), preserving them for retry instead of silently dropping
- **DB verification polling:** Test polls up to 60 seconds (12 attempts x 5s) for delivery count to stabilize, with early exit when count matches

See [SYNC_ARCHITECTURE.md](../../planning/SYNC_ARCHITECTURE.md) for the full decision document.

---

## Coordination Flow (Signal Handshake)

```
1. Scorer boots -> creates teams -> match setup -> toss wizard
2. Scorer POSTs `scorer-ready` signal to POST /api/v1/test/signal/scorer-ready
3. Scorer polls for `viewer-ready` (up to 30s, non-blocking — proceeds without viewer)
4. Viewer boots -> polls GET /api/v1/test/signal/scorer-ready (up to 5 min)
5. Viewer receives scorer-ready -> fetches matchId via GET /api/v1/test/latest-match
6. Viewer navigates to /live/:matchId -> connects WebSocket
7. Viewer POSTs `viewer-ready` signal
8. Scorer begins scoring ~240 random deliveries (20 overs per innings)
9. Viewer monitors ALL WebSocket updates, prints per-over reports
10. Match completes -> both tests report results
```

---

## Test Phases

### Scorer Phases

| Phase | What Happens | Duration |
|-------|-------------|----------|
| 1 | Boot app, land on Home page | ~5s |
| 2 | Create teams (skipped if already exist via smart reset) | 0s or ~90s |
| 3 | Match setup: select Mumbai Warriors + Chennai Challengers, 20 overs, 11 players | ~15s |
| 4 | Toss wizard: Mumbai Warriors wins toss, bats first. Openers: Rohit Sharma (str) + Virat Kohli. Bowler: Deepak Chahar | ~10s |
| 5 | 1st innings (Mumbai Warriors): 20 overs random scoring with `Random(42)` | ~15-25 min |
| 6 | Innings transition: select Chennai openers (Shubman Gill + Yashasvi Jaiswal) + Mumbai bowler (Jasprit Bumrah) | ~10s |
| 7 | 2nd innings (Chennai Challengers): 20 overs random scoring, chasing target | ~15-25 min |
| 8 | Match complete modal | ~5s |
| 9 | DB verification: deliveries, batting/bowling stats, result, awards (polls up to 60s for sync) | ~10-70s |
| 10 | Scorecard vs DB cross-check — navigates to scorecard, verifies player names and stats match DB | ~15s |

### Viewer Phases

| Phase | What Happens | Duration |
|-------|-------------|----------|
| 1 | Boot app, land on Home page (up to 180s on slow device) | ~5-180s |
| 2 | Create Dio client for server communication | instant |
| 3 | Poll for `scorer-ready` signal (up to 5 min) | up to 5 min |
| 4 | Navigate to `/live/:matchId` via GoRouter | ~2s |
| 5 | Wait for WebSocket connection + read initial LiveMatchState (up to 30s) | up to 30s |
| 6 | Monitor all updates — per-over sync reports printed after each over boundary | ~30-60 min |
| 7 | Final summary: update count, innings transitions, FAIL count, match result | instant |

---

## Team Setup

**Team A (Mumbai Warriors) — Bats First:**
| # | Player | Role | Notes |
|---|--------|------|-------|
| 0 | Rohit Sharma | Batter | Opening batter (striker) |
| 1 | Virat Kohli | Batter | Opening batter (non-striker) |
| 2 | Suryakumar Yadav | Batter | |
| 3 | KL Rahul | Batter | |
| 4 | Hardik Pandya | All-Rounder | In bowler rotation pool |
| 5 | Ravindra Jadeja | All-Rounder | In bowler rotation pool |
| 6 | Axar Patel | All-Rounder | In bowler rotation pool |
| 7 | Jasprit Bumrah | Bowler | 2nd innings opening bowler |
| 8 | Mohammed Shami | Bowler | |
| 9 | Yuzvendra Chahal | Bowler | |
| 10 | Rishabh Pant | WK-Batter | |

**Team B (Chennai Challengers) — Bats Second:**
| # | Player | Role | Notes |
|---|--------|------|-------|
| 0 | Shubman Gill | Batter | 2nd innings opening batter (striker) |
| 1 | Yashasvi Jaiswal | Batter | 2nd innings opening batter (non-striker) |
| 2 | Shreyas Iyer | Batter | |
| 3 | Sanju Samson | Batter | |
| 4 | Ravichandran Ashwin | All-Rounder | In bowler rotation pool |
| 5 | Washington Sundar | All-Rounder | In bowler rotation pool |
| 6 | Shardul Thakur | All-Rounder | In bowler rotation pool |
| 7 | Deepak Chahar | Bowler | 1st innings opening bowler |
| 8 | Bhuvneshwar Kumar | Bowler | |
| 9 | Kuldeep Yadav | Bowler | |
| 10 | Ishan Kishan | WK-Batter | |

**Bowler rotation:** 6 bowlers per team (indexes 4-9). Consecutive-over rule enforced — same bowler cannot bowl two overs in a row.

**Smart team reuse:** First run creates teams via UI (~90s). Subsequent runs detect existing teams via `GET /api/v1/test/teams` and skip to match setup (`resetMatchData` instead of `resetDatabase`).

---

## Random Delivery Distribution

Using `Random(42)` (deterministic seed) with weighted probabilities:

| Type | Weight | Probability | UI Action |
|------|--------|-------------|-----------|
| Dot ball | 30 | 30% | `tapRun(tester, 0)` |
| Single | 25 | 25% | `tapRun(tester, 1)` |
| Two | 15 | 15% | `tapRun(tester, 2)` |
| Three | 5 | 5% | `tapRun(tester, 3)` |
| Four | 10 | 10% | `tapRun(tester, 4)` |
| Six | 5 | 5% | `tapRun(tester, 6)` |
| Wicket | 5 | 5% | `tapWicket` -> `selectDismissalType('Bowled')` -> `tapWicketConfirm` |
| Wide | 3 | 3% | `tapExtra(tester, 'WD')` -> `confirmExtra(tester)` |
| No-ball | 2 | 2% | `tapExtra(tester, 'NB')` -> `confirmExtra(tester)` |

**Cricket rules in play:** Wides and no-balls are NOT legal deliveries (don't count toward 6-ball over). Wickets trigger new batter selection (up to 10 wickets = all out). Bowler rotation happens at over boundaries.

---

## DB Verification Checks (Scorer Phase 9)

The scorer waits for batch sync to flush all deliveries before verification. It polls `GET /api/v1/test/deliveries/:matchId` every 5 seconds (up to 60s) until the DB count matches the UI-tracked count or stabilizes for 3 consecutive rounds.

1. **Delivery count** — UI-tracked count == DB delivery count
2. **Delivery fields** — Each delivery: totalRuns, isWide, isNoBall, isWicket, isLegal, overNumber, ballNumber, isBoundaryFour, isBoundarySix
3. **Batting stats** — At least 4 batting records, per-player runs/balls/fours/sixes/notOut (stored via `INSERT...ON CONFLICT DO UPDATE` with UNIQUE constraints on `(innings_id, player_id)`)
4. **Bowling stats** — At least 4 bowling records, per-player overs/runs/wickets/wides/noBalls (same upsert pattern)
5. **Cross-check** — Sum of batting runs per innings vs tracked total; sum of bowling wickets per innings vs tracked wickets
6. **Match result** — Result type, winner, margin, man of match
7. **Match awards** — MOTM and MVP scores computed

---

## Viewer Per-Over Sync Report Format

After every over boundary, the viewer prints:

```
  ┌─── Over 3.0 ── Inn 1 ── Update #18 ───
  │ Score: 24/1 (3.0 ov)
  │ Batting: Mumbai Warriors  vs  Chennai Challengers
  │ CRR: 8.00
  │ Striker:     Virat Kohli        12(8)  4s:1 6s:1  SR:150.0
  │ Non-striker: Suryakumar Yadav   8(6)  4s:0 6s:1
  │ Bowler:      Deepak Chahar      1.0-0-9-0  Econ:9.0
  └──────────────────────────────────────────────
```

In the 2nd innings, also shows target + runs remaining + required run rate:

```
  ┌─── Over 5.0 ── Inn 2 ── Update #78 ───
  │ Score: 52/2 (5.0 ov)
  │ Batting: Chennai Challengers  vs  Mumbai Warriors
  │ CRR: 10.40  |  RRR: 8.93
  │ Target: 186  |  Need: 134 runs
  │ Striker:     Shreyas Iyer       18(14)  4s:2 6s:0  SR:128.6
  │ Non-striker: Sanju Samson       11(8)  4s:1 6s:0
  │ Bowler:      Jasprit Bumrah     2.0-1-6-1  Econ:3.0
  └──────────────────────────────────────────────
```

Special flags displayed when active:
- `** FREE HIT PENDING **`
- `** MAGIC OVER (2x) **`

### Viewer Assertions (all must pass)
- At least 20 WebSocket updates received
- At least 1 innings transition seen
- Max innings number >= 2
- Match completed within monitoring window (65 min)
- 0 invariant violations (FAIL count = 0)

**Late-join handling:** If the viewer joins after match completion (e.g., slow Gradle build), it detects `status == 'completed'` and skips progression assertions — only checks that initial state was received.

---

## Debugging Tips

### Scorer Issues
- **Match stuck on bowler selection?** Check if the next bowler name exists in the Playing XI. `ScenarioTeams.teamBBowlers` has 6 options. The helper tries fallback bowlers and last-resort picks first `ListTile`.
- **Over count mismatch?** Wides and no-balls don't count as legal balls. The random generator tracks `legalBalls` separately from total deliveries.
- **Innings not ending?** Check if all-out happened before 20 overs. Random seed 42 produces deterministic results. The loop checks for `MatchCompleteModal` and `InningsTransitionModal` after every delivery.
- **DB verification fails?** Batch sync chunks deliveries into groups of 30. The test polls up to 60s (12 rounds x 5s). If the server is slow, check `scoring.service.ts` logs for transaction errors. Common cause: UNIQUE constraint violation on stats upserts (fixed in migration `0005_stats_unique_constraints.sql`).
- **Sync count stuck below expected?** SyncService uses batch mode (>= 6 queued deliveries). If the server rejects a batch, all entries in that chunk stay unsynced. Check server logs for `recordDeliveryBatch` errors.
- **Stale bowler/batter sheet blocking scoring?** The `_ensureScoringControlsAccessible` helper auto-dismisses stale `SelectBowlerSheet` and `SelectBatterSheet` before every tap.

### Viewer Issues
- **Viewer never receives scorer-ready signal?** Check server is running. Check scorer terminal for errors. Verify emulator can reach `http://10.0.2.2:3001/api/v1/test/health` in browser.
- **"No match found — is the scorer running?"** Scorer hasn't completed toss wizard yet. Give it more time. Server may have restarted (signals are in-memory via `testSignals` Map).
- **Viewer joins late (match already completed)?** Viewer build took too long. Test handles this gracefully — sets `joinedLate = true`, skips progression assertions, only checks initial state received.
- **Invariant violation (FAIL)?** Runs or wickets decreased within an innings — indicates a WebSocket message ordering bug. Check server `rooms.ts` logs. This is a genuine bug.
- **WebSocket connection fails?** Check server logs for room errors. Verify `/ws` endpoint is running.

### ANR "App Not Responding" on Scorer
- **What:** Android shows "cricapp isn't responding" dialog because `WidgetTester` drives UI intensively on the main thread, making Android think the app is frozen.
- **Auto-dismiss:** Add to monitoring loop: `adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"` every ~30s.
- **Prevention:** Before launching tests, increase ANR timeout on emulator: `adb -s emulator-5554 shell settings put global anr_show_background 0`
- **Impact:** ANR dialog blocks UI taps, causing the test to stall. It also blocks network I/O, causing batch sync failures (`status=null body=null`).

### Batch Sync Failures (status=null)
- **Cause:** `status=null body=null` means the HTTP connection failed before any response — typically caused by ANR blocking network I/O on the emulator, or the server being unreachable.
- **Cause:** `status=500 INTERNAL_ERROR` means the server's batch transaction failed — check server logs for PostgreSQL errors (constraint violations, timeouts).
- **Impact:** Failed batches stay queued and retry on the next sync cycle. The viewer falls behind the scorer until sync catches up.
- **Mitigation:** The SyncService retries failed entries. The viewer test polls for up to 65 minutes, giving plenty of time for sync to recover.

### Viewer Innings Transition Race Condition
- **What:** The WebSocket `score_update` message does NOT include `inningsNumber`. When batch sync catches up and sends 2nd innings data, the viewer sees runs drop (e.g., 175→6) while `inningsNumber` is still 1.
- **Fix:** The viewer test detects "implicit" innings transitions when runs drop significantly (>50% decrease AND wickets decrease).
- **Root cause:** `WsScoreUpdateMessage` lacks `inningsNumber` field. The `WsInningsCompleteMessage` updates it, but may arrive after score updates. This is a known limitation — the test handles it gracefully.

### Shared Issues
- **Gradle lock contention / build failure?** Both emulators share `apps/mobile/build/`. Never launch simultaneously. Wait ~60s between launches.
- **Kill stale dart.exe:** `wmic.exe process where "name='dart.exe'" get processid,commandline` then `taskkill.exe /PID <pid> /F`
- **Server restart clears signals:** The `testSignals` Map is in-memory. If the server restarts mid-test, both scorer and viewer lose their coordination signals. Restart both tests.

---

## Key Files

| File | Purpose |
|------|---------|
| **Test files** | |
| `integration_test/full_t20_e2e_test.dart` | Scorer — 10 phases: boot, teams, setup, toss, 2 innings, DB verify, scorecard |
| `integration_test/full_t20_viewer_e2e_test.dart` | Viewer — 7 phases: boot, signal poll, navigate, WS monitor, assertions |
| `integration_test/helpers/scenario_test_data.dart` | `ScenarioTeams` — team rosters, openers, bowler pools, batter orders |
| `integration_test/helpers/match_flow_helpers.dart` | `tapRun`, `tapExtra`, `tapWicket`, `selectBowler`, `selectBatter`, `playRandomInnings`, `settle`, `visualPause` |
| `integration_test/helpers/server_manager.dart` | `ServerManager` — health check, DB reset, team existence check, API helpers |
| `integration_test/helpers/delivery_record.dart` | `DeliveryRecord` + `MatchRecord` — UI-side delivery tracking for DB comparison |
| `integration_test/helpers/tournament_flow_helpers.dart` | `createTeam`, `addPlayersToRoster`, `completeTossWizard`, `completeMatchSetup`, `completeInningsTransition` |
| `integration_test/helpers/app_test_wrapper.dart` | `AppTestWrapper.pumpApp` / `pumpAppAndWaitForHome` — in-memory Drift DB + ProviderScope |
| `integration_test/helpers/data_generators.dart` | `TeamData`, `PlayerData`, `TournamentConfig` data classes |
| **Sync pipeline (client)** | |
| `lib/src/shared/data/sync/sync_service.dart` | Batch/individual sync logic, `_batchThreshold = 6`, chunking (30/batch) |
| `lib/src/shared/data/database/daos/scoring_dao.dart` | `markSyncFailed()` — entries marked 'failed' not 'synced' |
| **Sync pipeline (server)** | |
| `apps/server/src/services/scoring.service.ts` | `recordDeliveryBatch()` — single-transaction batch processing |
| `apps/server/src/routes/v1/scoring.ts` | `POST /:id/deliveries/batch` endpoint (up to 300 deliveries) |
| `apps/server/src/db/schema/stats.ts` | UNIQUE constraints on `batting_stats`, `bowling_stats` |
| **Viewer** | |
| `lib/src/features/scoring/presentation/notifiers/match_live_notifier.dart` | `LiveMatchState` — viewer state model with striker/nonStriker/bowler snapshots |
| `lib/src/features/scoring/providers.dart` | `matchLiveNotifierProvider` — auto-dispose Riverpod provider |
| `lib/src/shared/data/websocket/ws_message_model.dart` | WS message types: `score_update`, `wicket`, `innings_complete`, `match_complete`, `match_state` |
| **Server test infra** | |
| `apps/server/src/routes/v1/test-verify.routes.ts` | All test endpoints (signals, deliveries, stats, match-result, latest-match, reset-db, reset-match-data) |

---

## Server Test Endpoints Reference

All under `GET/POST /api/v1/test/...` — only available when `NODE_ENV=test`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check (works in any env) |
| `/teams` | GET | List teams with player counts |
| `/latest-match` | GET | Most recently created match ID |
| `/deliveries/:matchId` | GET | All deliveries for a match (ordered by innings + sequence) |
| `/match-stats/:matchId` | GET | Batting + bowling stats per innings with player names |
| `/match-result/:matchId` | GET | Result type, winner, margin, MOTM |
| `/match-awards/:matchId` | GET | MOTM + MVP scores from match_analytics |
| `/signal/:name` | GET | Read coordination signal |
| `/signal/:name` | POST | Set coordination signal (body: `{ value: "true" }`) |
| `/signals` | DELETE | Clear all signals |
| `/reset-db` | POST | Truncate ALL tables + re-seed test user |
| `/reset-match-data` | POST | Truncate match tables only (preserve teams/players) |

---

## Architecture Reference

```
┌──────────────────┐                  ┌──────────────┐    WebSocket Pub    ┌──────────────────┐
│  EMULATOR-5554   │   HTTP Sync      │  BUN SERVER  │ ─────────────────> │  EMULATOR-5556   │
│  (Scorer)        │ ──────────────> │  port 3001   │   score_update      │  (Viewer)        │
│                  │                  │              │   wicket             │                  │
│  Taps scoring UI │  Live (<6):      │  PostgreSQL  │   innings_complete   │  LiveMatchPage   │
│  Random 20-over  │  POST /delivery  │  WebSocket   │   match_complete     │  Per-over reports│
│  match (seed=42) │                  │  rooms       │   match_state        │  Invariant checks│
│                  │  Batch (>=6):    │              │                      │                  │
│  SyncService     │  POST /batch     │  Single DB   │                      │                  │
│  (Drift/SQLite)  │  (30/chunk)      │  transaction │                      │                  │
└──────────────────┘                  └──────────────┘                     └──────────────────┘
                                          │
                                   Both use 10.0.2.2
                                   to reach localhost

Broadcast paths:
  Fast path:     ScoringPersistenceService -> publish_score WS -> server relay (zero DB) -> viewer <10ms
  Live sync:     SyncService (2s timer, threshold=1) -> POST /delivery -> DB persist -> match_state WS ~2s
  Batch backlog: SyncService queues >= 6 entries -> POST /deliveries/batch (30/chunk) -> match_state snapshot
  Full T20 sync: ~254 deliveries in ~9 chunks -> 3-8 seconds total (was ~5 minutes per-delivery)
```
