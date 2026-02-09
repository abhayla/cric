# CricApp - Continue Prompt

## Context for Resuming Work

**Project:** CricApp - Cricket scoring mobile app (CricHeroes competitor)
**Status:** Planning complete, implementation not yet started
**Working Directory:** `C:\Abhay\VideCoding\cric\`

## Tech Stack

- **Frontend:** Flutter (Dart) + Riverpod 3.0
- **Backend:** Bun + ElysiaJS + Drizzle ORM
- **Database:** PostgreSQL (server) + Drift/SQLite (local)
- **Auth:** Firebase Auth (Phone OTP, Google, Email)
- **Real-time:** Bun Native WebSockets
- **Target:** Android only (MVP)
- **UI:** Material 3 Dark Theme

## Documentation

### Planning Docs (`docs/planning/`)

| Document | Contents |
|----------|----------|
| `docs/planning/PDR.md` | Product vision, user stories (15), success metrics, non-functional requirements, MVP scope boundaries |
| `docs/planning/IMPLEMENTATION_PLAN.md` | Architecture, folder structure, packages, phased roadmap (7 phases, 14 weeks), verification plan, testing strategy |
| `docs/planning/DATABASE.md` | Full schema for 24 tables + 5 materialized views, indexes, SQLite local schema, sync strategy |
| `docs/planning/API.md` | All REST endpoints (auth, teams, matches, scoring, players, analytics, sync, health) + full WebSocket protocol |
| `docs/planning/SCORING_RULES.md` | Match state machine, delivery processing pipeline (10 steps), all cricket rules (strike rotation, wides, no-balls, byes, leg-byes, maidens, innings completion, dismissal types), undo logic, MVP algorithm, UI interactions |
| `docs/planning/blueprint.html` | Interactive visual blueprint — 18 screen wireframes, 5 scoring dialogs, backend architecture, cricket domain overlays |

### Process Docs (`docs/process/`)

| Document | Contents |
|----------|----------|
| `docs/process/DOCS_MANAGEMENT.md` | Documentation map, folder structure rules, maintenance guidelines |
| `docs/process/CODE_STANDARDS.md` | Variable naming, function naming, cricket-domain naming, error handling, import ordering |
| `docs/process/IMPLEMENTATION_PRACTICES.md` | Feature implementation workflow (7 steps), offline-first pattern, Riverpod state management, testing approach, WebSocket pattern, code generation, performance |
| `docs/process/CODE_FIXES.md` | Root cause analysis (8 steps), common issue patterns, debugging tools, scoring engine fix protocol |
| `docs/process/GITHUB_ISSUES.md` | Issue templates, label system, milestones, issue workflow, commit message format |
| `docs/process/CLAUDE_CODE_CONFIG.md` | Sub-agent specs (4 agents), skill definitions (6 skills) |

### Other

| Document | Contents |
|----------|----------|
| `CLAUDE.md` | Claude Code project instructions, code principles (YAGNI/KISS/DRY), architecture decisions |
| `.claude/rules.md` | File placement rules, folder structure, naming conventions, anti-patterns |
| `README.md` | Project overview with links to all docs |

## What to Do Next

Start with **Phase 1: Foundation** as described in `docs/planning/IMPLEMENTATION_PLAN.md`:

1. Initialize Flutter project (`apps/mobile/`) with the folder structure from Section 2.1
2. Initialize Bun server (`apps/server/`) with the folder structure from Section 2.2
3. Set up PostgreSQL + Drizzle schema using tables from `docs/planning/DATABASE.md`
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

## Completed Work

### Interactive Architectural Blueprint
- **`docs/planning/blueprint.html`** — Comprehensive single-file HTML blueprint (1763 lines) with:
  - All 18 screens wireframed (Splash, Login, OTP, Profile Setup, Home, Teams List, Create Team, Team Detail, Manage Roster, Match Setup, Toss, Scoring Page, Scorecard, Analytics, Player Profile, Player Stats, Match History)
  - 5 scoring dialogs orbiting the Scoring Page (Extras Panel, Wicket Dialog, Select Next Bowler, Select New Batter, Innings Transition)
  - Backend architecture band (API Layer, WebSocket Protocol, Database ER, Offline Sync swim-lane)
  - Cricket domain overlays (10-step delivery pipeline, match state machine, strike rotation decision tree, extras comparison table, undo mechanism, ScoringState shape, widget-to-state mapping)
  - Interactive pan/zoom (mouse drag + scroll wheel + touch pinch)
  - Navigation sidebar with animated pan-to-section
  - Minimap showing viewport position
  - Glossary of cricket terms
  - Hub-and-spoke layout with Scoring Page as gravitational center

### Best Practices Documentation
- Reorganized `docs/` into `planning/` and `process/` subdirectories
- Created Product Development Requirements (`docs/planning/PDR.md`)
- Created 6 process docs covering code standards, implementation workflow, debugging, issue management, and Claude Code config

## Files in Repository

```
cric/
├── .git/
├── .claude/
│   └── rules.md                  (file placement rules)
├── docs/
│   ├── planning/
│   │   ├── PDR.md                (product requirements)
│   │   ├── IMPLEMENTATION_PLAN.md
│   │   ├── DATABASE.md
│   │   ├── API.md
│   │   ├── SCORING_RULES.md
│   │   └── blueprint.html        (interactive architectural blueprint)
│   ├── process/
│   │   ├── DOCS_MANAGEMENT.md    (documentation map & rules)
│   │   ├── CODE_STANDARDS.md     (naming & formatting)
│   │   ├── IMPLEMENTATION_PRACTICES.md  (feature workflow)
│   │   ├── CODE_FIXES.md         (debugging workflow)
│   │   ├── GITHUB_ISSUES.md      (issue management)
│   │   └── CLAUDE_CODE_CONFIG.md (agent & skill specs)
│   └── CONTINUE_PROMPT.md        (this file)
├── Notes                          (user's working notes)
├── CLAUDE.md                      (Claude Code instructions)
└── README.md
```

## Instructions for Next Session

Read this file first, then read `docs/planning/IMPLEMENTATION_PLAN.md` Phase 1 section. Follow the workflow in `docs/process/IMPLEMENTATION_PRACTICES.md`. Begin implementation from step 1. Refer to `docs/planning/DATABASE.md` for schema, `docs/planning/API.md` for endpoints, `docs/planning/SCORING_RULES.md` for cricket logic, and `docs/planning/blueprint.html` for visual architecture reference.
