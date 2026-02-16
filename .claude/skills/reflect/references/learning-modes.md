# Reflect — Learning Modes Detail

## Session Mode — Lightweight Capture

**When:** Auto-invoked after skill completions, or `/reflect` with no args.

### Data Sources (read only)
1. `.claude/workflow-state.json` — current session state
2. `.claude/logs/fix-loop/*/` — iteration logs from fix-loop
3. `.claude/logs/post-fix-pipeline/` — evidence files
4. `git log --since="8 hours ago"` — recent commits
5. `git diff --name-only HEAD~5` — recently changed files

### Processing
1. Parse skill invocation results from workflow state
2. Parse fix-loop iteration logs for patterns
3. Identify new insights (error patterns, fix strategies)
4. Update memory topic files with new entries
5. Update failure-index.json with session outcomes

### Time Budget: 60 seconds max

---

## Deep Mode — Self-Modification

**When:** `/reflect deep` or auto-escalated (3+ consecutive unresolved in failure-index).

### Additional Data Sources
1. All skill SKILL.md files in `.claude/skills/`
2. All hook .ps1 files in `.claude/hooks/`
3. Agent definitions in `.claude/agents/`
4. Historical memory topic files

### Modification Process
1. Identify skill/hook that underperformed
2. Analyze root cause (missing pattern, wrong threshold, missing tool)
3. Propose modification (max 50 lines changed per file)
4. Apply with safety guards:
   - `git stash` before modification
   - Validate syntax after modification
   - If skill was used this session, re-run quick validation
   - Auto-revert if validation shows degradation

### Recursion Protocol
After modification, optionally re-invoke the modified skill with a test case:
- Depth 1: Re-run the specific scenario that triggered deep mode
- Depth 2: If still failing, try alternative modification
- Depth 3: Max depth — report findings, do NOT recurse further

### Time Budget: 120 seconds max

---

## Meta Mode — Learning Effectiveness

**When:** `/reflect meta` — periodic health check of the learning system.

### Analysis Dimensions

1. **Fix Pattern Coverage**
   - Total patterns in fix-patterns.md
   - Patterns applied > 1 time (reuse rate)
   - Patterns with auto-fix eligible = true
   - Patterns that prevented iteration escalation

2. **Failure Index Health**
   - Total entries
   - Entries with known_workaround
   - Entries at threshold (3+ unresolved)
   - Entries resolved after workaround was added

3. **Skill Gap Trends**
   - Open gaps vs closed gaps
   - Average time gaps stay open
   - Recurring themes in gaps

4. **Convergence Assessment**
   - IMPROVING: avg iterations per fix decreasing, reuse rate increasing
   - PLATEAUED: metrics stable for 5+ sessions
   - OSCILLATING: metrics alternating up/down

### Recommendations
Based on convergence:
- IMPROVING: "Continue current approach"
- PLATEAUED: "Consider /reflect deep to modify skills"
- OSCILLATING: "Review recent deep-mode modifications for conflicting changes"

### Time Budget: 60 seconds max

---

## Test-Run Mode — Dry Run

**When:** `/reflect test-run` — see what would change without writing.

### Process
1. Run all Steps 1-4 from session mode
2. Run Step 5 analysis from deep mode (identify modifications)
3. Present proposed changes WITHOUT writing any files
4. Show "Would affect: N files, ~N lines"

### Time Budget: 90 seconds max

---

## Memory File Conventions

### File Naming
- `testing-lessons.md` — Test failure patterns and fixes
- `fix-patterns.md` — Reusable fix strategies with error signatures
- `skill-gaps.md` — Areas where Claude Code skills need improvement
- `meta-reflections.md` — Deep mode modification history

### Entry Format
All entries should include:
- **Date:** ISO date
- **Context:** Which feature/phase/skill
- **Details:** Specific findings
- **Action:** What was done or should be done

### Deduplication
Before adding a new entry, search existing entries for:
- Same error signature (fix-patterns)
- Same skill + issue type (failure-index)
- Same gap description (skill-gaps)

If duplicate found, update the existing entry instead of creating a new one.

### Cleanup
During meta mode:
- Remove entries older than 30 days with no reuse
- Archive resolved skill gaps
- Consolidate duplicate fix patterns
