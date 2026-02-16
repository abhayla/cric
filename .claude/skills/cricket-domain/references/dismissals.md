# Dismissal Types (12)

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
