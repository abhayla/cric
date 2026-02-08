# CricApp - Cricket Scoring App

A cricket scoring mobile app targeting amateur/grassroots cricketers in India. Built with Flutter + Bun for optimal performance on low-end Android devices.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) + Riverpod 3.0 |
| Backend | Bun + ElysiaJS + Drizzle ORM |
| Database (Server) | PostgreSQL |
| Database (Local) | Drift / SQLite |
| Auth | Firebase Auth (Phone OTP, Google, Email) |
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
│   ├── CONTINUE_PROMPT.md
│   ├── API.md
│   ├── DATABASE.md
│   ├── SCORING_RULES.md
│   └── IMPLEMENTATION_PLAN.md
├── Notes
├── .gitignore
└── README.md
```

## Documentation

- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) - Full phased roadmap, architecture, and verification plan
- [API Design](docs/API.md) - REST endpoints and WebSocket protocol
- [Database Schema](docs/DATABASE.md) - All 24 tables, views, and design decisions
- [Scoring Rules](docs/SCORING_RULES.md) - Cricket rules engine, state machine, MVP algorithm
- [Continue Prompt](docs/CONTINUE_PROMPT.md) - Context for resuming work across sessions

## Key Features (MVP)

1. **Live Ball-by-Ball Scoring** - Tap-based scoring with offline support
2. **Player Profiles** - Career stats across batting, bowling, fielding
3. **Team Management** - Create teams, manage rosters
4. **Match Analytics** - Wagon wheel, manhattan chart, worm graph, MVP rankings
5. **Real-time Updates** - WebSocket broadcasting to all match viewers
6. **Offline-First** - Score matches without internet, sync later
