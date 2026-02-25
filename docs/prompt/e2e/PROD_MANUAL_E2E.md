# Production E2E Test Plan — 16 Teams, 5 Tournaments, 256 Matches

## Overview

Comprehensive production test: create 16 teams (96 players), run 5 tournaments (~256 matches) with fully random scoring. All data persists permanently on the prod server (`cricscores.in`). Runs overnight (~13-17 hours).

**100% UI-driven — zero API calls.** All actions (team creation, player addition, tournament creation, tournament status transitions, team registration, fixture generation, scoring, fixture navigation) go through the app UI — the exact same process any real user would follow. No API shortcuts. No exceptions.

### Full UI Flow Per Tournament
1. **Create Tournament** — Fill form (name, format chip, overs, ball type, players per side, group settings) -> Submit
2. **Open Registration** — Tap ... menu -> "Open Registration"
3. **Add Teams** — Tap "Add Team" on Teams tab -> select group (if applicable) -> tap team name. Repeat for all teams.
4. **Generate Fixtures** — Tap "Generate Fixtures" on Overview tab
5. **Start Tournament** — Tap ... menu -> "Start Tournament"
6. **Score Matches** — Scan FixtureCard widgets for unplayed matches, tap each one, complete toss + both innings via UI

### Error Tracking & Resume
- `ErrorTracker` stops test on first error and prints exactly where it stopped
- Resume: re-run the test — it creates a NEW tournament with a random name
- `startFromTeam` / `startFromMatch` params available for fine-grained resume

## Pre-Test Checklist

- [ ] Prod server running at `cricscores.in` (verify: `curl https://cricscores.in/api/v1/test/health`)
- [ ] Android emulator running (`emulator -avd <name>`)
- [ ] Scorer phone configured: `9999999999` (Firebase test phone, OTP: `123456`)
- [ ] Viewer phone configured: `9999999998` (Firebase test phone, OTP: `123456`)
- [ ] Prod APK built: `flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod`
- [ ] Viewer has prod APK installed on their device
- [ ] Stable internet connection for overnight run

## 16 Team Rosters

| # | Team Name | Player 1 | Player 2 | Player 3 | Player 4 | Player 5 | Player 6 |
|---|-----------|----------|----------|----------|----------|----------|----------|
| 1 | Team 1 | T1Play1 | T1Play2 | T1Play3 | T1Play4 | T1Play5 | T1Play6 |
| 2 | Team 2 | T2Play1 | T2Play2 | T2Play3 | T2Play4 | T2Play5 | T2Play6 |
| 3 | Team 3 | T3Play1 | T3Play2 | T3Play3 | T3Play4 | T3Play5 | T3Play6 |
| 4 | Team 4 | T4Play1 | T4Play2 | T4Play3 | T4Play4 | T4Play5 | T4Play6 |
| 5 | Team 5 | T5Play1 | T5Play2 | T5Play3 | T5Play4 | T5Play5 | T5Play6 |
| 6 | Team 6 | T6Play1 | T6Play2 | T6Play3 | T6Play4 | T6Play5 | T6Play6 |
| 7 | Team 7 | T7Play1 | T7Play2 | T7Play3 | T7Play4 | T7Play5 | T7Play6 |
| 8 | Team 8 | T8Play1 | T8Play2 | T8Play3 | T8Play4 | T8Play5 | T8Play6 |
| 9 | Team 9 | T9Play1 | T9Play2 | T9Play3 | T9Play4 | T9Play5 | T9Play6 |
| 10 | Team 10 | T10Play1 | T10Play2 | T10Play3 | T10Play4 | T10Play5 | T10Play6 |
| 11 | Team 11 | T11Play1 | T11Play2 | T11Play3 | T11Play4 | T11Play5 | T11Play6 |
| 12 | Team 12 | T12Play1 | T12Play2 | T12Play3 | T12Play4 | T12Play5 | T12Play6 |
| 13 | Team 13 | T13Play1 | T13Play2 | T13Play3 | T13Play4 | T13Play5 | T13Play6 |
| 14 | Team 14 | T14Play1 | T14Play2 | T14Play3 | T14Play4 | T14Play5 | T14Play6 |
| 15 | Team 15 | T15Play1 | T15Play2 | T15Play3 | T15Play4 | T15Play5 | T15Play6 |
| 16 | Team 16 | T16Play1 | T16Play2 | T16Play3 | T16Play4 | T16Play5 | T16Play6 |

Player phones: 9999999101 (T1Play1) through 9999999196 (T16Play6).
All players assigned role: **All-Rounder** (everyone can bat and bowl in 6-player format).

**Viewer:** Abhay Kumar (phone 9999999998) is added as a 7th roster member on Team 1. He won't be in the playing XI (playersPerSide=6) but can view all Team 1 matches as a participant.

## 5 Tournament Configurations

Tournament names are randomly generated per run (e.g., "Champions Trophy 48291", "Elite Series 73012").

| # | Format | Overs | Groups | Qualify/Group | Ball Type | Est. Matches |
|---|--------|-------|--------|---------------|-----------|-------------|
| T1 | Group+KO | 5 | 4 (4 teams) | Top 2 | Tennis (2) | ~31 |
| T2 | Group+KO | 10 | 4 (4 teams) | Top 1 | Leather (1) | ~27 |
| T3 | Knockout | 5 | - | - | Tennis (2) | 15 |
| T4 | Round Robin | 5 | - | - | Tennis (2) | 120 |
| T5 | Group+KO | 3 | 2 (8 teams) | Top 4 | Tape (3) | ~63 |

### Group Assignments

**T1 & T2 (4 groups x 4 teams):**
- Group A: Team 1, Team 2, Team 3, Team 4
- Group B: Team 5, Team 6, Team 7, Team 8
- Group C: Team 9, Team 10, Team 11, Team 12
- Group D: Team 13, Team 14, Team 15, Team 16

**T3 (Knockout):** Seeded 1-16 in team list order.

**T4 (Round Robin):** All 16 teams in single pool.

**T5 (2 groups x 8 teams):**
- Group A: Team 1-8
- Group B: Team 9-16

## Delivery Distribution (Random Scoring)

| Outcome | Weight | Probability |
|---------|--------|-------------|
| Dot (0) | 30 | 30% |
| Single (1) | 25 | 25% |
| Double (2) | 15 | 15% |
| Triple (3) | 5 | 5% |
| Four (4) | 10 | 10% |
| Six (6) | 5 | 5% |
| Wicket | 5 | 5% |
| Wide | 3 | 3% |
| No-ball | 2 | 2% |

**Wicket types (equal probability):** Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket, C&B.

**Magic Over:** When enabled, runs in the magic over are doubled (2x multiplier). The standalone match test enables magic over on over 2 to exercise this path. Tournament tests do not use magic over.

## Standalone Match Test (Automated)

`prod_standalone_match_test.dart` covers key gaps in a single ~10 min test:

- **G1 Standalone match**: Creates a match outside tournaments (Team 1 vs Team 2, 5 overs)
- **G4 Undo**: Scores 3 singles → taps undo → verifies score drops → re-scores
- **G5 Persistence**: After match, navigates to My Cricket > Matches tab, checks match card exists
- **G6 Target chase**: If first innings total is low (≤30), chases with singles to verify mid-over match completion
- **G10 Magic over**: Enables magic over on over 2 via the MatchSetupPage toggle

```bash
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/prod/prod_standalone_match_test.dart -d emulator-5556
```

## Quick Manual Test Sessions

### Session 1: Core Flow Verification (~15 min)
Before running overnight automation, manually verify on emulator:
1. Log in with test phone 9999999999
2. Create one team ("Test Team") with 6 players
3. Create a standalone match (5 overs)
4. Complete toss, score 2-3 overs
5. Verify scoring controls work, bowler rotation triggers
6. Verify match appears in "My Cricket" tab

### Session 2: Edge Cases (~10 min)
1. Score a wide followed by a no-ball (extras panel)
2. Take a wicket (Bowled) - verify new batter selection sheet
3. Verify last wicket triggers innings transition
4. Score target chase - verify match completion

### Session 3: Bowl-First Scenario (~10 min)
1. Create match, toss winner chooses to Field
2. Verify batting team is correct (toss loser bats first)
3. Score through innings transition
4. Verify correct teams batting in each innings

### Session 4: Persistence (~5 min)
1. Close and reopen app
2. Verify completed match still visible in match list
3. Verify scorecard shows correct data

## Execution Commands

```bash
# 1. Start emulator
emulator -avd <avd_name> &

# 2. Build prod debug APK
cd apps/mobile
flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod

# 3. Create teams (one-time, ~20 min)
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/prod/prod_team_setup_test.dart -d emulator-5554

# 4. Run tournaments sequentially (overnight)
# Option A: Individual
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/prod/prod_tournament_1_test.dart -d emulator-5554

# Option B: Runner script (all 5 tournaments)
bash scripts/prod-e2e-overnight.sh
```

## Pass/Fail Criteria

### PASS
- All 16 teams created with 6 players each
- Each tournament completes all fixtures without crashes
- Match completion modals appear for every match
- Match result text captured from MatchCompleteModal (contains "won by" / "Tied")
- Standings verified on Overview tab for group-stage tournaments (T1, T2, T5)
- Standalone match: undo decrements score, target chase ends mid-over, match persists on Matches tab
- No unhandled exceptions in test output
- ErrorTracker shows no errors for all tests
- Viewer can see tournaments and match scorecards on their device

### FAIL
- ErrorTracker stops test mid-tournament (investigate error in summary)
- Server returns 5xx errors during scoring
- Match gets stuck (no completion modal after all overs)
- Firebase auth fails on emulator

### WARN (investigate but don't block)
- Occasional wide/no-ball not registering (UI timing)
- Bowler selection falls back to "any available" (naming mismatch)
- Score totals differ by 1-2 runs (extras timing edge case)

## Viewer Verification Protocol

After overnight run completes, the viewer (phone 9999999998) should check:

1. **Tournaments tab:** 5 tournaments visible (with random names from that run)
2. **Each tournament:**
   - Standings tab shows correct team order (by points, then NRR)
   - Fixtures tab shows all matches as completed
   - Leaderboard shows top run-scorers and wicket-takers
3. **Any match scorecard:** Tap any completed match to verify:
   - Both innings shown with correct batting/bowling stats
   - Extras tallied (wides, no-balls)
   - Result displayed correctly
4. **Player profiles:** Tap any player name to verify career stats accumulated across tournaments
5. **Data integrity:** ~256 matches x ~60 deliveries avg = ~15,000 deliveries in prod DB

## Resumability

Each tournament test is **independent**:
- Tournament names are random — re-running creates a NEW tournament
- If a tournament test crashes, re-run it — no conflict with previous data
- Previous tournament data is never touched
- Team setup only needs to run once (teams persist on server)
