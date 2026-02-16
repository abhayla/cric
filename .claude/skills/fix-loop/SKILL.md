---
name: fix-loop
description: "Iterative fix cycle: analyze failures, apply minimal fixes, run code review gates, optionally retest. Full Loop mode (with retest) iterates until resolved. Single Fix mode (no retest) does one pass. Thinking escalation, debugger agent delegation. Use when tests fail, build breaks, or runtime errors."
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Task
metadata:
  version: 1.0.0
---

# Fix Loop

Iterative fix cycle that analyzes failures, applies minimal fixes, runs code review gates, and optionally retests. Supports Full Loop (with retest) and Single Fix (one pass) modes. Uses thinking escalation, debugger delegation, and structured iteration logging.

**Arguments:** $ARGUMENTS

---

## Execution Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Full Loop** | `retest_command` is provided | Run full analyze → fix → review → build → retest cycle, iterating until resolved or budget exhausted |
| **Single Fix** | `retest_command` is absent | Run ONE analyze → fix → review → build pass, then return results for the caller to retest externally |

---

## Input Parameters

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `failure_output` | string | Raw failure output (test errors, stack traces, assertion messages) |
| `failure_context` | string | What was tested and what was expected |
| `files_of_interest` | string[] | File paths to read for understanding the code under test |

### Optional (with defaults)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `build_command` | null | Rebuild command after fix (null = skip) |
| `retest_command` | null | **Present = Full Loop, absent = Single Fix** |
| `retest_timeout` | 300 | Retest timeout in seconds |
| `max_iterations` | 10 | Maximum total fix-build-test cycles |
| `max_attempts_per_issue` | 3 | Maximum attempts per discrete issue |
| `force_thinking_level` | null | Override auto-escalation: `"normal"`, `"thinkhard"`, `"ultrathink"` |
| `prohibited_actions` | [] | Actions you must NEVER take |
| `fix_target` | "production" | What to fix: `"production"`, `"test"`, `"either"` |
| `log_dir` | ".claude/logs/fix-loop/" | Directory for iteration log files |
| `clear_flags` | [] | Workflow state flags to clear on RESOLVED |

---

## Step 0: Pre-Execution Knowledge Check

Before attempting fixes, check for known patterns:

1. Read `failure-index.json` for matching `(skill, issue_type)`:
   ```bash
   node -e "
   const fs = require('fs');
   try {
     const d = JSON.parse(fs.readFileSync('.claude/logs/learning/failure-index.json'));
     for (const e of d.entries || []) {
       if (e.known_workaround) console.log('KNOWN:', e.skill + '/' + e.issue_type, '->', e.known_workaround);
     }
   } catch { console.log('No failure index found'); }
   "
   ```

2. If known workaround found → apply it first
3. If previous stall found → start with the strategy that eventually worked

---

## Iteration Algorithm (Full Loop Mode)

For the detailed pseudocode and edge cases, see [references/iteration-algorithm.md](references/iteration-algorithm.md).

### Per-Iteration Steps

1. **ANALYZE** — Read failure output, trace to source code, identify root cause
2. **FIX** — Apply minimal, targeted change. Check against `prohibited_actions`
3. **CODE REVIEW GATE** — Launch `code-reviewer` agent (via Task tool, read-only) to review the fix
   - If APPROVED → proceed
   - If FLAGGED with Critical → revert fix, re-attempt with rejection context
4. **BUILD** (if `build_command` provided) — Rebuild. If build fails `3` times → revert, mark FAILED_BUILD
5. **RETEST** — Run `retest_command`. If PASS → RESOLVED. If FAIL → next iteration

### Thinking Escalation (Canonical)

| Level | When | Approach |
|-------|------|----------|
| **normal** | Attempt 1 (or forced) | Analyze directly — read failure, trace to source, fix |
| **thinkhard** | Attempt 2-3 (or forced) | Launch `debugger` agent (read-only, via Task tool) with extended analysis, all prior attempt logs |
| **ultrathink** | Attempt 4+ (or forced) | Launch `debugger` agent with maximum depth, complete history, re-examine all assumptions |

Override: `force_thinking_level` skips auto-escalation.

When launching the debugger agent, include: complete failure output, all files of interest, summary of all previous fix attempts. The debugger returns analysis only — YOU apply the fixes.

---

## Prohibited Actions Enforcement

Before applying ANY fix, verify it does not involve:
- Adding `@Skip` or `skip()` annotations to tests
- Weakening assertions (removing expects, broadening matchers)
- Deleting or commenting out test methods
- Adding arbitrary `await Future.delayed()` as timing fixes
- Creating "fix later" TODO comments to bypass failures

If the ONLY viable fix would violate a prohibited action, mark UNRESOLVED with reason.

---

## Iteration Log Format

Each iteration written to `{log_dir}/{session_id}/iteration-{NNN}.md`:

```markdown
# Iteration {NNN}

## Metadata
- Iteration: {NNN} / {max_iterations}
- Issue: {description}
- Attempt: {M} / {max_attempts_per_issue}
- Thinking level: {normal | thinkhard | ultrathink}
- Mode: {full_loop | single_fix}

## Failure Analysis
- Root cause: {description}
- File: {path}

## Fix Applied
- File: {path}
- Change: {description}

## Code Review
- Verdict: {APPROVED | FLAGGED}

## Result
- Status: {PASSED | FAILED | TIMEOUT}
```

---

## Workflow State Updates

At start:
```bash
node -e "
const fs = require('fs');
const sf = '.claude/workflow-state.json';
try {
  const d = JSON.parse(fs.readFileSync(sf));
  d.skillInvocations.fixLoopInvoked = true;
  fs.writeFileSync(sf, JSON.stringify(d, null, 2));
} catch {}
"
```

On completion, update `fixLoopResult` with the outcome status.

---

## Output — Full Loop Mode

```markdown
## Fix Loop Results

### Status
- **Overall:** RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | MAX_ITERATIONS_EXCEEDED
- **Iterations used:** N / max_iterations
- **Issues found:** N
- **Issues resolved:** N

### Fixes Applied
1. [{file}:{line}] — Root cause: {description} → Fix: {change}

### Unresolved Issues
1. {description} — Attempts: N, Last error: {message}

### Tracking Metrics
- Debugger invocations: N
- Code reviews: N (approved: N, flagged: N)

### Files Changed
- {file_path}

### Flags Cleared
- {flag_name}: cleared (or "No flags to clear")
```

## Output — Single Fix Mode

```markdown
## Single Fix Result

### Status
- **Fix applied:** true | false
- **Review verdict:** APPROVED | FLAGGED
- **Build status:** PASSED | FAILED | SKIPPED

### Fix Details
- **File:** {path}
- **Root cause:** {description}
- **Change:** {description}
- **Thinking level:** {level}
```

---

## Edge Cases

| Edge Case | Handling |
|-----------|----------|
| No `build_command` | Skip rebuild step |
| Build fails 3 times | Revert fix, mark FAILED_BUILD |
| Code reviewer returns Critical | Revert, re-attempt with rejection context |
| `max_iterations` exceeded | Stop, return MAX_ITERATIONS_EXCEEDED |
| Fix creates NEW issue | Add to queue (max cascade depth 2) |
| Retest times out | Treat as failure, next attempt |
| No `files_of_interest` | Infer via Grep/Glob on error messages |
| All prohibited actions violated | Mark UNRESOLVED, log reason |
