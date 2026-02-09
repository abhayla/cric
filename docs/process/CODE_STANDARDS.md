# Code Standards

This document extends the naming conventions in [CLAUDE.md](../../CLAUDE.md) with detailed patterns for variables, functions, database naming, error handling, and imports.

For file naming and placement rules, see [.claude/rules.md](../../.claude/rules.md).

---

## Variable Naming Patterns

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

## Function & Method Naming

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

## Cricket-Domain Naming

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

## Database Naming Deep-Dive

Extends the conventions in [CLAUDE.md](../../CLAUDE.md). See [DATABASE.md](../planning/DATABASE.md) for the full schema.

### Junction Tables

Format: `<entity1>_<entity2>` in alphabetical order, plural.

```sql
team_players       -- not player_teams or team_player
match_players      -- not player_matches
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
match_status varchar(20)    -- 'SETUP', 'TOSS', 'INNINGS_1', etc.
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

---

## Error Handling Patterns

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

Use consistent error shape across all endpoints.

```typescript
// Error response shape
{
  "error": {
    "code": "INVALID_DELIVERY",
    "message": "Cannot bowl consecutive overs with same bowler"
  }
}
```

---

## Import Ordering

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

## Code Formatting

- **Dart:** Use `dart format` defaults (line length 80). Do not override.
- **TypeScript:** Use project `.prettierrc` or Bun defaults.
- **Max function length:** ~50 lines. If longer, extract a helper.
- **Max file length:** ~300 lines. If longer, split into logical units.
- **Prefer early returns** over nested if-else chains.
- **One blank line** between top-level declarations, no more.
- **Trailing commas** in Dart for multi-line parameter lists (enables better formatting).
