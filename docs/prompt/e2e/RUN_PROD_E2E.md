# Prompt: Run Production E2E Tests

Use this prompt to instruct Claude to execute the production E2E test suite.

---

## Critical Rule

**All actions (team creation, player addition, tournament creation, status transitions, team registration, fixture generation, scoring) go through the app UI — no API shortcuts, no exceptions.**

API calls are allowed ONLY for read-only queries: listing tournaments by name to get IDs, fetching fixture lists for scoring order, checking standings after completion.

### Tournament UI Flow (per tournament)
Each `setupTournamentViaUI()` call performs these steps through the real app UI:
1. Create tournament (form: name, format, overs, ball type, players per side, groups)
2. Open Registration (⋮ menu → "Open Registration")
3. Add all teams (Teams tab → "Add Team" → group chip → team name, repeated N times)
4. Generate Fixtures (Overview tab → "Generate Fixtures")
5. Start Tournament (⋮ menu → "Start Tournament")

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
Abhay Kumar (viewer, phone 9999999998) is automatically added to Bangalore Titans.

### Step 2: Run Tournaments (overnight, ~15 hours)

Option A — Run all sequentially via script:
```bash
bash scripts/prod-e2e-overnight.sh --skip-teams
```

Option B — Run individually (useful if one fails and needs re-run):
```bash
# Tournament 1: Champions Trophy (Group+KO, 5ov, ~31 matches, ~2hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_1_test.dart -d emulator-5556

# Tournament 2: Premier League (Group+KO, 10ov, ~27 matches, ~2.5hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_2_test.dart -d emulator-5556

# Tournament 3: Knockout Cup (KO, 5ov, 15 matches, ~1hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_3_test.dart -d emulator-5556

# Tournament 4: Super League (Round Robin, 5ov, 120 matches, ~7hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_4_test.dart -d emulator-5556

# Tournament 5: Masters Trophy (Group+KO, 3ov, ~63 matches, ~3hr)
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/prod/prod_tournament_5_test.dart -d emulator-5556
```

### Step 3: Verify Results

After completion, check:
1. Open the app on the viewer device (phone 9999999998)
2. Navigate to Tournaments tab — all 5 tournaments should be visible
3. Tap each tournament to verify standings and completed fixtures
4. Tap any match scorecard to verify innings data
5. Check player profiles for accumulated career stats

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Firebase auth fails | Verify test phone 9999999999 is configured in Firebase Console |
| Server 5xx errors | Check server logs: `pm2 logs cricscores` on VPS |
| Test hangs on fixture | Emulator might be slow — increase timeouts or restart emulator |
| Tournament test fails mid-run | Re-run just that tournament — it creates a NEW tournament |
| "No teams found" | Run team setup first: `--skip-teams` flag skips it |

## File Reference

| File | Purpose |
|------|---------|
| `apps/mobile/integration_test/prod/prod_helpers.dart` | `setupTournamentViaUI()`, `scoreAllFixtures()`, scoring helpers |
| `apps/mobile/integration_test/helpers/tournament_flow_helpers.dart` | `createTournament()`, `addTeamToTournament()`, `generateFixtures()`, `transitionTournamentStatus()` |
| `apps/mobile/integration_test/prod/prod_team_setup_test.dart` | Create 16 teams x 6 players via UI |
| `apps/mobile/integration_test/prod/prod_tournament_[1-5]_test.dart` | Individual tournament tests |
| `scripts/prod-e2e-overnight.sh` | Sequential runner with logging |
| `docs/prompt/e2e/PROD_MANUAL_E2E.md` | Full test plan reference |
