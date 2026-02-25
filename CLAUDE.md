# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CricScores is a cricket scoring mobile app (CricHeroes competitor) for amateur cricketers in India. Monorepo with a Flutter frontend and Bun backend. **Status: Phases 1–6 complete, Phase 7 (Polish & Testing) in progress.**

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) + Riverpod 3.0 |
| Local DB | Drift / SQLite |
| Backend | Bun + ElysiaJS + Drizzle ORM |
| Server DB | PostgreSQL |
| Auth | Firebase Auth (Phone OTP only for MVP) |
| Real-time | Bun Native WebSockets |
| UI Theme | Material 3 Light |
| Target | Android only (MVP) |

## Monorepo Layout

**[MANDATORY] Read [.claude/rules.md](.claude/rules.md) before creating any file or folder. All new code must follow this structure exactly.**

```text
cric/
├── apps/
│   ├── mobile/        # Flutter app
│   └── server/        # Bun backend
├── docs/
│   ├── planning/      # Product & architecture specs
│   ├── process/       # Workflow & standards
│   └── pre-prod/      # VPS deployment & production readiness
├── scripts/           # E2E orchestration, structure validators
├── .claude/           # Claude Code config + rules
└── CLAUDE.md
```

Every new file **must** be placed according to the placement rules in [.claude/rules.md](.claude/rules.md). No exceptions.

## Current Status

**Phases 1–6 COMPLETE.** Phase 7 (Polish & Testing) in progress. Heaviest test areas: `test/src/features/scoring/` (Flutter), `test/services/` (server). Full phase breakdown in [IMPLEMENTATION_PLAN.md](docs/planning/IMPLEMENTATION_PLAN.md). Session context and next steps in [CONTINUE_PROMPT.md](docs/CONTINUE_PROMPT.md).

## Key Documentation

| Document | Purpose |
|----------|---------|
| [CONTINUE_PROMPT.md](docs/CONTINUE_PROMPT.md) | Session handoff — start here each session |
| [PLAYBOOK.md](docs/process/PLAYBOOK.md) | Step-by-step implementation workflow |
| [SCORING_RULES.md](docs/planning/SCORING_RULES.md) | Cricket domain rules, delivery pipeline, match state machine |
| [DATABASE.md](docs/planning/DATABASE.md) | PostgreSQL schema (26 tables), enums, relationships |
| [API.md](docs/planning/API.md) | REST endpoint specs, request/response shapes |
| [SYNC_ARCHITECTURE.md](docs/planning/SYNC_ARCHITECTURE.md) | Dual-path broadcast, gap detection, offline sync queue |
| [CRICHEROES_REFERENCE.md](docs/planning/CRICHEROES_REFERENCE.md) | Competitive analysis for CricHeroes comparison |
| [PROJECT_MANAGEMENT.md](docs/process/PROJECT_MANAGEMENT.md) | Full documentation map and update frequencies |

## Build & Run Commands (once initialized)

```bash
# Flutter app
cd apps/mobile && flutter run --flavor dev              # Run on connected device
cd apps/mobile && flutter build apk --flavor dev        # Build dev APK
cd apps/mobile && flutter build apk --flavor prod --release --dart-define=FLAVOR=prod  # Build prod APK
cd apps/mobile && flutter test             # Run all tests
cd apps/mobile && flutter test test/path/to_test.dart          # Run single test file
cd apps/mobile && flutter test --name "test name"              # Run test by name
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs  # Code generation (Drift, Freezed, Riverpod)

# Bun server
cd apps/server && bun install              # Install dependencies
cd apps/server && bun run dev              # Start server (watch mode)
cd apps/server && bun run start            # Start server (production)
cd apps/server && bun run src/index.ts     # Start server (direct)
cd apps/server && bun run test             # Run all tests (--timeout=60000 --max-concurrency=1 via package.json)
cd apps/server && bun test src/path/to.test.ts                 # Run single test file
cd apps/server && bun run typecheck        # TypeScript type check (alias for bunx tsc --noEmit)
cd apps/server && bun run db:generate      # Generate migrations
cd apps/server && bun run db:migrate       # Apply migrations
cd apps/server && bun run db:seed          # Seed master data (dismissal types, positions, zones)
```

```bash
# Integration / E2E tests (require running server + emulator/device)
cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts   # Start test server
cd apps/mobile && flutter test --flavor dev integration_test/tests/02_standalone_match_test.dart -d emulator-5554  # Single match E2E
cd apps/mobile && flutter test --flavor dev integration_test/tests/08_viewer_live_test.dart -d <device>  # Multi-device WebSocket test
```

**E2E test rule:** E2E/integration tests CAN be run directly from Claude's CLI on real connected devices. Use `flutter test integration_test/<test>.dart -d <device-id>` with the appropriate device ID from `flutter devices`.

**E2E multi-device coordination:** Scorer and viewer tests synchronize via HTTP signal endpoints (`POST/GET /api/v1/test/signal/:name`). Flow: scorer creates match + toss, posts `scorer-ready` signal, polls for `viewer-ready` (120s). Viewer polls for `scorer-ready`, connects WebSocket, posts `viewer-ready`. Scorer then begins scoring. Orchestration script: `scripts/multi-device-e2e.sh` (supports `SWAP_DEVICES=1` to swap emulator/device roles).

**Environment setup:** Copy `apps/server/.env.example` to `apps/server/.env` and fill in PostgreSQL + Firebase credentials before starting the server.

**Code generation:** Files matching `*.g.dart`, `*.freezed.dart`, `*.gr.dart` are auto-generated. Never edit them manually — re-run `build_runner` instead.

**Server tests:** Use `bun run test` (not `bun test`) to run all tests — the npm script passes `--max-concurrency=1` and `ENABLE_TEST_AUTH=true` to avoid DB contention and enable test auth bypass. Individual files work with `NODE_ENV=test ENABLE_TEST_AUTH=true bun test path/to.test.ts`.

**Android build flavors:** Two flavors — `dev` (default, Firebase app `com.cricapp.cricapp`) and `prod` (Firebase app `in.cricscores.app`). Dev builds: `flutter run --flavor dev`. Prod builds: `flutter build apk --flavor prod --release --dart-define=FLAVOR=prod`. Each flavor has its own `google-services.json` in `android/app/src/<flavor>/`.

## First-Time Setup

```bash
# 1. Install dependencies
cd apps/mobile && flutter pub get && cd ../..
cd apps/server && bun install && cd ../..

# 2. Server environment
cp apps/server/.env.example apps/server/.env
# Edit .env with PostgreSQL connection string + Firebase credentials

# 3. Firebase config files (flavor-specific directories)
# Place google-services.json in apps/mobile/android/app/src/dev/  (dev flavor: com.cricapp.cricapp)
# Place google-services.json in apps/mobile/android/app/src/prod/ (prod flavor: in.cricscores.app)
# Place firebase-service-account.json in apps/server/

# 4. Database
cd apps/server && bun run db:generate && bun run db:migrate && bun run db:seed && cd ../..

# 5. Flutter code generation (Drift, Freezed, Riverpod)
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && cd ../..
```

## CI Pipeline

GitHub Actions (`.github/workflows/ci.yml`) runs on a self-hosted Windows runner with 5 jobs:

1. **structure-validate** — Runs `node scripts/validate-structure/flutter-validator.js` and `server-validator.js` to enforce folder placement rules from `.claude/rules.md`
2. **flutter-analyze** — `flutter pub get` → `build_runner build` → `flutter analyze`
3. **flutter-test** — (depends on analyze) `flutter test`
4. **server-lint** — `bunx tsc --noEmit`
5. **server-test** — (depends on lint) `bun test` with a test PostgreSQL database

Flutter and server jobs only run when their respective `apps/` directory has files (conditional on `hashFiles`). Structure validation always runs.

## Architecture Decisions

- **Offline-first:** All scoring writes go to local Drift/SQLite first, then sync to server. Deliveries have a `synced` flag.
- **Atomic delivery model:** Every ball bowled is stored as a `deliveries` record — the core unit for all stats and analytics.
- **Pre-computed stats:** `batting_stats`, `bowling_stats`, `fielding_stats` per innings + `player_career_stats` aggregates for fast reads.
- **Dual-path real-time broadcast:** Live scoring uses two parallel paths: (1) **Fast path (~ms):** `ScoringPersistenceService` sends `publish_score` WS message immediately after each delivery — server relays to room subscribers with zero DB access (sender excluded via Bun's `ws.publish`). (2) **Durable path (~2s):** `SyncService` timer fires every 2s (threshold: 1 pending delivery) — REST sync to server — server persists to PostgreSQL — broadcasts `match_state` reconciliation snapshot. Viewers detect missed messages via `deliveryCount` gap detection and auto-recover by re-sending `join_match`.
- **Scoring engine layering:** `ScoringNotifier` (pure state machine, ~1400 lines) is wrapped by `ScoringPersistenceService` (fire-and-forget JSON snapshots to Drift after each mutation) which coordinates with `SyncService` (FIFO queue processor for server sync). This layering keeps the core notifier testable with no I/O dependencies — all 333+ scoring tests run against the notifier directly.
- **WebSocket rooms:** Each match = one pub/sub room. Scorer = publisher, viewers = subscribers. Uses Bun's native `server.publish(topic, message)`. 7 server message types: `match_state`, `score_update`, `wicket`, `innings_complete`, `match_complete`, `delivery_undone`, `error`.
- **UUIDs everywhere:** All primary keys are UUIDs for cross-device sync compatibility.

## Scoring Engine Architecture

The scoring engine is the most complex subsystem. Key files and their roles:

**Server (`apps/server/src/`):**
- `services/scoring.service.ts` — 10-step delivery pipeline inside `db.transaction()`. Pre-validation outside the transaction for fail-fast. Handles: `recordDelivery`, `undoDelivery`, `getDeliveries`, `abandonMatch`, `declareInnings`, `reopenInnings`, `reopenMatch`. `completeMatch()` queries both innings to determine result (runs/wickets/tied/no_result). `checkInningsCompletion()` checks: all-out, overs exhausted, target chased. `checkOverCompletion()` checks: 6 legal balls → maiden detection → insert overs record.
- `routes/v1/scoring.ts` — Thin route handlers under `/api/v1/matches` prefix with `authMiddleware`. After each mutation, broadcasts appropriate WebSocket message.
- `services/career-stats.service.ts` — SQL aggregation of per-innings stats into `player_career_stats`. Wired into `completeMatch()` to auto-refresh.
- `websocket/rooms.ts` — `getMatchState(matchId)` builds full snapshot from DB. 6 `build*Message()` pure functions for broadcast types.

**Flutter (`apps/mobile/lib/src/features/scoring/`):**
- `domain/entities/delivery.dart` — `DismissalType` enum (11 values), `Delivery` entity (26 fields), `InningsCompletionReason` enum.
- `presentation/notifiers/scoring_notifier.dart` — Pure state machine (~1400 lines). `ScoringState` with ~30 fields + 15 computed getters. 10-step `_processDelivery` pipeline mirroring server. All cricket rules (strike rotation, free hit, extras, over completion, innings completion) encoded here.
- `presentation/notifiers/scoring_persistence_service.dart` — Wraps `ScoringNotifier`. Fire-and-forget JSON snapshots to Drift after each mutation. Static factories: `createNew()`, `resume()`.
- `core/utils/scoring_utils.dart` — Pure functions: `isLegalDelivery`, `calculateTotalRuns`, `shouldSwapStrike`, `isOverComplete`, `checkInningsCompletion`, `isMaidenOver`, `isNextFreeHit`.

**Key scoring rules:**
- Free hit: triggered by no-ball, persists through wides, consumed by legal delivery.
- Configurable: `wide_runs`/`no_ball_runs` from matches table (not hardcoded).
- Undo blocked after scorer confirms new batter/bowler selection (`undoBlockedByTransition`).

## Known Gotchas

### Freezed 3.x Patterns (Dart)
- Use `abstract class` with `_$Mixin` (NOT `class` + `const Constructor._()`).
- Custom methods (e.g. `toEntity()`) must be in **extensions**, not in the class body — generated `_Impl` uses `implements` not `extends`, so instance methods aren't inherited.
- Static helper methods should be top-level functions (not `static` in the abstract class).

### Bun Test Runner Bugs
- **`.rejects.toThrow()` hangs** with async functions that do DB operations (Drizzle/postgres.js). Use the `expectToReject()` helper with try-catch instead. Confirmed in bun v1.3.9. Plain `Error` throws work; the hang is specific to promises involving DB connections.
- Pre-transaction validation pattern: move fail-fast checks (match status, scorer auth, input validation) **before** `db.transaction()` for better performance and to avoid the bun test hang issue.

### Test Patterns
- In Flutter tests, use `Completer<T>().future` for never-completing futures (not `Future.delayed(Duration(days: 1))` which leaves pending timers).
- Server tests: always use `bun run test` (not `bun test` directly) to get `--max-concurrency=1` and avoid DB contention.

### Bun on Windows
- **Local dev:** Bun should be in PATH already. If not, install via `powershell -c "irm bun.sh/install.ps1 | iex"`.
- **VPS (`103.118.16.189`):** Bun is at `C:\Users\Administrator\.bun\bin\bun.exe`. In bash: `export PATH="$PATH:/c/Users/Administrator/.bun/bin"`.

## VPS Deployment

Production/friend-testing VPS: **544934-ABHAYVPS** at `103.118.16.189` (Windows Server 2022). Full deployment guide: [docs/pre-prod/VPS_ACTIONS.md](docs/pre-prod/VPS_ACTIONS.md).

| Detail | Value |
|--------|-------|
| VPS IP | `103.118.16.189` |
| Domain | `cricscores.in` (via Cloudflare) |
| CricScores port | `3005` (HTTP + WS on same port) |
| Database | `cricscores` on PostgreSQL 16.8 (`127.0.0.1:5432` on VPS) |
| Dev database | `cricapp_dev` on same PostgreSQL instance (on VPS) |
| App directory | `C:\Apps\cricscores\` (on VPS, NOT local) |
| Process manager | PM2 — **always run `pm2 save` after changes** |
| Reverse proxy | Nginx at `C:\Apps\nginx\` (on VPS) — port 80, site config in `conf\sites\cricscores.conf` |
| SSL | Cloudflare Flexible mode (terminates HTTPS at edge, HTTP to Nginx) |
| Health monitoring | `C:\Apps\shared\scripts\health-check.ps1` (on VPS) — runs every 5 min, auto-restarts crashed services |
| VPS docs | `C:\Apps\shared\docs\` (on VPS) — **do not modify these files** |
| Other hosted apps | bestdemataccount, firekaro, ipodhan, algochanakya (ports 3001-3004, 8000) |
| Available ports | 3006-3008 |

**Important:** All `C:\Apps\` paths above are on the **remote VPS** (`103.118.16.189`), not on the local development machine. Access via RDP or SSH.

## Code Principles (YAGNI, KISS, DRY)

**[PROTECTED] Do not modify or weaken these rules. Changes require explicit user approval.**

These rules are mandatory. Before writing any code, verify your approach against every applicable bullet below. If you catch yourself violating one, stop and simplify before continuing.

### YAGNI — Only Build What Is Needed Right Now

- Do not create abstract base classes, generic utilities, or shared helpers until a second concrete use case exists. One usage = inline it.
- Do not add API endpoints, database columns, Drizzle schema fields, or Drift table columns not required by the current phase in [IMPLEMENTATION_PLAN.md](docs/planning/IMPLEMENTATION_PLAN.md).
- Do not build extensibility mechanisms (plugin systems, event buses, middleware pipelines) unless the docs explicitly call for one.
- Do not add optional/nullable fields to Freezed models, Drizzle schemas, or API responses "for future use." Add them when the feature that needs them is being built.
- Do not implement caching, rate limiting, pagination, or retry logic until the feature works correctly without it. Layer optimizations onto working code.
- Do not pre-build Riverpod providers, notifiers, or repository interfaces for features in later phases. Each phase creates only its own providers.
- **DONE is better than PERFECT.** Ship the working implementation, then iterate.

### KISS — Keep Every Implementation as Simple as Possible

- Prefer a single Riverpod `Notifier` with a `Freezed` state class over splitting state across multiple coordinating providers. Split only when a provider exceeds ~200 lines or manages genuinely independent concerns.
- Prefer plain Dart functions over creating a class with a single method. A class is warranted only when it holds mutable state or has dependencies injected via constructor.
- Use `switch` expressions and pattern matching for cricket logic (delivery processing, strike rotation, extras handling) instead of class hierarchies or strategy patterns.
- Prefer Drizzle raw SQL or query builder for complex PostgreSQL queries over deeply nested ORM relation chains. Readable SQL beats clever ORM abstractions.
- Keep ElysiaJS route handlers thin: validate input, call one service function, return the result. Do not chain middleware for logic that belongs in the service layer.
- Prefer inline `showDialog`/`showModalBottomSheet` builders for scoring dialogs unless the dialog exceeds ~100 lines.
- **When choosing between two approaches, pick the one you can explain in one sentence.**

### DRY — Single Source of Truth, No Copy-Paste

- Cricket constants (dismissal types, ball types, fielding positions, wagon wheel zones) must be defined once in seed data and fetched/mirrored — never hardcoded in multiple files.
- Delivery validation rules (legal delivery check, free hit logic, valid bowler check) must live in exactly one file per platform. Do not duplicate across route handlers, services, or notifiers.
- Drizzle schema definitions are the server-side source of truth. Drift tables in Flutter mirror the shape but are maintained separately — this is cross-platform parity, not duplication.
- Reuse Freezed model `copyWith` for state transitions in Riverpod notifiers. Do not manually construct new state objects field-by-field.
- Extract shared Flutter widgets only after you have copy-pasted a UI pattern at least twice. Premature extraction creates wrong abstractions.
- WebSocket message types must be defined in one server-side types file and mirrored in one Dart file. Do not define message structures inline at send/receive sites.
- If you write the same Drizzle `where` clause or Drift query in multiple service functions, extract it into a DAO method — but only after the second occurrence.

## Cricket Domain Rules

Key rules in [SCORING_RULES.md](docs/planning/SCORING_RULES.md). Full reference: `.claude/skills/cricket-domain/SKILL.md`. Match state: `SETUP→TOSS→LIVE→INNINGS_BREAK→LIVE→COMPLETED` (`ABANDONED` at any point). Delivery pipeline: 10 steps (validate→calculate→extras→wicket→strike→stats→over→innings→broadcast→persist).

## No Shortcuts — Fix Root Causes Only

**[PROTECTED] Do not modify or weaken this rule. Changes require explicit user approval.**

Every bug, test failure, or code issue must be fixed by addressing its root cause. Shortcuts, workarounds, band-aids, and hacks are strictly prohibited:

- **No quick fixes:** Never patch symptoms with temporary code — investigate and fix the actual cause.
- **No "fix later" TODOs:** Never defer root cause analysis with comments like `// TODO: fix later`.
- **No validation bypasses:** Never disable error checking or validation to make code pass.
- **No mock implementations:** Never simulate functionality instead of building it correctly.
- **No error suppression:** Never swallow exceptions or suppress warnings without fixing the underlying cause.
- **No endless debugging loops:** If you can't find the root cause after reasonable investigation, fix the code to be robust (proper timeouts, error states, retries) AND continue investigating the root cause — don't just add debug prints and give up.

**Enforcement:** Follow the 8-step root cause analysis workflow in [CODE_FIXES.md](docs/process/CODE_FIXES.md). On test failures, follow escalation tiers through Hard Cap (iteration 10), then present findings to the user rather than introducing workarounds.

## Workflow Preferences

- **[IMPORTANT] Do not simulate or mock implementations — always write real, working code.**
- Fix root causes, not symptoms — loop on test failures until the underlying issue is resolved.
- If requirements are ambiguous, ask one clarifying question at a time (with your recommendation) until 100% confident — do not guess.
- **Session handoff:** Always update [CONTINUE_PROMPT.md](docs/CONTINUE_PROMPT.md) before ending work. Read it at the start of each session.
- **CricHeroes comparison:** Before implementing any new feature/screen, invoke the `cricheroes-comparator` agent. Incorporate ADOPT recommendations, log DEFER items in CONTINUE_PROMPT.md.
- **Playwright screenshots:** Save to `.playwright-mcp/screenshots/` (never project root).

**Implementation order:** domain entities → data layer → presentation. Never start with UI.

**TDD workflow:** Red-Green-Refactor per layer. Tests BEFORE implementation. See [PLAYBOOK.md](docs/process/PLAYBOOK.md).

**Detailed workflows:** [IMPLEMENTATION_PRACTICES.md](docs/process/IMPLEMENTATION_PRACTICES.md) for features, [CODE_FIXES.md](docs/process/CODE_FIXES.md) for debugging.

## Feature Architecture

Each feature in `apps/mobile/lib/src/features/<feature>/` follows clean architecture: `data/` (datasources, models, repositories) + `domain/` (entities, repository interfaces) + `presentation/` (notifiers, pages, widgets) + `providers.dart`. Full placement rules, decision tree, and critical anti-patterns in [.claude/rules.md](.claude/rules.md). Server-side: all DB access through services (never in route handlers), WS message types in centralized type files (never inline).

## Naming Conventions

- **Dart:** `snake_case.dart` files, `PascalCase` classes, `camelCase` vars/functions
- **TypeScript:** `kebab-case.ts` utils, `dot-notation.ts` services (e.g., `scoring.service.ts`), `PascalCase` types
- **Database:** `snake_case` plural tables, `snake_case` columns, `idx_<table>_<columns>` indexes
- **Git:** Conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Branch: `feature/`/`fix/`/`task/` + issue number

Full conventions (variable patterns, error handling, import ordering): [CODE_STANDARDS.md](docs/process/CODE_STANDARDS.md).
