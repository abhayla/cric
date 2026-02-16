# MVP Algorithm

## Batting Points
- Base: 1 point per 10 runs scored
- Strike rate bonus: +0.5 if batter SR > team SR; -0.5 if below; 0 if within 10%
- Milestone: 50 runs → +2; 100 runs → +5 (replaces 50 bonus, not additive)
- Boundaries: +0.1 per four, +0.2 per six

## Bowling Points
- Base: 3 points per wicket
- Economy bonus: +1 if below match average economy; -1 if above; 0 if within 0.5
- Maiden over bonus: +1 per maiden
- Milestone: 3 wickets → +3; 5 wickets → +5 (replaces 3W bonus, not additive)

## Fielding Points
- Catch: +1.5 | Run out (direct hit): +2.0 | Run out (assist): +1.0 | Stumping: +1.5

## Total
MVP Score = Batting + Bowling + Fielding. Tie-breaker: Batting > Bowling > Fielding.
