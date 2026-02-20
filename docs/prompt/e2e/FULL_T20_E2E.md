# Full T20 E2E Test — Run Prompt

Run this prompt when you want to execute the full T20 E2E test. This test proves a complete 20-over match works end-to-end through the real Flutter UI on a device, with all stats verified against PostgreSQL.

> **IMPORTANT — User-Visible Run:** Always let the user run E2E integration tests themselves from their IDE (Android Studio / VS Code) so they can watch the test execute on the device in real time. Do NOT run these from Claude's CLI in the background. Instead, provide the exact run command and let the user execute it.

---

## What This Test Does

- Reuses shared teams (Mumbai Warriors + Chennai Challengers, 11 players each) via Scenario 0 smart reset
- Scores a full T20 match: 20 overs per side with random deliveries (seed=42 for determinism)
- Verifies every delivery record in PostgreSQL matches what was tapped in the UI
- Verifies batting stats, bowling stats, match result, and match awards in DB
- Navigates to scorecard page and cross-checks UI values against DB (Scenario 15)

**Scenarios covered:** 12 (Full T20), 13 (Stat Verification), 15 (Scorecard vs DB)

**Total: ~240 deliveries scored through the UI. Runtime: ~30-60 minutes on emulator.**

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

**On emulator:**
```bash
cd apps/mobile && flutter test integration_test/full_t20_e2e_test.dart -d emulator-5554
```

**On physical device (replace `<DEVICE_ID>` and `<LAN_IP>`):**
```bash
cd apps/mobile && flutter test integration_test/full_t20_e2e_test.dart -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1
```

Find your device ID with `flutter devices` and LAN IP with `ipconfig` (Windows) or `ifconfig` (Mac/Linux).

The test has a 1-hour timeout (`Timeout(Duration(hours: 1))`).

> **Run this from your IDE terminal** — not from Claude's CLI — so you can watch it on your device.

---

## Test Phases

| Phase | What Happens | Duration |
|-------|-------------|----------|
| 1 | Boot app, land on Home page | ~5s |
| 2 | Create teams (skipped if already exist) | 0s or ~90s |
| 3 | Match setup: 20 overs, 11 players per side | ~15s |
| 4 | Toss wizard: Mumbai Warriors bats first | ~10s |
| 5 | 1st innings: 20 overs random scoring | ~15-25 min |
| 6 | Innings transition: select Chennai openers + Mumbai bowler | ~10s |
| 7 | 2nd innings: 20 overs random scoring | ~15-25 min |
| 8 | Match complete modal | ~5s |
| 9 | DB verification: deliveries, stats, result, awards | ~10s |
| 10 | Scorecard vs DB comparison | ~15s |

---

## Team Setup

**Team A (Mumbai Warriors):** Rohit Sharma, Virat Kohli, Suryakumar Yadav, KL Rahul, Hardik Pandya, Ravindra Jadeja, Axar Patel, Jasprit Bumrah, Mohammed Shami, Yuzvendra Chahal, Rishabh Pant

**Team B (Chennai Challengers):** Shubman Gill, Yashasvi Jaiswal, Shreyas Iyer, Sanju Samson, Ravichandran Ashwin, Washington Sundar, Shardul Thakur, Deepak Chahar, Bhuvneshwar Kumar, Kuldeep Yadav, Ishan Kishan

**Roles:** 4 batters, 3 all-rounders, 3 bowlers, 1 WK-batter per team.

**Smart reuse:** First run creates teams via UI (~90s). Subsequent runs detect existing teams via `GET /api/v1/test/teams` and skip to match setup.

---

## Random Delivery Distribution

Using `Random(42)` with weighted probabilities:
- 30% dot balls
- 25% singles
- 15% twos
- 5% threes
- 10% fours
- 5% sixes
- 5% wickets (Bowled only for simplicity)
- 3% wides
- 2% no-balls

---

## DB Verification Checks (Phase 9)

1. **Delivery count** — UI-tracked count == DB delivery count
2. **Delivery fields** — Each delivery: totalRuns, isWide, isNoBall, isWicket, isLegal, overNumber, ballNumber, isBoundaryFour, isBoundarySix
3. **Batting stats** — At least 4 batting records, per-player runs/balls/fours/sixes/notOut
4. **Bowling stats** — At least 4 bowling records, per-player overs/runs/wickets/wides/noBalls
5. **Match result** — Result type, winner, margin, man of match
6. **Match awards** — MOTM and MVP scores computed

---

## Debugging Tips

- **Match stuck on bowler selection?** Check if the next bowler name exists in the Playing XI. ScenarioTeams.teamBBowlers has 6 options.
- **Over count mismatch?** Wides and no-balls don't count as legal balls. The random generator tracks this correctly.
- **Innings not ending?** Check if all-out happened before 20 overs. Random seed 42 produces deterministic results.
- **DB verification fails?** Wait longer for sync — increase the `Future.delayed(Duration(seconds: 8))` before verification.

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/full_t20_e2e_test.dart` | Main test file |
| `integration_test/helpers/scenario_test_data.dart` | Shared team data (ScenarioTeams) |
| `integration_test/helpers/match_flow_helpers.dart` | Tap helpers, random innings |
| `integration_test/helpers/server_manager.dart` | Server API calls |
| `integration_test/helpers/delivery_record.dart` | MatchRecord for tracking |
| `integration_test/helpers/tournament_flow_helpers.dart` | Team creation, toss wizard |
| `integration_test/helpers/app_test_wrapper.dart` | App bootstrapping |
