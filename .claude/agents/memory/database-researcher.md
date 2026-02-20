# Database Researcher Memory

## Schema & Transaction Findings

- 2026-02-20: wagon_wheel_zones FK on deliveries is nullable (`onDelete: 'set null'`) — not all deliveries have shot data
- 2026-02-20: batting_stats and bowling_stats have no ON CONFLICT clause — upsertBattingStats/upsertBowlingStats use SELECT-then-INSERT or SELECT-then-UPDATE pattern, not true PostgreSQL upserts
- 2026-02-20: overs table has a unique constraint `uq_overs_innings_over` on (innings_id, over_number) — safe to use INSERT ... ON CONFLICT DO UPDATE for over records
- 2026-02-20: batting_stats has no unique constraint on (innings_id, player_id) — needs one before ON CONFLICT upsert can be used
- 2026-02-20: bowling_stats has no unique constraint on (innings_id, player_id) — same gap as batting_stats
- 2026-02-20: fielding_stats has no unique constraint on (innings_id, player_id) — same gap
- 2026-02-20: deliveries.synced column exists on the server-side schema (not just mobile); this is unusual — synced flag is server-side metadata for push-to-mobile flows if needed
- 2026-02-20: innings table has no index on (match_id, innings_number) — every innings cache miss does a full scan filtered by match_id (small table, low risk, but worth noting)
- 2026-02-20: recordDeliveryInTx issues 2 separate SELECTs per delivery for free-hit detection and sequence number; both could be collapsed into one CTE query
- 2026-02-20: checkOverCompletion re-reads all deliveries for the over (SELECT *) to compute maiden/runs — this data is already known from the batch being processed; redundant DB read in batch context
- 2026-02-20: career stats refresh (refreshMatchPlayerCareerStats) runs as 8 optimized GROUPING SETS queries inside the same batch transaction — already well-optimized, not a bottleneck
- 2026-02-20: The batch transaction holds row-level locks on innings, batting_stats, bowling_stats for the entire duration (~1-5 seconds for T20); concurrent writes to same match are blocked (acceptable: only 1 scorer per match)
- 2026-02-20: No statement_timeout set on the batch transaction — a 300-delivery batch could run 10-30 seconds; PostgreSQL default is no timeout; risk of OOM or client disconnect leaving orphaned transaction
- 2026-02-20: Multi-row INSERT VALUES for deliveries is feasible — all delivery fields are known upfront in batch; stats computation is the dependency that prevents pure bulk-insert
- 2026-02-20: Per-over mini-transaction strategy (6 deliveries per tx) is valid optimization — reduces WAL pressure and lock duration; compatible with innings cache pattern already in code
- 2026-02-20: Post-insert aggregate stat computation via SQL SUM/GROUP BY is viable for batting_stats and bowling_stats — avoids row-by-row accumulation, replaces ~480 SELECTs+UPDATEs with ~4 queries for T20
