---
name: multi-device-e2e
description: "Run the two-device scorer/viewer E2E test via scripts/multi-device-e2e.sh and triage its failures. Use when the user says 'run multi-device e2e', 'run the two-device test', 'test live viewer', 'scorer/viewer test', or after changing WebSocket live-update or signal-endpoint code."
type: workflow
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[--swap] [--prod]"
version: "1.0.0"
synthesized: true
private: false
---

# Multi-Device E2E (scorer + viewer)

Orchestrate `08_viewer_live_test.dart` across two Android devices: a scorer
that scores a full predetermined match and a viewer that verifies live
WebSocket updates. The script handles device assignment, LAN IP injection,
server startup, signal-based sequencing, and the combined report.

## STEP 1: Preflight

1. Server: the script auto-starts the Bun server (`PORT=3001 NODE_ENV=test bun
   run src/index.ts` in `apps/server/`) if `http://localhost:3001/api/v1/test/health`
   is not healthy. If a server is already running, verify it was started with
   `NODE_ENV=test` — signal endpoints do not exist otherwise:
   ```bash
   curl -s http://localhost:3001/api/v1/test/signal/scorer-ready
   ```
   A 404 on `/api/v1/test/*` against a running server means wrong NODE_ENV —
   restart it in test mode rather than proceeding.
2. Devices: `flutter devices` MUST list BOTH an Android emulator (e.g.,
   `emulator-5554`) and a real device (USB debugging on) or second emulator.
   The script exits 1 if either is missing (lines 166-173).
3. Network (real device runs): device and host on the same network; Windows
   Firewall MUST allow inbound port 3001.

## STEP 2: Invoke

```bash
bash scripts/multi-device-e2e.sh
```

Environment switches (verified against the script):

| Switch | Effect |
|--------|--------|
| `SWAP_DEVICES=1` | Scorer on real device, viewer on emulator (default is the reverse) — lines 213-239 |
| `FLAVOR=prod` | Prod mode against cricscores.in (adds `--dart-define=FLAVOR=prod`) — use for the `--prod` argument |
| `LAN_IP=192.168.x.x` | Override LAN IP auto-detection |

What the script does for you — do NOT duplicate manually:
- Detects devices via `flutter devices --machine`, with an `adb devices`
  fallback (lines 128-164).
- Auto-detects the host LAN IP via `ipconfig.exe` (Git Bash/Windows), then
  `ip route`, then `hostname -I` (lines 180-204), and injects
  `--dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1` and
  `WS_BASE_URL=ws://<LAN_IP>:3001/ws` into the REAL-device role only — the
  emulator role keeps the default `10.0.2.2` (lines 213-239).
- Resets match data (`POST /api/v1/test/reset-match-data`) and clears stale
  signals (`DELETE /api/v1/test/signals`) before launching (lines 280-282).
- Kills stale `dart.exe`/dart integration_test processes from crashed runs.

## STEP 3: Monitor

1. The script launches the scorer first, then polls
   `GET /api/v1/test/signal/scorer-ready` every 2s for up to 5 minutes
   (lines 300-335). It exits 1 if the scorer process dies or never signals.
2. After `scorer-ready`, it waits a 5s grace period so the Gradle daemon
   releases locks before the viewer build starts (lines 337-339), then
   launches the viewer.
3. Output is interleaved with `[scorer]` / `[viewer]` prefixes. To watch the
   handshake yourself while it runs:
   ```bash
   curl -s http://localhost:3001/api/v1/test/signal/viewer-ready
   curl -s http://localhost:3001/api/v1/test/signal/score-match-complete
   ```
4. The run ends with a combined PASSED/FAILED report and exits non-zero if
   either role failed. Expect 10-20 minutes total (Gradle builds dominate).

## STEP 4: Failure triage

Work through these in order — they cover the recurring failure modes:

1. **Stale signals** (viewer starts "already ready", or scorer proceeds
   immediately): `curl -X DELETE http://localhost:3001/api/v1/test/signals`
   and rerun. The script does this at startup, but a manually launched test
   half can leave signals behind mid-run.
2. **Wrong LAN IP** (real device times out at `pumpAppAndWaitForHome`, server
   logs show no requests from the device): rerun with `LAN_IP=<correct-ip>`.
   Verify from the device's browser: `http://<LAN_IP>:3001/api/v1/health`.
3. **Gradle daemon contention** (viewer build fails with lock errors right
   after the scorer build): the 5s grace period usually covers this; if it
   recurs, run `cd apps/mobile/android && ./gradlew --stop` and rerun.
4. **Device-id mismatch** (script picks the wrong device, or exits "No real
   Android device detected"): run `flutter devices` and `adb devices`,
   reconnect USB / restart adb (`adb kill-server && adb start-server`).
5. **Viewer fails `Scorer not ready after 300s`**: read the `[scorer]` lines
   — the scorer crashed before posting `scorer-ready`; fix that first, the
   viewer failure is downstream.
6. For test-logic failures (not orchestration), read
   `apps/mobile/integration_test/tests/08_viewer_live_test.dart` and follow
   the `e2e-signal-handshake` and `e2e-interaction-gotchas` rules in
   `.claude/rules/`.

## CRITICAL RULES

- MUST run against a `NODE_ENV=test` server — signal and reset endpoints do
  not exist otherwise; never point this workflow at prod data expecting them.
- MUST use `bash scripts/multi-device-e2e.sh` rather than launching the two
  `flutter test` halves by hand — manual launches skip the data reset, signal
  clear, LAN IP injection, and Gradle grace period.
- MUST NOT hardcode LAN IPs in test files; use the `LAN_IP=` override.
- MUST treat a viewer failure after a scorer failure as downstream — triage
  the scorer first.
- SHOULD pass `SWAP_DEVICES=1` (the `--swap` argument) to reproduce
  role-specific issues on the other device class.
