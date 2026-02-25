# Remaining E2E Tests — Run Prompt

Run this prompt to execute the full E2E test suite. Tests run sequentially on an emulator, with the multi-device test also using a second device for the viewer.

---

## HOW THIS TEST WORKS — READ THIS FIRST

The test suite consists of **8 automated integration tests** that run against the prod server (`cricscores.in`). All tests are **100% UI-driven** — `WidgetTester` drives the UI programmatically. No API shortcuts.

| # | Test File | Scenarios | Est. Runtime |
|---|-----------|-----------|-------------|
| 01 | `01_team_setup_test.dart` | Team setup (16 teams × 6 players) | ~20 min |
| 02 | `02_standalone_match_test.dart` | Standalone match, undo, target chase | ~10 min |
| 03 | `03_verify_after_match_test.dart` | My Cricket, scorecard, player profile | ~5 min |
| 04 | `04_tournament_gk_test.dart` | Group+Knockout tournament | ~2-3 hrs |
| 05 | `05_tournament_ko_test.dart` | Knockout tournament | ~1 hr |
| 06 | `06_tournament_rr_test.dart` | Round Robin tournament | ~1-2 hrs |
| 07 | `07_verify_all_screens_test.dart` | Navigate + verify all screens | ~10 min |
| 08 | `08_viewer_live_test.dart` | Multi-device WebSocket live test | ~15-25 min |

**Total estimated runtime: ~5-7 hours** (including tournaments).

---

## EXECUTION INSTRUCTIONS FOR CLAUDE

**DO NOT ask any questions. DO NOT ask for confirmations. Execute immediately.**

**Skip any prerequisite the user has already confirmed.**

### Step 1: Quick Prerequisites (only check unknowns)

| Check | Command | Skip if user said |
|-------|---------|-------------------|
| Emulator | `flutter devices 2>/dev/null \| grep emulator` | "emulator is running" |
| Server | `curl -s https://cricscores.in/health` | "server is running" |

If a check fails, report the specific failure and stop.

### Step 2: Run Tests Sequentially

Run each test one at a time. **Wait for each test to fully complete before starting the next.**

```bash
cd apps/mobile

# Test 01: Team Setup (~20 min, one-time)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/01_team_setup_test.dart -d emulator-5554

# Test 02: Standalone Match (~10 min)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554

# Test 03: Verify After Match (~5 min)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/03_verify_after_match_test.dart -d emulator-5554

# Test 04: Tournament Group+Knockout (~2-3 hrs)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/04_tournament_gk_test.dart -d emulator-5554

# Test 05: Tournament Knockout (~1 hr)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/05_tournament_ko_test.dart -d emulator-5554

# Test 06: Tournament Round Robin (~1-2 hrs)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/06_tournament_rr_test.dart -d emulator-5554

# Test 07: Verify All Screens (~10 min)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/07_verify_all_screens_test.dart -d emulator-5554

# Test 08: Multi-Device Viewer (needs second device)
flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/08_viewer_live_test.dart -d <device-id>
```

### Step 3: Final Summary Report

After all tests complete (or if any test fails), present a consolidated report:

```
=== E2E TEST RESULTS ===

| # | Test                     | Status    | Runtime | Notes |
|---|--------------------------|-----------|---------|-------|
| 01 | Team Setup              | PASS/FAIL | Xm Ys  |       |
| 02 | Standalone Match        | PASS/FAIL | Xm Ys  |       |
| 03 | Verify After Match      | PASS/FAIL | Xm Ys  |       |
| 04 | Tournament GK           | PASS/FAIL | Xm Ys  |       |
| 05 | Tournament KO           | PASS/FAIL | Xm Ys  |       |
| 06 | Tournament RR           | PASS/FAIL | Xm Ys  |       |
| 07 | Verify All Screens      | PASS/FAIL | Xm Ys  |       |
| 08 | Viewer Live             | PASS/FAIL | Xm Ys  |       |

Total: X/8 PASSED
Total runtime: ~XX minutes
```

---

## Test Dependencies

```
01_team_setup ─── (creates teams) ──→ 02, 03, 04, 05, 06, 07, 08
02_standalone_match ── (creates match) ──→ 03
04-06_tournaments ── (creates data) ──→ 07
```

- Test 01 must run first (creates teams used by all other tests)
- Test 03 depends on test 02 (verifies the match scored in test 02)
- Test 07 depends on tests 01-06 (navigates all screens to verify data)
- Test 08 is independent (needs a second device + a scorer running test 02 simultaneously)

---

## Key Files

| File | Purpose |
|------|---------|
| **Test files** | |
| `integration_test/tests/01_team_setup_test.dart` | Create 16 teams × 6 players |
| `integration_test/tests/02_standalone_match_test.dart` | Standalone match + undo + target chase |
| `integration_test/tests/03_verify_after_match_test.dart` | Verify match data on screens |
| `integration_test/tests/04_tournament_gk_test.dart` | Group+Knockout tournament |
| `integration_test/tests/05_tournament_ko_test.dart` | Knockout tournament |
| `integration_test/tests/06_tournament_rr_test.dart` | Round Robin tournament |
| `integration_test/tests/07_verify_all_screens_test.dart` | Navigate + verify all screens |
| `integration_test/tests/08_viewer_live_test.dart` | Multi-device WebSocket live test |
| **Core** | |
| `integration_test/core/app_bootstrap.dart` | App launch + Firebase auth |
| `integration_test/core/error_tracker.dart` | Step-by-step progress tracking |
| `integration_test/core/test_utils.dart` | `waitForFinder()`, `waitForFinderGone()`, `testLog()` |
| `integration_test/core/stat_tracker.dart` | Per-match stat accumulation |
| **Flows** | |
| `integration_test/flows/random_innings.dart` | `playRandomInnings()` — weighted random deliveries |
| `integration_test/flows/standalone_match_flow.dart` | Full standalone match lifecycle |
| `integration_test/flows/team_setup_flow.dart` | Create N teams × M players via UI |
| `integration_test/flows/tournament_flow.dart` | `scoreAllFixtures()` — score all tournament fixtures |
| **Helpers** | |
| `integration_test/helpers/scoring.dart` | Tap run/extra/wicket buttons |
| `integration_test/helpers/match_setup.dart` | Match setup + toss wizard |
| `integration_test/helpers/fixture_scanning.dart` | Find + tap FixtureCard widgets |
| `integration_test/helpers/tournament_mgmt.dart` | Tournament CRUD via UI |
| `integration_test/helpers/navigation.dart` | Tab switching, back navigation |
| `integration_test/helpers/modals.dart` | Dismiss completion/transition modals |
| `integration_test/helpers/forms.dart` | Fill text fields, create teams/players |
| **Verification** | |
| `integration_test/verification/my_cricket_verifier.dart` | My Cricket tab assertions |
| `integration_test/verification/tournament_verifier.dart` | Tournament detail assertions |
| `integration_test/verification/team_detail_verifier.dart` | Team detail page assertions |
| `integration_test/verification/player_profile_verifier.dart` | Player profile assertions |
| `integration_test/verification/live_verifier.dart` | Live match WebSocket assertions |
| `integration_test/verification/updates_verifier.dart` | Updates feed assertions |
| **Config** | |
| `integration_test/config/constants.dart` | Timeouts, retry counts |
| `integration_test/config/test_data.dart` | Team/player names, phone numbers |
| `integration_test/config/tournament_presets.dart` | Tournament format configs |
| **Models** | |
| `integration_test/models/delivery_record.dart` | Delivery tracking data class |
| `integration_test/models/match_outcome.dart` | Match result tracking |
| `integration_test/models/player_stats.dart` | Accumulated player stats |

---

## Debugging Tips

### Common Across All Tests
- **Gradle build takes 2-5 min** on first run per flavor. Be patient.
- **ANR "App Not Responding":** Run `adb -s emulator-5554 shell "am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"` to dismiss.
- **Kill stale dart.exe:** `wmic.exe process where "name='dart.exe'" get processid,commandline` then `taskkill.exe /PID <pid> /F`
- **ADB path:** If `adb` is not in PATH, use: `C:/Users/itsab/AppData/Local/Android/Sdk/platform-tools/adb.exe`

### Team Setup (Test 01)
- **Takes ~20 min** — creating 16 teams × 6 players through forms is slow. This is a one-time cost.
- **Already have teams?** Skip test 01 and go straight to test 02.

### Standalone Match (Test 02)
- **Match setup stalls?** Check toss wizard — opener/bowler names must match roster.
- **Undo not working?** Check if `undoBlockedByTransition` is true (undo is blocked after innings/bowler transitions).

### Tournament Tests (04-06)
- **Fixture card not found?** Test scrolls to find fixtures. All fixtures may already be played.
- **Match stuck?** ANR is more likely in long tournament tests — dismiss frequently.
- **ErrorTracker shows error?** Read the summary for the exact failure step.

### Viewer Test (08)
- **Needs two devices** — scorer on emulator, viewer on physical device (or second emulator).
- **WebSocket connection fails?** Verify server's `/ws` endpoint is running.
- **Signal handshake timeout?** Scorer must post `scorer-ready` before viewer can proceed.
