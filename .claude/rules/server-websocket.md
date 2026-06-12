---
name: server-websocket
description: >
  WebSocket conventions for the CricScores server (Bun native pub/sub via Elysia):
  dual-path auth with prod kill-switch, viewer-vs-scorer authorization, canonical
  topic helpers, fire-and-forget broadcasts, and the deliveryCount gap-detection contract.
globs: ["apps/server/src/websocket/**/*.ts"]
synthesized: true
version: "1.0.0"
private: true
---

# WebSocket Rules

Live scoring flows through Bun's native WebSocket pub/sub, wired as the Elysia plugin in `apps/server/src/websocket/handler.ts`, with topics in `rooms.ts` and outbound messages in `broadcaster.ts`.

## Dual-Path Auth — Never Weaken Either Side

Connection auth in `handler.ts open()` has exactly two paths:

1. **Production path**: `getFirebaseAuth().verifyIdToken(token)` (~line 67), then map the connection to the verified UID in `verifiedConnections`.
2. **Test bypass**: accepted ONLY when BOTH `NODE_ENV === 'test'` AND `ENABLE_TEST_AUTH === 'true'` (~lines 61-64), mapping the connection to `'test-user-e2e-001'`.

The bypass is backstopped by the boot-time kill-switch in `apps/server/src/index.ts` (~lines 37-41):

```ts
if (env.NODE_ENV === 'production' && process.env.ENABLE_TEST_AUTH === 'true') {
  console.error('FATAL: ENABLE_TEST_AUTH is forbidden in production');
  process.exit(1);
}
```

- MUST NOT relax the bypass condition (e.g. dropping the `NODE_ENV === 'test'` half, or honoring `ENABLE_TEST_AUTH` alone) and MUST NOT remove or soften the boot-time `process.exit(1)`. The double condition + kill-switch is the entire safety story for test auth.
- New auth-dependent WS features MUST resolve identity through `verifiedConnections.get(getWsKey(ws))` — never re-verify tokens per message and never trust a client-sent UID.

## Viewers vs. Scorers

Token-less connections are allowed as anonymous viewers (`if (!token) return;` ~line 57) — they can subscribe to match topics but MUST NEVER publish scores or mutate state.

Scorer authorization is checked per match via `verifyScorerForMatch(uid, matchId)` (~lines 25-46): cache lookup in the `scorerMatchAuth: Map<uid, Set<matchId>>` (~line 18) first, then a DB join `matches.scorerId → users.firebaseUid` on miss, caching positive results.

- Any new message type that writes match data MUST gate on `verifyScorerForMatch()` — viewer messages are read/subscribe only.
- Keep the cache positive-only as it is now: cache authorized pairs, re-query on miss. MUST NOT cache negative results (a scorer assigned mid-session would be locked out until restart).

## Canonical Topics — matchTopic() / userTopic() Only

The only two topic families are defined in `rooms.ts` (~lines 26-32):

```ts
export function matchTopic(matchId: string): string { return `match:${matchId}`; }
export function userTopic(userId: string): string { return `user:${userId}`; }
```

- `match:<matchId>` carries score/delivery/innings/match events; `user:<userId>` carries roster/team/tournament notifications (`broadcastTeamUpdated`, `broadcastTournamentUpdated` in `broadcaster.ts`).
- MUST use these helpers for every `subscribe`/`publish` call. NEVER build ad-hoc topic strings inline — a typo'd topic fails silently (publish to nobody).
- A genuinely new topic family requires a new helper in `rooms.ts` plus matching subscribe logic in `handler.ts` — not a string literal at the call site.

## Broadcasts Are Fire-and-Forget

`publish()` in `broadcaster.ts` (~lines 32-35) guards on the server reference and returns void:

```ts
function publish(matchId: string, message: object): void {
  if (!server) return;
  server.publish(matchTopic(matchId), JSON.stringify(message));
}
```

- Broadcast failure MUST NOT block or fail service/route logic. Routes wrap broadcast calls in try/catch and report `broadcastStatus: 'failed'` in the response instead of throwing (see `apps/server/src/routes/v1/scoring.ts` ~lines 113-120) — follow that shape for new broadcast call sites.
- MUST NOT make HTTP handlers await delivery confirmation from subscribers, and MUST NOT broadcast from inside a `db.transaction()` (see `server-batch-scoring.md`).
- `initBroadcaster(app.server!)` runs once after `app.listen()` in `index.ts` — new broadcast functions go in `broadcaster.ts` using the existing `publish`/`publishToUser` helpers, never holding their own server reference.

## Gap Detection — the deliveryCount Contract

Score broadcasts carry an incrementing `deliveryCount` (computed in `rooms.ts` ~lines 241-269, typed in `apps/server/src/types/websocket.ts` ~lines 93, 116). Viewers detect a missed message when `count != last + 1` and re-sync by sending `join_match`, which returns the full `getMatchState()` snapshot. The design is documented in `docs/planning/SYNC_ARCHITECTURE.md`.

- Any NEW broadcast type that represents scoring progress MUST preserve the counter contract: include the current `deliveryCount` so viewers can keep gap detection working.
- MUST NOT renumber, reset, or approximate `deliveryCount` — it derives from the actual deliveries table count, the single source of truth.
- The recovery path is always re-sync via full snapshot (`join_match` → `getMatchState()`), never client-side patching of missed deltas.

## CRITICAL RULES

- MUST keep WS auth dual-path: Firebase `verifyIdToken` in production; test bypass ONLY under `NODE_ENV === 'test' && ENABLE_TEST_AUTH === 'true'`; NEVER weaken the boot-time prod kill-switch (`process.exit(1)` in index.ts ~37-41).
- Anonymous (token-less) connections are viewers only — MUST NEVER publish scores; all write-path messages gate on `verifyScorerForMatch()` with the positive-only `scorerMatchAuth` cache.
- MUST build every topic via `matchTopic()` / `userTopic()` from `rooms.ts` — never ad-hoc topic strings.
- Broadcasts are fire-and-forget: failure sets `broadcastStatus: 'failed'`, MUST NOT block or fail service logic, and MUST NOT run inside a transaction.
- Every scoring-progress broadcast MUST carry the incrementing `deliveryCount`; gap recovery is full-snapshot re-sync via `join_match`, never delta patching.
