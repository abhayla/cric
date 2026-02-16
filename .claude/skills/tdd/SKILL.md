---
name: tdd
description: "Guided TDD workflow enforcing Red-Green-Refactor cycle per layer (domain, data, presentation). Use when implementing new features, user says 'tdd', 'test first', or 'red green refactor'. Write failing tests first, then implement."
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, Task
metadata:
  version: 1.1.0
---

# TDD — Test-Driven Development

Guided Red-Green-Refactor workflow for a specific feature and layer, with enforcement gates and automated fix delegation.

## Arguments

`$ARGUMENTS` should be `<feature> <layer>` where:
- `<feature>` = feature name (e.g., `auth`, `scoring`, `teams`, `tournaments`)
- `<layer>` = `domain`, `data`, `presentation`, or `all` (runs all 3 in sequence)

Examples: `/tdd auth domain`, `/tdd scoring all`, `/tdd teams data`

---

## Step 0: Initialize Workflow State

```bash
node -e "
const fs = require('fs');
const sf = '.claude/workflow-state.json';
try {
  const d = JSON.parse(fs.readFileSync(sf));
  d.activeCommand = 'tdd';
  d.steps = {};
  d.fixesApplied = [];
  d.filesChanged = [];
  d.testResults = { lastRunPassed: null, failureCount: 0 };
  fs.writeFileSync(sf, JSON.stringify(d, null, 2));
} catch {}
"
```

## Step 0b: Pre-Execution Knowledge Check

Check failure index for known issues in this feature area:

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

If known workarounds exist for this feature → apply proactively.

---

## Pre-Steps

1. **Read planning docs** relevant to the feature:
   - `docs/planning/SCORING_RULES.md` — if scoring feature
   - `docs/planning/DATABASE.md` — if data layer or schema-related
   - `docs/planning/API.md` — if data layer with remote datasource
   - `docs/planning/IMPLEMENTATION_PLAN.md` — current phase scope
   - `.claude/rules.md` — file placement rules

2. **Identify test file locations:**
   - Domain: `apps/mobile/test/src/features/<feature>/domain/`
   - Data: `apps/mobile/test/src/features/<feature>/data/`
   - Presentation: `apps/mobile/test/src/features/<feature>/presentation/`

3. **Identify source file locations:**
   - Domain: `apps/mobile/lib/src/features/<feature>/domain/`
   - Data: `apps/mobile/lib/src/features/<feature>/data/`
   - Presentation: `apps/mobile/lib/src/features/<feature>/presentation/`

---

## SELF-ENFORCEMENT GATE: Pre-Implementation

Before writing any implementation code (Phase 2), answer:

```
Planning docs read?          -> [YES: list / NO - STOP]
Test locations identified?   -> [YES: paths / NO - STOP]
Source locations identified?  -> [YES: paths / NO - STOP]
Issue/phase context?         -> [YES: Phase N, Issue #X / NO - STOP]
```

---

## Phase 1: RED — Write Failing Tests

**Context isolation rule:** Do NOT read existing implementation files. Write tests against INTERFACES, SPECS, and PLANNING DOCS only.

For layer-specific test patterns, see:
- [references/domain-layer.md](references/domain-layer.md) — Domain entity TDD examples
- [references/data-layer.md](references/data-layer.md) — Datasource/repository TDD examples
- [references/presentation-layer.md](references/presentation-layer.md) — Notifier/widget TDD + async patterns

### Run Tests — Confirm FAIL
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

All tests MUST FAIL. If any pass, the test is not testing new behavior — rewrite it.

Output: `RED PHASE COMPLETE — Tests written: X, Tests failing: X (expected)`

---

## Phase 2: GREEN — Implement to Pass

Write the minimum code to make ALL red tests pass. Do not add untested functionality.

### Implementation Order (if `all`)
1. Domain entities + repository interfaces → run domain tests
2. Freezed models + datasources + repository implementations → run data tests
3. Notifiers + pages + widgets + providers.dart → run presentation tests

### Run build_runner if needed
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

### Run Tests — Confirm PASS
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

### On Failure — Delegate to /fix-loop

> **ENFORCEMENT GATE:** If tests fail, you MUST use the Skill tool to invoke `/fix-loop`. Do NOT fix failures inline without the skill.

If any tests fail after implementation:

```
Skill("fix-loop") with arguments:
  failure_output:         {raw test failure output}
  failure_context:        "TDD GREEN phase: <feature>/<layer>"
  files_of_interest:      {source files created in this phase}
  build_command:          "cd apps/mobile && dart run build_runner build --delete-conflicting-outputs"
  retest_command:         "cd apps/mobile && flutter test test/src/features/<feature>/<layer>/"
  retest_timeout:         300
  max_iterations:         6
  max_attempts_per_issue: 3
  prohibited_actions:     ["skip tests", "weaken assertions", "delete tests"]
  fix_target:             "production"
  log_dir:                ".claude/logs/fix-loop/"
```

**CRITICAL:** Do NOT proceed to Phase 3 until all tests pass (fix-loop returns RESOLVED).

Output: `GREEN PHASE COMPLETE — Tests passing: X/X`

---

## Phase 3: REFACTOR — Clean Up

With all tests green, refactor for clarity without changing behavior:
- Extract repeated code into helper functions
- Improve naming
- Simplify complex conditionals
- Apply KISS/DRY principles

### Run Tests — Confirm Still PASS
```bash
cd apps/mobile && flutter test test/src/features/<feature>/<layer>/
```

If any test fails during refactor → revert the refactoring change and try a different approach.

Output: `REFACTOR PHASE COMPLETE — Tests still passing: X/X`

---

## SELF-ENFORCEMENT GATE: Pre-Commit

Before producing the final report, answer:

```
ALL tests passing?           -> [YES: X/X / NO - STOP]
/fix-loop invoked for failures? -> [YES: RESOLVED / N/A (no failures) / NO - STOP]
Files follow placement rules?   -> [YES / NO - STOP]
No prohibited patterns?         -> [YES / NO - STOP]
```

---

## Post-Workflow: Verification & Commit Pipeline

If any fixes were applied during the GREEN phase:

> **ENFORCEMENT GATE:** You MUST invoke `/post-fix-pipeline` before committing.

```
Skill("post-fix-pipeline") with arguments:
  fixes_applied:          {list from fix-loop}
  files_changed:          {all source + test files created}
  session_summary:        "TDD: <feature>/<layer> — N tests, M source files"
  test_suite_commands:    [
    { name: "feature-tests", command: "cd apps/mobile && flutter test test/src/features/<feature>/", timeout: 300 },
    { name: "flutter-analyze", command: "cd apps/mobile && flutter analyze", timeout: 120 }
  ]
  test_suite_max_fix_attempts: 2
  docs_instructions:      "Update docs/CONTINUE_PROMPT.md with TDD session summary."
  commit_format:          "feat(<feature>): implement <layer> layer via TDD"
  commit_scope:           "<feature>"
  push:                   false
```

---

## Post-Workflow: Learning Capture

After the workflow completes (all phases done, or stopped due to failure):

```
Skill("reflect", args="session")
```

This captures the TDD session outcomes into structured learning logs.

---

## Final Report

```
## TDD Summary: <feature> / <layer>

| Phase | Status | Details |
|-------|--------|---------|
| RED | DONE | X tests written, all failing |
| GREEN | DONE | X tests passing, Y source files |
| REFACTOR | DONE | Tests still green after cleanup |

### Fix-Loop Activity (if invoked)
- Iterations: X
- Issues fixed: X
- Debugger invocations: X

### Pipeline Status
- Post-fix-pipeline: COMPLETED | BLOCKED | NOT_NEEDED

### Files Created
- Test files: [list]
- Source files: [list]
```

---

## TDD Exceptions

Skip TDD for:
- **Generated code** (*.g.dart, *.freezed.dart) — test the source, not generated output
- **Static UI with no logic** (splash screen, about page) — use screenshot verify instead
- **Configuration files** (router setup, theme constants) — test via integration tests
- **Third-party wrappers** (Firebase init, Drift database constructor) — test the layer above
