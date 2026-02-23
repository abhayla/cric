# Persistence Recovery E2E Test — Run Prompt

Run this prompt when you want to test offline-first persistence and crash recovery. This test proves that scoring state survives an app restart and can be resumed without data loss.

---

## What This Test Does

- Scores 3 overs (18 legal deliveries) through the real Flutter UI
- Simulates an app restart by re-pumping the widget tree
- Verifies the app detects a resumable match from Drift/SQLite persistence
- Resumes scoring and records one more delivery
- Verifies no duplicate deliveries in PostgreSQL after the restart

**Scenario covered:** 16 (Kill App Mid-Innings / Persistence Recovery)

**Runtime: ~10-15 minutes on emulator.**

---

## Prerequisites Checklist

1. **Android emulator is running**
2. **Bun server running in test mode:**
   ```bash
   cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
   ```
3. **PostgreSQL running** with test database
4. **Flutter dependencies resolved** — `flutter pub get`
5. **Code generation up to date** — `dart run build_runner build --delete-conflicting-outputs`

---

## Run Command

```bash
cd apps/mobile && flutter test integration_test/persistence_e2e_test.dart -d emulator-5554
```

Timeout: 30 minutes.

---

## Test Phases

| Phase | What Happens |
|-------|-------------|
| 1 | Boot app, land on Home page |
| 2 | Create teams (skipped if already exist) |
| 3 | Match setup: 5 overs, 11 players |
| 4 | Toss: Mumbai Warriors bats first |
| 5 | Score 3 overs (18 deliveries): predetermined sequence |
| 6 | Simulate restart: re-pump the app widget tree |
| 7 | Verify recovery: check for resume prompt or restored state |
| 8 | Continue scoring: record 1 more delivery post-recovery |
| 9 | DB verification: no duplicate deliveries |

---

## Predetermined Delivery Sequence

### Over 1 (Deepak Chahar): 4, 1, 0, 2, 1, 6 = 14 runs
### Over 2 (Bhuvneshwar Kumar): 0, 0, 4, 0, 1, 0 = 5 runs
### Over 3 (Kuldeep Yadav): 2, 0, 1, 4, 0, 2 = 9 runs

**Total before restart: 28/0 in 3.0 overs**

### After Recovery: 1 delivery (4 runs)
**Expected DB count: 19 deliveries (18 + 1)**

---

## How Persistence Works

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

## How Sync Works

The `SyncService` pushes locally-queued deliveries to the server:

- **Live (< 6 queued):** Individual `POST /deliveries` per ball — immediate broadcast
- **Batch (>= 6 queued):** `POST /deliveries/batch` in chunks of 30 — single DB transaction per chunk
- **Failed entries:** Entries exceeding `maxRetries` are marked `'failed'` (not `'synced'`), preserving them for inspection rather than silently dropping data
- **After restart:** Unsynced deliveries remain in the `sync_queue` table and are retried on next sync cycle

---

## Simulation Limitation

In Flutter integration tests, we cannot truly kill the process. Instead:
- `AppTestWrapper.pumpApp(tester)` is called again to restart the widget tree
- This triggers the app's initialization flow including persistence check
- The Drift database persists on the emulator's filesystem between pumps

This simulates a "warm restart" rather than a cold kill. For true crash recovery testing, manually:
1. Run the test up to Phase 5 (score 3 overs)
2. Force-kill the app: `adb shell am force-stop in.cricscores.app`
3. Relaunch: `adb shell am start in.cricscores.app/.MainActivity`
4. Verify the resume prompt appears

---

## Key Verification

The critical assertion is:
```dart
expect(dbDeliveries.length, equals(19),
    reason: 'No duplicate deliveries after restart');
```

If persistence recovery re-syncs already-synced deliveries, the count would be > 19. If it loses unsynced deliveries, the count would be < 19.

---

## Debugging Tips

- **No resume prompt after restart?** Check that `ScoringPersistenceService` is correctly saving state. Look for `[Persistence]` log messages.
- **Duplicate deliveries?** The `synced` flag on each delivery prevents double-sync. Check if the sync queue was flushed before restart. The server also has duplicate detection via `sequenceNumber` within each innings.
- **Score mismatch after recovery?** Compare the `ScoringState` fields before and after. The persistence service should restore all fields exactly.
- **Failed sync entries?** Check for entries with status `'failed'` in the sync queue. These are entries that exceeded `maxRetries` — they are preserved (not silently dropped) for debugging.

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/persistence_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data |
| `integration_test/helpers/match_flow_helpers.dart` | Tap helpers |
| `integration_test/helpers/server_manager.dart` | Server API calls |
| `integration_test/helpers/app_test_wrapper.dart` | App bootstrapping |
| `lib/src/shared/data/sync/sync_service.dart` | Batch/individual sync logic (`_batchThreshold = 6`, chunks of 30) |
| `lib/src/shared/data/database/daos/scoring_dao.dart` | `markSyncFailed()` for entries exceeding maxRetries |
