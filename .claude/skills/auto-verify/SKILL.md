---
name: auto-verify
description: "Post-change verification: identifies changed files, maps to targeted tests, runs tests with smart priority, analyzes failures, applies fixes, runs regression checks. Use after code changes, user says 'verify', 'check changes', 'run affected tests', or before committing."
allowed-tools: Bash, Read, Grep, Glob, Skill, Task
metadata:
  version: 1.0.0
---

# Auto-Verify

Post-change verification that identifies changed files, maps to targeted tests, runs tests, analyzes failures, applies fixes, and runs regression checks.

**Arguments:** $ARGUMENTS

---

## Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scope` | string | `"all"` | `flutter`, `server`, or `all` |
| `base` | string | `"HEAD"` | Git base ref for change detection |
| `max_iterations` | int | `5` | Max fix iterations before stopping |
| `skip_regression` | bool | `false` | Skip regression checks after fix |

---

## Step 1: Identify Changes

```bash
git diff --name-only {base}
git diff --name-only --cached
```

Combine staged + unstaged changes.

**Filter rules:**
- Include: `.dart`, `.ts`, `.sql` files
- Exclude: `docs/`, `*.md`, `*.json`, `*.yml`, test files, generated files (`*.g.dart`, `*.freezed.dart`)
- Skip: files with only whitespace/comment changes

**Classify each file:**

| Path Pattern | Category |
|---|---|
| `apps/mobile/lib/src/features/{feat}/` | `flutter-{feat}` |
| `apps/mobile/lib/src/shared/` | `flutter-shared` |
| `apps/server/src/services/` | `server-service` |
| `apps/server/src/routes/` | `server-route` |
| `apps/server/src/db/` | `server-db` |
| Test files | Skip (test changes don't trigger auto-verify) |

If no changed files match scope: report "No changes in scope" and exit SUCCESS.

---

## Step 2: Map to Tests (Smart Selection)

For each changed file, find tests using prioritized lookup.

### Priority 0 — Convention-Based (CricScores-Specific)

| Source Pattern | Test Pattern |
|---|---|
| `features/{feat}/domain/entities/{name}.dart` | `test/src/features/{feat}/domain/{name}_test.dart` |
| `features/{feat}/data/repositories/{name}.dart` | `test/src/features/{feat}/data/{name}_test.dart` |
| `features/{feat}/data/datasources/{name}.dart` | `test/src/features/{feat}/data/{name}_test.dart` |
| `features/{feat}/presentation/notifiers/{name}.dart` | `test/src/features/{feat}/presentation/{name}_test.dart` |
| `features/{feat}/presentation/pages/{name}.dart` | `test/src/features/{feat}/presentation/{name}_test.dart` |
| `features/{feat}/presentation/widgets/{name}.dart` | `test/src/features/{feat}/presentation/{name}_test.dart` |
| `shared/data/database/tables/{name}.dart` | `test/src/shared/data/database/{name}_test.dart` |
| `server/src/services/{name}.service.ts` | `server/test/services/{name}.service.test.ts` |
| `server/src/routes/{name}.routes.ts` | `server/test/routes/{name}.routes.test.ts` |

### Priority 1 — Feature-Level Fallback

If no direct test mapping found:
| Source in Feature | Run All Tests In |
|---|---|
| `features/scoring/*` | `test/src/features/scoring/` |
| `features/auth/*` | `test/src/features/auth/` |
| `features/matches/*` | `test/src/features/matches/` |
| `features/teams/*` | `test/src/features/teams/` |
| `features/tournaments/*` | `test/src/features/tournaments/` |
| `features/analytics/*` | `test/src/features/analytics/` |
| `features/players/*` | `test/src/features/players/` |
| `features/home/*` | `test/src/features/home/` |
| `shared/*` | `test/src/shared/` |
| `server/src/*` | `apps/server/test/` (all server tests) |

### Priority 2 — Import-Based

Use Grep to find test files that import the changed module. Cap at 10.

### Priority 3 — Full Module Fallback

- Flutter: `cd apps/mobile && flutter test`
- Server: `cd apps/server && bun test`

**Cap:** Maximum 20 test files per run. If more, fall back to Priority 3.

---

## Step 3: Pre-Check Failure Index

```bash
node -e "
const fs = require('fs');
try {
  const d = JSON.parse(fs.readFileSync('.claude/logs/learning/failure-index.json'));
  for (const e of d.entries || []) {
    if (e.known_workaround) console.log('KNOWN:', e.issue_type, '->', e.known_workaround);
  }
} catch { console.log('No failure index'); }
"
```

If a known pattern matches an area being tested → note for Step 5.

---

## Step 4: Run Targeted Tests

**Flutter:**
```bash
cd apps/mobile && flutter test {test_files}
```

**Server:**
```bash
cd apps/server && bun test {test_files}
```

Record: test count, pass count, fail count, duration.

---

## Step 4b: Static Analysis (Quick Lint)

After tests pass (or in parallel), run static analysis on changed files only:

**Flutter (if scope includes flutter):**
```bash
cd apps/mobile && flutter analyze {changed_dart_files}
```

**Server (if scope includes server):**
```bash
cd apps/server && bunx tsc --noEmit
```

**Classification:**
- **Errors** → treat as test failure, go to Step 5
- **Warnings** (deprecations, unused imports) → include in report, suggest fixes
- **Info** → include in report only

This ensures deprecation warnings, unused variables, and lint issues are caught alongside test failures.

---

## Step 5: Analyze & Fix (if failures)

If all pass → skip to Step 7.

If failures exist:

| Iteration | Action |
|---|---|
| 1 | Known pattern from failure-index? Apply known workaround → retest |
| 1 | Unknown failure? Analyze → apply fix → retest |
| 2 | Same error? Escalate: invoke `/fix-loop` with `max_iterations: 3` |
| 3+ | Same error 3x? **STOP** → ask user |
| max_iterations | **STOP** → show summary |

For each fix, update workflow state:
```bash
node -e "
const fs = require('fs');
const sf = '.claude/workflow-state.json';
try {
  const d = JSON.parse(fs.readFileSync(sf));
  d.fixesApplied.push({file: '{file}', line: '{line}', description: '{desc}'});
  d.filesChanged.push('{file}');
  fs.writeFileSync(sf, JSON.stringify(d, null, 2));
} catch {}
"
```

---

## Step 6: Regression Check (CricScores Adjacency Map)

After targeted tests pass, run adjacent tests to catch regressions.

| Fixed Area | Also Test |
|---|---|
| `scoring/domain` | `scoring/data`, `scoring/presentation` |
| `scoring/data` | `scoring/presentation`, `shared/data/sync` |
| `matches/domain` | `scoring/domain` (match state affects scoring) |
| `teams/data` | `matches/data` (team roster affects match setup) |
| `shared/data/database` | All features that use those tables |
| `server/services/scoring` | `server/routes/scoring`, `server/services/sync` |
| `server/db/schema` | All server services + `server/routes` |

```bash
cd apps/mobile && flutter test {adjacent_tests}
cd apps/server && bun test {adjacent_tests}
```

If regression found:
1. Revert the fix that caused regression
2. Escalate to `/fix-loop` with broader context
3. Record in failure index

---

## Step 7: Report

```markdown
## Auto-Verify Results

### Status: {SUCCESS | PARTIAL | FAILED | MAX_ITERATIONS}

### Summary
- Scope: {flutter | server | all}
- Changed files: N
- Tests mapped: N (P0: N, P1: N, P2: N)
- Tests run: N
- Tests passed: N / Tests failed: N
- Iterations used: N / max_iterations
- Regressions checked: N (passed: N, failed: N)

### Test Results
| Test File | Result | Duration | Notes |
|---|---|---|---|
| {test_path} | PASS (N/N) | N.Ns | |

### Analysis
| File | Errors | Warnings | Info |
|---|---|---|---|
| {file_path} | 0 | 0 | 0 |

### Fixes Applied
1. [{file}:{line}] {description}

### Regression Results
| Adjacent Area | Tests | Result |
|---|---|---|
| scoring/data | 5 | PASS |
```

---

## Post-Run

If any fixes were applied:
1. Invoke `/post-fix-pipeline` with the fixes
2. Then invoke `/reflect session` to capture learnings

If no fixes needed:
- Report SUCCESS and exit cleanly
