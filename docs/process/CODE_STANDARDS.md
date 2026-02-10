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

### Overs Decimal Notation

Cricket overs use a special decimal notation: `12.3` means **12 overs and 3 balls** (not 12.3 mathematically). The `.N` part is always 0–5 (since 6 legal balls = 1 complete over).

Provide a utility function on both platforms:

```dart
// Dart: convert (overs: int, balls: int) → double display
double oversToDecimal(int overs, int balls) => overs + (balls / 10.0);
// 12 overs, 3 balls → 12.3

// Dart: convert decimal display → (overs, balls)
(int overs, int balls) decimalToOvers(double value) =>
    (value.truncate(), ((value * 10) % 10).round());
// 12.3 → (12, 3)
```

```typescript
// TypeScript: same utility
function oversToDecimal(overs: number, balls: number): number {
  return overs + balls / 10;
}
```

**Important:** Never do arithmetic on overs-decimal values. Convert to total balls first (`overs * 6 + balls`), do the math, then convert back.

### `total_runs` Computation

`deliveries.total_runs` is computed **at application level** during the delivery processing pipeline (Step 2 in SCORING_RULES.md):

```
total_runs = runs_from_bat + wide_runs + no_ball_runs + bye_runs + leg_bye_runs
```

This is NOT a database trigger or generated column — it is calculated in the scoring service/notifier before persisting. The value is stored as a regular column for fast reads.

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
| Master/seed data | `serial` (auto-increment integer) | `ball_types`, `dismissal_types`, `fielding_positions`, `wagon_wheel_zones` |

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
| Client → Server | `join_match`, `leave_match` |
| Server → Client | `match_state`, `score_update`, `wicket`, `innings_complete`, `match_complete`, `delivery_undone`, `error` |

> Scoring mutations (`delivery`, `undo_delivery`) go through REST, not WebSocket. WebSocket is broadcast-only. Server sends `match_state` snapshot on join/rejoin.

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

## 10. UI Design Tokens & Patterns

### Theme

| Token | Value | Notes |
|-------|-------|-------|
| M3 seed color | `#2E7D32` (Green 800) | Cricket green. All M3 tonal surfaces derive from this. |
| Color scheme | `ColorScheme.fromSeed(seedColor: Color(0xFF2E7D32), brightness: Brightness.dark)` | Dark theme only for MVP. |
| Font family | Roboto | Android system font. No `google_fonts` download needed. Use M3 default `TextTheme`. |
| Icon set | Material Symbols | Variable weight/fill. Built into Flutter via `Icons.*`. |
| Orientation | Portrait only | Lock via `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` in `main()`. |

### Scoring Semantic Colors (M3 Dark)

| Element | Color | Implementation |
|---------|-------|----------------|
| Dot ball (0) | Gray | `colorScheme.surfaceVariant` |
| Runs (1-3) | Default surface | `colorScheme.surface` with `colorScheme.outline` border |
| Four | Blue 800 | `Color(0xFF1565C0)` |
| Six | Purple 800 | `Color(0xFF6A1B9A)` |
| Wicket | Red 800 | `Color(0xFFC62828)` |
| Wide / No-ball | Orange 800 | `Color(0xFFE65100)` |
| Bye / Leg-bye | Gray dashed | `colorScheme.surfaceVariant` with dashed border |
| Free hit badge | Orange pill | `Color(0xFFE65100)` background, white text |
| Live badge | Red | `Color(0xFFEF4444)` with pulse animation |

These colors provide good contrast on dark backgrounds. Use them consistently across the scoring page, current over display, and commentary tab.

### Spacing System (8dp Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `spacingXs` | 4dp | Inline element gaps, icon-to-text |
| `spacingS` | 8dp | Between related elements in a group |
| `spacingM` | 16dp | Page margins, section gaps, card padding |
| `spacingL` | 24dp | Between major sections |
| `spacingXl` | 32dp | Page top/bottom padding |
| Touch target | 48x48dp minimum | Per PDR NFR. See Scoring Button Sizes below for specifics. |

### Scoring Button Sizes (Tiered)

| Button Type | Size | Shape | Notes |
|-------------|------|-------|-------|
| Run buttons (0, 1, 2, 3, 4, 6) | 56x56dp | Circular | Primary scoring actions |
| Extras buttons (Wide, No Ball, Bye, Leg Bye) | 48x40dp | Rounded rectangle | Secondary actions |
| Wicket button | 56x56dp | Circular | Red/error color — critical action |
| "More..." button | 48x48dp | Circular with "..." label | Opens custom run number picker dialog (0-12) for overthrow scenarios (5, 7, etc.) |
| Action bar buttons (Undo, Set) | 40x40dp | Circular | Smaller utility actions |
| Strike swap button | 40x40dp | Circular with swap icon | Between batter cards. Taps swaps striker/non-striker. UI-only operation (no delivery record), just updates ScoringState. Essential for correcting mistakes. |

### Scorer vs Viewer Mode (Q20)

The scoring page has two modes determined by whether the current user is the match's scorer:

| Aspect | Scorer Mode | Viewer Mode |
|--------|------------|-------------|
| Run buttons (0-4, 6, More...) | Visible, tappable | **Hidden** |
| Extras buttons (Wide, NB, Bye, LB) | Visible, tappable | **Hidden** |
| Wicket button | Visible, tappable | **Hidden** |
| Undo button | Visible, tappable | **Hidden** |
| Set button (menu) | Visible, tappable | **Hidden** |
| Strike swap button | Visible, tappable | **Hidden** |
| Score header | Visible | Visible |
| Batter cards | Visible (striker highlighted) | Visible (striker highlighted) |
| Bowler card | Visible | Visible |
| Current over display | Visible | Visible |
| Recent deliveries | Visible | Visible |
| Access method | Scorer opens match from "Score Match" | Viewer opens match via "Watch Live" button → connects WebSocket → read-only scoring page |
| Data source | Local Drift DB + sync | WebSocket broadcast only |

### Connectivity Status Indicator

- **Position:** Score header, top-right corner
- **Size:** 8dp diameter dot
- **Colors:** Green = connected, Yellow = reconnecting, Red = disconnected
- **Behavior:** Updates in real-time based on WebSocket connection state. No text label — dot only.

### Typography Scale

Use M3 default `TextTheme` with Roboto. No custom sizes needed — M3 provides:

| Style | Usage |
|-------|-------|
| `headlineLarge` | Match score (87/3) |
| `headlineMedium` | Page titles |
| `titleMedium` | Card headers (player names, team names) |
| `bodyLarge` | Primary content text |
| `bodyMedium` | Secondary content, descriptions |
| `labelLarge` | Buttons, tabs |
| `labelSmall` | Captions, stat labels ("R", "B", "4s", "6s", "SR") |

### Dark Theme Interpretation (Q24)

All 24 UI prototypes use a light blue theme. The app uses Material 3 Dark theme exclusively. When implementing, apply these interpretation rules:

| Prototype Element | Dark Theme Equivalent |
|-------------------|----------------------|
| White backgrounds | `colorScheme.surface` (dark) |
| Light gray cards | `colorScheme.surfaceContainer` |
| Blue primary buttons | `colorScheme.primary` (green-tinted from seed #2E7D32) |
| Blue text links | `colorScheme.primary` |
| Dark text on light | `colorScheme.onSurface` (light text on dark) |
| Gray secondary text | `colorScheme.onSurfaceVariant` |
| Light borders | `colorScheme.outlineVariant` |
| Blue header bars | `colorScheme.surfaceContainerHigh` |
| White input fields | `colorScheme.surfaceContainerHighest` with `outlineVariant` border |

The layout, spacing, and structure from prototypes remain identical — only colors invert to dark theme. Screenshots will be generated for review after Phase 1 setup.

### Surface Hierarchy (M3 Dark)

Use M3's built-in surface tones. No custom surface colors.

| Surface | Usage |
|---------|-------|
| `surface` | Page backgrounds |
| `surfaceContainer` | Cards, dialogs |
| `surfaceContainerHigh` | Elevated cards (scoring page header, player cards) |
| `surfaceContainerHighest` | Top-level containers, bottom sheets |
| `primaryContainer` | Active/selected states (current batter highlight) |

### State Patterns

| State | Pattern |
|-------|---------|
| **Loading** | Centered `CircularProgressIndicator` with optional text below ("Loading matches...") |
| **Empty** | Centered icon + descriptive text + CTA button (see Empty State Content table below) |
| **Error** | Centered error icon + message + "Retry" button. Never show raw exceptions to users. |
| **Pull-to-refresh** | `RefreshIndicator` on all list screens (match list, team list, player list). Triggers sync pull. |

### Transitions & Animations

Use M3 default page transitions only. No custom animations for MVP:
- **Root navigation:** Fade through (`FadeThroughTransition`)
- **Drill-down:** Shared axis (`SharedAxisTransition`)
- **Dialogs/sheets:** M3 default slide-up + fade

### Empty State Content (Per Screen)

| Screen | Icon | Message | CTA Button |
|--------|------|---------|------------|
| Home (no matches) | `Icons.sports_cricket` | "No matches yet" | "Start a Match" |
| Home (no tournaments) | `Icons.emoji_events` | "No tournaments" | "Create Tournament" |
| Teams List | `Icons.groups` | "No teams yet" | "Create a Team" |
| Match History | `Icons.scoreboard` | "No matches found" | "Start a Match" |
| Team Detail (Matches) | `Icons.scoreboard` | "No matches played yet" | — |
| Team Detail (Players) | `Icons.person_add` | "No players yet" | "Add Player" |
| Tournaments List | `Icons.emoji_events` | "No tournaments yet" | "Create Tournament" |
| Tournament Fixtures | `Icons.calendar_today` | "No fixtures generated" | "Generate Fixtures" |
| Scorecard Commentary | `Icons.chat_bubble_outline` | "No commentary available" | — |
| Leaderboard | `Icons.leaderboard` | "No stats yet" | — |

### Match Complete Modal (G18)

Triggered when match result is determined (2nd innings complete, target chased, or all out):

- **Type:** Modal dialog (not a separate screen)
- **Content:** "Match Complete!" header, result text (e.g., "Mumbai Warriors won by 15 runs"), final scores of both teams
- **Buttons:** "View Scorecard" (primary), "Back to Home" (secondary)
- **Tied knockout:** Show "Match Tied! Super Over Required" with "Start Super Over" button instead
- **Layout:** Reuse the Innings Transition modal layout with different content

### Playing XI Selection (G19)

Embedded in toss flow as Step 2.5 (after toss decision, before opener selection):

1. **Step 2.5a:** "Select Playing XI for {Team A}" — show roster, checkbox list (player name + role)
2. **Step 2.5b:** "Select Playing XI for {Team B}" — same flow
3. Pre-select all if roster size equals `players_per_side`
4. Validate: exactly `players_per_side` selected before proceeding
5. Creates `match_players` records for both teams

### Second Innings Opener Selection (G20)

Added to the Innings Transition modal after first innings summary + target display:

1. "Select Opening Batsmen" — 2 from now-batting team's Playing XI
2. "Select Opening Bowler" — 1 from now-bowling team's Playing XI
3. Same UI pattern as toss Step 3 (player list with checkboxes/radio)
4. On "Start 2nd Innings" → creates batting order and proceeds

### Commentary Auto-Generation (G21)

Template-based, generated on-the-fly from delivery data (no new DB column — YAGNI):

| Outcome | Template |
|---------|----------|
| Dot ball | `"{bowler} to {batter}, no run"` |
| Runs | `"{bowler} to {batter}, {runs} run(s)"` |
| Four | `"FOUR! {bowler} to {batter}, boundary"` |
| Six | `"SIX! {bowler} to {batter}, maximum!"` |
| Wide | `"{bowler} to {batter}, wide, {runs} run(s)"` |
| No-ball | `"{bowler} to {batter}, no-ball, {runs} run(s)"` |
| Wicket | `"OUT! {batter} {dismissal_type} {fielder_text} b {bowler}"` |

Generated at display time from delivery record fields. No `commentary_text` column needed.

### Missing Screens Scope (G22)

| Screen | Approach | Phase |
|--------|----------|-------|
| Edit Profile | Reuse Profile Setup form (screen 04), pre-filled with current data | MVP |
| Edit Team | Reuse Create Team form (screen 07), pre-filled | MVP |
| Settings | Inline section at bottom of Player Profile (screen 17) — logout + app version | MVP |
| Search Results | Deferred — use simple local filtering on list screens | Post-MVP |
| Advanced Filters | Deferred — use chip-based filtering in Match History prototype | Post-MVP |
| Edit Tournament | Deferred | Post-MVP |

### Wagon Wheel Player Selector (G25)

- **Position:** Dropdown above the wagon wheel chart
- **Default:** Top run-scorer in the selected innings
- **Options:** All batters who batted in the innings, sorted by batting order
- **Format:** Player name + runs scored (e.g., "R. Sharma — 65")
- **On change:** Re-render wagon wheel with selected player's shot data
- **Query:** Filter `deliveries` by `striker_id` + `innings_id` where `runs_from_bat > 0`

### Bottom Navigation (5 Tabs)

| Tab | Icon | Label | Destination |
|-----|------|-------|-------------|
| 1 | `Icons.home` | Home | Home dashboard (recent matches, quick actions, my stats) |
| 2 | `Icons.sports_cricket` | Matches | Match history list (all/won/lost/tied filters) |
| 3 | `Icons.emoji_events` | Tournaments | Tournament list (my tournaments, public tournaments) |
| 4 | `Icons.groups` | Teams | Teams list (my teams) |
| 5 | `Icons.person` | Profile | Player profile with stats and settings |

> Blueprint shows 3 tabs (Home, Teams, Profile) — outdated. Prototypes show 4 tabs — expanded to 5 with a dedicated Tournaments tab for quick access to tournament management.

### App Bar Pattern

- Standard `AppBar` for most screens (back button auto-provided by `GoRouter`).
- Scoring page: No app bar — full-screen immersive layout. Status bar visible.
- Use `AppBar.actions` for page-specific actions (filter, search, settings).

### Snackbar/Toast Patterns

| Scenario | Feedback Type |
|----------|--------------|
| Network error (transient) | `SnackBar` with retry action, 4 second duration |
| Sync success | Animated cloud icon in app bar, no text (≤10 items). Progress text for >10 items. |
| Form validation error | Inline text below field (red, `bodySmall`) |
| Destructive action success | `SnackBar`: "Match abandoned" / "Team deleted" |
| Critical failure | Full-screen error with retry button |

### Add Player Dialog (Q21)

When a captain adds a player to their team roster, the dialog offers two options:

1. **"Search by phone number"** — Finds an existing CricApp user by phone number. If found, sends a join invite (player appears in roster immediately for MVP — invitation system deferred to post-MVP).
2. **"Create new player"** — Captain enters name + phone number. Creates a placeholder user profile that the player can later claim by signing up with that phone number.

**Dialog layout:**
- Toggle at top: "Search Existing" | "Create New"
- Search mode: Phone number input → search button → result card → "Add to Team" button
- Create mode: Name input + Phone number input + Role selector → "Create & Add" button
- On success: player appears in roster list immediately

### Team Logo

- Upload: Simple file picker (`image_picker`), no cropping. Accept JPEG/PNG only.
- Max size: 100KB (compress if needed).
- Display: 48dp circle (`CircleAvatar`).
- Fallback: First letter of team name on `primaryContainer` background.
- Storage: Upload to server, store URL in `teams.logo_url`.

### User Avatar

- MVP: Initials only (first letter of display name). No photo upload.
- Display: `CircleAvatar` with initials on `primaryContainer` background.
- Post-MVP: Add camera/gallery picker for profile photos.

### Settings Screen

- No dedicated Settings page for MVP. Minimal settings live inside the Profile screen:
  - **Logout** button
  - **App version** display
- Post-MVP: Add theme, notification preferences, account deletion.

### Auth Screen

- **Phone OTP only** for MVP. No Google Sign-In, no Email/Password.
- Single login screen: Phone number input → "Send OTP" button → OTP verification page.
- New users go through profile setup (US-13) after first sign-in.

### Home Dashboard

- Shows after login. Content:
  - **Recent matches** list (last 5, sorted by date). Each card shows: opponent team, score summary, match status badge (Live/Completed/Abandoned), date.
  - **Quick actions** row: "Start Match" (primary CTA), "Create Team", "Join Team".
  - **My Stats** summary card: Total matches, runs, wickets, catches.
- Empty state: Cricket bat icon + "No matches yet" + "Start a Match" button.

### Local Preferences Keys

Standard keys for the `local_preferences` SQLite table (key-value store):

| Key | Value Type | Description |
|-----|-----------|-------------|
| `last_sync_timestamp` | ISO 8601 string | When the last successful sync completed |
| `current_match_id` | UUID string | Active match being scored (null if none) |
| `user_id` | UUID string | Current logged-in user's ID |
| `last_viewed_team_id` | UUID string | Last team the user viewed (for quick resume) |
| `app_version_seen` | Semver string | Last app version user saw (for what's-new prompts) |

---

## 11. Testing Standards

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

## 12. Logging Standards

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

## 13. Import Ordering

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

## 14. Code Formatting & Linting

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

## 15. Dependencies & Tooling

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
