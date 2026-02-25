# Prompt: Run Production E2E Tests

Use this prompt to instruct Claude to execute the production E2E test suite.

---

## Critical Rule

**100% UI-driven — zero API calls.** All actions (team creation, player addition, tournament creation, status transitions, team registration, fixture generation, scoring, fixture navigation) go through the app UI — the exact same process any real user would follow. No API shortcuts. No exceptions.

### Tournament UI Flow (per tournament)
Each tournament test performs these steps through the real app UI via helpers in `tournament_mgmt.dart`:
1. Create tournament (form: name, format, overs, ball type, players per side, groups)
2. Open Registration (... menu -> "Open Registration")
3. Add all teams (Teams tab -> "Add Team" -> group chip -> team name, repeated N times)
4. Generate Fixtures (Overview tab -> "Generate Fixtures")
5. Start Tournament (... menu -> "Start Tournament")

### Fixture Scoring (per match)
`scoreAllFixtures()` in `tournament_flow.dart` scans FixtureCard widgets on the Fixtures tab to find unplayed matches:
1. Switch to Fixtures tab, scan for unplayed FixtureCard
2. Tap the fixture card -> match setup -> toss wizard -> score both innings
3. Dismiss match complete modal -> navigate back to tournament detail
4. Repeat until no unplayed fixtures remain
5. Assert zero unplayed fixtures at completion

### Error Tracking
- `ErrorTracker` class logs every success/error with step description
- On first error: test stops immediately, prints where it stopped
- Resume support: `startFromTeam` / `startFromMatch` params to skip completed work
- `tracker.printSummary()` at end shows full progress report

## Pre-requisites

Before running, verify:
1. Android emulator is running (`flutter devices` should show emulator)
2. Prod server is live at cricscores.in
3. Prod debug APK is built: `cd apps/mobile && flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod`

## Execution Steps

### Step 1: Team Setup (one-time, ~20 min)

Run the team setup test to create 16 teams with 6 players each via UI:

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/01_team_setup_test.dart -d emulator-5554
```

Wait for completion. Verify output shows all 16 teams created with 6 players each.

### Step 2: Run Core Tests (~30 min)

```bash
# Standalone match: undo, target chase, persistence
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/02_standalone_match_test.dart -d emulator-5554

# Verify match data on screens
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/03_verify_after_match_test.dart -d emulator-5554
```

### Step 3: Run Tournaments (~5-6 hours total)

```bash
# Tournament 1: Group+Knockout, 4 groups × 4 teams (~27 matches, ~2-3hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/04_tournament_gk_test.dart -d emulator-5554

# Tournament 2: Knockout, 16 teams single elimination (15 matches, ~1hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/05_tournament_ko_test.dart -d emulator-5554

# Tournament 3: Round Robin (~1-2hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/06_tournament_rr_test.dart -d emulator-5554
```

### Step 4: Verify All Screens

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/07_verify_all_screens_test.dart -d emulator-5554
```

### Step 5: Viewer / WebSocket Test (separate device needed)

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/08_viewer_live_test.dart -d <device-id>
```

Run on a second device while a scorer runs test 02 on the emulator. See `scripts/multi-device-e2e.sh`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Firebase auth fails | Verify test phone 9999999999 is configured in Firebase Console |
| Server 5xx errors | Check server logs: `pm2 logs cricscores` on VPS |
| Test hangs on fixture | Emulator might be slow — increase timeouts or restart emulator |
| Tournament test fails mid-run | Re-run just that tournament — it creates a NEW tournament with random name |
| "No teams found" | Run team setup first (test 01) |
| ErrorTracker shows error | Read the summary — it shows exactly which step failed and what succeeded |

## File Reference

| File | Purpose |
|------|---------|
| `integration_test/core/app_bootstrap.dart` | App launch + Firebase auth |
| `integration_test/core/error_tracker.dart` | `ErrorTracker` — step tracking + resume |
| `integration_test/core/test_utils.dart` | `waitForFinder()`, `waitForFinderGone()`, `testLog()` |
| `integration_test/flows/tournament_flow.dart` | `scoreAllFixtures()` — orchestrates all fixture scoring |
| `integration_test/flows/random_innings.dart` | `playRandomInnings()` — weighted random delivery generation |
| `integration_test/flows/team_setup_flow.dart` | Create N teams × M players via UI |
| `integration_test/flows/standalone_match_flow.dart` | Full standalone match lifecycle |
| `integration_test/helpers/tournament_mgmt.dart` | `createTournament()`, `addTeamToTournament()`, `generateFixtures()` |
| `integration_test/helpers/fixture_scanning.dart` | Find and tap FixtureCard widgets |
| `integration_test/helpers/scoring.dart` | Tap scoring controls |
| `integration_test/config/test_data.dart` | Team/player names, phone numbers |
| `integration_test/config/tournament_presets.dart` | Tournament format configurations |
| `integration_test/tests/01_team_setup_test.dart` | Team setup test |
| `integration_test/tests/02_standalone_match_test.dart` | Standalone match test |
| `integration_test/tests/04_tournament_gk_test.dart` | Group+Knockout tournament test |
| `integration_test/tests/05_tournament_ko_test.dart` | Knockout tournament test |
| `integration_test/tests/06_tournament_rr_test.dart` | Round Robin tournament test |
| `integration_test/tests/07_verify_all_screens_test.dart` | Screen verification test |
| `integration_test/tests/08_viewer_live_test.dart` | Multi-device WebSocket test |
