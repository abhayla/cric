# Prompt: Run Production E2E Tests

Use this prompt to instruct Claude to execute the production E2E test suite.

---

## Critical Rule

**100% UI-driven — zero API calls.** All actions (team creation, player addition, tournament creation, status transitions, team registration, fixture generation, scoring, fixture navigation) go through the app UI — the exact same process any real user would follow. No API shortcuts. No exceptions.

### Tournament UI Flow (per tournament)
Each `setupTournamentViaUI()` call performs these steps through the real app UI:
1. Create tournament (form: name, format, overs, ball type, players per side, groups)
2. Open Registration (... menu -> "Open Registration")
3. Add all teams (Teams tab -> "Add Team" -> group chip -> team name, repeated N times)
4. Generate Fixtures (Overview tab -> "Generate Fixtures")
5. Start Tournament (... menu -> "Start Tournament")

### Fixture Scoring (per match)
`scoreAllFixturesViaUI()` scans FixtureCard widgets on the Fixtures tab to find unplayed matches:
1. Switch to Fixtures tab, scan for FixtureCard with `!fixture.hasMatch`
2. Tap the fixture card -> match setup -> random toss -> score both innings
3. Dismiss match complete modal -> navigate back to tournament detail
4. Repeat until no unplayed fixtures remain

### Error Tracking
- `ErrorTracker` class logs every success/error with step description
- On first error: test stops immediately, prints where it stopped
- Resume support: `startFromTeam` / `startFromMatch` params to skip completed work
- `tracker.printSummary()` at end shows full progress report

## Pre-requisites

Before running, verify:
1. Android emulator is running (`flutter devices` should show emulator-5556)
2. Prod server is live at cricscores.in
3. Prod debug APK is built: `cd apps/mobile && flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod`

## Execution Steps

### Step 1: Team Setup (one-time, ~20 min)

Run the team setup test to create 16 teams with 6 players each via UI:

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_team_setup_test.dart -d emulator-5556
```

Wait for completion. Verify output shows all 16 teams created with 6 players each.

Teams: Team 1 through Team 16
Players: T1Play1-T1Play6, T2Play1-T2Play6, ..., T16Play1-T16Play6
Phones: 9999999101 through 9999999196

### Step 2: Run Tournaments (overnight, ~15 hours)

Tournament names are randomly generated per run (e.g., "Champions Trophy 48291").

Option A — Run all sequentially via script:
```bash
bash scripts/prod-e2e-overnight.sh --skip-teams
```

Option B — Run individually (useful if one fails and needs re-run):
```bash
# Tournament 1: Group+KO, 5ov, 4 groups, top 2 qualify (~31 matches, ~2hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_1_test.dart -d emulator-5556

# Tournament 2: Group+KO, 10ov, 4 groups, top 1 qualifies (~27 matches, ~2.5hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_2_test.dart -d emulator-5556

# Tournament 3: Knockout, 5ov, 16 teams (15 matches, ~1hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_3_test.dart -d emulator-5556

# Tournament 4: Round Robin, 5ov, 120 matches (~7hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_4_test.dart -d emulator-5556

# Tournament 5: Group+KO, 3ov, 2 groups of 8, top 4 qualify (~63 matches, ~3hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_5_test.dart -d emulator-5556
```

### Step 3: Verify Results

After completion, check:
1. Open the app on the viewer device (phone 9999999998)
2. Navigate to Tournaments tab — all 5 tournaments should be visible
3. Tap each tournament to verify standings and completed fixtures
4. Tap any match scorecard to verify innings data
5. Check player profiles for accumulated career stats

### Step 2b: Standalone Match Test (~10 min)

Quick standalone match covering undo, target chase, magic over, and persistence:

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_standalone_match_test.dart -d emulator-5556
```

This test is independent of tournaments — uses Team 1 vs Team 2 from the prod roster.

### Viewer / WebSocket Tests (separate from overnight run)

Already covered by dedicated multi-device tests:
- `integration_test/multi_device_viewer_e2e_test.dart` — Quick WebSocket sync check (~5 min)
- `integration_test/full_t20_viewer_e2e_test.dart` — Full T20 per-over sync report (~2 hrs)

Run these separately with a viewer device. See `scripts/multi-device-e2e.sh`.

### Overnight Script

`scripts/prod-e2e-overnight.sh` is current and correct — supports `--skip-teams`, `--only N` flags. Logs output per-tournament to timestamped files.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Firebase auth fails | Verify test phone 9999999999 is configured in Firebase Console |
| Server 5xx errors | Check server logs: `pm2 logs cricscores` on VPS |
| Test hangs on fixture | Emulator might be slow — increase timeouts or restart emulator |
| Tournament test fails mid-run | Re-run just that tournament — it creates a NEW tournament with random name |
| "No teams found" | Run team setup first: `--skip-teams` flag skips it |
| ErrorTracker shows error | Read the summary — it shows exactly which step failed and what succeeded |

## File Reference

| File | Purpose |
|------|---------|
| `apps/mobile/integration_test/prod/prod_helpers.dart` | `setupTournamentViaUI()`, `scoreAllFixturesViaUI()`, `ErrorTracker`, `randomTournamentName()` |
| `apps/mobile/integration_test/helpers/tournament_flow_helpers.dart` | `createTournament()`, `addTeamToTournament()`, `generateFixtures()`, `transitionTournamentStatus()` |
| `apps/mobile/integration_test/helpers/data_generators.dart` | `TeamData`, `PlayerData`, `TournamentConfig` |
| `apps/mobile/integration_test/prod/prod_team_setup_test.dart` | Create 16 teams x 6 players via UI |
| `apps/mobile/integration_test/prod/prod_tournament_[1-5]_test.dart` | Individual tournament tests |
| `apps/mobile/integration_test/prod/prod_standalone_match_test.dart` | Standalone match: undo, target chase, magic over, persistence |
| `apps/mobile/integration_test/prod/prod_cleanup_test.dart` | Delete test teams via UI (graceful fallback) |
| `scripts/prod-e2e-overnight.sh` | Sequential runner with logging (`--skip-teams`, `--only N`) |
| `docs/prompt/e2e/PROD_MANUAL_E2E.md` | Full test plan reference |
