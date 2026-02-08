# CricApp - Continue Prompt

## Context for Resuming Work

**Project:** CricApp - Cricket scoring mobile app (CricHeroes competitor)
**Status:** Planning complete, implementation not yet started
**Working Directory:** `D:\Abhay\VibeCoding\cric\`

## Tech Stack

- **Frontend:** Flutter (Dart) + Riverpod 3.0
- **Backend:** Bun + ElysiaJS + Drizzle ORM
- **Database:** PostgreSQL (server) + Drift/SQLite (local)
- **Auth:** Firebase Auth (Phone OTP, Google, Email)
- **Real-time:** Bun Native WebSockets
- **Target:** Android only (MVP)
- **UI:** Material 3 Dark Theme

## Documentation Created

All planning documents are in `docs/`:

| Document | Contents |
|----------|----------|
| `docs/IMPLEMENTATION_PLAN.md` | Architecture, folder structure, packages, phased roadmap (7 phases, 14 weeks), verification plan, testing strategy |
| `docs/DATABASE.md` | Full schema for 24 tables + 5 materialized views, indexes, SQLite local schema, sync strategy |
| `docs/API.md` | All REST endpoints (auth, teams, matches, scoring, players, analytics, sync, health) + full WebSocket protocol |
| `docs/SCORING_RULES.md` | Match state machine, delivery processing pipeline (10 steps), all cricket rules (strike rotation, wides, no-balls, byes, leg-byes, maidens, innings completion, dismissal types), undo logic, MVP algorithm, UI interactions |
| `README.md` | Project overview with links to all docs |

## What to Do Next

Start with **Phase 1: Foundation** as described in `docs/IMPLEMENTATION_PLAN.md`:

1. Initialize Flutter project (`apps/mobile/`) with the folder structure from Section 2.1
2. Initialize Bun server (`apps/server/`) with the folder structure from Section 2.2
3. Set up PostgreSQL + Drizzle schema using tables from `docs/DATABASE.md`
4. Seed master data (dismissal types, fielding positions, wagon wheel zones, ball types)
5. Set up Firebase project + configure Flutter Firebase
6. Implement Firebase Auth (phone OTP + Google sign-in)
7. Implement auth middleware on Bun (Firebase JWT verification)
8. Set up Material 3 dark theme
9. Set up go_router with auth guards
10. Build screens: Splash, Login, OTP, Profile Setup

## Key Design Decisions Already Made

- Ball-by-ball granularity (every delivery stored)
- UUIDs for all primary keys (sync-friendly)
- 12-zone wagon wheel system (30-degree segments)
- Pre-computed stats per innings + career aggregates
- JSONB for graph data in match_analytics
- Offline-first with sync queue in local SQLite
- Scorer = publisher, viewers = subscribers in WebSocket rooms
- Free hit tracking on no-balls
- Byes/leg-byes don't break maidens

## Files in Repository

```
cric/
├── .git/
├── docs/
│   ├── CONTINUE_PROMPT.md    (this file)
│   ├── IMPLEMENTATION_PLAN.md
│   ├── DATABASE.md
│   ├── API.md
│   └── SCORING_RULES.md
├── Notes                      (user's working notes & best practices)
└── README.md
```

## Instructions for Next Session

Read this file first, then read `docs/IMPLEMENTATION_PLAN.md` Phase 1 section. Begin implementation from step 1. Refer to `docs/DATABASE.md` for schema, `docs/API.md` for endpoints, and `docs/SCORING_RULES.md` for cricket logic.
