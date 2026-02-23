# Implementation Practices

## Table of Contents

1. [Feature Implementation Workflow](#1-feature-implementation-workflow)
2. [Offline-First Pattern](#2-offline-first-pattern)
3. [Riverpod State Management Pattern](#3-riverpod-state-management-pattern)
4. [Navigation/Routing Patterns](#4-navigationrouting-patterns)
5. [Error Handling & Network Resilience](#5-error-handling--network-resilience)
6. [Security: Token Storage & Auth](#6-security-token-storage--auth)
7. [WebSocket Pattern](#7-websocket-pattern)
8. [WebSocket Error Handling & Reconnection](#8-websocket-error-handling--reconnection)
9. [Data Validation & Input Sanitization](#9-data-validation--input-sanitization)
10. [Sync Workflow & Background Tasks](#10-sync-workflow--background-tasks)
11. [Sync: Advanced Conflict Resolution](#11-sync-advanced-conflict-resolution)
12. [Database Schema Migrations](#12-database-schema-migrations)
13. [Testing Approach Per Layer](#13-testing-approach-per-layer)
13.5. [TDD — Test-Driven Development Per Layer](#135-tdd--test-driven-development-per-layer)
14. [Code Review Practices for Scoring](#14-code-review-practices-for-scoring)
15. [Logging & Crash Reporting](#15-logging--crash-reporting)
16. [Code Generation Workflow](#16-code-generation-workflow)
17. [Environment Configuration](#17-environment-configuration)
18. [Performance (Low-End Android)](#18-performance-low-end-android)

---

## 1. Feature Implementation Workflow

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
| Any feature/screen | [CRICHEROES_REFERENCE.md](../planning/CRICHEROES_REFERENCE.md) — relevant section for competitive context |

### Step 2.5: Run CricHeroes Comparison

Before designing or building, invoke the `cricheroes-comparator` agent:

> "Compare [feature/screen name] against CricHeroes"

The agent reads `docs/planning/CRICHEROES_REFERENCE.md` and produces a structured comparison report. Act on the results:

| Recommendation | Action |
|---------------|--------|
| **ADOPT** | Incorporate into current implementation. Mention in commit message. |
| **DEFER** | Log in CONTINUE_PROMPT.md under future enhancements. Do not build now. |
| **SKIP** | Ignore — not relevant for CricScores MVP. |

If an ADOPT gap has effort "medium" or "large", confirm with user before proceeding — it may change scope.

> Reference: [CRICHEROES_REFERENCE.md](../planning/CRICHEROES_REFERENCE.md)

### Step 3: Check Blueprint Wireframes

Open `docs/planning/blueprint.html` in a browser. Navigate to the relevant screen wireframe. Note:
- Layout structure (header, body, footer zones)
- Interactive elements (buttons, dialogs, swipe areas)
- Data displayed (which fields, formatting)
- Navigation flow (where each button leads)

> Use research agents (`scoring-researcher`, `database-researcher`, `ui-researcher`, `api-researcher`) to gather deep domain context before implementation. See [CLAUDE_CODE_CONFIG.md](CLAUDE_CODE_CONFIG.md).

### Step 4: Create Files Per rules.md

Consult [.claude/rules.md](../../.claude/rules.md) Section 3 (Placement Rules — Decision Tree) to determine exactly where each file goes. Create the directory structure for the feature if it doesn't exist.

### Step 5: Implement Domain → Data → Presentation

Build from the inside out:

1. **Domain layer** — Entities and repository interfaces. Pure Dart, no dependencies.
2. **Data layer** — Models (Freezed), datasources (Drift/Dio), repository implementations.
3. **Presentation layer** — Notifiers (Riverpod), pages, widgets.
4. **Providers** — Wire everything together in `providers.dart`.

This order ensures each layer's dependencies exist before it's built.

> Follow naming and error handling patterns in [CODE_STANDARDS.md](CODE_STANDARDS.md).
> Adhere to YAGNI/KISS/DRY principles in [CLAUDE.md](../../CLAUDE.md#code-principles-yagni-kiss-dry).

### Step 6: Test + Screenshot Verify

- Write tests for each layer (see [Testing Approach](#13-testing-approach-per-layer) below).
- For UI: take a screenshot and visually compare against the blueprint wireframe.
- If the screenshot doesn't match, fix and retest in a loop until it does.

> If tests fail, follow the debugging workflow in [CODE_FIXES.md](CODE_FIXES.md). For scoring bugs, use the Scoring Engine Fix Protocol in the same doc.

### Step 7: Update CONTINUE_PROMPT.md

Before ending the session, update [CONTINUE_PROMPT.md](../CONTINUE_PROMPT.md) with:
- What was completed
- What's next
- Any blockers or decisions pending
- Updated file tree if new directories were created

---

## 2. Offline-First Pattern

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 8 for the condensed offline-first data pattern table.

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

## 3. Riverpod State Management Pattern

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 6 for AsyncNotifier vs Notifier, Freezed field rules, and provider location rules.

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

## 4. Navigation/Routing Patterns

### Router Configuration

- Single `router.dart` file in `apps/mobile/lib/src/app/` (per rules.md placement).
- Use go_router with code generation for type-safe routes (`*.gr.dart`).
- All route paths defined as constants — no string literals in navigation calls.

### Auth Guard

Redirect unauthenticated users to login and authenticated users away from login via the `redirect` callback on `GoRouter`.

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/home';
    return null;
  },
  routes: [ /* ... */ ],
);
```

### Deep Linking

- Match URLs: `cricscores://match/:matchId` — opens match detail or live scoring view.

### Scoring Flow Navigation

- Linear flow: `MatchSetup → Toss → Scoring → Scorecard`.
- No back-navigation past toss once scoring starts — use `PopScope` with a confirmation dialog ("Abandon match?") if the scorer presses back during live scoring.
- Scoring page must not lose state on back press; wrap with `PopScope` to intercept.

---

## 5. Error Handling & Network Resilience

### Error Wrapping Per Layer

Errors transform as they flow through layers. See [CODE_STANDARDS.md](CODE_STANDARDS.md) for full error handling patterns.

- **Datasources** throw raw exceptions: `DriftDatabaseException`, `DioException`, `FirebaseAuthException`.
- **Repositories** catch and wrap into domain exceptions: `ScoringException`, `SyncException`, `AuthException`.
- **Notifiers** catch domain exceptions and set the `error` field on the Freezed state class.

```dart
// Repository wrapping datasource errors
Future<Delivery> recordDelivery(DeliveryInput input) async {
  try {
    final model = await _localDatasource.insertDelivery(input.toModel());
    return model.toEntity();
  } on DriftDatabaseException catch (e) {
    throw ScoringException('Failed to record delivery: ${e.message}');
  }
}
```

### Network Error Categories

- **Retryable:** Timeout, 5xx server errors, connection reset — retry with backoff.
- **Non-retryable:** 400 (bad request), 401 (unauthorized), 403 (forbidden), 404 (not found) — handle immediately, do not retry.

### Sync Failure Handling

- Track retry count in `sync_queue`. Mark as `FAILED` after **5 attempts** with exponential backoff (5s→10s→30s→60s→60s). Continue processing remaining queue items.

### User-Facing Error Display

- **SnackBar:** Transient errors (network timeout, sync retry).
- **Inline text:** Form validation errors (below the field).
- **Full-screen error + retry:** Critical failures (database corruption, auth failure).
- Never show raw exception messages or stack traces to users.

### Scoring Resilience

Delivery recording MUST succeed locally even if the server is unreachable. Never block the scorer with a network error dialog. Queue for sync and show a subtle offline indicator instead.

**Offline error handling (scoring context):**
- **No dialogs, toasts, or banners** during offline scoring — only log the error and update the connectivity dot indicator (green→yellow→red, 8dp dot in score header top-right).
- Scoring must never be interrupted by network state changes.
- Log sync failures at `w` (warning) level for later debugging.

### App Background/Kill Recovery (E2)

No special handling needed — rely on the offline-first architecture:

| Scenario | Behavior |
|----------|----------|
| **App backgrounded** | WebSocket disconnects. Auto-reconnect on resume (per Section 8). Scoring state preserved in memory. |
| **OS kills app** | Every delivery is persisted to local Drift DB immediately (Step 8 of pipeline). On relaunch, resume from local DB state. |
| **Resume UX** | Brief "Resuming match..." loading state while reading local DB and re-establishing WebSocket. |
| **Data safety** | All scoring data is in SQLite before any UI confirmation. No data loss possible from app kill. |

---

## 6. Security: Token Storage & Auth

### Token Storage

- Use `flutter_secure_storage` (backed by Android Keystore) for JWTs. Never use `SharedPreferences` for tokens.
- Firebase ID tokens expire after ~1 hour. Use `getIdToken(true)` to force refresh when needed.

### Dio Auth Interceptor

Intercept 401 responses, refresh the Firebase token, and retry the request. If refresh fails, trigger logout.

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // Token refresh failed — trigger logout
      }
    }
    handler.next(err);
  }
}
```

### Logout Cleanup

On logout: clear secure storage, disconnect WebSocket, clear Riverpod auth state, navigate to login.

### Server-Side Auth

- Firebase Admin SDK verifies JWT in auth middleware on every REST request.
- WebSocket authentication via JWT query parameter on connection. Ref: [API.md](../planning/API.md) Section 2.1.

---

## 7. WebSocket Pattern

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
    Validate delivery data
    Persist to PostgreSQL
    Broadcast score_update to match subscribers
    (See API.md Section 2.3 for all server→client message types)
```

### Client Side (Flutter)

```
WebSocket provider (Riverpod)
    ↓
Connect on match join → web_socket_channel package
    ↓
Handle disconnects per Section 8 (WebSocket Error Handling & Reconnection) below
    ↓
Parse JSON messages → route by 'type' field
    ↓
Update local state via Riverpod notifiers
```

**Message types and payload shapes:** See [API.md](../planning/API.md) Section 2 for the complete WebSocket protocol — client-to-server messages (Section 2.2) and server-to-client messages (Section 2.3). Do not define message structures inline; use type definitions in `apps/server/src/types/websocket.ts` (server) and mirrored Dart types (client) per CLAUDE.md DRY rules.

---

## 8. WebSocket Error Handling & Reconnection

### Disconnect Detection

- Listen on `web_socket_channel` stream `onDone` for connection close.
- Periodic heartbeat: send ping every 30 seconds, expect pong. No pong within 5 seconds = disconnected.

### Exponential Backoff Reconnection

Delays: 1s → 2s → 4s → 8s → 16s → 30s (cap). After 10 failed attempts, stop auto-reconnect. Show persistent "Connection lost" banner with manual retry button.

```dart
int _reconnectAttempts = 0;
static const int _maxAttempts = 10;
static const int _maxDelaySeconds = 30;

Future<void> _reconnect() async {
  if (_reconnectAttempts >= _maxAttempts) {
    _setConnectionState(ConnectionState.disconnected);
    return;
  }
  _setConnectionState(ConnectionState.reconnecting);
  final delay = min(pow(2, _reconnectAttempts).toInt(), _maxDelaySeconds);
  await Future.delayed(Duration(seconds: delay));
  _reconnectAttempts++;
  await _connect();
}
```

### Scorer vs Viewer on Disconnect

- **Scorer:** Continues scoring offline. Deliveries queue in local SQLite. Sync pushes when reconnected.
- **Viewer:** Shows stale indicator — "Last updated X seconds ago". Live data pauses until reconnected.

### Reconnection Catch-Up

After reconnecting: re-send `join_match`, then fetch current match state via REST `GET /api/v1/matches/:id` to catch up on missed updates.

### Connection State UI

Display in scoring page header:
- Green dot = connected
- Yellow dot = reconnecting
- Red dot = disconnected

---

## 9. Data Validation & Input Sanitization

### Two-Layer Validation

- **Client-side:** For UX — inline form errors, disabled submit buttons until valid. Not a security boundary.
- **Server-side:** For security — never trust client input. Elysia's TypeBox schema validation on route handlers. Keep handlers thin (per CLAUDE.md KISS).

### Parameterized Queries

- **Drizzle:** Use query builder or parameterized SQL. Never concatenate user input into queries.
- **Drift:** Parameterized by default. No raw SQL with string interpolation.

### Cricket-Specific Validations

Defined once per platform in `cricket-rules.ts` (server) / `cricket_utils.dart` (Flutter) per CLAUDE.md DRY rules. Ref: [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 2, Step 1 (VALIDATE).

- **Free hit:** Only `run_out` dismissal allowed.
- **Over limit:** Bowler can't exceed `ceil(totalOvers / 5)` overs.
- **Consecutive over restriction:** Same bowler can't bowl 2 consecutive overs.
- **Valid batter pair:** Striker ≠ non-striker, both active (not dismissed).

```dart
bool isValidFreeHitDismissal(String dismissalCode) {
  // On free hit, only run out is possible
  // Ref: SCORING_RULES.md Section 3.3
  return dismissalCode == 'ro';
}
```

---

## 10. Sync Workflow & Background Tasks

### Sync Triggers

1. **App startup** — process any queued items from previous session.
2. **Connectivity change** — via `connectivity_plus` package, trigger sync when online.
3. **Manual pull-to-refresh** — user-initiated on match list or scorecard.
4. **Periodic timer** — every 60 seconds when app is in foreground and online.

No background sync when app is killed (Android budget device battery limits).

### Batching

- Max 50 deliveries per sync request. Queue > 50 → split into batches.
- Priority order: (1) current match deliveries, (2) completed match data, (3) stats/analytics.

### Failure Handling

- Backoff between retry batches: 5s → 10s → 30s → 60s cap.
- After 5 consecutive failures on a batch, mark those items as `FAILED`. Continue to next batch.
- **Retry count persists across app restarts.** The `retry_count` is stored in the SQLite `sync_queue` table and is NOT reset on app relaunch. This prevents endless retries of permanently broken items (e.g., server schema mismatch, deleted resources).
- **Retry count reset rules:**
  - Reset to 0 on successful sync of that specific entity.
  - Items reaching `retry_count = 5` are marked FAILED (status = 'failed').
  - FAILED items are retried via manual pull-to-refresh (resets count to 0, status back to 'pending').
  - On match completion: one final forced sync attempt for ALL pending/failed items (resets all counts to 0).
  - Never auto-reset on app restart — only explicit success or user-initiated retry resets the count.
- Sync queue schema (local SQLite, ref [DATABASE.md](../planning/DATABASE.md) Section 10): `id`, `entity_type`, `entity_id`, `operation`, `payload`, `retry_count`, `status`, `created_at`.

```dart
Future<void> onConnectivityChanged(bool isOnline) async {
  if (!isOnline) return;
  final queue = await _syncDao.getPendingItems(limit: 50);
  for (final batch in queue.chunked(50)) {
    try {
      final result = await _remoteDatasource.pushBatch(batch);
      await _syncDao.markSynced(result.idMappings);
    } on DioException {
      await _syncDao.incrementRetryCount(batch);
    }
  }
}
```

---

## 11. Sync: Advanced Conflict Resolution

### Conflict Detection

Server checks `updated_at` on sync push. If server timestamp > client timestamp → conflict. Deliveries are append-only → conflicts rare. Match metadata (team name changes, etc.) → possible.

### Sync State Per Entity

States: `NOT_SYNCED` → `SYNCING` → `SYNCED`. On conflict: `SYNCING` → `CONFLICTED`.

UI icons: cloud-off (not synced), cloud-sync (syncing), cloud-done (synced), cloud-alert (conflicted).

### Resolution Strategy

Server is authoritative (per [Offline-First Pattern](#2-offline-first-pattern) above). On conflict, server version overwrites local. Show toast: "Match details updated from server."

### Batch Sync Protocol

`POST /api/v1/sync/push` with array of deliveries. Response includes `idMappings` (local UUID → server UUID). Ref: [API.md](../planning/API.md) Section 1.7.

### Sync Progress UI

- Large batches (> 10): show progress text — "Syncing 42/200 deliveries..."
- Small syncs (≤ 10): animated cloud icon in app bar, no text.

```dart
enum SyncState { notSynced, syncing, synced, conflicted }

SyncState nextState(SyncState current, SyncResponse response) {
  if (response.hasConflicts) return SyncState.conflicted;
  if (response.synced > 0) return SyncState.synced;
  return current;
}
```

---

## 12. Database Schema Migrations

### Drift (SQLite — Local)

Increment `schemaVersion` in `AppDatabase`. Implement `onUpgrade` with `MigrationStrategy`. Each migration uses `addColumn`, `createTable`, etc.

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    if (from < 2) {
      await migrator.addColumn(deliveries, deliveries.isFreeHit);
    }
  },
);
```

### Drizzle (PostgreSQL — Server)

Modify schema files in `apps/server/src/db/schema/`, then:
```bash
bunx drizzle-kit generate    # Creates migration SQL files
bunx drizzle-kit migrate     # Applies migrations to PostgreSQL
```

**Migration strategy (C4):** Development uses manual `bunx drizzle-kit migrate` after schema changes. Production deployment strategy (automated migrations, rollbacks) deferred to Phase 7.

### Backward Compatibility

Old app versions may sync after a server update. Server accepts both old and new schema shapes in `sync.service.ts` — apply defaults for new fields when absent in client payload.

### Migration Testing

- Create database at version N, migrate to N+1, verify data integrity.
- Place migration tests in `test/src/shared/data/database/`.

### Safety Rules

- Never drop columns containing delivery data. Deprecated columns → nullable first. Remove only after confirming all devices have migrated.

---

## 13. Testing Approach Per Layer

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 10 for coverage targets, per-layer testing rules, and the regression test mandate.

Coverage targets from [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) Section 7:

| Type | Target | Focus Areas |
|------|--------|-------------|
| Unit Tests | 60% | Scoring engine, cricket rules, MVP algorithm, sync engine |
| Widget Tests | 30% | Scoring controls, scorecard rendering, wagon wheel, chart data binding |
| Integration Tests | 10% | Full match scoring flow, offline sync, auth flow |

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

> Each delivery type test maps to a step in the 10-step delivery processing pipeline from [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 2.
> Undo tests must verify all 8 undo steps and 3 constraints from [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 4.

### Match State Machine Tests

- Test all 6 states: SETUP, TOSS, LIVE, INNINGS_BREAK, COMPLETED, ABANDONED.
- Test all valid transitions per the state table in [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 1.
- Test invalid transitions are rejected (e.g., SETUP → LIVE without toss).
- Test ABANDONED can be triggered from every state.
- Test tied scores after both innings → COMPLETED with result "Match Tied".

### Integration Tests — Full Match Flow

Test a complete match scenario: setup → toss → score an over → change bowler → take a wicket → complete innings → score second innings → match result.

### Test Failure Escalation

When tests fail repeatedly, follow escalation tiers in [CODE_FIXES.md](CODE_FIXES.md):
- **Normal (1-3 iterations):** Re-read failure, try a different code path.
- **Tier 1 (4-5):** Slow down, challenge assumptions.
- **Tier 2 (6-7):** Widen scope, trace full path.
- **Tier 3 (8-9):** Audit architecture.
- **Hard Cap (10):** Stop and present findings to user.

---

## 13.5. TDD — Test-Driven Development Per Layer

Every feature follows strict Red-Green-Refactor TDD. Tests are written BEFORE implementation for each layer. This catches design issues early and produces tests that verify behavior, not implementation details.

### TDD Cycle Per Layer

| Step | Action | Verify |
|------|--------|--------|
| **RED** | Write test against interface/spec | `flutter test` → all FAIL |
| **GREEN** | Implement minimum code to pass | `flutter test` → all PASS |
| **REFACTOR** | Clean up without breaking tests | `flutter test` → still PASS |

### Domain Layer TDD

Write pure unit tests against entity interfaces and domain logic functions. No mocks needed — domain has no external dependencies.

```dart
// test/src/features/scoring/domain/delivery_test.dart
// Written BEFORE scoring/domain/entities/delivery.dart exists

test('should calculate total runs including extras', () {
  final delivery = Delivery(
    runsFromBat: 4,
    wideRuns: 0,
    noBallRuns: 0,
    byeRuns: 0,
    legByeRuns: 0,
  );
  expect(delivery.totalRuns, 4);
});

test('wide should not be a legal delivery', () {
  final delivery = Delivery(isWide: true, wideRuns: 1);
  expect(delivery.isLegal, false);
});
```

### Data Layer TDD

Mock datasources and test repository contracts. Verify model serialization round-trips.

```dart
// test/src/features/scoring/data/scoring_repository_test.dart
// Written BEFORE scoring/data/repositories/ exists

test('should save delivery to local datasource first', () async {
  when(() => mockLocalDs.insertDelivery(any())).thenAnswer((_) async => model);
  await repo.recordDelivery(input);
  verify(() => mockLocalDs.insertDelivery(any())).called(1);
});

test('should wrap DriftException into ScoringException', () {
  when(() => mockLocalDs.insertDelivery(any())).thenThrow(DriftDatabaseException(''));
  expect(() => repo.recordDelivery(input), throwsA(isA<ScoringException>()));
});
```

### Presentation Layer TDD

Test notifier state transitions with mocked repository, then widget behavior.

```dart
// test/src/features/scoring/presentation/scoring_notifier_test.dart
// Written BEFORE scoring/presentation/notifiers/ exists

test('recordDelivery should update totalRuns', () async {
  when(() => mockRepo.recordDelivery(any())).thenAnswer((_) async => delivery);
  await notifier.recordDelivery(input);
  expect(notifier.state.totalRuns, 4);
});
```

### TDD Exceptions

Skip TDD for:
- **Generated code** — *.g.dart, *.freezed.dart, *.gr.dart (test the source annotations, not output)
- **Static UI with no logic** — splash screen, about page (use `/screenshot-verify` instead)
- **Configuration files** — router setup, theme constants (test via integration tests)
- **Third-party wrappers** — Firebase init, Drift database constructor (test the layer above)

### Reference

Use `/tdd <feature> <layer>` skill for guided TDD workflow. See [PLAYBOOK.md](PLAYBOOK.md) Steps 3-8 for the full 17-step integration.

---

## 14. Code Review Practices for Scoring

### PR Checklist for Scoring Changes

Every PR touching scoring logic must pass this checklist:

```markdown
- [ ] Delivery processing follows all 10 steps of the pipeline? (SCORING_RULES.md Section 2)
- [ ] Strike rotation matches all 7 scenarios? (SCORING_RULES.md Section 3.1)
- [ ] Undo reverses correctly (all 8 steps)? (SCORING_RULES.md Section 4)
- [ ] Stats updated atomically with delivery insert?
- [ ] Free hit flag propagates correctly to next delivery?
- [ ] Tests added/updated for changed behavior?
```

### High-Risk Files Requiring Tests on Any Change

Any modification to these files must include corresponding test updates:

- Flutter: `scoring_notifier.dart`, `cricket_utils.dart`
- Server: `scoring.service.ts`, `cricket-rules.ts`

No "I'll add tests later" for scoring changes.

### Manual Over Trace

Reviewer traces one 6-ball over through the code (dot, single, four, wide, wicket, dot) and verifies: score, strike position, batter/bowler stats, over state, and extras. Ref: [CODE_FIXES.md](CODE_FIXES.md) for the debugging trace technique.

### Tooling

Use the `scoring-researcher` agent for pre-review analysis of scoring changes. Ref: [CLAUDE_CODE_CONFIG.md](CLAUDE_CODE_CONFIG.md).

---

## 15. Logging & Crash Reporting

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 12 for logging conventions, privacy rules, and the `print()` ban.

### Flutter Logging

- Use `package:logger` with one `Logger` instance per class.
- Levels: `d` (debug, dev builds only), `i` (info), `w` (warning, retryable errors), `e` (error + stack trace).

### Crashlytics Setup

Wrap `main()` with `runZonedGuarded` and set `FlutterError.onError` to capture unhandled exceptions. Report scoring pipeline errors as non-fatal exceptions.

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    runApp(const ProviderScope(child: CricScores()));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
```

### Scoring Performance Logging

Log elapsed time per delivery processing cycle (all 10 pipeline steps). Target: < 50ms.

### Privacy

Never log phone numbers, email addresses, or auth tokens. Use UUIDs only in log entries. Mask PII before sending to Crashlytics.

### Server Logging

Structured JSON logging via `logger.ts`. Every entry includes: `matchId`, `event`, `timestamp`. WebSocket messages logged with `type` + `matchId` only (no payload). Ref: [CODE_FIXES.md](CODE_FIXES.md) for server-side debugging patterns.

---

## 16. Code Generation Workflow

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 15 for the code generation trigger table and version pinning rules.

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

## 17. Environment Configuration

### Flutter Environment

Use `--dart-define` at build time: `flutter run --dart-define=ENV=dev`. Access via `String.fromEnvironment('ENV')`. No `.env` files in the Flutter app.

```dart
// core/constants/app_constants.dart
class AppConstants {
  // D1: Default to Android emulator localhost; override via --dart-define for physical device
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}
```

### Firebase Per Environment

**MVP: Single Firebase project** (no staging/production split). The VPS is the only environment. Post-MVP: create separate projects per environment with their own `google-services.json` placed per flavor configuration.

### Package Version Strategy (C6)

- Use `flutter pub add <package>` and `bun add <package>` to get latest stable versions at time of project initialization.
- If Riverpod 3.0 is available, use it; otherwise use latest 2.x with adjusted patterns.
- Document actual installed versions in `pubspec.yaml` / `package.json` (caret ranges via `^`).
- Version ranges in [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) Sections 3-4 are **minimum targets**, not pinned versions.
- No version pinning unless a known-broken minor release is identified.

### Drift Database

Same schema across all environments. No environment-specific database behavior.

### Server Environment

Copy `.env.example` → `.env`. See [IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) Phase 7 for the complete list of 12 environment variables.

---

## 18. Performance (Low-End Android)

> **Quick reference:** See [CODE_STANDARDS.md](CODE_STANDARDS.md) Section 9 for the mandatory performance patterns table.

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

Paginate all list screens (match history, team players, search results) with 20 items per page. Use offset-based pagination with `?page=1&limit=20` query parameters (default 20, max 50).
