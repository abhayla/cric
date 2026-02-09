# Code Fixes & Debugging

## Root Cause Analysis Workflow

Every bug fix follows these 8 steps. Do not skip steps — especially step 5 (fix root cause, not symptom).

### Step 1: Reproduce the Bug

Create a minimal reproduction. If it's a scoring bug, write a test that exercises the exact delivery sequence. If it's a UI bug, note the exact screen and interaction.

### Step 2: Read Error + Stack Trace

Read the full error message and stack trace. Identify:
- Which file and line number threw the error
- The type of error (null check, state, network, SQL)
- The call chain that led to the error

### Step 3: Trace the Code Path

Follow the code path from the trigger (user action or API call) through each layer:

```
UI event → Notifier method → Repository method → Datasource method → DB/API
```

Identify which layer the bug originates in vs which layer it manifests in. These are often different.

### Step 4: Identify the Layer

| Symptom | Likely Layer |
|---------|-------------|
| Wrong data displayed | Presentation (widget reads wrong field) or Data (model mapping) |
| State not updating | Presentation (notifier not calling copyWith) or Provider wiring |
| Wrong stats calculated | Domain (business logic) or Data (SQL query) |
| Sync failure | Data (datasource) or Network |
| Crash on action | Domain (null/validation) or Data (schema mismatch) |

### Step 5: Fix the Root Cause

Fix the actual cause, not the symptom. Examples:

| Symptom | Wrong Fix | Right Fix |
|---------|-----------|-----------|
| Score shows wrong after wide | Add +1 to display widget | Fix delivery processing to count wide runs correctly |
| Crash on undo | Wrap in try-catch | Fix null check in undo logic for edge case |
| Stats mismatch after sync | Force re-fetch from server | Fix sync to update local stats table after push |

### Step 6: Write a Regression Test

Write a test that fails before the fix and passes after. This prevents the same bug from recurring.

### Step 7: Run Full Test Suite

Run the complete test suite for the affected feature, not just the new test. A fix in one area can break another.

```bash
cd apps/mobile && flutter test test/src/features/scoring/  # Full scoring suite
cd apps/mobile && flutter test                              # All tests
```

### Step 8: Screenshot Verify (if UI)

If the bug affected the UI, take a screenshot after the fix and visually verify against the blueprint wireframe.

---

## Common Issue Patterns

These are CricApp-specific issues that are likely to occur during implementation.

### Strike Rotation After Wicket

**Issue:** After a wicket, the new batter may be placed at the wrong end.
**Rule:** The new batter always takes the dismissed batter's position (striker or non-striker). If the dismissal happened with runs scored (e.g., caught off a 1-run attempted second), apply run-based rotation first, then place the new batter.
**Source of truth:** [SCORING_RULES.md](../planning/SCORING_RULES.md) — strike rotation section.

### Maiden Detection with Byes/Leg-Byes

**Issue:** An over with only byes/leg-byes may be incorrectly marked as not a maiden.
**Rule:** Byes and leg-byes do NOT break a maiden. Only runs from bat, wides, and no-balls break a maiden.
**Source of truth:** [SCORING_RULES.md](../planning/SCORING_RULES.md) — maiden detection section.

### Over Completion with Wides/No-Balls

**Issue:** Over counted as complete before 6 legal deliveries because wides/no-balls were counted.
**Rule:** Wides and no-balls are NOT legal deliveries. They don't increment the ball count toward the 6-ball over.
**Source of truth:** [SCORING_RULES.md](../planning/SCORING_RULES.md) — extras handling.

### Free Hit Triggering

**Issue:** Free hit not triggered after a no-ball, or triggered after a wide.
**Rule:** Free hit is triggered ONLY after a no-ball (not after a wide). On a free hit delivery, the only possible dismissal is run out.
**Source of truth:** [SCORING_RULES.md](../planning/SCORING_RULES.md) — free hit section.

### Sync Conflicts

**Issue:** Local and server data diverge after sync.
**Rule:** Server is authoritative. Last-write-wins using `updated_at` timestamps. Deliveries are append-only during a match — concurrent editing of the same delivery should not occur.
**Source of truth:** [DATABASE.md](../planning/DATABASE.md) — sync strategy section.

### WebSocket Disconnection

**Issue:** Viewer misses deliveries during a disconnect.
**Rule:** On reconnect, client should request the full current match state (not just subscribe to new events). The server provides a "catch-up" snapshot.
**Source of truth:** [API.md](../planning/API.md) — WebSocket protocol section.

### Stats Mismatch Between Inline and Aggregated

**Issue:** Batting/bowling stats inline on the scorecard don't match the stats tables.
**Rule:** Stats tables are the source of truth. They are updated in the same transaction as the delivery insert. If they diverge, the bug is in the delivery processing pipeline.
**Source of truth:** [SCORING_RULES.md](../planning/SCORING_RULES.md) — delivery pipeline step 6 (update stats).

---

## Debugging Tools

### Flutter (Dart)

| Tool | When to Use | How |
|------|-------------|-----|
| `debugPrint()` | Trace execution flow in notifiers | `debugPrint('recordDelivery: runs=$runs, isWide=$isWide')` |
| Riverpod observer | Watch all provider state changes | Register `ProviderObserver` in `ProviderScope` |
| Drift query logging | Debug SQL queries | Enable `QueryInterceptor` on database open |
| Flutter DevTools | Performance profiling, widget inspector | `flutter run` then open DevTools URL |
| `assert()` | Catch programming errors in debug mode | `assert(balls <= 6, 'Over cannot exceed 6 legal deliveries')` |

### Server (TypeScript/Bun)

| Tool | When to Use | How |
|------|-------------|-----|
| Structured JSON logs | All server events | `logger.info({ matchId, event: 'delivery_processed' })` |
| Drizzle query logging | Debug SQL queries | Enable `logger: true` in Drizzle config |
| WebSocket message logging | Debug real-time communication | Log all incoming/outgoing WS messages with type and match ID |
| Bun debugger | Step through service logic | `bun --inspect src/index.ts` |

---

## Test Failure Resolution Loop

```
Run tests
    ↓
Test fails
    ↓
Read the failure output carefully
    ↓
Is the test expectation correct?
├── NO → Fix the test (the test was wrong)
└── YES → Fix the code
            ↓
        Re-run the failing test
            ↓
        Still failing?
        ├── YES → Re-read the failure, check a different code path
        └── NO → Run the full feature test suite
                    ↓
                Any other failures?
                ├── YES → Fix (your change broke something else)
                └── NO → If UI test, take screenshot and verify
                            ↓
                        Screenshot matches blueprint?
                        ├── YES → Done
                        └── NO → Fix UI and loop back
```

---

## Scoring Engine Fix Protocol

The scoring engine is the most critical and complex piece of code. Extra care is required.

1. **Never fix without a reproducing test.** Write a test that demonstrates the bug before writing the fix.
2. **Run the full scoring test suite after every fix.** Scoring logic is deeply interconnected — a fix for wide runs can break maiden detection.
3. **SCORING_RULES.md is the source of truth.** If the code disagrees with [SCORING_RULES.md](../planning/SCORING_RULES.md), the code is wrong (unless the doc has an acknowledged error — in which case, fix the doc first with user approval).
4. **Manually trace 1 over after fixing.** Walk through a 6-ball over mentally (or in a test) to verify the fix doesn't break normal flow: dot, 1, 4, wide, 2, W, dot → verify score, strike, overs, bowler stats.
5. **Check undo after fixing.** If you fix delivery processing, verify that undo still correctly reverses the fixed behavior.

---

## Git Practices for Fixes

### Branch Naming

```
fix/<short-description>        # e.g., fix/strike-rotation-after-wicket
fix/<issue-number>-<desc>      # e.g., fix/42-maiden-detection-byes
```

### Commit Messages

```
fix: correct strike rotation after caught dismissal with runs

Root cause: strike was rotated for runs before the new batter was placed,
resulting in the new batter being at the wrong end.

Closes #42
```

### One Fix Per Commit

Each bug fix should be a single atomic commit. Don't bundle multiple unrelated fixes. This makes `git bisect` effective and reverts safe.
