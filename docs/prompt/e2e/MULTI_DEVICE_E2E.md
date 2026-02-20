# Multi-Device E2E Test — Run Prompt

Run this prompt when you want to execute the multi-device WebSocket live match verification test. This test proves the complete real-time broadcast pipeline works across two physical Android devices.

---

## What This Test Does

- **Scorer** (default: emulator): Scores a full predetermined match via UI taps with 2s pauses between deliveries
- **Viewer** (default: real device): Connects via WebSocket, receives live score updates, verifies every field against expected states. Viewer now shows: team names in header, both batter cards with full stats (R/B/4s/6s/SR), bowler card with full stats (O/M/R/W/Ec), non-striker stats updating per delivery, free hit badge, magic over badge, last delivery description banner, wicket notification banner (dismissible), over number, and stat column headers.
- **Pipeline validated**: Scorer UI -> ScoringNotifier -> SyncService -> Server API -> Broadcaster -> WebSocket pub/sub -> LiveMatchPage on viewer

---

## Prerequisites Checklist

Before running, confirm ALL of these:

1. **Android emulator is running** — start one via Android Studio or `emulator -avd <name>`
2. **Real Android device connected via USB** — USB debugging enabled in Developer Options
3. **Same network** — the real device must be on the same Wi-Fi network as the host machine
4. **Windows Firewall** — port 3001 must allow incoming connections (add inbound rule if needed)
5. **Bun server dependencies installed** — `cd apps/server && bun install` (one-time)
6. **Flutter dependencies resolved** — `cd apps/mobile && flutter pub get` (one-time)
7. **PostgreSQL running** — with test database configured in `apps/server/.env`

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

Override LAN IP detection:

```bash
LAN_IP=192.168.1.100 ./scripts/multi-device-e2e.sh
```

The script will:
1. Kill stale integration test processes (dart.exe from previous runs)
2. Detect emulator + real device automatically
3. Detect your LAN IP
4. Start the Bun server if not already running
5. Reset test database + clear coordination signals
6. Launch scorer (default: emulator)
7. Poll for `scorer-ready` signal (up to 5 minutes) instead of hardcoded sleep
8. Wait 5s Gradle grace period after scorer signals ready
9. Launch viewer (default: real device)
10. Wait for both to complete, print combined PASS/FAIL report

---

## Option B: Manual 3-Terminal Approach

```bash
# Terminal 1: Start test server
cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts

# Terminal 2: Start scorer FIRST (on emulator by default)
cd apps/mobile && flutter test integration_test/multi_device_scorer_e2e_test.dart -d emulator-5554

# Terminal 3: Start viewer AFTER scorer's Gradle build finishes (~60s)
cd apps/mobile && flutter test integration_test/multi_device_viewer_e2e_test.dart -d <real-device> \
  --dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1 \
  --dart-define=WS_BASE_URL=ws://<LAN_IP>:3001/ws
```

**Important:** Don't launch both simultaneously — they share `apps/mobile/build/`. Wait for scorer's Gradle build to finish before launching viewer.

---

## Coordination Flow (Signal Handshake)

The scorer and viewer coordinate via in-memory server signals (`POST/GET /api/v1/test/signal/:name`):

```
1. Scorer boots -> creates teams -> match -> toss
2. Scorer POSTs `scorer-ready` signal
3. Scorer polls for `viewer-ready` signal (up to 120s)
4. Viewer boots -> polls for `scorer-ready` signal (up to 180s)
5. Viewer receives scorer-ready -> fetches matchId via `/latest-match`
6. Viewer navigates to LiveMatchPage -> connects WebSocket
7. Viewer POSTs `viewer-ready` signal
8. Scorer sees viewer-ready -> starts scoring 18 deliveries with 2s gaps
9. Viewer monitors WebSocket updates in real-time
10. Both tests complete and report results
```

If the signal endpoints are unavailable, scorer falls back to a 5s wait.

---

## Expected Output

### Scorer logs (look for these in order):
```
[SCORER] Home page loaded
[SCORER] Teams already exist — skipping creation  (or creates them on first run)
[SCORER] Match Setup page
[SCORER] Toss complete — scoring page ready
[SCORER] Signal: scorer-ready posted
[SCORER] Waiting for viewer-ready...
[SCORER] Signal: viewer-ready received
[SCORER] 1.1 -> 4 (Rohit)       Score: 4/0
[SCORER] 1.2 -> 6 (Rohit)       Score: 10/0
... (14 deliveries in 1st innings with 2s gaps) ...
[SCORER] 2.6 -> W Bowled (Hardik) Score: 20/5 ALL OUT
[SCORER] Innings transition complete
[SCORER] 1.1 -> 6 (Dhoni)       Score: 6/0
... (4 deliveries in 2nd innings) ...
[SCORER] 1.4 -> 6 (Dhoni)       Score: 22/0 TARGET CHASED
[SCORER] Match complete. Scorer test PASSED.
```

### Viewer logs (look for these):
```
[VIEWER] Home page loaded
[VIEWER] API base: http://192.168.1.100:3001/api/v1
[VIEWER] Scorer ready signal received
[VIEWER] Found match: <uuid>
[VIEWER] Navigated to LiveMatchPage
[VIEWER] Initial state received: 0/0 (0.0)
[VIEWER] Signal: viewer-ready posted
[VIEWER] Update #1: 4/0 (0.1) Inn1 [Rohit Sharma 4(1)]
... (state updates as deliveries arrive) ...
[VIEWER] Update #14: 20/5 (2.0) Inn1
[VIEWER] Update #15: 6/0 (0.1) Inn2 ** INNINGS 2 **
...
[VIEWER] Update #18: 22/0 (0.4) Inn2 MATCH COMPLETE

┌─────┬──────┬───────┬───────┬──────────┬──────────────────────────┬────────┐
│  #  │ Inn  │ Runs  │ Wkts  │  Overs   │ Striker                  │ Status │
├─────┼──────┼───────┼───────┼──────────┼──────────────────────────┼────────┤
│  1  │  1   │    4  │    0  │      0.1 │ Rohit Sharma             │  PASS  │
... (18 rows) ...
│ 18  │  2   │   22  │    0  │      0.4 │ MS Dhoni                 │  PASS  │
├─────┴──────┴───────┴───────┴──────────┴──────────────────────────┴────────┤
│ PASS: 18 | WARN: 0 | MISS: 0 | FAIL: 0
└──────────────────────────────────────────────────────────────────────────────┘
```

### Status meanings:
- **PASS** — All core fields match (runs, wickets, overs, innings, striker name)
- **WARN** — Core fields match but player names differ (timing artifact, harmless)
- **MISS** — Expected delivery not received (viewer wasn't connected yet, expected if joining mid-match)
- **FAIL** — Core field mismatch (runs/wickets/overs/innings wrong — indicates a real bug)

Only FAIL indicates a WebSocket delivery bug. MISS and WARN are expected timing artifacts.

---

## Troubleshooting

### "No Android emulator detected"
Start an emulator: Android Studio -> Virtual Device Manager -> Play

### "No real Android device detected"
- Check USB cable and USB debugging
- Run `adb devices` — device should show as "device" not "unauthorized"
- If "unauthorized", check the device screen for a USB debugging permission dialog

### Viewer can't connect to server
- Verify the real device can reach the host: on the device, open browser and go to `http://<LAN_IP>:3001/api/v1/test/health`
- Add Windows Firewall inbound rule: `netsh advfirewall firewall add rule name="CricApp E2E" dir=in action=allow protocol=TCP localport=3001`
- Make sure device and host are on the same Wi-Fi network

### Gradle lock contention / build failure
- Both tests share `apps/mobile/build/` — never launch simultaneously
- The script handles this via signal polling + 5s Gradle grace period
- If running manually, wait ~60s after scorer's Gradle build before launching viewer
- Kill stale dart.exe processes: `wmic.exe process where "name='dart.exe'" get processid,commandline` then `taskkill.exe /PID <pid> /F`

### Scorer says "Viewer not ready after 120s — proceeding anyway"
- Viewer build took too long or crashed. Check viewer terminal.
- Scorer will still score, but viewer may miss early deliveries.

### "No match found" on viewer
- Scorer hasn't created the match yet. Check scorer terminal for errors.
- Server might not be running. Check Terminal 1.

### Match state mismatches (WARN/FAIL)
- WARN (core fields match, player names differ) = timing issue where the viewer captured a transitional state. Usually harmless.
- FAIL (core fields differ) = potential WebSocket broadcast bug. Check server logs for errors.

---

## Test Architecture Reference

```
┌─────────────────┐     HTTP/REST      ┌──────────────┐     WebSocket       ┌─────────────────┐
│   DEVICE A       │ ──────────────────>│  BUN SERVER  │──────────────────-->│  DEVICE B        │
│   (Scorer)       │   POST delivery    │  port 3001   │   score_update      │   (Viewer)       │
│                  │                    │              │   wicket             │                  │
│  Taps scoring UI │   Signal:          │  PostgreSQL  │   innings_complete   │  LiveMatchPage   │
│  2s between      │   scorer-ready     │  WebSocket   │   match_complete     │  verifies fields │
│  deliveries      │   viewer-ready     │  pub/sub     │                      │                  │
└─────────────────┘                    └──────────────┘   ws://<LAN_IP>:3001 └─────────────────┘
```

**Files involved:**
- `integration_test/helpers/app_test_wrapper.dart` — `pumpAppAndWaitForHome()` (180s timeout for real device Firebase)
- `integration_test/helpers/server_manager.dart` — Dynamic `baseUrl` resolution (dart-define or 10.0.2.2)
- `integration_test/helpers/expected_match_states.dart` — 18 pre-computed expected states
- `integration_test/multi_device_scorer_e2e_test.dart` — Scorer test (bidirectional handshake)
- `integration_test/multi_device_viewer_e2e_test.dart` — Viewer test (signal polling + MISS/FAIL tracking)
- `integration_test/single_match_e2e_test.dart` — Also posts scorer-ready signal (can be used as scorer)
- `scripts/multi-device-e2e.sh` — Orchestrator script (stale cleanup, SWAP_DEVICES, signal polling)
- `apps/server/src/routes/v1/test-verify.routes.ts` — Signal endpoints (`POST/GET /signal/:name`, `DELETE /signals`)

**Match scenario:** Mumbai Lions vs Chennai Kings, 5 overs, 6 players/side. 1st innings: ALL OUT 20/5 in 2.0 overs (includes wide, no-ball, free hit, 5 wickets). 2nd innings: target chased 22/0 in 0.4 overs. Result: Chennai Kings won by 5 wickets.
