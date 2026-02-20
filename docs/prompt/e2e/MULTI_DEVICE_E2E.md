# Multi-Device E2E Test — Run Prompt

Run this prompt when you want to execute the multi-device WebSocket live match verification test. This test proves the complete real-time broadcast pipeline works across two physical Android devices.

---

## What This Test Does

- **Scorer** (emulator): Scores a full predetermined match via UI taps with 2s pauses between deliveries
- **Viewer** (real device): Connects via WebSocket, receives live score updates, verifies every field against expected states
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

The script will:
1. Detect emulator + real device automatically
2. Detect your LAN IP (override with `LAN_IP=x.x.x.x ./scripts/multi-device-e2e.sh`)
3. Start the Bun server if not already running
4. Reset test database
5. Launch scorer on emulator
6. Wait 15s, then launch viewer on real device
7. Print combined PASS/FAIL report

---

## Expected Output

### Scorer logs (look for these in order):
```
[SCORER] Home page loaded
[SCORER] Teams already exist — skipping creation  (or creates them on first run)
[SCORER] Match Setup page
[SCORER] Toss complete — scoring page ready
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
[VIEWER] Found match: <uuid>
[VIEWER] Navigated to LiveMatchPage
[VIEWER] Initial state received: 4/0 (0.1)
[VIEWER] Update #2: 10/0 (0.2) Inn1 [Rohit Sharma 10(2)]
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
│ PASS: 18 | WARN: 0 | FAIL: 0
└──────────────────────────────────────────────────────────────────────────────┘
```

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

### Viewer misses early deliveries
- This is OK — the viewer uses flexible matching and only requires 10+ of the 18 updates
- For better coverage, increase the scorer's initial wait (edit `_deliveryPauseMs` or the 5s viewer-connect wait in the scorer test)

### "No match found within 120s"
- Scorer hasn't created the match yet. Check scorer terminal for errors.
- Server might not be running. Check Terminal 1.

### Match state mismatches (WARN/FAIL)
- WARN (core fields match, player names differ) = timing issue where the viewer captured a transitional state. Usually harmless.
- FAIL (core fields differ) = potential WebSocket broadcast bug. Check server logs for errors.

---

## Test Architecture Reference

```
┌─────────────────┐     HTTP/REST      ┌──────────────┐     WebSocket       ┌─────────────────┐
│   EMULATOR       │ ──────────────────>│  BUN SERVER  │──────────────────-->│  REAL DEVICE     │
│   (Scorer)       │   POST delivery    │  port 3001   │   score_update      │   (Viewer)       │
│                  │                    │              │   wicket             │                  │
│  Taps scoring UI │   10.0.2.2:3001   │  PostgreSQL  │   innings_complete   │  LiveMatchPage   │
│  2s between      │                    │  WebSocket   │   match_complete     │  verifies fields │
│  deliveries      │                    │  pub/sub     │                      │                  │
└─────────────────┘                    └──────────────┘   ws://<LAN_IP>:3001 └─────────────────┘
```

**Files involved:**
- `integration_test/helpers/expected_match_states.dart` — 18 pre-computed expected states
- `integration_test/multi_device_scorer_e2e_test.dart` — Scorer test (emulator)
- `integration_test/multi_device_viewer_e2e_test.dart` — Viewer test (real device)
- `scripts/multi-device-e2e.sh` — Orchestrator script

**Match scenario:** Mumbai Lions vs Chennai Kings, 5 overs, 6 players/side. 1st innings: ALL OUT 20/5 in 2.0 overs (includes wide, no-ball, free hit, 5 wickets). 2nd innings: target chased 22/0 in 0.4 overs. Result: Chennai Kings won by 5 wickets.
