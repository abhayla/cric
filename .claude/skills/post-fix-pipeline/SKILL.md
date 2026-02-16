---
name: post-fix-pipeline
description: "Post-fix verification pipeline: regression tests, full test suite with auto-fix, documentation updates (docs-manager agent), git commit (git-manager agent). Use after fix-loop succeeds to verify no regressions before committing. Typically invoked by tdd, fix-loop, or implement workflows."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Write, Edit, Task
metadata:
  version: 1.0.0
---

# Post-Fix Pipeline

Post-fix verification and commit process. Runs regression tests, test suite verification with auto-fix, documentation updates via docs-manager agent, and git commit via git-manager agent. Uses gate logic to HARD BLOCK commits when tests fail.

**Arguments:** $ARGUMENTS

## Caller Context

This skill is invoked by: `/tdd`, `/fix-loop`, `/auto-verify`. Each provides different `test_suite_commands` and `commit_format`. Adapt behavior accordingly.

---

## Input Parameters

### Core

| Parameter | Required | Description |
|-----------|----------|-------------|
| `fixes_applied` | Yes | List of fixes: `[{file, line, description}]` |
| `files_changed` | Yes | All file paths modified |
| `session_summary` | Yes | Human-readable summary of what was fixed |

### Regression Testing

| Parameter | Default | Description |
|-----------|---------|-------------|
| `regression_commands` | `[]` | Commands for regression testing: `[{name, command, timeout}]` |
| `regression_max_fix_attempts` | `3` | Max fix-loop iterations for regressions |

### Test Suite Verification

| Parameter | Default | Description |
|-----------|---------|-------------|
| `test_suite_commands` | see below | Test suite commands as commit gate |
| `test_suite_max_fix_attempts` | `2` | Max auto-fix attempts when suites fail |

**Default test_suite_commands** (if empty and code files changed):
```json
[
  { "name": "flutter-test", "command": "cd apps/mobile && flutter test", "timeout": 300 },
  { "name": "flutter-analyze", "command": "cd apps/mobile && flutter analyze", "timeout": 120 },
  { "name": "server-test", "command": "cd apps/server && bun test", "timeout": 120 },
  { "name": "server-typecheck", "command": "cd apps/server && bunx tsc --noEmit", "timeout": 60 }
]
```

Only run suites relevant to changed files:
- `apps/mobile/` changes → flutter-test + flutter-analyze
- `apps/server/` changes → server-test + server-typecheck
- Both → all 4

### Documentation

| Parameter | Default | Description |
|-----------|---------|-------------|
| `docs_instructions` | `""` | Instructions for docs-manager agent. Empty = skip |

### Git Commit

| Parameter | Default | Description |
|-----------|---------|-------------|
| `commit_format` | `"fix({scope}): {summary}"` | Commit message template |
| `commit_scope` | `"fix"` | Scope for commit message |
| `push` | `false` | Whether to push after commit |

---

## Algorithm

### STEP 0: Initialize Evidence

```bash
mkdir -p .claude/logs/post-fix-pipeline/
```

Write `evidence-init-{timestamp}.json`:
```json
{ "event": "pipeline_start", "fixCount": N, "filesChanged": [...], "timestamp": "ISO8601" }
```

### STEP 1: Gate Check

If `fixes_applied` is empty → return `NO_FIXES`, skip all remaining steps.

### STEP 2: Regression Testing (if regression_commands non-empty)

For each command:
1. Run with timeout
2. Record `{ name, status: PASSED|FAILED, output }`

Gate decision:
- ALL pass → proceed to Step 3
- Any fail → enter `/fix-loop` (max `regression_max_fix_attempts`)
- Still failing after max → **HARD BLOCK** — skip Steps 3-5

### STEP 3: Test Suite Verification (if test_suite_commands non-empty)

For each command:
1. Run with timeout
2. Record `{ name, passed_count, failed_count, output }`

Gate decision:
- ALL pass → gate = PASSED → Step 4
- Any fail:
  1. Launch `tester` agent (read-only, via Task tool) with failed tests + diff of changes
  2. Apply fixes based on analysis (max `test_suite_max_fix_attempts`)
  3. Re-run suite after each fix
  4. If fixed → gate = PASSED_AFTER_FIX → Step 4
  5. If still failing → gate = FAILED → **HARD BLOCK** Steps 4-5

Write `evidence-testsuite-{timestamp}.json`.

### STEP 4: Documentation (only if gates passed)

If `docs_instructions` non-empty:
1. Launch `docs-manager` agent (via Task tool) with fixes, files, summary, instructions
2. Record files updated

If empty, update `docs/CONTINUE_PROMPT.md` with session summary.

### STEP 5: Git Commit (only if gates passed)

1. Launch `git-manager` agent (via Task tool) with:
   - files_changed + doc files from Step 4
   - commit_format with scope and summary
   - push flag
   - Instruction: stage relevant files, create commit, include Co-Authored-By tag
2. Record commit hash and message

### STEP 6: Finalize Evidence & Update Workflow State

Write `evidence-complete-{timestamp}.json`:
```json
{
  "event": "pipeline_complete",
  "status": "COMPLETED|BLOCKED_BY_REGRESSION|BLOCKED_BY_TEST_SUITE|NO_FIXES",
  "commitHash": "...",
  "filesChanged": [...]
}
```

Update workflow state:
```bash
node -e "
const fs = require('fs');
const sf = '.claude/workflow-state.json';
try {
  const d = JSON.parse(fs.readFileSync(sf));
  d.skillInvocations.postFixPipelineInvoked = true;
  d.skillInvocations.postFixPipelineResult = '{STATUS}';
  fs.writeFileSync(sf, JSON.stringify(d, null, 2));
} catch {}
"
```

---

## Gate Logic

| Condition | Regression? | Docs? | Commit? |
|-----------|-------------|-------|---------|
| No fixes applied | NO | NO | NO |
| Regressions PASSED | YES | YES | YES |
| Regressions FAILED (after max) | YES (blocked) | **NO** | **NO** |
| Test suite PASSED | N/A | YES | YES |
| Test suite PASSED_AFTER_FIX | N/A | YES | YES |
| Test suite FAILED (after max) | N/A | **NO** | **NO** |
| No test_suite_commands | N/A | YES | YES |

---

## Output

```markdown
## Post-Fix Pipeline Results

### Overall Status
- **Status:** COMPLETED | BLOCKED_BY_REGRESSION | BLOCKED_BY_TEST_SUITE | NO_FIXES

### Regression Testing
- **Gate:** PASSED | PASSED_AFTER_FIX | FAILED | NOT_RUN

### Test Suite Verification
- **Gate:** PASSED | PASSED_AFTER_FIX | FAILED | NOT_RUN
- **Per-suite:** {name}: {passed} passed, {failed} failed

### Documentation Updates
- Files updated: {list or "skipped"}

### Git Commit
- **Hash:** {hash}
- **Message:** {message}
- **Pushed:** true | false
(Show "BLOCKED — gate failed" if blocked)
```

---

## Post-Pipeline Learning

After producing the output (regardless of status), invoke:
```
Skill("reflect", args="session")
```

This captures pipeline outcomes into learning logs. Runs for all statuses including BLOCKED.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Regression command times out | Treat as FAILED |
| Test suite command times out | Treat as FAILED |
| Tester agent fails | Gate = FAILED, block commit |
| Docs agent fails | Log warning, proceed (non-blocking) |
| Git agent fails | Log error, report COMMIT_FAILED |
