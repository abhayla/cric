# Scoring Feature — Cricket Scoring Engine (Flutter)

## Architecture

The scoring feature is a client-side state machine that processes deliveries through a 10-step pipeline mirroring the server-side logic (`scoring.service.ts`). The `ScoringNotifier` (~960 lines) is the architectural centerpiece.

## 10-Step Delivery Pipeline (`_processDelivery`)

1. **Determine legal status** — Wide/no-ball = not legal (don't count toward over)
2. **Calculate total runs** — Sum: runsFromBat + wideRuns + noBallRuns + byeRuns + legByeRuns
3. **Create delivery record** — Immutable `Delivery` entity with generated UUID
4. **Update innings totals** — Runs, balls (legal only), extras by type, wickets
5. **Update batter stats** — Balls faced (legal only), runs, boundaries, dismissal
6. **Update bowler stats** — Balls bowled, runs conceded, wickets, wides/no-balls, dot balls
7. **Calculate strike change** — Odd runs swap, wicket resets, end-of-over swap (see below)
8. **Check over completion** — 6 legal balls → save over record, update maiden count, clear bowlerId
9. **Determine free hit** — No-ball → next delivery is free hit; free hit + no-ball → chain continues
10. **Check innings completion** — All-out, overs exhausted, target chased, declaration

## Strike Rotation Rules

Handled by `ScoringUtils.shouldSwapStrike()` + end-of-over swap in step 7:

| Scenario | Swap? |
|----------|-------|
| Odd bat runs (1,3,5) | YES |
| Even bat runs (0,2,4,6) | NO |
| End of over | YES |
| Wide + odd additional runs | YES |
| Bye/leg-bye odd runs | YES |
| Odd runs + end of over | NO (double swap cancels) |
| Wicket | New batter takes striker end |

## Extras Quick Reference

| Extra | Legal? | Batter credit | Bowler concedes | Breaks maiden |
|-------|--------|--------------|----------------|---------------|
| Wide | NO | No | Yes (penalty + runs) | Yes |
| No-ball | NO | Bat runs only | Yes (penalty + bat runs) | Yes |
| Bye | YES | No | No | No |
| Leg-bye | YES | No | No | No |

Penalty runs (wide/no-ball) are configurable per match via `wideRunsPenalty`/`noBallRunsPenalty` fields (default: 1).

## State Design (`ScoringState`)

Hand-written class (not Freezed) with sentinel-based `copyWith` for nullable fields:

```dart
const _unset = Object();
// In copyWith: strikerId == _unset ? this.strikerId : strikerId as String?
```

Key field groups:
- **Match context** (immutable per innings): matchId, inningsId, teamIds, totalOvers, playersPerSide
- **Current players**: strikerId, nonStrikerId, bowlerId (nullable — null between overs)
- **Innings totals**: totalRuns, totalWickets, totalBalls, per-extra-type totals, target
- **Over state**: currentOverBalls (0-5), currentOverDeliveries[], completedOvers[], isFreeHitPending
- **Player stats**: `Map<String, BatterInnings>`, `Map<String, BowlerSpell>`, lastBowlerId
- **Completion**: isInningsComplete, isMatchComplete, completionReason
- **Undo**: deliveryHistory (ordered list of all deliveries)

## Undo (`undoLastDelivery`)

8-step reverse: remove delivery → reverse innings totals → reverse batter stats → reverse bowler stats → reverse strike → reopen over if needed → reverse free hit → reverse completion flags. Constraints: only last delivery, only by scorer.

## Key Domain Entities

| File | Entity | Purpose |
|------|--------|---------|
| `delivery.dart` | `Delivery`, `DismissalType` (12), `InningsCompletionReason` | Atomic ball record |
| `wicket_info.dart` | `WicketInfo` | Dismissal context per delivery |
| `batter_innings.dart` | `BatterInnings` | Live batting stats (R, B, 4s, 6s, SR) |
| `bowler_spell.dart` | `BowlerSpell` | Live bowling stats (O, M, R, W, Ec) |
| `over.dart` | `Over` | Completed over record |
| `innings.dart` | `Innings` | Innings-level aggregates |
| `playing_xi_player.dart` | `PlayingXIPlayer` | Roster player with role/style metadata |

## Core Utilities

- `ScoringUtils` (`core/utils/scoring_utils.dart`) — Pure functions: `isLegalDelivery`, `calculateTotalRuns`, `shouldSwapStrike`, `isOverComplete`, `checkInningsCompletion`, `isMaidenOver`, `isNextFreeHit`, `validateExtras`, `validateBatterPair`
- `CricketConstants` (`core/constants/cricket_constants.dart`) — `ballsPerOver=6`, `defaultWideRuns=1`, `defaultNoBallRuns=1`, `defaultPlayersPerSide=11`
- `CricketUtils` (`core/utils/cricket_utils.dart`) — Display formatting helpers

## Bowler Eligibility

Computed in `ScoringState.bowlerOptions` getter:
- **Consecutive-over block**: bowler who bowled the last over (`lastBowlerId`) is ineligible
- **Max overs**: `maxOversPerBowler` (explicit) or `ceil(totalOvers / 5)` (default cap)

## Widget-Notifier Integration

Widgets call notifier methods → notifier runs pipeline → state updates → widgets rebuild:
- `ScoringControls` → `recordDelivery(runs)`, `swapStrike()`, `undoLastDelivery()`
- `ExtrasPanel` → `recordWide/NoBall/Bye/LegBye(runs)`
- `SelectBatterSheet` → `selectNewBatter(playerId)`
- `SelectBowlerSheet` → `selectNewBowler(playerId)`
- `ScoringPage` watches `needsNewBatter`/`needsNewBowler` flags to auto-show sheets
