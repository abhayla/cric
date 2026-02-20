# Tournament E2E Test — Run Prompt

Run this prompt when you want to execute the full tournament E2E test. This test proves the complete tournament lifecycle works end-to-end through the real Flutter UI on an emulator, with all data verified against PostgreSQL.

---

## What This Test Does

- Creates 16 teams with 6 players each (IPL-style names) via server API
- Creates a Group+Knockout tournament (4 groups x 4 teams, 6 overs, magic over on 4th)
- Adds all teams to groups and generates fixtures via server API
- Plays 24 group stage matches through the real scoring UI (random deliveries, seed=42 for determinism)
- Verifies group standings
- Plays 2 semi-finals + 1 final through the UI
- Verifies tournament leaderboard (top run scorer, top wicket taker)
- Verifies all match results, deliveries, and awards in PostgreSQL via test API

**Total: 27 matches scored through the UI. Runtime: ~2-3 hours on emulator.**

---

## Prerequisites Checklist

Before running, confirm ALL of these:

1. **Android emulator is running** — start via Android Studio or `emulator -avd <name>`
2. **Bun server running in test mode:**
   ```bash
   cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
   ```
3. **PostgreSQL running** — with test database configured in `apps/server/.env`
4. **Flutter dependencies resolved** — `cd apps/mobile && flutter pub get`
5. **Code generation up to date** — `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

---

## Run Command

```bash
cd apps/mobile && flutter test integration_test/tournament_e2e_test.dart -d emulator-5554
```

The test has a 3-hour timeout (`Timeout(Duration(hours: 3))`).

---

## Test Phases

| Phase | What Happens | Method |
|-------|-------------|--------|
| 1 | Launch app, land on Home page | `AppTestWrapper.pumpApp()` |
| 2 | Create 16 teams + 96 players | `serverManager.createTeamApi()` + `createPlayerApi()` + `addPlayerToTeamApi()` |
| 3 | Create tournament "MockTour-{timestamp}" | `serverManager.createTournamentApi()` |
| 4 | Add 16 teams to 4 groups (A/B/C/D) | `serverManager.addTeamToTournamentApi()` |
| 5 | Generate fixtures (24 group + 3 knockout) | `serverManager.generateFixturesApi()` |
| 6 | Play 24 group matches | `playFullMatch()` x24 via UI |
| 7 | Verify group standings | `verifyStandingsPage()` |
| 8 | Play 2 semi-finals | `playFullMatch()` x2 via UI |
| 9 | Play the final | `playFullMatch()` x1 via UI |
| 10 | Verify tournament leaderboard | `navigateToLeaderboard()` |
| 11 | Log all results | Console output |
| 12 | DB verification | `dbVerifier.verifyMatchDeliveries()`, `verifyMatchAwards()`, `verifyStandings()`, `verifyLeaderboard()` |

---

## Match Flow (Each of the 27 Matches)

Each match follows this flow through the real UI:

1. **Navigate to tournament fixtures tab** — `ensureOnTournamentFixtures()`
2. **Tap the fixture card** — `tapFixtureCard()` finds the specific FixtureCard by both team names, scrolls into view, taps InkWell
3. **Complete match setup** — `completeMatchSetup()` taps "Proceed to Toss" (teams pre-selected from fixture)
4. **Complete 5-step toss wizard** — `completeTossWizard()`:
   - Step 1: Select toss winner (Team A always wins)
   - Step 2: Choose to Bat
   - Steps 3-4: Playing XI auto-selected (roster = playersPerSide)
   - Step 5: Select 2 openers + striker + opening bowler
5. **Score 1st innings** — `playRandomInnings()` with random deliveries (runs, wickets, extras)
6. **Innings transition** — `completeInningsTransition()` selects Team B openers + Team A bowler
7. **Score 2nd innings** — `playRandomInnings()` with random deliveries
8. **Match complete** — Wait for modal, tap "Back to Home"
9. **Navigate home** — `navigateToHome()` via button or GoRouter

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/tournament_e2e_test.dart` | Main test file |
| `integration_test/helpers/data_generators.dart` | `TeamData`, `PlayerData`, `TournamentConfig`, `TournamentTestData` with 16 IPL-style teams |
| `integration_test/helpers/tournament_flow_helpers.dart` | Navigation (tournaments/teams tabs), team creation via UI, toss wizard, fixture tapping, standings/leaderboard |
| `integration_test/helpers/match_flow_helpers.dart` | `playRandomInnings()`, `completeInningsTransition()`, `settle()`, `visualPause()` |
| `integration_test/helpers/server_manager.dart` | Server API calls: create team/player/tournament, generate fixtures, reset DB, health check |
| `integration_test/helpers/db_verifier.dart` | DB verification: deliveries, awards, standings, leaderboard |
| `integration_test/helpers/delivery_record.dart` | `MatchRecord`, `DeliveryRecord` for tracking expected vs actual |
| `integration_test/helpers/app_test_wrapper.dart` | `AppTestWrapper.pumpApp()` bootstraps the app in test mode |

---

## Data Setup

**Teams:** 16 teams, 6 players each, all players are `all_rounder` role (everyone can bat and bowl in 6-player format). Created via API in Phase 2 (not through UI — too slow for 16 teams).

**Tournament config:**
- Format: Group + Knockout
- Overs: 6 per innings
- Players per side: 6
- Groups: 4 (A, B, C, D with 4 teams each)
- Qualify per group: 1 (top team advances to semis)
- Magic over: 4th over (runs doubled)

**Group assignments:**
- Group A: Teams 1-4 (Mumbai Lions, Delhi Capitals, Chennai Kings, Kolkata Riders)
- Group B: Teams 5-8 (Bangalore Stars, Hyderabad Sunrisers, Rajasthan Royals, Punjab Kings)
- Group C: Teams 9-12 (Gujarat Titans, Lucknow Giants, Ahmedabad Warriors, Pune Strikers)
- Group D: Teams 13-16 (Indore Rangers, Jaipur Panthers, Chandigarh Lions, Goa Challengers)

**Random seed:** 42 (deterministic — same results every run)

---

## Known Issues

1. **Semi-final/final team selection is hardcoded** — Uses teams[0] vs teams[12] and teams[4] vs teams[8] as placeholders rather than reading actual group winners from standings. The actual group winners depend on random match results, so the hardcoded teams may not have qualified.

2. **DB verification uses placeholder tournament ID** — `const tournamentId = 'mock-tour-1'` instead of the actual UUID returned from `createTournamentApi()`.

3. **`test-verify` API returns 500** on tournament verification — Server-side bug in the endpoint (documented in CONTINUE_PROMPT.md).

4. **No team reuse across runs** — Each run creates fresh 16 teams + 96 players. No smart reset like the single match E2E test has.

---

## Debugging Tips

- **Match stuck on toss?** Check `dumpVisibleTexts()` output — opener or bowler names may not match player names in the roster.
- **Fixture card not found?** The test scrolls up to 15 times. Check if the fixture was already played (completed fixtures may look different).
- **"Back to Home" not found after match?** The MatchCompleteModal may take time to render. The test retries 5 times with 500ms waits.
- **Standings page empty?** Group standings update via `completeMatch()` on the server. If the test-verify API fails, standings won't populate.

---

## What This Test Does NOT Cover

- Bowl-first toss choice (always bats first)
- Playing XI selection through UI (auto-selected because roster = playersPerSide)
- Tied matches or super overs
- Tournament with different formats (knockout only, round robin only)
- Team reuse across test runs
- Player career stats accumulation across tournament matches
- NRR (Net Run Rate) calculation verification
- Match abandonment mid-tournament
