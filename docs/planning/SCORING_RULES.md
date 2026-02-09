# CricApp - Scoring Rules & Engine

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

---

## 2. Delivery Processing Pipeline

Every ball bowled follows this exact sequence:

```
Step 1:  VALIDATE delivery input
           ├── Valid batter pair (striker + non-striker)
           ├── Valid bowler (not same as last over's bowler in consecutive overs)
           ├── Valid over/ball number
           └── Match is in "live" state

Step 2:  CALCULATE runs
           ├── runs_from_bat (0, 1, 2, 3, 4, 6)
           ├── wide_runs (1 + any additional runs scored off wide)
           ├── no_ball_runs (1 + any additional runs scored off no-ball)
           ├── bye_runs (runs off byes)
           ├── leg_bye_runs (runs off leg-byes)
           └── total_runs = sum of all above

Step 3:  HANDLE extras
           ├── Wide:
           │     ├── +1 run to bowling figures + extras
           │     ├── Ball does NOT count as legal delivery
           │     ├── Runs do NOT count to batter
           │     └── Additional runs off wide → extras (wides)
           ├── No-ball:
           │     ├── +1 run to extras
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
           ├── Check if ALL OUT (10 wickets = innings over)
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

Step 8:  PERSIST to local SQLite (Drift)
           ├── Save delivery record
           ├── Update batting_stats for striker
           ├── Update bowling_stats for bowler
           ├── Update innings totals
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
  7. Wicket (run out): Depends on which end the dismissed batter was at
     - If striker run out at non-striker end → new batter at non-striker end
     - If non-striker run out → new batter at non-striker end
     - Crossed or not crossed matters

End of Over Special:
  - After over swap, if the last ball of previous over was odd runs,
    the swap cancels out (striker stays because: odd_swap + over_swap = no net swap)
  - Implementation: Apply run-based swap first, then apply over swap
```

### 3.2 Wides

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +1 to extras (wides category)
- Additional runs: If batsmen run on a wide, those runs add to wides too
- Bowler: Wide runs count against bowler's figures
- Batter: 0 runs credited to batter, 0 balls faced
- Strike: Additional odd runs → swap; even/zero → no swap
- Wicket on wide: Only stumped or run out possible
  - If stumped off wide: wide + stumping recorded
  - If run out off wide: wide + run out recorded (any runs completed count)
```

### 3.3 No-Balls

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +1 to extras (no-balls category)
- Bat runs: If batter hits the ball, runs from bat count to batter
- Bowler: No-ball runs + runs from bat count against bowler
- Batter: Runs from bat credited, ball NOT counted in balls faced
  (some scoring systems do count it; we follow CricHeroes convention of NOT counting)
- Free Hit: Next delivery after a no-ball is a free hit
  - On free hit: Only run out dismissal is possible
  - If the free hit is also a no-ball → another free hit follows
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

### 3.6 Maiden Overs

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

### 3.7 Innings Completion

```
An innings ends when ANY of:

1. ALL OUT: 10 wickets fallen
   - Team has 11 players, 10 can be dismissed (one stays not out)
   - Batting team can have fewer than 11 if players unavailable (retired hurt, etc.)

2. OVERS EXHAUSTED: Maximum overs bowled
   - T20: 20 overs
   - ODI: 50 overs
   - Custom: whatever was set

3. TARGET CHASED (2nd innings only):
   - Batting team's total exceeds 1st innings total
   - Match ends immediately (mid-over possible)

4. DECLARATION (manual):
   - Batting team declares (typically Test cricket, but allowed)
```

### 3.8 Dismissal Types

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
| 12 | Handled Ball | hb | No | No |

**Note:** On a free hit delivery, only "Run Out" (type 4) is possible.

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

CONSTRAINTS:
  - Only the LAST delivery can be undone
  - Only the scorer can undo
  - Cannot undo after innings/match completion (must reopen first)
  - Maximum undo chain: implementation allows multiple consecutive undos
```

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

### 6.1 Run Buttons

| Button | Action |
|--------|--------|
| **0** (dot) | Record dot ball, no runs |
| **1** | 1 run, swap strike |
| **2** | 2 runs, keep strike |
| **3** | 3 runs, swap strike |
| **4** | Boundary four, keep strike, mark `is_boundary_four` |
| **6** | Boundary six, keep strike, mark `is_boundary_six` |

### 6.2 Extras Buttons

| Button | Action |
|--------|--------|
| **Wide** | Opens sub-panel: [+0] [+1] [+2] [+3] [+4] for additional runs |
| **No Ball** | Opens sub-panel: runs from bat [0-6] + records free hit for next ball |
| **Bye** | Opens sub-panel: [1] [2] [3] [4] for bye runs |
| **Leg Bye** | Opens sub-panel: [1] [2] [3] [4] for leg-bye runs |

### 6.3 Wicket Dialog

When **WICKET** is tapped:
1. Select dismissal type (bowled, caught, lbw, run out, etc.)
2. If fielder required → select fielder from fielding team roster
3. If run out → also ask: how many runs completed before run out?
4. If run out → ask: which batter was run out? (striker or non-striker)
5. Confirm wicket → record delivery + wicket
6. If not all out → show "Select New Batter" dialog

### 6.4 End of Over Flow

After 6th legal delivery:
1. Show over summary (runs, wickets in that over)
2. Show "Select Next Bowler" dialog
3. Prevent same bowler as previous over (consecutive over rule)
4. After bowler selected → swap strike → continue scoring

### 6.5 Innings Transition

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
