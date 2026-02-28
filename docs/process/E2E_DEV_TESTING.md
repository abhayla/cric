# Dev/Local E2E Testing Strategy

Fast, frequent end-to-end testing against a local server for daily development.

## Goals

- **Fast feedback:** Full critical-path E2E in under 2 minutes
- **Reproducible:** Fixed random seeds, clean DB state per run
- **Independent:** Tests can run in any order or in parallel
- **CI-ready:** Runs headlessly on emulator without manual setup

## Architecture

```
Developer Machine
├── Local Bun Server (port 3001, test DB, NODE_ENV=test)
│   ├── REST API (http://localhost:3001)
│   ├── WebSocket server (ws://localhost:3001)
│   └── Signal endpoints (/api/v1/test/signal/:name)
├── Scorer Emulator (emulator-5554)
│   └── Flutter app (--flavor dev) → 10.0.2.2:3001
├── Viewer Emulator 1 (emulator-5556)  [optional]
│   └── Flutter app (--flavor dev) → 10.0.2.2:3001
├── Viewer Emulator N (emulator-5558+) [optional]
│   └── Flutter app (--flavor dev) → 10.0.2.2:3001
└── Flutter integration tests
```

- Local server with `NODE_ENV=test` and `ENABLE_TEST_AUTH=true`
- Separate test database (`cricapp_dev` or dedicated `cricapp_e2e_test`)
- `reset-match-data` endpoint clears state between test files
- Signal endpoints (`POST/GET /api/v1/test/signal/:name`) for multi-emulator coordination
- No network hops (Cloudflare/Nginx bypassed) — ~5ms vs ~1s per API call
- All emulators reach host at `10.0.2.2:3001` (Android's host loopback alias)

## Test Data Strategy

### UI-Driven Data Entry (Mandatory)

**All E2E test data must be created through the UI** — tapping buttons, filling forms, navigating screens — exactly as a real user would. No direct API calls (`Dio`, `http`) for creating teams, players, matches, or tournaments.

**Why:** E2E tests validate the full stack from user interaction to server persistence. Bypassing the UI with API calls defeats the purpose — it leaves form validation, navigation flows, error handling, and UI state management untested. A passing E2E test should prove that a real user can complete the workflow end-to-end.

**What this means:**
- Team creation → use `createTeam(tester, ...)` helper (taps "Create Team", fills form, submits)
- Player creation → use `fillAndSubmitPlayer(tester, ...)` helper (fills player form, waits for API response)
- Match creation → use match setup wizard flow (select teams, configure overs, etc.)
- Tournament creation → use `createTournament(tester, preset, name)` helper
- Toss → use `completeToss(tester, ...)` helper

**Existing helpers** in `integration_test/helpers/` already implement UI-driven flows for teams, players, matches, tournaments, toss, and scoring. Use them.

**Exception:** Signal endpoints (`POST/GET /api/v1/test/signal/:name`) for multi-device coordination are allowed — they are test infrastructure, not data creation.

### Fixed Random Seeds

All random scoring must use deterministic seeds:

```dart
// GOOD — reproducible
final rng = Random(42);

// BAD — different every run
final rng = Random();
```

Tournament name generation should also be deterministic or sequential (not `Random().nextInt(99999)`).

### Viewer Phone Pool

All `9999999XXX` phones are Firebase test numbers (OTP: `123456`). Any roster player can log in as a viewer — the full pool of 132+ player phones is available as viewer accounts.

| Role | Phone | Account | Notes |
|------|-------|---------|-------|
| Scorer | `9999999999` | Dedicated scorer | Creates and scores matches |
| Viewer (Abhay) | `9999999998` | Dedicated viewer | Used for manual viewing |
| Spectator | `9999999997` | Pure spectator | NOT on any team — public discovery testing |
| Viewer (Player301) | `9999999301` | Player301, Team1 roster | Team-member viewer tests |
| Non-playing viewer | `9999999401` | Player401, Team4 | On team NOT in match — non-team viewer tests |
| Any player | `9999999XXX` | Player{XXX} | Any player phone works as viewer |

**Public discovery:** The Live tab shows ALL live matches to any authenticated user (no team membership required). My Cricket filters by user's teams. Any test phone can discover any live match via the Live tab.

### Clean State Per Run

Before each test file:
1. Call `POST /api/v1/test/reset-match-data` to clear matches/tournaments
2. Teams and players persist across runs (idempotent creation)
3. Each test file is self-contained — creates its own teams if needed

## Test Suite Structure

### Tier 1: Smoke Test (~2 min) — Run on Every Change

Single test file that validates the critical path:

```
smoke_test.dart
├── Create 2 teams × 3 players (UI)
├── Create match (UI) — match setup wizard
├── Complete toss (UI)
├── Score 1 over per innings (6 legal deliveries each)
├── Complete match
├── Verify scorecard shows correct totals
└── Verify match appears in My Cricket → Matches tab
```

**Run command:**
```bash
cd apps/mobile && flutter test --flavor dev \
  integration_test/tests/smoke_test.dart -d emulator-5554
```

### Tier 2: Feature Tests (~5-10 min each) — Run Before Push

Independent tests, each seeds its own data:

| Test | What it validates | Teams needed |
|------|-------------------|--------------|
| `match_scoring_test.dart` | Full match with undo, extras, wickets, target chase | 2 × 6 players |
| `tournament_gk_test.dart` | Group+Knockout tournament lifecycle | 4 × 6 players |
| `tournament_ko_test.dart` | Knockout tournament lifecycle | 4 × 6 players |
| `tournament_rr_test.dart` | Round Robin tournament lifecycle | 4 × 6 players |
| `player_profile_test.dart` | Profile page, format chips, stats | Existing from match test |
| `team_management_test.dart` | Create team, add/remove players via UI | Created inline |
| `viewer_live_test.dart` | Multi-emulator scorer+viewer WebSocket live updates | 2 × 6 players (same as match test) |
| `spectator_live_test.dart` | Non-team user discovers match on Live tab, views live updates | 2 × 6 players (scored by scorer, viewed by spectator) |

**Key change from current:** Each test creates its own teams (via UI), so they don't depend on test 01 or each other.

### Tier 3: Full Suite (~20-30 min) — Pre-Release

Runs all Tier 2 tests plus:
- Screen verification sweep (all tabs, detail pages)
- Edge cases (maiden over, all-out, declaration)
- Multiple match formats (T20, ODI, Custom overs)

## Test File Structure

Split giant `testWidgets` into multiple focused tests per file:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await resetMatchData();
  });

  testWidgets('Match setup wizard creates match correctly', (tester) async {
    await pumpAppAndWaitForHome(tester);
    await navigateToMatchSetup(tester);
    // ... setup assertions
  });

  testWidgets('First innings scoring with undo', (tester) async {
    await pumpAppAndWaitForHome(tester);
    // ... resume match, score, undo, verify
  });

  testWidgets('Second innings target chase completes match', (tester) async {
    await pumpAppAndWaitForHome(tester);
    // ... score 2nd innings, verify completion
  });
}
```

**Benefit:** Granular pass/fail. If "undo" fails, you see exactly that — not "standalone match test failed."

## Verification (Inline, Not Separate)

Fold verification steps into the test that creates the data:

```dart
// After scoring a match, immediately verify:
testWidgets('Match completes and scorecard is correct', (tester) async {
  // ... score match ...

  // Verify inline — no separate test 03/07 needed
  await navigateToMyCricket(tester);
  await verifyMatchesTab(tester, minCount: 1);
  await verifyTeamsTab(tester, expectedTeams: ['TestTeam1', 'TestTeam2']);
});
```

## Screenshot on Failure

Capture visual state when assertions fail:

```dart
try {
  expect(find.text('Match Complete'), findsOneWidget);
} catch (e) {
  await IntegrationTestWidgetsFlutterBinding.instance
      .takeScreenshot('failure_match_complete');
  rethrow;
}
```

## Multi-Emulator Viewer Testing

WebSocket viewer testing (scorer scores, viewers see live updates) is a critical flow. Dev E2E is the best place for it: local server has signal endpoints, ~5ms latency (no signal timeouts), and full test DB control.

### Emulator Setup

Each emulator needs a distinct AVD or port assignment:

```bash
# Launch scorer emulator (default port)
emulator -avd Resizable_Experimental -port 5554

# Launch viewer emulator (separate AVD or same AVD name with different port)
emulator -avd Resizable_Experimental -port 5556

# Verify both are running
adb devices
# emulator-5554   device
# emulator-5556   device
```

**Resource requirements:** Each emulator uses ~2-3 GB RAM. Two emulators + local server = ~8 GB minimum. Close other heavy apps during multi-emulator testing.

**Note:** Two emulators from the same AVD image will share app data. If this causes issues, create a second AVD (e.g., `Viewer_Emulator`) via Android Studio AVD Manager.

### Signal-Based Coordination

The local server provides signal endpoints for automated scorer-viewer synchronization (only available when `NODE_ENV=test`):

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/test/signal/:name` | `POST` | Set a named signal (with optional JSON body as value) |
| `/api/v1/test/signal/:name` | `GET` | Read a signal (returns `null` if not set) |
| `/api/v1/test/signals` | `DELETE` | Clear all signals (called during `reset-match-data`) |

**Coordination flow:**

```
Scorer                              Viewer
  │                                   │
  ├── Create match + toss             │
  ├── POST signal/scorer-ready ──────►│
  │                                   ├── Poll GET signal/scorer-ready
  │◄──────── POST signal/viewer-ready─┤
  ├── Poll GET signal/viewer-ready    │
  │                                   │
  ├── Score delivery 1                │
  ├── ...                             ├── Verify live updates via WS
  ├── Score last delivery             │
  ├── POST signal/innings-1-complete ►│
  │                                   ├── Verify innings transition
  │◄── POST signal/viewer-verified-1 ─┤
  ├── Score innings 2                 │
  ├── Match complete                  ├── Verify match result
  └── Done                            └── Done
```

### Run Commands

```bash
# Terminal 1: Start local test server
cd apps/server
NODE_ENV=test ENABLE_TEST_AUTH=true PORT=3001 bun run src/index.ts

# Terminal 2: Scorer on emulator-5554
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/viewer_live_test.dart \
  --dart-define=ROLE=scorer -d emulator-5554

# Terminal 3: Viewer on emulator-5556 (as Player301, on Team1 roster)
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/viewer_live_test.dart \
  --dart-define=ROLE=viewer --dart-define=VIEWER_PHONE=9999999301 -d emulator-5556
```

**Bootstrap:** `pumpAppAndWaitForHome(tester, phoneNumber: '9999999301')` already supports multi-user login — pass the viewer's phone number to log in as that player.

### Viewer Assertions (Stronger Than Regex)

Dev viewer tests should verify more than "score text changed." At each sync point:

| Sync Point | Scorer Action | Viewer Assertion |
|------------|--------------|------------------|
| `scorer-ready` | Match created, toss done | Match appears in Live tab |
| After each delivery | Scores a ball | Delivery count increments by 1, score matches expected value |
| `innings-1-complete` | Innings ends | Target score appears, innings transition UI renders |
| `match-complete` | Match finishes | Correct result text (e.g., "Team1 won by 5 wickets"), match moves to completed |

Use signal endpoints for sync points: scorer posts `innings-1-complete`, viewer verifies the state then posts `viewer-verified-innings-1` before scorer proceeds to innings 2.

### Orchestration Script

For automated runs, adapt the existing `scripts/multi-device-e2e.sh` or create `scripts/dev-multi-emulator.sh`:

```bash
#!/bin/bash
# scripts/dev-multi-emulator.sh — Launch scorer+viewer on local emulators
SCORER_DEVICE="emulator-5554"
VIEWER_DEVICE="emulator-5556"
VIEWER_PHONE="9999999301"

cd apps/mobile

# Run scorer and viewer in parallel
flutter test --flavor dev \
  integration_test/tests/viewer_live_test.dart \
  --dart-define=ROLE=scorer -d $SCORER_DEVICE &
SCORER_PID=$!

flutter test --flavor dev \
  integration_test/tests/viewer_live_test.dart \
  --dart-define=ROLE=viewer --dart-define=VIEWER_PHONE=$VIEWER_PHONE -d $VIEWER_DEVICE &
VIEWER_PID=$!

# Wait for both to complete
wait $SCORER_PID $VIEWER_PID
echo "Multi-emulator test complete"
```

## Non-Team Viewer Testing

Tests that any authenticated user — even one with no team membership — can discover and view live matches via the Live tab.

### Scenarios

1. **Pure spectator** (`9999999997`) — not on any team roster. Discovers matches solely via the public Live tab.
2. **Non-playing team player** (`9999999401`, Player401 on Team4) — on a team, but not one playing in the match.

### Coordination Flow

```
Scorer (9999999999)                Spectator (9999999997)
  │                                   │
  ├── Create match (Team1 vs Team2)   │
  ├── Complete toss                   │
  ├── Score 1 delivery                │
  ├── POST signal/scorer-ready ──────►│
  │                                   ├── Poll GET signal/scorer-ready
  │                                   ├── Navigate to Live tab
  │                                   ├── Verify match appears (public discovery)
  │                                   ├── Tap into live view
  │                                   ├── Verify score visible
  │◄──────── POST signal/viewer-ready─┤
  ├── Poll GET signal/viewer-ready    │
  ├── Score remaining deliveries      ├── Verify WS updates in real-time
  ├── Match completes                 ├── Verify result
  └── Done                            │
                                      ├── Navigate to My Cricket
                                      ├── Verify match does NOT appear (correctly filtered)
                                      └── Done
```

### Key Assertions

- Match appears on Live tab (public discovery via `scope=public` works)
- Score, overs, wickets visible without roster membership
- WebSocket updates received in real-time (no team check on `join_match`)
- Match does NOT appear in spectator's My Cricket tab (user-scoped, correctly filtered)

### Run Commands

```bash
# Terminal 1: Start local test server
cd apps/server
NODE_ENV=test ENABLE_TEST_AUTH=true PORT=3001 bun run src/index.ts

# Terminal 2: Scorer on emulator-5554
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/spectator_live_test.dart \
  --dart-define=ROLE=scorer -d emulator-5554

# Terminal 3: Spectator on emulator-5556 (not on any team)
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/spectator_live_test.dart \
  --dart-define=ROLE=viewer --dart-define=VIEWER_PHONE=9999999997 -d emulator-5556
```

## Parallel Execution

The primary parallelism use case is scorer+viewer testing on multiple emulators (see above). Independent tests can also run in parallel on separate emulators:

```bash
# Independent tests on separate emulators (each shares the local server)
flutter test --flavor dev integration_test/tests/match_scoring_test.dart -d emulator-5554 &
flutter test --flavor dev integration_test/tests/tournament_gk_test.dart -d emulator-5556 &
wait
```

Requires isolated test users per emulator (different login phones) or `reset-match-data` scoped to the test's own data.

## Local Server Setup

```bash
# Terminal 1: Start local test server
cd apps/server
NODE_ENV=test ENABLE_TEST_AUTH=true PORT=3001 bun run src/index.ts

# Terminal 2: Run E2E tests (emulator uses 10.0.2.2 to reach host)
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/smoke_test.dart -d emulator-5554
```

The emulator accesses the local server at `10.0.2.2:3001` (Android's host loopback alias). No `--dart-define` overrides needed if `AppConstants` already handles dev flavor URLs.

## Migration Path from Current Strategy

| Step | Change | Effort |
|------|--------|--------|
| 1 | Create `smoke_test.dart` (Tier 1) | Small |
| 2 | Add fixed `Random(42)` seeds to tournament tests | Trivial |
| 3 | Make each tournament test create its own teams via UI | Medium |
| 5 | Split test 02 into multiple `testWidgets` | Medium |
| 6 | Merge test 03 into test 02, test 07 into relevant tests | Small |
| 7 | Add screenshot-on-failure wrapper | Small |
| 8 | Configure dev flavor to point to `10.0.2.2:3001` | Small |
| 9 | Create dev-flavor `viewer_live_test.dart` (adapt from prod test 08) | Medium |
| 10 | Add signal-based sync point assertions for viewer | Medium |
| 11 | Create `scripts/dev-multi-emulator.sh` orchestrator | Small |
| 12 | Set up second AVD for viewer emulator | Trivial |
| 13 | Fix server `getMatches` to support `scope=public` for Live tab | Medium |
| 14 | Wire Flutter Live tab to use `publicMatchesByStatusProvider` | Small |
| 15 | Register `9999999997` as Firebase test phone | Trivial |
| 16 | Create `spectator_live_test.dart` (non-team viewer E2E) | Medium |
