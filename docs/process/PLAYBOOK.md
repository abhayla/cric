# Implementation Playbook

Autonomous implementation workflow for CricApp. Ties together all planning docs, agents, skills, and hooks into a step-by-step process.

**Prerequisites:** Read [CLAUDE.md](../../CLAUDE.md) and [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) before starting.

---

## 1. Per-Feature Autonomous Workflow (17 Steps — TDD)

Execute this workflow for every GitHub Issue (screen or feature). All 13 agents are used at specific workflow points — agents are **read-only context collectors** that never write code. Tests are written BEFORE implementation using strict Red-Green-Refactor TDD.

### Step 1: Load the Issue

```bash
gh issue view <number>
```

Read the acceptance criteria checklist. Identify which wireframes, tables, endpoints, and rules are involved.

### Step 2: Pre-Implementation Research (5-7 Agents in Parallel)

Invoke agents based on feature type. Always invoke the first two; add others based on the table below.

| Agent | When to Invoke | What It Returns |
|-------|---------------|-----------------|
| `cricheroes-comparator` | **Always** (CLAUDE.md mandate) | ADOPT/SKIP/DEFER comparison report |
| `ui-researcher` | **Always** (wireframe + theme compliance) | Layout discrepancies, theme violations, a11y issues |
| `scoring-researcher` | Scoring/deliveries/match state features | Cricket rule compliance, pipeline step implications |
| `database-researcher` | Schema/tables/sync features | Schema correctness, migration needs, sync implications |
| `api-researcher` | REST endpoints or WebSocket features | Endpoint spec compliance, request/response shapes |
| `planner-researcher` | Architecturally complex or multi-layer features | Implementation approach, cross-cutting concerns |
| `system-architect` | Architectural decisions (offline-first, data flow) | Architecture recommendations, trade-off analysis |

**Example (scoring page):**
```
Task(cricheroes-comparator, "Compare scoring page against CricHeroes")
Task(ui-researcher, "Analyze wireframe docs/ui/12-scoring-page.html for M3 Light compliance")
Task(scoring-researcher, "Verify scoring page covers all delivery pipeline steps")
Task(database-researcher, "Check deliveries/innings/overs schema for scoring page")
Task(api-researcher, "Verify scoring REST endpoints and WebSocket broadcast")
```

### Step 3: Write Domain Tests (RED)

Write tests BEFORE implementation. Tests should be written against interfaces and specs — NOT existing code.

1. Create test file at `test/src/features/<feature>/domain/`
2. Write unit tests for entity behavior, validation rules, and domain logic from SCORING_RULES.md / DATABASE.md
3. Write tests against repository interfaces (abstract contracts)
4. Run tests — **confirm FAIL (RED state)**
5. Do NOT implement anything yet

**Context isolation:** In RED phase, do NOT read existing implementation files — write tests against INTERFACES and SPECS only.

### Step 4: Implement Domain Layer (GREEN + REFACTOR)

1. Entity classes in `features/<feature>/domain/entities/`
2. Repository interfaces in `features/<feature>/domain/repositories/`
3. Pure Dart — no framework dependencies
4. Run tests — **confirm PASS (GREEN state)**
5. **REFACTOR:** Clean up without breaking tests
6. Run tests one final time after refactor

### Step 5: Write Data Tests (RED)

1. Create test file at `test/src/features/<feature>/data/`
2. Write tests with mocked datasources, testing repository contracts
3. Write tests for model serialization (Freezed toJson/fromJson round-trips)
4. Run tests — **confirm FAIL (RED state)**
5. Do NOT implement anything yet

### Step 6: Implement Data Layer (GREEN + REFACTOR)

1. Freezed models in `features/<feature>/data/models/` (add `@freezed` + `@JsonSerializable`)
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Local datasource (Drift) in `features/<feature>/data/datasources/`
4. Remote datasource (Dio) in `features/<feature>/data/datasources/`
5. Repository implementation in `features/<feature>/data/repositories/`
6. Run tests — **confirm PASS (GREEN state)**
7. **REFACTOR:** Clean up without breaking tests
8. Run tests one final time after refactor

### Step 7: Write Presentation Tests (RED)

1. Create test file at `test/src/features/<feature>/presentation/`
2. Write notifier state transition tests with mocked repository
3. Write widget tests (pump with `ProviderScope` overrides, tap buttons, verify UI updates)
4. Run tests — **confirm FAIL (RED state)**
5. Do NOT implement anything yet

### Step 8: Implement Presentation Layer (GREEN + REFACTOR)

1. Freezed state class for the notifier
2. Riverpod Notifier in `features/<feature>/presentation/notifiers/`
3. Page widget in `features/<feature>/presentation/pages/`
4. Feature-specific widgets in `features/<feature>/presentation/widgets/`
5. Provider declarations in `features/<feature>/providers.dart`
6. Run tests — **confirm PASS (GREEN state)**
7. **REFACTOR:** Clean up without breaking tests
8. Run tests one final time after refactor

### Step 9: Build Check

Run `/build-check` skill (or manually):
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
cd apps/mobile && flutter analyze
```
Fix all analysis issues before proceeding.

### Step 10: Playwright Wireframe Comparison

Follow the protocol in **Section 3** below. Run `/screenshot-verify XX` where XX is the screen number.

### Step 11: Post-Implementation Review (2 Agents)

```
Task(code-reviewer, "Review <feature> implementation for quality, YAGNI/KISS/DRY compliance")
Task(tester, "Check <feature> test coverage and identify gaps — tests should already exist from TDD steps")
```

Focus: The tester agent now verifies coverage GAPS rather than generating tests from scratch — tests already exist from Steps 3/5/7.

### Step 12: Fix Loop (Test Failures)

Follow [CODE_FIXES.md](CODE_FIXES.md) escalation tiers:
- **Normal (1-3 iterations):** Re-read failure, try a different code path
- **Tier 1 (4-5):** Slow down, challenge assumptions
- **Tier 2 (6-7):** Widen scope, trace full path — invoke `debugger` agent
- **Tier 3 (8-9):** Audit architecture
- **Hard Cap (10):** Stop and present findings to user

### Step 13: Fix Loop (Wireframe Mismatch)

If `/screenshot-verify` reported FAIL:
1. Fix the specific discrepancies listed
2. Re-run `/screenshot-verify XX`
3. Max 5 iterations — if still failing, log the discrepancy in the issue and continue

### Step 14: Commit

1. Invoke `git-manager` agent for safe git practices review
2. Commit with conventional commit referencing issue number:
   ```
   feat(scoring): implement scoring page UI (#42)
   ```

### Step 15: Update GitHub Issue

```bash
gh issue edit <number> --body "..." # Check off completed acceptance criteria
```

### Step 16: Session Handoff

Run `/session-handoff` to update `docs/CONTINUE_PROMPT.md` with:
- What was completed
- Next step
- Any blockers
- File tree changes

### Step 17: Next Issue or Phase Gate

- If more issues in the milestone → loop to Step 1
- If milestone complete → run `/phase-gate N` (see Section 2)

---

## 2. Per-Phase Checklists

### Phase 1: Foundation

**Entry:** Project start (no prerequisites)

**Issues (11):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 1 | Project initialization (Flutter + Bun) | — | infra |
| 2 | PostgreSQL + Drizzle schema + seed data | — | server |
| 3 | Firebase Auth setup + middleware | — | auth |
| 4 | M3 Light theme + go_router + auth guards | — | app |
| 5 | Splash screen | 01-splash | auth |
| 6 | Login page | 02-login | auth |
| 7 | OTP verification page | 03-otp | auth |
| 8 | Profile setup page | 04-profile-setup | auth |
| 9 | Home page (dashboard) | 05-home | home |
| 10 | Bottom navigation shell | — | app |
| 11 | Match history page (empty state) | 18-match-history | home |

**Screenshot comparisons:** 01, 02, 03, 04, 05, 18

**Exit criteria:**
- [ ] All 11 issues closed
- [ ] CI green (structure-validate + flutter-analyze + flutter-test)
- [ ] Login with Phone OTP → see home screen → navigate between tabs
- [ ] 6 wireframe comparisons pass
- [ ] 40%+ test coverage (auth notifier, domain entities)
- [ ] TDD coverage verified (tests written before implementation for each layer)
- [ ] `docs/CONTINUE_PROMPT.md` updated

**Phase gate agents:** `database-admin` (schema review), `docs-manager` (doc consistency)

---

### Phase 2: Teams & Match Setup

**Entry:** Phase 1 gate passed

**Issues (10):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 12 | Teams CRUD (API + service) | — | server |
| 13 | Teams list page | 06-teams-list | teams |
| 14 | Create team page | 07-create-team | teams |
| 15 | Team detail page | 08-team-detail | teams |
| 16 | Manage roster page + add player | 09-manage-roster, 28-add-player | teams |
| 17 | Match creation (API + service) | — | server |
| 18 | Match setup page | 10-match-setup | scoring |
| 19 | Toss page (5-step stepper) | 11-toss | scoring |
| 20 | Drift local database setup | — | infra |
| 21 | Basic offline data caching | — | infra |

**Screenshot comparisons:** 06, 07, 08, 09, 10, 11, 28

**Exit criteria:**
- [ ] All 10 issues closed
- [ ] Create team, add players, create match, complete toss works end-to-end
- [ ] 7 wireframe comparisons pass
- [ ] 50%+ test coverage
- [ ] TDD coverage verified (tests written before implementation for each layer)
- [ ] Offline caching verified (airplane mode → data persists)

---

### Phase 2.5: Tournament Management

**Entry:** Phase 2 gate passed

**Issues (10):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 22 | Tournament CRUD (API + service) | — | server |
| 23 | Tournaments list page | 19-tournaments-list | tournaments |
| 24 | Create tournament page | 20-create-tournament | tournaments |
| 25 | Tournament detail page | 21-tournament-detail | tournaments |
| 26 | Standings / Points table | 22-standings | tournaments |
| 27 | Knockout bracket visualization | 23-knockout-bracket | tournaments |
| 28 | Tournament leaderboard | 24-tournament-leaderboard | tournaments |
| 29 | Fixture generation algorithms | — | server |
| 30 | NRR calculation engine | — | server |
| 31 | Super over (trigger + scoring + UI) | 27-super-over-setup | scoring |

**Screenshot comparisons:** 19, 20, 21, 22, 23, 24, 27

**Exit criteria:**
- [ ] All 10 issues closed
- [ ] Create tournament (all 3 formats) → generate fixtures → complete 1 match → standings update
- [ ] NRR verified against manual calculation
- [ ] Super over triggers on knockout tie
- [ ] TDD coverage verified (tests written before implementation for each layer)
- [ ] 7 wireframe comparisons pass

---

### Phase 3: Scoring Engine (CRITICAL)

**Entry:** Phase 2.5 gate passed

**Issues (13):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 32 | Delivery recording (server-side pipeline) | — | server |
| 33 | Scoring state machine (Flutter notifier) | — | scoring |
| 34 | Scoring page UI | 12-scoring-page | scoring |
| 35 | Wicket dialog | 13-wicket-dialog | scoring |
| 36 | Extras panel | 14-extras-panel | scoring |
| 37 | Innings transition modal | 25-innings-transition | scoring |
| 38 | Match complete modal | 26-match-complete | scoring |
| 39 | Undo functionality | — | scoring |
| 40 | WebSocket server + room management | — | server |
| 41 | WebSocket client (Flutter) + live broadcast | — | scoring |
| 42 | Scorecard page | 15-scorecard | scoring |
| 43 | Full offline scoring + sync queue | — | scoring |
| 44 | Select new batter + select bowler modals | — | scoring |

**Screenshot comparisons:** 12, 13, 14, 15, 25, 26

**Exit criteria:**
- [ ] All 13 issues closed
- [ ] Score a complete T20 match ball-by-ball (40 overs)
- [ ] total_runs = sum of all deliveries
- [ ] Wickets count matches dismissals
- [ ] Strike rotation correct after every delivery type
- [ ] Extras attributed correctly (wide/NB to bowler, bye/LB to extras)
- [ ] Over changes after 6 legal deliveries
- [ ] Maiden overs detected
- [ ] All-out triggers innings completion
- [ ] Offline scoring works → syncs when reconnected
- [ ] 60+ scoring engine unit tests
- [ ] 60%+ overall test coverage
- [ ] TDD coverage verified (tests written before implementation for each layer)
- [ ] 6 wireframe comparisons pass

---

### Phase 4: Analytics & Visualizations

**Entry:** Phase 3 gate passed

**Issues (5):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 45 | Wagon wheel (CustomPainter) | 16-match-analytics | analytics |
| 46 | Manhattan chart (fl_chart) | 16-match-analytics | analytics |
| 47 | Worm graph (fl_chart) | 16-match-analytics | analytics |
| 48 | MVP algorithm + card | 16-match-analytics | analytics |
| 49 | Match analytics page (tabbed) | 16-match-analytics | analytics |

**Screenshot comparisons:** 16

**Exit criteria:**
- [ ] All 5 issues closed
- [ ] All 4 chart types render correctly with real match data
- [ ] Charts perform on 2GB RAM device (no jank)
- [ ] MVP rankings accurate
- [ ] 1 wireframe comparison passes

---

### Phase 5: Player Profiles & Stats

**Entry:** Phase 4 gate passed

**Issues (4):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 50 | Career stats aggregation (materialized views) | — | server |
| 51 | Player profile page | 17-player-profile | player_profile |
| 52 | Stats page (batting/bowling/fielding tabs) | 17-player-profile | player_profile |
| 53 | Stats refresh on match completion | — | server |

**Screenshot comparisons:** 17

**Exit criteria:**
- [ ] All 4 issues closed
- [ ] Career stats match manual aggregate of match performances
- [ ] Stats refresh automatically on match completion
- [ ] 1 wireframe comparison passes

---

### Phase 6: Polish & Testing

**Entry:** Phase 5 gate passed

**Issues (7):**

| # | Screen/Feature | Wireframes | Component |
|---|---------------|------------|-----------|
| 54 | Scoring engine unit tests (comprehensive) | — | testing |
| 55 | Cricket rules unit tests | — | testing |
| 56 | Scoring page widget tests | — | testing |
| 57 | Full match integration test | — | testing |
| 58 | Offline→online sync E2E test | — | testing |
| 59 | Performance testing (2GB RAM device) | — | testing |
| 60 | Home page dashboard (final) | 05-home | home |

**Exit criteria:**
- [ ] All 7 issues closed
- [ ] Unit test coverage: 60%+
- [ ] Widget test coverage: 30%+
- [ ] Integration test coverage: 10%+
- [ ] No P0 bugs open
- [ ] No jank on low-end device (< 16ms frame times)
- [ ] Cold start < 3s

---

### Phase 7: Deployment

Manual VPS configuration — no GitHub Issues. See [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) Phase 7 for full deployment tasks.

---

## 3. Playwright Wireframe Comparison Protocol

Step-by-step for comparing Flutter app against HTML wireframes.

### Setup

Serve wireframes locally (leave running in background):
```bash
python -m http.server 9123 --directory docs/ui
```

### Comparison Steps

1. **Navigate Playwright** to the wireframe:
   ```
   browser_navigate: http://localhost:9123/XX-name.html
   ```

2. **Screenshot wireframe:**
   ```
   browser_take_screenshot: .playwright-mcp/screenshots/wireframe-XX-name.png
   ```

3. **Screenshot Flutter app** (via flutter screenshot or Playwright on emulator):
   ```bash
   cd apps/mobile && flutter screenshot --out=../../.playwright-mcp/screenshots/app-XX-name.png
   ```

4. **Visual comparison** against 6 criteria:

   | # | Criterion | What to Check | Tolerance |
   |---|-----------|--------------|-----------|
   | 1 | Layout structure | Header/body/footer zones match | Exact zone match |
   | 2 | Component presence | All buttons, cards, fields, icons present | 100% — nothing missing |
   | 3 | Spacing compliance | 8dp grid, margins, padding | ±4-8dp tolerance |
   | 4 | M3 Light theme | Correct surface colors, seed #1976D2 | M3 token usage, no hardcoded colors |
   | 5 | Content accuracy | Labels, placeholder text match wireframe | Exact text match |
   | 6 | Touch targets | All interactive elements >= 48x48dp | No exceptions |

5. **Result:** PASS = all 6 criteria met. FAIL = any criterion violated.

6. **Fix loop:** Max 5 iterations. If unresolved after 5, log the discrepancy in the GitHub Issue and continue.

### Quick Reference: `/screenshot-verify XX`

Use the `/screenshot-verify` skill for automated comparison. Pass the screen number as argument (e.g., `/screenshot-verify 12`).

---

## 4. Screen-to-Issue Mapping (28 Wireframes → 22 Issues)

Modals and dialogs are grouped with their parent screen's issue.

| Issue | Screens (wireframes) | Phase | Feature |
|-------|---------------------|-------|---------|
| Splash | 01-splash | 1 | auth |
| Login | 02-login | 1 | auth |
| OTP Verification | 03-otp | 1 | auth |
| Profile Setup | 04-profile-setup | 1 | auth |
| Home Dashboard | 05-home | 1 | home |
| Match History | 18-match-history | 1 | home |
| Teams List | 06-teams-list | 2 | teams |
| Create Team | 07-create-team | 2 | teams |
| Team Detail | 08-team-detail | 2 | teams |
| Manage Roster + Add Player | 09-manage-roster, 28-add-player | 2 | teams |
| Match Setup | 10-match-setup | 2 | scoring |
| Toss (5-step stepper) | 11-toss | 2 | scoring |
| Tournaments List | 19-tournaments-list | 2.5 | tournaments |
| Create Tournament | 20-create-tournament | 2.5 | tournaments |
| Tournament Detail | 21-tournament-detail | 2.5 | tournaments |
| Standings | 22-standings | 2.5 | tournaments |
| Knockout Bracket | 23-knockout-bracket | 2.5 | tournaments |
| Tournament Leaderboard | 24-tournament-leaderboard | 2.5 | tournaments |
| Scoring Page + Wicket + Extras + Select Batter/Bowler | 12-scoring-page, 13-wicket-dialog, 14-extras-panel | 3 | scoring |
| Scorecard | 15-scorecard | 3 | scoring |
| Innings Transition + Match Complete + Super Over Setup | 25-innings-transition, 26-match-complete, 27-super-over-setup | 3 | scoring |
| Match Analytics | 16-match-analytics | 4 | analytics |
| Player Profile | 17-player-profile | 5 | player_profile |

### Issue Template

Each issue follows this structure:

```markdown
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

### TDD Checklist
- [ ] Domain tests written BEFORE domain implementation (RED→GREEN→REFACTOR)
- [ ] Data tests written BEFORE data implementation (RED→GREEN→REFACTOR)
- [ ] Presentation tests written BEFORE presentation implementation (RED→GREEN→REFACTOR)

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
**Tables:** ...
**Endpoints:** ...
**Rules:** ...

## Agents to Invoke
- [ ] `cricheroes-comparator` (pre-implementation)
- [ ] `ui-researcher` (pre-implementation)
- [ ] `code-reviewer` (post-implementation)
- [ ] `tester` (post-implementation)
```

### Labels

- `type: feature` — all screen/feature issues
- `P0: critical` — scoring engine, auth, core infrastructure
- `P1: important` — teams, tournaments, analytics, profiles
- `component: auth` / `component: scoring` / `component: teams` / `component: tournaments` / `component: analytics` / `component: player_profile` / `component: home` / `component: infra` / `component: server` / `component: testing`

### Milestones

- `Phase 1` — Foundation (11 issues)
- `Phase 2` — Teams & Match Setup (10 issues)
- `Phase 2.5` — Tournament Management (10 issues)
- `Phase 3` — Scoring Engine (13 issues)
- `Phase 4` — Analytics (5 issues)
- `Phase 5` — Player Profiles (4 issues)
- `Phase 6` — Polish & Testing (7 issues)

Use `/issue-create N` skill to auto-generate issues for a phase.

---

## 5. Session Management Protocol

### Starting a Session

1. Read `docs/CONTINUE_PROMPT.md` — "What to Do Next" section
2. Verify git state: `git status` + `git log --oneline -5`
3. Resume from the exact step documented

### During a Session

- After each issue completion, update `CONTINUE_PROMPT.md` via `/session-handoff`
- If context compaction occurs, the `reinject-after-compaction` hook auto-injects critical rules + current session context

### Ending a Session

The `quality-gate` hook blocks session end if `CONTINUE_PROMPT.md` hasn't been updated or if uncommitted source changes exist. Update it with:

1. **Completed work** — issues closed, features implemented
2. **Next step** — exact issue number and step in the 17-step TDD workflow
3. **TDD state** — which RED/GREEN/REFACTOR phase you're in per layer
4. **Blockers** — any unresolved issues or questions
5. **File tree changes** — new files created, modified files

### Edge Cases

| Scenario | Resolution |
|----------|-----------|
| Ambiguous wireframe | Use planning doc hierarchy: SCORING_RULES.md > DATABASE.md > API.md > CODE_STANDARDS.md |
| Agent conflicts | Prioritize: SCORING_RULES > DATABASE > API |
| Build errors | Max 5 fix iterations, then pause for user |
| Missing wireframe | Pause and ask user — never guess |
| Context compaction mid-feature | The hook re-injects rules + git state + current phase/screen/checklist status |
| Test failure at hard cap (10) | Stop, present findings to user, do NOT proceed |
