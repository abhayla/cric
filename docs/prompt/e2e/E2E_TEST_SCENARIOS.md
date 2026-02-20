# E2E Test Scenarios — CricApp

Comprehensive list of real-life test scenarios to validate CricApp on emulator + local server. These go beyond unit tests by exercising the full stack: Flutter UI → Notifier → Drift persistence → REST/WebSocket → Bun server → PostgreSQL.

## Test Infrastructure

### Scenario 0: Shared Team Setup (Run Once)

Create two teams with full rosters (11 players each) on the first test run. All subsequent tests reuse these teams — only match data is reset between scenarios via `POST /api/v1/test/reset-match-data`.

**Why:** Avoids redundant team creation (~90 seconds saved per test). Teams and players persist in the database across test runs. Each scenario starts fresh by resetting match/delivery/stats data only.

**Verification:**
- `GET /api/v1/test/teams` returns 2 teams with 11+ players each
- If teams exist, skip creation and go directly to match setup

---

## Category A: Cricket Edge Cases (Scoring Logic)

### Scenario 1: Five Wickets in One Over

Score an over where 5 wickets fall (5 different batters dismissed). Tests rapid new-batter selection flow and all-out detection mid-over.

**Setup:** Bat first, score normally for a few overs, then take 5 wickets in one over.
**Verify:** Each wicket triggers new batter selection. If 10th wicket falls, innings ends immediately (11th batter stays not out). Bowling stats show 5W for that bowler's over.

### Scenario 2: Wide + No-Ball Chain (Over Doesn't End)

Bowl: Wide, Wide, Wide, No-Ball, Wide, then 6 legal deliveries. The over should not end until 6 legal balls are bowled.

**Verify:** Over ball count stays at 0 through all 4 extras. Total extras accumulate correctly. Over ends only after 6 legal deliveries. Overs display shows correct format (e.g., "1.0" not "1.4").

### Scenario 3: Target Chased Off a Wide

First innings: score a modest total. Second innings: reach 1 run short of target, then bowler bowls a wide. Match should end immediately — wide counts as a run toward the target.

**Verify:** Match completes on the wide delivery. Result shows "Won by X wickets". No additional deliveries can be scored after match completion.

### Scenario 4: Target Chased Off a No-Ball

Same as Scenario 3 but with a no-ball instead of wide.

**Verify:** Match completes on the no-ball. No-ball penalty run(s) push total past target. Result is correct.

### Scenario 5: All Out for 0

Dismiss all 10 batters without scoring any runs (10 consecutive bowled/LBW wickets on dot balls).

**Verify:** Total score = 0. Total wickets = 10. All 10 batters show 0 runs in batting stats. 11th batter shows "not out" with 0 balls faced. Innings ends with completion reason = all_out.

### Scenario 6: Last Ball Six to Win

First innings: set a target. Second innings: reach exactly 5 runs short of target with 1 ball remaining in the 20th over. Score a six.

**Verify:** Match ends immediately on the six. Result shows correct winning margin. Match doesn't continue to end of over.

### Scenario 7: Tied Match

Both teams score exactly the same total with both innings completed (overs exhausted or all out).

**Verify:** Match result type = "tied". No winner. Both team scores displayed as equal. Result description = "Match Tied".

### Scenario 8: Undo After Over Transition

Score 6 legal deliveries to complete an over. Select a new bowler for the next over. Then undo the last delivery.

**Verify:** Over is reopened. Previous bowler is restored. New bowler selection is cancelled. `lastBowlerId` is correctly restored. Ball count goes back to 5. Maiden count decremented if the completed over was a maiden.

### Scenario 9: Undo After Innings Transition

Complete first innings (all out or overs exhausted). Start second innings (select openers + bowler). Then attempt undo.

**Verify:** Undo should be blocked (`undoBlockedByTransition` = true after innings transition). The UI undo button should be disabled. State remains in second innings.

### Scenario 10: Abandon Mid-Match

Start scoring a match, bowl a few overs, then abandon the match.

**Verify:** Match status = "abandoned". No winner. Match cannot be resumed for scoring. Stats from partial play are preserved in DB.

### Scenario 11: Maiden Over

Bowl 6 consecutive dot balls (0 runs, no extras) in a single over.

**Verify:** Over marked as maiden (`isMaiden = true`). Bowler's maiden count incremented. Economy rate reflects 0 runs for that over.

### Scenario 12: Full-Length T20 Match

Score a complete T20 match: 20 overs per side (~240 deliveries). Mix of runs (0, 1, 2, 3, 4, 6), extras (wides, no-balls, byes, leg-byes), wickets (multiple dismissal types), and at least one undo.

**Verify:** This is the "soak test" — validates no memory leaks, no state corruption over a long session, correct final stats. Compare scorecard page against hand-calculated values for at least 3 batters and 2 bowlers.

---

## Category B: Extras and Dismissal Combinations

### Scenario 21: No-Ball Free Hit Chain

Bowl: No-ball → Free hit delivery (boundary) → No-ball again → Another free hit → Legal delivery.

**Verify:** Free hit indicator appears after each no-ball. Only run out is possible on free hit deliveries. Free hit chains correctly (no-ball on a free hit = another free hit). Chain breaks on a legal delivery that isn't a no-ball.

### Scenario 22: All Dismissal Types

Score deliveries that result in each of the 12 dismissal types across one or more matches:
- Bowled, Caught, LBW, Run Out (striker), Run Out (non-striker), Stumped, Hit Wicket, Caught & Bowled, Hit Ball Twice, Obstructing the Field, Timed Out, Retired Hurt

**Verify:** Each dismissal type is correctly recorded in the delivery record. Wicket count increments for all except Retired Hurt. Bowler gets credit where applicable (Bowled, Caught, LBW, Stumped, Hit Wicket, Caught & Bowled). Fielder recorded for Caught, Stumped, Run Out.

### Scenario 23: Bye and Leg-Bye Scoring

Score byes (1, 2, 4) and leg-byes (1, 2, 4) across multiple deliveries.

**Verify:** Runs added to team total but NOT to batter's runs. Runs NOT conceded by bowler. Don't break a maiden over. Extras breakdown shows correct bye/leg-bye totals. Odd byes/leg-byes swap strike.

### Scenario 24: Wicket on a No-Ball (Run Out)

Bowl a no-ball where the batters attempt a run and one is run out.

**Verify:** No-ball penalty still counted. Run out is valid (only dismissal possible on no-ball). Free hit is triggered for next delivery despite the wicket. New batter faces the free hit.

### Scenario 25: Wicket on a Free Hit (Run Out)

During a free hit delivery, batters attempt a run and one is run out.

**Verify:** Run out is the only valid dismissal. Wicket is recorded. Other dismissal types should be unavailable/disabled in the wicket dialog during free hit.

---

## Category C: Match Flow Variations

### Scenario 26: Overs Exhausted Innings End

Score a full 20 overs (120 legal deliveries) without being all out.

**Verify:** Innings ends automatically after the 20th over. Completion reason = overs_exhausted. All batting stats preserved. Not-out batters marked correctly.

### Scenario 27: Bowler Eligibility Enforcement

Attempt to select the same bowler for consecutive overs. Attempt to select a bowler who has reached max overs.

**Verify:** Consecutive-over bowler shown as ineligible with reason "Bowled last over". Max-overs bowler shown as ineligible with reason "Max overs reached". UI prevents selection of ineligible bowlers.

### Scenario 28: Strike Rotation Correctness

Score a sequence of deliveries with known strike outcomes:
- 1 run → strike swaps
- 2 runs → strike stays
- 3 runs → strike swaps
- End of over → strike swaps
- 1 run + end of over → double swap = no net change

**Verify:** After each delivery, verify which batter has the strike indicator (*) in the UI. Track striker/non-striker IDs through the sequence.

### Scenario 29: Bowl-First Toss Choice

Win toss and choose to field first instead of bat.

**Verify:** Bowling team bowls first (correct team shown as batting in score header). Innings transition correctly swaps roles. Second innings has the toss-winning team batting to chase.

### Scenario 30: Target Chase Exact Score

Second innings team scores exactly the target (not one more).

**Verify:** Matching the target = win (in cricket, you chase by reaching the target, which means equaling the target score since target = first innings + 1). Result shows correct winner and margin.

### Scenario 31: Declaration

First innings team declares (stops batting voluntarily before being all out or overs exhausted).

**Verify:** Innings ends with completion reason = declaration. Second innings gets correct target (first innings score + 1). Batting stats preserved at declaration point.

---

## Category D: Magic Over

### Scenario 32: Magic Over with Run Multiplier

Configure a match with magic over on over 4, multiplier 3x. Score runs during over 4.

**Verify:** Runs scored in over 4 are multiplied by 3 in the team total. Score header shows "MAGIC OVER 3x" badge. Commentary shows original and multiplied values. Scorecard highlights magic over deliveries.

### Scenario 33: Magic Over Wicket Penalty

Configure a match with magic over penalty = -5. Take a wicket during the magic over.

**Verify:** -5 runs applied to batting team's total on wicket. Delivery record has `magicOverPenaltyApplied = true`. Total score correctly reflects multiplied runs minus penalty.

### Scenario 34: Magic Over + Undo

Score a magic over delivery (multiplied runs), then undo it.

**Verify:** Multiplied runs are correctly reversed (not just the base runs). Team total returns to pre-delivery value. Undo uses the dynamic multiplier, not hardcoded 2x.

---

## Category E: Data Integrity and Stats

### Scenario 13: Full Match Stat Verification

Score a complete match with varied deliveries. After match completion, query the server DB and verify:

**Verify:**
- Every delivery record matches what was scored (runs, extras, wickets, ball number)
- `batting_stats` per player: runs, balls faced, fours, sixes, strike rate, dismissal type
- `bowling_stats` per player: overs bowled, maidens, runs conceded, wickets, economy
- `match_result`: winner, margin, margin type
- `fall_of_wickets`: correct score and over at each wicket
- Scorecard page UI matches all DB values

### Scenario 14: Full Undo Reversal

Score 30 deliveries (mix of runs, extras, wickets), then undo all 30 in reverse order.

**Verify:** After all undos, state returns to initial (0/0, 0.0 overs, original openers at crease, no delivery history). All batter/bowler stats are zeroed. No orphaned data in DB.

### Scenario 15: Scorecard vs DB Consistency

After a completed match, compare every value shown on the Scorecard page against direct DB queries.

**Verify:** Batting table rows match `batting_stats`. Bowling table rows match `bowling_stats`. Extras breakdown matches sum of delivery extras. Fall of wickets matches `fall_of_wickets` table. Commentary entries match `deliveries` table in reverse chronological order.

---

## Category F: Session Stability

### Scenario 16: Kill App Mid-Innings (Persistence Recovery)

Score 3 overs, force-kill the app (not graceful exit), relaunch.

**Verify:** App detects resumable match via `ScoringPersistenceService`. Score, batter stats, bowler stats, over history all restored from Drift snapshot. Scoring can continue from exact point of interruption. No duplicate deliveries in DB after sync.

### Scenario 17: Background App and Return

Score 2 overs, press Home button, wait 60 seconds, return to app.

**Verify:** Scoring page is still visible with correct state. No data loss. WebSocket reconnects if it was disconnected. Next delivery records correctly.

---

## Category G: Multi-Device

### Scenario 18: Viewer Joins Mid-Innings

Scorer scores 3 overs, then viewer connects to live match.

**Verify:** Viewer receives full `match_state` snapshot on join: current score, batting/bowling stats, this-over deliveries, team names. All subsequent deliveries appear in real-time on viewer.

### Scenario 19: Viewer Joins After Match Completion

Scorer completes an entire match. Viewer then connects.

**Verify:** Viewer receives final match state with `status = 'completed'`. Match result displayed. No further updates expected.

---

## Category H: Player Profile and Accumulation

### Scenario 20: Player Profile Across Multiple Matches

Score 2-3 complete matches using the same teams/players. Then open a player's detail page.

**Verify:**
- Career batting stats (total runs, average, strike rate, highest score) accumulated correctly across all matches
- Career bowling stats (total wickets, economy, average, best figures) accumulated correctly
- Match history lists all matches the player participated in, with per-match performance
- Tournament participation shown if matches were part of a tournament
- Stats are consistent between the profile page API response and direct DB query of `player_career_stats`

### Scenario 35: Same Player Stats Accumulate Across Matches

Player A scores 50 in Match 1, 30 in Match 2, gets out both times.

**Verify:** Career batting average = 80/2 = 40.0. Total runs = 80. Innings = 2. Dismissals = 2.

### Scenario 36: Bowler Stats Across Matches

Bowler B takes 3/25 in 4 overs (Match 1) and 2/30 in 4 overs (Match 2).

**Verify:** Career wickets = 5. Career runs conceded = 55. Career overs = 8.0. Career economy = 55/8 = 6.875. Best bowling = 3/25.

---

## Category I: Negative / Error Cases

### Scenario 37: Duplicate Opener Selection

Attempt to select the same player as both opening batters.

**Verify:** UI prevents selection or shows validation error. Both opener slots must have different players.

### Scenario 38: Ineligible Bowler Selection

After an over, attempt to tap on the bowler who just bowled (consecutive-over block).

**Verify:** Bowler row shows as greyed out with "Bowled last over" reason. Tapping does nothing or shows feedback. Only eligible bowlers can be selected.

### Scenario 39: Score After Match Complete

After match is completed, attempt to navigate back to scoring page or record a delivery.

**Verify:** Scoring is blocked. Match complete modal is the terminal state. No way to add deliveries to a completed match without explicit reopen.

### Scenario 40: Empty Playing XI Validation

At the toss step, attempt to proceed without selecting enough players for the Playing XI.

**Verify:** "Next" button is disabled until exactly `players_per_side` players are selected. Validation message shows "X / 11 selected".

---

## Category J: Tournament Flow

### Scenario 41: Tournament Team Reuse Across Runs

Create 16 teams + players once. On subsequent test runs, detect existing teams and skip creation. Only reset tournament/match data.

**Verify:** Second run skips team creation (fast path). Teams and rosters are intact. New tournament can be created with existing teams.

### Scenario 42: Knockout-Only Tournament

Create a tournament with format = "knockout" (no group stage). 8 teams, single elimination.

**Verify:** No group stage fixtures generated. Bracket has QF → SF → Final structure. All 7 matches (4 QF + 2 SF + 1 F) play through correctly. Winner determined.

### Scenario 43: Round Robin Tournament

Create a tournament with format = "round_robin". 4 teams, every team plays every other team.

**Verify:** 6 fixtures generated (C(4,2)). Standings table shows all teams with correct W/L/Pts/NRR after all matches.

### Scenario 44: NRR (Net Run Rate) Calculation

Play multiple group matches where NRR is the tiebreaker (2+ teams tied on points).

**Verify:** NRR calculated correctly per formula: (total runs scored / total overs faced) - (total runs conceded / total overs bowled). Teams with same points ranked by NRR. Standings reflect correct ordering.

### Scenario 45: Bowl-First in Tournament Match

In a tournament fixture, win toss and choose to field first.

**Verify:** Bowling team fields first. After innings transition, toss-winning team bats to chase. Fixture result recorded correctly regardless of toss choice.

### Scenario 46: Tied Match in Group Stage (Points)

Engineer a tied match during group stage (both teams score identical totals).

**Verify:** Both teams awarded 1 point each (not 2 for a win). Standings reflect tied match correctly (Tied column incremented). NRR calculation handles the tie.

### Scenario 47: Tournament Player Career Stats

After completing a full tournament (27 matches), query career stats for players who played in multiple matches.

**Verify:** Career stats aggregate correctly across all tournament matches. Batting average, bowling economy, and total runs/wickets are consistent between player profile API and direct DB query. `player_career_stats` table reflects tournament participation.

### Scenario 48: Match Abandonment Mid-Tournament

Abandon a group stage match mid-innings.

**Verify:** Match marked as "abandoned" in tournament fixtures. No points awarded to either team. Standings correctly exclude the abandoned match from NRR calculation. Remaining fixtures unaffected.

### Scenario 49: Tournament Fixture Navigation

After completing some group matches, navigate between tournament tabs (Overview, Fixtures, Standings, Teams) and back.

**Verify:** Completed fixtures show results. Upcoming fixtures remain tappable. Standings update after each match. No navigation crashes or stale data.

### Scenario 50: Tournament Leaderboard Accuracy

After a full tournament, verify leaderboard categories: Most Runs, Most Wickets, Best Batting Average, Best Bowling Economy, Most Sixes, Most Catches.

**Verify:** Each category shows the correct leader with accurate stats aggregated from all tournament matches. Stats match `batting_stats` and `bowling_stats` tables filtered by tournament matches.

---

## Priority Ranking

### Must Have (Test First)
| Scenario | Reason |
|----------|--------|
| 0 (shared teams) | Infrastructure — all other tests depend on this |
| 12 (full T20) | Longest stress test, catches memory/state issues |
| 13 (stat verification) | Core data integrity — DB correctness |
| 15 (scorecard vs DB) | Presentation layer — UI matches DB |
| 16 (persistence recovery) | Offline-first reliability |
| 20 (player profile) | Cross-match accumulation |
| 21 (free hit chain) | Common cricket scenario, complex state |
| 22 (dismissal types) | 11 of 12 types untested in E2E |
| 26 (overs exhausted) | Second innings-end path |

### Should Have
| Scenario | Reason |
|----------|--------|
| 1-11 (edge cases) | Cover unusual but valid cricket scenarios |
| 23-25 (extras + wicket combos) | Complex interaction paths |
| 27-28 (bowler/strike) | Correctness of eligibility and rotation |
| 29 (bowl-first) | Untested toss path |
| 35-36 (accumulation) | Multi-match stat correctness |
| 41 (tournament team reuse) | Infrastructure — avoid 2hr setup on re-runs |
| 42-43 (knockout/round robin) | Untested tournament formats |
| 47 (tournament career stats) | Cross-tournament stat accumulation |
| 50 (leaderboard accuracy) | Tournament awards correctness |

### Nice to Have
| Scenario | Reason |
|----------|--------|
| 14 (full undo reverse) | Extreme edge case |
| 17-19 (multi-device/stability) | Partially covered by existing tests |
| 30 (target chase exact) | Boundary condition for win detection |
| 31 (declaration) | Voluntary innings end path |
| 32-34 (magic over) | Lower-frequency match scenarios |
| 37-40 (negative cases) | Defensive validation |
| 44 (NRR calculation) | Complex formula, hard to verify manually |
| 45-46 (bowl-first/tied in tournament) | Tournament-specific toss/result paths |
| 48-49 (abandon/navigation) | Edge cases in tournament context |
