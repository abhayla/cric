# GitHub Issues Management

## Issue Templates

### Bug Report

```markdown
## Bug Report

**Description:**
[Clear, concise description of the bug]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Screenshots/Recordings:**
[Attach screenshots or screen recordings if UI-related]

**Device Info:**
- Device: [e.g., Samsung Galaxy A12]
- Android Version: [e.g., 12]
- RAM: [e.g., 3GB]
- App Version: [e.g., 0.1.0]

**Severity:**
- [ ] P0 - Critical (app crash, data loss, scoring incorrect)
- [ ] P1 - High (feature broken, workaround exists)
- [ ] P2 - Medium (minor incorrect behavior)
- [ ] P3 - Low (cosmetic, edge case)

**Additional Context:**
[Any other relevant information, logs, or error messages]
```

### Feature Request

```markdown
## Feature Request

**User Story:**
As a [role], I want to [goal] so that [benefit].

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Implementation Phase:** [1-7, per IMPLEMENTATION_PLAN.md]

**Priority:**
- [ ] P0 - Must have for MVP
- [ ] P1 - Should have for MVP
- [ ] P2 - Nice to have
- [ ] P3 - Future consideration

**Design Reference:**
[Link to blueprint.html section or wireframe if applicable]

**Technical Notes:**
[Any implementation considerations, affected tables, endpoints, etc.]
```

### Task

```markdown
## Task

**Description:**
[What needs to be done]

**Subtasks:**
- [ ] [Subtask 1]
- [ ] [Subtask 2]
- [ ] [Subtask 3]

**Implementation Phase:** [1-7]

**Effort Estimate:** [S/M/L/XL]
- S = < 2 hours
- M = 2-8 hours
- L = 1-3 days
- XL = 3+ days

**Dependencies:**
[List any issues that must be completed first]

**Relevant Docs:**
[Links to specific sections in planning docs]
```

---

## Label System

### Type Labels

| Label | Color | Description |
|-------|-------|-------------|
| `type: bug` | `#d73a4a` (red) | Something isn't working correctly |
| `type: feature` | `#0075ca` (blue) | New functionality |
| `type: task` | `#e4e669` (yellow) | Infrastructure, setup, configuration |
| `type: enhancement` | `#a2eeef` (cyan) | Improvement to existing feature |
| `type: docs` | `#0075ca` (blue) | Documentation updates |

### Priority Labels

| Label | Color | Description |
|-------|-------|-------------|
| `P0: critical` | `#b60205` (dark red) | Blocks release, data loss, crash |
| `P1: high` | `#d93f0b` (orange) | Important for current phase |
| `P2: medium` | `#fbca04` (yellow) | Should be done this phase |
| `P3: low` | `#0e8a16` (green) | Can wait for next phase |

### Component Labels

| Label | Description |
|-------|-------------|
| `component: scoring-engine` | Delivery processing, state machine, cricket rules |
| `component: offline-sync` | Drift DB, sync queue, conflict resolution |
| `component: websocket` | Real-time broadcasting, rooms, reconnection |
| `component: auth` | Firebase Auth, JWT, login/signup flow |
| `component: teams` | Team CRUD, roster management |
| `component: analytics` | Wagon wheel, manhattan, worm, MVP |
| `component: player-stats` | Career stats, batting/bowling/fielding aggregates |
| `component: ui` | Screens, widgets, theme, layout |
| `component: backend` | ElysiaJS routes, services, middleware |
| `component: database` | Drizzle schema, migrations, queries |

### Status Labels

| Label | Description |
|-------|-------------|
| `status: needs-triage` | New issue, not yet reviewed |
| `status: ready` | Triaged, ready for implementation |
| `status: blocked` | Blocked by another issue or decision |
| `status: wontfix` | Intentionally not fixing |

---

## Milestones

Map milestones to the 7 implementation phases from [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md).

| Milestone | Phase | Description |
|-----------|-------|-------------|
| `Phase 1: Foundation` | 1 | Project setup, auth, theme, navigation |
| `Phase 2: Match Setup` | 2 | Teams, match creation, toss, player selection |
| `Phase 3: Scoring Engine` | 3 | Ball-by-ball scoring, all delivery types, undo |
| `Phase 4: Real-time & Sync` | 4 | WebSocket broadcasting, offline sync |
| `Phase 5: Stats & Analytics` | 5 | Career stats, match analytics, MVP |
| `Phase 6: Polish` | 6 | Performance, edge cases, UX refinement |
| `Phase 7: Release` | 7 | Testing, Play Store submission, launch |

---

## Issue Workflow

```
Create issue (use template)
    ↓
Add labels: type + priority + component
    ↓
Assign to milestone (phase)
    ↓
Status: needs-triage → ready (after review)
    ↓
Start work:
    ├── Create branch from main
    │   ├── Feature: feature/<issue-#>-<short-name>
    │   ├── Bug fix: fix/<issue-#>-<short-name>
    │   └── Task: task/<issue-#>-<short-name>
    ↓
Implement (follow IMPLEMENTATION_PRACTICES.md)
    ↓
Create PR referencing the issue
    ├── PR title: "feat: <description> (#<issue-number>)"
    ├── PR body: references issue, describes changes, test plan
    ↓
Merge PR → issue auto-closes via "Closes #<number>" in PR body
```

---

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/) with issue references.

### Format

```
<type>: <description> (#<issue-number>)

[optional body]

[optional footer]
```

### Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation changes only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Build, CI, dependencies, tooling |
| `perf` | Performance improvement |
| `style` | Code formatting (no logic change) |

### Examples

```
feat: implement ball-by-ball scoring UI (#15)
fix: correct maiden detection when byes scored (#42)
docs: add offline sync pattern to implementation practices
refactor: extract delivery validation into shared function (#38)
test: add exhaustive dismissal type tests (#30)
chore: update Flutter to 3.x and Riverpod to 3.0
```

### Rules

- Subject line: imperative mood, lowercase, no period, max 72 characters
- Reference issue number in subject when applicable
- Body: explain WHY the change was made, not WHAT (the diff shows what)
- Use `Closes #<number>` in footer to auto-close the linked issue on merge
