# 10-Step Delivery Processing Pipeline

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

## Maiden Over Definition

A maiden over requires ALL of:
- `runs_from_bat` across all 6 legal deliveries = 0
- `wide_runs` across entire over = 0
- `no_ball_runs` across entire over = 0

Byes and leg-byes do NOT break a maiden (they don't count against the bowler).
