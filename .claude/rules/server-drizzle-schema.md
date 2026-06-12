---
name: server-drizzle-schema
description: >
  Drizzle schema conventions for the CricScores PostgreSQL database: mandatory
  id/createdAt/updatedAt columns, the deliberate cascade-vs-restrict delete taxonomy,
  named unique constraints, and the migrate + schema-parity workflow after changes.
globs: ["apps/server/src/db/schema/*.ts"]
synthesized: true
version: "1.0.0"
private: false
---

# Drizzle Schema Rules

All tables live in `apps/server/src/db/schema/*.ts` (users, teams, matches, innings, deliveries, stats, tournaments, master-data, activity-feed) and are re-exported via `schema/index.ts`.

## Mandatory Columns on EVERY Table

Every table MUST declare this exact trio (verified 100% compliant across `users.ts`, `stats.ts`, `matches.ts`):

```ts
id: uuid('id').defaultRandom().primaryKey(),
createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
```

- MUST NOT use serial/integer PKs, client-generated IDs as PK, or composite PKs for new tables — UUIDs are what the offline-sync protocol and WebSocket payloads assume.
- MUST NOT omit `$onUpdate(() => new Date())` on `updatedAt` — without it the column silently freezes at insert time and staleness checks lie.
- Column names are snake_case in SQL, camelCase in TS — `varchar('display_name', ...)` as `displayName` (see `users.ts` ~lines 4-16 for the reference shape).

## Delete Strategy Is a Deliberate Taxonomy — Never Default

`onDelete` is chosen per relationship class, not left to the default (`no action`). The codebase taxonomy:

| Relationship class | `onDelete` | Evidence |
|---|---|---|
| Child/derived rows owned by a parent (stats → innings, deliveries → innings, teamPlayers → teams) | `'cascade'` | `stats.ts` ~lines 8, 32, 54; `teams.ts` ~line 17 |
| References to shared entities (→ users, → teams from matches/tournaments) | `'restrict'` | `stats.ts` playerId refs; `matches.ts` ~lines 9-16; `tournaments.ts` ~lines 42-111 |
| Optional/annotative references (dismissalType, fielder, dismissedBy) | `'set null'` | `stats.ts` ~lines 17-19 |

```ts
inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
fielderId: uuid('fielder_id').references(() => users.id, { onDelete: 'set null' }),
```

- Deleting an innings MUST take its derived stats and deliveries with it (cascade); deleting a user or team with match history MUST be blocked by the database (restrict), not by application-level checks alone.
- When adding a foreign key, pick from this taxonomy explicitly. MUST NOT omit `onDelete` and MUST NOT cascade a reference to a shared entity "for convenience" — that turns a user deletion into silent stats destruction.

## Named Unique Constraints for Business Rules

Unique business invariants get NAMED constraints with the `uq_<table>_<cols>` convention (see `stats.ts`):

```ts
unique('uq_batting_stats_innings_player').on(table.inningsId, table.playerId),
unique('uq_bowling_stats_innings_player').on(table.inningsId, table.playerId),
unique('uq_career_stats_player_format').on(table.playerId, table.format),
```

- MUST name every unique constraint — auto-generated names make migration diffs and constraint-violation errors unreadable.
- One-stats-row-per-player-per-innings is enforced by the DATABASE, not by upsert logic alone. New "exactly one X per Y" invariants follow the same pattern: add the constraint, then write the upsert against it.

## After ANY Schema Change — the Full Sequence

A schema edit is not done until all four steps run, in order:

1. `bun run db:generate` — drizzle-kit generates the SQL migration (`apps/server/package.json` ~line 9)
2. Review the generated migration — confirm it matches intent (especially destructive changes)
3. `bun run db:migrate` — apply it (~line 10)
4. Run the `/schema-parity` skill — the Flutter app's Drift schema MUST track the Drizzle schema; a server-only schema change breaks offline sync silently

- MUST NOT hand-edit applied migrations or apply schema changes with raw SQL outside drizzle-kit — the migration journal becomes the lie that breaks the next `db:migrate`.
- MUST NOT merge a schema change without the parity check — the mobile Drift schema (`/schema-parity`, `/drift-migrate` skills) is a downstream consumer of every table the sync protocol touches.

## CRITICAL RULES

- EVERY table MUST have `id: uuid().defaultRandom().primaryKey()`, `createdAt: timestamp().defaultNow().notNull()`, and `updatedAt: timestamp().defaultNow().$onUpdate(() => new Date()).notNull()`.
- MUST choose `onDelete` from the taxonomy: `'cascade'` for child/derived tables, `'restrict'` for shared entities (users, teams), `'set null'` for optional annotative refs — NEVER omit it or default it.
- Unique business constraints MUST be named (`uq_<table>_<cols>`) and enforced in the database, not only in application code.
- After ANY schema change: `bun run db:generate` → review → `bun run db:migrate` → run `/schema-parity` so the Drift mobile schema tracks Drizzle.
- MUST NOT hand-edit applied migrations or bypass drizzle-kit with raw DDL.
