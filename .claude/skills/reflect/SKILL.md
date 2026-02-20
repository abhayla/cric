---
name: reflect
description: "Learning system: analyzes session outcomes, updates memory topics (testing-lessons, fix-patterns, skill-gaps), maintains failure index. Four modes: session (recent work), deep (modify skills/hooks), meta (learning effectiveness), test-run (dry run). Use after completing work or when user says 'reflect', 'what did we learn', or 'capture lessons'."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
metadata:
  version: 1.0.0
---

# Reflect — Learning System Analysis

Analyze skill outcomes, update memory, and optionally self-modify skills/hooks to close gaps.

**Arguments:** $ARGUMENTS

---

## Mode Selection

| Mode | Trigger | Modifies files? | Time |
|------|---------|-----------------|------|
| `session` (default) | Auto-invoked after skills, or `/reflect` | Memory topic files only | <60s |
| `deep` | `/reflect deep` | Memory + Skills + Hooks | <120s |
| `meta` | `/reflect meta` | Memory only | <60s |
| `test-run` | `/reflect test-run` | No (dry-run) | <90s |

Parse `$ARGUMENTS`: empty or `session` → session mode, `deep` → deep mode, `meta` → meta mode, `test-run` → test-run mode.

---

## Self-Skip Rule

This skill MUST NOT invoke itself. If during deep mode a re-run triggers `/reflect`, detect and break the cycle.

---

## Step 1: Gather Session Data

Read recent activity from multiple sources:

1. **Workflow state:**
   ```bash
   node -e "
   const fs = require('fs');
   try {
     const d = JSON.parse(fs.readFileSync('.claude/workflow-state.json'));
     console.log(JSON.stringify(d, null, 2));
   } catch { console.log('{}'); }
   "
   ```

2. **Fix-loop logs** (most recent session):
   ```
   Glob: .claude/logs/fix-loop/*/iteration-*.md
   ```

3. **Post-fix-pipeline evidence:**
   ```
   Glob: .claude/logs/post-fix-pipeline/evidence-*.json
   ```

4. **Git log** (recent commits this session):
   ```bash
   git log --oneline --since="8 hours ago" 2>/dev/null || echo "No recent commits"
   ```

---

## Step 2: Analyze Outcomes

For each skill invocation found in the session:

| Metric | How to Calculate |
|--------|-----------------|
| Success rate | RESOLVED / total invocations |
| Avg iterations | Total iterations / invocations |
| Common failure types | Group by error pattern |
| Fix patterns | Group by fix strategy (what worked) |
| Time sinks | Which issues consumed most iterations |

Produce a summary table:

```markdown
| Skill | Invocations | Resolved | Avg Iterations | Top Issue |
|-------|-------------|----------|----------------|-----------|
| fix-loop | N | N | N.N | {type} |
| post-fix-pipeline | N | N | — | {gate status} |
```

---

## Step 3: Update Memory Topic Files

Memory lives in the Claude Code auto-memory directory (the `memory/` folder alongside your project's `.claude/` config).

### 3a. Update `testing-lessons.md`

Add new entries for test failures and fixes discovered this session:

```markdown
### {date} — {feature area}
- **Issue:** {description}
- **Root cause:** {what was wrong}
- **Fix:** {what resolved it}
- **Prevention:** {how to avoid in future}
```

### 3b. Update `fix-patterns.md`

Add new fix patterns that worked:

```markdown
### {Pattern Name}
- **Error signature:** {error message pattern}
- **Root cause:** {description}
- **Fix strategy:** {what to do}
- **Files:** {typical files involved}
- **Auto-fix eligible:** Yes/No
- **Success count:** N
```

### 3c. Update `skill-gaps.md`

Record areas where skills/agents fell short:

```markdown
### {Gap Name}
- **Skill:** {which skill}
- **Scenario:** {what happened}
- **Impact:** {time wasted, manual intervention needed}
- **Recommendation:** {how to improve}
```

Create these files if they don't exist.

---

## Step 4: Update Failure Index

The failure index tracks recurring issues across sessions.

File: `.claude/logs/learning/failure-index.json`

Structure:
```json
{
  "entries": [
    {
      "skill": "fix-loop",
      "issue_type": "null_check_scoring",
      "occurrences": [
        { "date": "2026-02-16", "outcome": "RESOLVED", "iterations": 2 }
      ],
      "known_workaround": "Add null guard before accessing innings.battingStats",
      "auto_fix_eligible": true,
      "threshold_reached": false
    }
  ]
}
```

Rules:
- If issue type already exists → append to occurrences
- If 3+ consecutive UNRESOLVED → set `threshold_reached: true`
- If a fix worked → update `known_workaround` with the strategy
- If `auto_fix_eligible` patterns have accumulated 3+ successful fixes → mark as eligible

---

## Step 5: Deep Mode — Self-Modification (only in `deep` mode)

**Safety guards:**
- NEVER modify: CLAUDE.md, .claude/rules.md, .env files, build.gradle.kts
- Git stash before any modification
- Skip files with uncommitted changes
- Max 5 files per session, 50 lines per file
- Auto-revert if re-run shows degraded results
- Max 3 recursive depth levels

Allowed modifications:
- Skill SKILL.md files (improve descriptions, add edge cases)
- Hook .ps1 files (add new patterns, fix false positives)
- Agent definitions (adjust tools, model assignments)
- Memory topic files (always allowed)

After each modification:
1. Validate: `node -e "JSON.parse(fs.readFileSync('...'))"` for JSON, syntax check for others
2. If the modified skill/hook was used this session, re-run a quick test
3. If test shows DEGRADED → auto-revert via `git checkout -- {file}`

---

## Step 6: Meta Mode — Learning Effectiveness (only in `meta` mode)

Analyze the learning system itself:

1. Read all memory topic files
2. Count total entries in each topic
3. Analyze:
   - How many fix-patterns were reused (applied > 1 time)?
   - How many failure-index entries reached threshold?
   - Are skill-gaps being closed over time?
4. Convergence assessment: IMPROVING | PLATEAUED | OSCILLATING

---

## Workflow State Update

```bash
node -e "
const fs = require('fs');
const sf = '.claude/workflow-state.json';
try {
  const d = JSON.parse(fs.readFileSync(sf));
  d.skillInvocations.reflectInvoked = true;
  fs.writeFileSync(sf, JSON.stringify(d, null, 2));
} catch {}
"
```

---

## Output — Session Mode

```markdown
## Reflect: Session Analysis

### Captures Analyzed: N
### Skill Success Rates
{table from Step 2}

### New Insights
- {insight 1}
- {insight 2}

### Memory Updates
- testing-lessons.md: +{N} entries
- fix-patterns.md: +{N} entries
- skill-gaps.md: {N} gaps updated
- failure-index.json: {N} entries updated
```

## Output — Deep Mode

```markdown
## Reflect: Deep Analysis & Modification

### Modifications Applied
| # | File | Change | Validated | Result |
|---|------|--------|-----------|--------|
{table}

### Memory Updates
{same as session}
```

## Output — Meta Mode

```markdown
## Reflect: Meta-Analysis

### Fix Pattern Reuse Rate: {X}%
### Failure Index Entries: {N} total, {M} threshold reached
### Skill Gaps: {N} open, {M} closed
### Convergence: IMPROVING | PLATEAUED | OSCILLATING
### Recommendation: {action}
```

---

## Quick Reference

| Mode | Reads | Writes Memory | Modifies Skills/Hooks | Recurses |
|------|-------|---------------|----------------------|----------|
| session | workflow state, logs | Yes | No | No |
| deep | + skill/hook defs | Yes | Yes (with safety) | Yes (max 3) |
| meta | topics, modifications | Yes (meta only) | No | No |
| test-run | + skill/hook defs | No | No | No |
