---
name: cricket-domain
description: Cricket domain rules reference. Auto-loaded when working on scoring features. Contains match state machine, delivery pipeline, strike rotation, extras handling, dismissals, undo logic, and MVP algorithm.
allowed-tools: Read
---

# Cricket Domain Rules Reference

Full cricket rules for CricApp scoring engine. Source of truth: [SCORING_RULES.md](../../docs/planning/SCORING_RULES.md).

## Match State Machine

```
SETUP → TOSS → LIVE → INNINGS_BREAK → LIVE → COMPLETED
                                                  ↓
                                             SUPER_OVER (if tied)

At any point: → ABANDONED
```

| From | To | Trigger |
|------|----|---------|
| SETUP | TOSS | Both teams selected, match params set |
| TOSS | LIVE | Toss winner/decision recorded, opening players selected |
| LIVE (1st) | INNINGS_BREAK | All out OR overs exhausted OR declaration |
| INNINGS_BREAK | LIVE (2nd) | Opening players for 2nd innings selected |
| LIVE (2nd) | COMPLETED | All out OR overs exhausted OR target chased |
| LIVE (2nd) | SUPER_OVER | Scores tied after both innings |
| Any | ABANDONED | Manual abandonment by scorer |

During `LIVE`, `innings.innings_number` distinguishes 1st vs 2nd innings. Tied scores → COMPLETED with "Match Tied".

## 10-Step Delivery Processing Pipeline

Every ball bowled follows this exact sequence:

1. **VALIDATE** — Valid batter pair, valid bowler (not same as last over), match in live state
2. **CALCULATE RUNS** — `runs_from_bat` + `wide_runs` + `no_ball_runs` + `bye_runs` + `leg_bye_runs` = `total_runs`
3. **HANDLE EXTRAS** — Wide: +1 to extras, NOT legal; No-ball: +1 to extras, NOT legal, next = free hit; Bye/LB: runs to extras, IS legal
4. **PROCESS WICKET** — Record dismissal type + fielder + bowler credit, update fall of wickets, check all out
5. **ROTATE STRIKE** — Odd runs swap; even runs no swap; end of over swaps; wide+odd swaps
6. **UPDATE STATS** — batting_stats, bowling_stats, fielding_stats, innings totals
7. **CHECK OVER** — 6 legal deliveries = over complete, check maiden, require new bowler
8. **CHECK INNINGS** — All out, overs exhausted, target chased, declaration
9. **BROADCAST** — WebSocket `score_update` to match room subscribers
10. **PERSIST** — Save to local Drift DB (synced=false), queue for server sync

## Strike Rotation Rules (7 Scenarios)

```
Odd runs from bat (1, 3, 5)       → SWAP striker/non-striker
Even runs (0, 2, 4, 6)            → NO SWAP
End of over                        → SWAP (regardless of last ball)
Wide + odd additional runs         → SWAP
Bye/Leg-bye follows same odd/even rule

End-of-over special:
  After over swap, if last ball was odd runs, the two swaps cancel out
  (odd_swap + over_swap = no net swap).
  Implementation: Apply run-based swap first, then apply over swap.

Wicket (caught): New batter at striker end
Wicket (run out): Depends on which end — crossed or not crossed matters
```

## Extras Comparison Table

| Extra | Legal Delivery? | Batter Credit? | Against Bowler? | Breaks Maiden? | Dismissals Possible |
|-------|----------------|----------------|-----------------|----------------|---------------------|
| Wide | No | No | Yes | Yes | Stumped, Run out |
| No-ball | No | Bat runs: yes | Yes | Yes | Run out only (free hit next ball) |
| Bye | Yes | No | No | No | Any |
| Leg-bye | Yes | No | No | No | Any |

### Free Hit Rules
- Triggered after any no-ball
- Only run out (#4) dismissal is possible on a free hit delivery
- If free hit delivery is also a no-ball → another free hit follows (chain)
- Free hit flag propagates to the NEXT delivery after the no-ball

## Dismissal Types (12)

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

## Maiden Over Definition

A maiden over requires ALL of:
- `runs_from_bat` across all 6 legal deliveries = 0
- `wide_runs` across entire over = 0
- `no_ball_runs` across entire over = 0

Byes and leg-byes do NOT break a maiden (they don't count against the bowler).

## Innings Completion Conditions (4)

1. **ALL OUT** — `players_per_side - 1` wickets fallen (not hardcoded 10)
2. **OVERS EXHAUSTED** — Maximum overs bowled (T20=20, ODI=50, custom)
3. **TARGET CHASED** (2nd innings only) — Batting team total exceeds 1st innings total; match ends immediately (mid-over possible)
4. **DECLARATION** (manual) — Batting team declares

## Undo Logic (8 Steps + 3 Constraints)

Undo removes the most recent delivery and reverses ALL state changes:

1. Remove delivery record from local DB
2. Reverse batting stats (subtract runs, balls faced, fours/sixes)
3. Reverse bowling stats (subtract runs conceded, ball count, wickets)
4. Reverse innings totals (subtract total runs, extras, wickets)
5. Reverse strike change (if runs caused a swap, swap back; if over ended, reverse over swap)
6. Reverse wicket (remove fall of wickets entry, restore dismissed batter, remove fielding credit)
7. Handle edge cases: undo first ball of over → go back to previous over; undo after over change → reopen previous over; undo first ball of innings → error
8. Send undo via WebSocket to update all viewers

**Constraints:**
- Only the LAST delivery can be undone
- Only the scorer can undo
- Cannot undo after innings/match completion without reopening
- Multiple consecutive undos are allowed

## MVP Algorithm

**Batting Points:**
- Base: 1 point per 10 runs scored
- Strike rate bonus: +0.5 if batter SR > team SR; -0.5 if below; 0 if within 10%
- Milestone: 50 runs → +2; 100 runs → +5 (replaces 50 bonus, not additive)
- Boundaries: +0.1 per four, +0.2 per six

**Bowling Points:**
- Base: 3 points per wicket
- Economy bonus: +1 if below match average economy; -1 if above; 0 if within 0.5
- Maiden over bonus: +1 per maiden
- Milestone: 3 wickets → +3; 5 wickets → +5 (replaces 3W bonus, not additive)

**Fielding Points:**
- Catch: +1.5 | Run out (direct hit): +2.0 | Run out (assist): +1.0 | Stumping: +1.5

**Total:** MVP Score = Batting + Bowling + Fielding. Tie-breaker: Batting > Bowling > Fielding.

## Key Edge Cases

- Wide + run out (wide recorded + run out dismissal, no legal ball counted)
- No-ball + free hit chain (no-ball → free hit → another no-ball → another free hit)
- Last ball of over + wicket with odd runs (apply run swap? then over swap? then wicket?)
- All out on a wide (10th wicket stumped off a wide — wide runs + stumping + innings over)
- Target chased on extras (wide gives winning run — match ends immediately)

## Full Reference

For complete rules with all subsections, read: `docs/planning/SCORING_RULES.md`
