---
name: cricket-domain
description: "Cricket domain rules reference for match state machine, delivery pipeline, strike rotation, extras, dismissals, undo logic, and MVP algorithm. Use when working on scoring features, user asks about cricket rules, or needs to verify scoring logic correctness."
allowed-tools: Read
metadata:
  version: 1.0.0
---

# Cricket Domain Rules Reference

Full cricket rules for CricScores scoring engine. Source of truth: [SCORING_RULES.md](../../docs/planning/SCORING_RULES.md).

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

## Quick Reference

- **Delivery pipeline:** 10 steps (validate → calculate → extras → wicket → strike → stats → over → innings → broadcast → persist). See [references/delivery-pipeline.md](references/delivery-pipeline.md).
- **Strike rotation:** 7 scenarios (odd/even runs, over end, wides, wickets). See [references/strike-rotation.md](references/strike-rotation.md).
- **Dismissals:** 12 types with fielder/bowler credit rules + undo logic. See [references/dismissals.md](references/dismissals.md).
- **MVP algorithm:** Batting + Bowling + Fielding point system. See [references/mvp-algorithm.md](references/mvp-algorithm.md).

## Innings Completion Conditions (4)

1. **ALL OUT** — `players_per_side - 1` wickets fallen (not hardcoded 10)
2. **OVERS EXHAUSTED** — Maximum overs bowled (T20=20, ODI=50, custom)
3. **TARGET CHASED** (2nd innings only) — Batting team total exceeds 1st innings total; match ends immediately
4. **DECLARATION** (manual) — Batting team declares

## Key Edge Cases

- Wide + run out (wide recorded + run out dismissal, no legal ball counted)
- No-ball + free hit chain (no-ball → free hit → another no-ball → another free hit)
- Last ball of over + wicket with odd runs (apply run swap? then over swap? then wicket?)
- All out on a wide (10th wicket stumped off a wide — wide runs + stumping + innings over)
- Target chased on extras (wide gives winning run — match ends immediately)

## Full Reference

For complete rules with all subsections, read: `docs/planning/SCORING_RULES.md`
