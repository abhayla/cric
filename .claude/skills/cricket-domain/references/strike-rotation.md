# Strike Rotation Rules (7 Scenarios)

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
