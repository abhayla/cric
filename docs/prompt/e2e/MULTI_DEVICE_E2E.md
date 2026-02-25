# Multi-Device E2E Test — Run Prompt

Run this prompt when you want to execute the multi-device WebSocket live match verification test. This test proves the complete real-time broadcast pipeline works across two Android devices.

---

## What This Test Does

- **Scorer** (default: emulator): Scores a match via `02_standalone_match_test.dart` with UI taps and 2s pauses between deliveries
- **Viewer** (default: real device or second emulator): Runs `08_viewer_live_test.dart` — connects via WebSocket, receives live score updates, verifies every field against expected states. Viewer shows: team names in header, batter cards with full stats, bowler card, free hit badge, wicket notifications, and over-by-over sync reports.
- **Pipeline validated (dual-path):**
  - **Fast path** (~ms): Scorer UI -> ScoringNotifier -> ScoringPersistenceService -> `publish_score` WS message -> Server relay (zero DB) -> LiveMatchPage on viewer
  - **Durable path** (~2s): Scorer UI -> ScoringNotifier -> Drift/SQLite -> SyncService (timer: 2s, threshold: 1; batch >= 6: `POST /deliveries/batch`) -> Server persists -> `match_state` broadcast -> LiveMatchPage on viewer

---

## Prerequisites Checklist

Before running, confirm ALL of these:

1. **Android emulator is running** — start one via Android Studio or `emulator -avd <name>`
2. **Real Android device connected via USB** (or second emulator) — USB debugging enabled
3. **Same network** — the real device must be on the same Wi-Fi network as the host machine
4. **Prod server is live** at `cricscores.in`
5. **Teams already created** — run test 01 first (`01_team_setup_test.dart`)
6. **Flutter dependencies resolved** — `cd apps/mobile && flutter pub get`
7. **Firebase test phone numbers configured** — In Firebase Console:
   - `+919999999999` — used by the **scorer** device (OTP: `123456`)
   - `+919999999998` — used by the **viewer** device (OTP: `123456`)

---

## Option A: Automated (Recommended)

Run the orchestrator script which handles everything:

```bash
./scripts/multi-device-e2e.sh
```

To swap device roles (scorer on real device, viewer on emulator):

```bash
SWAP_DEVICES=1 ./scripts/multi-device-e2e.sh
```

The script will:
1. Kill stale integration test processes
2. Detect emulator + real device automatically
3. Launch scorer test first
4. Poll for `scorer-ready` signal
5. Launch viewer test after scorer signals ready
6. Wait for both to complete, print combined PASS/FAIL report

---

## Option B: Manual 2-Terminal Approach

```bash
# Terminal 1: Start scorer on emulator
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554

# Terminal 2: Start viewer AFTER scorer's Gradle build finishes (~60s)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/08_viewer_live_test.dart -d <device-id>
```

**Important:** Don't launch both simultaneously — they share `apps/mobile/build/`. Wait for scorer's Gradle build to finish before launching viewer.

---

## Coordination Flow (Signal Handshake)

The scorer and viewer coordinate via server signal endpoints (`POST/GET /api/v1/test/signal/:name`):

```
1. Scorer boots -> authenticates -> creates match -> toss
2. Scorer POSTs `scorer-ready` signal
3. Scorer polls for `viewer-ready` signal (up to 120s)
4. Viewer boots -> polls for `scorer-ready` signal (up to 180s)
5. Viewer receives scorer-ready -> fetches matchId via `/latest-match`
6. Viewer navigates to LiveMatchPage -> connects WebSocket
7. Viewer POSTs `viewer-ready` signal
8. Scorer sees viewer-ready -> starts scoring deliveries with 2s gaps
9. Viewer monitors WebSocket updates in real-time
10. Both tests complete and report results
```

If the signal endpoints are unavailable, scorer falls back to a 5s wait.

---

## Expected Output

### Scorer logs (look for these in order):
```
[SCORER] Home page loaded
[SCORER] Match Setup page
[SCORER] Toss complete — scoring page ready
[SCORER] Signal: scorer-ready posted
[SCORER] Waiting for viewer-ready...
[SCORER] Signal: viewer-ready received
[SCORER] Scoring deliveries...
[SCORER] Match complete. Scorer test PASSED.
```

### Viewer logs (look for these):
```
[VIEWER] Home page loaded
[VIEWER] Scorer ready signal received
[VIEWER] Found match: <uuid>
[VIEWER] Navigated to LiveMatchPage
[VIEWER] Initial state received
[VIEWER] Signal: viewer-ready posted
[VIEWER] Update #1: score update received
...
[VIEWER] Match complete. PASS: N | WARN: 0 | MISS: 0 | FAIL: 0
```

### Status meanings:
- **PASS** — All core fields match (runs, wickets, overs, innings, striker name)
- **WARN** — Core fields match but player names differ (timing artifact, harmless)
- **MISS** — Expected delivery not received (viewer wasn't connected yet)
- **FAIL** — Core field mismatch (runs/wickets/overs wrong — indicates a real bug)

---

## Troubleshooting

### "No Android emulator detected"
Start an emulator: Android Studio -> Virtual Device Manager -> Play

### "No real Android device detected"
- Check USB cable and USB debugging
- Run `adb devices` — device should show as "device" not "unauthorized"
- If "unauthorized", check the device screen for USB debugging permission dialog

### Viewer can't connect to server
- Verify the real device can reach the server: open browser on device and go to `https://cricscores.in/health`
- All tests use the prod server at `cricscores.in`, so no LAN connectivity needed

### Gradle lock contention / build failure
- Both tests share `apps/mobile/build/` — never launch simultaneously
- Wait ~60s after scorer's Gradle build before launching viewer
- Kill stale dart.exe: `wmic.exe process where "name='dart.exe'" get processid,commandline`

### Scorer says "Viewer not ready after 120s — proceeding anyway"
- Viewer build took too long or crashed. Check viewer terminal.
- Scorer will still score, but viewer may miss early deliveries.

### Match state mismatches (WARN/FAIL)
- WARN = timing issue, harmless
- FAIL = potential WebSocket broadcast bug. Check server logs.

---

## Key Files

| File | Purpose |
|------|---------|
| `integration_test/tests/02_standalone_match_test.dart` | Scorer test (also posts scorer-ready signal) |
| `integration_test/tests/08_viewer_live_test.dart` | Viewer test (signal polling + live verification) |
| `integration_test/core/app_bootstrap.dart` | App launch + Firebase auth |
| `integration_test/core/test_utils.dart` | `waitForFinder()`, `waitForFinderGone()` |
| `integration_test/verification/live_verifier.dart` | Live match WebSocket assertions |
| `integration_test/helpers/scoring.dart` | Tap scoring controls |
| `integration_test/helpers/match_setup.dart` | Match setup + toss wizard |
| `scripts/multi-device-e2e.sh` | Orchestrator script (SWAP_DEVICES, signal polling) |
| `lib/src/shared/data/sync/sync_service.dart` | Batch/individual sync logic |
| `lib/src/shared/data/websocket/ws_message_model.dart` | WS message types |

---

## Architecture Reference

```
+-----------------+                  +--------------+    WebSocket Pub    +------------------+
|  DEVICE A       |   HTTP Sync      |  BUN SERVER  | -----------------> |  DEVICE B        |
|  (Scorer)       | ---------------> | cricscores.in|   score_update     |  (Viewer)        |
|                 |                  |              |   wicket           |                  |
|  Taps scoring UI|  SyncService     |  PostgreSQL  |   innings_complete |  LiveMatchPage   |
|  via WidgetTest |  timer: 2s       |  WebSocket   |   match_complete   |  verifies fields |
|                 |                  |  pub/sub     |   match_state      |                  |
|  Drift/SQLite   |  Live (<6):      |              |                    |                  |
|  local first    |  POST /delivery  |              |                    |                  |
|                 |  Batch (>=6):    |              |                    |                  |
|                 |  POST /batch     |              |                    |                  |
+-----------------+                  +--------------+                    +------------------+

Broadcast paths:
  Fast path:     ScoringPersistenceService -> publish_score WS -> server relay (zero DB) -> viewer <10ms
  Durable path:  SyncService -> REST POST -> DB persist -> match_state WS broadcast -> viewer ~2s
```
