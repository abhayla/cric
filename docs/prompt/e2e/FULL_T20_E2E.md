# Full T20 E2E Test — Run Prompt

Run this prompt to execute the full T20 E2E test (Scenarios 12, 13, 15) with **scorer + viewer on two devices**.

---

## HOW THIS TEST WORKS — READ THIS FIRST

This is an **AUTOMATED integration test**, not a manual scoring session.

- **You do NOT manually tap scores.** The test code (`WidgetTester`) drives the UI programmatically — it taps run buttons, selects bowlers, confirms wickets, etc. automatically.
- **You WATCH it happen on the devices.** The app launches visually on the device, and you see screens change, buttons get tapped, and scores update in real-time — all driven by code.
- **Scorer device:** You'll see the app boot, authenticate, set up match, complete toss, then rapid-fire scoring — buttons light up, score ticks up, bowler dialogs open and close automatically.
- **Viewer device:** You'll see the app boot, navigate to the live match page, and the score/stats update in real-time as the scorer pushes deliveries through the server via WebSocket.
- **Terminal output:** Both terminals print detailed logs — per-over summaries, delivery tracking, sync reports. The real action is on the device screens + terminal logs.

**First-run timing:** Gradle build takes **2-5 minutes** before anything appears on the device. The terminal will show Gradle output during this time. Be patient — once the app icon appears, scoring starts within ~30 seconds.

---

## EXECUTION INSTRUCTIONS FOR CLAUDE

**DO NOT ask any questions. DO NOT ask for confirmations. DO NOT repeat information the user already provided. Execute immediately.**

**Skip any prerequisite the user has already confirmed** (e.g., "server is already running" = skip server health check). Only check what is unknown.

### Step 1: Quick Prerequisites (only check unknowns)

Only run checks for things the user has NOT already confirmed. Skip silently if already stated.

| Check | Command | Skip if user said |
|-------|---------|-------------------|
| Devices | `flutter devices 2>/dev/null \| grep -E "emulator\|device"` | "devices are running" |
| Server | `curl -s https://cricscores.in/health` | "server is running" |
| Stale processes | `wmic.exe process where "name='dart.exe'" get processid,commandline` | Only check if a previous test run failed |

If a check fails, report the specific failure and stop. Do NOT ask the user what to do — just tell them what's wrong.

### Step 2: Launch Tests from Claude's CLI

Run both tests directly. Do NOT ask the user to run them. Do NOT output commands for copy-paste.

**Scorer (launch first, background):**
```
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554
  - run_in_background: true
  - timeout: 600000 (10 min — Gradle build alone can take 5 min)
```

**Viewer (launch ~60s after scorer, background):**
```
Wait 60 seconds, then:
Bash tool: cd D:/Abhay/VibeCoding/cric/apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/08_viewer_live_test.dart -d <device-id>
  - run_in_background: true
  - timeout: 600000
```

**Why 60s delay:** Both tests share `apps/mobile/build/`. Simultaneous launches cause Gradle lock contention. The viewer polls for the `scorer-ready` signal for up to 5 minutes, so a 60s delay is safe.

### Step 3: Monitor & Compare Scores After Each Over

After launching both tests, actively monitor the scorer output and take screenshots to compare both devices after every over.

**Monitoring loop (run until match completes or tests end):**

0. **Dismiss ANR dialogs** — Every check cycle, run on BOTH devices to prevent ANR from blocking:
   ```bash
   adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   adb -s <device-id> shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"
   ```

1. **Check scorer progress** — Use `TaskOutput` (non-blocking, `block: false`) on the scorer task ID to read output. Look for over completion lines.

2. **When a new over completes** — Take screenshots of BOTH devices:
   ```bash
   adb -s emulator-5554 exec-out screencap -p > .playwright-mcp/screenshots/scorer_innN_overX.png
   adb -s <device-id> exec-out screencap -p > .playwright-mcp/screenshots/viewer_innN_overX.png
   ```

3. **Read both screenshots** using the Read tool and compare scores.

4. **Report to user** after each over comparison:
   ```
   Over X.0 (Inn N) — Scorer: 85/3  |  Viewer: 85/3  SYNC OK
   ```

5. **Timing:** Check every ~30 seconds. An over takes ~30-60s to complete.

6. **On match completion** — Both tests print final summaries. Read both outputs and present a combined report.

**Screenshot directory:** Save all screenshots to `.playwright-mcp/screenshots/` (per CLAUDE.md rules).

**ADB path:** If `adb` is not in PATH, use the full path: `C:/Users/itsab/AppData/Local/Android/Sdk/platform-tools/adb.exe`

---

## What This Test Does

### Scorer
- The automated test launches CricScores, authenticates with Firebase (test phone 9999999999), creates/reuses teams, sets up a match, completes the toss, then **programmatically taps scoring buttons** for ~240 deliveries across 2 innings
- You see all of this happening live on the device screen
- After the match completes, the test verifies the match result is displayed

### Viewer (test 08)
- The automated test launches CricScores on the second device, navigates to the live match page, and **watches the score update in real-time via WebSocket**
- You see the live match page showing current score, batting/bowling stats, run rates — all updating as the scorer pushes deliveries
- The terminal prints per-over sync reports showing what the viewer received

**End-to-end pipeline verified (dual-path):**
- **Fast path** (~ms): Scorer UI tap -> ScoringNotifier -> ScoringPersistenceService -> `publish_score` WS -> Server relay (zero DB) -> Viewer LiveMatchPage
- **Durable path** (~2s): Scorer UI tap -> ScoringNotifier -> Drift/SQLite -> SyncService (timer: 2s, threshold: 1) -> HTTP POST -> Bun Server -> PostgreSQL -> `match_state` WS broadcast -> Viewer LiveMatchPage

**Scenarios covered:** 12 (Full T20), 13 (Stat Verification + WebSocket Sync), 15 (Scorecard vs DB)

**Total: ~240 deliveries. Runtime: ~30-60 minutes on emulator (+ 2-5 min Gradle build on first run).**

### Sync Architecture (Batch HTTP)

Deliveries are written to local Drift/SQLite first (offline-first), then synced to the server via the `SyncService`:

- **Fast-path WS relay:** After each delivery, `ScoringPersistenceService` sends `publish_score` WS message to server -> server relays payload to all room subscribers (zero DB, sub-10ms latency). Independent of the REST sync cycle.
- **Live scoring (< 6 queued):** Individual `POST /deliveries` per ball (SyncService timer: 2s, threshold: 1) -> server persists -> broadcasts `match_state` reconciliation snapshot (~2s total latency)
- **Backlog sync (>= 6 queued):** `POST /deliveries/batch` sends up to 30 deliveries per chunk in a single DB transaction — server auto-creates missing innings, precomputes sequence numbers, uses `INSERT...ON CONFLICT DO UPDATE` for stats upserts
- **Performance:** Full T20 backlog (254 deliveries) syncs in ~3-8 seconds via batch endpoint
- **Silent data loss fix:** Failed sync entries are marked `'failed'` (not `'synced'`), preserving them for retry

See [SYNC_ARCHITECTURE.md](../../planning/SYNC_ARCHITECTURE.md) for the full decision document.

---

## Coordination Flow (Signal Handshake)

```
1. Scorer boots -> authenticates -> creates teams -> match setup -> toss wizard
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

## Random Delivery Distribution

Using `Random(42)` (deterministic seed) with weighted probabilities:

| Type | Weight | Probability | UI Action |
|------|--------|-------------|-----------|
| Dot ball | 30 | 30% | Tap "0" in ScoringControls |
| Single | 25 | 25% | Tap "1" |
| Two | 15 | 15% | Tap "2" |
| Three | 5 | 5% | Tap "3" |
| Four | 10 | 10% | Tap "4" |
| Six | 5 | 5% | Tap "6" |
| Wicket | 5 | 5% | Tap "W" -> select dismissal -> confirm |
| Wide | 3 | 3% | Tap "WD" -> confirm |
| No-ball | 2 | 2% | Tap "NB" -> confirm |

**Cricket rules in play:** Wides and no-balls are NOT legal deliveries (don't count toward 6-ball over). Wickets trigger new batter selection (up to 10 wickets = all out). Bowler rotation happens at over boundaries.

---

## Viewer Per-Over Sync Report Format

After every over boundary, the viewer prints:

```
  +--- Over 3.0 -- Inn 1 -- Update #18 ---
  | Score: 24/1 (3.0 ov)
  | Batting: Mumbai Warriors  vs  Chennai Challengers
  | CRR: 8.00
  | Striker:     Virat Kohli        12(8)  4s:1 6s:1  SR:150.0
  | Non-striker: Suryakumar Yadav   8(6)  4s:0 6s:1
  | Bowler:      Deepak Chahar      1.0-0-9-0  Econ:9.0
  +---------------------------------------------
```

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
- **Match stuck on bowler selection?** Check if the next bowler name exists in the Playing XI. The helper tries fallback bowlers and last-resort picks first `ListTile`.
- **Over count mismatch?** Wides and no-balls don't count as legal balls. The random generator tracks `legalBalls` separately from total deliveries.
- **Innings not ending?** Check if all-out happened before 20 overs. The loop checks for `MatchCompleteModal` and `InningsTransitionModal` after every delivery.

### Viewer Issues
- **Viewer never receives scorer-ready signal?** Check server is running. Check scorer terminal for errors.
- **Viewer joins late (match already completed)?** Test handles this gracefully — sets `joinedLate = true`, skips progression assertions.
- **Invariant violation (FAIL)?** Runs or wickets decreased within an innings — indicates a WebSocket message ordering bug.
- **WebSocket connection fails?** Check server logs for room errors.

### ANR "App Not Responding" on Scorer
- **What:** Android shows "cricapp isn't responding" dialog because `WidgetTester` drives UI intensively.
- **Auto-dismiss:** Add to monitoring loop: `adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"` every ~30s.
- **Impact:** ANR dialog blocks UI taps, causing the test to stall.

### Shared Issues
- **Gradle lock contention / build failure?** Both devices share `apps/mobile/build/`. Never launch simultaneously. Wait ~60s between launches.
- **Kill stale dart.exe:** `wmic.exe process where "name='dart.exe'" get processid,commandline` then `taskkill.exe /PID <pid> /F`

---

## Key Files

| File | Purpose |
|------|---------|
| **Test files** | |
| `integration_test/tests/02_standalone_match_test.dart` | Scorer — standalone match (also used as scorer for dual-device) |
| `integration_test/tests/08_viewer_live_test.dart` | Viewer — WebSocket live monitoring |
| **Core** | |
| `integration_test/core/app_bootstrap.dart` | App launch + Firebase auth |
| `integration_test/core/error_tracker.dart` | Step-by-step progress tracking |
| `integration_test/core/test_utils.dart` | `waitForFinder()`, `waitForFinderGone()`, `testLog()` |
| **Flows** | |
| `integration_test/flows/random_innings.dart` | `playRandomInnings()` — weighted random delivery generation |
| `integration_test/flows/standalone_match_flow.dart` | Full match lifecycle |
| **Helpers** | |
| `integration_test/helpers/scoring.dart` | Tap scoring controls |
| `integration_test/helpers/match_setup.dart` | Match setup + toss wizard |
| `integration_test/helpers/modals.dart` | Dismiss completion/transition modals |
| **Verification** | |
| `integration_test/verification/live_verifier.dart` | Live match WebSocket assertions |
| **Models** | |
| `integration_test/models/delivery_record.dart` | `DeliveryRecord` — UI-side delivery tracking |
| `integration_test/models/match_outcome.dart` | Match result tracking |
| **Sync pipeline (client)** | |
| `lib/src/shared/data/sync/sync_service.dart` | Batch/individual sync logic, `_batchThreshold = 6`, chunking (30/batch) |
| `lib/src/shared/data/database/daos/scoring_dao.dart` | `markSyncFailed()` — entries marked 'failed' not 'synced' |
| **Sync pipeline (server)** | |
| `apps/server/src/services/scoring.service.ts` | `recordDeliveryBatch()` — single-transaction batch processing |
| `apps/server/src/routes/v1/scoring.ts` | `POST /:id/deliveries/batch` endpoint (up to 300 deliveries) |
| **Viewer** | |
| `lib/src/features/scoring/presentation/notifiers/match_live_notifier.dart` | `LiveMatchState` — viewer state model |
| `lib/src/shared/data/websocket/ws_message_model.dart` | WS message types |

---

## Architecture Reference

```
+-----------------+                  +--------------+    WebSocket Pub    +------------------+
|  DEVICE 1       |   HTTP Sync      |  BUN SERVER  | -----------------> |  DEVICE 2        |
|  (Scorer)       | ---------------> |  cricscores  |   score_update     |  (Viewer)        |
|                 |                  |  .in         |   wicket           |                  |
|  Taps scoring UI|  Live (<6):      |              |   innings_complete |  LiveMatchPage   |
|  Random 20-over |  POST /delivery  |  PostgreSQL  |   match_complete   |  Per-over reports|
|  match (seed=42)|                  |  WebSocket   |   match_state      |  Invariant checks|
|                 |  Batch (>=6):    |  rooms       |                    |                  |
|  SyncService    |  POST /batch     |              |                    |                  |
|  (Drift/SQLite) |  (30/chunk)      |  Single DB   |                    |                  |
+-----------------+                  |  transaction |                    +------------------+
                                     +--------------+

Broadcast paths:
  Fast path:     ScoringPersistenceService -> publish_score WS -> server relay (zero DB) -> viewer <10ms
  Live sync:     SyncService (2s timer, threshold=1) -> POST /delivery -> DB persist -> match_state WS ~2s
  Batch backlog: SyncService queues >= 6 entries -> POST /deliveries/batch (30/chunk) -> match_state snapshot
```
