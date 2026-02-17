# Match Scoring Flow

Step-by-step match scoring through UI taps for integration tests.

## Delivery Types and Tap Sequences

### Regular Runs (0, 1, 2, 3, 4, 6)
1. Find run button inside `ScoringControls` widget
2. `tester.tap(runButton)` -> `pumpAndSettle()` -> 300ms pause

### Extras — Wide (WD)
1. Tap "WD" button in `ScoringControls`
2. `ExtrasPanel` appears
3. Tap "Confirm" inside `ExtrasPanel`
4. Not a legal delivery (no ball count increment)

### Extras — No Ball (NB)
1. Tap "NB" button in `ScoringControls`
2. `ExtrasPanel` appears
3. Tap "Confirm" inside `ExtrasPanel`
4. Not a legal delivery (no ball count increment)

### Wicket
1. Tap "W" button in `ScoringControls`
2. `WicketDialog` appears
3. Tap dismissal type (e.g., "Bowled")
4. Tap `FilledButton` (confirm) in `WicketDialog`
5. If not all out: `SelectBatterSheet` appears
6. Tap new batter name -> `pumpAndSettle()`

## Random Delivery Generation

`RandomDeliveryType.pick(random)` uses weighted probabilities:

| Type | Weight | Probability |
|------|--------|------------|
| Dot | 30 | 30% |
| Single | 25 | 25% |
| Two | 15 | 15% |
| Three | 5 | 5% |
| Four | 10 | 10% |
| Six | 5 | 5% |
| Wicket | 5 | 5% |
| Wide | 3 | 3% |
| No Ball | 2 | 2% |

Total weight: 100

## playRandomInnings() Algorithm

```
Input: tester, matchRecord, inningsNumber, totalOvers, playersPerSide,
       bowlerNames, batterNames, magicOverNumber, random

State: wickets=0, legalBalls=0, currentOverBalls=0, bowlerIndex=0,
       lastBowlerIndex=-1, nextBatterIndex=2

WHILE wickets < maxWickets AND legalBalls < maxBalls:
  1. Check for MatchCompleteModal or InningsTransitionModal -> break if found
  2. Pick random delivery type (weighted)
  3. Guard: if wicket and near all-out, 50% chance to downgrade to dot
  4. Execute delivery tap sequence (see above)
  5. Record delivery in matchRecord
  6. If legal delivery: increment legalBalls, currentOverBalls
  7. If wicket: increment wickets, select next batter
  8. If currentOverBalls >= 6:
     a. Reset currentOverBalls to 0
     b. Rotate bowler (next index, skip last bowler for consecutive-over rule)
     c. Select new bowler via SelectBowlerSheet
  9. Check again for completion modals -> break if found
```

## Bowler Rotation

- 6 bowlers available per team (players 1-6)
- Rotate sequentially: bowler 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 0 -> ...
- Skip last bowler (consecutive-over rule): if `nextBowlerIdx == lastBowlerIndex`, skip to next
- After each over: `SelectBowlerSheet` appears, tap bowler name

## Innings Transition

`completeInningsTransition()` handles the 3-step `InningsTransitionModal`:

1. **Summary step**: Shows 1st innings score -> Tap "Next"
2. **Select openers**: Tap striker name, tap non-striker name -> Tap "Next"
3. **Select bowler**: Tap bowler name -> Tap "Start Innings"

Visual pauses: 600ms before/after transition.

## Match Completion Detection

The loop checks for two modals after each delivery:
- `MatchCompleteModal` — match is over (target chased, all out in 2nd innings)
- `InningsTransitionModal` — 1st innings complete

Detection: `find.byType(MatchCompleteModal).evaluate().isNotEmpty`

After match completion, dismiss via "Back to Home" button.

## Magic Over Handling

When `magicOverNumber` is set (e.g., 4):
- During that over, ALL runs are doubled by the scoring engine
- The test records doubled values in `DeliveryRecord`
- Strike rotation uses original (undoubled) runs
- Magic over applies to both innings

## DeliveryRecord Tracking

Every UI tap creates a `DeliveryRecord` with:
- `runsFromBat`, `isWide`, `wideRuns`, `isNoBall`, `noBallRuns`
- `isBye`, `byeRuns`, `isLegBye`, `legByeRuns`
- `isWicket`, `isBoundaryFour`, `isBoundarySix`
- `overNumber`, `ballNumber`, `isMagicOver`

Records accumulate in `MatchRecord` per innings, used for DB verification.
