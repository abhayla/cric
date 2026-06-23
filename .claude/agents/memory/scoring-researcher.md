# Scoring Researcher — Accumulated Knowledge

## Sync Service Insights

- 2026-02-20: incrementRetry in batch failure path is N+1 query pattern (SELECT+UPDATE per entry) — should be bulk UPDATE
- 2026-02-20: Server batch endpoint wraps ALL deliveries in single PostgreSQL transaction — partial failure = full rollback, no duplicate risk
- 2026-02-20: Server has UUID-based idempotency check for each delivery in batch (scoring.service.ts line 664-673)
- 2026-02-20: Match completion mid-batch causes server to stop processing remaining deliveries (line 661) — those entries become permanently orphaned in client queue
- 2026-02-20: _isSyncing guard can silently drop immediate sync triggers, but while-loop re-queries DB so current cycle picks up new entries
- 2026-02-20: No exponential backoff on retry — server under load gets hammered every 10 seconds regardless of failure count
- 2026-02-20: No connectivity check before sync attempt — offline devices waste time on Dio timeouts
- 2026-02-20: Batch threshold hardcoded at 6 — periodic timer triggers should prefer batch mode regardless of count
- 2026-02-20: Network timeout on successful batch causes retry count escalation even though server has the data — could lead to false "failed" status

## Client Scoring Notifier Insights

- 2026-06-23: scoring_notifier.dart is now ~1515 lines (not ~1400 per docs). Pipeline has half-steps 2.5 (magic over multiplier) and 4.5 (fall-of-wickets cache) interleaved.
- 2026-06-23: DismissalType enum has 11 values, NOT 12 as scoring CLAUDE.md claims. Missing "handled the ball"/"hit the ball twice". IDs 10 (timedOut) / 11 (obstructingField) are non-MVP (isMvpActive => id <= 9).
- 2026-06-23: Free-hit/wide/no-ball dismissal restrictions (isValidOnFreeHit/isValidOnWide/isValidOnNoBall on DismissalType) exist as getters but are NOT enforced in _processDelivery/recordWicket — UI-layer enforcement only. Gap.
- 2026-06-23: Run-out always nulls strikerId (scoring_notifier.dart:1385) regardless of WicketInfo.battersCrossed — battersCrossed field captured but unused by engine. Likely wrong-end bug for non-striker run-outs / crossed runs.
- 2026-06-23: Magic over multiplies stored Delivery component values (effectiveRunsFromBat etc) but Step 7 shouldSwapStrike uses RAW inputs — multiplier does NOT change strike parity. Undo de-multiplies (~:818-839) before re-checking swap.
- 2026-06-23: undoBlockedByTransition set true by selectNewBatter/selectNewBowler when history non-empty; blocks undo across player-transition boundary; reset on next committed delivery and inside undo.
- 2026-06-23: isRealWicket (!=retiredHurt && !=retiredOut && isMvpActive) gates totalWickets increment AND all-out check — retired hurt/out don't count toward all-out (playersPerSide-1).
- 2026-06-23: Over completion sets bowlerId=null in commit (:1498) -> needsNewBowler getter -> UI shows select bowler. lastBowlerId drives consecutive-over ineligibility in bowlerOptions. effectiveMax bowler overs = maxOversPerBowler ?? ceil(totalOvers/5).
- 2026-06-23: End-of-over strike swap (:1436) only runs if both striker AND non-striker non-null — wicket on last ball nulls striker, so swap skipped (incoming batter correctly takes strike).
- 2026-06-23: fallOfWickets computed TWO ways — ScoringState.fallOfWickets getter recomputes from history (:399), notifier keeps _cachedFallOfWickets incrementally (:626). Divergence risk.
- 2026-06-23: Tied knockout (newTotalRuns==firstRuns) forces isMatchComplete=false and needsSuperOver=true instead of completing (:1472-1481). startSuperOver resets to 1 over / 3 players (2 wkts = all out).
