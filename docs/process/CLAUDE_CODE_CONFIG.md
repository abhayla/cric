# Claude Code Configuration

This document defines sub-agent specifications, skill definitions, hooks, and MCP server configuration for Claude Code when working on CricScores. Agents and skills are implemented as actual config files in `.claude/agents/` and `.claude/skills/`.

---

## Design Rationale

### Agents as Context Collectors

Agents are **research-only context collectors**, not implementers. They read, analyze, and summarize — they never write or edit code. This design is based on two key insights:

1. **Minimizing context rot**: Focused prompts with only domain-relevant context produce more accurate results than broad, general-purpose prompts. Each agent carries only the documentation and file paths relevant to its domain.

2. **Separation of concerns**: The main agent makes implementation decisions with full project context. Sub-agents gather deep domain-specific context that the main agent can use. This prevents sub-agents from making changes that conflict with the broader implementation plan.

### Agent Tool Restrictions

All agents have access to: `Read, Grep, Glob, WebFetch, WebSearch`

They deliberately lack: `Edit, Write, Bash` — ensuring they can only observe, never modify.

### Skills as User-Invocable Only

All skills use `disable-model-invocation: true`. This means Claude Code will never auto-run these skills — the user must explicitly invoke them with `/<skill-name>`. This prevents unintended test runs, migrations, or file modifications.

---

## Sub-Agents (14)

> **Implementation:** Config files in `.claude/agents/*.md`

### 1. Scoring Engine Researcher — `scoring-researcher`

**Purpose:** Research and analyze cricket scoring logic — delivery processing pipeline, strike rotation, extras, dismissals, and undo mechanics.

**Config file:** `.claude/agents/scoring-researcher.md`

**Context files read before every task:**
- [SCORING_RULES.md](../planning/SCORING_RULES.md) — Full delivery pipeline, state machine, all cricket rules
- [DATABASE.md](../planning/DATABASE.md) — `deliveries`, `batting_stats`, `bowling_stats`, `fielding_stats`, `innings` tables

**Domain expertise:**
- 10-step delivery processing pipeline analysis
- Strike rotation verification for all delivery types
- Extras handling (wides, no-balls, byes, leg-byes)
- All 12 dismissal types
- Undo correctness verification

**Key files this agent investigates:**
- `apps/mobile/lib/src/features/scoring/` — all files
- `apps/mobile/lib/src/core/utils/cricket_utils.dart`
- `apps/server/src/services/scoring.service.ts`
- `apps/server/src/utils/cricket-rules.ts`

---

### 2. Database & Sync Researcher — `database-researcher`

**Purpose:** Research and analyze database schemas, migrations, sync engine, and data access patterns.

**Config file:** `.claude/agents/database-researcher.md`

**Context files read before every task:**
- [DATABASE.md](../planning/DATABASE.md) — All 24 tables, 5 materialized views, indexes, SQLite local schema
- [API.md](../planning/API.md) — Sync endpoints (Section 1.8)

**Domain expertise:**
- Schema verification against DATABASE.md spec
- Drift ↔ Drizzle cross-platform parity analysis
- Sync engine flow (offline queue → server push → UUID mapping → conflict resolution)
- Index naming and foreign key constraint verification
- Materialized view refresh strategies

**Key files this agent investigates:**
- `apps/server/src/db/` — schema, migrations, seed
- `apps/mobile/lib/src/shared/data/database/` — Drift tables, DAOs
- `apps/mobile/lib/src/shared/data/sync/` — sync engine
- `apps/server/src/services/sync.service.ts`

---

### 3. UI Researcher — `ui-researcher`

**Purpose:** Research and analyze Flutter UI implementation, widget structure, theme compliance, and blueprint wireframe adherence.

**Config file:** `.claude/agents/ui-researcher.md`

**Context files read before every task:**
- [blueprint.html](../planning/blueprint.html) — Wireframes for all 18 screens and 5 scoring dialogs
- [.claude/rules.md](../../.claude/rules.md) — Widget placement rules (Section 3)

**Domain expertise:**
- Screen layout comparison against blueprint wireframes
- Material 3 light theme token compliance (no hardcoded colors)
- Accessibility: 48x48dp touch targets, semantics
- Performance: ListView.builder, Riverpod select() for granular rebuilds
- Widget placement rule verification

**Key files this agent investigates:**
- `apps/mobile/lib/src/features/*/presentation/` — pages and widgets
- `apps/mobile/lib/src/shared/widgets/` — shared widgets
- `apps/mobile/lib/src/core/theme/` — theme and colors

---

### 4. API & WebSocket Researcher — `api-researcher`

**Purpose:** Research and analyze REST API routes, service layer logic, WebSocket protocol, and middleware configuration.

**Config file:** `.claude/agents/api-researcher.md`

**Context files read before every task:**
- [API.md](../planning/API.md) — All REST endpoints with request/response examples, WebSocket protocol
- [DATABASE.md](../planning/DATABASE.md) — Table schemas for query building

**Domain expertise:**
- REST endpoint spec compliance (paths, methods, request/response shapes, status codes)
- Thin route handler pattern verification (validate → call service → return)
- Firebase JWT middleware on authenticated routes
- WebSocket message type compliance against API.md Section 2
- Service layer architecture (one service per domain, correct dependency flow)

**Key files this agent investigates:**
- `apps/server/src/routes/v1/` — all route files
- `apps/server/src/services/` — all service files
- `apps/server/src/websocket/` — handler, rooms, types
- `apps/server/src/middleware/` — auth, error handler, CORS
- `apps/server/src/types/` — all type definitions

---

### 5. CricHeroes Comparator — `cricheroes-comparator`

**Purpose:** Compare CricScores features against CricHeroes (market leader, 40M+ users). Produces structured comparison reports with adopt/skip/defer gap recommendations.

**Config file:** `.claude/agents/cricheroes-comparator.md`

**Context files read before every task:**
- [CRICHEROES_REFERENCE.md](../planning/CRICHEROES_REFERENCE.md) — Pre-built CricHeroes knowledge base (relevant section for the feature)
- Relevant CricScores planning doc (DATABASE.md, API.md, SCORING_RULES.md, blueprint.html)

**Domain expertise:**
- CricHeroes feature inventory (scoring, teams, tournaments, analytics, profiles, community)
- UI/UX pattern comparison (layout, flows, components, interaction patterns)
- Feature gap analysis with adopt/skip/defer recommendations and effort estimates
- Performance benchmarking (app size, scoring speed, offline capability, device support)

**When invoked:**
- Automatically before implementing any new feature or screen (per CLAUDE.md workflow rule)
- When making significant UI/UX design decisions
- When user asks "how does CricHeroes handle [X]?"

**Key files this agent investigates:**
- `docs/planning/CRICHEROES_REFERENCE.md` — primary knowledge base
- `docs/planning/DATABASE.md`, `API.md`, `SCORING_RULES.md`, `blueprint.html` — CricScores specs
- `apps/mobile/lib/src/features/` — existing implementation (if any)
- Live web: `blog.cricheroes.com`, `cricheroes.com`, Play Store listing

---

### 6. System Architect — `system-architect`

**Purpose:** Expert system architect for CricScores. Architectural decisions, system design reviews, database schema analysis, API design, scoring engine architecture, offline-first patterns, and WebSocket protocol design.

**Config file:** `.claude/agents/system-architect.md`

**Domain expertise:**
- Cricket domain logic and Flutter+Bun stack
- Real-time mobile systems design
- Offline-first architecture patterns
- Database schema optimization

---

### 7. Code Reviewer — `code-reviewer`

**Purpose:** Comprehensive code review and quality assessment. Use after implementing features, before merging PRs, for security vulnerability assessment, or when optimizing performance.

**Config file:** `.claude/agents/code-reviewer.md`

**Domain expertise:**
- Code quality and technical debt analysis
- Security vulnerability assessment
- Performance bottleneck identification
- Best practices compliance

---

### 8. Database Admin — `database-admin`

**Purpose:** Database administration and performance optimization. Diagnosing performance bottlenecks, optimizing structures, managing indexes, analyzing query performance.

**Config file:** `.claude/agents/database-admin.md`

**Domain expertise:**
- PostgreSQL performance optimization
- Index management and query analysis
- Backup strategies and health assessment

---

### 9. Debugger — `debugger`

**Purpose:** Issue investigation and debugging specialist. Diagnosing errors, analyzing system behavior, investigating performance problems, examining logs.

**Config file:** `.claude/agents/debugger.md`

**Domain expertise:**
- Error diagnosis and root cause analysis
- Performance problem investigation
- Test failure debugging
- Log analysis (server, CI/CD)

---

### 10. Docs Manager — `docs-manager`

**Purpose:** Technical documentation management. Creating/updating docs, establishing implementation standards, syncing docs with code changes.

**Config file:** `.claude/agents/docs-manager.md`

**Domain expertise:**
- Documentation structure and consistency
- Cross-reference link validation
- Documentation summary reports

---

### 11. Git Manager — `git-manager`

**Purpose:** Git operations specialist. Staging, committing, and pushing code changes safely with proper conventional commit messages.

**Config file:** `.claude/agents/git-manager.md`

**Domain expertise:**
- Conventional commit message formatting
- Branch workflow operations
- Safe git practices

---

### 12. Planner Researcher — `planner-researcher`

**Purpose:** Technical research and planning specialist. Researching best practices, analyzing codebase structure, designing system architectures, breaking down complex requirements.

**Config file:** `.claude/agents/planner-researcher.md`

**Domain expertise:**
- Best practices research
- System architecture design
- Requirements breakdown
- Technical planning

---

### 13. Tester — `tester`

**Purpose:** Testing and quality assurance specialist. Running test suites, analyzing coverage, validating error handling, checking performance requirements.

**Config file:** `.claude/agents/tester.md`

**Domain expertise:**
- Test suite execution and analysis
- Coverage analysis
- Error handling validation
- Build process verification

---

### 14. Reviewer — `reviewer`

**Purpose:** Requirements verification and comprehensive review agent. Compares implementation against acceptance criteria, planning docs, wireframes, and domain rules. Produces requirements traceability matrix with PASS/WARN/BLOCK verdict. Runs at PLAYBOOK Step 11 (Stage 3).

**Config file:** `.claude/agents/reviewer.md`

**Context files read before every task:**
- GitHub issue acceptance criteria (via `gh issue view`)
- Relevant planning docs (DATABASE.md, API.md, SCORING_RULES.md)
- Wireframe HTML (if UI feature)
- `.claude/skills/cricket-domain/SKILL.md` — cricket rules reference

**Domain expertise:**
- Requirements traceability (acceptance criteria → code + test)
- Spec-to-code comparison (planning docs → implementation)
- Cross-domain consistency (schema parity, API-schema alignment, domain rule compliance)
- Unified PASS/WARN/BLOCK verdict with actionable BLOCK items

**When invoked:**
- PLAYBOOK Step 11 Stage 3 (after code-reviewer + tester + domain agents)
- Before any merge or milestone completion

---

## Hooks (10)

> **Implementation:** PowerShell scripts in `.claude/hooks/*.ps1`
>
> Hooks run automatically on specific events. They read JSON from stdin, validate, and exit 0 (allow) or 2 (block with stderr message).

### Hook 1: File Placement Validator

**File:** `.claude/hooks/validate-file-placement.ps1`
**Event:** PreToolUse on `Edit|Write`

Validates file paths against rules.md before any write. Checks: no files in `lib/` root except `main.dart`, `snake_case.dart` naming, no widgets in `core/`, no `models/` in `domain/`, service `.service.ts` suffix, page/notifier/model suffixes, no files in server `src/` root except `index.ts`.

**Skips:** `.claude/`, `docs/`, `test/`, `node_modules/`, `build/`, `.dart_tool/`, `android/`, generated files, config files at project root.

---

### Hook 2: Cross-Feature Import Guard

**File:** `.claude/hooks/guard-cross-feature-imports.ps1`
**Event:** PreToolUse on `Write`

For Dart files in `features/<A>/`, scans content for imports from `features/<B>/(data|domain)/`. Blocks with guidance to use shared/ providers instead.

**Skips:** Non-Dart files, test files, generated files, files not in a feature directory.

---

### Hook 3: Sensitive File Protection

**File:** `.claude/hooks/protect-sensitive-files.ps1`
**Event:** PreToolUse on `Edit|Write`

Blocks writes to `.env*`, `*credentials*`, `*service-account*`, `google-services.json`, `*.key`, `*.pem`, `*.p12`.

**Allows:** `.env.example`, files in `docs/`, files in `test/`.

---

### Hook 4: Session Start Context Loader

**File:** `.claude/hooks/load-session-context.ps1`
**Event:** SessionStart (startup, resume)

Reads `docs/CONTINUE_PROMPT.md` and outputs the "What to Do Next" section to stdout, injecting it as context for Claude. Never blocks.

---

### Hook 5: Post-Compaction Context Re-injection

**File:** `.claude/hooks/reinject-after-compaction.ps1`
**Event:** SessionStart (compact)

After context compaction, outputs condensed critical rules: top 10 file placement anti-patterns, 10-step delivery pipeline, match state machine, 5 critical cricket rules. Never blocks.

---

### Hook 6: Session Handoff Reminder

**File:** `.claude/hooks/remind-session-handoff.ps1`
**Event:** Stop

Checks if `docs/CONTINUE_PROMPT.md` has uncommitted changes. If source files were changed but CONTINUE_PROMPT.md was not updated, blocks with a reminder. Skips for pure research sessions (no source file changes).

---

### Hook 7: Bash Command Safety Guard

**File:** `.claude/hooks/guard-bash-commands.ps1`
**Event:** PreToolUse on `Bash`

Blocks destructive commands: `rm -rf`, `rm -fr`, `git push --force`, `git push -f`, `git reset --hard`, `git clean -f`, `git clean -fd`, `git branch -D`, `--no-verify`. Allows `git push --force-with-lease` as a safer alternative.

---

### Hook 8: CricHeroes Comparator Auto-Invoke

**File:** `.claude/hooks/auto-invoke-cricheroes-comparator.ps1`
**Event:** PreToolUse on `Write`

Auto-invokes CricHeroes comparison when creating new feature files in `apps/mobile/lib/src/features/`. Non-blocking reminder.

---

### Hook 9: Auto-Format

**File:** `.claude/hooks/auto-format.ps1`
**Event:** PostToolUse on `Edit|Write`

Formats `.dart` files with `dart format --fix` and `.ts` files with `npx prettier --write` after every Edit/Write. Skips generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`). Never blocks.

---

### Hook 10: Schema Parity Reminder

**File:** `.claude/hooks/remind-schema-parity.ps1`
**Event:** PostToolUse on `Edit|Write`

Non-blocking reminder when Drizzle schema files (`apps/server/src/db/schema/*.ts`) or Drift table files (`apps/mobile/lib/src/shared/data/database/tables/*.dart`) are modified. Reminds to run `/schema-parity` and relevant code generation commands. Never blocks.

---

## MCP Servers (2)

### PostgreSQL MCP (project-scope)

**Config:** `.mcp.json` at project root (gitignored — contains connection string)
**Server:** `@modelcontextprotocol/server-postgres` via `cmd /c npx`
**Connection:** `postgresql://cricapp_user:<password>@localhost:5432/cricapp_dev`
**Security:** Read-only database user (SELECT grants only)

### GitHub MCP (user-scope)

**Config:** Via `claude mcp add --scope user` (stored in user's global config, not in project)
**Server:** GitHub's official MCP endpoint
**Used for:** PR creation/review, issue management, Actions status checks
**Authentication:** Personal access token with `repo`, `workflow` scopes

---

## Skills (16)

> **Implementation:** Config files in `.claude/skills/<skill-name>/SKILL.md`
>
> All skills are user-invocable only (`disable-model-invocation: true`). Invoke with `/<skill-name>`.

### `/score-test`

**Purpose:** Run the scoring engine test suite.

**Config file:** `.claude/skills/score-test/SKILL.md`

**Command:**
```bash
cd apps/mobile && flutter test test/src/features/scoring/
```

**When to use:** After any change to scoring logic, delivery processing, strike rotation, or undo functionality.

---

### `/build-check`

**Purpose:** Run code generation and static analysis.

**Config file:** `.claude/skills/build-check/SKILL.md`

**Commands:**
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
cd apps/mobile && flutter analyze
```

**When to use:** After modifying Freezed classes, Drift tables, Riverpod annotations, or go_router routes. Also before committing to catch lint errors.

---

### `/sync-test`

**Purpose:** Test offline sync round-trip.

**Config file:** `.claude/skills/sync-test/SKILL.md`

**Commands:**
```bash
cd apps/server && bun test test/services/sync.service.test.ts
cd apps/mobile && flutter test test/src/shared/data/sync/
```

**When to use:** After changes to sync engine, sync queue, or server sync endpoints.

---

### `/screenshot-verify`

**Purpose:** Take a screenshot of the current screen and compare against the blueprint wireframe.

**Config file:** `.claude/skills/screenshot-verify/SKILL.md`

**Workflow:**
1. Take screenshot of the running app
2. Read `docs/planning/blueprint.html` and find the corresponding wireframe
3. Compare layout, spacing, data display, and interactive elements
4. Flag any discrepancies

**When to use:** After implementing or modifying any UI screen or widget.

---

### `/session-handoff`

**Purpose:** Update `docs/CONTINUE_PROMPT.md` with current session progress.

**Config file:** `.claude/skills/session-handoff/SKILL.md`

**Workflow:**
1. Read current `docs/CONTINUE_PROMPT.md`
2. Update "Completed Work" section with what was done this session
3. Update "What to Do Next" section with remaining tasks
4. Update "Files in Repository" if new directories were created
5. Note any blockers or pending decisions

**When to use:** At the end of every coding session, before ending the conversation.

---

### `/db-migrate`

**Purpose:** Generate and apply Drizzle migrations.

**Config file:** `.claude/skills/db-migrate/SKILL.md`

**Commands:**
```bash
cd apps/server && bunx drizzle-kit generate
cd apps/server && bunx drizzle-kit migrate
```

**When to use:** After modifying any Drizzle schema file in `apps/server/src/db/schema/`.

---

### `/analyze`

**Purpose:** Run Flutter static analysis only (no build_runner). Faster than `/build-check` when you only need lint checking.

**Config file:** `.claude/skills/analyze/SKILL.md`

**Command:**
```bash
cd apps/mobile && flutter analyze
```

**When to use:** Quick lint check during development. Use `/build-check` instead when generated files need updating.

---

### `/server-test`

**Purpose:** Run Bun server test suite (all tests or a specific file).

**Config file:** `.claude/skills/server-test/SKILL.md`

**Command:**
```bash
cd apps/server && bun test [$ARGUMENTS]
```

**When to use:** After changes to server routes, services, middleware, or WebSocket handlers.

---

### `/commit-draft`

**Purpose:** Analyze staged changes and draft a conventional commit message. Does NOT commit — only drafts for user review.

**Config file:** `.claude/skills/commit-draft/SKILL.md`

**Output format:** `<type>(<scope>): <description>` + Co-Authored-By line.

**When to use:** Before committing, to get a properly formatted conventional commit message.

---

### `/debug-log`

**Purpose:** Create or update a debug iteration log per [CODE_FIXES.md](CODE_FIXES.md) workflow.

**Config file:** `.claude/skills/debug-log/SKILL.md`

**Usage:** `/debug-log <issue-name>` — Creates `docs/debug/<issue-name>.md` with iteration tracking table.

**Escalation tiers:** Iteration 4 (Tier 1), 6 (Tier 2), 8 (Tier 3), 10 (HARD CAP).

**When to use:** When debugging a non-trivial issue that may require multiple fix attempts.

---

### `/schema-parity`

**Purpose:** Compare Drift (Flutter) tables against Drizzle (server) schema. Read-only parity check.

**Config file:** `.claude/skills/schema-parity/SKILL.md`

**Output:** Structured diff report — matched tables, column mismatches, missing tables, type mapping validation.

**When to use:** After modifying Drizzle or Drift schema files, or during schema review.

---

### `/drift-migrate`

**Purpose:** Manage Drift schema version bumps and scaffold migration code.

**Config file:** `.claude/skills/drift-migrate/SKILL.md`

**Modes:**
- **Default (safe):** Read-only scaffold — shows migration code without writing
- **Apply:** `/drift-migrate apply` — Writes migration code and runs build_runner

**When to use:** After adding/modifying Drift table columns or adding new tables.
