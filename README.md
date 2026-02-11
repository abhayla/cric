# CricApp - Cricket Scoring App

A cricket scoring mobile app targeting amateur/grassroots cricketers in India. Built with Flutter + Bun for optimal performance on low-end Android devices.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) + Riverpod 3.0 |
| Backend | Bun + ElysiaJS + Drizzle ORM |
| Database (Server) | PostgreSQL |
| Database (Local) | Drift / SQLite |
| Auth | Firebase Auth (Phone OTP only for MVP) |
| Real-time | Bun Native WebSockets |
| Target | Android only (MVP) |
| UI Theme | Material 3 Dark |

## Project Structure

```
cric/
├── apps/
│   ├── mobile/          # Flutter app
│   └── server/          # Bun backend
├── docs/
│   ├── planning/        # Product & architecture docs
│   │   ├── PDR.md
│   │   ├── IMPLEMENTATION_PLAN.md
│   │   ├── DATABASE.md
│   │   ├── API.md
│   │   ├── SCORING_RULES.md
│   │   ├── blueprint.html
│   │   └── CRICHEROES_REFERENCE.md
│   ├── process/         # Workflow & standards docs
│   │   ├── PROJECT_MANAGEMENT.md
│   │   ├── CODE_STANDARDS.md
│   │   ├── IMPLEMENTATION_PRACTICES.md
│   │   ├── CODE_FIXES.md
│   │   ├── GITHUB_ISSUES.md
│   │   └── CLAUDE_CODE_CONFIG.md
│   ├── debug/           # Debug iteration logs
│   └── CONTINUE_PROMPT.md
├── scripts/
│   └── validate-structure/  # CI structure validation
├── .claude/
│   ├── rules.md
│   ├── hooks/           # Automated guardrails (7 hooks)
│   ├── agents/          # Research-only sub-agents (13)
│   └── skills/          # User-invocable skills (12)
├── .github/
│   └── workflows/       # CI pipeline
├── CLAUDE.md
├── .gitignore
└── README.md
```

## Documentation

### Planning

- [Product Requirements](docs/planning/PDR.md) - Product vision, user stories, success metrics, MVP scope
- [Implementation Plan](docs/planning/IMPLEMENTATION_PLAN.md) - Full phased roadmap, architecture, and verification plan
- [API Design](docs/planning/API.md) - REST endpoints and WebSocket protocol
- [Database Schema](docs/planning/DATABASE.md) - All 28 tables, views, and design decisions
- [Scoring Rules](docs/planning/SCORING_RULES.md) - Cricket rules engine, state machine, MVP algorithm
- [Blueprint](docs/planning/blueprint.html) - Interactive wireframes and architecture diagrams (open in browser)
- [CricHeroes Reference](docs/planning/CRICHEROES_REFERENCE.md) - Competitive analysis knowledge base

### Process

- [Project Management](docs/process/PROJECT_MANAGEMENT.md) - Documentation map, maintenance rules, codebase structure enforcement
- [Code Standards](docs/process/CODE_STANDARDS.md) - Naming conventions, error handling, import ordering
- [Implementation Practices](docs/process/IMPLEMENTATION_PRACTICES.md) - Feature workflow, offline-first, testing
- [Code Fixes](docs/process/CODE_FIXES.md) - Debugging workflow, common issues, fix protocol
- [GitHub Issues](docs/process/GITHUB_ISSUES.md) - Issue templates, labels, milestones
- [Claude Code Config](docs/process/CLAUDE_CODE_CONFIG.md) - Sub-agent specs and skill definitions

### Session Management

- [Continue Prompt](docs/CONTINUE_PROMPT.md) - Context for resuming work across sessions

## CI/CD

GitHub Actions CI pipeline (`.github/workflows/ci.yml`) runs on push to `main`/`develop` and PRs:

1. **Structure Validation** — Enforces file placement rules via `scripts/validate-structure/`
2. **Flutter Analyze** — Static analysis (`flutter analyze`)
3. **Flutter Test** — Full test suite (`flutter test`)
4. **Server Lint** — TypeScript type checking (`bunx tsc --noEmit`)
5. **Server Test** — Bun test suite (`bun test`)

Runner: self-hosted (Windows Server 2022 VPS). Jobs skip automatically when their target directory has no changes.

## Key Features (MVP)

1. **Live Ball-by-Ball Scoring** - Tap-based scoring with offline support
2. **Player Profiles** - Career stats across batting, bowling, fielding
3. **Team Management** - Create teams, manage rosters
4. **Match Analytics** - Wagon wheel, manhattan chart, worm graph, MVP rankings
5. **Real-time Updates** - WebSocket broadcasting to all match viewers
6. **Offline-First** - Score matches without internet, sync later
