---
name: server-batch-scoring
description: >
  Transactional batch delivery scoring conventions for the CricScores server: single
  transaction per batch, recordDeliveryInTx() as the shared core, per-transaction innings
  cache, server-side innings creation, and post-commit-only broadcasts/milestones.
globs: ["apps/server/src/services/scoring.service.ts", "apps/server/src/routes/v1/scoring.ts"]
synthesized: true
version: "1.0.0"
private: false
---

# Batch Scoring Transaction Rules

The batch sync endpoint `POST /api/v1/matches/:id/delivery-batch` (`apps/server/src/routes/v1/scoring.ts`, route `'/:id/delivery-batch'`) is the offline-sync entry point for mobile scorers. Its correctness contract is all-or-nothing: a batch either fully lands or fully rolls back.

## One Transaction Per Batch — No Partial Sync

`recordDeliveryBatch()` (`apps/server/src/services/scoring.service.ts`) MUST process every delivery of a batch inside a single `db.transaction()` (~line 624). Any thrown error (validation, missing innings, DB constraint) rolls back the ENTIRE batch.

- MUST NOT loop over deliveries with one transaction per delivery — a mid-batch failure would leave the match in a half-synced state the client cannot reconcile.
- MUST NOT catch-and-continue on a failing delivery inside the batch loop. Throw `AppError` and let the transaction abort; the client retries the whole batch.
- Cheap precondition checks (match exists, status is `live`/`innings_break`, caller is `matches.scorerId`) run BEFORE the transaction as fail-fast (~lines 596-613), then the match row is re-read INSIDE the transaction (~lines 626-634). Keep both — the pre-check saves a transaction, the in-tx re-read guards against races.

## recordDeliveryInTx() Is the Single Core

`recordDeliveryInTx()` (scoring.service.ts ~lines 92-460) is the transaction-aware 10-step delivery pipeline. Both the single-delivery path (`recordDelivery()`, ~line 478) and the batch path (~line 773) MUST flow through it.

```ts
type TxHandle = Parameters<Parameters<typeof db.transaction>[0]>[0];   // ~line 80

export async function recordDeliveryInTx(
  tx: TxHandle,
  matchId: string,
  txMatch: typeof matches.$inferSelect,          // read ONCE per transaction
  inningsCache: Map<number, typeof innings.$inferSelect>,
  input: DeliveryInput,
  precomputed?: { sequenceNumber?: number; isFreeHit?: boolean },
): Promise<DeliveryResult>
```

- New scoring logic (extras variants, dismissal types, magic-over tweaks) goes INSIDE `recordDeliveryInTx()` so both paths get it. MUST NOT fork delivery logic into a batch-only or single-only helper.
- Helper functions that touch the DB inside the pipeline MUST accept the `TxHandle` parameter (the pattern used at ~lines 1398, 1492, 1557, ...). NEVER call the global `db` from inside a transaction-scoped helper — it escapes the transaction.

## Per-Transaction inningsCache — No Re-Queries

Within a batch transaction, innings lookups MUST go through the shared `inningsCache: Map<inningsNumber, inningsRow>`:

- The batch path loads ALL existing innings for the match into the cache once (~lines 642-650), and `recordDeliveryInTx()` checks the cache before querying (~lines 105-123) and updates it after every innings mutation (~lines 374, 391, 419).
- MUST NOT issue a per-delivery `SELECT` for an innings already in the cache, and MUST keep the cache in sync after `UPDATE`/`INSERT` on `innings` — a stale cache row silently corrupts running totals for the rest of the batch.
- The same applies to sequence numbers: the batch precomputes `MAX(sequence_number)` ONCE per innings into `sequenceCounters` (~lines 688-700) and threads it via the `precomputed` parameter. New per-delivery derived state (e.g. free-hit tracking, ~lines 776-785) follows the same precompute-and-thread pattern.

## The SERVER Creates Innings Rows

Batch deliveries carry `inningsNumber` (TypeBox schema in scoring.ts, ~line 132) — clients NEVER send or coordinate innings UUIDs for innings they haven't seen. Inside the transaction the server pre-creates missing innings 2+ by swapping teams from innings 1 (~lines 652-686):

```ts
const [newInnings] = await tx.insert(innings).values({
  matchId,
  inningsNumber: inningsNum,
  battingTeamId: inn1.bowlingTeamId,
  bowlingTeamId: inn1.battingTeamId,
  target,
}).returning();
```

- Innings 1 MUST already exist (created at toss) — a batch referencing a missing innings 1 throws `VALIDATION_ERROR`, never auto-creates it.
- MUST NOT add a client-supplied innings-UUID creation path. Offline clients reference innings by number; the server owns identity.

## Broadcasts and Milestones Fire AFTER Commit — Never Inside

WebSocket broadcasts and activity-feed events MUST run after `db.transaction()` returns, never inside the callback:

- The batch route broadcasts ONE full `broadcastMatchState(matchId, state)` after the service call (scoring.ts ~lines 112-120), wrapped in try/catch that sets `broadcastStatus: 'failed'` without failing the HTTP response. MUST NOT broadcast per-delivery from a batch.
- Milestone events (50s/100s/wickets) via `emitMilestoneEvents()` are fire-and-forget post-commit with a logged `.catch` (scoring.service.ts ~line 535); batch-completion events (`emitMatchCompletedEvents`, `emitTournamentMatchResultEvents`) follow the same shape (~lines 799-819).
- A broadcast inside the transaction would announce state that may roll back, and a slow subscriber would hold the transaction open. If you need post-commit work that depends on the result, return the data from the transaction callback and act on it afterwards — exactly what `result.matchComplete` does (~line 799).

## CRITICAL RULES

- MUST process every delivery of a batch in ONE `db.transaction()` — any failure rolls back the whole batch; no partial sync, no catch-and-continue.
- MUST route all delivery recording (single and batch) through `recordDeliveryInTx()` with a `TxHandle` — never fork scoring logic per path or call global `db` inside a tx-scoped helper.
- MUST resolve innings through the per-transaction `inningsCache` and keep it updated after mutations — no per-delivery re-queries, no stale cache rows.
- MUST let the server create innings 2+ rows from `inningsNumber` inside the transaction — clients NEVER coordinate innings UUIDs; innings 1 must pre-exist from the toss.
- MUST fire WebSocket broadcasts and milestone/activity events AFTER transaction commit, fire-and-forget with logged `.catch` — NEVER inside the transaction, and broadcast failure MUST NOT fail the HTTP response (use `broadcastStatus`).
