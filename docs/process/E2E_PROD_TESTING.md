# Prod E2E Testing Strategy

Pre-release validation against the production server on real devices. Run infrequently — only before publishing APKs or after infrastructure changes.

## Goals

- **Validate the full stack:** Cloudflare → Nginx → Bun → PostgreSQL on VPS
- **Real device testing:** Touch input, screen sizes, Android versions, network conditions
- **Multi-device WebSocket:** Scorer + viewer on separate physical devices
- **Confidence gate:** Must pass before any APK release to testers/Play Store

## Architecture

```
Real Devices
├── Device 1 (Scorer): OnePlus EB2101 / OPPO CPH2691
├── Device 2 (Viewer): The other device
└── Both connect to cricscores.in (prod server)

Production Stack
├── Cloudflare (SSL termination, CDN)
├── Nginx (reverse proxy, port 80)
├── Bun + ElysiaJS (port 3005)
└── PostgreSQL 16.8 (cricscores DB)
```

## When to Run

| Trigger | Which tests |
|---------|------------|
| Before APK release | Full suite (all tests) |
| After VPS/server deploy | Smoke + standalone match (01 → 02) |
| After Nginx/Cloudflare change | Smoke + multi-device (01 → 02 → 08) |
| After scoring engine changes | Standalone match + one tournament (01 → 02 → 04) |
| After WebSocket changes | Multi-device test (01 → 08) |

## Test Suite

### Current Tests (Ordered, Sequential)

Tests run against shared prod server state and **must execute in order:**

| # | Test | Duration | Dependencies | What it validates |
|---|------|----------|-------------|-------------------|
| 01 | Team Setup | ~5 min | None | Create 12 teams × 11 players (idempotent) |
| 02 | Standalone Match | ~10 min | 01 | Full match: setup, toss, scoring, undo, target chase |
| 03 | Verify After Match | ~2 min | 01, 02 | My Cricket tabs show correct data post-match |
| 04 | Tournament GK | ~45 min | 01 | Group+Knockout: 8 teams, 2 groups, ~15 matches |
| 05 | Tournament KO | ~20 min | 01 | Knockout: 8 teams, 7 matches |
| 06 | Tournament RR | ~15 min | 01 | Round Robin: 4 teams, 6 matches |
| 07 | Verify All Screens | ~3 min | 01-06 | Full screen sweep: Teams, Matches, Tournaments, Live, Updates |
| 08 | Viewer Live | ~10 min | 01 | Multi-device WebSocket: scorer + viewer real-time sync |
| 09 | Player Profile | ~3 min | 01, 02 | Profile page via More tab + direct navigation |
| perf | Performance | ~3 min | None | 5-over match with timing instrumentation |

**Total wall time:** ~2 hours (sequential, single device except 08)

### Recommended Run Order

**Quick validation (before minor releases):** 01 → 02 → 03 → 09
**Full validation (before major releases):** 01 → 02 → 03 → 09 → 04 → 05 → 06 → 07 → 08

## Execution

### Single-Device Tests (01-07, 09)

```bash
cd apps/mobile

# Run individual test
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/tests/01_team_setup_test.dart -d <device-id>

# Run in sequence (recommended order)
for test in 01_team_setup 02_standalone_match 03_verify_after_match \
            09_player_profile 04_tournament_gk 05_tournament_ko \
            06_tournament_rr 07_verify_all_screens; do
  echo "=== Running $test ==="
  flutter test --flavor prod --dart-define=FLAVOR=prod \
    integration_test/tests/${test}_test.dart -d <device-id>
done
```

### Multi-Device Test (08)

**Option A: Orchestration script (automated)**
```bash
./scripts/multi-device-e2e.sh
# Auto-detects emulator + real device, launches scorer then viewer
# Set SWAP_DEVICES=1 to swap roles
```

**Option B: Manual two-terminal (more control)**
```bash
# Terminal 1: Scorer on emulator
flutter test --flavor prod --dart-define=FLAVOR=prod \
  --dart-define=ROLE=scorer \
  integration_test/tests/08_viewer_live_test.dart -d emulator-5554

# Terminal 2: Viewer on real device (wait for "scorer-ready" signal)
flutter test --flavor prod --dart-define=FLAVOR=prod \
  --dart-define=ROLE=viewer \
  integration_test/tests/08_viewer_live_test.dart -d <device-id>
```

### Performance Test

```bash
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/tests/perf_basic_test.dart -d emulator-5554
```

## Devices

| Device | ID | Android | Role |
|--------|-----|---------|------|
| OPPO CPH2691 | `843773fe` | 16 | Scorer or Viewer |
| OnePlus EB2101 | `f7d1d240` | 13 | Scorer or Viewer |
| Emulator (Resizable) | `emulator-5554` | varies | Dev testing, perf |

Check connected devices:
```bash
flutter devices
# or
adb devices
```

## Test Accounts

| Role | Phone | OTP | Purpose |
|------|-------|-----|---------|
| Scorer | `9999999999` | `123456` | Creates and scores matches |
| Viewer (Abhay) | `9999999998` | `123456` | Views matches on second device |

Both are Firebase test phone numbers configured in project `cricapp-7403d`. Abhay must be on at least one team's roster in every test match for live viewing.

## Known Issues & Constraints

### Latency
- API calls to `cricscores.in`: ~0.6-1.4s each (Cloudflare → Nginx → Bun → PG)
- Player creation: 132 players × ~1s = ~2-3 min for team setup (idempotent, skips existing)
- Each delivery: ~1.5-1.8s (REST sync + WS broadcast)

### State Persistence
- Prod DB retains all test data across runs — teams, matches, tournaments accumulate
- `ensureTeamsExist` is idempotent (checks via API, deletes/recreates if roster count is wrong)
- No `reset-match-data` on prod — old matches/tournaments remain visible
- Tournament names use random suffixes to avoid collisions across runs

### Device Connectivity
- USB debugging must be enabled on real devices
- Devices may disconnect mid-test (especially OPPO) — reconnect and re-run from current test
- Multi-device test requires both devices on same network
- Windows Firewall must allow the signal server port

### Timeouts
| Test | Timeout |
|------|---------|
| 01 Team Setup | 60 min |
| 02 Standalone Match | 30 min |
| 03 Verify | 10 min |
| 04 Tournament GK | 3 hours |
| 05 Tournament KO | 3 hours |
| 06 Tournament RR | 3 hours |
| 07 Verify All | 15 min |
| 08 Multi-device | 30 min (each role) |
| 09 Player Profile | 15 min |

### Animation Gotcha
**Never use `tester.pumpAndSettle()` in integration tests.** `PulsingLiveDot` and `SyncStatusIndicator` have infinite repeating animations that prevent settling. Always use `settle(tester)` from `core/test_utils.dart` (pumps 10×100ms frames).

## Failure Investigation

When a test fails on prod:

1. **Check device connectivity:** `adb devices` — device may have disconnected
2. **Check server health:** `curl https://cricscores.in/api/v1/test/health`
3. **Check PM2 status:** RDP into VPS → `pm2 status` → check for crashed processes
4. **Check logs:** `pm2 logs cricscores --lines 50` on VPS
5. **Re-run the failing test alone** — transient network issues are common
6. **If scoring fails:** Compare delivery count in test output with server DB
7. **If multi-device fails:** Check Windows Firewall, verify both devices can reach the signal endpoint

## Relationship to Dev E2E

| Aspect | Dev E2E | Prod E2E |
|--------|---------|----------|
| Server | Local Bun (port 3001) | cricscores.in (VPS) |
| Database | Local test DB | Production PostgreSQL |
| API latency | ~5ms | ~600-1400ms |
| Data seeding | API calls (fast) | UI-driven (slow, idempotent) |
| Frequency | Every code change | Pre-release only |
| Devices | Emulator only | Real devices + emulator |
| Multi-device | Not needed | Test 08 |
| State cleanup | `reset-match-data` | Accumulates |
| Random seeds | Fixed (`Random(42)`) | Random (prod-realistic) |
| CI-runnable | Yes (headless emulator) | No (needs physical devices) |

Dev E2E catches logic bugs fast. Prod E2E validates the full deployment stack and real-world device behavior.
