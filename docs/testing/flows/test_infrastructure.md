# Test Infrastructure

Server manager setup, app wrapper configuration, and DB verification API for E2E integration tests.

## Components

```
integration_test/
├── tournament_e2e_test.dart          # Main test
└── helpers/
    ├── server_manager.dart           # Bun server lifecycle
    ├── app_test_wrapper.dart         # Flutter app wrapper
    ├── db_verifier.dart              # DB verification client
    ├── data_generators.dart          # Team/player/tournament generators
    ├── match_flow_helpers.dart       # Scoring UI tap helpers
    ├── tournament_flow_helpers.dart  # Tournament UI navigation helpers
    └── delivery_record.dart          # Delivery tracking data classes
```

## Server Manager

`ServerManager` manages the Bun test server lifecycle.

### Configuration
- Port: 3001 (test-specific)
- Environment: `NODE_ENV=test`
- Database: `cricapp_test_e2e`
- Server directory: `../../server` (relative to mobile app)

### Methods

**`startServer()`**
1. Spawns `bun run src/index.ts` via `Process.start()`
2. Sets `NODE_ENV=test` and `PORT=3001`
3. Polls `http://localhost:3001/health` every 500ms
4. Times out after 15 seconds if server doesn't respond

**`stopServer()`**
- Kills the spawned process

**`resetDatabase()`**
- Sends `POST /api/v1/test/reset-db` to truncate all tables
- Re-seeds master data (dismissal types, ball types, etc.)

## App Test Wrapper

`AppTestWrapper` provides `pumpApp(tester)` to boot the full Flutter app in test mode.

### What It Does
1. Wraps `CricApp` in a `ProviderScope`
2. Overrides Dio base URL to `http://localhost:3001`
3. Sets up mock Firebase Auth (returns authenticated user)
4. Debug mode router skips auth screens, routes to `/home`

### Usage
```dart
await AppTestWrapper.pumpApp(tester);
expect(find.text('Home'), findsWidgets);
```

## Test Verification API

Server-side endpoints in `test-verify.routes.ts`, only enabled when `NODE_ENV=test`.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/test/deliveries/:matchId` | All delivery records for a match |
| GET | `/api/v1/test/standings/:tournamentId` | Raw tournament standings |
| GET | `/api/v1/test/match-result/:matchId` | Match result record |
| GET | `/api/v1/test/leaderboard/:tournamentId?category=runs\|wickets` | Leaderboard data |
| POST | `/api/v1/test/reset-db` | Truncate all tables, re-seed master data |

### Security
- All endpoints are guarded: `if (process.env.NODE_ENV !== 'test') return 403`
- Never exposed in production

### Response Shapes

**Deliveries** (`GET /api/v1/test/deliveries/:matchId`):
```json
{
  "deliveries": [
    {
      "id": "uuid",
      "innings_id": "uuid",
      "over_number": 1,
      "ball_number": 1,
      "runs_from_bat": 4,
      "is_wide": false,
      "is_no_ball": false,
      "is_wicket": false,
      "is_boundary": true,
      "total_runs": 4
    }
  ]
}
```

**Standings** (`GET /api/v1/test/standings/:tournamentId`):
```json
{
  "standings": [
    {
      "team_id": "uuid",
      "team_name": "Team1",
      "played": 3,
      "won": 2,
      "lost": 1,
      "tied": 0,
      "points": 4,
      "nrr": 1.250
    }
  ]
}
```

## DB Verifier (Client-Side)

`DbVerifier` calls the test API endpoints via Dio and compares results.

### Methods

**`verifyMatchDeliveries(matchId, expectedDeliveries)`**
- Fetches deliveries from server
- Compares count, then each field (runs, extras, wickets, boundaries)
- Returns `VerificationResult` with passed/failed + diff details

**`verifyMatchResult(matchId)`**
- Fetches match result record
- Checks: result exists, winner correct, result type (win/tie/no result)

**`verifyStandings(tournamentId)`**
- Fetches all standings rows
- Checks: all 16 teams present, played/won/lost/points correct, NRR non-null

**`verifyLeaderboard(tournamentId, {category})`**
- Fetches leaderboard for runs or wickets
- Returns top player name and value

### Usage in Tests
```dart
final dbVerifier = DbVerifier(baseUrl: 'http://localhost:3001');

// After each match:
final result = await dbVerifier.verifyMatchDeliveries(
  matchId,
  matchRecord.allDeliveries,
);
expect(result.passed, true);

// After group stage:
final standings = await dbVerifier.verifyStandings(tournamentId);
expect(standings.passed, true);
```

## Adding New Verification Endpoints

1. Add route in `apps/server/src/routes/v1/test-verify.routes.ts`
2. Guard with `NODE_ENV=test` check
3. Query relevant tables via Drizzle
4. Add corresponding method in `apps/mobile/integration_test/helpers/db_verifier.dart`
5. Add `VerificationResult` parsing for the new response shape

## Data Generators

`TournamentTestData` provides factory methods:

| Method | Output |
|--------|--------|
| `generate16Teams()` | 16 teams, 8 players each (T{n}P{m} naming) |
| `generateTeams(count, {playersPerTeam})` | Configurable team count |
| `mockTour1Config()` | 6-over, 6-player, Group+Knockout, magic over on 4th |
| `defaultGroupAssignments()` | 4 groups x 4 teams |
