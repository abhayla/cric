# Code Standards

Single reference for all coding conventions in CricApp. Covers naming, API design, state management, error handling, testing, performance, logging, linting, and tooling.

For file naming and placement rules, see [.claude/rules.md](../../.claude/rules.md).
For code principles (YAGNI, KISS, DRY), see [CLAUDE.md](../../CLAUDE.md#code-principles-yagni-kiss-dry).

---

## 1. Variable Naming Patterns

### Dart (Flutter)

| Pattern | Convention | Examples |
|---------|-----------|----------|
| ID suffix | `camelCase` ending in `Id` | `matchId`, `bowlerId`, `deliveryId` |
| Boolean prefix | `is`, `has`, `can`, `should` | `isWide`, `hasExtraRuns`, `canUndo`, `shouldRotateStrike` |
| Lists | Plural nouns | `deliveries`, `players`, `innings` |
| Maps with key hint | `<value>By<Key>` | `playerStatsById`, `matchesByDate`, `teamsByName` |
| Callbacks/handlers | `on` prefix | `onDeliveryRecorded`, `onWicketFallen`, `onOverCompleted` |
| Private members | Underscore prefix | `_currentInnings`, `_syncQueue`, `_isLoading` |
| State flags | `is` + past participle or adjective | `isLoading`, `isSynced`, `isCompleted` |
| Counts | Noun + `Count` | `wicketCount`, `overCount`, `runCount` |
| Nullable | No special prefix — Dart's `?` suffix handles it | `String? displayName`, `int? targetScore` |

### TypeScript (Bun Server)

| Pattern | Convention | Examples |
|---------|-----------|----------|
| ID suffix | `camelCase` ending in `Id` | `matchId`, `bowlerId`, `userId` |
| Boolean prefix | `is`, `has`, `can` | `isLegal`, `hasWicket`, `canBowlNextOver` |
| Arrays | Plural nouns | `deliveries`, `players`, `innings` |
| Callbacks | `on` prefix or verb phrase | `onMessage`, `handleDelivery` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_OVERS`, `WICKETS_PER_INNINGS` |
| Env variables | `SCREAMING_SNAKE_CASE` | `DATABASE_URL`, `FIREBASE_PROJECT_ID` |

---

## 2. Function & Method Naming

### Riverpod Notifier Methods (Dart)

Use `verb + noun` pattern. The verb describes the action, the noun describes the cricket domain object.

```dart
// Scoring notifier
recordDelivery()        // not addBall() or saveBall()
undoLastDelivery()      // not undo() or revert()
rotateStrike()          // not swapBatsmen()
completeOver()          // not endOver() or finishOver()
startInnings()          // not beginInnings()
endInnings()            // not completeInnings() — "complete" is for overs
selectBowler()          // not chooseBowler()
selectBatter()          // not chooseBatter()

// Match setup notifier
createMatch()
updateMatchSettings()
recordToss()
selectPlayingXI()
```

### Repository Methods (Dart)

Use CRUD verbs: `get`, `create`, `update`, `delete`, `list`.

```dart
getMatch(String matchId)
getMatchById(String id)           // when "by" clause needed
createDelivery(Delivery delivery)
updateInnings(Innings innings)
deleteMatch(String matchId)
listMatchesByTeam(String teamId)
listDeliveriesByInnings(String inningsId)
```

### Datasource Methods (Dart)

Include source hint in the method name.

```dart
// Local datasource
insertDeliveryLocal(DeliveryModel model)
getMatchFromLocal(String matchId)
getUnsyncedDeliveries()

// Remote datasource
fetchMatchFromServer(String matchId)
pushDeliveryToServer(DeliveryModel model)
syncDeliveriesToServer(List<DeliveryModel> models)
```

### Service Methods (TypeScript)

Use domain verbs. Services encapsulate business logic.

```typescript
// scoring.service.ts
processDelivery(delivery: DeliveryInput): Promise<DeliveryResult>
validateDelivery(delivery: DeliveryInput): ValidationResult
calculateRunsFromDelivery(delivery: Delivery): RunBreakdown
getInningsStats(inningsId: string): Promise<InningsStats>

// match.service.ts
createMatch(input: CreateMatchInput): Promise<Match>
transitionMatchState(matchId: string, newState: MatchState): Promise<Match>
```

### Route Handlers (TypeScript)

Keep handlers thin — validate, call service, return. Name the handler function after the HTTP method + resource.

```typescript
// routes/v1/scoring.ts
app.post('/deliveries', createDelivery)
app.delete('/deliveries/:id', undoDelivery)
app.get('/innings/:id/stats', getInningsStats)
```

---

## 3. Cricket-Domain Naming

Use standard cricket terminology. The codebase should read like a cricket conversation.

| Use | Don't Use | Why |
|-----|-----------|-----|
| `delivery` | `ball_event`, `ball_record` | "Delivery" is the cricket term for a bowled ball |
| `innings` | `round`, `inning` | "Innings" is both singular and plural in cricket |
| `striker` | `current_batter`, `facing_batter` | "Striker" is the standard cricket term |
| `nonStriker` | `other_batter`, `runner_end` | "Non-striker" is the standard term |
| `wide` | `wide_ball` | Just "wide" — the type implies it's a delivery |
| `noBall` | `no_ball_delivery` | Just "no-ball" |
| `bye` | `bye_run` | "Bye" is the cricket term |
| `legBye` | `leg_bye_run` | "Leg-bye" is the cricket term |
| `maiden` | `scoreless_over` | "Maiden" is the cricket term |
| `over` | `ball_set` | "Over" = 6 legal deliveries |
| `dismissal` | `out_type`, `wicket_type` | "Dismissal" is the formal cricket term |
| `declaration` | `early_end`, `voluntary_end` | "Declaration" is the cricket term for voluntary innings end |

---

## 4. Database Naming Deep-Dive

Extends the conventions in [CLAUDE.md](../../CLAUDE.md). See [DATABASE.md](../planning/DATABASE.md) for the full schema.

### Junction Tables

Format: `<semantic_name>` describing the relationship, plural.

```sql
team_rosters       -- team membership (not team_players)
match_players      -- players in a specific match
```

### Stats Tables

Format: `<domain>_stats` with a scope qualifier.

```sql
batting_stats      -- per-innings batting stats
bowling_stats      -- per-innings bowling stats
fielding_stats     -- per-innings fielding stats
player_career_stats -- aggregated across all matches
```

### Enum-Like Columns

Use `varchar` with constrained values, not database enums. This avoids migration headaches.

```sql
match_status varchar(20)    -- 'setup', 'toss', 'live', 'innings_break', 'completed', 'abandoned'
player_role varchar(20)     -- 'batter', 'bowler', 'all_rounder', 'keeper'
batting_style varchar(20)   -- 'right_hand', 'left_hand'
```

### Timestamps

Every table gets `created_at` and `updated_at` columns.

```sql
created_at timestamp DEFAULT now()
updated_at timestamp DEFAULT now()    -- updated via trigger or application code
```

### Soft Delete

Use `is_active boolean DEFAULT true` for entities that should not be hard-deleted (teams, players).

Deliveries and stats are hard-deleted on undo — they are transactional, not reference data.

### Primary Key Types

| Table Category | PK Type | Examples |
|----------------|---------|----------|
| Entity tables | `uuid DEFAULT gen_random_uuid()` | `users`, `teams`, `matches`, `deliveries`, `innings` |
| Master/seed data | `serial` (auto-increment integer) | `ball_types`, `dismissal_types`, `shot_types`, `fielding_positions`, `wagon_wheel_zones` |

UUIDs enable offline creation and cross-device sync without server round-trips.

### Foreign Key Columns

Use `<singular_entity>_id` pattern for all foreign keys:

```sql
team_id     -- references teams.id
bowler_id   -- references users.id (the bowling player)
innings_id  -- references innings.id
match_id    -- references matches.id
```

### Boolean Columns

Use `is_<adjective>` or `is_<past_participle>` pattern:

```sql
-- From deliveries table
is_wide, is_no_ball, is_bye, is_leg_bye, is_wicket
is_legal, is_boundary_four, is_boundary_six, is_free_hit

-- From other tables
is_completed    -- innings, overs
is_maiden       -- overs
is_not_out      -- batting_stats
is_active       -- team_rosters
```

Exception: `synced` (deliveries) and `requires_fielder` / `requires_bowler_credit` (dismissal_types) — descriptive enough without `is_` prefix.

### Decimal Precision

| Data Type | Precision | Examples |
|-----------|-----------|----------|
| Overs | `decimal(5,1)` | `innings.total_overs`, `fall_of_wickets.overs_at_fall` |
| Overs (smaller scope) | `decimal(4,1)` | `bowling_stats.overs_bowled` |
| Overs (career) | `decimal(6,1)` | `player_career_stats.overs_bowled` |
| Averages | `decimal(6,2)` | `batting_average`, `bowling_average` |
| Rates | `decimal(5,2)` | `economy_rate`, `run_rate` |
| Strike rates | `decimal(6,2)` | `batting_strike_rate`, `bowling_strike_rate` |
| Percentages | `decimal(5,2)` | `dot_ball_percentage`, `boundary_percentage` |

### Materialized View Naming

Format: `<subject>_<scope>_<type>` describing what data they aggregate.

```sql
player_match_summary      -- player performance per match
innings_scoreboard        -- full scorecard view
batting_innings_summary   -- batting card with dismissal description
bowling_innings_summary   -- bowling analysis card
player_season_stats       -- aggregated stats by format
```

Refresh trigger: auto-refresh after match status changes to `completed`.

---

## 5. API Standards

See [API.md](../planning/API.md) for full endpoint definitions.

### Versioning

All endpoints use `/api/v1` prefix.

### Authentication

- **REST:** `Authorization: Bearer <firebase_jwt_token>` header on every request.
- **WebSocket:** `wss://host/ws?token=<firebase_jwt>` query parameter on connection.

### JSON Field Naming

| Layer | Convention | Example |
|-------|-----------|---------|
| Database (PostgreSQL/SQLite) | `snake_case` | `innings_number`, `is_legal`, `created_at` |
| Server TypeScript internals | `camelCase` | `inningsNumber`, `isLegal`, `createdAt` |
| JSON API responses | `camelCase` | `"inningsNumber"`, `"isLegal"`, `"createdAt"` |
| Dart models | `camelCase` | `inningsNumber`, `isLegal`, `createdAt` |

Drizzle handles DB↔TypeScript mapping. `@JsonKey(name:)` or `json_serializable` handles Dart↔JSON mapping.

### Response Envelope

```json
// Single resource — singular key
{ "match": { "id": "uuid", "status": "live", ... } }

// Collection — plural key with total and page
{
  "teams": [ ... ],
  "total": 42,
  "page": 1
}
```

### HTTP Status Codes

| Status | Usage |
|--------|-------|
| `200` | Successful read or update |
| `201` | Resource created (POST /teams, POST /matches) |
| `400` | Validation error (bad request body) |
| `401` | Missing or invalid auth token |
| `403` | Authenticated but not authorized (not the scorer) |
| `404` | Resource not found |
| `409` | Conflict (sync conflict, duplicate) |
| `429` | Rate limited |
| `500` | Internal server error |

### Pagination

Offset-based with `?page=1&limit=20` query parameters. Default 20 items per page, max 50.

```json
{
  "matches": [ ... ],
  "total": 87,
  "page": 2
}
```

### WebSocket Message Shape

All messages follow a consistent structure:

```json
{
  "type": "score_update",
  "matchId": "uuid",
  "data": { ... }
}
```

- `type` uses `snake_case` (e.g., `score_update`, `join_match`, `undo_delivery`).
- `matchId` is required on all match-scoped messages.
- `data` contains the payload (omitted for `join_match` / `leave_match`).
- Error messages use `{ "type": "error", "message": "..." }` (no `matchId` or `data`).

| Direction | Message Types |
|-----------|--------------|
| Client → Server | `join_match`, `leave_match`, `delivery`, `undo_delivery` |
| Server → Client | `score_update`, `wicket`, `innings_complete`, `match_complete`, `error` |

---

## 6. State Management Patterns

See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 3 for full Riverpod patterns and examples.

### AsyncNotifier vs Notifier

| Type | Use When | Example |
|------|----------|---------|
| `AsyncNotifier` | `build()` awaits data (initial fetch, refresh) | Loading match list, fetching player stats |
| `Notifier` | Synchronous state transitions | Scoring state, match setup form state, UI toggles |

### Freezed State Class Design

| Field Type | When to Use | Example |
|------------|------------|---------|
| `required T` | Always present, must be provided | `required String matchId`, `required int totalRuns` |
| `@Default(value) T` | Has a sensible default | `@Default(false) bool isLoading`, `@Default(0) int wickets` |
| `T?` nullable | Genuinely optional or not yet available | `String? error`, `Delivery? lastDelivery` |

Rules:
- Always include `String? error` for error state.
- Use `copyWith` for all state transitions (per CLAUDE.md DRY rules).
- Do not add fields "for future use" — add when the feature needs them.

### Provider Declaration Location

| Provider Scope | Location | Example |
|---------------|----------|---------|
| Feature-specific | `features/<feature>/providers.dart` | `scoringNotifierProvider`, `matchSetupProvider` |
| App-wide (auth, connectivity) | `src/app/providers.dart` | `authStateProvider`, `connectivityProvider` |
| Infrastructure (DB, Dio, WS) | `src/shared/providers/` | `databaseProvider`, `dioProvider`, `websocketProvider` |

---

## 7. Error Handling Patterns

### Custom Exception Classes (Dart)

One exception class per domain concern. Defined in `apps/mobile/lib/src/core/errors/exceptions.dart`.

```dart
class ScoringException implements Exception {
  final String message;
  const ScoringException(this.message);
}

class SyncException implements Exception {
  final String message;
  final bool isRetryable;
  const SyncException(this.message, {this.isRetryable = true});
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
```

### Error Flow

```
Datasource throws → Repository catches and wraps → Notifier catches and updates state
     DriftError         ScoringException              state = state.copyWith(error: ...)
     DioException        SyncException
     FirebaseException   AuthException
```

- **Datasources** throw raw errors (Drift, Dio, Firebase exceptions).
- **Repositories** catch datasource exceptions, wrap in domain exceptions.
- **Notifiers** catch domain exceptions, update Freezed state with error info.
- **Never** swallow exceptions silently. Always log or surface to the user.

### Server Error Responses (TypeScript)

Use consistent error shape across all endpoints. See [API.md](../planning/API.md) Section 3 for the full specification.

```typescript
// Error response shape
{
  "error": {
    "code": "INVALID_DELIVERY",
    "message": "Cannot bowl consecutive overs with same bowler",
    "details": { }
  }
}
```

The `details` object is optional — include it for validation errors with field-level detail (e.g., `{ "field": "bowlerId", "reason": "Same as previous over" }`).

### Error Codes

Error codes use `SCREAMING_SNAKE_CASE`. Standard codes map to HTTP statuses:

| Error Code | HTTP Status | Description |
|-----------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid auth token |
| `FORBIDDEN` | 403 | Not authorized for this action |
| `NOT_FOUND` | 404 | Resource does not exist |
| `VALIDATION_ERROR` | 400 | Invalid request body or parameters |
| `CONFLICT` | 409 | Sync conflict or duplicate resource |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

Domain-specific codes (all map to `400` unless noted):

| Error Code | Context |
|-----------|---------|
| `INVALID_DELIVERY` | Delivery input fails validation (Step 1 of pipeline) |
| `MATCH_NOT_LIVE` | Attempted scoring action on a non-LIVE match |
| `INVALID_STATE_TRANSITION` | Invalid match state change (e.g., SETUP → COMPLETED) |
| `CONSECUTIVE_OVER` | Same bowler attempting consecutive overs |
| `SYNC_CONFLICT` | Client data conflicts with server (maps to `409`) |

---

## 8. Offline-First Data Pattern

See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 2 for the full workflow with code examples.

| Step | Action | State |
|------|--------|-------|
| 1 | Write to local Drift/SQLite | `synced = false` |
| 2 | UI updates immediately from local DB | User sees instant feedback |
| 3 | Sync engine pushes to server when online | `syncing` |
| 4 | Server confirms, local record updated | `synced = true` |
| 5 | Offline queue processes FIFO when connectivity returns | Batch processing |

- **Reads:** Always from local Drift DB. Background sync pulls latest from server.
- **Conflicts:** Server wins (last-write-wins on `updated_at`).
- **Deliveries:** Append-only during a match — concurrent editing of same delivery is not possible.

---

## 9. Performance Patterns

Target: smooth performance on 2GB RAM budget Android devices. See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 18 for detailed examples.

| Pattern | Rule | Why |
|---------|------|-----|
| Riverpod `select()` | Use `ref.watch(provider.select((s) => s.field))` for granular rebuilds | Prevents unnecessary widget rebuilds |
| `ListView.builder` | Always use for lists with >10 items | Lazy construction saves memory |
| Image compression | All images < 100KB before storage | Low-bandwidth devices, limited storage |
| Database indexes | All hot-path queries must use indexed columns | See [DATABASE.md](../planning/DATABASE.md) for index list |
| Pagination | 20 items/page default, max 50 | Prevents loading unbounded data into memory |

---

## 10. Testing Standards

See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 13 for per-layer testing examples and the scoring engine test matrix.

### Coverage Targets

| Type | Target | Focus Areas |
|------|--------|-------------|
| Unit Tests | 60% | Scoring engine, cricket rules, MVP algorithm, sync engine |
| Widget Tests | 30% | Scoring controls, scorecard rendering, wagon wheel, chart data binding |
| Integration Tests | 10% | Full match scoring flow, offline sync, auth flow |

### Per-Layer Testing Rules

| Layer | Test Type | Approach |
|-------|-----------|----------|
| Domain (entities, functions) | Pure unit tests | No mocks — domain has no external dependencies |
| Data (repositories) | Unit tests with mocked datasources | Use `mocktail` to mock Drift/Dio datasources |
| Presentation (notifiers) | Unit tests with mocked repositories | Create notifier with mock repo, assert state transitions |
| Widgets | Widget tests with `ProviderScope` overrides | Pump widget, tap buttons, verify UI updates |

### Mocking Library

Use **`mocktail`** (not `mockito`). Already in `dev_dependencies`.

```dart
import 'package:mocktail/mocktail.dart';

class MockScoringRepository extends Mock implements ScoringRepository {}
```

### Regression Test Mandate

Every bug fix **must** include a test that:
1. Fails before the fix (reproduces the bug).
2. Passes after the fix.

No exceptions for scoring engine bugs.

### Test Failure Escalation

Follow escalation tiers in [CODE_FIXES.md](CODE_FIXES.md):
- **Normal (1-3 iterations):** Re-read failure, try a different code path.
- **Tier 1 (4-5):** Slow down, challenge assumptions.
- **Tier 2 (6-7):** Widen scope, trace full path.
- **Tier 3 (8-9):** Audit architecture.
- **Hard Cap (10):** Stop and present findings to user.

---

## 11. Logging Standards

See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 15 for Crashlytics setup and scoring performance logging.

### Dart (Flutter)

- **Dev tracing:** `debugPrint()` — stripped in release builds automatically.
- **Structured logging:** `package:logger` — one `Logger` instance per class.
- **Never use `print()`** — it is not stripped in release and bypasses log levels.

```dart
// Levels: d (debug), i (info), w (warning), e (error + stack trace)
final _log = Logger();
_log.d('Processing delivery: $deliveryId');
_log.e('Scoring pipeline failed', error: e, stackTrace: st);
```

### TypeScript (Bun Server)

Structured JSON logging via `utils/logger.ts`. Every log entry includes context fields:

```typescript
logger.info({ matchId, event: 'delivery_processed', timestamp: Date.now() });
logger.error({ matchId, event: 'sync_failed', error: err.message });
```

### Privacy Rules

- **Never log:** Phone numbers, email addresses, auth tokens, passwords.
- **Use UUIDs** for identity in log entries — never PII.
- **Mask PII** before sending to Crashlytics or any external service.

---

## 12. Import Ordering

### Dart

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter/package imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

// 3. Project relative imports
import '../../core/errors/exceptions.dart';
import '../domain/entities/delivery.dart';
import 'scoring_notifier.dart';
```

### TypeScript

```typescript
// 1. Node/Bun builtins (rare)

// 2. npm packages
import { Elysia } from 'elysia';
import { eq } from 'drizzle-orm';

// 3. Local imports: config > db > services > middleware > utils > types
import { env } from '../config/env';
import { db } from '../db';
import { deliveries } from '../db/schema';
import { scoringService } from '../services/scoring.service';
import { logger } from '../utils/logger';
import type { DeliveryInput } from '../types/cricket';
```

---

## 13. Code Formatting & Linting

### Formatting Rules

- **Dart:** Use `dart format` defaults (line length 80). Do not override.
- **TypeScript:** Use project `.prettierrc` or Bun defaults.
- **Max function length:** ~50 lines. If longer, extract a helper.
- **Max file length:** ~300 lines. If longer, split into logical units.
- **Prefer early returns** over nested if-else chains.
- **One blank line** between top-level declarations, no more.
- **Trailing commas** in Dart for multi-line parameter lists (enables better formatting).

### Lint Configuration

**Dart** — `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
```

`avoid_print` enforces using `debugPrint()` or `package:logger` instead of `print()`.

**TypeScript** — `tsconfig.json` strict settings:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true
  }
}
```

### Debug Assertions

Use `assert()` for invariant checks in Dart. Assertions are stripped in release builds.

```dart
assert(legalBallsInOver >= 0 && legalBallsInOver <= 6);
assert(striker.id != nonStriker.id, 'Striker and non-striker must be different');
```

---

## 14. Dependencies & Tooling

### Version Pinning

Use `^` caret ranges for all dependencies. Pin exact versions only for known-broken minor releases.

```yaml
# pubspec.yaml — use caret ranges
flutter_riverpod: ^3.0.0
drift: ^2.15.0
```

```json
// package.json — use caret ranges
"elysia": "^1.2.0",
"drizzle-orm": "^0.35.0"
```

### Code Generation Triggers

| Trigger | Generated Files | Command |
|---------|----------------|---------|
| `@freezed` class modified | `*.freezed.dart` | `dart run build_runner build --delete-conflicting-outputs` |
| Drift table definitions modified | `*.g.dart` | Same build_runner command |
| `@riverpod` annotations modified | `*.g.dart` | Same build_runner command |
| `@JsonSerializable` models modified | `*.g.dart` | Same build_runner command |
| go_router typed routes modified | `*.gr.dart` | Same build_runner command |
| Drizzle schema files modified | Migration SQL files | `bunx drizzle-kit generate && bunx drizzle-kit migrate` |

**Never edit** `*.g.dart`, `*.freezed.dart`, `*.gr.dart` manually. If generated output is wrong, fix the source and re-run the generator.
