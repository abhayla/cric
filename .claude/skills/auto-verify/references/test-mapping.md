# Auto-Verify — CricScores Test Mapping Reference

## Flutter Test Directory Structure

```
apps/mobile/test/src/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── scoring/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── matches/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── teams/
│   ├── tournaments/
│   ├── analytics/
│   ├── players/
│   └── home/
└── shared/
    └── data/
        ├── database/
        └── sync/
```

## Server Test Directory Structure

```
apps/server/test/
├── services/
│   ├── auth.service.test.ts
│   ├── scoring.service.test.ts
│   ├── match.service.test.ts
│   ├── sync.service.test.ts
│   └── ...
├── routes/
│   ├── auth.routes.test.ts
│   ├── scoring.routes.test.ts
│   └── ...
└── db/
    └── schema/
```

## Adjacency Map (Regression Testing)

### Flutter Feature Dependencies

```
scoring → matches (match state)
scoring → teams (player roster for batting/bowling)
scoring → analytics (stats feed charts)
scoring → players (career stats aggregation)
matches → teams (team selection)
matches → tournaments (fixture linkage)
tournaments → teams (standings)
home → matches + scoring + players (dashboard data)
shared/database → ALL features (schema changes)
shared/sync → scoring + matches (offline sync)
```

### Server Service Dependencies

```
scoring.service → match.service (match state queries)
scoring.service → sync.service (broadcast deliveries)
match.service → team.service (roster lookups)
tournament.service → match.service (fixture management)
stats.service → scoring.service (aggregation queries)
db/schema → ALL services (schema is foundation)
```

## Automated Diagnosis Patterns (CricScores-Specific)

| Error Pattern | Automated Action |
|---|---|
| `type 'Null' is not a subtype` | Check Freezed model nullability, add null guard |
| `RangeError (index)` | Check innings/over array bounds |
| `Bad state: No element` | Check empty list before `.first` / `.last` |
| `MissingPluginException` | Add `TestWidgetsFlutterBinding.ensureInitialized()` |
| `Expected X actual Y` (runs/score) | Trace through delivery pipeline Step 2 (calculate runs) |
| `Strike rotation wrong` | Trace through pipeline Step 5, check odd/even + over-end logic |
| `Connection refused :3000` | Server not running, start with `cd apps/server && bun run src/index.ts` |
| `relation "X" does not exist` | Run migrations: `cd apps/server && bunx drizzle-kit migrate` |
| `duplicate key value` | Check UUID generation, use `ON CONFLICT` clause |
| `expected stream of type T` | Check Riverpod provider type, rebuild with `build_runner` |
| `Could not find a generator` | Run `dart run build_runner build --delete-conflicting-outputs` |
