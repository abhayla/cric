# CricScores - Scoring Rules & Engine

## 1. Match State Machine

```
  SETUP ──→ TOSS ──→ LIVE ──→ INNINGS_BREAK ──→ LIVE ──→ COMPLETED

  At any point: ──→ ABANDONED
```

> If scores are tied after both innings, the match result is "Match Tied" (status → COMPLETED).

> During `LIVE` status, the current innings is identified by `innings.innings_number` (1 or 2).

### State Transitions

| From | To | Trigger |
|------|----|---------|
| SETUP | TOSS | Both teams selected, match params set |
| TOSS | LIVE | Toss winner/decision recorded, opening players selected |
| LIVE | INNINGS_BREAK | All out OR overs exhausted OR declaration (1st innings) |
| INNINGS_BREAK | LIVE | Opening players for 2nd innings selected |
| LIVE | COMPLETED | All out OR overs exhausted OR target chased OR scores tied (2nd innings) |
| Any | ABANDONED | Manual abandonment by scorer |
| ABANDONED | (previous state) | Reopen by scorer/organizer (only if result not finalized) |

**Reopen rules (ABANDONED → previous state):**
- Only the scorer or tournament organizer can reopen an abandoned match.
- Reopen returns the match to the state it was in before abandonment.
- Confirmation dialog: "This match was abandoned. Resume scoring?"
- Once a `match_result` record has been created and finalized (e.g., tournament standings updated), the match cannot be reopened.

**Abandonment rules:**
- **UI flow:** Scorer taps "Set" button → "Abandon Match" → Confirmation dialog → On confirm: match status → ABANDONED.
- **Stats impact:** Partial match stats DO count in career stats (whatever was played counts).
- **Match result:** A `match_result` record is created with `result_type = 'no_result'`, `winner_team_id = null`, `margin = null`.
- **MVP:** No MVP is calculated for abandoned matches.
- **Tournament impact:** See Section 8.8 for abandoned tournament match rules.

---

## 2. Delivery Processing Pipeline

Every ball bowled follows this exact sequence:

```
Step 1:  VALIDATE delivery input
           ├── Valid batter pair (striker + non-striker, must be different)
           ├── Valid bowler (not same as last over's bowler in consecutive overs)
           ├── Bowler within over limit: matches.max_overs_per_bowler or ceil(totalOvers / 5)
           ├── Valid over/ball number
           ├── Match is in "live" state
           ├── Scorer is authorized (matches.scorer_id must match current user)
           ├── Extras mutual exclusivity: wide + bye is invalid (wide IS an extra type)
           └── Both client and server validate (client for UX speed, server authoritative on sync)

Step 2:  CALCULATE runs
           ├── runs_from_bat (0, 1, 2, 3, 4, 6, or any value for overthrows)
           ├── wide_runs (matches.wide_runs + any additional runs scored off wide)
           ├── no_ball_runs (matches.no_ball_runs + any additional runs scored off no-ball)
           ├── bye_runs (runs off byes)
           ├── leg_bye_runs (runs off leg-byes)
           └── total_runs = sum of all above
           Note: Read wide_runs/no_ball_runs penalty from matches table (default 1, configurable per tournament).

Step 3:  HANDLE extras
           ├── Wide:
           │     ├── +matches.wide_runs (default 1) to bowling figures + extras
           │     ├── Ball does NOT count as legal delivery
           │     ├── Runs do NOT count to batter
           │     └── Additional runs off wide → extras (wides)
           ├── No-ball:
           │     ├── +matches.no_ball_runs (default 1) to extras
           │     ├── Ball does NOT count as legal delivery
           │     ├── Runs from bat DO count to batter
           │     ├── Next delivery is a FREE HIT
           │     └── On free hit: only run out dismissal possible
           ├── Bye:
           │     ├── Runs count to extras (byes), not to batter
           │     └── Runs do NOT count against bowler
           └── Leg-bye:
                 ├── Runs count to extras (leg-byes), not to batter
                 └── Runs do NOT count against bowler

Step 4:  HANDLE wicket (if applicable)
           ├── Record dismissal type + fielder + bowler credit
           ├── Update fall of wickets (score, overs at fall)
           ├── Check if ALL OUT (wickets == players_per_side - 1, NOT hardcoded 10)
           └── New batter required (unless all out)

Step 5:  CALCULATE strike change
           ├── Odd runs from bat → SWAP striker/non-striker
           ├── Even runs (including 0) → NO swap
           ├── End of over → SWAP striker/non-striker
           ├── Wide with odd additional runs → SWAP
           └── Wicket → new batter comes in at striker end
                         (unless caught, then depends on completed runs)

Step 6:  CHECK over completion
           ├── Count only LEGAL deliveries (not wides, not no-balls)
           ├── 6 legal deliveries = over complete
           ├── Mark over as maiden if 0 runs scored off bowler
           │     (byes and leg-byes do NOT break maiden)
           └── Require new bowler selection

Step 7:  CHECK innings completion
           ├── All out (10 wickets) → innings over
           ├── Overs exhausted (max overs bowled) → innings over
           ├── Target chased (2nd innings only) → match over
           └── Declaration (manual, typically longer formats)

Step 8:  PERSIST to local SQLite (Drift) — ALL WRITES IN A SINGLE DRIFT TRANSACTION
           ├── Save delivery record
           ├── Update batting_stats for striker
           ├── Update bowling_stats for bowler
           ├── Update innings totals
           ├── Update fielding_stats (if wicket with fielder)
           ├── Save fall_of_wickets (if wicket)
           ├── Save overs record (if over completed)
           └── Mark as synced=false

Step 9:  SEND via WebSocket
           ├── Send delivery data to server
           ├── Server validates and persists to PostgreSQL
           └── Server broadcasts score_update to all subscribers

Step 10: UPDATE UI state
           ├── Refresh score header
           ├── Refresh current batsmen cards
           ├── Refresh bowler card
           ├── Update current over display
           └── Update run rate
```

---

## 3. Cricket Rules - Detailed

### 3.1 Strike Rotation

```
RULE: After each delivery, determine if striker/non-striker swap.

Scenarios:
  1. Runs from bat = 1, 3, 5 → SWAP (odd runs)
  2. Runs from bat = 0, 2, 4, 6 → NO SWAP (even runs)
  3. End of over → SWAP (regardless of last ball result)
  4. Wide + 1 additional run = SWAP (odd total movement)
  5. Bye/Leg-bye follows same odd/even rule
  6. Wicket (caught): New batter at striker end
  7. Wicket (run out): Scorer MUST indicate "batters had crossed" or "batters had NOT crossed"
     - If batters HAD crossed when run out occurred:
       → Surviving batter is at the END OPPOSITE to where they started
       → New batter enters at the dismissed batter's original end
     - If batters had NOT crossed:
       → Surviving batter stays at the END where they started
       → New batter enters at the dismissed batter's end
     - UI: Wicket dialog shows "Had batters crossed?" toggle for run out dismissals only

End of Over Special:
  - After over swap, if the last ball of previous over was odd runs,
    the swap cancels out (striker stays because: odd_swap + over_swap = no net swap)
  - Implementation: Apply run-based swap first, then apply over swap
```

### 3.2 Wides

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +matches.wide_runs (default 1, configurable per tournament) to extras (wides category)
- Additional runs: If batsmen run on a wide, those runs add to wides too
- Bowler: Wide runs count against bowler's figures
- Stumped off wide: bowler IS credited with the wicket
- Batter: 0 runs credited to batter, 0 balls faced
- Strike: Additional odd runs → swap; even/zero → no swap
- Wicket on wide: Only stumped or run out possible
  - If stumped off wide: wide + stumping recorded
  - If run out off wide: wide + run out recorded
    - total_runs = 1 (wide base) + completed runs before run out
    - ALL runs count as wide_runs (extras) — batter gets 0 bat_runs
    - Bowler concedes all wide_runs
    - Example: Wide + batters complete 1 run + run out = wide_runs: 2, bat_runs: 0, wicket: run out
    - Bowler: wide_runs: 2 conceded, no wicket credit (run out on wide)
  - **UI flow:** Scorer taps Wide → extras panel opens → Wicket button appears in panel.
    Only Stumped and Run Out dismissal types are available. Confirm records the combined delivery.
```

### 3.3 No-Balls

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +matches.no_ball_runs (default 1, configurable per tournament) to extras (no-balls category)
- Bat runs: If batter hits the ball, runs from bat count to batter
- Bowler: No-ball runs + runs from bat count against bowler
- Hit wicket on no-ball: batter is NOT out (no-ball overrides the dismissal)
- Batter: Runs from bat credited, ball NOT counted in balls faced
  (some scoring systems do count it; we follow CricHeroes convention of NOT counting)
- **No-ball + byes:** If no-ball bowled and batter misses but batsmen run:
  - 1 run penalty → `no_ball_runs` (extras, against bowler)
  - Runs completed → `bye_runs` (extras, NOT against bowler, NOT to batter)
  - Total = `no_ball_runs` + `bye_runs`
- Free Hit: Next delivery after a no-ball is a free hit
  - On free hit: Only run out dismissal is possible
  - If the free hit is also a no-ball → another free hit follows
  - **Free hit persists through wides:** If a wide is bowled during a free hit, the next delivery is still a free hit (since a wide is not a legal delivery)
  - **Free hit expiry:** Free hit expires on the next LEGAL delivery. Byes/leg-byes on a free hit delivery ARE legal deliveries, so the free hit is consumed. But if the free hit delivery is a wide or no-ball, the free hit continues to the next delivery.
- Strike: Normal odd/even rules for runs from bat
```

### 3.4 Byes

```
- Ball count: YES, it is a legal delivery
- Runs: Count as extras (byes category)
- Batter: 0 runs credited to batter, 1 ball faced
- Bowler: 0 runs against bowler, 1 ball counted
- Strike: Odd bye runs → swap; even → no swap
- Common scenario: Ball passes wicket-keeper, batsmen run
```

### 3.5 Leg-Byes

```
- Ball count: YES, it is a legal delivery
- Runs: Count as extras (leg-byes category)
- Batter: 0 runs credited to batter, 1 ball faced
- Bowler: 0 runs against bowler, 1 ball counted
- Strike: Odd leg-bye runs → swap; even → no swap
- Maiden: Leg-byes do NOT break a maiden over
```

### 3.6 Five-Run Penalty

```
A 5-run penalty is awarded for specific rule violations (e.g., ball hitting a fielder's helmet
on the ground, deliberate distraction, ball tampering). Rare in amateur cricket but supported.
Matches ICC Standard Match Conditions (Law 41.17).

Recording method: Create a separate penalty delivery in the relevant innings.
  - Delivery record: is_penalty = true, total_runs = 5, bat_runs = 0, is_legal = false
  - bowler_id = NULL (penalty is not bowled by anyone)
  - ball_number = 0 (not a real delivery)
  - over_number = current over (context only)
  - striker_id / non_striker_id = current batters (context only)
  - Penalty runs don't affect any bowler's economy or figures
  - No bowler/batter attribution on penalty delivery

If penalty awarded to BATTING team:
  - penalty_runs = 5 added to batting team's current innings total
  - Create penalty delivery in current innings

If penalty awarded to FIELDING team:
  - penalty_runs = 5 added to fielding team's innings total
  - Uses `innings.penalty_runs` column on the fielding team's innings
  - If fielding team hasn't batted yet, stored for their upcoming innings

- Does NOT count as a delivery (no ball counted, is_legal = false)
- Batter: 0 runs credited, 0 balls faced
- Bowler: 0 runs against bowler
- Strike: No change
- UI flow: Scorer taps "Set" button → "5-Run Penalty" →
  Toggle: "Awarded to Batting Team" / "Awarded to Fielding Team" → Confirm
  (Both directions supported per ICC Laws — batting team penalty adds to current
  batting innings extras; fielding team penalty adds to other team's innings total)
```

### 3.7 Maiden Overs

```
DEFINITION: An over where the bowler concedes ZERO runs from bat AND zero wides/no-balls.

Maiden = true if:
  - runs_from_bat across all 6 legal deliveries = 0
  - wide_runs across entire over = 0
  - no_ball_runs across entire over = 0

Maiden = true EVEN if:
  - Byes or leg-byes were scored (these don't count against bowler)

Maiden = false if:
  - Any runs from bat
  - Any wides (even 1 wide with 0 additional runs)
  - Any no-balls
```

### 3.8 Powerplay Rules (MVP)

```
MVP SCOPE: Display-only — no fielding restriction enforcement.

- Show "PP" badge on over numbers during powerplay overs (1 to powerplay_overs)
- powerplay_overs is configured per tournament (or null for no powerplay)
- Standalone matches: no powerplay (null by default)
- No fielding position tracking per delivery in MVP
- Full fielding restriction enforcement deferred to post-MVP
  when field placement feature is added
```

### 3.9 Overthrow Attribution

```
All runs from overthrows are attributed to the batter on strike and conceded by the bowler:

Case 1 — Batter hits the ball + overthrow:
  - bat_runs = initial shot runs + overthrow runs (all credited to batter)
  - bowler concedes all bat_runs
  - Example: Batter hits 1, overthrow adds 3 → bat_runs: 4, bowler_runs: 4

Case 2 — Bye/Leg-bye + overthrow (no bat contact):
  - All runs are extras of the same type (bye_runs or leg_bye_runs)
  - Bowler concedes 0 runs (byes/leg-byes are not against bowler)
  - Example: Leg-bye 1 + overthrow 3 → leg_bye_runs: 4, bowler_runs: 0

UI: Scorer uses the "..." (Other) button to enter the total runs including overthrows.
```

### 3.10 Innings Completion

```
An innings ends when ANY of:

1. ALL OUT: `players_per_side - 1` wickets fallen (NOT hardcoded to 10)
   - Team has `players_per_side` players, `players_per_side - 1` can be dismissed (one stays not out)
   - Batting team can have fewer active batters if players retired hurt
   - **Retired hurt last-man rule:** If after a wicket or retirement, fewer than 2 active batters remain (all others dismissed or retired out), the innings ends. A retired hurt batter CAN return, so they do not count as permanently unavailable. If a retired hurt batter is the only option, the "Select New Batter" dialog shows them marked "Retired Hurt — can return".

2. OVERS EXHAUSTED: Maximum overs bowled
   - T20: 20 overs
   - ODI: 50 overs
   - Custom: whatever was set

3. TARGET CHASED (2nd innings only):
   - Batting team's total exceeds 1st innings total
   - Match ends immediately (mid-over possible)

4. DECLARATION (manual):
   - Batting team declares voluntarily
   - Enabled for ALL formats (T20, ODI, custom) — amateur cricket uses custom rules;
     T20 declarations are rare but valid
   - No format-based restriction
   - **UI flow:** Scorer taps "Set" button in action bar → menu shows "Declare Innings" option
     → Confirmation dialog: "Declare innings at {score}/{wickets} ({overs})? This cannot be undone."
     → Yes/No → On confirm: innings marked completed with `completed_reason = 'declared'`
```

### 3.11 Dismissal Types

| # | Type | Code | Fielder Required | Bowler Credited |
|---|------|------|------------------|-----------------|
| 1 | Bowled | b | No | Yes |
| 2 | Caught | c | Yes (catcher) | Yes |
| 3 | LBW | lbw | No | Yes |
| 4 | Run Out | ro | Yes (thrower) | No |
| 5 | Stumped | st | Yes (wicket-keeper) | Yes |
| 6 | Hit Wicket | hw | No | Yes |
| 7 | Caught & Bowled | c&b | No (bowler = catcher) | Yes |
| 8 | Retired Hurt | rh | No | No |
| 9 | Retired Out | ret | No | No |

| 10 | Timed Out | to | No | No |
| 11 | Obstructing Field | of | No | No |

> **Types 10-11 (Timed Out, Obstructing Field) are deferred to post-MVP.** They remain in the DB enum but are greyed out in the wicket dialog. Extremely rare in amateur cricket. "Handled Ball" is no longer a separate dismissal — it was merged into "Obstructing the Field" in the 2017 Laws of Cricket.

**Note:** On a free hit delivery, only "Run Out" (type 4) is possible.

**Retired Hurt / Retired Out rules:**
- Neither counts as a wicket for all-out purposes (10 "real" wickets = all out).
- **Retired Hurt (rh):** Temporary — batter can return at the fall of the next wicket. Marked with `is_retired_hurt = true` in `batting_stats`.
- **Retired Out (ret):** Permanent — batter cannot return. Treated as "out" for stats.
- **UI flow:** Scorer taps Wicket → Retired → submenu: "Retired Hurt" / "Retired Out". New batter dialog follows immediately.
- **Return from Retired Hurt:** When a new wicket falls, if a retired hurt batter is available, the "Select New Batter" dialog shows them as an option (marked as "Retired Hurt — can return").

**Caught dismissal — runs before catch:** If batsmen complete runs before a catch is taken, the runs do NOT count (Law 33). The batter is credited with 0 runs on a caught dismissal. Any completed runs are voided.

**New batter position by dismissal type:**
- **Bowled, LBW, Hit Wicket, Stumped:** Striker was dismissed → new batter takes the striker's end.
- **Caught, Caught & Bowled:** New batter at striker's end. (If batsmen crossed before catch, non-striker returns to original end.)
- **Run Out:** Depends on "Had batters crossed?" (see Section 3.1, item 7).
- **Retired Hurt / Retired Out:** New batter replaces the retiring batter at their current end.

---

## 4. Undo Functionality

```
UNDO removes the most recent delivery and reverses ALL state changes:

1. Remove delivery record from local DB
2. Reverse batting stats:
   - Subtract runs from batter
   - Subtract balls faced (if legal delivery)
   - Decrement fours/sixes if applicable
3. Reverse bowling stats:
   - Subtract runs conceded
   - Subtract ball count from over
   - Decrement wickets if applicable
4. Reverse innings totals:
   - Subtract total runs
   - Subtract extras
   - Decrement wickets if applicable
5. Reverse strike change:
   - If runs caused a swap, swap back
   - If over ended, reverse over swap
6. Reverse wicket:
   - Remove fall of wickets entry
   - Restore dismissed batter to striker/non-striker position
   - Remove fielding stat credit
7. Handle edge cases:
   - Undo first ball of over → go back to previous over
   - Undo first ball of innings → error (can't undo)
   - Undo after over change → reopen previous over
8. Send undo via WebSocket to update all viewers

UNDO PENALTY DELIVERY (5-run penalty):
  - Remove the penalty delivery record (is_penalty = true)
  - Reverse penalty_runs from innings total
  - If penalty was to fielding team's innings, reverse innings.penalty_runs
  - Same constraint: only the LAST delivery can be undone

CONSTRAINTS:
  - Only the LAST delivery can be undone
  - Only the scorer can undo
  - Cannot undo after innings/match completion (must reopen first — see Section 4.1)
  - Maximum undo chain: implementation allows multiple consecutive undos
  - **Blocked after transition:** Undo is available only for the most recent delivery
    AND only before the next state transition (new batter confirmed or new bowler confirmed).
    Once the scorer confirms a new batter selection or new bowler selection, the
    previous delivery cannot be undone. This prevents complex state reversal across
    player selection boundaries.
```

### 4.1 Reopen After Completion

If the scorer needs to undo after an innings or match has been marked completed (e.g., last ball was scored incorrectly), they must reopen first.

**UI flow:** Scorer taps "Set" button → contextual menu shows:
- **"Reopen Last Innings"** — Only shown when the current innings just completed (innings break or match just ended). Reverses the completion, returns innings to LIVE state. Scorer can then undo the last delivery.
- **"Reopen Match"** — Only shown when match status is COMPLETED. Reverses match completion, returns to LIVE state for the last active innings. Scorer can then undo or continue scoring.

**Rules:**
- Only the scorer can reopen.
- Reopening removes the `match_result` record (if match was completed).
- Reopening an innings sets `is_completed = false` and clears `completed_reason`.
- After reopening, normal undo functionality becomes available again.

---

## 5. MVP Algorithm

Based on CricHeroes-style MVP point system:

### 5.1 Batting Points

```
Base Points:
  - 1 point per 10 runs scored

Strike Rate Bonus (compared to team's average SR in that innings):
  - If batter SR > team SR: +0.5
  - If batter SR < team SR: -0.5
  - If batter SR within 10% of team SR: 0

Milestone Bonuses:
  - 50 runs: +2 points
  - 100 runs: +5 points (replaces 50 bonus, not additive)

Boundary Bonuses:
  - Per four: +0.1 points
  - Per six: +0.2 points

Example:
  R. Sharma: 65 runs (40 balls), 6 fours, 3 sixes, team SR = 130
  - Base: 65/10 = 6.5
  - SR: 162.5 vs 130 → above team SR → +0.5
  - Milestone: 50+ → +2
  - Fours: 6 * 0.1 = 0.6
  - Sixes: 3 * 0.2 = 0.6
  - Total Batting Points = 10.2
```

### 5.2 Bowling Points

```
Base Points:
  - 3 points per wicket

Economy Bonus (compared to match average economy):
  - If bowler economy < match average: +1
  - If bowler economy > match average: -1
  - If within 0.5 of match average: 0

Maiden Over Bonus:
  - +1 point per maiden over

Milestone Bonuses:
  - 3 wickets: +3 points
  - 5 wickets: +5 points (replaces 3W bonus, not additive)

Example:
  J. Bumrah: 4 overs, 2 maidens, 18 runs, 3 wickets, match avg economy = 7.5
  - Base: 3 * 3 = 9
  - Economy: 4.5 vs 7.5 → below average → +1
  - Maidens: 2 * 1 = 2
  - Milestone: 3 wickets → +3
  - Total Bowling Points = 15.0
```

### 5.3 Fielding Points

```
  - Catch: +1.5 points
  - Run out (direct hit): +2.0 points
  - Run out (assist/relay throw): +1.0 point
  - Stumping: +1.5 points

Example:
  V. Kohli: 2 catches, 1 run out (direct)
  - Catches: 2 * 1.5 = 3.0
  - Run out: 1 * 2.0 = 2.0
  - Total Fielding Points = 5.0
```

### 5.4 Total MVP Score

```
MVP Score = Batting Points + Bowling Points + Fielding Points

Rankings sorted by total MVP score descending.
Tie-breaker: Batting points > Bowling points > Fielding points
```

---

## 6. Scoring Page UI Interactions

### Scoring Page Layout

The scoring page uses a fixed-scroll-fixed layout:

| Zone | Position | Content |
|------|----------|---------|
| **Score header** | Fixed top | Total score, overs, current run rate, target (2nd innings), team names |
| **Middle area** | Scrollable | Current batter card (striker highlighted), current bowler card, current over display, last few overs summary |
| **Run buttons + extras** | Fixed bottom | Run buttons row (0, 1, 2, 3, 4, 6, ...) and extras row (Wide, No Ball, Bye, Leg Bye, Wicket) |

No app bar on the scoring page — full-screen immersive layout. The "Set" button (for declaration, abandonment, penalties, reopen) is positioned in the score header area.

**"Set" button menu items (6 total):**
1. **Declare Innings** — End current innings voluntarily (see Section 3.8)
2. **Abandon Match** — Abandon match entirely (see Section 1, Abandonment rules)
3. **5-Run Penalty** — Award 5-run penalty to either team (see Section 3.6)
4. **Bowler Injured** — Replace bowler mid-over (see Section 6.4b)
5. **Reopen Last Innings** — *(contextual, only shown after innings completion)* Reverses innings completion (see Section 4.1)
6. **Reopen Match** — *(contextual, only shown when match is COMPLETED or ABANDONED)* Reverses match/abandoned completion (see Section 4.1 and Section 1 Reopen rules)

### 6.1 Run Buttons

| Button | Action |
|--------|--------|
| **0** (dot) | Record dot ball, no runs |
| **1** | 1 run, swap strike |
| **2** | 2 runs, keep strike |
| **3** | 3 runs, swap strike |
| **4** | Boundary four, keep strike, mark `is_boundary_four` |
| **6** | Boundary six, keep strike, mark `is_boundary_six` |
| **...** (Other) | Opens number picker (0-9) for any run value (overthrows: 5, 7, etc.) |

### 6.2 Extras Buttons

| Button | Action |
|--------|--------|
| **Wide** | Opens sub-panel: [+0] [+1] [+2] [+3] [+4] [Custom] for additional runs. Wicket button available (only Stumped/Run Out). |
| **No Ball** | Opens sub-panel: runs from bat [0-6] [Custom] + records free hit for next ball |
| **Bye** | Opens sub-panel: [1] [2] [3] [4] [Custom] for bye runs |
| **Leg Bye** | Opens sub-panel: [1] [2] [3] [4] [Custom] for leg-bye runs |

### 6.3 Wagon Wheel Zone Selection

After recording a boundary (4 or 6), an optional zone selection overlay appears:
- Shows a 12-zone circle (matching the `wagon_wheel_zones` table).
- Scorer taps the zone where the shot was hit.
- "Skip" button to dismiss without selecting a zone (sets `wagonWheelZoneId = null`).
- Non-boundary deliveries (0, 1, 2, 3, extras) skip this step entirely.
- Zone data is used for the wagon wheel analytics chart.

### 6.4 Wicket Dialog

When **WICKET** is tapped:
1. Select dismissal type (bowled, caught, lbw, run out, etc.)
2. If fielder required → select fielder from fielding team roster
3. If run out → also ask: how many runs completed before run out?
4. If run out → ask: which batter was run out? (striker or non-striker)
5. If run out → show "Direct Hit?" toggle (default off). If on, records `fielding_stats.direct_hits` for the fielder. If off, records as relay/assist run out.
6. Confirm wicket → record delivery + wicket
7. If not all out → show "Select New Batter" dialog

### 6.4b Bowler Injury Mid-Over

A bowler cannot change mid-over under normal circumstances. However, if the bowler is injured:

1. Scorer taps "Set" button → "Bowler Injured" option
2. "Select Replacement Bowler" dialog opens with eligible bowlers:
   - Any bowler not at max overs qualifies
   - Previous-over bowler CAN replace (exception to consecutive-over rule per ICC Law 22.7)
   - Bowlers already injured in this match are excluded from the list
3. The replacement bowler completes the remaining balls of the over
4. The replacement bowler CANNOT bowl the NEXT over (consecutive over rule applies)
5. Both bowlers' stats are recorded for the over: original bowler's deliveries + replacement bowler's deliveries

### 6.5 End of Over Flow

After 6th legal delivery:
1. Show over summary (runs, wickets in that over)
2. Show "Select Next Bowler" dialog
3. Prevent same bowler as previous over (consecutive over rule)
4. After bowler selected → swap strike → continue scoring

**Wicket on last ball of over:** If the 6th legal delivery is a wicket:
1. Process wicket first → show "Select New Batter" dialog
2. Then show over summary → "Select Next Bowler" dialog
3. Order: Wicket → New Batter → New Bowler (always process wicket before over completion)

### 6.6 Innings Transition

When innings ends:
1. Show innings summary (total runs, wickets, overs, run rate)
2. Show extras breakdown
3. Show top performers
4. "Start 2nd Innings" button
5. Select opening batsmen for chasing team
6. Select opening bowler for bowling team
7. Display target prominently in score header

---

## 7. Over Display Notation

Each ball in the current over is displayed with standard cricket notation:

| Symbol | Meaning |
|--------|---------|
| `.` | Dot ball (0 runs) |
| `1` | 1 run |
| `2` | 2 runs |
| `3` | 3 runs |
| `4` | Boundary four |
| `6` | Boundary six |
| `W` | Wicket |
| `Wd` | Wide |
| `Nb` | No ball |
| `B` | Bye |
| `Lb` | Leg bye |
| `1Wd` | Wide + 1 run |
| `1Nb` | No-ball + 1 run from bat |

Example over: `. 1 4 W . Wd 2 6` (6 legal balls + 1 wide)

---

## 8. Tournament Rules

### 8.1 Tournament State Machine

```
  DRAFT ──→ REGISTRATION ──→ LIVE ──→ COMPLETED
```

| From | To | Trigger |
|------|----|---------|
| DRAFT | REGISTRATION | Organizer opens registration |
| REGISTRATION | LIVE | Teams finalized, fixtures generated |
| LIVE | COMPLETED | All fixtures completed or manual completion |

- Only the tournament organizer (`tournaments.created_by`) can trigger transitions.
- Moving to LIVE requires at least 2 teams and generated fixtures.
- Moving to COMPLETED is automatic when all fixtures are completed, or manual by the organizer.

### 8.2 Tournament Formats

**Round-Robin:**
- Every team plays every other team once.
- Total fixtures = N × (N-1) / 2 where N = number of teams.
- All fixtures are in `round_type = 'group'`.
- Winner determined by points table (Section 8.4 tiebreakers).

**Knockout:**
- Single-elimination bracket.
- If odd number of teams, the highest seed gets a bye in the first round.
- Standard bracket rounds: Quarter-Final (8 teams), Semi-Final (4 teams), Final (2 teams).
- Optional third-place match (`has_third_place_match` flag).
- Seeding: based on `tournament_teams.seed_number` (set by organizer).

**Group Stage + Knockout:**
- Teams divided into `num_groups` groups.
- Group stage: round-robin within each group (fixtures with `round_type = 'group'`).
- Top `qualify_per_group` teams from each group advance to knockout.
- Knockout bracket auto-seeded: A1 vs B2, B1 vs A2, C1 vs D2, D1 vs C2 (cross-group seeding).
- Same-position tiebreak between groups by NRR.

### 8.3 Net Run Rate (NRR) Calculation

```
NRR = (Total Runs Scored / Total Overs Faced) - (Total Runs Conceded / Total Overs Bowled)
```

**Rules:**
1. Cumulative across ALL tournament matches for a team.
2. If a team is ALL OUT, use the full quota of overs (not actual overs faced).
3. If NOT all out, use actual overs faced (decimal: 18.4 overs = 18 + 4/6 = 18.667).
4. Overs decimal conversion: X.Y overs = X + (Y / 6).
5. No-result matches are EXCLUDED from NRR calculation.
6. Display format: 3 decimal places, with +/- sign prefix (e.g., +1.234, -0.567).

**Worked Example:**

Team A plays 2 matches in a tournament (20 overs per match):

| Match | Batting | Bowling |
|-------|---------|---------|
| Match 1 | Scored 180/4 in 20.0 overs | Conceded 150/10 (all out in 18.2 overs → use 20.0) |
| Match 2 | Scored 160/10 (all out in 19.1 → use 20.0) | Conceded 140/6 in 20.0 overs |

```
Total Runs Scored   = 180 + 160 = 340
Total Overs Faced   = 20.0 + 20.0 = 40.0 (both use full quota — Match 1 batted full, Match 2 all out)
Total Runs Conceded = 150 + 140 = 290
Total Overs Bowled  = 20.0 + 20.0 = 40.0 (Match 1 opponent all out → full quota, Match 2 bowled full)

NRR = (340 / 40.0) - (290 / 40.0) = 8.500 - 7.250 = +1.250
```

### 8.4 Tiebreaker Order (Fixed)

When two or more teams have equal points, resolve in this order:

1. **Points** — Higher wins.
2. **Net Run Rate** — Higher wins.
3. **Head-to-head result** — Winner of the direct match between the tied teams.
4. **If still tied** — Joint rank (position shared, next rank skips).

This order is fixed and not configurable per tournament.

### 8.5 Qualification Rules

- Configurable top-N per group (`qualify_per_group`, default 2).
- Knockout bracket seeding from group stage:
  - 2 groups: A1 vs B2, B1 vs A2
  - 4 groups: A1 vs B2, C1 vs D2, B1 vs A2, D1 vs C2
- Same-position tiebreak across groups: resolved by NRR.
- If `qualify_per_group` exceeds teams in a group, all teams in that group qualify.

### 8.6 Tournament Match Integration

When a match has `tournament_id` set (i.e., it is a tournament match):

- The same scoring engine pipeline (Section 2) applies — no changes to delivery processing.
- **On match completion** (status → COMPLETED), the following post-completion hooks fire:
  1. Determine match result (winner, tie, no result) from `match_result`.
  2. Award points to both teams per the tournament's point configuration (`points_win`, `points_tie`, `points_no_result`, `points_loss`).
  3. Recalculate NRR for both teams using cumulative data from `tournament_standings`.
  4. Recalculate `position` for all teams in the relevant group (or entire tournament for round-robin/knockout).
  5. Update `tournament_standings` rows for both teams.
  6. If all group stage fixtures are complete and tournament format is `group_knockout`, auto-populate knockout bracket fixtures with qualified teams.
- These hooks run server-side only. The Flutter app fetches updated standings via the API.

### 8.7 Match Rules Inheritance from Tournament

When a scorer starts a match from a tournament fixture, the match inherits these fields from the tournament configuration:

| Tournament Field | Match Equivalent | Behavior |
|-----------------|-----------------|----------|
| `overs_per_match` | `total_overs` | Locked — not editable per match |
| `ball_type_id` | `ball_type_id` | Locked |
| `players_per_side` | Playing XI size | Locked — match_players enforces this count instead of hardcoded 11 |
| `max_overs_per_bowler` | Bowler over limit | Locked — overrides default ceil(totalOvers/5) formula |
| `wide_runs` | Wide penalty runs | Locked — scoring engine uses this instead of default 1 |
| `no_ball_runs` | No-ball penalty runs | Locked — scoring engine uses this instead of default 1 |
| `powerplay_overs` | Powerplay overs | Locked — display-only "PP" badge for MVP (see Section 3.8) |

**Match creation from fixture flow:**
1. Scorer navigates to fixture in tournament detail
2. Taps "Start Match" on an unplayed fixture (one with `match_id = NULL`)
3. System creates match record with:
   - `tournament_id` = fixture's tournament_id
   - `home_team_id` / `away_team_id` from fixture
   - `total_overs` = tournament.overs_per_match
   - `ball_type_id` = tournament.ball_type_id
   - `format` = derived from overs (≤20 → "T20", ≤50 → "ODI", else "custom")
   - `scorer_id` = current user
4. `tournament_fixtures.match_id` updated to point to new match
5. Match proceeds through normal flow: SETUP → TOSS → LIVE → COMPLETED

**Standalone matches** (tournament_id = null) continue to use defaults:
- Players per side = 11
- Bowler over limit = ceil(totalOvers/5)
- Wide runs = 1, No-ball runs = 1
- No powerplay

### 8.8 Abandonment Impact on Tournaments

When a tournament match is abandoned:

- **Result:** "No Result" (NR) — `match_result.result_type = 'no_result'`
- **Points:** Each team receives NR points (default 1, per `tournaments.points_no_result`)
- **NRR:** Abandoned match is **excluded** from NRR calculation (per Section 8.3, rule 5)
- **Career stats:** Partial stats from the abandoned match **DO count** in career stats (per Section 1 abandonment rules)
- **Standings:** `tournament_standings.no_result` column incremented for both teams

---

## 9. Super Over Rules

### 9.1 Trigger Condition

A super over is triggered when ALL of these conditions are met:
1. Match is a tournament match (`tournament_id` is not null)
2. Fixture `round_type` is a knockout round: "quarter_final", "semi_final", "final", or "third_place"
3. Match result is tied (both innings completed, scores equal)

**Non-knockout matches** (group stage, round-robin) that end in a tie are recorded as "tie" with points awarded per the tournament's `points_tie` config. No super over.

**Standalone matches** (tournament_id = null) that end in a tie are recorded as "Match Tied" (existing behavior). No super over.

### 9.2 Super Over Procedure

1. **Batting order:** The team that batted **second** in regulation bats **first** in the super over.
2. **Innings creation:** 2 additional innings records with `is_super_over = true`, `super_over_number = 1`.
3. **Over limit:** 1 over (6 legal deliveries) per team.
4. **Player limit:** 3 batters per team (2 at crease + 1 reserve who enters if a wicket falls). Any bowler from the Playing XI can bowl.
5. **Wicket limit:** 2 wickets per side. When the 2nd wicket falls, the super over innings for that team ends (only 3 batters, 2 can be dismissed).
6. **Bowler:** Any bowler from the Playing XI. No restriction on who bowled in regulation.
7. **Extras, strike rotation, free hits:** All standard delivery pipeline rules (Section 2) apply identically.

### 9.3 Super Over Tie (Sudden Death)

If the super over also ends in a tie:
1. Another super over is played (`super_over_number` increments: 2, 3, ...).
2. **Different bowlers must be used** for each subsequent super over — the bowler from the previous super over cannot bowl again in the next one.
3. Same batting order rule applies: the team that batted second in the previous super over bats first in the next.
4. Repeat until a winner is determined.

### 9.4 Result Recording

- `match_result.result_type` = "super_over"
- `match_result.winner_team_id` = winning team
- `match_result.margin` = runs margin in the deciding super over
- `match_result.summary` = e.g., "Mumbai Warriors won in Super Over"

### 9.5 Stats Impact

- **Super over stats do NOT count toward:**
  - Player career stats (`player_career_stats`)
  - Tournament leaderboard rankings
  - Batting/bowling averages and aggregates
- **Super over stats DO count toward:**
  - Match result determination only
  - Match scorecard display (shown as separate super over section)

### 9.6 Scoring Engine Integration

The super over uses the **same delivery processing pipeline** (Section 2, Steps 1-10) with these modifications:

| Pipeline Step | Modification for Super Over |
|--------------|----------------------------|
| Step 1: VALIDATE | Wicket limit = 2 (not 10). Over limit = 1 (not totalOvers). Bowler over limit not applicable (only 1 over). |
| Step 4: HANDLE wicket | ALL OUT check: 2 wickets = super over innings ends (3 batters, 2 dismissable). |
| Step 7: CHECK innings completion | All out = 2 wickets. Overs exhausted = 1 over. Target chased = super over target. |
| Step 8: PERSIST | Delivery saved to innings with `is_super_over = true`. |

### 9.7 UI Flow

1. After regulation match ends tied in a knockout fixture:
   - Match Complete modal shows "Match Tied" result text
   - Modal has "Start Super Over" button (replaces "View Scorecard" as primary CTA)
   - Secondary button: "Back to Home" (outlined)
   - Standalone match tie → COMPLETED with "Match Tied" (no super over option)
2. Tapping "Start Super Over" opens the Super Over Setup stepper (3 steps):
   - Step 1: "Team A Batters" — Select 3 from Playing XI (checkboxes) + mark striker/non-striker
   - Step 2: "Team A Bowler" — Select 1 from Playing XI (radio)
   - Step 3: "Team B Batters + Bowler" — Same as steps 1+2 combined
   - Footer: "Start Super Over" button
   - Batting order auto-determined: team that batted 2nd in regulation goes first (per ICC)
3. Super over scoring page uses the same scoring controls
4. Super over section shown separately on the scorecard
5. If super over ties → repeat prompt for another super over

---

## 10. Deferred to Post-MVP

The following scoring features are intentionally deferred. They remain in the DB enum/schema but are not implemented in the MVP scoring pipeline or UI:

| Feature | Reason | Notes |
|---------|--------|-------|
| **Mankad (run-out before delivery)** | Requires fundamentally different recording flow — no delivery record, just a wicket. Very rare in amateur cricket. | The 10-step pipeline assumes a ball has been bowled. Mankad would need a separate "non-delivery wicket" flow. |
| **Timed Out dismissal** | Extremely rare. No ball bowled, doesn't fit delivery pipeline. | Keep in DB enum, grey out in wicket dialog. |
| **Obstructing the Field dismissal** | Extremely rare in amateur cricket. | Keep in DB enum, grey out in wicket dialog. (Note: "Handled Ball" was merged into this per 2017 Laws.) |
| **Wagon Wheel zone selection during scoring** | Dramatically simplifies scoring flow. Zone selection adds friction to every boundary. | Remove `wagonWheelZoneId` from delivery payload. Post-MVP: add zone picker after boundary shots. |
| **DLS calculations** | Complex, not needed for most amateur formats. | |
| **Shot type tracking** | No `shot_types` table in MVP. | |
| **Partnerships** | Can be computed from deliveries post-hoc. | |
