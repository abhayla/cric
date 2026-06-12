---
name: flutter-offline-batch-sync
description: >
  The offline sync pipeline's four query-reduction properties (serial FIFO
  undo phase, per-match batched creates, single-trip reads, bulk synced
  marking) must be preserved by any change to sync_service.dart.
globs: ["apps/mobile/lib/src/shared/data/sync/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Offline Batch Sync Pipeline

`apps/mobile/lib/src/shared/data/sync/sync_service.dart` pushes locally
queued deliveries to the server in two phases. Its shape was deliberately
optimized (commit `c6ace4b`) to bound both HTTP round-trips and local DB
queries during live scoring. Any edit to this file MUST preserve the four
query-reduction properties below.

## Phase A — undo (delete) entries: serial FIFO

Undo entries MUST sync one at a time, in insertion order, stopping on the
first failure (`return false; // Stop on first failure to maintain FIFO`,
~line 170). An undo applied out of order would delete the wrong delivery
server-side. MUST NOT batch or parallelize Phase A.

## Phase B — create entries: batched per match, chunked

Constants (lines ~13–14 and ~225):

```dart
/// Minimum number of create entries to trigger batch mode.
const _batchThreshold = 1;

/// Max deliveries per single batch HTTP request to avoid huge transactions.
static const _maxBatchChunkSize = 30;
```

- When pending creates `>= _batchThreshold` (currently 1, i.e. effectively
  always), `_syncBatch` groups entries by `matchId` and POSTs each group to
  `/api/v1/matches/<matchId>/delivery-batch` (~line 258).
- Each per-match group is chunked at `_maxBatchChunkSize` (30) per request to
  bound server transaction size (~lines 241–245). MUST NOT remove chunking or
  raise the chunk size without server-side evidence.
- Note: the class doc comment still says "batch if >= 6 entries" — that is
  stale; the constant `_batchThreshold = 1` is authoritative.

## The four query-reduction properties (MUST preserve)

1. **Single-trip reads** — Phase B reads the queue once per loop iteration
   via `_dao.getPendingCreateEntries(limit: 300)` (~line 181). MUST NOT
   replace this with per-entry queries (N round-trips into Drift during a
   live match).
2. **Bulk synced marking** — after a successful chunk POST, mark the whole
   chunk with `_dao.markMultipleSynced(chunk.map((e) => e.id).toList())`
   (~line 262) — one query. MUST NOT loop `markSynced(entry.id)` per entry in
   the batch path (the per-entry call is correct only in single mode and
   Phase A).
3. **Per-chunk retry counters** — on a failed chunk, `incrementRetry` runs
   for the entries of THAT chunk only (~lines 270–273), and `_syncBatch`
   returns false. Retry semantics are per-chunk, not per-entry attempts and
   not global.
4. **Retry exhaustion is explicit** — entries with
   `retryCount >= maxRetries` (default 5) are `markFailed`, surfacing
   `SyncStatus.error` — they MUST NOT be silently dropped or marked synced.

## When changing this file

- Adding a new entity type to the queue: route it through the existing
  two-phase loop; do not add a third ad-hoc sync path.
- Changing batch size/threshold: update the constant, the doc comment, AND
  verify against the server's `delivery-batch` transaction limits.
- Any change MUST keep `_processCreateEntries`'s `while (true)` drain loop
  terminating: every iteration must either sync, fail-and-return, or return
  on empty.

## CRITICAL RULES

- Phase A (undo) MUST stay serial FIFO with stop-on-first-failure — NEVER
  batched or reordered.
- Phase B MUST batch creates per match to
  `POST /api/v1/matches/<matchId>/delivery-batch`, chunked at
  `_maxBatchChunkSize` (30).
- Reads MUST be single-trip (`getPendingCreateEntries(limit: 300)` once per
  drain iteration) — NEVER N per-entry queries.
- Post-sync marking in the batch path MUST use `markMultipleSynced()` — one
  query per chunk, not one per entry.
- Retry counters increment per-chunk on batch failure; exhausted entries are
  `markFailed` and surfaced via `SyncStatus.error` — NEVER silently dropped.
