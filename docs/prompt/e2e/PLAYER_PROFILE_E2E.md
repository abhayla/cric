# Player Profile E2E Test — Run Prompt

Run this prompt when you want to test player profile and career stat accumulation across multiple matches. This test proves that playing 2 matches with the same players correctly aggregates career stats.

---

## What This Test Does

- Scores 2 complete quick matches (5 overs each, 6 players per side) using the same teams
- Navigates to a player's profile page via Teams → Team Detail → Players → Player Detail
- Verifies career stats (matches played, total runs, average, wickets) accumulated across both matches
- Cross-checks profile page data against the server API and database

**Scenario covered:** 20 (Player Profile Across Multiple Matches)

**Runtime: ~20-30 minutes on emulator.**

---

## Prerequisites Checklist

1. **Android emulator is running**
2. **Bun server running in test mode:**
   ```bash
   cd apps/server && PORT=3001 NODE_ENV=test bun run src/index.ts
   ```
3. **PostgreSQL running** with test database
4. **Flutter dependencies resolved** — `flutter pub get`
5. **Code generation up to date** — `dart run build_runner build --delete-conflicting-outputs`

---

## Run Command

```bash
cd apps/mobile && flutter test integration_test/player_profile_e2e_test.dart -d emulator-5554
```

Timeout: 45 minutes.

---

## Test Phases

| Phase | What Happens |
|-------|-------------|
| 1 | Boot app |
| 2 | Create teams (Mumbai Warriors + Chennai Challengers, skipped if exist) |
| 3 | Match 1: 5 overs, random scoring with seed=42 |
| 4 | Match 2: 5 overs, random scoring with seed=99 |
| 5 | Navigate to player profile: Teams → Mumbai Warriors → Players → Rohit Sharma |
| 6 | Verify profile page shows career stats |
| 7 | DB verification: query player career stats API |

---

## Match Configuration

Both matches use identical setup:
- **Overs:** 5 per innings
- **Players per side:** 6
- **Toss:** Mumbai Warriors bats first (both matches)
- **Random seeds:** Match 1 = 42, Match 2 = 99 (different results each match)

### Match 1 Flow
1. Team A bats: `playRandomInnings(seed=42, overs=5, playersPerSide=6)`
2. Innings transition: Chennai openers + Mumbai bowler
3. Team B bats: `playRandomInnings(seed=42, overs=5, playersPerSide=6)`
4. Match complete → Back to Home
5. Wait for sync (5s)

### Match 2 Flow
Same structure but with `seed=99` for different delivery patterns.

---

## Profile Navigation Path

```
Home → Teams tab → Tap "Mumbai Warriors" → Players tab → Tap "Rohit Sharma" → Player Detail Page
```

On the Player Detail page, expect to see:
- **Career batting stats:** Total runs, average, strike rate, highest score, innings count
- **Career bowling stats:** Total wickets, economy, average, best figures
- **Match history:** List of matches the player participated in
- **Per-match performance:** Runs and wickets per match

---

## Career Stats Accumulation Logic

After 2 matches, `player_career_stats` should show:
- `matches = 2`
- `batting_innings = 2` (batted in both 1st innings)
- `total_runs = sum of runs across both matches`
- `batting_average = total_runs / dismissals`
- `bowling_overs, bowling_wickets, bowling_economy` if the player bowled

The `career-stats.service.ts` triggers `refreshMatchPlayerCareerStats()` after each `completeMatch()` call, which recalculates career stats for all players in that match.

---

## DB Verification

The test queries career stats via:
1. `GET /api/v1/test/teams` → find team ID
2. `GET /api/v1/teams/:teamId/players` → find player ID
3. `GET /api/v1/players/:playerId/stats` → get career stats

### Key Assertions
- Player participated in >= 2 matches
- Total runs >= 0 (should have batted in both)
- Career stats are consistent between profile page UI and API response

---

## Important Notes

- **Do NOT reset match data between matches!** Both matches must accumulate stats for the same players. Only call `resetMatchData()` in `setUpAll()` before the first match.
- **6-player teams:** With `playersPerSide=6`, all 6 roster players are auto-selected for Playing XI (no manual XI selection needed in toss wizard).
- **Bowler pools:** Only take first 4 bowlers from `ScenarioTeams.teamBBowlers` for 5-over matches (need at most ceil(5/1) = 5 different bowlers, but 4 is enough with rotation).

---

## Debugging Tips

- **Match 2 "Start Match" not found?** Make sure you navigated back to Home after Match 1. Use `navigateToHome(tester)` or GoRouter fallback.
- **Player not found in roster?** Check that team creation succeeded. The `addPlayersToRoster` helper waits for API calls to complete before continuing.
- **Career stats show only 1 match?** The `completeMatch()` call triggers career stat refresh. Verify both matches completed successfully (check for MatchCompleteModal).
- **Profile page empty?** The player detail page may need to fetch data from server. Wait for `pumpAndSettle` after navigation.

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/player_profile_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data |
| `integration_test/helpers/match_flow_helpers.dart` | Random innings, tap helpers |
| `integration_test/helpers/single_match_flow.dart` | SingleMatchFlow orchestrator |
| `integration_test/helpers/server_manager.dart` | Server API calls |
| `integration_test/helpers/tournament_flow_helpers.dart` | Team creation, toss, navigation |
