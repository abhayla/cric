# Bun Server — CricApp Backend

## Architecture
ElysiaJS REST API + Bun native WebSockets, Drizzle ORM on PostgreSQL.

## Structure
- `src/config/` — Environment validation, database connection
- `src/db/schema/` — Drizzle table definitions (source of truth)
- `src/db/migrations/` — Drizzle-kit generated migrations
- `src/db/seed/` — Master data seeding
- `src/routes/v1/` — Versioned API route handlers
- `src/services/` — Business logic layer
- `src/websocket/` — WebSocket handler, rooms, types
- `src/middleware/` — Auth, error handling, CORS
- `src/types/` — Shared TypeScript types/DTOs
- `src/utils/` — Utility functions

## Naming Conventions
- Files: `kebab-case.ts` for utils/middleware, `dot-notation.ts` for services
- Services: `*.service.ts` suffix
- Types/interfaces: `PascalCase`
- Variables/functions: `camelCase`
- Drizzle schema tables: `snake_case` SQL names

## Key Patterns
- Routes validate input, call one service function, return result
- Services contain business logic, access DB via Drizzle
- All DB access through services — never in route handlers
- WebSocket message types defined in `src/types/websocket.ts`

## Database
- Drizzle schema = server-side source of truth
- UUIDs for all primary keys
- `created_at` + `updated_at` on all tables
- Application-level `updated_at` via `.$onUpdate()`

## Commands
```bash
bun run dev              # Watch mode
bun run start            # Production
bun run db:generate      # Generate migrations
bun run db:migrate       # Apply migrations
bun run db:seed          # Seed master data
bun run typecheck        # TypeScript check
```
