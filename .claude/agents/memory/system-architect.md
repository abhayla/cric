# System Architect Memory

## Architectural Decisions & Findings

- 2026-02-20: Sync bottleneck analysis -- broadcast query assembly (8 SELECTs after tx) is the main performance bottleneck, re-reads data just written in transaction
- 2026-02-20: recordDelivery transaction executes 15-27 DB ops per delivery; no ON CONFLICT upserts used for batting/bowling stats
- 2026-02-20: CRITICAL -- SyncService marks failed entries as synced after maxRetries (5), causing silent data loss
- 2026-02-20: CRITICAL -- innings UUID mismatch: client-generated inningsId for innings 2 won't match server-created UUID; client must send inningsNumber for offline sync
- 2026-02-20: Batch sync endpoint (POST /sync/push) is specced in API.md but NOT implemented; client sends individual POST per delivery
- 2026-02-20: SyncService only enqueues delivery entities, not innings/stats/overs -- relies on server-side recordDelivery to manage all dependent records
- 2026-02-20: At 100 concurrent matches (~3.3 del/sec), total DB load is ~115 queries/sec -- well within PG capacity; broadcast queries are the scaling bottleneck
- 2026-02-20: Total latency scorer-tap-to-viewer ~116-220ms online; local write gives instant UX at 5-10ms
- 2026-02-20: deliveryToOverBall helper is duplicated identically in scoring.ts and rooms.ts
- 2026-02-20: FIFO sync halts on first failure -- head-of-line blocking means one bad entry blocks all subsequent syncs
