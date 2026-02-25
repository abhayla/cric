# Tournament E2E Tests — Run Prompt

Run this prompt when you want to execute the tournament E2E tests. These tests prove the complete tournament lifecycle works end-to-end through the real Flutter UI on an emulator against the prod server (`cricscores.in`).

---

## What These Tests Do

Three tournament tests cover the three tournament formats:

| Test | File | Format | Teams | Est. Matches | Runtime |
|------|------|--------|-------|-------------|---------|
| 04 | `04_tournament_gk_test.dart` | Group+Knockout | 16 (4 groups × 4) | ~27 | ~2-3 hrs |
| 05 | `05_tournament_ko_test.dart` | Knockout | 16 (single elimination) | 15 | ~1 hr |
| 06 | `06_tournament_rr_test.dart` | Round Robin | Subset | Varies | ~1-2 hrs |

Each test:
- Creates a tournament with a random name via the UI
- Opens registration, adds teams, generates fixtures — all via UI
- Scores all fixtures through the real scoring UI (random deliveries)
- Verifies tournament completion (no unplayed fixtures remain)

**100% UI-driven — zero API calls.**

---

## Prerequisites Checklist

Before running, confirm ALL of these:

1. **Android emulator is running** — start via Android Studio or `emulator -avd <name>`
2. **Prod server is live** at `cricscores.in` (verify: `curl https://cricscores.in/health`)
3. **Teams already created** — run test 01 first (`01_team_setup_test.dart`)
4. **Flutter dependencies resolved** — `cd apps/mobile && flutter pub get`
5. **Code generation up to date** — `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

---

## Run Commands

```bash
# Group+Knockout tournament
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/04_tournament_gk_test.dart -d emulator-5554

# Knockout tournament
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/05_tournament_ko_test.dart -d emulator-5554

# Round Robin tournament
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/06_tournament_rr_test.dart -d emulator-5554
```

---

## Test Flow (Per Tournament)

| Phase | What Happens | Key File |
|-------|-------------|----------|
| 1 | Launch app, authenticate with test phone | `app_bootstrap.dart` |
| 2 | Create tournament via UI form | `tournament_mgmt.dart` |
| 3 | Open registration, add teams to groups | `tournament_mgmt.dart` |
| 4 | Generate fixtures | `tournament_mgmt.dart` |
| 5 | Start tournament | `tournament_mgmt.dart` |
| 6 | Score all fixtures (scan → tap → score → repeat) | `tournament_flow.dart` |
| 7 | Verify no unplayed fixtures remain | `tournament_flow.dart` |

## Match Flow (Each Fixture)

Each match follows this flow through the real UI:

1. **Scan fixtures tab** — find unplayed FixtureCard (`fixture_scanning.dart`)
2. **Tap fixture card** — navigate to match setup
3. **Complete match setup + toss wizard** — (`match_setup.dart`)
4. **Score 1st innings** — `playRandomInnings()` with weighted random deliveries (`random_innings.dart`)
5. **Innings transition** — select openers + bowler for 2nd innings (`modals.dart`)
6. **Score 2nd innings** — `playRandomInnings()`
7. **Match complete** — dismiss MatchCompleteModal (`modals.dart`)
8. **Navigate back** — return to tournament fixtures tab (`navigation.dart`)

---

## Key Helper Files

| File | Purpose |
|------|---------|
| `integration_test/core/app_bootstrap.dart` | App launch + Firebase auth |
| `integration_test/core/error_tracker.dart` | Step-by-step progress tracking |
| `integration_test/core/test_utils.dart` | `waitForFinder()`, `waitForFinderGone()`, `testLog()` |
| `integration_test/flows/tournament_flow.dart` | `scoreAllFixtures()` — orchestrates all fixture scoring |
| `integration_test/flows/random_innings.dart` | `playRandomInnings()` — weighted random delivery generation |
| `integration_test/helpers/tournament_mgmt.dart` | `createTournament()`, `addTeamToTournament()`, `generateFixtures()` |
| `integration_test/helpers/fixture_scanning.dart` | Find and tap FixtureCard widgets |
| `integration_test/helpers/match_setup.dart` | Match setup + 5-step toss wizard |
| `integration_test/helpers/scoring.dart` | Tap scoring controls (runs, extras, wickets) |
| `integration_test/helpers/modals.dart` | Dismiss completion/transition modals |
| `integration_test/models/delivery_record.dart` | `DeliveryRecord` for tracking expected deliveries |

---

## Debugging Tips

- **Match stuck on toss?** Check toss wizard step — opener or bowler names may not match roster.
- **Fixture card not found?** Test scrolls to find fixtures. Check if all fixtures already played.
- **"Back to Home" not found?** MatchCompleteModal may take time. Test uses `waitForFinder()` with timeout.
- **ErrorTracker shows error?** Read the summary — it shows exactly which step failed and what succeeded.

---

## What These Tests Do NOT Cover

- Bowl-first toss choice (always bats first)
- Playing XI selection through UI (auto-selected because roster = playersPerSide)
- Tied matches or super overs
- Magic over in tournaments
- Match abandonment mid-tournament
- NRR calculation verification
- Player career stats accumulation verification (covered by test 07)
