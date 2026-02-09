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

**Iteration tracking:** Start a counter at `iteration = 1`. Increment after each failed re-run.

**Debug logging:** At loop start, create `docs/debug/<issue-name>.md` with the following table. After each failed iteration, append a row. In conversation, maintain a 1-2 line status summary referencing this file.

```
| Iter | Hypothesis | Fix Attempted | Result | Finding |
|------|-----------|--------------|--------|---------|
```

### Flowchart

```
Run test
    |
Test fails -> Read failure output carefully
    |
Is the test expectation correct?
|-- NO -> Fix the test
+-- YES -> Fix the code
            |
        Re-run the failing test (iteration++)
            |
        Passes?
        |-- YES -> Run full feature test suite
        |           |
        |       Any other failures?
        |       |-- YES -> Fix (your change broke something -- restart loop)
        |       +-- NO -> If UI test, screenshot verify against blueprint -> Done
        |
        +-- NO -> Update DEBUG file, then check iteration tier:
                |-- Normal (1-3): Re-read failure, try a different code path
                |-- Tier 1 (4-5): Slow Down -- apply Tier 1 instructions
                |-- Tier 2 (6-7): Widen -- apply Tier 2 instructions
                |-- Tier 3 (8-9): Audit -- apply Tier 3 instructions
                +-- Hard Cap (10): STOP -> present findings to user
```

### Escalation Tier Summary

| Tier | Iterations | Reasoning Shift | Scope Expansion |
|------|-----------|----------------|-----------------|
| Normal | 1-3 | Read error, fix the obvious cause | Failing function and its immediate context |
| Tier 1 | 4-5 | Slow down, challenge assumptions | Full file + imports + type definitions |
| Tier 2 | 6-7 | Trace full path, map expected vs actual | Callers/callees + planning docs |
| Tier 3 | 8-9 | Audit architecture, check for interacting bugs | Full feature directory + codebase grep |
| Hard Cap | 10 | Stop fixing | Present structured findings to user |

### Tier 1 — Slow Down (iterations 4-5)

- **Read the DEBUG file** to review all findings from iterations 1-3. Identify what has been ruled out vs what remains uncertain.
- **Discard your previous theory, but carry forward all findings.** Re-interpret the accumulated evidence with fresh eyes.
- **List your assumptions explicitly:** what you believe the code does, what the test expects, what the types are. Verify each against the actual source.
- **Read the entire file** containing the failing code (not just the failing function). Check imports, type definitions, and constructor parameters for mismatches.

### Tier 2 — Widen (iterations 6-7)

- **Read the DEBUG file** and identify the pattern across all 5 failed iterations — same error, shifting errors, or partial fixes?
- **Trace the full code path** from the test's entry point to the failure point. At each layer boundary (UI → Notifier → Repository → Datasource → DB), write out the expected vs actual state.
- **The bug may not be where it manifests.** Grep for all callers and callees of the failing function. The root cause may be upstream or downstream.
- **Read the relevant planning doc** ([SCORING_RULES.md](../planning/SCORING_RULES.md), [DATABASE.md](../planning/DATABASE.md), or [API.md](../planning/API.md)) and compare the spec against the implementation line by line.

### Tier 3 — Audit (iterations 8-9)

- **Read the DEBUG file** and look for contradictions — did any two iterations produce conflicting findings? A contradiction points to interacting bugs.
- **Challenge interface contracts between layers.** Is the repository returning what the notifier expects? Is the datasource mapping fields correctly? Could two bugs be canceling each other on other paths but compounding here?
- **For scoring bugs:** manually walk through the 10-step delivery pipeline ([SCORING_RULES.md](../planning/SCORING_RULES.md)) with the test's exact input data, writing out the expected output of each step.
- **Read the full feature directory.** Grep the codebase for the same function/pattern to find a working instance elsewhere — diff it against the failing code.

### Hard Cap — Iteration 10

Stop fixing. Present findings to the user in this format:

```
## Stuck: [Test Name]

**Failure:** [One-line error summary]

**Pattern:** [What is consistent across all 9 attempts — same error? shifting errors?]

**Attempts:**
1. [What was tried -> what happened]
...
9. [What was tried -> what happened]

**Files Investigated:**
- [file path — reason for reading]

**Root Cause Hypothesis:** [Best theory for why the fix is not working]

**Recommended Next Steps:**
- [What the user should check or decide]
- [Whether a design change or spec clarification may be needed]
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
