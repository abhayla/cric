# Dev/Local E2E Testing Strategy

Fast, frequent end-to-end testing against a local server for daily development.

## Goals

- **Fast feedback:** Full critical-path E2E in under 2 minutes
- **Reproducible:** Fixed random seeds, clean DB state per run
- **Independent:** Tests can run in any order or in parallel
- **CI-ready:** Runs headlessly on emulator without manual setup

## Architecture

```
Developer Machine
├── Local Bun Server (port 3001, test DB)
├── Android Emulator (emulator-5554)
└── Flutter integration tests (--flavor dev)
```

- Local server with `NODE_ENV=test` and `ENABLE_TEST_AUTH=true`
- Separate test database (`cricapp_dev` or dedicated `cricapp_e2e_test`)
- `reset-match-data` endpoint clears state between test files
- No network hops (Cloudflare/Nginx bypassed) — ~5ms vs ~1s per API call

## Test Data Strategy

### API-Seeded Data (Not UI-Driven)

Team/player creation is infrastructure, not the feature under test. Seed via direct API calls:

```dart
// Instead of UI taps (tap "Create Team" → type name → add 11 players one-by-one):
Future<void> seedTeamsViaApi(List<TestTeam> teams) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3001/api/v1'));
  // Authenticate as test user
  dio.options.headers['Authorization'] = 'Bearer $testToken';
  for (final team in teams) {
    await dio.post('/teams', data: {'name': team.name, 'location': 'Test'});
    for (final player in team.players) {
      // Create user + add to roster via API
      await dio.post('/teams/$teamId/roster', data: {...});
    }
  }
}
```

**Benefit:** 12 teams × 11 players in ~5 seconds (vs ~5 minutes via UI).

Reserve UI-driven creation only for tests that specifically validate the create-team or add-player UI flow.

### Fixed Random Seeds

All random scoring must use deterministic seeds:

```dart
// GOOD — reproducible
final rng = Random(42);

// BAD — different every run
final rng = Random();
```

Tournament name generation should also be deterministic or sequential (not `Random().nextInt(99999)`).

### Clean State Per Run

Before each test file:
1. Call `POST /api/v1/test/reset-match-data` to clear matches/tournaments
2. Teams and players persist across runs (idempotent creation)
3. Each test file is self-contained — creates its own teams if needed

## Test Suite Structure

### Tier 1: Smoke Test (~2 min) — Run on Every Change

Single test file that validates the critical path:

```
smoke_test.dart
├── Seed 2 teams × 3 players via API
├── Create match (UI) — match setup wizard
├── Complete toss (UI)
├── Score 1 over per innings (6 legal deliveries each)
├── Complete match
├── Verify scorecard shows correct totals
└── Verify match appears in My Cricket → Matches tab
```

**Run command:**
```bash
cd apps/mobile && flutter test --flavor dev \
  integration_test/tests/smoke_test.dart -d emulator-5554
```

### Tier 2: Feature Tests (~5-10 min each) — Run Before Push

Independent tests, each seeds its own data:

| Test | What it validates | Teams needed |
|------|-------------------|--------------|
| `match_scoring_test.dart` | Full match with undo, extras, wickets, target chase | 2 × 6 players |
| `tournament_gk_test.dart` | Group+Knockout tournament lifecycle | 4 × 6 players |
| `tournament_ko_test.dart` | Knockout tournament lifecycle | 4 × 6 players |
| `tournament_rr_test.dart` | Round Robin tournament lifecycle | 4 × 6 players |
| `player_profile_test.dart` | Profile page, format chips, stats | Existing from match test |
| `team_management_test.dart` | Create team, add/remove players via UI | Created inline |

**Key change from current:** Each test creates its own teams (via API), so they don't depend on test 01 or each other.

### Tier 3: Full Suite (~20-30 min) — Pre-Release

Runs all Tier 2 tests plus:
- Screen verification sweep (all tabs, detail pages)
- Edge cases (maiden over, all-out, declaration)
- Multiple match formats (T20, ODI, Custom overs)

## Test File Structure

Split giant `testWidgets` into multiple focused tests per file:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Seed data via API once for all tests in this file
    await seedTeamsViaApi([team1, team2]);
    await resetMatchData();
  });

  testWidgets('Match setup wizard creates match correctly', (tester) async {
    await pumpAppAndWaitForHome(tester);
    await navigateToMatchSetup(tester);
    // ... setup assertions
  });

  testWidgets('First innings scoring with undo', (tester) async {
    await pumpAppAndWaitForHome(tester);
    // ... resume match, score, undo, verify
  });

  testWidgets('Second innings target chase completes match', (tester) async {
    await pumpAppAndWaitForHome(tester);
    // ... score 2nd innings, verify completion
  });
}
```

**Benefit:** Granular pass/fail. If "undo" fails, you see exactly that — not "standalone match test failed."

## Verification (Inline, Not Separate)

Fold verification steps into the test that creates the data:

```dart
// After scoring a match, immediately verify:
testWidgets('Match completes and scorecard is correct', (tester) async {
  // ... score match ...

  // Verify inline — no separate test 03/07 needed
  await navigateToMyCricket(tester);
  await verifyMatchesTab(tester, minCount: 1);
  await verifyTeamsTab(tester, expectedTeams: ['TestTeam1', 'TestTeam2']);
});
```

## Screenshot on Failure

Capture visual state when assertions fail:

```dart
try {
  expect(find.text('Match Complete'), findsOneWidget);
} catch (e) {
  await IntegrationTestWidgetsFlutterBinding.instance
      .takeScreenshot('failure_match_complete');
  rethrow;
}
```

## Parallel Execution (Future)

Once tests are independent, run on multiple emulators:

```bash
# Launch 3 emulators, run independent tests simultaneously
flutter test integration_test/tests/match_scoring_test.dart -d emulator-5554 &
flutter test integration_test/tests/tournament_gk_test.dart -d emulator-5556 &
flutter test integration_test/tests/tournament_ko_test.dart -d emulator-5558 &
wait
```

Requires each emulator to have its own local server port or shared server with isolated test users.

## Local Server Setup

```bash
# Terminal 1: Start local test server
cd apps/server
NODE_ENV=test ENABLE_TEST_AUTH=true PORT=3001 bun run src/index.ts

# Terminal 2: Run E2E tests (emulator uses 10.0.2.2 to reach host)
cd apps/mobile
flutter test --flavor dev \
  integration_test/tests/smoke_test.dart -d emulator-5554
```

The emulator accesses the local server at `10.0.2.2:3001` (Android's host loopback alias). No `--dart-define` overrides needed if `AppConstants` already handles dev flavor URLs.

## Migration Path from Current Strategy

| Step | Change | Effort |
|------|--------|--------|
| 1 | Add `seedTeamsViaApi()` helper using test auth | Small |
| 2 | Create `smoke_test.dart` (Tier 1) | Small |
| 3 | Add fixed `Random(42)` seeds to tournament tests | Trivial |
| 4 | Make each tournament test seed its own teams | Medium |
| 5 | Split test 02 into multiple `testWidgets` | Medium |
| 6 | Merge test 03 into test 02, test 07 into relevant tests | Small |
| 7 | Add screenshot-on-failure wrapper | Small |
| 8 | Configure dev flavor to point to `10.0.2.2:3001` | Small |
