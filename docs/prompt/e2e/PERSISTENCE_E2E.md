# Persistence Recovery E2E Test — Run Prompt

Run this prompt when you want to test offline-first persistence and crash recovery. This test proves that scoring state survives an app restart and can be resumed without data loss.

---

## Status: NOT YET IMPLEMENTED

This scenario (Scenario 16 from `E2E_TEST_SCENARIOS.md`) does not have a dedicated automated test in the current test suite. The closest existing test is `02_standalone_match_test.dart` which covers basic match completion and persistence verification (match appears in My Cricket tab after completion).

**To implement:** Create a new test file (e.g., `integration_test/tests/09_persistence_recovery_test.dart`) following the current architecture.

---

## What This Test Should Do

- Score 3 overs (18 legal deliveries) through the real Flutter UI
- Simulate an app restart by re-pumping the widget tree
- Verify the app detects a resumable match from Drift/SQLite persistence
- Resume scoring and record one more delivery
- Verify no duplicate deliveries after the restart

**Scenario covered:** 16 (Kill App Mid-Innings / Persistence Recovery)

**Estimated runtime: ~10-15 minutes on emulator.**

---

## Prerequisites

1. **Android emulator is running**
2. **Prod server is live** at `cricscores.in`
3. **Teams already created** — run test 01 first
4. **Flutter dependencies resolved** — `flutter pub get`
5. **Code generation up to date** — `dart run build_runner build --delete-conflicting-outputs`

---

## Implementation Notes

### Current Architecture

The test should use the current layered infrastructure:
- `core/app_bootstrap.dart` — App launch + Firebase auth
- `helpers/scoring.dart` — Tap scoring controls
- `helpers/match_setup.dart` — Match setup + toss wizard
- `core/test_utils.dart` — `waitForFinder()`, `settle()`
- `models/delivery_record.dart` — Delivery tracking

### How Persistence Works

CricScores uses `ScoringPersistenceService` to save scoring state to local Drift/SQLite after each delivery mutation. On app restart:

1. `ScoringPersistenceService.checkForResumableMatch()` checks Drift for saved state
2. If found, the home page shows a "Resume Match" indicator
3. Tapping resume calls `ScoringPersistenceService.resume()` which restores:
   - Match context (matchId, inningsId, team IDs, overs config)
   - Current score (runs, wickets, balls)
   - Current players (striker, non-striker, bowler)
   - Batter stats (Map<String, BatterInnings>)
   - Bowler stats (Map<String, BowlerSpell>)
   - Over history and current over deliveries
   - Free hit state

### How Sync Works

The `SyncService` pushes locally-queued deliveries to the server:

- **Live (< 6 queued):** Individual `POST /deliveries` per ball — immediate broadcast
- **Batch (>= 6 queued):** `POST /deliveries/batch` in chunks of 30 — single DB transaction per chunk
- **Failed entries:** Entries exceeding `maxRetries` are marked `'failed'` (not `'synced'`), preserving them for inspection
- **After restart:** Unsynced deliveries remain in the `sync_queue` table and are retried on next sync cycle

### Simulation Limitation

In Flutter integration tests, we cannot truly kill the process. Instead:
- `app_bootstrap` is called again to restart the widget tree
- This triggers the app's initialization flow including persistence check
- The Drift database persists on the emulator's filesystem between pumps

This simulates a "warm restart" rather than a cold kill. For true crash recovery testing, manually:
1. Run the test up to score 3 overs
2. Force-kill the app: `adb shell am force-stop in.cricscores.app`
3. Relaunch: `adb shell am start in.cricscores.app/.MainActivity`
4. Verify the resume prompt appears

---

## Debugging Tips

- **No resume prompt after restart?** Check that `ScoringPersistenceService` is correctly saving state. Look for `[Persistence]` log messages.
- **Duplicate deliveries?** The `synced` flag on each delivery prevents double-sync. Check if the sync queue was flushed before restart.
- **Score mismatch after recovery?** Compare the `ScoringState` fields before and after. The persistence service should restore all fields exactly.
- **Failed sync entries?** Check for entries with status `'failed'` in the sync queue.
