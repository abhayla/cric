---
name: phase-gate
description: Run phase completion gate checks to verify all exit criteria are met before progressing to the next implementation phase.
disable-model-invocation: true
context: fork
allowed-tools: Bash, Read, Glob, Grep, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot
---

# Phase Gate

Verify all exit criteria for a phase before progressing to the next one.

## Arguments

`$ARGUMENTS` should be the phase number (e.g., "1", "2", "2.5", "3").

## Steps

1. **Read phase definition** from `docs/planning/IMPLEMENTATION_PLAN.md` Section 5, Phase `$ARGUMENTS`.

2. **Check 5 criteria:**

### Criterion 1: GitHub Issues Closed
```bash
gh issue list --milestone "Phase $ARGUMENTS" --state open
```
- PASS if 0 open issues in the milestone.
- FAIL if any open issues remain — list them.

### Criterion 2: Test Suite Pass
```bash
cd apps/mobile && flutter test
cd apps/server && bun test
```
- PASS if both exit code 0.
- FAIL if any test failures — list failures.

### Criterion 3: Screenshot Comparisons
- For each screen in this phase, check if `.playwright-mcp/screenshots/wireframe-XX.png` exists.
- If screenshots exist, compare against app screenshots.
- PASS if all screens have passing comparisons (or no screens in this phase).
- FAIL if any missing or failing comparisons.

### Criterion 4: CI Green
```bash
gh run list --limit 1
```
- PASS if latest CI run status is "completed" with conclusion "success".
- FAIL if latest run failed — show which jobs failed.

### Criterion 5: Code Quality
```bash
cd apps/mobile && flutter analyze
cd apps/server && bunx tsc --noEmit
```
- PASS if both exit code 0 (no warnings or errors).
- FAIL if any issues found.

### Criterion 6: Test Coverage
```bash
cd apps/mobile && flutter test --coverage
cd apps/server && bun test --coverage
```
- PASS if overall coverage >= phase threshold:
  - Phase 1: 40%
  - Phase 2: 50%
  - Phase 2.5+: 60%
  - Phase 3 (Scoring Engine): 80%
- PASS if scoring feature files (`features/scoring/`) >= 90% (when Phase 4+ exists)
- FAIL if below threshold — list files with lowest coverage

3. **Report results:**

```
## Phase Gate: Phase $ARGUMENTS

| Criterion | Status | Details |
|-----------|--------|---------|
| GitHub Issues closed | PASS/FAIL | X open / Y total |
| Test suite pass | PASS/FAIL | X passed, Y failed |
| Screenshot comparisons | PASS/FAIL | X/Y screens verified |
| CI green | PASS/FAIL | Run #NNN status |
| Code quality | PASS/FAIL | Warnings/errors count |
| Test coverage | PASS/FAIL | X% (threshold: Y%) |

**Overall: PASS / FAIL**
```

4. **If FAIL:** List specific blockers that must be resolved. Do NOT proceed to the next phase.

5. **If PASS:** Invoke `database-admin` and `docs-manager` agents for phase-end review, then confirm the phase is complete.
