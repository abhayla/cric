# Gap Analysis Working Document (Q11-62)

This document contains all context needed to resolve questions 11-62 of the CricApp gap analysis. It is self-contained -- all relevant excerpts from planning docs are included below.

---

## Questions to Resolve

### Category 2: Missing Database Infrastructure

| # | Question | Context | Details |
|---|----------|---------|---------|
| 11 | **Materialized view SQL** | Phase 5 (Player Profiles) | 5 views named but no SQL definitions written. Needed before career stats work. |

### Category 3: Missing API Endpoints (5 items)

| # | Question | Context | Details |
|---|----------|---------|---------|
| 12 | **No opening players selection endpoint** | TOSS -> LIVE transition | SCORING_RULES requires opening batsmen + bowler selected, but no endpoint to submit this. |
| 13 | **No Playing XI selection endpoint** | US-10, Match Setup | No way for captain to select 11 players from roster before match. |
| 14 | **Incomplete endpoint specs** | Implementation | `PUT /teams/:id` (no request body), `GET /players/:id` (no response), `GET /matches` (no response shape), `DELETE /teams/:id/players/:pid` (no response). |
| 15 | **Auth verify `token` field** | Auth flow | Response has `"token": "server_jwt_if_needed"` -- undecided if server issues its own JWT or uses Firebase JWT directly. |
| 16 | **Sync pull response shapes** | Offline sync | Shows placeholder `"deliveries": ["..."]` but no actual entity shapes defined. |

### Category 4: Underspecified Scoring Engine Logic (15 items)

| # | Question | Context | Details |
|---|----------|---------|---------|
| 17 | **Run out crossed/not-crossed** | Mentioned as important but exact logic not specified. Which end does the non-dismissed batter stay at? |
| 18 | **Retired hurt flow** | No UI flow. Does it count as a wicket for all-out (10 wickets)? How does a player return? Is it via the Wicket dialog? |
| 19 | **Stumped off wide** | Wide and wicket on same delivery. Does scorer tap Wide first then Wicket? Combined action? |
| 20 | **No-ball + byes interaction** | If no-ball bowled and batter misses but they run -- is it no-ball + byes, or just no-ball runs? |
| 21 | **Wicket on last ball of over** | Does over complete first (new bowler dialog) then new batter dialog? Or wicket first? |
| 22 | **New batter position for bowled/LBW/stumped/hit_wicket** | Only caught and run out positions specified. Others should be striker end but not stated. |
| 23 | **Wide + run out run classification** | Completed runs on a wide+run out -- do they count as wides or bat runs? |
| 24 | **Free hit continuation through wides** | No-ball -> free hit -> wide -> is next delivery still free hit? (ICC: yes, since wide isn't a legal delivery) |
| 25 | **5 runs from bat (overthrows)** | Run buttons only show 0,1,2,3,4,6. No way to record 5 runs. |
| 26 | **Wide +5/+6 overthrows** | Wide sub-panel only shows +0 to +4. Overthrows can exceed this. |
| 27 | **Declaration flow** | Mentioned as innings completion condition but no UI button, dialog, or flow specified. |
| 28 | **Match abandonment effect on stats** | ABANDONED reachable from any state. Do partial match stats count in career? What about match_result record? |
| 29 | **Bowler over limit** | IMPL_PRACTICES mentions `ceil(totalOvers / 5)` limit per bowler, but this is NOT in SCORING_RULES validation step. |
| 30 | **Concurrent scoring prevention** | What if two devices try to score same match? No locking mechanism documented. |
| 31 | **5-run penalty** | Referenced in IMPL_PRACTICES test matrix but completely missing from SCORING_RULES. |

### Category 5: UI/Design Gaps (19 items)

| # | Question | Context | Details |
|---|----------|---------|---------|
| 32 | **Material 3 seed color** | No seed color defined for the M3 dark theme. All surface tones derive from this. |
| 33 | **Font family** | `google_fonts` is a dependency but no typeface named. |
| 34 | **Typography scale** | No heading/body/caption sizes for Flutter TextStyles. |
| 35 | **Spacing/padding system** | No design tokens (8dp grid? 4dp? 16dp page margins?). |
| 36 | **Icon set** | Material Icons? No specification. |
| 37 | **Loading/empty/error states** | No wireframes for loading spinners, empty lists, error screens, skeleton screens. |
| 38 | **Animations and transitions** | No page transitions, durations, or hero animations specified. |
| 39 | **Wagon wheel zone selection UI** | 12-zone circle wireframed for analytics but no UI showing how scorer RECORDS the zone during scoring. |
| 40 | **Pull-to-refresh** | Not specified for any list screen. |
| 41 | **Scoring page scroll behavior** | What's sticky/fixed during scroll? Score header? Run buttons? |
| 42 | **App bar patterns** | No specification for back buttons, action icons, SliverAppBar vs standard. |
| 43 | **Snackbar/toast patterns** | When to show success/error feedback and in what form. |
| 44 | **Team logo upload/display** | Create Team has "Upload Logo" but no upload flow, display size, placeholder, or cropping specs. |
| 45 | **Avatar/profile photo** | Profile shows initials circle. No camera/upload flow wireframed. |
| 46 | **Settings/preferences screen** | Not in the 18 screens. Is there one? (Theme, notifications, account settings?) |
| 47 | **Landscape orientation** | Not addressed. Lock to portrait? |
| 48 | **Email auth flow** | Listed as MVP auth method but no user story, no acceptance criteria, no screen differences from phone OTP. |
| 49 | **Home dashboard content** | Phase 6 mentions "recent matches, quick actions" but details are only in blueprint wireframe. Match card content (opponent, score, status badge, date) needs confirmation. |
| 50 | **Dark theme surface hierarchy** | M3 dark has surface, surfaceContainer, surfaceContainerHigh, etc. No mapping specified. |

### Category 6: Deployment & Infrastructure (8 items)

| # | Question | Context | Details |
|---|----------|---------|---------|
| 51 | **VPS provider and specs** | Phase 7 says "Set up VPS" with no provider, RAM, CPU, region, or OS specified. |
| 52 | **CI/CD service** | No mention of GitHub Actions, Railway, Vercel, or any CI service. |
| 53 | **Domain name** | API.md references `wss://api.cricapp.com` but no domain registration or DNS mentioned. |
| 54 | **Database hosting** | Self-hosted PostgreSQL on VPS? Managed service (Supabase, Neon, RDS)? |
| 55 | **Firebase project setup** | Separate projects for dev/prod? Project naming? |
| 56 | **Play Store listing** | App name, description, screenshots, privacy policy -- none specified. |
| 57 | **Monitoring/alerting** | No production health monitoring, error alerting, or dashboards specified. |
| 58 | **Backup/recovery** | Critical match data. No backup strategy for PostgreSQL or device data loss. |

### Category 7: Server Architecture Gaps (4 items)

| # | Question | Context | Details |
|---|----------|---------|---------|
| 59 | **WebSocket delivery message missing fields** | WS message lacks `wideRuns`, `noBallRuns`, `byeRuns`, `legByeRuns`, `isBoundaryFour`, `isBoundarySix`, `sequenceNumber` that REST has. |
| 60 | **WebSocket catch-up after disconnect** | Says "fetch current match state via REST" but doesn't specify if missed deliveries are replayed or just latest snapshot. |
| 61 | **Overs decimal notation utility** | 12.3 means 12 overs 3 balls, not 12.3 mathematically. No utility function spec for this conversion. |
| 62 | **`deliveries.total_runs` computation** | Listed as "computed" but unclear if DB trigger, generated column, or application-level. |

---

## Current Doc State - Key Excerpts

---

### From SCORING_RULES.md (FULL CONTENT)

This is the most critical file for Q17-31.

#### 1. Match State Machine

```
  SETUP --> TOSS --> LIVE --> INNINGS_BREAK --> LIVE --> COMPLETED

  At any point: --> ABANDONED
```

> If scores are tied after both innings, the match result is "Match Tied" (status -> COMPLETED).

> During `LIVE` status, the current innings is identified by `innings.innings_number` (1 or 2).

**State Transitions:**

| From | To | Trigger |
|------|----|---------|
| SETUP | TOSS | Both teams selected, match params set |
| TOSS | LIVE | Toss winner/decision recorded, opening players selected |
| LIVE | INNINGS_BREAK | All out OR overs exhausted OR declaration (1st innings) |
| INNINGS_BREAK | LIVE | Opening players for 2nd innings selected |
| LIVE | COMPLETED | All out OR overs exhausted OR target chased OR scores tied (2nd innings) |
| Any | ABANDONED | Manual abandonment by scorer |

#### 2. Delivery Processing Pipeline

Every ball bowled follows this exact sequence:

```
Step 1:  VALIDATE delivery input
           |-- Valid batter pair (striker + non-striker)
           |-- Valid bowler (not same as last over's bowler in consecutive overs)
           |-- Valid over/ball number
           |-- Match is in "live" state

Step 2:  CALCULATE runs
           |-- runs_from_bat (0, 1, 2, 3, 4, 6)
           |-- wide_runs (1 + any additional runs scored off wide)
           |-- no_ball_runs (1 + any additional runs scored off no-ball)
           |-- bye_runs (runs off byes)
           |-- leg_bye_runs (runs off leg-byes)
           |-- total_runs = sum of all above

Step 3:  HANDLE extras
           |-- Wide:
           |     |-- +1 run to bowling figures + extras
           |     |-- Ball does NOT count as legal delivery
           |     |-- Runs do NOT count to batter
           |     |-- Additional runs off wide -> extras (wides)
           |-- No-ball:
           |     |-- +1 run to extras
           |     |-- Ball does NOT count as legal delivery
           |     |-- Runs from bat DO count to batter
           |     |-- Next delivery is a FREE HIT
           |     |-- On free hit: only run out dismissal possible
           |-- Bye:
           |     |-- Runs count to extras (byes), not to batter
           |     |-- Runs do NOT count against bowler
           |-- Leg-bye:
                 |-- Runs count to extras (leg-byes), not to batter
                 |-- Runs do NOT count against bowler

Step 4:  HANDLE wicket (if applicable)
           |-- Record dismissal type + fielder + bowler credit
           |-- Update fall of wickets (score, overs at fall)
           |-- Check if ALL OUT (10 wickets = innings over)
           |-- New batter required (unless all out)

Step 5:  CALCULATE strike change
           |-- Odd runs from bat -> SWAP striker/non-striker
           |-- Even runs (including 0) -> NO swap
           |-- End of over -> SWAP striker/non-striker
           |-- Wide with odd additional runs -> SWAP
           |-- Wicket -> new batter comes in at striker end
                         (unless caught, then depends on completed runs)

Step 6:  CHECK over completion
           |-- Count only LEGAL deliveries (not wides, not no-balls)
           |-- 6 legal deliveries = over complete
           |-- Mark over as maiden if 0 runs scored off bowler
           |     (byes and leg-byes do NOT break maiden)
           |-- Require new bowler selection

Step 7:  CHECK innings completion
           |-- All out (10 wickets) -> innings over
           |-- Overs exhausted (max overs bowled) -> innings over
           |-- Target chased (2nd innings only) -> match over
           |-- Declaration (manual, typically longer formats)

Step 8:  PERSIST to local SQLite (Drift)
           |-- Save delivery record
           |-- Update batting_stats for striker
           |-- Update bowling_stats for bowler
           |-- Update innings totals
           |-- Mark as synced=false

Step 9:  SEND via WebSocket
           |-- Send delivery data to server
           |-- Server validates and persists to PostgreSQL
           |-- Server broadcasts score_update to all subscribers

Step 10: UPDATE UI state
           |-- Refresh score header
           |-- Refresh current batsmen cards
           |-- Refresh bowler card
           |-- Update current over display
           |-- Update run rate
```

#### 3. Cricket Rules - Detailed

##### 3.1 Strike Rotation

```
RULE: After each delivery, determine if striker/non-striker swap.

Scenarios:
  1. Runs from bat = 1, 3, 5 -> SWAP (odd runs)
  2. Runs from bat = 0, 2, 4, 6 -> NO SWAP (even runs)
  3. End of over -> SWAP (regardless of last ball result)
  4. Wide + 1 additional run = SWAP (odd total movement)
  5. Bye/Leg-bye follows same odd/even rule
  6. Wicket (caught): New batter at striker end
  7. Wicket (run out): Depends on which end the dismissed batter was at
     - If striker run out at non-striker end -> new batter at non-striker end
     - If non-striker run out -> new batter at non-striker end
     - Crossed or not crossed matters

End of Over Special:
  - After over swap, if the last ball of previous over was odd runs,
    the swap cancels out (striker stays because: odd_swap + over_swap = no net swap)
  - Implementation: Apply run-based swap first, then apply over swap
```

**KEY GAP for Q17:** Run out "crossed or not crossed matters" is mentioned but the exact logic is not defined. The three sub-bullets describe only where the NEW batter goes, not where the surviving batter ends up when batters have or have not crossed.

##### 3.2 Wides

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +1 to extras (wides category)
- Additional runs: If batsmen run on a wide, those runs add to wides too
- Bowler: Wide runs count against bowler's figures
- Batter: 0 runs credited to batter, 0 balls faced
- Strike: Additional odd runs -> swap; even/zero -> no swap
- Wicket on wide: Only stumped or run out possible
  - If stumped off wide: wide + stumping recorded
  - If run out off wide: wide + run out recorded (any runs completed count)
```

**KEY OBSERVATION for Q19:** States "stumped off wide" and "run out off wide" are possible, but gives no UI flow for how the scorer records this (single combined action? two-step?).

**KEY OBSERVATION for Q23:** States "any runs completed count" on wide + run out, but does not classify whether completed runs go to wides or bat runs.

##### 3.3 No-Balls

```
- Ball count: NOT a legal delivery (over ball count stays)
- Runs: +1 to extras (no-balls category)
- Bat runs: If batter hits the ball, runs from bat count to batter
- Bowler: No-ball runs + runs from bat count against bowler
- Batter: Runs from bat credited, ball NOT counted in balls faced
  (some scoring systems do count it; we follow CricHeroes convention of NOT counting)
- Free Hit: Next delivery after a no-ball is a free hit
  - On free hit: Only run out dismissal is possible
  - If the free hit is also a no-ball -> another free hit follows
- Strike: Normal odd/even rules for runs from bat
```

**KEY OBSERVATION for Q24:** States "If the free hit is also a no-ball -> another free hit follows" but does NOT address what happens if a wide occurs during a free hit (does the free hit carry forward through the wide?).

**KEY OBSERVATION for Q20:** States "runs from bat count to batter" when batter hits, but does not address: if no-ball is bowled, batter misses, and they run -- are those byes on a no-ball, or just no-ball runs?

##### 3.4 Byes

```
- Ball count: YES, it is a legal delivery
- Runs: Count as extras (byes category)
- Batter: 0 runs credited to batter, 1 ball faced
- Bowler: 0 runs against bowler, 1 ball counted
- Strike: Odd bye runs -> swap; even -> no swap
- Common scenario: Ball passes wicket-keeper, batsmen run
```

##### 3.5 Leg-Byes

```
- Ball count: YES, it is a legal delivery
- Runs: Count as extras (leg-byes category)
- Batter: 0 runs credited to batter, 1 ball faced
- Bowler: 0 runs against bowler, 1 ball counted
- Strike: Odd leg-bye runs -> swap; even -> no swap
- Maiden: Leg-byes do NOT break a maiden over
```

##### 3.6 Maiden Overs

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

##### 3.7 Innings Completion

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

**KEY OBSERVATION for Q18:** Mentions "players unavailable (retired hurt, etc.)" affecting all-out count, but does not specify the exact logic.

**KEY OBSERVATION for Q27:** Declaration is listed as an innings completion condition but the UI flow, button, and dialog are completely absent.

##### 3.8 Dismissal Types

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

**KEY OBSERVATION for Q18:** Retired Hurt (rh) and Retired Out (ret) are listed as dismissal types with no bowler credit, but no flow describes how a batter returns from retired hurt, or whether retired hurt counts as a wicket for the 10-wicket all-out threshold.

**KEY OBSERVATION for Q22:** The strike change rule (Step 5) says "Wicket -> new batter comes in at striker end (unless caught, then depends on completed runs)". This only explicitly addresses caught and run out. For bowled/LBW/stumped/hit_wicket, it's implied the batter was at the striker end, but not explicitly stated.

#### 4. Undo Functionality

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
   - Undo first ball of over -> go back to previous over
   - Undo first ball of innings -> error (can't undo)
   - Undo after over change -> reopen previous over
8. Send undo via WebSocket to update all viewers

CONSTRAINTS:
  - Only the LAST delivery can be undone
  - Only the scorer can undo
  - Cannot undo after innings/match completion (must reopen first)
  - Maximum undo chain: implementation allows multiple consecutive undos
```

#### 5. MVP Algorithm

##### 5.1 Batting Points

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
```

##### 5.2 Bowling Points

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
```

##### 5.3 Fielding Points

```
  - Catch: +1.5 points
  - Run out (direct hit): +2.0 points
  - Run out (assist/relay throw): +1.0 point
  - Stumping: +1.5 points
```

##### 5.4 Total MVP Score

```
MVP Score = Batting Points + Bowling Points + Fielding Points

Rankings sorted by total MVP score descending.
Tie-breaker: Batting points > Bowling points > Fielding points
```

#### 6. Scoring Page UI Interactions

##### 6.1 Run Buttons

| Button | Action |
|--------|--------|
| **0** (dot) | Record dot ball, no runs |
| **1** | 1 run, swap strike |
| **2** | 2 runs, keep strike |
| **3** | 3 runs, swap strike |
| **4** | Boundary four, keep strike, mark `is_boundary_four` |
| **6** | Boundary six, keep strike, mark `is_boundary_six` |

**KEY OBSERVATION for Q25:** Only 0, 1, 2, 3, 4, 6 are listed. No button for 5 (overthrow scenario where 1 run + 4 overthrows = 5).

##### 6.2 Extras Buttons

| Button | Action |
|--------|--------|
| **Wide** | Opens sub-panel: [+0] [+1] [+2] [+3] [+4] for additional runs |
| **No Ball** | Opens sub-panel: runs from bat [0-6] + records free hit for next ball |
| **Bye** | Opens sub-panel: [1] [2] [3] [4] for bye runs |
| **Leg Bye** | Opens sub-panel: [1] [2] [3] [4] for leg-bye runs |

**KEY OBSERVATION for Q26:** Wide sub-panel only shows +0 to +4. No +5 or +6 for overthrow scenarios.

##### 6.3 Wicket Dialog

When **WICKET** is tapped:
1. Select dismissal type (bowled, caught, lbw, run out, etc.)
2. If fielder required -> select fielder from fielding team roster
3. If run out -> also ask: how many runs completed before run out?
4. If run out -> ask: which batter was run out? (striker or non-striker)
5. Confirm wicket -> record delivery + wicket
6. If not all out -> show "Select New Batter" dialog

##### 6.4 End of Over Flow

After 6th legal delivery:
1. Show over summary (runs, wickets in that over)
2. Show "Select Next Bowler" dialog
3. Prevent same bowler as previous over (consecutive over rule)
4. After bowler selected -> swap strike -> continue scoring

**KEY OBSERVATION for Q21:** No specification for what happens when the 6th legal delivery is also a wicket. Does the wicket dialog come first, then the end-of-over flow? Or vice versa?

##### 6.5 Innings Transition

When innings ends:
1. Show innings summary (total runs, wickets, overs, run rate)
2. Show extras breakdown
3. Show top performers
4. "Start 2nd Innings" button
5. Select opening batsmen for chasing team
6. Select opening bowler for bowling team
7. Display target prominently in score header

#### 7. Over Display Notation

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

---

### From API.md

#### Full Auth Endpoint (relevant to Q15)

```
POST   /api/v1/auth/verify
```
Verify Firebase token, create or retrieve user record.

**Request:**
```json
{
  "idToken": "firebase_id_token_string"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "firebaseUid": "string",
    "displayName": "string",
    "phone": "string",
    "email": "string",
    "battingStyle": "right_hand",
    "bowlingStyle": "right_arm_fast",
    "playerRole": "all_rounder",
    "isNewUser": false
  },
  "token": "server_jwt_if_needed"
}
```

**KEY GAP for Q15:** The `"token": "server_jwt_if_needed"` is undecided. The rest of the API spec says `Authorization: Bearer <token>` header on every request. IMPLEMENTATION_PRACTICES Section 6 says "Firebase Admin SDK verifies JWT in auth middleware on every REST request" and "Use `flutter_secure_storage` (backed by Android Keystore) for JWTs." It appears Firebase JWT is used directly, but the `token` response field is ambiguous.

#### Incomplete Endpoints (relevant to Q14)

**PUT /api/v1/teams/:id** -- Update team info. Only team owner/captain. **(NO request body specified, NO response body specified)**

**GET /api/v1/players/:id** -- Get player profile. **(NO response body specified)**

**GET /api/v1/matches** -- List matches the user is involved in. Query params: `?status=live&page=1&limit=20`. **(NO response shape specified)**

**DELETE /api/v1/teams/:id/players/:pid** -- Remove player from roster. Only team owner/captain. **(NO response body specified)**

#### Missing Endpoints (relevant to Q12, Q13)

The Toss screen wireframe (blueprint.html) shows:
- Opening Batsmen: dropdown to select R. Sharma (Striker) and S. Dhawan (Non-striker)
- Opening Bowler: dropdown to select J. Bumrah

But the API only has `PUT /api/v1/matches/:id/toss` with body `{ "winnerId": "team_uuid", "decision": "bat" }`. **There is no endpoint to submit opening players.**

Similarly, the `match_players` table exists in DATABASE.md for Playing XI (max 11 per team per match), but **no API endpoint exists to select/submit Playing XI** from team roster. The only player-related match endpoint is the toss endpoint.

#### Sync Pull Response (relevant to Q16)

```
GET    /api/v1/sync/pull?since=timestamp
```

**Response (200):**
```json
{
  "deliveries": [ "..." ],
  "matches": [ "..." ],
  "updatedAt": "2025-03-15T10:35:00Z"
}
```

**KEY GAP for Q16:** The response uses placeholder `"..."` strings. No actual entity shapes defined for sync pull. Compare with the sync push endpoint which at least defines `idMappings` and `conflicts` shapes.

#### WebSocket Delivery Message (relevant to Q59)

**Client to Server "delivery" message:**
```json
{
  "type": "delivery",
  "matchId": "uuid",
  "data": {
    "overNumber": 5,
    "ballNumber": 3,
    "strikerId": "uuid",
    "nonStrikerId": "uuid",
    "bowlerId": "uuid",
    "runsFromBat": 4,
    "isWide": false,
    "isNoBall": false,
    "isBye": false,
    "isLegBye": false,
    "isWicket": false,
    "wagonWheelZoneId": 3
  }
}
```

**Compare with REST `POST /matches/:id/deliveries`:**
```json
{
  "overNumber": 5,
  "ballNumber": 3,
  "strikerId": "uuid",
  "nonStrikerId": "uuid",
  "bowlerId": "uuid",
  "runsFromBat": 4,
  "isWide": false,
  "isNoBall": false,
  "isBye": false,
  "isLegBye": false,
  "wideRuns": 0,
  "noBallRuns": 0,
  "byeRuns": 0,
  "legByeRuns": 0,
  "isWicket": false,
  "isBoundaryFour": true,
  "isBoundarySix": false,
  "wagonWheelZoneId": 3,
  "wicket": null
}
```

**KEY GAP for Q59:** WebSocket message is missing these fields that REST has:
- `wideRuns`
- `noBallRuns`
- `byeRuns`
- `legByeRuns`
- `isBoundaryFour`
- `isBoundarySix`
- `sequenceNumber` (from database schema `deliveries.sequence_number`)
- `wicket` object

#### WebSocket Reconnection (relevant to Q60)

From IMPLEMENTATION_PRACTICES Section 8:

> After reconnecting: re-send `join_match`, then fetch current match state via REST `GET /api/v1/matches/:id` to catch up on missed updates.

**KEY GAP for Q60:** This only says "fetch current match state via REST" but does not specify whether:
- Missed individual deliveries are replayed in sequence
- Just the latest snapshot (current score, batters, bowler) is fetched
- Whether `GET /matches/:id/deliveries?since=lastSeenSequence` is used

The `GET /matches/:id` response only shows current innings summary (totalRuns, totalWickets, overs), not individual missed deliveries.

#### WebSocket Connection URL (relevant to Q53)

```
wss://api.cricapp.com/ws?token=<firebase_jwt>
```

This domain `api.cricapp.com` is referenced but no domain registration, DNS setup, or infrastructure provisioning is documented.

#### Anonymous Viewers

> Anonymous viewers: Read-only WebSocket connections (viewers) do not require authentication. Connect without a `token` parameter to join match rooms as a subscriber. Anonymous connections can only receive `score_update`, `wicket`, `innings_complete`, and `match_complete` messages -- they cannot send `delivery` or `undo_delivery` messages.

---

### From DATABASE.md

#### Materialized Views (relevant to Q11)

Section 7 defines 5 materialized views by name and description only -- **no SQL definitions:**

1. **`player_match_summary`** -- Quick player performance per match. Joins deliveries + batting_stats + bowling_stats.

2. **`innings_scoreboard`** -- Scorecard view. Joins innings + batting_stats + bowling_stats + dismissal info.

3. **`batting_innings_summary`** -- Batting card with dismissal description (e.g. "c Smith b Jones 45 (32)").

4. **`bowling_innings_summary`** -- Bowling analysis card (e.g. "J Bumrah 4-0-22-2").

5. **`player_season_stats`** -- Aggregated stats by format across all matches.

**Refresh trigger:** Auto-refresh after match status changes to "completed".

**KEY GAP for Q11:** All 5 views are named with brief descriptions but zero SQL definitions. To implement Phase 5 (Player Profiles & Stats), these view definitions are needed. The tables they would JOIN are fully defined:
- `deliveries` (Section 3.4)
- `batting_stats` (Section 5.1)
- `bowling_stats` (Section 5.2)
- `fielding_stats` (Section 5.3)
- `innings` (Section 3.2)
- `wickets_by_delivery` (Section 4.1)
- `player_career_stats` (Section 6.1)
- `match_result` (Section 6.2)

#### deliveries.total_runs Column (relevant to Q62)

From Section 3.4 `deliveries` table:

```
| total_runs | integer | computed: runs_from_bat + wide_runs + no_ball_runs + bye_runs + leg_bye_runs |
```

**KEY GAP for Q62:** Listed as "computed" with the formula, but implementation strategy is not specified:
- PostgreSQL generated column (`GENERATED ALWAYS AS (...) STORED`)?
- Database trigger?
- Application-level computation before INSERT?

The Drift/SQLite local schema would need a matching strategy.

#### innings.total_overs Decimal Notation (relevant to Q61)

From Section 3.2 `innings` table:

```
| total_overs | decimal(5,1) | e.g. 12.3 |
```

From Section 5.2 `bowling_stats`:

```
| overs_bowled | decimal(4,1) | e.g. 4.0 |
```

**KEY GAP for Q61:** The notation 12.3 means "12 overs and 3 balls" not the mathematical value 12.3. No utility function is specified for:
- Converting (overs: int, balls: int) -> decimal notation
- Converting decimal notation -> (overs: int, balls: int)
- Adding two overs values correctly (e.g., 12.3 + 0.4 should equal 13.1, not 12.7)
- The file `cricket_utils.dart` is listed in the folder structure for "Strike rotation, over calc" but no spec for the calculation.

#### match_players Table (relevant to Q13)

```
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK -> matches.id | |
| team_id | uuid FK -> teams.id | |
| player_id | uuid FK -> users.id | |
| batting_order | integer | nullable (set when player comes in to bat) |
| is_playing | boolean | default true |
| is_captain | boolean | default false |
| is_keeper | boolean | default false |
| created_at | timestamp | |
| updated_at | timestamp | |

Unique constraint: (match_id, team_id, player_id)
Max per team per match: 11 players (enforced at application level)
```

The table exists but no API endpoint to populate it.

#### batting_stats.is_retired_hurt (relevant to Q18)

From Section 5.1 `batting_stats`:

```
| is_retired_hurt | boolean | default false |
```

This flag exists in the table but no logic or flow is defined for:
- How to set it (via the Wicket dialog? separate UI action?)
- Whether it counts toward the 10-wicket all-out threshold
- How a batter returns from retired hurt status

#### match_result Table (relevant to Q28)

```
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK -> matches.id | UNIQUE |
| winner_team_id | uuid FK -> teams.id | nullable (tie/no result) |
| result_type | varchar(20) | "runs", "wickets", "tie", "no_result" |
| margin | integer | nullable (runs or wickets margin) |
| man_of_match_id | uuid FK -> users.id | nullable |
| summary | text | e.g. "Team A won by 5 wickets" |
| created_at | timestamp | |
```

**KEY GAP for Q28:** `result_type` includes "no_result" but the state machine only has "ABANDONED" and "COMPLETED". When a match is abandoned:
- Does a `match_result` record get created with `result_type = "no_result"`?
- Do partial match stats (batting/bowling/fielding from innings played so far) count toward career stats?
- This is not specified anywhere.

#### Local SQLite Schema (relevant to sync/offline)

**Mirrored tables:** users, teams, team_rosters, match_players, matches, innings, overs, deliveries, batting_stats, bowling_stats

**Additional local-only tables:**

`sync_queue`:
| Column | Type | Notes |
|--------|------|-------|
| id | integer PK autoincrement | |
| entity_type | text NOT NULL | match, innings, delivery, batting_stats, etc. |
| entity_id | text NOT NULL | local UUID of the entity |
| operation | text NOT NULL | create, update, delete |
| payload | text NOT NULL | JSON blob of entity data |
| retry_count | integer | default 0 |
| status | text | default 'pending' -- pending, syncing, synced, failed |
| created_at | timestamp | default CURRENT_TIMESTAMP |

`local_preferences`:
| Column | Type | Notes |
|--------|------|-------|
| key | text PK | |
| value | text NOT NULL | |

---

### From IMPLEMENTATION_PLAN.md

#### Phase 5: Player Profiles & Stats (relevant to Q11)

```
Phase 5: Player Profiles & Stats (Week 10-11)
- [ ] Implement career stats aggregation (server-side, materialized views)
- [ ] Build Player Profile Page
- [ ] Build Stats Page (batting, bowling, fielding tabs)
- [ ] Build Match History Page
- [ ] Implement stats refresh after each match completion
```

#### Phase 6: Polish & Testing (relevant to Q49)

```
Phase 6: Polish & Testing (Week 12-13)
- [ ] Unit tests for scoring engine (critical path)
- [ ] Unit tests for cricket rules (strike rotation, extras, overs)
- [ ] Widget tests for Scoring Page
- [ ] Integration tests for full match scoring flow
- [ ] Offline scoring to online sync end-to-end test
- [ ] Performance testing on low-end Android devices
- [ ] Bug fixes and UI polish
- [ ] Home Page dashboard (recent matches, quick actions)
```

#### Phase 7: Deployment & Launch (relevant to Q51-58)

```
Phase 7: Deployment & Launch (Week 14)
- [ ] Set up VPS (PostgreSQL + Bun server)
- [ ] Configure SSL/HTTPS
- [ ] Set up CI/CD pipeline
- [ ] Build release APK
- [ ] Google Play Store listing
- [ ] Launch
```

**KEY GAPS for Q51-58:** Phase 7 is the shortest phase description with the least detail:
- Q51: "Set up VPS" -- no provider (DigitalOcean, Hetzner, AWS, etc.), no specs (RAM, CPU, region, OS)
- Q52: "Set up CI/CD pipeline" -- no service specified (GitHub Actions, Railway, etc.)
- Q53: Domain `api.cricapp.com` referenced in API.md but no registration/DNS steps
- Q54: "PostgreSQL" on VPS -- self-hosted vs managed service not decided
- Q55: Firebase project -- IMPLEMENTATION_PRACTICES Section 17 mentions "Separate Firebase projects per environment" but no project naming or setup steps
- Q56: "Google Play Store listing" -- no app name, description, screenshots, privacy policy
- Q57: No monitoring/alerting mentioned anywhere
- Q58: No backup/recovery strategy mentioned anywhere

#### Key Screens (MVP) - 18 Total

```
1. Splash Screen
2. Login Page (Phone OTP / Google / Email)
3. OTP Verification Page
4. Profile Setup Page
5. Home Page (Dashboard)
6. Teams List Page
7. Create Team Page
8. Team Detail Page
9. Manage Roster Page
10. Match Setup Page
11. Toss Page
12. Scoring Page (most critical)
13. Wicket Dialog
14. Extras Panel
15. Scorecard Page
16. Match Analytics Page
17. Player Profile Page
18. Match History Page
```

**KEY GAP for Q46:** No Settings/Preferences screen in the 18 screens.

#### Architecture Data Flow

```
1. Scorer taps ball outcome on Flutter UI
2. App saves to local Drift DB immediately (offline-safe)
3. App sends delivery data via WebSocket to Bun server
4. Bun server validates, persists to PostgreSQL
5. Bun server broadcasts update to all match subscribers via WebSocket pub/sub
6. All viewers' Flutter apps receive update, refresh scorecard UI
```

#### Flutter Packages (relevant to Q33, Q36)

```yaml
  # UI & Charts
  fl_chart: ^0.68.0
  google_fonts: ^6.2.0
  flutter_svg: ^2.0.0
```

`google_fonts` is listed as a dependency but no specific typeface is named anywhere in the docs.

#### Folder Structure (relevant to Q32, Q50)

```
apps/mobile/lib/src/core/theme/
    app_theme.dart               # M3 dark theme
    app_colors.dart
```

These files are listed in the folder structure but no content or specifications for them exist. No seed color, no surface hierarchy, no color token definitions.

---

### From PDR.md

#### Non-Functional Requirements (relevant to Q35, Q47)

| Requirement | Target | Rationale |
|-------------|--------|-----------|
| Cold start time | < 3 seconds | Low-end Android users expect fast app launch |
| Local DB size | < 50MB per 100 matches | Budget phones have limited storage |
| Battery usage | < 5% per T20 match scored | Scoring sessions can be 2+ hours |
| Minimum touch target | 48x48 dp | Accessibility and outdoor usability (bright sun, sweaty fingers) |
| APK size | < 30MB | Play Store download on slow connections |
| API response time | < 200ms (p95) | Fast data loading when online |
| Offline storage | Unlimited matches | No cap on offline scoring |

**KEY OBSERVATION for Q35:** Touch target minimum is 48x48 dp -- this is a spacing/sizing constraint but no general spacing system (8dp grid, page margins, etc.) is defined.

**KEY OBSERVATION for Q47:** No mention of landscape orientation anywhere. Minimum touch target of 48x48 dp is easier to achieve in portrait on phone screens.

#### MVP Scope Boundaries (relevant to Q46, Q48)

**Included in MVP:**
- Android app only
- Ball-by-ball scoring with full extras and dismissals
- Offline-first with sync
- Live WebSocket broadcasting
- Team and player management
- Career stats (batting, bowling, fielding)
- Match analytics (wagon wheel, manhattan, worm)
- MVP rankings per match
- Firebase Auth (phone OTP, Google, email)

**Explicitly Excluded from MVP:**
- iOS app -- Android only for initial launch
- Tournament/league management -- Only individual matches
- DLS (Duckworth-Lewis-Stern) -- Rain-affected match calculations
- Video highlights/replays -- No video integration
- Multi-language support -- English only
- Social features -- No chat, comments, or social feed
- Advertisement integration -- No ads in MVP
- Premium/paid features -- No monetization in MVP
- Custom scoring rules -- Standard cricket rules only
- Ball tracking/analytics -- No pitch map or ball trajectory
- Umpire DRS -- No decision review system
- Commentary/text updates -- Ball-by-ball data only, no narrative

**KEY OBSERVATION for Q48:** Email auth is listed as "Included in MVP" alongside Phone OTP and Google, but there is no user story, no acceptance criteria, and no screen wireframe for email auth (only US-11 for phone OTP and US-12 for Google exist).

#### User Stories (relevant to Q13, Q48)

| ID | Role | Goal | Priority | Phase |
|----|------|------|----------|-------|
| US-10 | Captain | Manage team roster for a match | P1 | 2 |
| US-11 | Player | Sign up with phone OTP | P0 | 1 |
| US-12 | Player | Sign up with Google | P0 | 1 |
| US-13 | Player | Set up my profile | P0 | 1 |

**KEY OBSERVATION for Q48:** No user story for email auth (only phone OTP as US-11 and Google as US-12).

**KEY OBSERVATION for Q13:** US-10 says "Can select playing XI from team roster before match starts" (P1, Phase 2) but no API endpoint exists to do this.

---

### From IMPLEMENTATION_PRACTICES.md

#### Section 9: Data Validation & Input Sanitization (relevant to Q29)

**Cricket-Specific Validations:**

> Defined once per platform in `cricket-rules.ts` (server) / `cricket_utils.dart` (Flutter) per CLAUDE.md DRY rules. Ref: SCORING_RULES.md Section 2, Step 1 (VALIDATE).

> - **Free hit:** Only `run_out` dismissal allowed.
> - **Over limit:** Bowler can't exceed `ceil(totalOvers / 5)` overs.
> - **Consecutive over restriction:** Same bowler can't bowl 2 consecutive overs.
> - **Valid batter pair:** Striker != non-striker, both active (not dismissed).

**KEY GAP for Q29:** The bowler over limit `ceil(totalOvers / 5)` is specified here in IMPLEMENTATION_PRACTICES but is **NOT** in SCORING_RULES.md's Step 1 VALIDATE. This is a contradiction -- SCORING_RULES validates: valid batter pair, valid bowler (consecutive over rule), valid over/ball number, match is live. It does NOT include the max overs per bowler validation.

#### Section 13: Testing Approach Per Layer (relevant to Q31)

**Scoring Engine -- Exhaustive Tests:**

> - Every delivery type: dot ball, 1-6 runs, wide, no-ball, bye, leg-bye
> - All 12 dismissal types with correct stat attribution
> - Strike rotation: odd runs, even runs, end of over, after wicket
> - Over completion: 6 legal deliveries (wides/no-balls don't count)
> - Innings completion: all out, overs exhausted, target chased, declaration
> - Undo: every delivery type reversal, stat rollback, strike un-rotation
> - Free hit: triggered after no-ball, only run-out dismissal allowed
> - Maiden detection: 0 runs from bat (byes don't break maiden)
> - **Edge cases: last ball of over is wide, wicket on free hit, 5-run penalty**

**KEY GAP for Q31:** "5-run penalty" is listed as an edge case test scenario here, but the 5-run penalty is **completely absent** from SCORING_RULES.md. No definition of when it occurs, how it affects scoring, how it's recorded in the delivery model, or how the UI captures it.

#### Section 18: Performance (Low-End Android) (relevant to Q41)

> Target: smooth performance on 2GB RAM budget Android devices.

> - Riverpod: Use select() for Granular Rebuilds
> - Lists: Always Use ListView.builder
> - Images: Compress Below 100KB
> - Database: Use Indexes from DATABASE.md
> - Pagination: 20 items per page

No specific guidance on scoring page scroll behavior or sticky elements.

#### Section 8: WebSocket Error Handling & Reconnection (relevant to Q60)

> **Reconnection Catch-Up:**
> After reconnecting: re-send `join_match`, then fetch current match state via REST `GET /api/v1/matches/:id` to catch up on missed updates.

> **Scorer vs Viewer on Disconnect:**
> - **Scorer:** Continues scoring offline. Deliveries queue in local SQLite. Sync pushes when reconnected.
> - **Viewer:** Shows stale indicator -- "Last updated X seconds ago". Live data pauses until reconnected.

> **Connection State UI:**
> Display in scoring page header:
> - Green dot = connected
> - Yellow dot = reconnecting
> - Red dot = disconnected

#### Section 5: Error Handling & Network Resilience (relevant to Q43)

> **User-Facing Error Display:**
> - **SnackBar:** Transient errors (network timeout, sync retry).
> - **Inline text:** Form validation errors (below the field).
> - **Full-screen error + retry:** Critical failures (database corruption, auth failure).
> - Never show raw exception messages or stack traces to users.

This gives some guidance on snackbar/toast patterns for Q43 but no comprehensive specification.

#### Section 17: Environment Configuration (relevant to Q55)

> **Firebase Per Environment:**
> Separate Firebase projects per environment. Each has its own `google-services.json` placed per flavor configuration.

**KEY GAP for Q55:** Mentions separate Firebase projects per environment but no project naming convention, no setup steps, and no indication of how many environments (dev, staging, prod?).

---

### From CODE_STANDARDS.md

#### Section 5: API Standards (relevant to Q14-16)

**JSON Field Naming:**

| Layer | Convention |
|-------|-----------|
| Database (PostgreSQL/SQLite) | `snake_case` |
| Server TypeScript internals | `camelCase` |
| JSON API responses | `camelCase` |
| Dart models | `camelCase` |

**Response Envelope:**

```json
// Single resource -- singular key
{ "match": { "id": "uuid", "status": "live", ... } }

// Collection -- plural key with total and page
{
  "teams": [ ... ],
  "total": 42,
  "page": 1
}
```

**HTTP Status Codes:**

| Status | Usage |
|--------|-------|
| 200 | Successful read or update |
| 201 | Resource created (POST /teams, POST /matches) |
| 400 | Validation error (bad request body) |
| 401 | Missing or invalid auth token |
| 403 | Authenticated but not authorized (not the scorer) |
| 404 | Resource not found |
| 409 | Conflict (sync conflict, duplicate) |
| 429 | Rate limited |
| 500 | Internal server error |

**WebSocket Message Shape:**

```json
{
  "type": "score_update",
  "matchId": "uuid",
  "data": { ... }
}
```

- `type` uses `snake_case`
- `matchId` is required on all match-scoped messages
- `data` contains the payload
- Error messages use `{ "type": "error", "message": "..." }`

**Domain-specific error codes:**

| Error Code | Context |
|-----------|---------|
| INVALID_DELIVERY | Delivery input fails validation (Step 1 of pipeline) |
| MATCH_NOT_LIVE | Attempted scoring action on a non-LIVE match |
| INVALID_STATE_TRANSITION | Invalid match state change |
| CONSECUTIVE_OVER | Same bowler attempting consecutive overs |
| SYNC_CONFLICT | Client data conflicts with server |

These error codes can be used to fill gaps in Q14 (incomplete endpoint error responses).

---

### From blueprint.html (Key Wireframe Descriptions)

#### Auth Flow Screens

**Splash Screen:** Shows CricApp logo, "Loading..." text, progress bar. Annotation: checks auth state on launch -- if logged in + profile complete -> Home; if logged in but no profile -> Profile Setup; else -> Login.

**Login Screen:** Phone number input with "+91" prefix, "Send OTP" primary button, divider with "or sign in with", two buttons: "Google" and "Email". Annotation: Firebase Auth providers: Phone OTP (primary), Google Sign-In, Email/Password.

**KEY OBSERVATION for Q48:** The Login wireframe shows an "Email" button alongside Google, but no email-specific screen flow exists (no email input, no password input, no forgot password). The OTP screen only handles phone verification.

**OTP Verification:** 6-digit code entry boxes, "Verify" button, "Resend in 0:28" text.

**Profile Setup:** Display Name input, Batting Style dropdown, Bowling Style dropdown, Player Role dropdown, City input (optional), "Complete Profile" button.

**KEY OBSERVATION for Q45:** Profile Setup shows text fields only -- no profile photo upload, no avatar selection, no camera option.

#### Home Dashboard Screen

Shows: "Welcome, Rohit!" greeting, Quick Actions row (+ Match, Teams, Stats), Recent Matches section with cards showing:
- Match card 1: "Mumbai W. vs Delhi D." / "156/7 vs 142/9" / DONE badge (green)
- Match card 2: "CSK XI vs RCB XI" / "87/3 (12.3)" / LIVE badge (red, with dot indicator)
- Match card 3: "Weekend XI vs Friends" / "Mar 20 Wankhede" / SOON badge (gray)

Bottom navigation: Home (active), Teams, Profile.

Annotation: "Tap LIVE match -> Scoring Page (if scorer) or Scorecard (if viewer). Tap COMPLETED -> Scorecard + Analytics."

**KEY OBSERVATION for Q49:** The dashboard wireframe confirms: match cards show team names, abbreviated scores, overs, status badges (DONE/LIVE/SOON), and date/venue. This is the only specification for home dashboard content.

#### Teams Flow Screens

**Teams List:** "+ Create Team" button at top, team cards showing name, player count, city. Bottom nav.

**Create Team:** Team Name input, City input, "Upload Logo" button, "Create" button.

**KEY OBSERVATION for Q44:** "Upload Logo" is a simple button with no further flow specified. No file picker, camera option, cropping UI, display size, placeholder image, or upload mechanism.

**Team Detail:** Team name, city, player count, roster table (jersey#, name, role), "Manage Roster" link.

**Manage Roster:** Search input, player cards with "Add"/"Remove" buttons, note "Owner/Captain can manage roster".

#### Match Setup & Toss Screens

**Match Setup:** Home Team dropdown, Away Team dropdown, Format selection (T20/ODI/Custom toggle), Overs input, Ball Type dropdown, Venue input, "Proceed to Toss" button.

**Toss Screen:** Toss Winner toggle (team buttons), Decision toggle (Bat First / Bowl First), Opening Batsmen dropdowns (Striker, Non-striker), Opening Bowler dropdown, "Start Match" button.

Annotation: "Status transitions: SETUP -> TOSS -> LIVE. Creates innings record. Sets batting/bowling teams."

**KEY OBSERVATION for Q12:** The Toss screen wireframe shows opening player selection UI, but the API `PUT /matches/:id/toss` only accepts `winnerId` and `decision`. No endpoint to submit the opening batsmen and bowler selections.

#### Scoring Page (CENTER - Largest wireframe)

**Score Header (dark background):**
- Team name + innings number ("Mumbai Warriors 1st Inn")
- Score: "87/3 (12.3 ov)" in large text
- Current Run Rate, Target, Required Run Rate on right
- FREE HIT badge (orange) when applicable

**Batting Cards (stacked):**
- Striker card (green left border): name + *, R/B/4s/6s/SR stats
- Non-striker card: name, R/B/4s/6s/SR stats

**Bowler Card (red left border):** name, Ov/M/R/W/Ec stats

**Current Over Display:** "Over 13" label, ball indicators (dot=gray, 1=white, 4=blue, W=red, Wd=dashed border, ?=placeholder)

**Run Buttons:** 0, 1 (primary/dark), 2, 3, 4 (blue), 6 (purple)

**Extras & Wicket Row:**
- Extras: Wide, NB, Bye, LB buttons
- Wicket: Large red "W" button

**Action Bar:** Undo, Card, Set buttons

**KEY OBSERVATION for Q25:** Run buttons are 0, 1, 2, 3, 4, 6. No 5 button.

**KEY OBSERVATION for Q41:** The scoring page wireframe shows all elements in a single phone frame without any scroll indicators. No indication of what's fixed/sticky vs scrollable.

**KEY OBSERVATION for Q39:** No wagon wheel zone selection UI appears on the scoring page. The `wagonWheelZoneId` field exists in the delivery model but no UI for recording it during scoring.

#### Scoring Dialogs

**Extras Panel (Bottom Sheet):**
- Wide -- Additional Runs: [+0] [+1] [+2] [+3] [+4]
- No Ball -- Runs from Bat: [0] [1] [2] [3] [4] [6]
- Byes / Leg Byes -- Runs: [1] [2] [3] [4]
- Confirm button

**KEY OBSERVATION for Q26:** Wide sub-panel shows +0 to +4 only. No +5 or +6.

Annotation: "Strike rotation on extras follows same odd/even rule for additional runs. Wide with 0 extra -> no swap. Wide with 1 extra -> swap."

**Wicket Dialog (Modal):**
- Step 1: Dismissal Type buttons: Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket, C&B, Retired
- Step 2: Fielder selection dropdown (from bowling team)
- Step 3: Runs before dismissal (run out only): [0] [1] [2] [3]
- Step 4: Which batter dismissed? Striker / Non-Striker toggle
- Step 5: Confirm Wicket button

Annotation: "Run out: must specify WHICH batter dismissed & runs completed before. On a wide: only stumped or run out. On free hit: only run out possible."

**KEY OBSERVATION for Q19:** No UI flow for stumped-off-wide. The Wicket dialog doesn't show how to combine wide + stumped. Does the scorer tap Wide first, then Wicket? Or is there a combined flow?

**KEY OBSERVATION for Q18:** "Retired" appears as a dismissal type button in the Wicket dialog, but no distinction between "Retired Hurt" (temporary) and "Retired Out" (permanent). No flow for returning from retired hurt.

**Select Next Bowler (Modal):**
- "Over complete. Select bowler for over 14."
- Bowler cards with stats (O-M-R-W) and Select button
- Previous over's bowler shown struck-through with "Bowled last over" message

**Select New Batter (Modal):**
- "Wicket! Select next batter."
- Available batter cards with role and jersey number
- Already-out batters shown struck-through with "Already batted (out)" message

**Innings Transition (Modal):**
- Team name + "1st Innings" header
- Score: "156/7 (20.0 ov)"
- Extras breakdown: "Wd: 3 NB: 2 B: 1 LB: 2 = 8"
- Top performers
- Fall of wickets
- Target: 157 (prominent red text)
- "Start 2nd Innings" button

Annotation: "Creates new innings record. Sets target = 1st innings total + 1. Prompts for opening batsmen and opening bowler for 2nd innings."

#### Scorecard Page

Tabs: 1st Inn / 2nd Inn
Batting table: Batter, R, B, 4s, 6s, SR
Bowling table: Bowler, O, M, R, W, Ec
Extras line, FoW line
Match result text at bottom

#### Analytics Page

Tabs: Wagon / Manhat / Worm / MVP

**Wagon Wheel:** Batter selector dropdown, circular field with 12 zones (30-degree segments), zone lines, shot dots (blue=4, purple=6, black=1-3), Off/Leg labels.

**Manhattan Chart:** Bar chart, overs on X axis, runs per over on Y axis, red bars for overs with wickets.

**Worm Graph:** Line chart, two colored lines (Inn 1 solid blue, Inn 2 dashed red), overs vs cumulative runs.

**MVP Rankings:** Ranked player cards with total points and breakdown (Bat/Bowl/Field).

**KEY OBSERVATION for Q39:** The Wagon Wheel is shown only in the Analytics tab for viewing historical shot data. No corresponding UI exists on the Scoring Page for the scorer to SELECT a zone when recording each delivery. Yet the `wagonWheelZoneId` field exists in the delivery REST payload and WebSocket message.

#### Player Profile Page

- Initials circle avatar ("RS")
- Player name, role, batting style, city
- Summary stats: Mat, Runs, Avg, Wkts
- Bottom nav: Home, Teams, Profile (active)

**KEY OBSERVATION for Q45:** Shows initials-based avatar only. No photo, no upload flow.

#### Player Stats Page

- Format filter: All / T20 / ODI / Custom
- Tabs: Batting / Bowling / Fielding
- Stats table with all fields from API response

#### Match History Page

- Match cards showing: opponent, date, format, personal performance, match result with color coding
- "Load More" button at bottom (pagination indicator)

#### Match State Machine (wireframe panel)

Flow boxes: SETUP -> TOSS -> INNINGS_1 -> INN_BREAK -> INNINGS_2 -> COMPLETED
Separate box: ABANDONED (any point)
Note: "Tied scores -> COMPLETED with 'Match Tied'"

#### Delivery Pipeline (wireframe panel)

10 numbered steps matching SCORING_RULES.md Section 2:
1. VALIDATE -- batter pair, bowler, match state
2. CALCULATE runs -- bat + extras = total
3. HANDLE extras -- wide/NB/bye/LB rules
4. HANDLE wicket -- dismissal, fielder, bowler credit
5. CALCULATE strike -- rotation logic (odd/even)
6. CHECK over -- 6 legal = complete, maiden detect
7. CHECK innings -- all out / overs done / target chased
8. PERSIST -- Drift INSERT, update 5 tables
9. SEND -- WebSocket fire-and-forget
10. UPDATE UI -- Riverpod state rebuild

#### ScoringState Shape (wireframe panel)

```
Match Context: matchId, inningsId, format, totalOvers
Score: totalRuns, totalWickets, currentOvers, currentRunRate, requiredRunRate, target
Players: striker, nonStriker, currentBowler
Current Over: overNumber, legalBalls, deliveries[]
State Flags: isFreeHit, isInningsComplete, isMatchComplete
Last Delivery: lastDeliveryId (for undo)
```

#### Extras Comparison Table (wireframe panel)

| Extra | Legal Delivery? | Batter Credit? | Against Bowler? | Breaks Maiden? |
|-------|----------------|----------------|-----------------|----------------|
| Wide | No | No | Yes | Yes |
| No-Ball | No | Bat runs: Yes | Yes | Yes |
| Bye | Yes | No | No | No |
| Leg Bye | Yes | No | No | No |

#### Cricket Domain Rules Annotation

- Wides/NB don't count as legal deliveries -- ball_number stays, sequence_number advances
- Free hit chain: NB -> free hit -> another NB -> another free hit (until legal delivery)
- All out = 10 wickets (not 11). 11th batter remains not out.
- Target chased = match ends IMMEDIATELY mid-over

#### Widget-to-State Mapping (wireframe panel)

| Widget | State Fields |
|--------|-------------|
| Score Header | totalRuns, totalWickets, overs, CRR, RRR |
| Striker Card | striker.{runs,balls,4s,6s,SR} |
| NonStriker Card | nonStriker.{runs,balls,4s,6s,SR} |
| Bowler Card | bowler.{O,M,R,W,Econ} |
| Over Display | currentOver.deliveries[] |
| Free Hit Badge | isFreeHit |
| Run Buttons | -> recordDelivery() |
| Undo Button | lastDeliveryId |

#### Glossary

- **Over:** 6 legal deliveries by one bowler
- **Maiden:** Over with 0 runs off bowler
- **Strike Rate:** (Runs / Balls) x 100
- **Economy:** Runs conceded / Overs bowled
- **Extras:** Runs not from bat (Wide, NB, Bye, LB)
- **Free Hit:** After NB, only run out possible
- **Wagon Wheel:** Shot direction chart (12 zones)
- **Manhattan:** Runs per over bar chart
- **Worm:** Cumulative runs line chart
- **FoW:** Fall of Wickets (score at each dismissal)
- **All Out:** 10 wickets fallen
- **Declaration:** Batting team voluntarily ends innings

---

## Cross-Reference Summary: Where Each Question's Evidence Lives

| Q# | Primary Source | Secondary Source | What's Missing |
|----|--------------|-----------------|----------------|
| 11 | DATABASE.md Section 7 | IMPLEMENTATION_PLAN Phase 5 | SQL definitions for all 5 materialized views |
| 12 | API.md PUT /matches/:id/toss | blueprint.html Toss screen | Endpoint for opening player selection |
| 13 | DATABASE.md match_players table | PDR.md US-10 | API endpoint for Playing XI selection |
| 14 | API.md Sections 1.2-1.5 | CODE_STANDARDS.md Section 5 | Request/response bodies for 4 endpoints |
| 15 | API.md Section 1.1 auth/verify | IMPL_PRACTICES Section 6 | Decision: server JWT vs Firebase JWT |
| 16 | API.md Section 1.7 sync/pull | DATABASE.md Section 10 | Entity shapes for sync pull response |
| 17 | SCORING_RULES.md Section 3.1 (item 7) | -- | Full crossed/not-crossed logic |
| 18 | SCORING_RULES.md Section 3.8 (types 8,9) | DATABASE.md batting_stats.is_retired_hurt | UI flow, wicket count impact, return logic |
| 19 | SCORING_RULES.md Section 3.2 (wicket on wide) | blueprint.html Wicket Dialog | Combined UI flow for wide+stumped |
| 20 | SCORING_RULES.md Section 3.3 (no-ball rules) | -- | no-ball + byes classification |
| 21 | SCORING_RULES.md Section 6.4 (end of over) | Section 6.3 (wicket dialog) | Dialog ordering for wicket on last ball |
| 22 | SCORING_RULES.md Section 2 Step 5 | -- | Explicit new batter position for all dismissal types |
| 23 | SCORING_RULES.md Section 3.2 (wide+run out) | -- | Run classification (wides vs bat runs) |
| 24 | SCORING_RULES.md Section 3.3 (free hit) | -- | Free hit through wides |
| 25 | SCORING_RULES.md Section 6.1 | blueprint.html run buttons | Run button for 5 (overthrows) |
| 26 | SCORING_RULES.md Section 6.2 | blueprint.html extras panel | Wide +5/+6 overthrow buttons |
| 27 | SCORING_RULES.md Section 3.7 (item 4) | -- | Declaration UI flow, button, dialog |
| 28 | SCORING_RULES.md state machine (ABANDONED) | DATABASE.md match_result | Stats impact, match_result creation |
| 29 | IMPL_PRACTICES Section 9 | SCORING_RULES.md Section 2 Step 1 | Bowler limit in validation step |
| 30 | -- | DATABASE.md matches.scorer_id | Concurrent scoring lock mechanism |
| 31 | IMPL_PRACTICES Section 13 (test matrix) | -- | 5-run penalty definition in SCORING_RULES |
| 32 | IMPLEMENTATION_PLAN folder structure | -- | M3 seed color value |
| 33 | IMPLEMENTATION_PLAN pubspec.yaml | -- | Font family name |
| 34 | -- | -- | Typography scale |
| 35 | PDR.md NFR (48x48dp touch target) | -- | Spacing system / design tokens |
| 36 | -- | -- | Icon set specification |
| 37 | IMPL_PRACTICES Section 5 (error display) | -- | Loading/empty/error state wireframes |
| 38 | -- | -- | Animation/transition specs |
| 39 | blueprint.html analytics wagon wheel | API.md wagonWheelZoneId field | Zone selection UI during scoring |
| 40 | -- | -- | Pull-to-refresh specification |
| 41 | blueprint.html scoring page | -- | Scroll behavior / sticky elements |
| 42 | -- | -- | App bar pattern specification |
| 43 | IMPL_PRACTICES Section 5 | -- | Comprehensive snackbar/toast patterns |
| 44 | blueprint.html Create Team | -- | Upload flow, display size, placeholder |
| 45 | blueprint.html Player Profile | -- | Photo upload flow |
| 46 | IMPLEMENTATION_PLAN 18 screens list | -- | Settings screen entirely missing |
| 47 | PDR.md NFR section | -- | Landscape orientation policy |
| 48 | PDR.md MVP scope + US list | blueprint.html Login screen | Email auth user story + screen flow |
| 49 | blueprint.html Home Dashboard | IMPLEMENTATION_PLAN Phase 6 | Confirmed wireframe content |
| 50 | IMPLEMENTATION_PLAN folder structure | -- | Dark theme surface hierarchy mapping |
| 51 | IMPLEMENTATION_PLAN Phase 7 | -- | VPS provider, specs, region |
| 52 | IMPLEMENTATION_PLAN Phase 7 | -- | CI/CD service |
| 53 | API.md wss://api.cricapp.com | -- | Domain registration, DNS |
| 54 | IMPLEMENTATION_PLAN Phase 7 | -- | Database hosting decision |
| 55 | IMPL_PRACTICES Section 17 | -- | Firebase project naming, setup |
| 56 | IMPLEMENTATION_PLAN Phase 7 | -- | Play Store listing content |
| 57 | -- | -- | Monitoring/alerting |
| 58 | -- | -- | Backup/recovery strategy |
| 59 | API.md Section 2.2 vs Section 1.4 | -- | Missing WS delivery fields |
| 60 | IMPL_PRACTICES Section 8 | API.md Section 2 | Catch-up strategy (replay vs snapshot) |
| 61 | DATABASE.md innings.total_overs | IMPLEMENTATION_PLAN cricket_utils.dart | Overs notation utility function |
| 62 | DATABASE.md deliveries.total_runs | -- | Computed column implementation strategy |
