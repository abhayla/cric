# E2E Full Match UI Test Plan

Comprehensive end-to-end test scenarios exercising the full multi-page user journey through widget interactions. Each scenario documents the ball-by-ball sequence, expected state after each delivery, and UI interaction patterns.

## Test Data

### Teams (3 players each for fast test execution)

| Team | Player 1 | Player 2 | Player 3 |
|------|----------|----------|----------|
| Mumbai Indians (MI) | Rohit Sharma (C) | Suryakumar Yadav | Jasprit Bumrah |
| Chennai Super Kings (CSK) | MS Dhoni (WK) | Ravindra Jadeja | Deepak Chahar |

### Match Configuration
- **Overs**: 2 (12 balls per innings max)
- **Players per side**: 3
- **Wide/NB penalty**: 1 run each
- **Ball type**: Tennis (irrelevant for scoring logic)

---

## Group 1: Match Setup Page UI

### 1.1 Format selection and presets
- Select overs (2), players per side (3)
- Verify validation: 0 overs rejected, negative players rejected

### 1.2 Ball type selection
- Tennis ball selected by default
- Leather ball selectable

> **Note**: Match setup is handled before ScoringPage. For E2E widget tests, we construct ScoringPageArgs directly.

---

## Group 2: Toss Wizard UI (5 Steps)

### 2.1 Toss flow
1. **Step 1 — Toss Winner**: Tap "Mumbai Indians"
2. **Step 2 — Decision**: Tap "Bat" (or "Bowl")
3. **Step 3 — Playing XI Team A**: Select/confirm 3 players
4. **Step 4 — Playing XI Team B**: Select/confirm 3 players
5. **Step 5 — Openers + Bowler**: Select striker, non-striker, opening bowler → "Start Match"

> **Note**: Toss wizard is a separate page. E2E widget tests start at ScoringPage with pre-configured args.

---

## Group 3: Full Match — Win by Runs

### 1st Innings (MI batting, CSK bowling)

| Ball | Action | Runs | Score | Overs | Striker |
|------|--------|------|-------|-------|---------|
| 1.1 | Tap "1" | 1 | 1/0 | 0.1 | SKY (swapped) |
| 1.2 | Tap "1" | 1 | 2/0 | 0.2 | Rohit (swapped back) |
| 1.3 | Tap "4" | 4 | 6/0 | 0.3 | Rohit |
| 1.4 | Tap "4" | 4 | 10/0 | 0.4 | Rohit |
| 1.5 | Tap "0" | 0 | 10/0 | 0.5 | Rohit |
| 1.6 | Tap "6" | 6 | 16/0 | 1.0 | Rohit → end of over swaps to SKY |

**Over complete → Select bowler sheet appears. Select Deepak Chahar.**

| Ball | Action | Runs | Score | Overs | Striker |
|------|--------|------|-------|-------|---------|
| 2.1 | Tap "4" | 4 | 20/0 | 1.1 | SKY |
| 2.2 | Tap "4" | 4 | 24/0 | 1.2 | SKY |
| 2.3 | Tap "0" | 0 | 24/0 | 1.3 | SKY |
| 2.4 | Tap "0" | 0 | 24/0 | 1.4 | SKY |
| 2.5 | Tap "2" | 2 | 26/0 | 1.5 | SKY |
| 2.6 | Tap "0" | 0 | 26/0 | 2.0 | SKY |

**Innings complete (overs exhausted) → Innings Transition Modal appears.**
- Target: 27

### Innings Transition
1. **Step 1 (Summary)**: Verify score 26/0, tap "Next"
2. **Step 2 (Openers)**: Select MS Dhoni + Ravindra Jadeja as openers, tap "Next"
3. **Step 3 (Bowler)**: Select Rohit Sharma as opening bowler, tap "Start Innings"

### 2nd Innings (CSK batting, MI bowling)

| Ball | Action | Runs | Score | Overs |
|------|--------|------|-------|-------|
| 1.1-1.6 | Tap "0" x6 | 0 | 0/0 | 1.0 |

**Over complete → Select bowler (auto-select if only 1 eligible).**

| Ball | Action | Runs | Score | Overs |
|------|--------|------|-------|-------|
| 2.1-2.6 | Tap "0" x6 | 0 | 0/0 | 2.0 |

**Match complete → Modal shows "Mumbai Indians won by 26 runs".**
- Tap "View Scorecard"

---

## Group 4: Full Match — Win by Wickets (Target Chase)

### 1st Innings: Score 7 runs
- Over 1: 6 singles (6 runs) → select new bowler
- Over 2: 5 dots + 1 single (1 run) = 7 total
- Target: 8

### 2nd Innings: Chase succeeds mid-over
- Ball 1: Tap "6" (6 runs)
- Ball 2: Tap "1" (7 runs)
- Ball 3: Tap "1" (8 runs) → **TARGET CHASED! Match ends immediately.**
- Result: "CSK won by 2 wickets" (3 players - 1 - 0 wickets = 2)

---

## Group 5: Full Match — All Out

### 1st Innings
- Ball 1: Tap "W" → Select "Bowled" → "Confirm Wicket" → Wicket 1
- **Select new batter** (auto-select if only 1 available: Player 3)
- Ball 2: Tap "W" → Select "Caught" → Select fielder → "Next" → "Confirm Wicket" → Wicket 2
- **ALL OUT (3 players - 1 = 2 wickets)**
- Innings complete with reason "All Out"

---

## Group 6: Full Match — Tie

### 1st Innings (1 over): All dots = 0 runs
### 2nd Innings: All out for 0 runs
- Wicket 1 (bowled) → select new batter → Wicket 2 (bowled) → all out
- Both innings: 0 runs → **Match Tied**

---

## Group 7: Extras Through UI

### 7.1 Wide
1. Tap "WD" → ExtrasPanel opens
2. Default runs = 0, total = 1 (penalty)
3. Tap "Confirm" → Score increases by 1
4. Verify: over ball count unchanged (wide is not legal)

### 7.2 Wide + additional runs
1. Tap "WD" → select "2" in ExtrasPanel
2. Tap "Confirm" → Score increases by 3 (1 penalty + 2)

### 7.3 No Ball
1. Tap "NB" → ExtrasPanel opens
2. Default runs = 0, total = 1 (penalty)
3. Tap "Confirm" → Score increases by 1
4. Verify: free hit indicator appears

### 7.4 Bye
1. Tap "B" → ExtrasPanel opens
2. Default runs = 1
3. Tap "Confirm" → Score increases by 1
4. Verify: legal delivery (over advances)

### 7.5 Leg Bye
1. Tap "LB" → ExtrasPanel opens
2. Default runs = 1
3. Tap "Confirm" → Score increases by 1
4. Verify: legal delivery (over advances)

---

## Group 8: Free Hit Mechanics Through UI

### 8.1 No-ball triggers free hit
- Record NB → verify free hit indicator in ThisOverDisplay

### 8.2 Wicket on free hit: only run out allowed
- Record NB → free hit active
- Tap "W" → WicketDialog: only "Run Out" enabled, others disabled/greyed

### 8.3 Wide on free hit persists
- Record NB → free hit active → record Wide → free hit still active

### 8.4 No-ball on free hit chains
- Record NB → free hit → record another NB → free hit still active

### 8.5 Legal delivery consumes free hit
- Record NB → free hit → tap "4" → free hit consumed

---

## Group 9: Strike Rotation Through UI

### 9.1 Odd runs swap striker
- Note striker name → tap "1" → striker name changes

### 9.2 Even runs keep striker
- Note striker name → tap "2" → striker name unchanged
- tap "4" → unchanged, tap "6" → unchanged

### 9.3 End of over swaps
- Bowl 6 dots → select new bowler → striker swapped from end of over

### 9.4 Odd runs + end of over = double swap (cancels out)
- Ball 1-5: dots, Ball 6: 1 run → 1 swap (odd) + 1 swap (over end) = back to original

### 9.5 Wide + odd additional runs = swap
- Record wide with 1 additional run → striker swaps

---

## Group 10: Undo Through UI

### 10.1 Undo run
- Tap "4" → score = 4 → tap Undo → score = 0

### 10.2 Undo wide
- Tap "WD" → confirm → score = 1 → tap Undo → score = 0, extras = 0

### 10.3 Undo after over completion
- Bowl 6 dots → over complete → tap Undo → over reopened, 5 balls in current over

### 10.4 Undo wicket
- Record wicket → wickets = 1 → tap Undo → wickets = 0

### 10.5 Undo disabled when no deliveries
- Fresh innings → Undo button is disabled

---

## Group 11: Maiden Over

### 11.1 Six dot balls = maiden
- Bowl 6 dots → verify bowler maiden count = 1
- Verify over marked as maiden in completed overs

### 11.2 Byes don't break maiden
- 5 dots + 1 bye → bowler maiden count = 1

---

## Group 12: Wicket Types Through UI

### 12.1 Bowled (1-step, no fielder)
- Tap "W" → select "Bowled" → button says "Confirm Wicket" (step 1 terminal) → tap → wicket recorded

### 12.2 Caught (2-step, fielder required)
- Tap "W" → select "Caught" → tap "Next" → step 2 (Select Fielder) → tap fielder → "Confirm Wicket"

### 12.3 LBW (1-step)
- Tap "W" → select "LBW" → "Confirm Wicket"

### 12.4 Run Out (3-step)
- Tap "W" → select "Run Out" → "Next" → select fielder → "Next" → step 3 (who dismissed, batters crossed, runs) → "Confirm Wicket"

### 12.5 Stumped (2-step)
- Tap "W" → select "Stumped" → "Next" → select fielder → "Confirm Wicket"

### 12.6 Hit Wicket (1-step)
- Tap "W" → select "Hit Wicket" → "Confirm Wicket"

### 12.7 Caught & Bowled (1-step)
- Tap "W" → select "C & B" → "Confirm Wicket"

---

## Group 13: Bowler Eligibility

### 13.1 Consecutive-over block
- Bowler A bowls over 1 → at over 2 selection, Bowler A is greyed out with "Bowled last over"

### 13.2 Max overs per bowler
- In a 2-over match with 3 players, max overs = ceil(2/5) = 1
- After bowling 1 over, bowler shows "Max overs reached"

---

## UI Interaction Quick Reference

| Action | Finder Pattern |
|--------|---------------|
| Tap run (0,1,2,3,4,6) | `find.text('N')` inside ScoringControls |
| Tap Wide | `find.text('WD')` |
| Tap No Ball | `find.text('NB')` |
| Tap Bye | `find.text('B')` |
| Tap Leg Bye | `find.text('LB')` |
| Tap Wicket | `find.text('W')` |
| Undo | Icon button with tooltip 'Undo' |
| Swap Strike | Icon button with tooltip 'Swap Strike' |
| Confirm Extra | `find.text('Confirm')` in ExtrasPanel |
| Select dismissal | `find.text('Bowled')` etc. in WicketDialog |
| Confirm Wicket | `find.text('Confirm Wicket')` |
| Next (WicketDialog) | `find.text('Next')` in dialog footer |
| Select bowler | Tap player name in SelectBowlerSheet |
| Select batter | Tap player name in SelectBatterSheet |
| Innings transition Next | `find.text('Next')` in modal footer |
| Start Innings | `find.text('Start Innings')` |
| View Scorecard | `find.text('View Scorecard')` |

## Auto-Select Behavior

With 3-player teams:
- **SelectBowlerSheet**: If only 1 eligible bowler, auto-selects via `addPostFrameCallback`
- **SelectBatterSheet**: If only 1 remaining batter, auto-selects via `addPostFrameCallback`
- After 1st wicket with 3rd batter entering, next wicket = all out (no batter selection needed)
