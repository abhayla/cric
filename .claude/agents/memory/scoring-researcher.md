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
