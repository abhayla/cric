# Claude Code Configuration

This document defines sub-agent specifications and skill definitions for Claude Code when working on CricApp. These are spec-only — no actual config files are generated. Use these as reference when configuring Claude Code agents and skills.

---

## Sub-Agents

### 1. Scoring Engine Specialist

**Purpose:** Implement and maintain the scoring engine — the most critical and complex component.

**Context files to read before every task:**
- [SCORING_RULES.md](../planning/SCORING_RULES.md) — Full delivery pipeline, state machine, all cricket rules
- [DATABASE.md](../planning/DATABASE.md) — `deliveries`, `batting_stats`, `bowling_stats`, `fielding_stats`, `innings` tables

**Rules:**
- Must write a failing test BEFORE implementing any scoring logic
- Verify strike rotation against [SCORING_RULES.md](../planning/SCORING_RULES.md) for every delivery type
- Follow all 10 steps of the delivery processing pipeline — no shortcuts
- Run the full scoring test suite after every change
- Verify undo correctness for every new delivery type implemented
- Never hardcode cricket constants — reference seed data

**Key files this agent owns:**
- `apps/mobile/lib/src/features/scoring/` — all files
- `apps/mobile/lib/src/core/utils/cricket_utils.dart`
- `apps/server/src/services/scoring.service.ts`
- `apps/server/src/utils/cricket-rules.ts`

---

### 2. Database & Sync Agent

**Purpose:** Implement database schemas, migrations, sync engine, and data access layers.

**Context files to read before every task:**
- [DATABASE.md](../planning/DATABASE.md) — All 24 tables, 5 materialized views, indexes, SQLite local schema
- [API.md](../planning/API.md) — Sync endpoints (Section 1.8)

**Rules:**
- Tables must match [DATABASE.md](../planning/DATABASE.md) exactly — column names, types, constraints, indexes
- Implement `sync_queue` table for offline-first queue management
- Handle UUID mapping between local and server IDs
- Every Drizzle migration must be tested with seed data
- Drift tables mirror Drizzle schema shape but are maintained separately (cross-platform parity)
- Use the index names from DATABASE.md (`idx_<table>_<columns>`)

**Key files this agent owns:**
- `apps/server/src/db/` — schema, migrations, seed
- `apps/mobile/lib/src/shared/data/database/` — Drift tables, DAOs
- `apps/mobile/lib/src/shared/data/sync/` — sync engine
- `apps/server/src/services/sync.service.ts`

---

### 3. UI Builder Agent

**Purpose:** Implement Flutter screens, widgets, and visual components.

**Context files to read before every task:**
- [blueprint.html](../planning/blueprint.html) — Wireframes for all 18 screens and 5 scoring dialogs
- [.claude/rules.md](../../.claude/rules.md) — Widget placement rules (Section 3)

**Rules:**
- Follow Material 3 dark theme — use theme tokens, not hardcoded colors
- Screenshot-verify every screen against the blueprint wireframe before marking complete
- Minimum touch target: 48x48 dp for all interactive elements
- Use `ListView.builder` for all lists (performance on low-end devices)
- Use Riverpod `select()` for granular widget rebuilds
- Feature-specific widgets go in `features/<feature>/presentation/widgets/`
- Cross-feature widgets go in `shared/widgets/` (only after 2+ usages)
- Pages go in `features/<feature>/presentation/pages/`

**Key files this agent owns:**
- `apps/mobile/lib/src/features/*/presentation/` — pages and widgets
- `apps/mobile/lib/src/shared/widgets/` — shared widgets
- `apps/mobile/lib/src/core/theme/` — theme and colors

---

### 4. API & WebSocket Agent

**Purpose:** Implement REST API routes, services, middleware, and WebSocket real-time system.

**Context files to read before every task:**
- [API.md](../planning/API.md) — All REST endpoints with request/response examples, WebSocket protocol
- [DATABASE.md](../planning/DATABASE.md) — Table schemas for query building

**Rules:**
- Routes must match [API.md](../planning/API.md) exactly — paths, methods, request/response shapes, status codes
- Firebase JWT middleware on all authenticated routes
- Keep route handlers thin: validate input → call service → return result
- WebSocket message types must match [API.md](../planning/API.md) Section 2
- One service file per domain (scoring, match, player, team, analytics, sync)
- Error responses use consistent shape: `{ error: { code, message } }`
- All endpoints must validate input before calling services

**Key files this agent owns:**
- `apps/server/src/routes/v1/` — all route files
- `apps/server/src/services/` — all service files
- `apps/server/src/websocket/` — handler, rooms, types
- `apps/server/src/middleware/` — auth, error handler, CORS
- `apps/server/src/types/` — all type definitions

---

## Skills

### `/score-test`

**Purpose:** Run the scoring engine test suite.

**Command:**
```bash
cd apps/mobile && flutter test test/src/features/scoring/
```

**When to use:** After any change to scoring logic, delivery processing, strike rotation, or undo functionality.

---

### `/build-check`

**Purpose:** Run code generation and static analysis.

**Commands:**
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
cd apps/mobile && flutter analyze
```

**When to use:** After modifying Freezed classes, Drift tables, Riverpod annotations, or go_router routes. Also before committing to catch lint errors.

---

### `/sync-test`

**Purpose:** Test offline sync round-trip.

**Commands:**
```bash
# Start server in test mode
cd apps/server && bun test test/services/sync.service.test.ts

# Run Flutter sync tests
cd apps/mobile && flutter test test/src/shared/data/sync/
```

**When to use:** After changes to sync engine, sync queue, or server sync endpoints.

---

### `/screenshot-verify`

**Purpose:** Take a screenshot of the current screen and compare against the blueprint wireframe.

**Workflow:**
1. Take screenshot of the running app
2. Open `docs/planning/blueprint.html` and navigate to the corresponding wireframe
3. Compare layout, spacing, data display, and interactive elements
4. Flag any discrepancies

**When to use:** After implementing or modifying any UI screen or widget.

---

### `/session-handoff`

**Purpose:** Update `docs/CONTINUE_PROMPT.md` with current session progress.

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

**Commands:**
```bash
cd apps/server && bunx drizzle-kit generate
cd apps/server && bunx drizzle-kit migrate
```

**When to use:** After modifying any Drizzle schema file in `apps/server/src/db/schema/`.
