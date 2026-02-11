# Claude Code Configuration

This document defines sub-agent specifications and skill definitions for Claude Code when working on CricApp. Agents and skills are implemented as actual config files in `.claude/agents/` and `.claude/skills/`.

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

## Sub-Agents

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
- Material 3 dark theme token compliance (no hardcoded colors)
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

**Purpose:** Compare CricApp features against CricHeroes (market leader, 40M+ users). Produces structured comparison reports with adopt/skip/defer gap recommendations.

**Config file:** `.claude/agents/cricheroes-comparator.md`

**Context files read before every task:**
- [CRICHEROES_REFERENCE.md](../planning/CRICHEROES_REFERENCE.md) — Pre-built CricHeroes knowledge base (relevant section for the feature)
- Relevant CricApp planning doc (DATABASE.md, API.md, SCORING_RULES.md, blueprint.html)

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
- `docs/planning/DATABASE.md`, `API.md`, `SCORING_RULES.md`, `blueprint.html` — CricApp specs
- `apps/mobile/lib/src/features/` — existing implementation (if any)
- Live web: `blog.cricheroes.com`, `cricheroes.com`, Play Store listing

---

## Skills

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
