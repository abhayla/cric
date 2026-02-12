---
name: issue-create
description: Create GitHub Issues for a phase from wireframe HTML files, cross-referenced with API.md, DATABASE.md, and SCORING_RULES.md.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
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

5. **Create each issue** using this template:

   ```bash
   gh issue create --title "<screen/feature name>" --milestone "Phase $ARGUMENTS" --label "type: feature" --label "P0: critical" --label "component: <area>" --body "$(cat <<'EOF'
   ## User Story
   As a [role], I want to [action] so that [benefit].

   ## Acceptance Criteria

   ### Domain Layer
   - [ ] Entity classes created
   - [ ] Repository interface defined

   ### Data Layer
   - [ ] Freezed models with JSON serialization
   - [ ] Local datasource (Drift)
   - [ ] Remote datasource (Dio)
   - [ ] Repository implementation

   ### Presentation Layer
   - [ ] Notifier with Freezed state
   - [ ] Page widget
   - [ ] Feature-specific widgets
   - [ ] providers.dart declarations

   ### Tests
   - [ ] Domain unit tests
   - [ ] Repository unit tests (mocked datasources)
   - [ ] Notifier unit tests (mocked repo)
   - [ ] Widget tests

   ### Wireframe Comparison
   - [ ] Screenshot matches wireframe (`/screenshot-verify XX`)

   ## Design Reference
   Wireframe: `docs/ui/XX-name.html`

   ## Technical Notes
   **Tables:** `table1`, `table2`
   **Endpoints:** `GET /api/v1/...`, `POST /api/v1/...`
   **Rules:** (if applicable)

   ## Agents to Invoke
   - [ ] `cricheroes-comparator` (pre-implementation)
   - [ ] `ui-researcher` (pre-implementation)
   - [ ] `code-reviewer` (post-implementation)
   - [ ] `tester` (post-implementation)
   EOF
   )"
   ```

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
