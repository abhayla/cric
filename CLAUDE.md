# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CricApp is a cricket scoring mobile app (CricHeroes competitor) for amateur cricketers in India. Monorepo with a Flutter frontend and Bun backend. **Status: planning complete, implementation not yet started.**

## Tech Stack

- **Frontend:** Flutter (Dart) + Riverpod 3.0, Drift/SQLite (local DB), Material 3 Dark Theme
- **Backend:** Bun + ElysiaJS + Drizzle ORM, PostgreSQL
- **Auth:** Firebase Auth (Phone OTP, Google, Email)
- **Real-time:** Bun Native WebSockets
- **Target:** Android only (MVP)

## Monorepo Layout

- `apps/mobile/` — Flutter app (feature-first clean architecture with data/domain/presentation layers per feature)
- `apps/server/` — Bun backend (routes → services → Drizzle ORM → PostgreSQL)
- `docs/` — All design documents

## Key Documentation

Read these before implementing:
- `docs/CONTINUE_PROMPT.md` — Start here for session context and next steps
- `docs/IMPLEMENTATION_PLAN.md` — Phased roadmap (7 phases), folder structure, packages
- `docs/DATABASE.md` — 24 tables, 5 materialized views, indexes, local SQLite schema
- `docs/API.md` — REST endpoints with request/response examples, WebSocket protocol
- `docs/SCORING_RULES.md` — Match state machine, delivery processing pipeline, cricket rules, MVP algorithm

## Build & Run Commands (once initialized)

```bash
# Flutter app
cd apps/mobile && flutter run              # Run on connected device
cd apps/mobile && flutter build apk        # Build release APK
cd apps/mobile && flutter test             # Run tests
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs  # Code generation (Drift, Freezed, Riverpod)

# Bun server
cd apps/server && bun install              # Install dependencies
cd apps/server && bun run src/index.ts     # Start server
cd apps/server && bun test                 # Run tests
cd apps/server && bunx drizzle-kit generate  # Generate migrations
cd apps/server && bunx drizzle-kit migrate   # Apply migrations
```

## Architecture Decisions

- **Offline-first:** All scoring writes go to local Drift/SQLite first, then sync to server. Deliveries have a `synced` flag.
- **Atomic delivery model:** Every ball bowled is stored as a `deliveries` record — the core unit for all stats and analytics.
- **Pre-computed stats:** `batting_stats`, `bowling_stats`, `fielding_stats` per innings + `player_career_stats` aggregates for fast reads.
- **WebSocket rooms:** Each match = one pub/sub room. Scorer = publisher, viewers = subscribers. Uses Bun's native `server.publish(topic, message)`.
- **UUIDs everywhere:** All primary keys are UUIDs for cross-device sync compatibility.

## Cricket Domain Rules

The scoring engine is the most critical piece. Key rules in `docs/SCORING_RULES.md`:
- Odd runs swap striker/non-striker; end of over swaps too
- Wides/no-balls are NOT legal deliveries (don't count toward 6-ball over)
- No-ball triggers free hit on next delivery (only run out possible)
- Byes/leg-byes don't count against bowler and don't break maidens
- 10 wickets = all out = innings over

## Workflow Preferences

- **[IMPORTANT] Do not just simulate the implementation or mocking them, always implement the real code.**
- Only implement features when actually needed (no speculative over-engineering)
- Fix root causes, not symptoms — loop on test failures until the underlying issue is resolved
- Take screenshots after tests and visually verify UI matches expected output
- Save session context to `docs/CONTINUE_PROMPT.md` before ending work
- Ask clarifying questions before implementing if requirements are ambiguous — do not guess
- After completing work, update `docs/CONTINUE_PROMPT.md` with current state so the next session can resume seamlessly
