# Sync Architecture — Decision Document

**Date:** 2026-02-21
**Status:** Decision Made — Option A+E (Batch HTTP with Hybrid Trigger)
**Context:** Delivery sync from mobile scorer to server is too slow and has correctness bugs

---

## Problem Statement

Three problems with the current per-delivery sync architecture:

1. **Slow sync throughput**: 1 delivery/sec (individual HTTP POST + DB transaction each). A T20 match backlog (254 deliveries) takes 4-5 minutes. Users want server-side stats immediately after match ends.
2. **FIFO ordering dependency**: Server has separate innings records. If innings-2 deliveries hit the sync queue before innings-1 finishes syncing (creating the innings-2 record on server), they fail and block everything behind them.
3. **Silent data loss**: When `retryCount >= 5`, the entry is `markSynced()` (skipped) — the delivery is permanently lost without any error surfacing to the user.

**Business requirements:**
- Parallel scoring of multiple matches simultaneously
- 100s to 1000s of viewers per match watching live ball-by-ball updates
- Offline-first: scoring must continue without internet
- Fast sync when connectivity returns

---

## Current Architecture

```
Flutter SyncService (sync_service.dart)
  └── while(pendingEntries) {
        entry = next from SQLite sync_queue
        POST /api/v1/matches/{id}/deliveries  ← 1 HTTP round-trip per delivery
        if fail → break (FIFO stop)           ← blocks entire queue
      }

Server per-delivery route (scoring.ts → scoring.service.ts)
  └── pre-validate (1 SELECT)
  └── db.transaction() {
        re-validate match (1 SELECT)
        resolve innings (1 SELECT)
        validate innings (1 SELECT)
        get max sequence number (1 SELECT)
        get previous delivery for free-hit (1 SELECT)
        check duplicate (1 SELECT)
        INSERT delivery (1 INSERT)
        INSERT wicket + fall_of_wickets (conditional, 2 INSERTs)
        upsertBattingStats × 2 (2 SELECT + 2 UPSERT)
        upsertBowlingStats (1 SELECT + 1 UPSERT)
        upsertFieldingStats (conditional)
        UPDATE innings totals (1 UPDATE)
        checkOverCompletion (2 SELECT + 1 UPSERT)
        re-read innings (1 SELECT)
        checkInningsCompletion → possible UPDATE + INSERT
      }
  └── post-transaction broadcast queries (5-8 more SELECTs)
  └── broadcastScoreUpdate()

Total: ~15-25 DB operations per delivery, ~1 HTTP round-trip, ~1 second wall time
254 deliveries × 1 second = ~4.25 minutes
```

---

## Options Evaluated

### All Five Approaches

| Approach | Throughput Fix | Ordering Fix | Live Viewer Latency | Complexity | Verdict |
|----------|:---:|:---:|:---:|:---:|---------|
| **A+E. Batch HTTP + Hybrid Trigger** | Yes (90% faster) | Yes (with inningsMetadata) | Unchanged (~200ms) | Medium | **SELECTED** |
| B. Full State Snapshot | Yes | Yes | Degrades (jarring reset) | High | Reject — client becomes trusted source of stats |
| **C. WebSocket Bidirectional** | Online only | No | Best (~50ms) | High | **Defer to Phase 8** |
| D. Event Sourcing/CQRS | Same as A | Yes | Adds delay | Highest | Over-engineered for single-scorer |
| E. Hybrid trigger (standalone) | Wraps A | Wraps A | N/A | Low | Combined with A |

---

## Head-to-Head: Batch HTTP (A+E) vs WebSocket Bidirectional (C)

### How Each Works

```
═══════════════════════════════════════════════════════════════════
OPTION A+E: BATCH HTTP + HYBRID TRIGGER
═══════════════════════════════════════════════════════════════════

ONLINE (live scoring):
  Scorer ──POST /deliveries──▶ Server ──WS broadcast──▶ 1000 viewers
           (HTTP, ~200ms)              (instant)

OFFLINE BACKLOG:
  Scorer ──POST /deliveries/batch──▶ Server ──WS match_state──▶ viewers
           (HTTP, 100 deliveries)            (1 snapshot)
           3-8 sec total

  Two endpoints:  /deliveries       (single, for live)
                  /deliveries/batch (bulk, for backlog)

═══════════════════════════════════════════════════════════════════
OPTION C: WEBSOCKET BIDIRECTIONAL
═══════════════════════════════════════════════════════════════════

ONLINE (live scoring):
  Scorer ──WS message──▶ Server ──WS broadcast──▶ 1000 viewers
           (~50ms)               (instant)

OFFLINE BACKLOG:
  Scorer ──WS stream (254 msgs)──▶ Server ──WS match_state──▶ viewers
           (rapid fire over                 (1 snapshot at end)
            persistent connection)
           ~5-15 sec total

  One channel: WebSocket for everything (read + write)
```

### Detailed Comparison

```
┌─────────────────────────┬──────────────────────┬──────────────────────┐
│                         │   A+E: BATCH HTTP    │  C: WS BIDIRECTIONAL │
├─────────────────────────┼──────────────────────┼──────────────────────┤
│                         │                      │                      │
│  LIVE SCORING LATENCY   │  ~200ms              │  ~50ms               │
│  (ball-by-ball)         │  (HTTP round-trip)   │  (no handshake)      │
│                         │                      │                      │
│  BACKLOG THROUGHPUT     │  3-8 sec             │  5-15 sec            │
│  (254 deliveries)       │  (1-3 batch requests)│  (254 WS msgs, each │
│                         │                      │   still needs DB tx) │
│                         │                      │                      │
│  ORDERING FIX           │  Yes                 │  No                  │
│  (innings dependency)   │  (inningsMetadata    │  (still per-delivery │
│                         │   in batch payload)  │   processing)        │
│                         │                      │                      │
│  SILENT DATA LOSS FIX   │  Yes                 │  Worse               │
│                         │  (atomic transaction │  (WS fire-and-forget │
│                         │   = all or nothing)  │   no HTTP status)    │
│                         │                      │                      │
│  SERVER DB LOAD         │                      │                      │
│  (100 concurrent        │  100-300 txns        │  25,400 txns         │
│   matches backlog)      │  (batched)           │  (still per-delivery)│
│                         │                      │                      │
│  SERVER DB LOAD         │  ~3/sec              │  ~3/sec              │
│  (100 matches LIVE)     │  (same either way)   │  (same either way)   │
│                         │                      │                      │
│  VIEWER EXPERIENCE      │  1 clean snapshot    │  254 rapid-fire msgs │
│  (during backlog)       │                      │  OR custom buffering │
│                         │                      │                      │
│  OFFLINE RELIABILITY    │  Queue in SQLite     │  WS is dead offline  │
│                         │  Batch on reconnect  │  Still needs HTTP    │
│                         │                      │  fallback queue!     │
│                         │                      │                      │
│  AUTH                   │  Existing ElysiaJS   │  Must reimplement    │
│                         │  middleware works     │  (WS upgrade happens │
│                         │                      │   before middleware)  │
│                         │                      │                      │
│  ACK / CONFIRMATION     │  HTTP 201/4xx/5xx    │  Must build custom   │
│                         │  (built-in)          │  ack protocol        │
│                         │                      │  (msg_id → ack_id)   │
│                         │                      │                      │
│  RETRY ON FAILURE       │  HTTP status code    │  Must detect failure │
│                         │  → retry or skip     │  from missing ack    │
│                         │                      │  + timeout           │
│                         │                      │                      │
│  CONNECTION MANAGEMENT  │  Stateless           │  Must handle:        │
│                         │  (Dio handles it)    │  - reconnect logic   │
│                         │                      │  - heartbeat/ping    │
│                         │                      │  - message redelivery│
│                         │                      │  - duplicate detect  │
│                         │                      │                      │
│  IMPLEMENTATION EFFORT  │  Medium              │  High                │
│  (server)               │  1 new endpoint      │  Rewrite WS handler  │
│                         │  1 service function  │  + auth + ack proto  │
│                         │                      │  + scoring logic     │
│                         │                      │                      │
│  IMPLEMENTATION EFFORT  │  Small               │  High                │
│  (client)               │  Modify SyncService  │  New WS scoring      │
│                         │  batch threshold     │  client + reconnect  │
│                         │                      │  + offline fallback  │
│                         │                      │                      │
│  TESTING EFFORT         │  Low                 │  High                │
│                         │  Extend existing     │  All new: WS auth,   │
│                         │  scoring tests       │  ack, reconnect,     │
│                         │                      │  offline fallback    │
│                         │                      │                      │
│  CODE PATHS             │  2 (single + batch)  │  3 (WS online +     │
│                         │                      │  HTTP offline +      │
│                         │                      │  HTTP batch backup)  │
│                         │                      │                      │
│  WHAT BREAKS            │  Nothing existing    │  Clean separation of │
│                         │                      │  HTTP=write, WS=read │
│                         │                      │  is destroyed        │
└─────────────────────────┴──────────────────────┴──────────────────────┘
```

### Critical Insight: Option C Still Needs A+E

```
Option C ALONE is insufficient:

  Scorer goes offline
       │
       ▼
  WS connection dies ──▶ Can't send deliveries over WS
       │
       ▼
  Must queue locally in SQLite (same as today)
       │
       ▼
  Comes back online, WS reconnects
       │
       ▼
  NOW WHAT? Stream 254 msgs over WS? ──▶ Still per-delivery DB txns!
                                          Still innings ordering problem!
                                          Still no atomicity!
       │
       ▼
  OR... fall back to HTTP batch endpoint ──▶ That's just Option A+E
```

- **Option C without A+E** = still has the backlog problem AND the ordering bug AND the silent data loss. Only makes the online path 150ms faster while adding massive complexity.
- **Option C with A+E** = 50ms live latency + fast batch backlog. But now 3 code paths instead of 2.

### The 150ms Difference in Context

```
Cricket scoring reality:

  Bowler runs in ────────────────────── 15-30 seconds
  Ball is bowled  ─────────────────────  0.5 seconds
  Scorer observes result ──────────────  2-5 seconds
  Scorer taps button ──────────────────  1-3 seconds
  ════════════════════════════════════════════════════
  Total: 20-40 seconds between deliveries

  HTTP sync latency:  200ms  (0.5% of the gap)
  WS sync latency:     50ms  (0.1% of the gap)
  Difference:         150ms  ← viewer literally cannot perceive this
```

Viewers see the score update 20-40 seconds after the ball is bowled regardless of whether sync takes 50ms or 200ms. The bottleneck is the human scorer, not the transport.

---

## Decision: Option A+E (Batch HTTP with Hybrid Trigger)

### How It Works

```
ONLINE (normal live scoring — 1 ball every 30-60 sec):
  Same as today: per-ball POST → immediate broadcast → viewers see it in <200ms

OFFLINE BACKLOG (coming back online with 10+ queued deliveries):
  SyncService detects queue depth > 10
       │
       ▼
  Collects up to 100 deliveries + innings metadata
       │
       ▼
  POST /api/v1/matches/:id/deliveries/batch
       │
       ▼
  Server: ONE transaction (creates missing innings, processes all deliveries)
       │
       ▼
  ONE match_state broadcast to viewers (not 254 individual updates)
       │
       ▼
  ~3-8 seconds instead of ~4-5 minutes
```

### Why This is Best for Business Requirements

**"Parallel score multiple matches":**
- Current: 100 matches syncing backlogs = 25,400 individual DB transactions hammering PostgreSQL
- Batch: 100 matches syncing backlogs = 100-300 transactions. ~100x less DB contention

**"100s/1000s of viewers":**
- Current: 254 rapid-fire WebSocket broadcasts per match during backlog = viewer UI flickers through 254 state changes
- Batch: 1 `match_state` snapshot per match = viewers see clean, instant catch-up

**Offline-first integrity:**
- Current: Silent data loss after 5 retries, innings UUID mismatch
- Batch: `inningsMetadata` in payload eliminates ordering dependency; single transaction = all-or-nothing (no partial sync)

### Three Bugs Fixed Together

| Bug | Current Behavior | Fix |
|-----|-----------------|-----|
| **Slow sync** | 1 delivery/sec, 4-5 min for T20 | Batch endpoint: 3-8 sec |
| **Silent data loss** | `markSynced()` after 5 failures = delivery permanently lost | Never mark failed entries as synced; surface error to UI |
| **Innings UUID mismatch** | Client inningsId ≠ server inningsId → 404 | Batch includes `inningsMetadata`; server creates missing innings in same transaction |

### Performance Projections

| Metric | Current | Batch (A+E) |
|---|---|---|
| T20 backlog sync time | ~254 seconds (4.25 min) | 3-8 seconds |
| HTTP round trips for backlog | 254 | 1-3 |
| DB transactions for backlog | 254 | 1 |
| DB operations for backlog | ~5,000 | ~5,000 (same work, fewer txns) |
| Live viewer latency (online) | ~200ms | Unchanged (~200ms) |
| Live viewer latency after backlog | 4-5 min delay | 3-8 sec delay |
| Innings ordering failure risk | High | Eliminated |

### Implementation Plan

| Phase | What | Effort |
|-------|------|--------|
| 1. Refactor | Extract `recordDeliveryInTx()` from existing `recordDelivery()` — no behavior change | Small |
| 2. Server batch endpoint | `POST /:id/deliveries/batch` + `recordDeliveryBatch()` service + tests | Medium |
| 3. Client batch trigger | `SyncService` detects queue depth > 10, sends batch, includes innings metadata | Small |
| 4. E2E verification | Existing `full_t20_e2e_test.dart` — reduce polling window from 5 min to ~30 sec | Trivial |

---

## Viewer Gap Detection via Delivery Counter

During rapid scoring or brief WS disconnects, the fast-path relay can silently drop messages. The viewer detects gaps using an incrementing `deliveryCount` in `score_update` payloads.

### How It Works

1. **Scorer** includes `deliveryCount` (= `deliveryHistory.length`) in every `score_update` payload
2. **Server** includes `deliveryCount` (= `COUNT(*)` on deliveries table for current innings) in every `match_state` snapshot
3. **Viewer** tracks `lastDeliveryCount` and checks each incoming `score_update`:
   - `deliveryCount == 0` → backward-compatible old scorer, apply normally
   - `deliveryCount == lastDeliveryCount + 1` → sequential, apply normally
   - Otherwise → gap detected, re-send `join_match` to get full `match_state` snapshot
4. A `_refreshRequested` flag prevents spamming `join_match` on multiple rapid gaps
5. `match_state` response resets the counter and clears the refresh flag
6. Innings change resets `lastDeliveryCount` to 0

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| Brief WS disconnect, 2 deliveries dropped | Viewer detects gap, re-joins, gets full state in <500ms |
| Long disconnect (30s+) | Durable path `match_state` arrives within 2-8s anyway |
| Undo (deliveryCount goes backward) | Treated as gap, viewer requests refresh |
| Innings change | `lastDeliveryCount` resets to 0; first 2nd-innings delivery (count=1) is sequential |
| Old scorer / new viewer | Old scorer sends no deliveryCount → defaults to 0 → gap check skipped |

---

## Deferred: Option C (WebSocket Bidirectional) — Phase 8+

Option C is a legitimate optimization for a future where CricScores has:
- Automated ball-tracking (no human scorer delay)
- Sub-second live betting integration
- Real-time commentary AI that needs instant delivery data

For a human-scored amateur cricket app, 200ms vs 50ms is invisible given the 20-40 second gap between deliveries.

If Option C is implemented later, it would **complement** A+E (not replace it):
- WS for online live scoring (50ms latency)
- HTTP batch for offline backlog recovery (3-8 sec)
- HTTP single for fallback when WS is unavailable

---

## Research Sources

- CricHeroes architecture analysis (Node.js + MySQL, per-ball HTTP, no batch endpoint found)
- [Boosting Postgres INSERT Performance by 2x With UNNEST](https://www.tigerdata.com/blog/boosting-postgres-insert-performance)
- [Testing Postgres Ingest: INSERT vs. Batch INSERT vs. COPY](https://www.tigerdata.com/learn/testing-postgres-ingest-insert-vs-batch-insert-vs-copy)
- [WebSockets vs HTTP performance comparison](https://blog.feathersjs.com/http-vs-websockets-a-performance-comparison-da2533f13a77)
- [Bun WebSocket benchmark — 7x Node.js](https://lemire.me/blog/2023/11/25/a-simple-websocket-benchmark-in-javascript-node-js-versus-bun/)
- [Building offline-first apps using event-sourcing](https://flpvsk.com/blog/2019-07-20-offline-first-apps-event-sourcing/)
- [Event Sourcing pattern — Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)
- [CQRS Pattern — Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs)
- [How to Architect a Scalable Sports Data Pipeline](https://medium.com/@marketing_25315/how-to-architect-a-scalable-low-latency-sports-data-pipeline-for-real-time-apps-385b18246fd8)
- [The Complete Guide to Offline-First Architecture in Android](https://androidengineers.substack.com/p/the-complete-guide-to-offline-first)
- CricScores API.md Section 1.7 — Batch sync endpoint spec (`POST /api/v1/sync/push`)
