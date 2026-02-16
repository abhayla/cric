---
name: issue-create
description: "Create GitHub Issues for all screens/features in an implementation phase. Use when starting a new phase, user says 'create issues', 'plan phase', or 'generate tickets'. Cross-references wireframes, API.md, DATABASE.md, and SCORING_RULES.md."
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
metadata:
  version: 1.0.0
---

# Issue Create

Create GitHub Issues for all screens/features in a given phase.

## Arguments

`$ARGUMENTS` should be the phase number (e.g., "1", "2", "2.5", "3").

## Steps

1. **Read phase definition** from `docs/planning/IMPLEMENTATION_PLAN.md` Section 5, Phase `$ARGUMENTS` to identify all deliverables.

2. **Read the wireframe-to-issue mapping** from `docs/process/PLAYBOOK.md` Section 4 to get the screen groupings for this phase.

3. **Check for existing issues** to avoid duplicates:
   ```bash
   gh issue list --milestone "Phase $ARGUMENTS" --state all --limit 100
   ```

4. **For each issue in this phase:**

   a. Read the relevant wireframe HTML file(s) from `docs/ui/<number>-<name>.html`
   b. Cross-reference with:
      - `docs/planning/DATABASE.md` — tables and columns involved
      - `docs/planning/API.md` — endpoints required
      - `docs/planning/SCORING_RULES.md` — cricket rules (if scoring-related)
   c. Extract acceptance criteria from the wireframe (components, fields, interactions)

5. **Create each issue** using the template in [references/issue-template.md](references/issue-template.md).

6. **After creating all issues**, verify:
   ```bash
   gh issue list --milestone "Phase $ARGUMENTS" --state open
   ```

7. **Report summary:**
   ```
   ## Issues Created for Phase $ARGUMENTS

   | # | Title | Labels | Wireframes |
   |---|-------|--------|------------|
   | NNN | Screen Name | component: area | XX-name.html |
   ...

   Total: X issues created, Y already existed (skipped)
   ```
