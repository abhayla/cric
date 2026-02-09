# Implementation Practices

## Feature Implementation Workflow

Every new feature follows these 7 steps in order.

### Step 1: Read Phase Requirements

Open [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) and read the current phase section. Identify which features, tables, endpoints, and screens are in scope. Do not build anything from a later phase.

### Step 2: Read Relevant Specs

For the feature you're implementing, read the relevant sections:

| Building... | Read... |
|-------------|---------|
| Database tables | [DATABASE.md](../planning/DATABASE.md) — table schema, indexes, constraints |
| API endpoints | [API.md](../planning/API.md) — request/response shapes, status codes |
| Scoring logic | [SCORING_RULES.md](../planning/SCORING_RULES.md) — delivery pipeline, state machine |
| UI screens | [blueprint.html](../planning/blueprint.html) — wireframes, dialog layouts |

### Step 3: Check Blueprint Wireframes

Open `docs/planning/blueprint.html` in a browser. Navigate to the relevant screen wireframe. Note:
- Layout structure (header, body, footer zones)
- Interactive elements (buttons, dialogs, swipe areas)
- Data displayed (which fields, formatting)
- Navigation flow (where each button leads)

### Step 4: Create Files Per rules.md

Consult [.claude/rules.md](../../.claude/rules.md) Section 3 (Placement Rules — Decision Tree) to determine exactly where each file goes. Create the directory structure for the feature if it doesn't exist.

### Step 5: Implement Domain → Data → Presentation

Build from the inside out:

1. **Domain layer** — Entities and repository interfaces. Pure Dart, no dependencies.
2. **Data layer** — Models (Freezed), datasources (Drift/Dio), repository implementations.
3. **Presentation layer** — Notifiers (Riverpod), pages, widgets.
4. **Providers** — Wire everything together in `providers.dart`.

This order ensures each layer's dependencies exist before it's built.

### Step 6: Test + Screenshot Verify

- Write tests for each layer (see Testing Approach below).
- For UI: take a screenshot and visually compare against the blueprint wireframe.
- If the screenshot doesn't match, fix and retest in a loop until it does.

### Step 7: Update CONTINUE_PROMPT.md

Before ending the session, update [CONTINUE_PROMPT.md](../CONTINUE_PROMPT.md) with:
- What was completed
- What's next
- Any blockers or decisions pending
- Updated file tree if new directories were created

---

## Offline-First Pattern

All data writes follow the offline-first pattern. See [DATABASE.md](../planning/DATABASE.md) for the sync table schema.

### Write Path

```
User action (e.g., record delivery)
    ↓
Write to Drift/SQLite (synced = false)
    ↓
UI updates immediately from local DB
    ↓
Sync engine checks connectivity
    ├── Online → Push to server via REST/WebSocket
    │             ↓
    │         Server responds with confirmation + server ID
    │             ↓
    │         Update local record (synced = true, server_id mapped)
    │
    └── Offline → Queue in sync_queue table
                    ↓
                When connectivity returns → process queue FIFO
```

### Read Path

```
UI requests data
    ↓
Always read from local Drift DB
    ↓
Background sync pulls latest from server when online
    ↓
Local DB updated → UI rebuilds via Riverpod watch
```

### Conflict Resolution

- **Last-write-wins** with `updated_at` timestamp comparison.
- Server is the authority for conflicts — server version overwrites local on sync.
- Deliveries are append-only during a match (no concurrent editing of same delivery).

---

## Riverpod State Management Pattern

### One Notifier + One Freezed State Per Concern

Each major feature concern gets exactly one `Notifier` paired with one `@freezed` state class. Split only when a notifier exceeds ~200 lines or manages genuinely independent state.

### ScoringState Example Shape

```dart
@freezed
class ScoringState with _$ScoringState {
  const factory ScoringState({
    required String matchId,
    required String inningsId,
    required int totalRuns,
    required int wickets,
    required int overs,
    required int ballsInCurrentOver,
    required String strikerId,
    required String nonStrikerId,
    required String currentBowlerId,
    required List<Delivery> currentOverDeliveries,
    required bool isLoading,
    required bool isFreeHit,
    String? error,
    Delivery? lastDelivery,
  }) = _ScoringState;
}
```

### AsyncNotifier vs Notifier

| Use | When |
|-----|------|
| `AsyncNotifier` | Fetching data from datasources (initial load, refreshing) |
| `Notifier` | Synchronous state transitions (scoring, UI state toggles) |

### Provider Declarations

All providers for a feature go in `features/<feature>/providers.dart`. Do not scatter provider declarations across files.

```dart
// features/scoring/providers.dart
final scoringNotifierProvider =
    NotifierProvider<ScoringNotifier, ScoringState>(ScoringNotifier.new);

final matchSetupNotifierProvider =
    NotifierProvider<MatchSetupNotifier, MatchSetupState>(MatchSetupNotifier.new);
```

---

## Testing Approach Per Layer

### Domain Layer — Pure Unit Tests

Test entities and business logic functions in isolation. No mocks needed — domain has no external dependencies.

```dart
test('odd runs should rotate strike', () {
  expect(shouldRotateStrike(runs: 1, isOverComplete: false), true);
  expect(shouldRotateStrike(runs: 3, isOverComplete: false), true);
  expect(shouldRotateStrike(runs: 2, isOverComplete: false), false);
});
```

### Data Layer — Mock Datasources

Test repositories with mocked datasources. Verify correct mapping between models and entities.

### Presentation Layer — Widget + Notifier Tests

- **Notifier tests:** Create notifier with mock repository, call methods, assert state transitions.
- **Widget tests:** Pump widget with `ProviderScope` overrides, tap buttons, verify UI updates.

### Scoring Engine — Exhaustive Tests

The scoring engine requires the most comprehensive tests. Cover:

- Every delivery type: dot ball, 1-6 runs, wide, no-ball, bye, leg-bye
- All 12 dismissal types with correct stat attribution
- Strike rotation: odd runs, even runs, end of over, after wicket
- Over completion: 6 legal deliveries (wides/no-balls don't count)
- Innings completion: all out, overs exhausted, target chased, declaration
- Undo: every delivery type reversal, stat rollback, strike un-rotation
- Free hit: triggered after no-ball, only run-out dismissal allowed
- Maiden detection: 0 runs from bat (byes don't break maiden)
- Edge cases: last ball of over is wide, wicket on free hit, 5-run penalty

### Integration Tests — Full Match Flow

Test a complete match scenario: setup → toss → score an over → change bowler → take a wicket → complete innings → score second innings → match result.

---

## WebSocket Pattern

See [API.md](../planning/API.md) Section 2 for the full WebSocket protocol.

### Server Side (Bun)

```
Bun native WebSocket server
    ↓
Match rooms via server.publish(topic, message)
    ↓
Scorer connects → authenticated via Firebase JWT → joins room as publisher
Viewers connect → join room as subscribers
    ↓
On delivery processed:
    server.publish(`match:${matchId}`, JSON.stringify({
        type: 'delivery',
        data: { ... }
    }))
```

### Client Side (Flutter)

```
WebSocket provider (Riverpod)
    ↓
Connect on match join → web_socket_channel package
    ↓
Auto-reconnect with exponential backoff on disconnect
    ↓
Parse JSON messages → route by 'type' field
    ↓
Update local state via Riverpod notifiers
```

### Message Format

All WebSocket messages use this shape:

```json
{
  "type": "delivery" | "wicket" | "over_complete" | "innings_complete" | "match_complete",
  "data": { ... },
  "timestamp": "ISO-8601"
}
```

---

## Code Generation Workflow

### When to Run build_runner

Run `dart run build_runner build --delete-conflicting-outputs` after modifying:

- `@freezed` classes (generates `*.freezed.dart`)
- Drift table definitions (generates `*.g.dart`)
- `@riverpod` annotations (generates `*.g.dart`)
- `@JsonSerializable` models (generates `*.g.dart`)
- go_router typed routes (generates `*.gr.dart`)

### Never Edit Generated Files

Files matching `*.g.dart`, `*.freezed.dart`, `*.gr.dart` are auto-generated. If the generated output is wrong, fix the source file and re-run build_runner.

### Drizzle Migrations (Server)

```bash
# After modifying any file in apps/server/src/db/schema/
bunx drizzle-kit generate    # Creates migration SQL files
bunx drizzle-kit migrate     # Applies migrations to PostgreSQL
```

---

## Performance (Low-End Android)

Target: smooth performance on 2GB RAM budget Android devices.

### Riverpod: Use select() for Granular Rebuilds

```dart
// Only rebuild when totalRuns changes, not on every state update
final runs = ref.watch(scoringNotifierProvider.select((s) => s.totalRuns));
```

### Lists: Always Use ListView.builder

Never use `ListView(children: [...])` for lists with more than ~10 items. Always use `ListView.builder` for lazy construction.

### Images: Compress Below 100KB

All user-uploaded images (profile photos, team logos) should be compressed to < 100KB before storage.

### Database: Use Indexes from DATABASE.md

All queries in hot paths (scoring, stats reads) must use indexed columns. See [DATABASE.md](../planning/DATABASE.md) for the full index list.

### Pagination

Paginate all list screens (match history, team players, search results) with 20 items per page. Use cursor-based pagination with `created_at` + `id` as the cursor.
